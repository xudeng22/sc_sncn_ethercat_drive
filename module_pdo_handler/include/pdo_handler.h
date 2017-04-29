#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>

#include <ethercat_service.h>

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
    uint32_t timestamp;
} pdo_handler_values_t;

int pdo_handler(client interface i_pdo_communication i_pdo, pdo_handler_values_t &InOut);

uint16_t pdo_get_controlword(pdo_handler_values_t InOut);

int8_t pdo_get_op_mode(pdo_handler_values_t InOut);

int16_t pdo_get_target_torque(pdo_handler_values_t InOut);

int32_t pdo_get_target_position(pdo_handler_values_t InOut);

int32_t pdo_get_target_velocity(pdo_handler_values_t InOut);

int32_t pdo_get_offset_torque(pdo_handler_values_t InOut);

uint32_t pdo_get_tuning_command(pdo_handler_values_t InOut);

uint8_t pdo_get_digital_output1(pdo_handler_values_t InOut);

uint8_t pdo_get_digital_output2(pdo_handler_values_t InOut);

uint8_t pdo_get_digital_output3(pdo_handler_values_t InOut);

uint8_t pdo_get_digital_output4(pdo_handler_values_t InOut);

uint32_t pdo_get_user_mosi(pdo_handler_values_t InOut);

void pdo_set_statusword(uint16_t value, pdo_handler_values_t &InOut);

void pdo_set_op_mode_display(int8_t value, pdo_handler_values_t &InOut);

void pdo_set_position_value(int32_t value, pdo_handler_values_t &InOut);

void pdo_set_velocity_value(int32_t value, pdo_handler_values_t &InOut);

void pdo_set_torque_value(int16_t value, pdo_handler_values_t &InOut);

void pdo_set_secondary_position_value(int32_t value, pdo_handler_values_t &InOut);

void pdo_set_secondary_velocity_value(int32_t value, pdo_handler_values_t &InOut);

void pdo_set_analog_input1(uint16_t value, pdo_handler_values_t &InOut);

void pdo_set_analog_input2(uint16_t value, pdo_handler_values_t &InOut);

void pdo_set_analog_input3(uint16_t value, pdo_handler_values_t &InOut);

void pdo_set_analog_input4(uint16_t value, pdo_handler_values_t &InOut);

void pdo_set_tuning_status(uint32_t value, pdo_handler_values_t &InOut);

void pdo_set_digital_input1(uint8_t value, pdo_handler_values_t &InOut);

void pdo_set_digital_input2(uint8_t value, pdo_handler_values_t &InOut);

void pdo_set_digital_input3(uint8_t value, pdo_handler_values_t &InOut);

void pdo_set_digital_input4(uint8_t value, pdo_handler_values_t &InOut);

void pdo_set_user_miso(uint32_t value, pdo_handler_values_t &InOut);

void pdo_set_timestamp(uint32_t value, pdo_handler_values_t &InOut);
