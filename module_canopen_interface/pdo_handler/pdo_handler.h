#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>
#include "co_interface.h"

/**
 * @brief Structure to store values for PDO exchange with master
 */
typedef struct
{
    /* Input from Master */
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
    /* Output to Master */
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
    uint32_t timestamp;
} pdo_values_t;


/**
 * @brief PDO handler interface for value exchange with the client application
 */
interface i_pdo_handler_exchange
{
    /**
     * @brief Exchange function to update values to and form master
     *
     * @param[in] pdo_out  All output parameters to be sent
     * @return  1. pdo values recently received
     *          2. communication status
     */
    {pdo_values_t, unsigned int} pdo_exchange_app(pdo_values_t pdo_out);

    /**
     * @brief Initialize pdo struct
     *
     * @deprecated Initialize the structure when declared!
     *
     * @return Zero initialized PDO values struct @see pdo_values_t
     */
    pdo_values_t pdo_init(void);
};

/**
 * @brief Writes PDOs from struct into sending buffer.
 * @param[in] pdo_number    PDO number
 * @param[out] buffer       Sending buffer
 * @param[in] InOut         PDO struct
 * @return  Datalength in Byte
 */
char pdo_encode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t InOut);

/**
 * @brief Writes PDOs from sending buffer into struct.
 * @param[in] pdo_number    PDO number
 * @param[in] buffer       Sending buffer
 * @param[out] InOut         PDO struct
 */
void pdo_decode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t &InOut);

/**
 * @brief Writes out going PDOs from pdo_out in InOut; reads in going PDOs from InOut into pdo_in
 * @param[in,out] InOut     PDO struct from CANopen Interface Service.
 * @param[in] pdo_out       PDO struct, which contains new updated values from app to master
 * @param[out] pdo_in       PDO struct, which contains new updated values from master to app
 */
void pdo_exchange(pdo_values_t &InOut, pdo_values_t pdo_out, pdo_values_t &pdo_in);

/**
 *  @brief This function initializes a struct from the type of pdo_values_t
 *
 * @return pdo_values_t with values initialized
 */
pdo_values_t pdo_init_data(void);

/**
 * @brief Get target torque from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target torque from EtherCAT in range [0 - mNm * Current Resolution]
 */
int16_t pdo_get_target_torque(pdo_values_t InOut);

/**
 * @brief Get target velocity from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target velocity from EtherCAT in rpm
 */
int32_t pdo_get_target_velocity(pdo_values_t InOut);

/**
 * @brief Get target position from EtherCAT
 *
 * @param InOut Structure containing all PDO data
 *
 * @return target position from EtherCAT in ticks
 */
int32_t pdo_get_target_position(pdo_values_t InOut);

/**
 * @brief Get the current controlword
 *
 * @param PDO object
 * @return current controlword
 */
uint16_t pdo_get_controlword(pdo_values_t InOut);

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
int8_t pdo_get_op_mode(pdo_values_t InOut);

/**
 * @brief Send actual torque to EtherCAT
 *
 * @param[in] actual_torque sent to EtherCAT in range [0 - mNm * Current Resolution]
 * @param InOut Structure containing all PDO data
 */
void pdo_set_torque_value(int16_t actual_torque, pdo_values_t &InOut);

/**
 * @brief Send actual velocity to EtherCAT
 *
 * @param[in] actual_velocity sent to EtherCAT in rpm
 * @param InOut Structure containing all PDO data
 */
void pdo_set_velocity_value(int32_t actual_velocity, pdo_values_t &InOut);

/**
 * @brief Send actual position to EtherCAT
 *
 * @param[in] actual_position sent to EtherCAT in ticks
 * @param InOut Structure containing all PDO data
 */
void pdo_set_position_value(int32_t actual_position, pdo_values_t &InOut);

/**
 * @brief Send the current status
 *
 * @param statusword  the current statusword
 * @param InOut PDO object
 */
void pdo_set_statusword(uint16_t statusword, pdo_values_t &InOut);

/**
 * @brief Send to currently active operation mode
 *
 * @param opmode the currently active operation mode
 * @param InOut PDO object
 */
void pdo_set_opmode_display(int8_t opmode, pdo_values_t &InOut);

int32_t pdo_get_offset_torque(pdo_values_t InOut);

uint32_t pdo_get_tuning_command(pdo_values_t InOut);

uint8_t pdo_get_digital_output1(pdo_values_t InOut);

uint8_t pdo_get_digital_output2(pdo_values_t InOut);

uint8_t pdo_get_digital_output3(pdo_values_t InOut);

uint8_t pdo_get_digital_output4(pdo_values_t InOut);

uint32_t pdo_get_user_mosi(pdo_values_t InOut);

void pdo_set_statusword(uint16_t value, pdo_values_t &InOut);

void pdo_set_op_mode_display(int8_t value, pdo_values_t &InOut);

void pdo_set_secondary_position_value(int32_t value, pdo_values_t &InOut);

void pdo_set_secondary_velocity_value(int32_t value, pdo_values_t &InOut);

void pdo_set_analog_input1(uint16_t value, pdo_values_t &InOut);

void pdo_set_analog_input2(uint16_t value, pdo_values_t &InOut);

void pdo_set_analog_input3(uint16_t value, pdo_values_t &InOut);

void pdo_set_analog_input4(uint16_t value, pdo_values_t &InOut);

void pdo_set_tuning_status(uint32_t value, pdo_values_t &InOut);

void pdo_set_digital_input1(uint8_t value, pdo_values_t &InOut);

void pdo_set_digital_input2(uint8_t value, pdo_values_t &InOut);

void pdo_set_digital_input3(uint8_t value, pdo_values_t &InOut);

void pdo_set_digital_input4(uint8_t value, pdo_values_t &InOut);

void pdo_set_user_miso(uint32_t value, pdo_values_t &InOut);

void pdo_set_timestamp(uint32_t value, pdo_values_t &InOut);
