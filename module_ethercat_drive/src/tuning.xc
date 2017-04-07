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
        client interface MotionControlInterface i_motion_control,
        client interface PositionFeedbackInterface ?i_position_feedback_1,
        client interface PositionFeedbackInterface ?i_position_feedback_2
    )
{
    uint8_t status_mux     = (tuning_status >> 16) & 0xff;

    //mux send offsets and other data in the tuning result pdo using the lower bits of statusword
    status_mux++;
    switch(status_mux) {
    case TUNING_STATUS_MUX_OFFSET: //send offset
        user_miso = motorcontrol_config.commutation_angle_offset;
        break;
    case TUNING_STATUS_MUX_POLE_PAIRS: //pole pairs
        user_miso = motorcontrol_config.pole_pairs;
        break;
    case TUNING_STATUS_MUX_MIN_POS: //position limit min
        user_miso = motion_ctrl_config.min_pos_range_limit;
        break;
    case TUNING_STATUS_MUX_MAX_POS: //position limit max
        user_miso = motion_ctrl_config.max_pos_range_limit;
        break;
    case TUNING_STATUS_MUX_MAX_SPEED: //max speed
        user_miso = motion_ctrl_config.max_motor_speed;
        break;
    case TUNING_STATUS_MUX_MAX_TORQUE: //max torque
        user_miso = motion_ctrl_config.max_torque;
        break;
    case TUNING_STATUS_MUX_POS_KP: //P_pos
        user_miso = motion_ctrl_config.position_kp;
        break;
    case TUNING_STATUS_MUX_POS_KI: //I_pos
        user_miso = motion_ctrl_config.position_ki;
        break;
    case TUNING_STATUS_MUX_POS_KD: //D_pos
        user_miso = motion_ctrl_config.position_kd;
        break;
    case TUNING_STATUS_MUX_POS_I_LIM: //integral_limit_pos
        user_miso = motion_ctrl_config.position_integral_limit;
        break;
    case TUNING_STATUS_MUX_VEL_KP: //P vel
        user_miso = motion_ctrl_config.velocity_kp;
        break;
    case TUNING_STATUS_MUX_VEL_KI: //I vel
        user_miso = motion_ctrl_config.velocity_ki;
        break;
    case TUNING_STATUS_MUX_VEL_KD: //D vel
        user_miso = motion_ctrl_config.velocity_kd;
        break;
    case TUNING_STATUS_MUX_VEL_I_LIM: //integral_limit_vel
        user_miso = motion_ctrl_config.velocity_integral_limit;
        break;
    case TUNING_STATUS_MUX_FAULT: //fault code
        user_miso = upstream_control_data.error_status;
        break;
    case TUNING_STATUS_MUX_BRAKE_STRAT: //brake_release_strategy
        user_miso = motion_ctrl_config.brake_release_strategy;
        break;
    case TUNING_STATUS_MUX_SENSOR_ERROR:// sensor error
    default:
        user_miso = upstream_control_data.sensor_error;
        status_mux = 0;
        break;
    }

    //check for new command
    if (tuning_command == 0) { //no mode
        tuning_status &= ~TUNING_ACK; //reset ack bit in tuning_status
    } else if ((tuning_status & TUNING_ACK) == 0) {// ack bit is not set = it's a new command
        tuning_status |= TUNING_ACK; //set ack bit in tuning_status
        tuning_mode_state.command   = tuning_command;

        // debug print
        printf("command: %3d, value: %d\n", tuning_mode_state.command, tuning_mode_state.value);

        //execute command
        tuning_command_handler(tuning_mode_state,
                motorcontrol_config, motion_ctrl_config, pos_feedback_config_1, pos_feedback_config_2,
                sensor_commutation, sensor_motion_control,
                i_motion_control, i_position_feedback_1, i_position_feedback_2);

        //update flags
        tuning_mode_state.flags = tuning_set_flags(tuning_mode_state, motorcontrol_config, motion_ctrl_config,
                pos_feedback_config_1, pos_feedback_config_2, sensor_commutation);
    }

    //put status mux, state flags,  tuning state in tuning status
    tuning_status = (tuning_status & ~0xffffff) | ((uint32_t)status_mux << 16) | (tuning_mode_state.flags << 8) | tuning_mode_state.motorctrl_status;

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
        client interface MotionControlInterface i_motion_control,
        client interface PositionFeedbackInterface ?i_position_feedback_1,
        client interface PositionFeedbackInterface ?i_position_feedback_2
)
{

    /* execute command */
    if (tuning_mode_state.command & TUNING_CMD_SET_PARAM_MASK) { //set parameter commands
        switch(tuning_mode_state.command) {
        case TUNING_CMD_POSITION_KP:
            motion_ctrl_config.position_kp = tuning_mode_state.value;
            break;
        case TUNING_CMD_POSITION_KI:
            motion_ctrl_config.position_ki = tuning_mode_state.value;
            break;
        case TUNING_CMD_POSITION_KD:
            motion_ctrl_config.position_kd = tuning_mode_state.value;
            break;
        case TUNING_CMD_POSITION_I_LIM:
            motion_ctrl_config.position_integral_limit = tuning_mode_state.value;
            break;
        case TUNING_CMD_MOMENT_INERTIA:
            motion_ctrl_config.moment_of_inertia = tuning_mode_state.value;
            break;
        case TUNING_CMD_POSITION_PROFILER:
            motion_ctrl_config.enable_profiler = tuning_mode_state.value;
            break;
        case TUNING_CMD_VELOCITY_KP:
            motion_ctrl_config.velocity_kp = tuning_mode_state.value;
            break;
        case TUNING_CMD_VELOCITY_KI:
            motion_ctrl_config.velocity_ki = tuning_mode_state.value;
            break;
        case TUNING_CMD_VELOCITY_KD:
            motion_ctrl_config.velocity_kd = tuning_mode_state.value;
            break;
        case TUNING_CMD_VELOCITY_I_LIM:
            motion_ctrl_config.velocity_integral_limit = tuning_mode_state.value;
            break;
        case TUNING_CMD_MAX_TORQUE:
            motion_ctrl_config.max_torque = tuning_mode_state.value;
            motorcontrol_config.max_torque = tuning_mode_state.value;
            break;
        case TUNING_CMD_MAX_SPEED:
            motion_ctrl_config.max_motor_speed = tuning_mode_state.value;
            break;
        case TUNING_CMD_MAX_POSITION:
            motion_ctrl_config.max_pos_range_limit = tuning_mode_state.value;
            break;
        case TUNING_CMD_MIN_POSITION:
            motion_ctrl_config.min_pos_range_limit = tuning_mode_state.value;
            break;
        case TUNING_CMD_BRAKE_RELEASE_STRATEGY:
            motion_ctrl_config.brake_release_strategy = tuning_mode_state.value;
            break;
        case TUNING_CMD_POLARITY_MOTION:
            motion_ctrl_config.polarity = tuning_mode_state.value;
            break;
        case TUNING_CMD_POLARITY_SENSOR:
            if (sensor_commutation == 2) {
                if (!isnull(i_position_feedback_2)) {
                    pos_feedback_config_2.polarity = tuning_mode_state.value;
                    i_position_feedback_2.set_config(pos_feedback_config_2);
                }
            } else {
                if (!isnull(i_position_feedback_1)) {
                    pos_feedback_config_1.polarity = tuning_mode_state.value;
                }
                i_position_feedback_1.set_config(pos_feedback_config_1);
            }
            break;
        case TUNING_CMD_POLE_PAIRS:
            if (tuning_mode_state.value > 0) {
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
            }
            break;
        case TUNING_CMD_OFFSET:
            motorcontrol_config.commutation_angle_offset = tuning_mode_state.value;
            break;
        case TUNING_CMD_PHASES_INVERTED:
            if (tuning_mode_state.value) {
                motorcontrol_config.phases_inverted = MOTOR_PHASES_INVERTED;
            } else {
                motorcontrol_config.phases_inverted = MOTOR_PHASES_NORMAL;
            }
            break;
        }

        //set config structures
        if (tuning_mode_state.command & TUNING_CMD_SET_MOTION_CONTROL_MASK) {
            i_motion_control.set_position_velocity_control_config(motion_ctrl_config);
        }
        if (tuning_mode_state.command & TUNING_CMD_SET_MOTOR_CONTROL_MASK) {
            tuning_mode_state.brake_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            i_motion_control.set_motorcontrol_config(motorcontrol_config);
        }

    } else { //action command

        switch(tuning_mode_state.command) {
        case TUNING_CMD_CONTROL_DISABLE:
            i_motion_control.disable();
            tuning_mode_state.brake_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            break;


        case TUNING_CMD_CONTROL_POSITION://select control mode
            //select control mode
            int position_control_strategy = motion_ctrl_config.position_control_strategy;
            switch(tuning_mode_state.value) {
            case 1:
                position_control_strategy = POS_PID_CONTROLLER;
                break;
            case 2:
                position_control_strategy = POS_PID_VELOCITY_CASCADED_CONTROLLER;
                break;
            case 3:
                position_control_strategy = NL_POSITION_CONTROLLER;
                break;
            }
            i_motion_control.enable_position_ctrl(position_control_strategy);

            //set motorcontrol status
            switch (position_control_strategy) {
            case POS_PID_CONTROLLER:
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_POSITION_PID;
                break;
            case POS_PID_VELOCITY_CASCADED_CONTROLLER:
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED;
                break;
            case NL_POSITION_CONTROLLER:
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_POSITION_NL;
                break;
            }
            tuning_mode_state.brake_flag = 1;
            break;


        case TUNING_CMD_CONTROL_VELOCITY:
            i_motion_control.enable_velocity_ctrl();
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_VELOCITY;
            tuning_mode_state.brake_flag = 1;
            break;


        case TUNING_CMD_CONTROL_TORQUE:
            i_motion_control.enable_torque_ctrl();
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_TORQUE;
            tuning_mode_state.brake_flag = 1;
            break;


        //auto offset tuning
        case TUNING_CMD_AUTO_OFFSET:
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            tuning_mode_state.brake_flag = 0;
            motorcontrol_config = i_motion_control.set_offset_detection_enabled();
            break;

        //set brake
        case TUNING_CMD_BRAKE:
            if (tuning_mode_state.value == 1 || tuning_mode_state.value == 0) {
                i_motion_control.set_brake_status(tuning_mode_state.value);
                tuning_mode_state.brake_flag = tuning_mode_state.value;
            }
            break;

        case TUNING_CMD_SAFE_TORQUE:
            tuning_mode_state.brake_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            i_motion_control.set_safe_torque_off_enabled();
            break;

        //fault reset
        case TUNING_CMD_FAULT_RESET:
            i_motion_control.disable();
            tuning_mode_state.brake_flag = 0;
            tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
            i_motion_control.reset_motorcontrol_faults();
            break;

        //set zero position
        case TUNING_CMD_ZERO_POSITION:
            if (sensor_motion_control == 2) {
                if (!isnull(i_position_feedback_2)) {
                    i_position_feedback_2.send_command(REM_16MT_CONF_NULL, 0, 0);
                    i_position_feedback_2.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                    i_position_feedback_2.send_command(REM_16MT_CTRL_RESET, 0, 0);
                }
            } else {
                if (!isnull(i_position_feedback_1)) {
                    i_position_feedback_1.send_command(REM_16MT_CONF_NULL, 0, 0);
                    i_position_feedback_1.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                    i_position_feedback_1.send_command(REM_16MT_CTRL_RESET, 0, 0);
                }
            }
            break;

        //set multiturn value (does not change offset)
        case TUNING_CMD_SET_MULTITURN:
            if (sensor_motion_control == 2) {
                if (!isnull(i_position_feedback_2)) {
                    i_position_feedback_2.send_command(REM_16MT_CONF_MTPRESET, tuning_mode_state.value, 16);
                    i_position_feedback_2.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                    i_position_feedback_2.send_command(REM_16MT_CTRL_RESET, 0, 0);
                }
            } else {
                if (!isnull(i_position_feedback_1)) {
                    i_position_feedback_1.send_command(REM_16MT_CONF_MTPRESET, tuning_mode_state.value, 16);
                    i_position_feedback_1.send_command(REM_16MT_CTRL_SAVE, 0, 0);
                    i_position_feedback_1.send_command(REM_16MT_CTRL_RESET, 0, 0);
                }
            }
            break;

        } /* end switch action command*/
    } /* end if setting/action command */
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
    return (uint8_t)( (integrated_profiler<<TUNING_FLAG_INTEGRATED_PROFILER) | (phases_inverted<<TUNING_FLAG_PHASES_INVERTED) | (sensor_polarity<<TUNING_FLAG_SENSOR_POLARITY) | (motion_polarity<<TUNING_FLAG_MOTION_POLARITY) | (tuning_mode_state.brake_flag<<TUNING_FLAG_BRAKE) );
}
