/**
 * @file pdo_handler.h
 * @brief Control Protocol for PDOs
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>

#include <ethercat_service.h>

/**
 * @brief
 *  Struct for Tx, Rx PDOs
 */
typedef struct
{
    uint16_t controlword;
    int8_t op_mode;
    int16_t target_torque;
    int32_t target_position;
    int32_t target_velocity;
    int32_t offset_torque;
    int32_t tuning_status;
    int32_t tuning_control;
    int32_t command_pid_update;
    uint16_t statusword;
    int8_t op_mode_display;
    int32_t position_value;
    int32_t velocity_value;
    int16_t torque_value;
    int32_t additional_feedbacksensor_value;
    int32_t tuning_result;
} pdo_handler_values_t;



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
int pdo_handler(client interface i_pdo_communication i_pdo, pdo_handler_values_t &InOut);

/**
 *  @brief
 *       This function initializes a struct from the type of pdo_handler_values_t
 *
 *      \return pdo_handler_values_t with values initialized
 */
pdo_handler_values_t pdo_handler_init(void);

/**
 * @brief Get target torque from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target torque from EtherCAT in range [0 - mNm * Current Resolution]
 */
int pdo_get_target_torque(pdo_handler_values_t InOut);

/**
 * @brief Get target velocity from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target velocity from EtherCAT in rpm
 */
int pdo_get_target_velocity(pdo_handler_values_t InOut);

/**
 * @brief Get target position from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target position from EtherCAT in ticks
 */
int pdo_get_target_position(pdo_handler_values_t InOut);

/**
 * @brief Get the current controlword
 *
 * @param PDO object
 * @return current controlword
 */
int pdo_get_controlword(pdo_handler_values_t InOut);

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
int pdo_get_opmode(pdo_handler_values_t InOut);

/**
 * @brief Send actual torque to EtherCAT
 *
 * @param[in] actual_torque sent to EtherCAT in range [0 - mNm * Current Resolution]
 * @param InOut Structure containing all PDO data
 */
void pdo_set_torque_value(int actual_torque, pdo_handler_values_t &InOut);

/**
 * @brief Send actual velocity to EtherCAT
 *
 * @param[in] actual_velocity sent to EtherCAT in rpm
 * @param InOut Structure containing all PDO data
 */
void pdo_set_velocity_value(int actual_velocity, pdo_handler_values_t &InOut);

/**
 * @brief Send actual position to EtherCAT
 *
 * @param[in] actual_position sent to EtherCAT in ticks
 * @param InOut Structure containing all PDO data
 */
void pdo_set_position_value(int actual_position, pdo_handler_values_t &InOut);

/**
 * @brief Send the current status
 *
 * @param statusword  the current statusword
 * @param InOut PDO object
 */
void pdo_set_statusword(int statusword, pdo_handler_values_t &InOut);

/**
 * @brief Send to currently active operation mode
 *
 * @param opmode the currently active operation mode
 * @param InOut PDO object
 */
void pdo_set_opmode_display(int opmode, pdo_handler_values_t &InOut);


int pdo_get_offset_torque(pdo_handler_values_t &InOut);
int pdo_get_tuning_status(pdo_handler_values_t &InOut);
int pdo_get_tuning_control(pdo_handler_values_t &InOut);
int pdo_get_command_pid_update(pdo_handler_values_t &InOut);
void pdo_set_tuning_result(int value, pdo_handler_values_t &InOut);
void pdo_set_additional_feedbacksensor_value(int value, pdo_handler_values_t &InOut);
