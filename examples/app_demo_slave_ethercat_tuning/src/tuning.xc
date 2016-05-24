/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>


static inline void update_offset(MotorcontrolConfig &motorcontrol_config, int voltage, int offset)
{
    if (voltage >= 0)
        motorcontrol_config.hall_offset[0] =  offset;
    else
        motorcontrol_config.hall_offset[1] =  offset;
}

void run_offset_tuning(int position_limit, interface MotorcontrolInterface client i_commutation,
                       interface ADCInterface client ?i_adc, chanend coe_out, chanend pdo_out, chanend pdo_in,
                       interface PositionControlInterface client ?i_position_control, interface BrakeInterface client ?i_brake,
                       interface HallInterface client ?i_hall, interface BISSInterface client ?i_biss, interface AMSInterface client ?i_ams)
{
    delay_milliseconds(500);
    printf(">>   SOMANET ETHERCAT OFFSET TUNING SERVICE STARTING...\n");

    //variables
    int offset = 0;
    int field_control_flag = 1;
    int brake_flag = 0;
    int torque_flag = 0;
    int pole_pairs = 0;
    char mode = 0;
    int value = 0;
    int status_mux = 0;
    int count = 0;
    int velocity = 0;
    int position_limit_reached = 0;
    int voltage = 0;
    //timing
    timer t;
    unsigned ts;
    t :> ts;
    //tuning variable
    int enable_tuning = 0;
    int current_sampling = 0;
    int peak_current = 0;
    int last_peak_current = 0;
    int phase_b, phase_c;
    int best_offset_pos, best_offset_neg, offset_pos, offset_neg, start_offset_pos, start_offset_neg;
    int min_current_pos, last_min_current_pos, min_current_neg, last_min_current_neg;
    int range_pos, range_neg, step_pos, step_neg;
    int tuning_done_pos, tuning_done_neg;
    //parameters structs
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    BISSConfig biss_config;
    AMSConfig ams_config;
    HallConfig hall_config;
    ctrl_proto_values_t InOut;
    //init structs and set number of pole pairs
    if (!isnull(i_ams)) {
        ams_config = i_ams.get_ams_config();
        pole_pairs = ams_config.pole_pairs;
    }
    if (!isnull(i_biss)) {
        biss_config = i_biss.get_biss_config();
        pole_pairs = biss_config.pole_pairs;
    }
    if (!isnull(i_hall)) {
        hall_config = i_hall.get_hall_config();
        pole_pairs = hall_config.pole_pairs;
    }

    /* Initialise the position profile generator */
    if (!isnull(i_position_control)) {
        ProfilerConfig profiler_config;
        profiler_config.polarity = POLARITY;
        profiler_config.max_position = MAX_POSITION_LIMIT;
        profiler_config.min_position = MIN_POSITION_LIMIT;
        profiler_config.max_velocity = MAX_VELOCITY;
        profiler_config.max_acceleration = MAX_ACCELERATION;
        profiler_config.max_deceleration = MAX_DECELERATION;
        init_position_profiler(profiler_config, i_position_control, i_hall, null, i_biss, i_ams);
    }

    //init offset
    if (motorcontrol_config.commutation_method == FOC) {
        field_control_flag = 0;
        i_commutation.set_control(field_control_flag);
        printf("FOC commutation\nField and Torque controllers deactivated\n");
    } else {
        printf("Sine commutation\n");
    }
    if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
        printf("Hall tuning, ");
    } else if (motorcontrol_config.commutation_sensor == BISS_SENSOR){
        offset = i_commutation.set_sensor_offset(-1);
        printf("BiSS tuning, Sensor offset %d, ", offset);
    } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR){
        offset = i_commutation.set_sensor_offset(-1);
        printf("AMS tuning, Sensor offset %d, ", offset);
    }
    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
        printf ( "Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
    } else {
        printf ( "Polarity %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
    }
    fflush(stdout);


    //main loop
    while (1) {
        select {
        case t when timerafter(ts) :> void:
            //update ethercat and send data
            ctrlproto_protocol_handler_function(pdo_out,pdo_in,InOut);
            InOut.velocity_actual = velocity;
            InOut.torque_actual = i_commutation.get_torque_actual();
            InOut.position_actual = ((last_peak_current << 16) & 0xffff0000) | (i_commutation.get_field() & 0x0000ffff);
            InOut.operation_mode_display = (0x80 & InOut.operation_mode_display) | status_mux;
            switch(status_mux) { //send offsets and other data in the status_word
            case 0: //send offset clk
                InOut.status_word = 0xfff & motorcontrol_config.hall_offset[0];
                break;
            case 1: //send offset cclk
                InOut.status_word = 0xfff & motorcontrol_config.hall_offset[1];
                break;
            case 2: //send sensor offset
                InOut.status_word = offset;
                break;
            case 3:
                InOut.status_word = (pole_pairs << 3) | (field_control_flag << 2);
                if (motorcontrol_config.bldc_winding_type == DELTA_WINDING)
                    InOut.status_word |= 0b01;
                if (motorcontrol_config.polarity_type == INVERTED_POLARITY)
                    InOut.status_word |= 0b10;
                status_mux = -1;
                break;
            }
            status_mux++;

            //read ethercat data
            if (InOut.operation_mode != 6) { //received mode
                InOut.operation_mode_display |= 0x80; //send ack
                mode = InOut.operation_mode;
                value = sext(InOut.target_position, 32);
            } else if (InOut.operation_mode_display & 0x80) { //ack send, received ack
                InOut.operation_mode_display &= 0x7f;

                //execute command
                switch(mode) {
                //auto find offset
                case 'a':
                    if (!isnull(i_brake)) {
                        brake_flag = 1;
                        i_brake.set_brake(brake_flag);
                    }
                    //stop the motor
                    i_commutation.set_voltage(0);
                    delay_milliseconds(500);
                    i_commutation.set_calib(1);
                    //set internal commutation voltage to 1000
                    i_commutation.set_voltage(1000);
                    //go to 1024 position (quarter turn)
                    delay_milliseconds(500);
                    offset = i_commutation.set_calib(0);
                    //start turning the motor and print the offsets found
                    voltage = 0;
                    i_commutation.set_voltage(voltage);
                    if (!isnull(i_brake)) {
                        brake_flag = 0;
                        i_brake.set_brake(brake_flag);
                    }
                    motorcontrol_config = i_commutation.get_config();
                    break;
                //release brake
                case 'b':
                    if (!isnull(i_brake)) {
                        if (brake_flag)
                            brake_flag = 0;
                        else
                            brake_flag = 1;
                        i_brake.set_brake(brake_flag);
                    }
                    break;
                //auto tune the offset by mesuring the current consumption
                case 'c':
                    if (!isnull(i_adc)) {
                        if (voltage && enable_tuning == 0) {
                            motorcontrol_config = i_commutation.get_config();
                            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                                start_offset_pos = i_commutation.set_sensor_offset(-1);
                                start_offset_neg = start_offset_pos;
                            } else {
                                start_offset_pos = motorcontrol_config.hall_offset[0];
                                start_offset_neg = motorcontrol_config.hall_offset[1];
                            }
                            best_offset_pos = start_offset_pos;
                            offset_pos = start_offset_pos;
                            best_offset_neg = start_offset_neg;
                            offset_neg = start_offset_neg;
                            enable_tuning = 1;
                            last_min_current_pos = 10000;
                            min_current_pos = 10000;
                            last_min_current_neg = 10000;
                            min_current_neg = 10000;
                            peak_current = 0;
                            current_sampling = 200;
                            range_pos = 0;
                            step_pos = 2;
                            range_neg = 0;
                            step_neg = 2;
                            tuning_done_pos = 0;
                            tuning_done_neg = 0;
                        } else {
                            enable_tuning = 0;
                            motorcontrol_config.hall_offset[0] = best_offset_pos;
                            motorcontrol_config.hall_offset[1] = best_offset_neg;
                            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                                i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                                offset = i_commutation.set_sensor_offset(-1);
                                motorcontrol_config.hall_offset[0] = 0;
                                motorcontrol_config.hall_offset[1] = 0;
                            }
                            i_commutation.set_config(motorcontrol_config);
                        }
                    }
                    break;
                //reverse motor direction
                case 'd':
                    if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
                        int temp = motorcontrol_config.hall_offset[0];
                        motorcontrol_config.hall_offset[0] = (motorcontrol_config.hall_offset[1] + 2048) & 4095;
                        motorcontrol_config.hall_offset[1] = (temp + 2048) & 4095;
                        i_commutation.set_config(motorcontrol_config);
                    } else if (motorcontrol_config.commutation_sensor == BISS_SENSOR) {
                        offset = (offset + 2048) & 4095;
                        i_commutation.set_sensor_offset(offset);
                    } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR) {
                        if (motorcontrol_config.commutation_method == FOC) {
                            motorcontrol_config.hall_offset[0] = (motorcontrol_config.hall_offset[0] + 2048) & 4095;
                        } else {
                            int temp = motorcontrol_config.hall_offset[0];
                            motorcontrol_config.hall_offset[0] = (motorcontrol_config.hall_offset[1] + 2048) & 4095;
                            motorcontrol_config.hall_offset[1] = (temp + 2048) & 4095;
                        }
                        i_commutation.set_config(motorcontrol_config);
                    }
                    break;
                //reverse motor winding type
                case 'w':
                    if (motorcontrol_config.bldc_winding_type == STAR_WINDING)
                        motorcontrol_config.bldc_winding_type = DELTA_WINDING;
                    else
                        motorcontrol_config.bldc_winding_type = STAR_WINDING;
                    i_commutation.set_config(motorcontrol_config);
                    break;
                //toggle field controler
                case 'f':
                    if (motorcontrol_config.commutation_method == FOC) {
                        if (field_control_flag == 0) {
                            field_control_flag = 1;
                        } else {
                            field_control_flag = 0;
                        }
                        i_commutation.set_control(field_control_flag);
                    }
                    break;
                //position limit
                case 'l':
                    if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
                        i_biss.reset_biss_position(0);
                    } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                        i_ams.reset_ams_position(0);
                    } else if (motorcontrol_config.commutation_sensor == HALL_SENSOR && !isnull(i_hall)) {
                        i_hall.reset_hall_absolute_position(0);
                    }
                    if (value < 0) {
                        position_limit = value;
                    } else if (value > 0) {
                        position_limit = value;
                    }
                    break;
                //reverse motor polarity
                case 'm':
                    if (motorcontrol_config.polarity_type == NORMAL_POLARITY) {
                        motorcontrol_config.polarity_type = INVERTED_POLARITY;
                        motorcontrol_config.bldc_winding_type = DELTA_WINDING;
                    } else {
                        motorcontrol_config.polarity_type = NORMAL_POLARITY;
                        motorcontrol_config.bldc_winding_type = STAR_WINDING;
                    }
                    i_commutation.set_config(motorcontrol_config);
                    break;
                //set offset
                case 'o':
                    if (voltage >= 0 || (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR)) {
                        motorcontrol_config.hall_offset[0] = value;
                    } else {
                        motorcontrol_config.hall_offset[1] = value;
                    }
                    i_commutation.set_config(motorcontrol_config);
                    break;
                //set number of pole pairs
                case 'p':
                    if (!isnull(i_hall)) {
                        hall_config = i_hall.get_hall_config();
                        hall_config.pole_pairs = value;
                        i_hall.set_hall_config(hall_config);
                    }
                    if (!isnull(i_biss)) {
                        biss_config = i_biss.get_biss_config();
                        biss_config.pole_pairs = value;
                        i_biss.set_biss_config(biss_config);
                    }
                    if (!isnull(i_ams)) {
                        ams_config = i_ams.get_ams_config();
                        ams_config.pole_pairs = value;
                        i_ams.set_ams_config(ams_config);
                    }
                    pole_pairs = value;
                    break;
                //reverse voltage
                case 'r':
                    if (voltage) {
                        if (!isnull(i_brake)) {
                            brake_flag = 1;
                            i_brake.set_brake(brake_flag);
                        }
                        voltage = -voltage;
                        if (motorcontrol_config.commutation_method == FOC && torque_flag) {
                            i_commutation.set_torque(voltage);
                        } else {
                            i_commutation.set_voltage(voltage);
                        }
                    }
                    break;
                //set sensor offset
                case 's':
                    offset = value;
                    i_commutation.set_sensor_offset(offset);
                    break;
                //set torque
                case 't':
                    if (motorcontrol_config.commutation_method == FOC) {
                        if (!isnull(i_brake)) {
                            brake_flag = 1;
                            i_brake.set_brake(brake_flag);
                        }
                        field_control_flag = 1;
                        voltage = value;
                        i_commutation.set_torque(voltage);
                        torque_flag = 1;
                    }
                    break;
                //restart watchdog
                case 'y':
                    if (!isnull(i_brake)) {
                        brake_flag = 1;
                        i_brake.set_brake(brake_flag);
                    }
                    i_commutation.set_voltage(0);
                    i_commutation.restart_watchdog();
                    if (!isnull(i_brake)) {
                        brake_flag = 0;
                        i_brake.set_brake(brake_flag);
                    }
                    break;
                //go to 0 position
                case 'z':
                    if (!isnull(i_position_control)) {
                        if (!isnull(i_brake)) {
                            brake_flag = 1;
                            i_brake.set_brake(brake_flag);
                        }
                        /* Set new target position for profile position control */
                        set_profile_position(value, 200, 200, 200, i_position_control);
                        i_position_control.disable_position_ctrl();
                        voltage = 0;
                        i_commutation.set_voltage(voltage);
                        i_commutation.set_fets_state(1);
                        if (!isnull(i_brake)) {
                            brake_flag = 0;
                            i_brake.set_brake(brake_flag);
                        }
                    }
                    break;
                //set voltage
                case 0:
                    motorcontrol_config = i_commutation.get_config();
                    if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == BISS_SENSOR) {
                        offset = i_commutation.set_sensor_offset(-1);
                    }
                    torque_flag = 0;
                    voltage = value;
                    if (voltage) {
                        if (!isnull(i_brake)) {
                            brake_flag = 1;
                            i_brake.set_brake(brake_flag);
                        }
                        i_commutation.set_voltage(voltage);
                    } else {
                        i_commutation.set_voltage(voltage);
                        delay_milliseconds(500);
                        if (!isnull(i_brake)) {
                            brake_flag = 0;
                            i_brake.set_brake(brake_flag);
                        }
                    }
                    break;
                } //end of switch
            } //end of new command received


            //get position and velocity
            if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
                velocity = i_biss.get_biss_velocity();
                { count, void, void } = i_biss.get_biss_position();
            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                velocity = i_ams.get_ams_velocity();
                { count, void } = i_ams.get_ams_position();
            } else if (motorcontrol_config.commutation_sensor == HALL_SENSOR && !isnull(i_hall)) {
                count = i_hall.get_hall_position_absolute();
                velocity = i_hall.get_hall_velocity();
            }

            //postion limiter
            if (position_limit > 0) {
                if (count >= position_limit && velocity > 10) {
                    i_commutation.set_voltage(0);
                    position_limit_reached = 1;
                    if (!isnull(i_brake) && enable_tuning == 0) {
                        delay_milliseconds(500);
                        brake_flag = 0;
                        i_brake.set_brake(brake_flag);
                    }
                } else if (count <= -position_limit && velocity < -10) {
                    i_commutation.set_voltage(0);
                    position_limit_reached = 1;
                    if (!isnull(i_brake) && enable_tuning == 0) {
                        delay_milliseconds(500);
                        brake_flag = 0;
                        i_brake.set_brake(brake_flag);
                    }
                } else {
                    position_limit_reached = 0;
                }
            }

            //current measurement
            if (!isnull(i_adc)) {
                {phase_b, phase_c} = i_adc.get_currents();
                current_sampling--;
                //find the peak current by sampling every [period] microseconds [times] times
                if (phase_b > peak_current)
                    peak_current = phase_b;
                else if (phase_b < -peak_current)
                    peak_current = -phase_b;
            }

            //tuning loop
            if (enable_tuning) {
                //reverse direction if the position limit is reached
                if (position_limit_reached) {
                    position_limit_reached = 0;
                    i_commutation.set_voltage(0);
                    delay_milliseconds(500);
                    voltage = -voltage;
                    i_commutation.set_voltage(voltage);
                    delay_milliseconds(500);
                    current_sampling = 200;
                    peak_current = 0;
                }

                //new measured peak current
                if (current_sampling <= 0) {

                    if (voltage > 0 && tuning_done_pos == 0) {
                        //update min current and best offset
                        if (peak_current < min_current_pos) {
                            min_current_pos = peak_current;
                            best_offset_pos = offset_pos;
                        }
                        //end of a range, check if the peak current is decreasing
                        if (range_pos <= 0) {
                            if (min_current_pos >= last_min_current_pos) {
                                if (step_pos > 0) { //now search by decreasing the offset
                                    step_pos = -step_pos;
                                    offset_pos = start_offset_pos;
                                } else { //offset pos tuning is done
                                    tuning_done_pos = 1;
                                    position_limit_reached = 1;
                                }
                            }
                            range_pos = 25;
                            last_min_current_pos = min_current_pos;
                        }
                        range_pos--;
                        offset_pos += step_pos;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_pos);
                            offset = offset_pos;
                        } else {
                            update_offset(motorcontrol_config, voltage, (offset_pos & 4095));
                        }
                    } else if (voltage < 0 && tuning_done_neg == 0){ //negative voltage
                        //update min current and best offset
                        if (peak_current < min_current_neg) {
                            min_current_neg = peak_current;
                            best_offset_neg = offset_neg;
                        }
                        if (range_neg <= 0) { //end of a range, check if the peak current is decreasing
                            if (min_current_neg >= last_min_current_neg) {
                                if (step_neg > 0) { //now search by decreasing the offset
                                    step_neg = -step_neg;
                                    offset_neg = start_offset_neg;
                                } else { //offset neg tuning is done
                                    tuning_done_neg = 1;
                                    position_limit_reached = 1;
                                }
                            }
                            range_neg = 25;
                            last_min_current_neg = min_current_neg;
                        }
                        range_neg--;
                        offset_neg += step_neg;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_neg);
                            offset = offset_neg;
                        } else {
                            update_offset(motorcontrol_config, voltage, (offset_neg & 4095));
                        }
                    }

                    if((tuning_done_pos + tuning_done_neg) >= 2) {//tuning is done
                        voltage = 0;
                        i_commutation.set_voltage(voltage);
                        if (!isnull(i_brake)) {
                            delay_milliseconds(500);
                            brake_flag = 0;
                            i_brake.set_brake(brake_flag);
                        }
                        enable_tuning = 0;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor == AMS_SENSOR) {
                            AMSConfig ams_config = i_ams.get_ams_config();
                            int ticks_per_turn = (1 << ams_config.resolution_bits);
                            best_offset_pos &= (ticks_per_turn - 1);
                            best_offset_neg &= (ticks_per_turn - 1);
                        } else {
                            best_offset_pos &= 4095;
                            best_offset_neg &= 4095;
                        }
                        motorcontrol_config.hall_offset[0] = best_offset_pos;
                        motorcontrol_config.hall_offset[1] = best_offset_neg;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                            offset = i_commutation.set_sensor_offset(-1);
                            motorcontrol_config.hall_offset[0] = 0;
                            motorcontrol_config.hall_offset[1] = 0;
                        }
                        i_commutation.set_config(motorcontrol_config);
                    } else {
                        last_peak_current = peak_current; //for displaying peak current
                        peak_current = 0;       // reset
                        current_sampling = 200; // current sampling
                        i_commutation.set_config(motorcontrol_config); //update offset
                    }
                } //end new measured peak current
            } //end tuning loop

            if (current_sampling <= 0) {
                last_peak_current = peak_current;
                current_sampling = 200;
                peak_current = 0;
            }
            t :> ts;
            ts += USEC_STD * 1000;
            break;
        } //end select
    } //end while(1)
}
