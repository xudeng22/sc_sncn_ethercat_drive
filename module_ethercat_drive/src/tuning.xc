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

#if 0
static void brake_shake(interface MotorControlInterface client i_motorcontrol, int torque) {
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
#endif

/*
 * Function to call while in tuning opmode
 *
 * Assumption: this function is called every 1ms! (like the standard control does)
 *
 * FIXME
 * - get rid of {Upsream,Downstream}ControlData here, the data exchange should exclusively happen
 *   in the calling ethercat_drive_service.
 */
int tuning_handler_ethercat(
        /* input */  uint32_t    tuning_command,
        /* output */ uint32_t    &user_miso, uint32_t &tuning_status,
        TuningModeState             &tuning_mode_state,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig &motion_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config_1,
        PositionFeedbackConfig   &pos_feedback_config_2,
        int sensor_commutation,
        int sensor_motion_control,
        UpstreamControlData      &upstream_control_data,
        DownstreamControlData    &downstream_control_data,
        client interface PositionVelocityCtrlInterface i_position_control,
        client interface PositionFeedbackInterface ?i_position_feedback_1,
        client interface PositionFeedbackInterface ?i_position_feedback_2
    )
{
    uint8_t status_mux     = (tuning_status >> 16) & 0xff;

    //mux send offsets and other data in the tuning result pdo using the lower bits of statusword
    status_mux++;
    switch(status_mux) {
    case 1: //send offset
        user_miso = motorcontrol_config.commutation_angle_offset;
        break;
    case 2: //pole pairs
        user_miso = motorcontrol_config.pole_pairs;
        break;
    case 3: //target
        switch(tuning_mode_state.motorctrl_status) {
        case TUNING_MOTORCTRL_TORQUE:
            user_miso = downstream_control_data.torque_cmd;
            break;
        case TUNING_MOTORCTRL_VELOCITY:
            user_miso = downstream_control_data.velocity_cmd;
            break;
        case TUNING_MOTORCTRL_POSITION:
        case TUNING_MOTORCTRL_POSITION_PROFILER:
            user_miso = downstream_control_data.position_cmd;
            break;
        }
        break;
    case 4: //position limit min
        user_miso = motion_ctrl_config.min_pos_range_limit;
        break;
    case 5: //position limit max
        user_miso = motion_ctrl_config.max_pos_range_limit;
        break;
    case 6: //max speed
        user_miso = motion_ctrl_config.max_motor_speed;
        break;
    case 7: //max torque
        user_miso = motion_ctrl_config.max_torque;
        break;
    case 8: //P_pos
        user_miso = motion_ctrl_config.position_kp;
        break;
    case 9: //I_pos
        user_miso = motion_ctrl_config.position_ki;
        break;
    case 10: //D_pos
        user_miso = motion_ctrl_config.position_kd;
        break;
    case 11: //integral_limit_pos
        user_miso = motion_ctrl_config.position_integral_limit;
        break;
    case 12: //
        user_miso = motion_ctrl_config.velocity_kp;
        break;
    case 13: //
        user_miso = motion_ctrl_config.velocity_ki;
        break;
    case 14: //
        user_miso = motion_ctrl_config.velocity_kd;
        break;
    case 15: //
        user_miso = motion_ctrl_config.velocity_integral_limit;
        break;
    case 16: //fault code
        user_miso = upstream_control_data.error_status;
        break;
    case 17: //brake_release_strategy
        user_miso = motion_ctrl_config.brake_release_strategy;
        break;
    default: //sensor error
        user_miso = upstream_control_data.sensor_error;
        status_mux = 0;
        break;
    }

    if ((tuning_command & 0xff) == 'p') { //cyclic position mode
        downstream_control_data.position_cmd = tuning_mode_state.value;

    } else {//command mode
        tuning_mode_state.mode_1 = 0; //default command do nothing

        //check for new command
        if (tuning_command == 0) { //no mode
            tuning_status &= ~0x80000000; //reset ack bit in tuning_status
        } else if ((tuning_status & 0x80000000) == 0) {// ack bit is not set = it's a new command
            tuning_status |= 0x80000000; //set ack bit in tuning_status
            tuning_mode_state.mode_1   = tuning_command          & 0xff;
            tuning_mode_state.mode_2   = (tuning_command >>  8)  & 0xff;
            tuning_mode_state.mode_3   = (tuning_command >> 16)  & 0xff;
        }

        /* print command */
        if (tuning_mode_state.mode_1 >=32 && tuning_mode_state.mode_1 <= 126) { //mode is a printable ascii char
            if (tuning_mode_state.mode_2 != 0) {
                if (tuning_mode_state.mode_3 != 0) {
                    printf("%c %c %c %d\n", tuning_mode_state.mode_1, tuning_mode_state.mode_2, tuning_mode_state.mode_3, tuning_mode_state.value);
                } else {
                    printf("%c %c %d\n", tuning_mode_state.mode_1, tuning_mode_state.mode_2, tuning_mode_state.value);
                }
            } else {
                printf("%c %d\n", tuning_mode_state.mode_1, tuning_mode_state.value);
            }
        }

        //execute command
        tuning_command_handler(tuning_mode_state,
                motorcontrol_config, motion_ctrl_config, pos_feedback_config_1, pos_feedback_config_2,
                sensor_commutation, sensor_motion_control,
                upstream_control_data, downstream_control_data,
                i_position_control, i_position_feedback_1, i_position_feedback_2);
    }

    //put status mux, state flags,  tuning state in tuning status
    uint8_t flags = tuning_set_flags(tuning_mode_state, motorcontrol_config, motion_ctrl_config,
            pos_feedback_config_1, pos_feedback_config_2, sensor_commutation);
    tuning_status = (tuning_status & ~0xffffff) | ((uint32_t)status_mux << 16) | (flags << 8) | tuning_mode_state.motorctrl_status;

    return 0;
}



void tuning_command_handler(
        TuningModeState             &tuning_mode_state,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig &motion_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config_1,
        PositionFeedbackConfig   &pos_feedback_config_2,
        int sensor_commutation,
        int sensor_motion_control,
        UpstreamControlData      &upstream_control_data,
        DownstreamControlData    &downstream_control_data,
        client interface PositionVelocityCtrlInterface i_position_control,
        client interface PositionFeedbackInterface ?i_position_feedback_1,
        client interface PositionFeedbackInterface ?i_position_feedback_2
    )
{

    //repeat
    const int tolerance = 1000;
    if (tuning_mode_state.repeat_flag == 1) {
        if (upstream_control_data.position < (downstream_control_data.position_cmd+tolerance) &&
            upstream_control_data.position > (downstream_control_data.position_cmd-tolerance)) {
            downstream_control_data.position_cmd = -downstream_control_data.position_cmd;
        }
    }

    /* execute command */
    switch(tuning_mode_state.mode_1) {
    //position commands
    case 'p':
        downstream_control_data.offset_torque = 0;
        downstream_control_data.position_cmd = tuning_mode_state.value;
        motion_ctrl_config = i_position_control.get_position_velocity_control_config();
        switch(tuning_mode_state.mode_2)
        {
        //direct command with profile
        case 'p':
                //bug: the first time after one p# command p0 doesn't use the profile; only the way back to zero
                motion_ctrl_config.enable_profiler = 1;
                i_position_control.set_position_velocity_control_config(motion_ctrl_config);
                printf("Go to %d with profile\n", tuning_mode_state.value);
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                break;
        //step command (forward and backward)
        case 's':
                switch(tuning_mode_state.mode_3)
                {
                //with profile
                case 'p':
                        motion_ctrl_config.enable_profiler = 1;
                        printf("position cmd: %d to %d with profile\n", tuning_mode_state.value, -tuning_mode_state.value);
                        break;
                //without profile
                default:
                        motion_ctrl_config.enable_profiler = 0;
                        printf("position cmd: %d to %d\n", tuning_mode_state.value, -tuning_mode_state.value);
                        break;
                }
                i_position_control.set_position_velocity_control_config(motion_ctrl_config);
                downstream_control_data.offset_torque = 0;
                downstream_control_data.position_cmd = tuning_mode_state.value;
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                delay_milliseconds(1500);
                downstream_control_data.position_cmd = -tuning_mode_state.value;
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                delay_milliseconds(1500);
                downstream_control_data.position_cmd = 0;
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                break;
        //direct command
        default:
                motion_ctrl_config.enable_profiler = 0;
                i_position_control.set_position_velocity_control_config(motion_ctrl_config);
                printf("Go to %d\n", tuning_mode_state.value);
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                break;
        }
        break;

    //repeat
    case 'R':
        if (tuning_mode_state.value) {
            downstream_control_data.position_cmd = upstream_control_data.position+tuning_mode_state.value;
            tuning_mode_state.repeat_flag = 1;
        } else {
            tuning_mode_state.repeat_flag = 0;
        }
        break;

    //set velocity
    case 'v':
        downstream_control_data.velocity_cmd = tuning_mode_state.value;
        upstream_control_data = i_position_control.update_control_data(downstream_control_data);
        printf("set velocity %d\n", downstream_control_data.velocity_cmd);
        break;

    //change pid coefficients
    case 'k':
        motion_ctrl_config = i_position_control.get_position_velocity_control_config();
        switch(tuning_mode_state.mode_2) {
        case 'p': //position
            switch(tuning_mode_state.mode_3) {
            case 'p':
                motion_ctrl_config.position_kp = tuning_mode_state.value;
                break;
            case 'i':
                motion_ctrl_config.position_ki = tuning_mode_state.value;
                break;
            case 'd':
                motion_ctrl_config.position_kd = tuning_mode_state.value;
                break;
            case 'l':
                motion_ctrl_config.position_integral_limit = tuning_mode_state.value;
                break;
            case 'j':
                motion_ctrl_config.moment_of_inertia = tuning_mode_state.value;
                break;
            default:
                printf("Pp:%d Pi:%d Pd:%d Pi lim:%d j:%d\n", motion_ctrl_config.position_kp, motion_ctrl_config.position_ki, motion_ctrl_config.position_kd,
                        motion_ctrl_config.position_integral_limit, motion_ctrl_config.moment_of_inertia);
                break;
            }
            break;
            case 'v': //velocity
                switch(tuning_mode_state.mode_3) {
                case 'p':
                    motion_ctrl_config.velocity_kp = tuning_mode_state.value;
                    break;
                case 'i':
                    motion_ctrl_config.velocity_ki = tuning_mode_state.value;
                    break;
                case 'd':
                    motion_ctrl_config.velocity_kd = tuning_mode_state.value;
                    break;
                case 'l':
                    motion_ctrl_config.velocity_integral_limit = tuning_mode_state.value;
                    break;
                default:
                    printf("Kp:%d Ki:%d Kd:%d\n", motion_ctrl_config.velocity_kp, motion_ctrl_config.velocity_ki, motion_ctrl_config.velocity_kd);
                    break;
                }
                break;
        } /* end mode_2 */
        i_position_control.set_position_velocity_control_config(motion_ctrl_config);
        break;

    //limits
    case 'L':
        motion_ctrl_config = i_position_control.get_position_velocity_control_config();
        switch(tuning_mode_state.mode_2) {
            //max torque
            case 't':
                motion_ctrl_config.max_torque = tuning_mode_state.value;
                motorcontrol_config.max_torque = tuning_mode_state.value;
                i_position_control.set_motorcontrol_config(motorcontrol_config);
                tuning_mode_state.brake_flag = 0;
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
                break;
            //max speed
            case 's':
            case 'v':
                motion_ctrl_config.max_motor_speed = tuning_mode_state.value;
                break;
            //max position
            case 'p':
                switch(tuning_mode_state.mode_3) {
                case 'u':
                    motion_ctrl_config.max_pos_range_limit = tuning_mode_state.value;
                    break;
                case 'l':
                    motion_ctrl_config.min_pos_range_limit = tuning_mode_state.value;
                    break;
                default:
                    motion_ctrl_config.max_pos_range_limit = tuning_mode_state.value;
                    motion_ctrl_config.min_pos_range_limit = -tuning_mode_state.value;
                    break;
                }
                break;
        } /* end mode_2 */
        i_position_control.set_position_velocity_control_config(motion_ctrl_config);
        break;

    //enable position control
    case 'e':
        if (tuning_mode_state.value > 0) {
            tuning_mode_state.brake_flag = 1;
            switch(tuning_mode_state.mode_2) {
            case 'p':
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_POSITION;
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                downstream_control_data.position_cmd = upstream_control_data.position;
                upstream_control_data = i_position_control.update_control_data(downstream_control_data);
                printf("start position %d\n", downstream_control_data.position_cmd);

                //select profiler
                motion_ctrl_config = i_position_control.get_position_velocity_control_config();
                if (tuning_mode_state.mode_3 == 'p') {
                    motion_ctrl_config.enable_profiler = 1;
                    tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_POSITION_PROFILER;
                } else {
                    motion_ctrl_config.enable_profiler = 0;
                }
                i_position_control.set_position_velocity_control_config(motion_ctrl_config);

                //select control mode
                switch(tuning_mode_state.value) {
                case 1:
                    i_position_control.enable_position_ctrl(POS_PID_CONTROLLER);
                    printf("simpe PID pos ctrl enabled\n");
                    break;
                case 2:
                    i_position_control.enable_position_ctrl(POS_PID_VELOCITY_CASCADED_CONTROLLER);
                    printf("vel.-cascaded pos ctrl enabled\n");
                    break;
                case 3:
                    i_position_control.enable_position_ctrl(NL_POSITION_CONTROLLER);
                    printf("Nonlinear pos ctrl enabled\n");
                    break;
                default:
                    i_position_control.enable_position_ctrl(motion_ctrl_config.position_control_strategy);
                    printf("%d pos ctrl enabled\n", motion_ctrl_config.position_control_strategy);
                    break;
                }
                break;
            case 'v':
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_VELOCITY;
                downstream_control_data.velocity_cmd = 0;
                i_position_control.enable_velocity_ctrl();
                printf("velocity ctrl enabled\n");
                break;
            case 't':
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_TORQUE;
                downstream_control_data.torque_cmd = 0;
                i_position_control.enable_torque_ctrl();
                printf("torque ctrl enabled\n");
                break;
            }
        } else {
            tuning_mode_state.brake_flag = 0;
            tuning_mode_state.repeat_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            i_position_control.disable();
            printf("position ctrl disabled\n");
        }
        break;

    //pole pairs
    case 'P':
        if (sensor_commutation == 2) {
            if (!isnull(i_position_feedback_2)) {
                pos_feedback_config_2.pole_pairs = tuning_mode_state.value;
                i_position_feedback_2.set_config(pos_feedback_config_2);
            }
        } else {
            if (!isnull(i_position_feedback_1)) {
                pos_feedback_config_1.pole_pairs = tuning_mode_state.value;
                i_position_feedback_1.set_config(pos_feedback_config_1);
            }
        }
        motorcontrol_config.pole_pairs = tuning_mode_state.value;
        tuning_mode_state.brake_flag = 0;
        tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
        i_position_control.set_motorcontrol_config(motorcontrol_config);
        break;

    //direction
    case 'd':
        motion_ctrl_config = i_position_control.get_position_velocity_control_config();
        if (motion_ctrl_config.polarity == MOTION_POLARITY_INVERTED) {
            motion_ctrl_config.polarity = MOTION_POLARITY_NORMAL;
        } else {
            motion_ctrl_config.polarity = MOTION_POLARITY_INVERTED;
        }
        i_position_control.set_position_velocity_control_config(motion_ctrl_config);
        break;

    //sensor polarity
    case 's':
        if (sensor_commutation == 2) {
            if (!isnull(i_position_feedback_2)) {
                if (pos_feedback_config_2.polarity == SENSOR_POLARITY_INVERTED) {
                    pos_feedback_config_2.polarity = SENSOR_POLARITY_NORMAL;
                } else {
                    pos_feedback_config_2.polarity = SENSOR_POLARITY_INVERTED;
                }
                i_position_feedback_2.set_config(pos_feedback_config_2);
            }
        } else {
            if (!isnull(i_position_feedback_1)) {
                if (pos_feedback_config_1.polarity == SENSOR_POLARITY_INVERTED) {
                    pos_feedback_config_1.polarity = SENSOR_POLARITY_NORMAL;
                } else {
                    pos_feedback_config_1.polarity = SENSOR_POLARITY_INVERTED;
                }
                i_position_feedback_1.set_config(pos_feedback_config_1);
            }
        }
        break;

    //auto offset tuning
    case 1:
        tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
        tuning_mode_state.brake_flag = 0;
        motorcontrol_config = i_position_control.set_offset_detection_enabled();
        break;

    //set offset
    case 'o':
        tuning_mode_state.brake_flag = 0;
        tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
        motorcontrol_config.commutation_angle_offset = tuning_mode_state.value;
        i_position_control.set_motorcontrol_config(motorcontrol_config);
        printf("set offset to %d\n", tuning_mode_state.value);
        break;

    //set brake
    case 'b':
        switch(tuning_mode_state.mode_2) {
        case 's': //toggle special brake release
            motion_ctrl_config = i_position_control.get_position_velocity_control_config();
            motion_ctrl_config.brake_release_strategy = tuning_mode_state.value;
            i_position_control.set_position_velocity_control_config(motion_ctrl_config);
            break;
        default:
            if (tuning_mode_state.brake_flag == 0 || tuning_mode_state.value == 1) {
                tuning_mode_state.brake_flag = 1;
                printf("Brake released\n");
            } else {
                tuning_mode_state.brake_flag = 0;
                printf("Brake blocking\n");
            }
            i_position_control.set_brake_status(tuning_mode_state.brake_flag);
            break;
        } /* end mode_2 */
        break;

    //set zero position
    case 'z':
        if (sensor_motion_control == 2) {
            if (!isnull(i_position_feedback_2)) {
                switch(tuning_mode_state.mode_2) {
                case 'z':
                    i_position_feedback_2.send_command(REM_16MT_CONF_NULL, 0, 0);
                    break;
                default:
                    i_position_feedback_2.send_command(REM_16MT_CONF_MTPRESET, tuning_mode_state.value, 16);
                    break;
                }
                i_position_feedback_2.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                i_position_feedback_2.send_command(REM_16MT_CTRL_RESET, 0, 0);
            }
        } else {
            if (!isnull(i_position_feedback_1)) {
                switch(tuning_mode_state.mode_2) {
                case 'z':
                    i_position_feedback_1.send_command(REM_16MT_CONF_NULL, 0, 0);
                    break;
                default:
                    i_position_feedback_1.send_command(REM_16MT_CONF_MTPRESET, tuning_mode_state.value, 16);
                    break;
                }
                i_position_feedback_1.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                i_position_feedback_1.send_command(REM_16MT_CTRL_RESET, 0, 0);
            }
        }
        break;

    //reverse torque
    case 'r':
        switch(tuning_mode_state.motorctrl_status) {
        case TUNING_MOTORCTRL_TORQUE:
            downstream_control_data.torque_cmd = -downstream_control_data.torque_cmd;
            printf("Torque %d\n", downstream_control_data.torque_cmd);
            break;
        case TUNING_MOTORCTRL_VELOCITY:
            downstream_control_data.velocity_cmd = -downstream_control_data.velocity_cmd;
            printf("Velocity %d\n", downstream_control_data.velocity_cmd);
            break;
        }
        break;

    //set torque
    case '@':
        //switch to torque control mode
        if (tuning_mode_state.motorctrl_status != TUNING_MOTORCTRL_TORQUE) {
            tuning_mode_state.brake_flag = 1;
            tuning_mode_state.repeat_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_TORQUE;
            i_position_control.enable_torque_ctrl();
            printf("switch to torque control mode\n");
        }
        //release the brake
        if (tuning_mode_state.brake_flag == 0) {
            tuning_mode_state.brake_flag = 1;
            i_position_control.set_brake_status(tuning_mode_state.brake_flag);
        }
        downstream_control_data.torque_cmd = tuning_mode_state.value;
        upstream_control_data = i_position_control.update_control_data(downstream_control_data);
        break;
    } /* main switch */
}

uint8_t tuning_set_flags(TuningModeState &tuning_mode_state,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig      &motion_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config_1,
        PositionFeedbackConfig   &pos_feedback_config_2,
        int sensor_commutation)
{
    int motion_polarity = 0;
    if (motion_ctrl_config.polarity == MOTION_POLARITY_INVERTED) {
        motion_polarity = 1;
    }
    int sensor_polarity = (int)pos_feedback_config_1.polarity;
    if (sensor_commutation == 2) {
        sensor_polarity = (int)pos_feedback_config_2.polarity;
    }
    if (sensor_polarity == SENSOR_POLARITY_INVERTED) {
        sensor_polarity = 1;
    } else {
        sensor_polarity = 0;
    }
    int phases_inverted = 0;
    if (motorcontrol_config.phases_inverted == MOTOR_PHASES_INVERTED) {
        phases_inverted = 1;
    }
    int integrated_profiler = 0;
    if (motion_ctrl_config.enable_profiler) {
        integrated_profiler = 1;
    }
    return (uint8_t)( (integrated_profiler<<4) | (phases_inverted<<3) | (sensor_polarity<<2) | (motion_polarity<<1) | tuning_mode_state.brake_flag );
}
