/**
 * @file config_manager.h
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <ethercat_service.h>
#include <motor_control_interfaces.h>
#include <hall_service.h>
#include <qei_service.h>
#include <gpio_service.h>
#include <motion_control_service.h>
#include <profile_control.h>

/* Define which type a given profiler configuration is
 * FIXME could be added into ProfilerConfig!
 */
enum eProfileType {
    PROFILE_TYPE_UNKNOWN = 0
    ,PROFILE_TYPE_POSITION
    ,PROFILE_TYPE_VELOCITY
};

/*
 * General, syncronize configuration with the object dictionary values provided
 * by the EtherCAT master.
 */

int  cm_sync_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index);

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        client interface MotorcontrolInterface ?i_commutation,
        MotorcontrolConfig &commutation_params,
        int sensor_commutation,
        int sensor_commutation_type);

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler,
        enum eProfileType type);

void cm_sync_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control,
        MotionControlConfig &position_config,
        int sensor_resolution);

/* This function is a workaround until the hall and motorconfig is reorganized. */
void cm_sync_config_hall_states(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        interface MotorcontrolInterface client ?i_motorcontrol,
        PositionFeedbackConfig &feedback_config,
        MotorcontrolConfig &motorcontrol_config,
        int sensor_index);

/*
 * Set default configuration of the modules in the object dictionary. If nothing
 * is overwritten, this settings will be used later.
 */

void cm_default_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index);

void cm_default_config_motor_control(
        client interface i_coe_communication i_coe,
        client interface MotorcontrolInterface ?i_commutation,
        MotorcontrolConfig &commutation_params);

void cm_default_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler);

void cm_default_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control);
