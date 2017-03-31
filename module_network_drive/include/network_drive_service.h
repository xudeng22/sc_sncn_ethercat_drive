/**
 * @file network_drive_service.h
 * @brief CANopen Motor Drive Service
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motor_control_interfaces.h>
#include <co_interface.h>
#include <pdo_handler.h>

#include <motion_control_service.h>
#include <position_feedback_service.h>

#include <profile_control.h>

/**
 * @brief This Service enables motor drive functions with CANopen.
 *
 * @param profiler_config Configuration for profile mode control.
 * @param i_pdo Interface for PDOs to communication module.
 * @param i_od Interface for SDOs to CANopen service.
 * @param i_motorcontrol Interface to Motor Commutation Service
 * @param i_position_velocity_control Interface to Position-Velocity Control Loop Service.
 * @param i_position_feedback Inteface to Position Feedback Service.
 */
void network_drive_service(ProfilerConfig &profiler_config,
                            client interface i_co_communication i_co,
                            client interface MotorControlInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_velocity_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2);

void network_drive_service_debug(ProfilerConfig &profiler_config,
                            client interface i_co_communication i_co,
                            client interface MotorControlInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_velocity_control,
                            client interface PositionFeedbackInterface i_position_feedback);
