/*
 * tuning.xc
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */
#include <tuning.h>
#include <stdio.h>
#include <ctype.h>
#include <state_modes.h>


static int auto_offset(interface MotorcontrolInterface client i_motorcontrol)
{
    printf("Sending offset_detection command ...\n");
    i_motorcontrol.set_offset_detection_enabled();

    int offset = -1;
    while (offset == -1) {
        delay_milliseconds(50);//wait until offset is detected
        offset = i_motorcontrol.set_calib(0);
    }

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

static void brake_shake(interface MotorcontrolInterface client i_motorcontrol, int torque) {
    const int period = 50;
    i_motorcontrol.set_brake_status(1);
    for (int i=0 ; i<1 ; i++) {
        i_motorcontrol.set_torque(torque);
        delay_milliseconds(period);
        i_motorcontrol.set_torque(-torque);
        delay_milliseconds(period);
    }
    i_motorcontrol.set_torque(0);
}

/*
 * Function to call while in tuning opmode
 *
 * Assumption: this function is called every 1ms! (like the standard control does)
 *
 * FIXME
 * - get rid of {Upsream,Downstream}ControlData here, the data exchange should exclusively happen
 *   in the calling ethercat_drive_service.
 */
int tuning_handler(
        /* input */  uint16_t controlword, uint32_t control_extension, uint32_t target_position,
        /* output */ uint16_t &statusword, uint32_t &tuning_result,
        ProfilerConfig        &profiler_config, /* ??? */
        MotorcontrolConfig    &motorcontrol_config, /* ??? */
        UpstreamControlData     upstream_control_data,
        DownstreamControlData   downstream_control_data,
        interface MotorcontrolInterface client i_motorcontrol,
        interface PositionVelocityCtrlInterface client i_position_control,
        client interface PositionFeedbackInterface ?i_position_feedback,
        client interface PositionLimiterInterface ?i_position_limiter
    )
{
    static int motor_polarity = 0;
    static int sensor_polarity = 0;
    static int target_torque = 0;

    /* Lol! Flags! */
    static int brake_flag = 0;
    static int torque_control_flag = 0;
    static int position_ctrl_flag = 0;
    static int position_limit = 0;

    static uint8_t status_mux     = 0;
    static uint8_t status_display = 0;

    if (controlword == CMD_SHUTDOWN) {
        brake_flag = 0;
        torque_control_flag = 0;
        position_ctrl_flag = 0;
    }

    /* FIXME shouldn't be read every time */
    PosVelocityControlConfig pos_velocity_ctrl_config;
    if (!isnull(i_position_control)) {
        pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
    }

    PositionFeedbackConfig pos_feedback_config;
    if (!isnull(i_position_feedback)) {
        pos_feedback_config = i_position_feedback.get_config();
    }

#if 0 /* This is done by the upstream! */
    //get position and velocity
    upstream_control_data = i_position_control.update_control_data(downstream_control_data);

    //set output values
    InOut.velocity_actual = upstream_control_data.velocity;
    InOut.torque_actual = upstream_control_data.computed_torque;
    InOut.position_actual = upstream_control_data.position;
    InOut.user1_out = upstream_control_data.sensor_torque;
    InOut.status_word = status_mux;
#endif

    status_mux = ((status_mux + 1) >= 5) ? 0 : status_mux + 1;

    switch(status_mux) { //send offsets and other data in the user4 pdo
    case 0: //send flags
        tuning_result = (motor_polarity<<4)+(sensor_polarity<<3)+(torque_control_flag<<2)+(position_ctrl_flag<<1)+brake_flag;
        break;
    case 1: //send offset
        tuning_result = motorcontrol_config.commutation_angle_offset;
        break;
    case 2: //pole pairs
        tuning_result = motorcontrol_config.pole_pair;
        break;
    case 3: //target torque
        tuning_result = target_torque;
        break;
    case 4:
        tuning_result = position_limit;
        break;
    default: //target position
        tuning_result = target_position;
        break;
    }

    //receive mode and value

    char mode   = 0; //controlword & 0xff;
    char mode_2 = 0;
    char mode_3 = 0;
    //char opstat = (control_extension >> 16) & 0xff;
    int  value  = sext(target_position, 32);

    if (controlword == 0) { //no mode
         status_display = 0; //reset status display
     } else { //new mode received
         if (status_display != (controlword & 0xff)) {//if the ACK bit is not set
             status_display = (controlword & 0xff); //set controlword display
             value = sext(target_position, 32);
             mode   = controlword         & 0xff;
             mode_2 = (controlword >>  8) & 0xff;
             mode_3 = control_extension   & 0xff;
         }
     }

    statusword = ((status_display & 0xff) << 8) | (status_mux & 0xff);

    /* print command */
    if (mode >=32 && mode <= 126) { //mode is a printable ascii char
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

    /* execute command */

    switch(mode) {
    //go to position directly
    case 'p':
        downstream_control_data.position_cmd = value;
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
        } /* end mode2 */
        break;

    //set velocity
    case 'v':
        downstream_control_data.velocity_cmd = value;
        downstream_control_data.position_cmd = downstream_control_data.velocity_cmd; //for display
        i_position_control.update_control_data(downstream_control_data);
        printf("set velocity %d\n", downstream_control_data.velocity_cmd);
        break;

    //pid coefficients
    case 'k':
        pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
        switch(mode_2) {
        case 'p': //position
            switch(mode_3) {
            case 'p':
                pos_velocity_ctrl_config.P_pos = value;
                break;
            case 'i':
                pos_velocity_ctrl_config.I_pos = value;
                break;
            case 'd':
                pos_velocity_ctrl_config.D_pos = value;
                break;
            default:
                printf("Pp:%d Pi:%d Pd:%d\n", pos_velocity_ctrl_config.P_pos, pos_velocity_ctrl_config.I_pos, pos_velocity_ctrl_config.D_pos);
                break;
            }
            break;
            case 'v': //velocity
                switch(mode_3) {
                case 'p':
                    pos_velocity_ctrl_config.P_velocity = value;
                    break;
                case 'i':
                    pos_velocity_ctrl_config.I_velocity = value;
                    break;
                case 'd':
                    pos_velocity_ctrl_config.D_velocity = value;
                    break;
                default:
                    printf("Kp:%d Ki:%d Kd:%d\n", pos_velocity_ctrl_config.P_velocity, pos_velocity_ctrl_config.I_velocity, pos_velocity_ctrl_config.D_velocity);
                    break;
                }
                break;
        } /* end mode_2 */
        i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
        break;

        //limits
        case 'L':
            switch(mode_2) {
            case 'p': //position pid limits
                switch(mode_3) {
                case 'i':
                    pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                    pos_velocity_ctrl_config.integral_limit_pos = value;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    break;
                }
                break;

            case 'v': //velocity pid limits
                switch(mode_3) {
                case 'i':
                    pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                    pos_velocity_ctrl_config.integral_limit_velocity = value;
                    i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                    break;
                }
                break;

            //max torque
            case 't':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                pos_velocity_ctrl_config.max_torque = value;
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                break;
            //max speed
            case 's':
                pos_velocity_ctrl_config = i_position_control.get_position_velocity_control_config();
                pos_velocity_ctrl_config.max_speed = value;
                i_position_control.set_position_velocity_control_config(pos_velocity_ctrl_config);
                break;
            } /* end mode_2 */
            break;

        //step command
        case 'c':
            switch(mode_2) {
                case 'p':
                    printf("position cmd: %d to %d (range:-32767 to 32767)\n", value, -value);
                    downstream_control_data.position_cmd = value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(1000);
                    downstream_control_data.position_cmd = -value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(1000);
                    downstream_control_data.position_cmd = 0;
                    i_position_control.update_control_data(downstream_control_data);
                    break;
                case 'v':
                    printf("velocity cmd: %d to %d (range:-32767 to 32767)\n", value, -value);
                    downstream_control_data.velocity_cmd = value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(500);
                    downstream_control_data.velocity_cmd = -value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(500);
                    downstream_control_data.velocity_cmd = 0;//value;
                    i_position_control.update_control_data(downstream_control_data);
                    break;
                case 't':
                    printf("torque cmd: %d to %d (range:-32767 to 32767)\n", value, -value);
                    downstream_control_data.torque_cmd = value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(400);
                    downstream_control_data.torque_cmd = -value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(400);
                    downstream_control_data.torque_cmd = 0;
                    i_position_control.update_control_data(downstream_control_data);
                    break;
                case 'o':
                    printf("offset-torque cmd: %d to %d\n", value, -value);
                    downstream_control_data.position_cmd = 0;
                    downstream_control_data.velocity_cmd = 0;
                    downstream_control_data.offset_torque = value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(200);
                    downstream_control_data.offset_torque = -value;
                    i_position_control.update_control_data(downstream_control_data);
                    delay_milliseconds(200);
                    downstream_control_data.offset_torque = 0;
                    i_position_control.update_control_data(downstream_control_data);
                    break;
            } /* end mode_2 */
            break;

        //enable
        case 'e':
            if (value == 1) {
                switch(mode_2) {
                    case 'p':
                        position_ctrl_flag = 1;
                        torque_control_flag = 0;
                        downstream_control_data.position_cmd = upstream_control_data.position;
                        i_position_control.enable_position_ctrl(POS_PID_VELOCITY_CASCADED_CONTROLLER);
                        printf("position ctrl enabled\n");
                        break;
                    case 'v':
                        position_ctrl_flag = 1;
                        torque_control_flag = 0;
                        downstream_control_data.velocity_cmd = 0;
                        downstream_control_data.position_cmd = downstream_control_data.velocity_cmd; //for display
                        i_position_control.enable_velocity_ctrl(POS_PID_VELOCITY_CASCADED_CONTROLLER);
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
                pos_feedback_config.biss_config.pole_pairs = value;
                pos_feedback_config.contelec_config.pole_pairs = value;
                brake_flag = 0;
                torque_control_flag = 0;
                i_position_feedback.set_config(pos_feedback_config);
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
                    pos_feedback_config.biss_config.polarity = 1;
                    pos_feedback_config.contelec_config.polarity = 1;
                    sensor_polarity = 1;
                } else {
                    pos_feedback_config.biss_config.polarity = 0;
                    pos_feedback_config.contelec_config.polarity = 0;
                    sensor_polarity = 0;
                }
                i_position_feedback.set_config(pos_feedback_config);
            }
            break;

        //position limiter
        case 'l':
            if (!isnull(i_position_limiter)) {
                i_position_limiter.set_limit(value);
                position_limit = i_position_limiter.get_limit();
            }
            break;

        //auto offset tuning
        case 'a':
            brake_flag = 1;
            i_motorcontrol.set_brake_status(brake_flag);
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
            switch(mode_2) {
            case 's': //torque safe mode
                torque_control_flag = 0;
                i_motorcontrol.set_safe_torque_off_enabled();
                break;
            case 'o': //set torque offset
                downstream_control_data.offset_torque = value;
                break;
            default:
                if (torque_control_flag == 0 || value == 1) {
                    torque_control_flag = 1;
                    i_motorcontrol.set_torque_control_enabled();
                    printf("Torque control activated\n");
                } else {
                    torque_control_flag = 0;
                    i_motorcontrol.set_torque_control_disabled();
                    printf("Torque control deactivated\n");
                }
                break;
            } /* end mode_2 */
            break;

        //set brake
        case 'b':
            switch(mode_2) {
            case 's':
                brake_flag = 1;
                brake_shake(i_motorcontrol, value);
                break;
            default:
                if (brake_flag == 0 || value == 1) {
                    brake_flag = 1;
                    printf("Brake released\n");
                } else {
                    brake_flag = 0;
                    printf("Brake blocking\n");
                }
                i_motorcontrol.set_brake_status(brake_flag);
                break;
            } /* end mode_2 */
            break;

        //set zero position
        case 'z':
            if (!isnull(i_position_feedback)) {
//                    i_position_feedback.send_command(CONTELEC_CONF_NULL, 0, 0);
                i_position_feedback.send_command(CONTELEC_CONF_MTPRESET, value, 16);
                i_position_feedback.send_command(CONTELEC_CTRL_SAVE, 0, 0);
                i_position_feedback.send_command(CONTELEC_CTRL_RESET, 0, 0);
            }
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
            target_torque = value;
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
    } /* main switch */

    return 0;
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
//                        printf("up limit reached\n");
                    }
                } else if (count <= -position_limit && velocity < -10) {
                    i_motorcontrol.set_torque_control_disabled();
                    i_motorcontrol.set_safe_torque_off_enabled();
                    i_motorcontrol.set_brake_status(0);
                    if (print_position_limit <= 0) {
                        print_position_limit = 1;
//                        printf("down limit reached\n");
                    }
                }
            }
            t :> ts;
            ts += USEC_FAST * 1000;
            break;

        case i_position_limiter.set_limit(int in_limit):
            if (in_limit < 0) {
                position_limit = in_limit;
//                printf("Position limit disabled\n");
            } else if (in_limit > 0) {
//                printf("Position limited to %d ticks\n", in_limit);
                position_limit = in_limit;
            }
            break;

        case i_position_limiter.get_limit() -> int out_limit:
            out_limit =  position_limit;
            break;

        }//end select
    }//end while
}//end function
