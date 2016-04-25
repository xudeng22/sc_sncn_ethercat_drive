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
    if ((voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
        motorcontrol_config.hall_offset[0] =  offset;
    else
        motorcontrol_config.hall_offset[1] =  offset;
}

void run_offset_tuning(int position_limit, interface MotorcontrolInterface client i_commutation, interface TuningInterface client ?i_tuning,
                       interface ADCInterface client ?i_adc, chanend coe_out, chanend pdo_out, chanend pdo_in,
                       interface PositionControlInterface client ?i_position_control,
                       interface HallInterface client ?i_hall, interface BISSInterface client ?i_biss, interface AMSInterface client ?i_ams)
{
    delay_milliseconds(500);
    printf(">>   SOMANET OFFSET TUNING SERVICE STARTING...\n");
    int offset = 0;
    int field_control_flag = 1;
    int torque_flag = 0;
    //set position limit
    if (position_limit && !isnull(i_tuning))
        i_tuning.set_limit(position_limit);
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    ctrl_proto_values_t InOut;

    timer t;
    unsigned ts;
    t :> ts;
    int count = 0;
    int torque_offset = 0;
    int velocity = 0;
    int position_limit_reached = 0;
    int print_position_limit = 0;
    int voltage = 0;
    int target_torque = 0;
    int current_sampling = 0;
    int peak_current = 0;
    int last_peak_current = 0;
    int phase_b, phase_c;
    int adc_a, adc_b;
    int enable_tuning = 0;
    int best_offset_pos, best_offset_neg, offset_pos, offset_neg, start_offset_pos, start_offset_neg;
    int min_current_pos, last_min_current_pos, min_current_neg, last_min_current_neg;
    int range_pos, range_neg, step_pos, step_neg;
    int tuning_done_pos, tuning_done_neg;

    if (!isnull(i_position_control)) {
        /* Initialise the position profile generator */
        ProfilerConfig profiler_config;
        profiler_config.polarity = POLARITY;
        profiler_config.max_position = MAX_POSITION_LIMIT;
        profiler_config.min_position = MIN_POSITION_LIMIT;
        profiler_config.max_velocity = MAX_VELOCITY;
        profiler_config.max_acceleration = MAX_ACCELERATION;
        profiler_config.max_deceleration = MAX_DECELERATION;
        init_position_profiler(profiler_config, i_position_control, i_hall, null, i_biss, i_ams);
    }

    if (!isnull(i_adc)) {
        { adc_a, adc_b } = i_adc.get_external_inputs();
        torque_offset = adc_b - adc_a;
        torque_offset = 0;
    }

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
        printf ( "Star winding, Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
    } else if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
        printf ( "Star winding, Polarity %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
    } else {
        printf ("Delta winding, Polarity %d\noffset clk %d (for negative voltage)\noffset cclk %d (for positive voltage)\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
    }
    printf("Enter a to start the auto sensor offset finding.\n");
    fflush(stdout);
    //read and adjust the offset.
    char mode = 0;
    int value = 0;
    int sign = 1;
    int status_mux = 0;
    while (1) {
        select {
        case t when timerafter(ts) :> void:
            //update ethercat
            ctrlproto_protocol_handler_function(pdo_out,pdo_in,InOut);
            InOut.velocity_actual = velocity;
            InOut.torque_actual = i_commutation.get_torque_actual();
            InOut.position_actual = ((last_peak_current << 16) & 0xffff0000) | (i_commutation.get_field() & 0x0000ffff);
            switch(status_mux) { //send offsets in the status_word
            case 0: //send offset clk
                int polarity_winding_bit = 0;
                if (motorcontrol_config.polarity_type == INVERTED_POLARITY)
                    polarity_winding_bit |= 0x2000;
                if (motorcontrol_config.bldc_winding_type == DELTA_WINDING)
                    polarity_winding_bit |= 0x1000;
                InOut.status_word = polarity_winding_bit | (0xfff & motorcontrol_config.hall_offset[0]);
                break;
            case 1: //send offset cclk
                InOut.status_word = (field_control_flag << 12) | 0x4000 | (0xfff & motorcontrol_config.hall_offset[1]);
                break;
            case 2: //send sensor offset
                InOut.status_word = 0x8000 | offset;
                status_mux = -1;
                break;
            }
            status_mux++;
//            InOut.status_word = motorcontrol_config.hall_offset[0];

//            last_peak_current =  1234;
//            int field = -2345;
//            InOut.position_actual = ((last_peak_current << 16) & 0xffff0000) | (field & 0x0000ffff);


            if (InOut.operation_mode != 6) { //received mode
                InOut.operation_mode_display = 6; //send ack
                mode = InOut.operation_mode;
                value = sext(InOut.target_position, 32);
            } else if (InOut.operation_mode_display == 6) { //received ack
                InOut.operation_mode_display = 0;
                printf("mode %d, value %d\n", mode, value);

                switch(mode) {
                //auto find offset
                case 'a':
                    //stop the motor
                    i_commutation.set_voltage(0);
                    delay_milliseconds(500);
                    i_commutation.set_calib(1);
                    //set internal commutation voltage to 1000
                    if (motorcontrol_config.bldc_winding_type == STAR_WINDING)
                        i_commutation.set_voltage(1000);
                    else
                        i_commutation.set_voltage(-1000);
                    //go to 1024 position (quarter turn)
                    delay_milliseconds(500);
                    offset = i_commutation.set_calib(0);
                    //start turning the motor and print the offsets found
                    i_commutation.set_voltage(voltage);
                    motorcontrol_config = i_commutation.get_config();
                    if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == BISS_SENSOR) {
                        printf("Sensor offset: %d, ", offset);
                    }
                    printf("Voltage %d, Polarity %d\n", voltage, motorcontrol_config.polarity_type);
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        printf ( "Star winding, Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
                    } else if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                        printf("Star winding\nPolarity %d, Voltage %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    } else {
                        printf("Delta winding\nPolarity %d, Voltage %d\noffset clk %d (for negative voltage)\noffset cclk %d (for positive voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    }
                    if (motorcontrol_config.commutation_sensor == HALL_SENSOR) {
                        printf("Hall sensor are not precise!\nOffsets could need to be shifted by +/- 682.\n");
                    }
                    printf("Enter c to start the auto tuning\nor enter o with a value to set the offset manually\n");
                    break;
                    //auto tune the offset by mesuring the current consumption
                case 'c':
                    //            if (!isnull(i_adc)) {
                    //                printf("Starting auto tuning...\n(This could take around 30 seconds)\n");
                    //                if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING)) {
                    //                    motorcontrol_config.hall_offset[0] = auto_tuning_current(i_commutation, i_adc, voltage);
                    ////                    motorcontrol_config = i_commutation.get_config();
                    //                    printf("auto tuned offset clk: %d\n", motorcontrol_config.hall_offset[0]);
                    //                } else {
                    //                    motorcontrol_config.hall_offset[1] = auto_tuning_current(i_commutation, i_adc, voltage);
                    //                    printf("auto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[1]);
                    //                }
                    //            } else {
                    //                printf("No adc service provided\n");
                    //            }
                    //            if (voltage)
                    //                printf("Starting auto tuning...\n(This could take around 30 seconds)\n");
                    //            else
                    //                printf("Stop auto tuning...\n");
                    if (!isnull(i_adc)) {
                        if (voltage && enable_tuning == 0) {
                            motorcontrol_config = i_commutation.get_config();
                            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                                start_offset_pos = i_commutation.set_sensor_offset(-1);
                                start_offset_neg = start_offset_pos;
                            } else if (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                                start_offset_pos = motorcontrol_config.hall_offset[0];
                                start_offset_neg = motorcontrol_config.hall_offset[1];
                            } else {
                                start_offset_pos = motorcontrol_config.hall_offset[1];
                                start_offset_neg = motorcontrol_config.hall_offset[0];
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
                            printf("Starting auto tuning...\n");
                        } else {
                            enable_tuning = 0;
                            if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                                motorcontrol_config.hall_offset[0] = best_offset_pos;
                                motorcontrol_config.hall_offset[1] = best_offset_neg;
                            } else {
                                motorcontrol_config.hall_offset[1] = best_offset_pos;
                                motorcontrol_config.hall_offset[0] = best_offset_neg;
                            }
                            printf("Tuning aborted!\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                            if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                                i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                                offset = i_commutation.set_sensor_offset(-1);
                                motorcontrol_config.hall_offset[0] = 0;
                                motorcontrol_config.hall_offset[1] = 0;
                                printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                            }
                            i_commutation.set_config(motorcontrol_config);
                        }
                    }
                    break;
                    //reverse motor direction
                case 'd':
                    if (motorcontrol_config.commutation_method == FOC) {
                        if (motorcontrol_config.bldc_winding_type == STAR_WINDING)
                            motorcontrol_config.bldc_winding_type = DELTA_WINDING;
                        else
                            motorcontrol_config.bldc_winding_type = STAR_WINDING;
                        i_commutation.set_config(motorcontrol_config);
                        printf("Reverse motor direction\n");
                    } else { //flip offsets
                        int temp = motorcontrol_config.hall_offset[0];
                        motorcontrol_config.hall_offset[0] = motorcontrol_config.hall_offset[1];
                        motorcontrol_config.hall_offset[1] = temp;
                        i_commutation.set_config(motorcontrol_config);
                        if (motorcontrol_config.bldc_winding_type == STAR_WINDING)
                            printf("Polarity %d, Voltage %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                        else
                            printf("Polarity %d, Voltage %d\noffset clk %d (for negative voltage)\noffset cclk %d (for positive voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    }
                    break;
                    //toggle field controler
                case 'f':
                    if (motorcontrol_config.commutation_method == FOC) {
                        if (field_control_flag == 0) {
                            field_control_flag = 1;
                            printf("Field controler activated\n");
                        } else {
                            field_control_flag = 0;
                            printf("Field and Torque controlers deactivated\n");
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
                        printf("Position limit disabled\n");
                    } else if (value > 0) {
                        printf("Position limited to %d ticks around here\n", value);
                        position_limit = value;
                    } else {
                        printf("Position limited around here\n");
                    }
                    break;
                    //reverse sensor direction
                case 'm':
                    if (motorcontrol_config.polarity_type == NORMAL_POLARITY)
                        motorcontrol_config.polarity_type = INVERTED_POLARITY;
                    else
                        motorcontrol_config.polarity_type = NORMAL_POLARITY;
                    i_commutation.set_config(motorcontrol_config);
                    printf("Polarity %d\n", motorcontrol_config.polarity_type);
                    break;
                    //set offset
                case 'o':
                    if ((motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) ||
                            (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) ||
                            (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING)) {
                        motorcontrol_config.hall_offset[0] = value;
                        printf("offset clk: %d\n", value);
                    } else {
                        motorcontrol_config.hall_offset[1] = value;
                        printf("offset cclk: %d\n", value);
                    }
                    i_commutation.set_config(motorcontrol_config);
                    break;
                    //print offsets, voltage and polarity
                case 'p':
                    motorcontrol_config = i_commutation.get_config();
                    if (motorcontrol_config.commutation_sensor == AMS_SENSOR || motorcontrol_config.commutation_sensor == BISS_SENSOR) {
                        offset = i_commutation.set_sensor_offset(-1);
                        printf("Sensor offset %d, ", offset);
                    }
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        printf ( "Star winding, Polarity %d\noffset %d\n", motorcontrol_config.polarity_type, motorcontrol_config.hall_offset[0]);
                    } else if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                        printf("Star winding\nPolarity %d, Voltage %d\noffset clk %d (for positive voltage)\noffset cclk %d (for negative voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    } else {
                        printf("Delta winding\nPolarity %d, Voltage %d\noffset clk %d (for negative voltage)\noffset cclk %d (for positive voltage)\n", motorcontrol_config.polarity_type, voltage, motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    }
                    break;
                    //reverse voltage
                case 'r':
                    voltage = -voltage;
                    if (motorcontrol_config.commutation_method == FOC && torque_flag) {
                        i_commutation.set_torque(voltage);
                        if (!isnull(i_tuning))
                            i_tuning.set_torque(voltage);
                        printf("torque %d\n", voltage);
                    } else {
                        i_commutation.set_voltage(voltage);
                        if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
                            printf("voltage: %i, offset clk: %d\n", voltage, motorcontrol_config.hall_offset[0]);
                        else
                            printf("voltage: %i, offset cclk: %d\n", voltage, motorcontrol_config.hall_offset[1]);
                    }
                    break;
                    //set sensor offset
                case 's':
                    offset = value;
                    i_commutation.set_sensor_offset(offset);
                    printf("Sensor offset: %d\n", offset);
                    break;
                    //set torque
                case 't':
                    if (motorcontrol_config.commutation_method == FOC) {
                        field_control_flag = 1;
                        voltage = value * sign;
                        i_commutation.set_torque(voltage);
                        torque_flag = 1;
                        if (!isnull(i_tuning))
                            i_tuning.set_torque(voltage);
                        printf("torque %d\n", voltage);
                    }
                    break;
                    //restart watchdog
                case 'y':
                    i_commutation.set_voltage(0);
                    i_commutation.restart_watchdog();
                    printf("Watchdog restarted\n");
                    break;
                    //go to 0 position
                case 'z':
                    if (!isnull(i_position_control)) {
                        /* Set new target position for profile position control */
                        set_profile_position(0, 200, 200, 200, i_position_control);
                        printf("Returned to 0\n");
                        i_position_control.disable_position_ctrl();
                        delay_milliseconds(500);
                        i_commutation.set_fets_state(1);
                    } else {
                        printf("No position control\n");
                    }
                    break;
                    //set voltage
                case 0:
                    torque_flag = 0;
                    voltage = value * sign;
                    i_commutation.set_voltage(voltage);
                    if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
                        printf("voltage: %i, offset clk: %d\n", voltage, motorcontrol_config.hall_offset[0]);
                    else
                        printf("voltage: %i, offset cclk: %d\n", voltage, motorcontrol_config.hall_offset[1]);
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
            if (motorcontrol_config.commutation_method == SINE)
                xscope_int(VELOCITY, velocity);
            //
            //            //torque display
            //            if (motorcontrol_config.commutation_method == FOC) {
            //                int torque = i_commutation.get_torque_actual();
            //                int actual_voltage, error_torque_integral;
            //                {actual_voltage, error_torque_integral} = i_commutation.get_torque_control_out();
            //                xscope_int(VOLTAGE, actual_voltage);
            //                xscope_int(TORQUE, torque);
            //                xscope_int(TARGET_TORQUE, target_torque);
            //                xscope_int(ERROR_TORQUE, target_torque-torque);
            //            }

            //postion limiter
            if (position_limit > 0) {
                if (count >= position_limit && velocity > 10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit >= 0) {
                        print_position_limit = -1;
                        printf("up limit reached\n");
                    }
                    position_limit_reached = 1;
                } else if (count <= -position_limit && velocity < -10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit <= 0) {
                        print_position_limit = 1;
                        printf("down limit reached\n");
                    }
                    position_limit_reached = 1;
                } else {
                    position_limit_reached = 0;
                }
            }

            //current measurement
            if (!isnull(i_adc)) {
                {phase_b, phase_c} = i_adc.get_currents();
                //                { adc_a, adc_b } = i_adc.get_external_inputs();

                if (current_sampling > 0) {
                    current_sampling--;
                    //find the peak current by sampling every [period] microseconds [times] times
                    if (phase_b > peak_current)
                        peak_current = phase_b;
                    else if (phase_b < -peak_current)
                        peak_current = -phase_b;
                }
                if (motorcontrol_config.commutation_method == SINE) {
                    xscope_int(PHASE_B, phase_b);
                    xscope_int(PHASE_C, phase_c);
                }
                //                xscope_int(PEAK_CURRENT, last_peak_current);
                //                xscope_int(TORQUE_SENSOR, (adc_b-adc_a-torque_offset)/4);
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
                            printf("offset pos %d, %d -> %d\n", offset_pos, last_min_current_pos, min_current_pos);
                            if (min_current_pos >= last_min_current_pos) {
                                if (step_pos > 0) { //now search by decreasing the offset
                                    step_pos = -step_pos;
                                    offset_pos = start_offset_pos;
                                } else { //offset pos tuning is done
                                    tuning_done_pos = 1;
                                    position_limit_reached = 1;
                                    printf("tuning pos done %d\n", best_offset_pos);
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
                            printf("offset neg %d, %d -> %d\n", offset_neg, last_min_current_neg, min_current_neg);
                            if (min_current_neg >= last_min_current_neg) {
                                if (step_neg > 0) { //now search by decreasing the offset
                                    step_neg = -step_neg;
                                    offset_neg = start_offset_neg;
                                } else { //offset neg tuning is done
                                    tuning_done_neg = 1;
                                    position_limit_reached = 1;
                                    printf("tuning neg done %d\n", best_offset_neg);
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
                        if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                            motorcontrol_config.hall_offset[0] = best_offset_pos;
                            motorcontrol_config.hall_offset[1] = best_offset_neg;
                        } else {
                            motorcontrol_config.hall_offset[1] = best_offset_pos;
                            motorcontrol_config.hall_offset[0] = best_offset_neg;
                        }
                        printf("Tuning done\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                            offset = i_commutation.set_sensor_offset(-1);
                            motorcontrol_config.hall_offset[0] = 0;
                            motorcontrol_config.hall_offset[1] = 0;
                            printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                        }
                        i_commutation.set_config(motorcontrol_config);
                    } else {
                        last_peak_current = peak_current; //for displaying peak current
                        peak_current = 0;       // reset
                        current_sampling = 200; // current sampling
                        i_commutation.set_config(motorcontrol_config); //update offset
                    }
                } //end new measured peak current
            } //end tuning

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

int find_peak_current(interface ADCInterface client i_adc, int period, int times)
{   //find the peak current by sampling every [period] microseconds [times] times
    int peak_current = 0;
    for (int i=0; i<times; i++) {
        int current;
        {current, void} = i_adc.get_currents();
        if (current > peak_current)
            peak_current = current;
        else if (current < -peak_current)
            peak_current = -current;
        delay_microseconds(period);
    }
    return peak_current;
}


int auto_tuning_current(interface MotorcontrolInterface client i_commutation, interface ADCInterface client i_adc, int voltage)
{
    int step = 2;
    int start_offset = 0;
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
        start_offset = motorcontrol_config.hall_offset[0];
    else
        start_offset = motorcontrol_config.hall_offset[1];
    //starting peak current and offset
    int best_offset = start_offset;
    int min_current = find_peak_current(i_adc, 1000, 200);
    int last_min_current;
    //search forward then backward
    for (int j=0; j<2; j++) {
        int offset = start_offset;
        do {
            last_min_current = min_current;
            for (int i=0; i<25; i++) {
                unsigned int pos_offset = (offset & 4095); //positive offset
                //update offset
                if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
                    motorcontrol_config.hall_offset[0] = pos_offset;
                else
                    motorcontrol_config.hall_offset[1] = pos_offset;
                i_commutation.set_config(motorcontrol_config);
                //find the peak current
                int peak_current = find_peak_current(i_adc, 1000, 200);
                //update minimum current and best offset
                if (peak_current < min_current) {
                    min_current = peak_current;
                    best_offset = pos_offset;
                }
                offset += step;
            }
        } while (min_current < last_min_current);
        step = -step;
    }
    if (motorcontrol_config.commutation_method == FOC || (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) || (voltage <= 0 && motorcontrol_config.bldc_winding_type == DELTA_WINDING))
        motorcontrol_config.hall_offset[0] = best_offset;
    else
        motorcontrol_config.hall_offset[1] = best_offset;
    i_commutation.set_config(motorcontrol_config);
    return best_offset;
}


[[combinable]]
 void tuning_service(interface TuningInterface server i_tuning, interface MotorcontrolInterface client i_commutation,
                     interface ADCInterface client ?i_adc, interface PositionControlInterface client ?i_position_control,
                     interface HallInterface client ?i_hall, interface BISSInterface client ?i_biss, interface AMSInterface client ?i_ams)
{
    timer t;
    unsigned ts;
    t :> ts;
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();
    int count = 0;
    int torque_offset = 0;
    int velocity = 0;
    int position_limit = 0;
    int position_limit_reached = 0;
    int print_position_limit = 0;
    int voltage = 0;
    int target_torque = 0;
    int current_sampling = 0;
    int peak_current = 0;
    int last_peak_current = 0;
    int phase_b, phase_c;
    int adc_a, adc_b;
    int enable_tuning = 0;
    int best_offset_pos, best_offset_neg, offset_pos, offset_neg, start_offset_pos, start_offset_neg;
    int min_current_pos, last_min_current_pos, min_current_neg, last_min_current_neg;
    int range_pos, range_neg, step_pos, step_neg;
    int tuning_done_pos, tuning_done_neg;

    if (!isnull(i_position_control)) {
        /* Initialise the position profile generator */
        ProfilerConfig profiler_config;
        profiler_config.polarity = POLARITY;
        profiler_config.max_position = MAX_POSITION_LIMIT;
        profiler_config.min_position = MIN_POSITION_LIMIT;
        profiler_config.max_velocity = MAX_VELOCITY;
        profiler_config.max_acceleration = MAX_ACCELERATION;
        profiler_config.max_deceleration = MAX_DECELERATION;
        init_position_profiler(profiler_config, i_position_control, i_hall, null, i_biss, i_ams);
    }

    if (!isnull(i_adc)) {
        { adc_a, adc_b } = i_adc.get_external_inputs();
        torque_offset = adc_b - adc_a;
        torque_offset = 0;
    }

    while(1) {
        select {
        case t when timerafter(ts) :> void:
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
            if (motorcontrol_config.commutation_method == SINE)
                xscope_int(VELOCITY, velocity);
//
//            //torque display
//            if (motorcontrol_config.commutation_method == FOC) {
//                int torque = i_commutation.get_torque_actual();
//                int actual_voltage, error_torque_integral;
//                {actual_voltage, error_torque_integral} = i_commutation.get_torque_control_out();
//                xscope_int(VOLTAGE, actual_voltage);
//                xscope_int(TORQUE, torque);
//                xscope_int(TARGET_TORQUE, target_torque);
//                xscope_int(ERROR_TORQUE, target_torque-torque);
//            }

            //postion limiter
            if (position_limit > 0) {
                if (count >= position_limit && velocity > 10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit >= 0) {
                        print_position_limit = -1;
                        printf("up limit reached\n");
                    }
                    position_limit_reached = 1;
                } else if (count <= -position_limit && velocity < -10) {
                    i_commutation.set_voltage(0);
                    if (print_position_limit <= 0) {
                        print_position_limit = 1;
                        printf("down limit reached\n");
                    }
                    position_limit_reached = 1;
                } else {
                    position_limit_reached = 0;
                }
            }

            //current measurement
            if (!isnull(i_adc)) {
                {phase_b, phase_c} = i_adc.get_currents();
//                { adc_a, adc_b } = i_adc.get_external_inputs();

                if (current_sampling > 0) {
                    current_sampling--;
                    //find the peak current by sampling every [period] microseconds [times] times
                    if (phase_b > peak_current)
                        peak_current = phase_b;
                    else if (phase_b < -peak_current)
                        peak_current = -phase_b;
                }
                if (motorcontrol_config.commutation_method == SINE) {
                    xscope_int(PHASE_B, phase_b);
                    xscope_int(PHASE_C, phase_c);
                }
//                xscope_int(PEAK_CURRENT, last_peak_current);
//                xscope_int(TORQUE_SENSOR, (adc_b-adc_a-torque_offset)/4);
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
                            printf("offset pos %d, %d -> %d\n", offset_pos, last_min_current_pos, min_current_pos);
                            if (min_current_pos >= last_min_current_pos) {
                                if (step_pos > 0) { //now search by decreasing the offset
                                    step_pos = -step_pos;
                                    offset_pos = start_offset_pos;
                                } else { //offset pos tuning is done
                                    tuning_done_pos = 1;
                                    position_limit_reached = 1;
                                    printf("tuning pos done %d\n", best_offset_pos);
                                }
                            }
                            range_pos = 25;
                            last_min_current_pos = min_current_pos;
                        }
                        range_pos--;
                        offset_pos += step_pos;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_pos);
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
                            printf("offset neg %d, %d -> %d\n", offset_neg, last_min_current_neg, min_current_neg);
                            if (min_current_neg >= last_min_current_neg) {
                                if (step_neg > 0) { //now search by decreasing the offset
                                    step_neg = -step_neg;
                                    offset_neg = start_offset_neg;
                                } else { //offset neg tuning is done
                                    tuning_done_neg = 1;
                                    position_limit_reached = 1;
                                    printf("tuning neg done %d\n", best_offset_neg);
                                }
                            }
                            range_neg = 25;
                            last_min_current_neg = min_current_neg;
                        }
                        range_neg--;
                        offset_neg += step_neg;
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset(offset_neg);
                        } else {
                            update_offset(motorcontrol_config, voltage, (offset_neg & 4095));
                        }
                    }

                    if((tuning_done_pos + tuning_done_neg) >= 2) {//tuning is done
                        voltage = 0;
                        i_commutation.set_voltage(voltage);
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
                        if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                            motorcontrol_config.hall_offset[0] = best_offset_pos;
                            motorcontrol_config.hall_offset[1] = best_offset_neg;
                        } else {
                            motorcontrol_config.hall_offset[1] = best_offset_pos;
                            motorcontrol_config.hall_offset[0] = best_offset_neg;
                        }
                        printf("Tuning done\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                        if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                            i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                            motorcontrol_config.hall_offset[0] = 0;
                            motorcontrol_config.hall_offset[1] = 0;
                            printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                        }
                        i_commutation.set_config(motorcontrol_config);
                    } else {
                        last_peak_current = peak_current; //for displaying peak current
                        peak_current = 0;       // reset
                        current_sampling = 200; // current sampling
                        i_commutation.set_config(motorcontrol_config); //update offset
                    }
                } //end new measured peak current
            } //end tuning

            if (current_sampling <= 0) {
                last_peak_current = peak_current;
                current_sampling = 200;
                peak_current = 0;
            }
            t :> ts;
            ts += USEC_STD * 1000;
            break;

        case i_tuning.tune(int in_voltage):
            if (!isnull(i_adc)) {
                voltage = in_voltage;
                if (voltage && enable_tuning == 0) {
                    motorcontrol_config = i_commutation.get_config();
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        start_offset_pos = i_commutation.set_sensor_offset(-1);
                        start_offset_neg = start_offset_pos;
                    } else if (voltage >= 0 && motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                        start_offset_pos = motorcontrol_config.hall_offset[0];
                        start_offset_neg = motorcontrol_config.hall_offset[1];
                    } else {
                        start_offset_pos = motorcontrol_config.hall_offset[1];
                        start_offset_neg = motorcontrol_config.hall_offset[0];
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
                    printf("Starting auto tuning...\n");
                } else {
                    enable_tuning = 0;
                    if (motorcontrol_config.bldc_winding_type == STAR_WINDING) {
                        motorcontrol_config.hall_offset[0] = best_offset_pos;
                        motorcontrol_config.hall_offset[1] = best_offset_neg;
                    } else {
                        motorcontrol_config.hall_offset[1] = best_offset_pos;
                        motorcontrol_config.hall_offset[0] = best_offset_neg;
                    }
                    printf("Tuning aborted!\nauto tuned offset clk: %d\nauto tuned offset cclk: %d\n", motorcontrol_config.hall_offset[0], motorcontrol_config.hall_offset[1]);
                    if (motorcontrol_config.commutation_method == FOC && motorcontrol_config.commutation_sensor != HALL_SENSOR) {
                        i_commutation.set_sensor_offset((best_offset_pos+best_offset_neg)/2);
                        motorcontrol_config.hall_offset[0] = 0;
                        motorcontrol_config.hall_offset[1] = 0;
                        printf("mean offset: %d\n", (best_offset_pos+best_offset_neg)/2);
                    }
                    i_commutation.set_config(motorcontrol_config);
                }
            }
            break;

        case i_tuning.set_position(int in_position):
            if (!isnull(i_position_control)) {
                /* Set new target position for profile position control */
                set_profile_position(0, 200, 200, 200, i_position_control);
                printf("Returned to 0\n");
                i_position_control.disable_position_ctrl();
                delay_milliseconds(500);
                i_commutation.set_fets_state(1);
            } else {
                printf("No position control\n");
            }
            break;

        case i_tuning.set_limit(int in_limit):
            if (motorcontrol_config.commutation_sensor == BISS_SENSOR && !isnull(i_biss)) {
                i_biss.reset_biss_position(0);
            } else if (motorcontrol_config.commutation_sensor == AMS_SENSOR && !isnull(i_ams)) {
                i_ams.reset_ams_position(0);
            } else if (motorcontrol_config.commutation_sensor == HALL_SENSOR && !isnull(i_hall)) {
                i_hall.reset_hall_absolute_position(0);
            }
            if (in_limit < 0) {
                position_limit = in_limit;
                printf("Position limit disabled\n");
            } else if (in_limit > 0) {
                printf("Position limited to %d ticks around here\n", in_limit);
                position_limit = in_limit;
            } else {
                printf("Position limited around here\n");
            }
            break;

        case i_tuning.set_torque(int in_torque):
            target_torque = in_torque;
            break;

        case i_tuning.get_velocity() -> int out_velocity:
            out_velocity = velocity;
            break;
        }
    }
}
