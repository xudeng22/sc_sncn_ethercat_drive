/**
 * @file ethercat_drive_service.h
 * @brief EtherCAT Motor Drive Server
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
                            chanend pdo_out, chanend pdo_in, chanend coe_out,
                            interface MotorcontrolInterface client i_motorcontrol,
                            interface HallInterface client ?i_hall,
                            interface QEIInterface client ?i_qei,
                            interface BISSInterface client ?i_biss,
                            interface GPIOInterface client ?i_gpio,
                            interface TorqueControlInterface client i_torque_control,
                            interface VelocityControlInterface client i_velocity_control,
                            interface PositionControlInterface client i_position_control);
