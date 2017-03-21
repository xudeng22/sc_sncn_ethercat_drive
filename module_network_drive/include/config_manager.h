/**
 * @file config_manager.h
 * @brief CANopen Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motor_control_interfaces.h>
#include <motion_control_service.h>
#include <profile_control.h>

/*
 * General, syncronize configuration with the object dictionary values provided
 * by the master.
 */

void cm_sync_config_position_feedback(
        client interface i_co_communication i_co,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config);

void cm_sync_config_motor_control(
        client interface i_co_communication i_co,
        client interface MotorcontrolInterface ?i_commutation,
        MotorcontrolConfig &commutation_params);

void cm_sync_config_profiler(
        client interface i_co_communication i_co,
        ProfilerConfig &profiler);

void cm_sync_config_pos_velocity_control(
        client interface i_co_communication i_co,
        client interface PositionVelocityCtrlInterface i_position_control,
        MotionControlConfig &position_config);

/*
 * Set default configuration of the modules in the object dictionary. If nothing
 * is overwritten, this settings will be used later.
 */

void cm_default_config_position_feedback(
        client interface i_co_communication i_co,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config);

void cm_default_config_motor_control(
        client interface i_co_communication i_co,
        client interface MotorcontrolInterface ?i_commutation,
        MotorcontrolConfig &commutation_params);

void cm_default_config_profiler(
        client interface i_co_communication i_co,
        ProfilerConfig &profiler);

void cm_default_config_pos_velocity_control(
        client interface i_co_communication i_co,
        client interface PositionVelocityCtrlInterface i_position_control);
