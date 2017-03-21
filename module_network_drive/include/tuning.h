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
#include <position_feedback_service.h>
#include <stdint.h>

#include <xscope.h>
#include <mc_internal_constants.h>

//FixMe Profiler initialization should be done in main. The user_config thus will be excluded from here!
//#include <user_config_speedy_A1.h>
//#include <user_config.h>

typedef enum {
    TUNING_MOTORCTRL_OFF= 0,
    TUNING_MOTORCTRL_TORQUE= 1,
    TUNING_MOTORCTRL_POSITION= 2,
    TUNING_MOTORCTRL_VELOCITY= 3,
    TUNING_MOTORCTRL_POSITION_PROFILER= 4
} TuningMotorCtrlStatus;


typedef struct {
    int mode_1;
    int mode_2;
    int mode_3;
    int value;
    int brake_flag;
    int repeat_flag;
    TuningMotorCtrlStatus motorctrl_status;
} TuningStatus;


int tuning_handler(
        /* input */  uint16_t    controlword, uint32_t control_extension,
        /* output */ uint16_t    &statusword, uint32_t &tuning_result,
        TuningStatus             &tuning_status,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig      &pos_velocity_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config,
        UpstreamControlData      &upstream_control_data,
        DownstreamControlData    &downstream_control_data,
        client interface PositionVelocityCtrlInterface i_position_control,
        client interface PositionFeedbackInterface ?i_position_feedback
    );

void tuning_command(
        TuningStatus             &tuning_status,
        MotorcontrolConfig       &motorcontrol_config,
        MotionControlConfig      &pos_velocity_ctrl_config,
        PositionFeedbackConfig   &pos_feedback_config,
        UpstreamControlData      &upstream_control_data,
        DownstreamControlData    &downstream_control_data,
        client interface PositionVelocityCtrlInterface i_position_control,
        client interface PositionFeedbackInterface ?i_position_feedback
    );
