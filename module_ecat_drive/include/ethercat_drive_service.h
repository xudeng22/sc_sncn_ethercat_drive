/**
 * @file ecat_motor_drive.h
 * @brief Ethercat Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

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
void ethercat_drive_service(chanend pdo_out, chanend pdo_in, chanend coe_out,
                        interface MotorcontrolInterface client i_commutation,
                        interface HallInterface client i_hall,
                        interface QEIInterface client i_qei,
                        interface TorqueControlInterface client i_torque_control,
                        interface VelocityControlInterface client i_velocity_control,
                        interface PositionControlInterface client i_position_control,
                        interface GPIOInterface client i_gpio);

int detect_sensor_placement(chanend c_hall, chanend c_qei, chanend c_commutation);

