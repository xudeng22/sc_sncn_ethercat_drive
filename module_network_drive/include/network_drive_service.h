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
#include <file_service.h>

/* Set with `-DSTARTUP_READ_FLASH_OBJECTS=1` either in the makefile or at the command line
 * to activate initial read of object dictionary from flash at startup */
#ifndef STARTUP_READ_FLASH_OBJECTS
#define STARTUP_READ_FLASH_OBJECTS  1
#endif

/**
 * @brief This Service enables motor drive functions with CANopen.
 *
 * @param i_pdo Interface for PDOs to communication module.
 * @param i_od Interface for SDOs to CANopen service.
 * @param i_torque_control Interface to Motor Control Service
 * @param i_motion_control Interface to Motion Control Service.
 * @param i_position_feedback_1 Interface to the fisrt sensor service
 * @param i_position_feedback_2 Interface to the second sensor service
 */
void network_drive_service( client interface i_pdo_handler_exchange i_pdo,
                            client interface i_co_communication i_co,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2,
                            client interface FileServiceInterface i_file_service);
