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
 * @param profiler_config Configuration for profile mode control.
 * @param pdo_out Channel to send out information to EtherCAT Service.
 * @param pdo_in Channel to receive information from EtherCAT Service.
 * @param coe_out Channel to receive motor configuration information from EtherCAT Service.
 * @param i_motorcontrol Interface to Motor Commutation Service
 * @param i_hall Interface to Hall Service.
 * @param i_qei Interface to Incremental Encoder Service.
 * @param i_biss Interface to BiSS Encoder Service.
 * @param i_gpio Interface to the GPIO Service.
 * @param i_torque_control Interface to Torque Control Loop Service.
 * @param i_velocity_control Interface to Velocity Control Loop Service.
 * @param i_position_control Interface to Position Control Loop Service.
 */
void ethercat_drive_service(ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface MotorControlInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_control,
                            client interface PositionFeedbackInterface i_position_feedback);

void ethercat_drive_service_debug(ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface MotorControlInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_control,
                            client interface PositionFeedbackInterface i_position_feedback);
