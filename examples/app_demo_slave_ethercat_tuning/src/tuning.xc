/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>


int auto_offset(interface MotorcontrolInterface client i_motorcontrol)
{
    printf("Sending offset_detection command ...\n");
    i_motorcontrol.set_offset_detection_enabled();

    delay_milliseconds(30000);

    int offset=i_motorcontrol.set_calib(0);
    printf("Detected offset is: %i\n", offset);
//    printf(">>  CHECK PROPER OFFSET POLARITY ...\n");
    int proper_sensor_polarity=i_motorcontrol.get_sensor_polarity_state();
    if(proper_sensor_polarity == 1) {
        printf(">>  PROPER POSITION SENSOR POLARITY ...\n");
        i_motorcontrol.set_torque_control_enabled();
    } else {
        offset = -1;
        printf(">>  WRONG POSITION SENSOR POLARITY ...\n");
    }
    return offset;
}


void run_offset_tuning(ProfilerConfig profiler_config, interface MotorcontrolInterface client i_motorcontrol,
                      interface PositionVelocityCtrlInterface client i_position_control,
                      client interface PositionFeedbackInterface ?i_position_feedback,
                      client interface PositionLimiterInterface ?i_position_limiter,
                      chanend pdo_out, chanend pdo_in, client interface i_coe_communication i_coe)
{
    delay_milliseconds(500);
    printf(">>   SOMANET OFFSET TUNING SERVICE STARTING...\n");


    //variables
    int brake_flag = 0;
    int torque_control_flag = 0;
    int position_ctrl_flag = 0;
    int motor_polarity = 0, sensor_polarity = 0;
    int target_torque = 0;
    int position_limit = 0;
    int status_mux = 0;
    int sign = 1;
    //timing
    timer t;
    unsigned ts;
    t :> ts;
    //parameters structs
    MotorcontrolConfig motorcontrol_config = i_motorcontrol.get_config();
    PositionFeedbackConfig position_feedback_config;
    PosVelocityControlConfig pos_velocity_ctrl_config;
    if (!isnull(i_position_control)) {
        pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
    }
    DownstreamControlData downstream_control_data;
    downstream_control_data.velocity_cmd = 0;
    downstream_control_data.torque_cmd = 0;
    downstream_control_data.offset_torque = 0;
    downstream_control_data.position_cmd = 0;
    UpstreamControlData upstream_control_data;
    ctrl_proto_values_t InOut = init_ctrl_proto();
    InOut = init_ctrl_proto();

    //brake and motorcontrol enable
    i_motorcontrol.set_brake_status(brake_flag);
    if (torque_control_flag == 1){
        i_motorcontrol.set_torque_control_enabled();
    }


    /* Initialise the position profile generator */
    if (!isnull(i_position_feedback)) {
        profiler_config.ticks_per_turn = i_position_feedback.get_ticks_per_turn();
        init_position_profiler(profiler_config);

        position_feedback_config = i_position_feedback.get_config();
        switch(position_feedback_config.sensor_type) {
        case BISS_SENSOR:
            sensor_polarity = position_feedback_config.biss_config.polarity;
            break;
        case CONTELEC_SENSOR:
            sensor_polarity = position_feedback_config.contelec_config.polarity;
            break;
        }
    }

    /* Initialise local variables */
    if (motorcontrol_config.polarity_type == NORMAL_POLARITY) {
        motor_polarity = 0;
    } else {
        motor_polarity = 1;
    }
    if (!isnull(i_position_limiter)) {
        position_limit = i_position_limiter.get_limit();
    }



    fflush(stdout);
    //main loop
    while (1) {
        select {
        case t when timerafter(ts) :> void:
            //get position and velocity
            upstream_control_data = i_position_control.update_control_data(downstream_control_data);

            //set output values
            InOut.velocity_actual = upstream_control_data.velocity;
            InOut.torque_actual = upstream_control_data.computed_torque;
            InOut.position_actual = upstream_control_data.position;
            InOut.user1_out = upstream_control_data.sensor_torque;
            InOut.status_word = status_mux;

            switch(status_mux) { //send offsets and other data in the user4 pdo
            case 0: //send flags
                InOut.user4_out = (motor_polarity<<4)+(sensor_polarity<<3)+(torque_control_flag<<2)+(position_ctrl_flag<<1)+brake_flag;
                break;
            case 1: //send offset
                InOut.user4_out = motorcontrol_config.commutation_angle_offset;
                break;
            case 2: //pole pairs
                InOut.user4_out = motorcontrol_config.pole_pair;
                break;
            case 3: //target torque
                InOut.user4_out = target_torque;
                break;
            case 4:
                InOut.user4_out = position_limit;
                break;
            default: //target position
                InOut.user4_out = downstream_control_data.position_cmd;
                status_mux = -1;
                break;
            }
            status_mux++;

            /* Read/Write packets to ethercat Master application */
            ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);

            //receive mode and value
            char mode = 0;
            char mode_2 = 0;
            char mode_3 = 0;
            int value = 0;
            if (InOut.operation_mode == 6) { //no mode
                InOut.operation_mode_display &= 0x7f; //unset the ACK bit
            } else { //new mode received
                if ((InOut.operation_mode_display  & 0x80) == 0) {//if the ACK bit is not set
                    InOut.operation_mode_display |= 0x80; //set the ACK bit
                    mode = InOut.operation_mode;
                    mode_2 = InOut.control_word & 0x00ff;
                    mode_3 = InOut.control_word >> 8;
                    value = sext(InOut.target_position, 32);
                }
            }

            //execute command
            if (mode != 0) {
                if (mode_2 != 0) {
                    if (mode_3 != 0) {
                        printf("%c %c %c %d\n", mode, mode_2, mode_3, value);
                    } else {
                        printf("%c %c %d\n", mode, mode_2, value);
                    }
                } else {
                    printf("%c %d\n", mode, value);
                }
            }
            switch(mode) {
            //go to position directly
            case 'p':
                downstream_control_data.position_cmd = value*sign;
                downstream_control_data.offset_torque = 0;
                switch(mode_2) {
                case 'p':
                    if (!isnull(i_position_feedback)) {
                        position_ctrl_flag = 1;
                        torque_control_flag = 0;
                        printf("Go to %d with profile\n", downstream_control_data.position_cmd);
                        set_profile_position(downstream_control_data, 1000, 1000, 1000, i_position_control);
                    }
                    break;
                default:
                    i_position_control.update_control_data(downstream_control_data);
                    printf("Go to %d\n", downstream_control_data.position_cmd);
                    break;
                }
                break;

            //set velocity
            case 'v':
                downstream_control_data.velocity_cmd = value;
                downstream_control_data.position_cmd = downstream_control_data.velocity_cmd; //for display
                downstream_control_data.offset_torque = 0;
                i_position_control.update_control_data(downstream_control_data);
                printf("set velocity %d\n", downstream_control_data.velocity_cmd);
                break;

            //pid coefficients
            case 'k':
                switch(mode_2) {
                case 'p': //position
                    switch(mode_3) {
                    case 'p':
                        pos_velocity_ctrl_config.int10_P_position = value;
                        break;
                    case 'i':
                        pos_velocity_ctrl_config.int10_I_position = value;
                        break;
                    case 'd':
                        pos_velocity_ctrl_config.int10_D_position = value;
                        break;
                    default:
                        printf("Pp:%d Pi:%d Pd:%d\n", pos_velocity_ctrl_config.int10_P_position, pos_velocity_ctrl_config.int10_I_position, pos_velocity_ctrl_config.int10_D_position);
                        break;
                    }
                    break;
                case 'v': //velocity
                    switch(mode_2) {
                    case 'p':
                        pos_velocity_ctrl_config.int10_P_velocity = value;
                        break;
                    case 'i':
                        pos_velocity_ctrl_config.int10_I_velocity = value;
                        break;
                    case 'd':
                        pos_velocity_ctrl_config.int10_D_velocity = value;
                        break;
                    default:
                        printf("Kp:%d Ki:%d Kd:%d\n", pos_velocity_ctrl_config.int10_P_velocity, pos_velocity_ctrl_config.int10_I_velocity, pos_velocity_ctrl_config.int10_D_velocity);
                        break;
                    }
                    break;
                }
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                break;
            //velocity pid limits
            case 'L':
                switch(mode_2) {
                case 'p':
                    pos_velocity_ctrl_config.int21_P_error_limit_velocity = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_velocity, pos_velocity_ctrl_config.int21_I_error_limit_velocity
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_velocity, pos_velocity_ctrl_config.int21_max_torque);
                    break;
                case 'i':
                    pos_velocity_ctrl_config.int21_I_error_limit_velocity = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_velocity, pos_velocity_ctrl_config.int21_I_error_limit_velocity
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_velocity, pos_velocity_ctrl_config.int21_max_torque);
                    break;
                case 'l':
                    pos_velocity_ctrl_config.int22_integral_limit_velocity = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_velocity, pos_velocity_ctrl_config.int21_I_error_limit_velocity
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_velocity, pos_velocity_ctrl_config.int21_max_torque);
                    break;
                case 'c':
                    pos_velocity_ctrl_config.int21_max_torque = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_velocity, pos_velocity_ctrl_config.int21_I_error_limit_velocity
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_velocity, pos_velocity_ctrl_config.int21_max_torque);
                    break;
                default:
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_velocity, pos_velocity_ctrl_config.int21_I_error_limit_velocity
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_velocity, pos_velocity_ctrl_config.int21_max_torque);
                    break;
                }
                break;
            //position pid limits
            case 'i':
                switch(mode_2) {
                case 'p':
                    pos_velocity_ctrl_config.int21_P_error_limit_position = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_position, pos_velocity_ctrl_config.int21_I_error_limit_position
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_position, pos_velocity_ctrl_config.int21_max_speed);
                    break;
                case 'i':
                    pos_velocity_ctrl_config.int21_I_error_limit_position = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_position, pos_velocity_ctrl_config.int21_I_error_limit_position
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_position, pos_velocity_ctrl_config.int21_max_speed);
                    break;
                case 'l':
                    pos_velocity_ctrl_config.int22_integral_limit_position = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_position, pos_velocity_ctrl_config.int21_I_error_limit_position
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_position, pos_velocity_ctrl_config.int21_max_speed);
                    break;
                case 'c':
                    pos_velocity_ctrl_config.int21_max_speed = value * sign;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_position, pos_velocity_ctrl_config.int21_I_error_limit_position
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_position, pos_velocity_ctrl_config.int21_max_speed);
                    break;
                default:
                    printf("P_e_lim:%d I_e_lim:%d int_lim:%d cmd_lim:%d\n", pos_velocity_ctrl_config.int21_P_error_limit_position, pos_velocity_ctrl_config.int21_I_error_limit_position
                                                                          , pos_velocity_ctrl_config.int22_integral_limit_position, pos_velocity_ctrl_config.int21_max_speed);
                    break;
                }
                break;
            //step command
            case 'c':
                switch(mode_2) {
                    case 'p':
                        printf("position cmd: %d to %d (range:-32767 to 32767)\n", value*sign, -value*sign);
                        downstream_control_data.offset_torque = 0;
                        downstream_control_data.position_cmd = value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1000);
                        downstream_control_data.position_cmd = -value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(1000);
                        downstream_control_data.position_cmd = 0;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                    case 'v':
                        printf("velocity cmd: %d to %d (range:-32767 to 32767)\n", value*sign, -value*sign);
                        downstream_control_data.offset_torque = 0;
                        downstream_control_data.velocity_cmd = value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(500);
                        downstream_control_data.velocity_cmd = -value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(500);
                        downstream_control_data.velocity_cmd = 0;//value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                    case 't':
                        printf("torque cmd: %d to %d (range:-32767 to 32767)\n", value*sign, -value*sign);
                        downstream_control_data.torque_cmd = value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(400);
                        downstream_control_data.torque_cmd = -value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(400);
                        downstream_control_data.torque_cmd = 0;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                    case 'o':
                        printf("offset-torque cmd: %d to %d\n", value*sign, -value*sign);
                        downstream_control_data.position_cmd = 0;
                        downstream_control_data.velocity_cmd = 0;
                        downstream_control_data.offset_torque = value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(200);
                        downstream_control_data.offset_torque = -value*sign;
                        i_position_control.update_control_data(downstream_control_data);
                        delay_milliseconds(200);
                        downstream_control_data.offset_torque = 0;
                        i_position_control.update_control_data(downstream_control_data);
                        break;
                        }
                break;

            //enable
            case 'e':
                if (value == 1) {
                    switch(mode_2) {
                        case 'p':
                            position_ctrl_flag = 1;
                            torque_control_flag = 0;
                            downstream_control_data.position_cmd = upstream_control_data.position;
                            i_position_control.enable_position_ctrl();
                            printf("position ctrl enabled\n");
                            break;
                        case 'v':
                            position_ctrl_flag = 1;
                            torque_control_flag = 0;
                            downstream_control_data.velocity_cmd = 0;
                            downstream_control_data.position_cmd = downstream_control_data.velocity_cmd; //for display
                            i_position_control.enable_velocity_ctrl();
                            printf("velocity ctrl enabled\n");
                            break;
                        case 't':
                            position_ctrl_flag = 1;
                            torque_control_flag = 0;
                            i_position_control.enable_torque_ctrl();
                            printf("torque ctrl enabled\n");
                            break;
                    }
                } else {
                    position_ctrl_flag = 0;
                    torque_control_flag = 0;
                    brake_flag = 0;
                    i_position_control.disable();
                    printf("position ctrl disabled\n");
                }
                break;

            //pole pairs
            case 'P':
                if (!isnull(i_position_feedback)) {
                    motorcontrol_config.pole_pair = value;
                    position_feedback_config.biss_config.pole_pairs = value;
                    position_feedback_config.contelec_config.pole_pairs = value;
                    brake_flag = 0;
                    torque_control_flag = 0;
                    i_position_feedback.set_config(position_feedback_config);
                    i_motorcontrol.set_config(motorcontrol_config);
                }
                break;

            //direction (motor polarity)
            case 'd':
                if (motorcontrol_config.polarity_type == NORMAL_POLARITY){
                    motorcontrol_config.polarity_type = INVERTED_POLARITY;
                    motor_polarity = 1;
                } else {
                    motorcontrol_config.polarity_type = NORMAL_POLARITY;
                    motor_polarity = 0;
                }
                i_motorcontrol.set_config(motorcontrol_config);
                torque_control_flag = 0;
                brake_flag = 0;
                break;

            //sensor polarity
            case 's':
                if (!isnull(i_position_feedback)) {
                    if (sensor_polarity == 0) {
                        position_feedback_config.biss_config.polarity = 1;
                        position_feedback_config.contelec_config.polarity = 1;
                        sensor_polarity = 1;
                    } else {
                        position_feedback_config.biss_config.polarity = 0;
                        position_feedback_config.contelec_config.polarity = 0;
                        sensor_polarity = 0;
                    }
                    i_position_feedback.set_config(position_feedback_config);
                }
                break;

            //position limiter
            case 'l':
                if (!isnull(i_position_limiter)) {
                    i_position_limiter.set_limit(value * sign);
                    position_limit = i_position_limiter.get_limit();
                }
                break;

            //auto offset tuning
            case 'a':
                motorcontrol_config.commutation_angle_offset = auto_offset(i_motorcontrol);
                break;

            //set offset
            case 'o':
                motorcontrol_config.commutation_angle_offset = value;
                i_motorcontrol.set_config(motorcontrol_config);
                brake_flag = 0;
                torque_control_flag = 0;
                printf("set offset to %d\n", value);
                break;

            //reverse torque
            case 'r':
                target_torque = -target_torque;
                i_motorcontrol.set_torque(target_torque);
                printf("Torque %d\n", target_torque);
                break;

            //enable and disable torque controller
            case 't':
                if (mode_2 == 's') {
                    torque_control_flag = 0;
                    i_motorcontrol.set_safe_torque_off_enabled();
                } else {
                    if (torque_control_flag == 0 || value == 1) {
                        torque_control_flag = 1;
                        i_motorcontrol.set_torque_control_enabled();
                        printf("Torque control activated\n");
                    } else {
                        torque_control_flag = 0;
                        i_motorcontrol.set_torque_control_disabled();
                        printf("Torque control deactivated\n");
                    }
                }
                break;
            //set brake
            case 'b':
                if (brake_flag == 0 || value == 1) {
                    brake_flag = 1;
                    printf("Brake released\n");
                } else {
                    brake_flag = 0;
                    printf("Brake blocking\n");
                }
                i_motorcontrol.set_brake_status(brake_flag);
                break;

            //set torque
            case '@':
                if (position_ctrl_flag) {
                    position_ctrl_flag = 0;
                    i_position_control.disable();
                    delay_milliseconds(500);
                    brake_flag = 1;
                    torque_control_flag = 1;
                    i_motorcontrol.set_torque(0);
                    i_motorcontrol.set_torque_control_enabled();
                    i_motorcontrol.set_brake_status(brake_flag);
                }
                target_torque = value*sign;
                if (target_torque) {
                    if (brake_flag == 0) {
                        brake_flag = 1;
                        i_motorcontrol.set_brake_status(brake_flag);
                    }
                    if (torque_control_flag == 0) {
                        torque_control_flag = 1;
                        i_motorcontrol.set_torque_control_enabled();
                    }
                }
                i_motorcontrol.set_torque(target_torque);
                printf("Torque %d\n", target_torque);
                break;
            }


            t :> ts;
            ts += USEC_STD * 1000;
            break;
        } //end select
    } //end while(1)
}


void position_limiter(int position_limit, interface PositionLimiterInterface server i_position_limiter, client interface MotorcontrolInterface i_motorcontrol)
{
    timer t;
    unsigned ts;
    t :> ts;
    int print_position_limit = 0;
    int count = 0;
    int velocity = 0;

    while(1) {
        select {
        case t when timerafter(ts) :> void:

            count = i_motorcontrol.get_position_actual();
            velocity = i_motorcontrol.get_velocity_actual();

            //postion limiter
            if (position_limit > 0) {
                if (count >= position_limit && velocity > 10) {
                    i_motorcontrol.set_torque_control_disabled();
                    i_motorcontrol.set_safe_torque_off_enabled();
                    i_motorcontrol.set_brake_status(0);
                    if (print_position_limit >= 0) {
                        print_position_limit = -1;
                        printf("up limit reached\n");
                    }
                } else if (count <= -position_limit && velocity < -10) {
                    i_motorcontrol.set_torque_control_disabled();
                    i_motorcontrol.set_safe_torque_off_enabled();
                    i_motorcontrol.set_brake_status(0);
                    if (print_position_limit <= 0) {
                        print_position_limit = 1;
                        printf("down limit reached\n");
                    }
                }
            }
            t :> ts;
            ts += USEC_FAST * 1000;
            break;

        case i_position_limiter.set_limit(int in_limit):
            if (in_limit < 0) {
                position_limit = in_limit;
                printf("Position limit disabled\n");
            } else if (in_limit > 0) {
                printf("Position limited to %d ticks\n", in_limit);
                position_limit = in_limit;
            }
            break;

        case i_position_limiter.get_limit() -> int out_limit:
            out_limit =  position_limit;
            break;

        }//end select
    }//end while
}//end function
