/**
 * @file pdo_handler.h
 * @brief Control Protocol for PDOs
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>
#include "co_interface.h"
//#include <canod.h>

#define PDO_BYTES_SIZE 30
#define PDO_WORDS_SIZE 15

#define PDO_BUFFER_SIZE    64

/**
* @brief Control word to request PDO data.
*/
#define DATA_REQUEST     1



/**
 * @brief
 *  This function receives channel communication from the ctrlproto_pdo_handler_thread
 *  It updates the referenced values according to the command and has to be placed
 *  inside the control loop.
 *
 *  This function is not considered as stand alone thread! It's for being executed in
 *  the motor control thread
 *
 * @param pdo_out       Channel for outgoing process data objects
 * @param pdo_in        Channel for incoming process data objects
 * @param InOut         Struct for exchanging data with the motor control functions
 *
 * @return      1 if communication is active else 0
 */
//int pdo_protocol_handler(client interface PDOCommunicationInterface i_pdo, pdo_values_t &InOut);
void pdo_protocol_handler(pdo_size_t buffer[], pdo_values_t &InOut);

//void pdo_encode_buffer(pdo_size_t buffer[], pdo_values_t InOut);
//void pdo_decode_buffer(pdo_size_t buffer[], pdo_values_t &InOut);

char pdo_encode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t InOut);
void pdo_decode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t &InOut);

void pdo_exchange(pdo_values_t &InOut, pdo_values_t pdo_out, pdo_values_t &pdo_in);
/**
 *  @brief
 *       This function initializes a struct from the type of pdo_values_t
 *
 *      \return pdo_values_t with values initialized
 */
pdo_values_t pdo_init_data(void);

/**
 * @brief Get target torque from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target torque from EtherCAT in range [0 - mNm * Current Resolution]
 */
int pdo_get_target_torque(pdo_values_t InOut);

/**
 * @brief Get target velocity from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target velocity from EtherCAT in rpm
 */
int pdo_get_target_velocity(pdo_values_t InOut);

/**
 * @brief Get target position from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target position from EtherCAT in ticks
 */
int pdo_get_target_position(pdo_values_t InOut);

/**
 * @brief Get the current controlword
 *
 * @param PDO object
 * @return current controlword
 */
int pdo_get_controlword(pdo_values_t InOut);

/**
 * @brief Get current operation mode request
 *
 * Please keep in mind, the operation mode will only change in state "Switch on
 * Disabled". While the device is not in "Switch on Disable" the new opmode is
 * stored and set after the device comes back to "Switch on Disabled" and will
 * be set there.
 *
 * @param PDO object
 * @return current operation mode request
 */
int pdo_get_opmode(pdo_values_t InOut);

/**
 * @brief Send actual torque to EtherCAT
 *
 * @param[in] actual_torque sent to EtherCAT in range [0 - mNm * Current Resolution]
 * @param InOut Structure containing all PDO data
 */
void pdo_set_torque_value(int actual_torque, pdo_values_t &InOut);

/**
 * @brief Send actual velocity to EtherCAT
 *
 * @param[in] actual_velocity sent to EtherCAT in rpm
 * @param InOut Structure containing all PDO data
 */
void pdo_set_velocity_value(int actual_velocity, pdo_values_t &InOut);

/**
 * @brief Send actual position to EtherCAT
 *
 * @param[in] actual_position sent to EtherCAT in ticks
 * @param InOut Structure containing all PDO data
 */
void pdo_set_position_value(int actual_position, pdo_values_t &InOut);

/**
 * @brief Send the current status
 *
 * @param statusword  the current statusword
 * @param InOut PDO object
 */
void pdo_set_statusword(int statusword, pdo_values_t &InOut);

/**
 * @brief Send to currently active operation mode
 *
 * @param opmode the currently active operation mode
 * @param InOut PDO object
 */
void pdo_set_opmode_display(int opmode, pdo_values_t &InOut);

int pdo_get_offset_torque(pdo_values_t &InOut);
int pdo_get_tuning_command(pdo_values_t &InOut);
int pdo_get_dgitial_output1(pdo_values_t &InOut);
int pdo_get_dgitial_output2(pdo_values_t &InOut);
int pdo_get_dgitial_output3(pdo_values_t &InOut);
int pdo_get_dgitial_output4(pdo_values_t &InOut);
int pdo_get_user_mosi(pdo_values_t &InOut);

void pdo_set_secondary_position_value(int value, pdo_values_t &InOut);
void pdo_set_secondary_velocity_value(int value, pdo_values_t &InOut);
void pdo_set_analog_input1(int value, pdo_values_t &InOut);
void pdo_set_analog_input2(int value, pdo_values_t &InOut);
void pdo_set_analog_input3(int value, pdo_values_t &InOut);
void pdo_set_analog_input4(int value, pdo_values_t &InOut);
void pdo_set_tuning_status(int value, pdo_values_t &InOut);
void pdo_set_digital_input1(int value, pdo_values_t &InOut);
void pdo_set_digital_input2(int value, pdo_values_t &InOut);
void pdo_set_digital_input3(int value, pdo_values_t &InOut);
void pdo_set_digital_input4(int value, pdo_values_t &InOut);
void pdo_set_user_miso(int value, pdo_values_t &InOut);
