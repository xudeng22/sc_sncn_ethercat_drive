/*
 * tuning.h
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */


#pragma once

#include <platform.h>
#include <motor_control_interfaces.h>
#include <refclk.h>
#include <adc_service.h>
#include <motion_control_service.h>
#include <profile_control.h>
#include <ethercat_service.h>
#include <pdo_handler.h>
#include <position_feedback_service.h>
#include <stdint.h>

#include <xscope.h>
#include <mc_internal_constants.h>

#define TUNING_CMD_SET_PARAM_MASK               0x80
#define TUNING_CMD_SET_MOTION_CONTROL_MASK      0x40
#define TUNING_CMD_SET_MOTOR_CONTROL_MASK       0x20
#define TUNING_CMD_SET_POSITION_FEEDBACK_MASK   0x10

#define TUNING_ACK                          0x80000000

typedef enum {
    TUNING_CMD_AUTO_OFFSET                = 0x01,
    TUNING_CMD_BRAKE                      = 0x02,
    TUNING_CMD_SAFE_TORQUE                = 0x03,
    TUNING_CMD_ZERO_POSITION              = 0x04,
    TUNING_CMD_SET_MULTITURN              = 0x05,
    TUNING_CMD_FAULT_RESET                = 0x06,
    TUNING_CMD_CONTROL_DISABLE            = 0x07,
    TUNING_CMD_CONTROL_POSITION           = 0x08,
    TUNING_CMD_CONTROL_VELOCITY           = 0x09,
    TUNING_CMD_CONTROL_TORQUE             = 0x0A,
    TUNING_CMD_POSITION_KP                = 0xC0,
    TUNING_CMD_POSITION_KI                = 0xC1,
    TUNING_CMD_POSITION_KD                = 0xC2,
    TUNING_CMD_POSITION_I_LIM             = 0xC3,
    TUNING_CMD_MOMENT_INERTIA             = 0xC4,
    TUNING_CMD_POSITION_PROFILER          = 0xC5,
    TUNING_CMD_VELOCITY_KP                = 0xC6,
    TUNING_CMD_VELOCITY_KI                = 0xC7,
    TUNING_CMD_VELOCITY_KD                = 0xC8,
    TUNING_CMD_VELOCITY_I_LIM             = 0xC9,
    TUNING_CMD_MAX_SPEED                  = 0xCA,
    TUNING_CMD_MAX_POSITION               = 0xCB,
    TUNING_CMD_MIN_POSITION               = 0xCC,
    TUNING_CMD_BRAKE_RELEASE_STRATEGY     = 0xCD,
    TUNING_CMD_POLARITY_MOTION            = 0xCE,
    TUNING_CMD_MAX_TORQUE                 = 0xE0,
    TUNING_CMD_POLARITY_SENSOR            = 0x90,
    TUNING_CMD_POLE_PAIRS                 = 0xB0,
    TUNING_CMD_OFFSET                     = 0xA0,
    TUNING_CMD_PHASES_INVERTED            = 0xA1,
    TUNING_CMD_RATED_TORQUE               = 0xA2
} TuningCommands;

typedef enum {
    TUNING_MOTORCTRL_OFF                            = 0,
    TUNING_MOTORCTRL_POSITION_PID                   = 1,
    TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED = 2,
    TUNING_MOTORCTRL_POSITION_NL                    = 3,
    TUNING_MOTORCTRL_VELOCITY                       = 4,
    TUNING_MOTORCTRL_TORQUE                         = 5
} TuningMotorCtrlStatus;

typedef enum {
    TUNING_STATUS_MUX_OFFSET            = 1,
    TUNING_STATUS_MUX_POLE_PAIRS        = 2,
    TUNING_STATUS_MUX_MIN_POS           = 3,
    TUNING_STATUS_MUX_MAX_POS           = 4,
    TUNING_STATUS_MUX_MAX_SPEED         = 5,
    TUNING_STATUS_MUX_MAX_TORQUE        = 6,
    TUNING_STATUS_MUX_POS_KP            = 7,
    TUNING_STATUS_MUX_POS_KI            = 8,
    TUNING_STATUS_MUX_POS_KD            = 9,
    TUNING_STATUS_MUX_POS_I_LIM         = 10,
    TUNING_STATUS_MUX_VEL_KP            = 11,
    TUNING_STATUS_MUX_VEL_KI            = 12,
    TUNING_STATUS_MUX_VEL_KD            = 13,
    TUNING_STATUS_MUX_VEL_I_LIM         = 14,
    TUNING_STATUS_MUX_FAULT             = 15,
    TUNING_STATUS_MUX_BRAKE_STRAT       = 16,
    TUNING_STATUS_MUX_SENSOR_ERROR      = 17,
    TUNING_STATUS_MUX_MOTION_CTRL_ERROR = 18,
    TUNING_STATUS_MUX_RATED_TORQUE      = 19
} TuningStatusMux;

typedef enum {
    TUNING_FLAG_BRAKE               = 0,
    TUNING_FLAG_MOTION_POLARITY     = 1,
    TUNING_FLAG_SENSOR_POLARITY     = 2,
    TUNING_FLAG_PHASES_INVERTED     = 3,
    TUNING_FLAG_INTEGRATED_PROFILER = 4
} TuningFlagsBit;

typedef struct {
    int command;
    int value;
    int brake_flag;
    int flags;
    TuningMotorCtrlStatus motorctrl_status;
} TuningModeState;


int tuning_handler_ethercat(
        /* input */  uint32_t    tuning_command,
        /* output */ uint32_t    &statusword, uint32_t &tuning_status,
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
    );

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
    );

uint8_t tuning_set_flags(TuningModeState &tuning_mode_state,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig      &motion_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config_1,
        PositionFeedbackConfig   &pos_feedback_config_2,
        int sensor_commutation);
