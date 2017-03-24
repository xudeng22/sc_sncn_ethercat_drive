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
    uint32_t tuning_command;
    uint8_t digital_output1;
    uint8_t digital_output2;
    uint8_t digital_output3;
    uint8_t digital_output4;
    uint32_t user_mosi;
    uint16_t statusword;
    int8_t op_mode_display;
    int32_t position_value;
    int32_t velocity_value;
    int16_t torque_value;
    int32_t secondary_position_value;
    int32_t secondary_velocity_value;
    uint16_t analog_input1;
    uint16_t analog_input2;
    uint16_t analog_input3;
    uint16_t analog_input4;
    uint32_t tuning_status;
    uint8_t digital_input1;
    uint8_t digital_input2;
    uint8_t digital_input3;
    uint8_t digital_input4;
    uint32_t user_miso;
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
int pdo_get_tuning_command(pdo_handler_values_t &InOut);
int pdo_get_dgitial_output1(pdo_handler_values_t &InOut);
int pdo_get_dgitial_output2(pdo_handler_values_t &InOut);
int pdo_get_dgitial_output3(pdo_handler_values_t &InOut);
int pdo_get_dgitial_output4(pdo_handler_values_t &InOut);
int pdo_get_user_mosi(pdo_handler_values_t &InOut);

void pdo_set_secondary_position_value(int value, pdo_handler_values_t &InOut);
void pdo_set_secondary_velocity_value(int value, pdo_handler_values_t &InOut);
void pdo_set_analog_input1(int value, pdo_handler_values_t &InOut);
void pdo_set_analog_input2(int value, pdo_handler_values_t &InOut);
void pdo_set_analog_input3(int value, pdo_handler_values_t &InOut);
void pdo_set_analog_input4(int value, pdo_handler_values_t &InOut);
void pdo_set_tuning_status(int value, pdo_handler_values_t &InOut);
void pdo_set_digital_input1(int value, pdo_handler_values_t &InOut);
void pdo_set_digital_input2(int value, pdo_handler_values_t &InOut);
void pdo_set_digital_input3(int value, pdo_handler_values_t &InOut);
void pdo_set_digital_input4(int value, pdo_handler_values_t &InOut);
void pdo_set_user_miso(int value, pdo_handler_values_t &InOut);
