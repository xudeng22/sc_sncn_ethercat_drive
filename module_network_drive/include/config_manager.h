/**
 * @file config_manager.h
 * @brief CANopen Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motor_control_interfaces.h>
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
 * by the master.
 */

int cm_sync_config_position_feedback(
        client interface i_co_communication i_co,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config, int feedback_service_index,
        int &sensor_commutation, int &sensor_motion_control,
        int number_of_ports, int &port_index);

void cm_sync_config_motor_control(
        client interface i_co_communication i_co,
        client interface TorqueControlInterface ?i_torque_control,
        MotorcontrolConfig &commutation_params,
        int sensor_commutation,
        int sensor_commutation_type);

void cm_sync_config_profiler(
        client interface i_co_communication i_co,
        ProfilerConfig &profiler,
        enum eProfileType type);

void cm_sync_config_pos_velocity_control(
        client interface i_co_communication i_co,
        client interface MotionControlInterface i_motion_control,
        MotionControlConfig &position_config,
        int sensor_resolution);

/* This function is a workaround until the hall and motorconfig is reorganized. */
void cm_sync_config_hall_states(
        client interface i_co_communication i_co,
        client interface PositionFeedbackInterface i_pos_feedback,
        client interface TorqueControlInterface ?i_torque_control,
        PositionFeedbackConfig &feedback_config,
        MotorcontrolConfig &motorcontrol_config,
        int sensor_index);

/*
 * Set default configuration of the modules in the object dictionary. If nothing
 * is overwritten, this settings will be used later.
 */

void cm_default_config_position_feedback(
        client interface i_co_communication i_co,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int feedback_service_index);

void cm_default_config_motor_control(
        client interface i_co_communication i_co,
        client interface TorqueControlInterface ?i_torque_control,
        MotorcontrolConfig &commutation_params);

void cm_default_config_profiler(
        client interface i_co_communication i_co,
        ProfilerConfig &profiler);

void cm_default_config_pos_velocity_control(
        client interface i_co_communication i_co,
        client interface MotionControlInterface i_motion_control);
