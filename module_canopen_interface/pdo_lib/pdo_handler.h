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
 *  Struct for Tx, Rx PDOs
 */
typedef struct
{
    int8_t operation_mode;     //      Modes of Operation
    uint16_t control_word;     //      Control Word

    int16_t target_torque;
    int32_t target_velocity;
    int32_t target_position;

    /* User defined PDOs */
    int32_t user1_in;
    int32_t user2_in;
    int32_t user3_in;
    int32_t user4_in;


    int8_t operation_mode_display; //      Modes of Operation Display
    uint16_t status_word;                   //  Status Word

    int16_t actual_torque;
    int32_t actual_velocity;
    int32_t actual_position;

    /* User defined PDOs */
    int32_t user1_out;
    int32_t user2_out;
    int32_t user3_out;
    int32_t user4_out;
} pdo_values_t;

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
int pdo_protocol_handler(client interface PDOCommunicationInterface i_pdo, pdo_values_t &InOut);

/**
 *  @brief
 *       This function initializes a struct from the type of pdo_values_t
 *
 *      \return pdo_values_t with values initialized
 */
pdo_values_t pdo_init(void);

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
void pdo_set_actual_torque(int actual_torque, pdo_values_t &InOut);

/**
 * @brief Send actual velocity to EtherCAT
 *
 * @param[in] actual_velocity sent to EtherCAT in rpm
 * @param InOut Structure containing all PDO data
 */
void pdo_set_actual_velocity(int actual_velocity, pdo_values_t &InOut);

/**
 * @brief Send actual position to EtherCAT
 *
 * @param[in] actual_position sent to EtherCAT in ticks
 * @param InOut Structure containing all PDO data
 */
void pdo_set_actual_position(int actual_position, pdo_values_t &InOut);

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
