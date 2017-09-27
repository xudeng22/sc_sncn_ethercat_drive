/**
 * @file ethercat_drive_service.h
 * @brief EtherCAT Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motor_control_interfaces.h>
#include <ethercat_service.h>

#include <motion_control_service.h>
#include <position_feedback_service.h>

#include <profile_control.h>

/**
 * @brief This Service enables motor drive functions via EtherCAT.
 *
 * @param i_pdo Channel to send and receive information to EtherCAT Service.
 * @param i_coe Channel to receive motor configuration information from EtherCAT Service.
 * @param i_torque_control Interface to Motor Control Service
 * @param i_motion_control Interface to Motion Control Service.
 * @param i_position_feedback_1 Interface to the fisrt sensor service
 * @param i_position_feedback_2 Interface to the second sensor service
 */
void ethercat_drive_service(client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2);

void ethercat_drive_service_debug(ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback);
