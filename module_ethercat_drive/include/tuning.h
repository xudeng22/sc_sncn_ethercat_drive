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


/**
 * @brief Tuning command codes
 */
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
    TUNING_CMD_AUTO_POS_CONTROLLER_TUNE   = 0x0B,
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


/**
 * @brief Motorcontrol status during tuning mode
 */
typedef enum {
    TUNING_MOTORCTRL_OFF                            = 0,
    TUNING_MOTORCTRL_POSITION_PID                   = 1,
    TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED = 2,
    TUNING_MOTORCTRL_POSITION_LT                    = 3,
    TUNING_MOTORCTRL_VELOCITY                       = 4,
    TUNING_MOTORCTRL_TORQUE                         = 5
} TuningMotorCtrlStatus;


/**
 * @brief Tuning status mux codes
 *
 *  This is used to mux multiple parameters and status in one pdo
 *  to send to the master
 */
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


/**
 * @brief Structure for the command and value, status and flags of the tuning mode
 */
typedef struct {
    int command;
    int value;
    int brake_flag;
    int flags;
    TuningMotorCtrlStatus motorctrl_status;
} TuningModeState;


/**
 * @brief Function to handle the Tuning mode of ethercat drive
 *        It handles the muxing of mulitple parameters to send to the master
 *        It also handles the command received from the master and calls the tuning_command_handler function.
 *
 * @param tuning_command tuning command code
 * @param user_miso to send multiple parameters and status to the master
 * @param tuning_status to send multiple parameters and status to the master
 * @param tuning_mode_state state of the motorcontrol in tuning mode
 * @param motorcontrol_config configuration structure of the motorcontrol service
 * @param motion_ctrl_config configuration structure of the motion control service
 * @param pos_feedback_config_1 configuration structure of the position feedback number 1
 * @param pos_feedback_config_2 configuration structure of the position feedback number 2
 * @param sensor_commutation number of the commutation sensor
 * @param sensor_motion_control number of the motion control sensor
 * @param upstream_control_data structure with positon, velocity and status of sensor and motorcontrol
 * @param i_motion_control client interface to the motion control service
 * @param i_position_feedback_1 client interface to the position feedback number 1
 * @param i_position_feedback_2 client interface to the position feedback number 2
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
    );


/**
 * @brief Function to handle the tuning commands
 *
 * @param tuning_mode_state state of the motorcontrol in tuning mode, also contains the tuning command and value
 * @param motorcontrol_config configuration structure of the motorcontrol service
 * @param motion_ctrl_config configuration structure of the motion control service
 * @param pos_feedback_config_1 configuration structure of the position feedback number 1
 * @param pos_feedback_config_2 configuration structure of the position feedback number 2
 * @param sensor_commutation number of the commutation sensor
 * @param sensor_motion_control number of the motion control sensor
 * @param upstream_control_data structure with positon, velocity and status of sensor and motorcontrol
 * @param i_motion_control client interface to the motion control service
 * @param i_position_feedback_1 client interface to the position feedback number 1
 * @param i_position_feedback_2 client interface to the position feedback number 2
 */
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


/**
 * @brief Function to parse different status flags to send to the master
 *
 * @param motorcontrol_config configuration structure of the motorcontrol service
 * @param motion_ctrl_config configuration structure of the motion control service
 * @param pos_feedback_config_1 configuration structure of the position feedback number 1
 * @param pos_feedback_config_2 configuration structure of the position feedback number 2
 * @param sensor_commutation number of the commutation sensor
 */
uint8_t tuning_set_flags(TuningModeState &tuning_mode_state,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig      &motion_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config_1,
        PositionFeedbackConfig   &pos_feedback_config_2,
        int sensor_commutation);
