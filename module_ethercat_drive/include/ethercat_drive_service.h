/**
 * @file ecat_motor_drive.h
 * @brief Ethercat Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motorcontrol_service.h>
#include <hall_service.h>
#include <qei_service.h>
#include <gpio_service.h>

#include <velocity_ctrl_service.h>
#include <position_ctrl_service.h>
#include <torque_ctrl_service.h>

#include <profile_control.h>

#define PP      1   /* [O] Profile Position mode */
#define VL      2   /* [O] Velocity mode (frequency converter) */
#define PV      3   /* [O] Profile velocity mode */
#define TQ      4   /* [O] Torque profile mode */
#define HM      6   /* [O] Homing mode */
#define IP      7   /* [O] Interpolated position mode */
#define CSP     8   /* [C] Cyclic synchronous position mode */
#define CSV     9   /* [C] Cyclic synchronous velocity mode */
#define CST     10  /* [C] Cyclic synchronous torque mode */
#define CSTCA   11  /* [O] Cyclic synchronous torque mode with commutation angle */

/**
 * @brief This server implementation enables motor drive functions via EtherCAT communication
 *
 * @Input Channel
 * @param pdo_in channel to receive information from ethercat
 * @param coe_out channel to receive motor config information from ethercat
 * @param c_signal channel to receive init ack from commutation loop
 * @param c_hall channel to receive position information from hall
 * @param c_qei channel to receive position information from qei
 *
 * @Output Channel
 * @param pdo_out channel to send out information via ethercat
 * @param c_torque_ctrl channel to receive/send torque control information
 * @param c_velocity_ctrl channel to receive/send velocity control information
 * @param c_position_ctrl channel to receive/send position control information
 * @param c_gpio channel to config/read/drive GPIO digital ports
 *
 */
void ethercat_drive_service(CyclicSyncPositionConfig &cyclic_sync_position_config,
                            CyclicSyncVelocityConfig &cyclic_sync_velocity_config,
                            CyclicSyncTorqueConfig &cyclic_sync_torque_config,
                            ProfilePositionConfig &profile_position_config,
                            ProfileVelocityConfig &profile_velocity_config,
                            ProfileTorqueConfig &profile_torque_config,
                            chanend pdo_out, chanend pdo_in, chanend coe_out,
                            interface MotorcontrolInterface client i_commutation,
                            interface HallInterface client i_hall,
                            interface QEIInterface client i_qei,
                            interface GPIOInterface client i_gpio,
                            interface TorqueControlInterface client i_torque_control,
                            interface VelocityControlInterface client i_velocity_control,
                            interface PositionControlInterface client i_position_control);
