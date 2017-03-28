#include <ethercat_service.h>
#include <pdo_handler.h>

#define MAX_PDO_SIZE 64

int pdo_handler(client interface i_pdo_communication i_pdo, pdo_handler_values_t &inout)
{

    unsigned char buffer[MAX_PDO_SIZE];
    unsigned int count = 0;

    count = i_pdo.get_pdos_value(buffer);

    if(count > 0)
    {
        inout.controlword = buffer[1] << 8 | buffer[0];
        inout.op_mode = buffer[2];
        inout.target_torque = buffer[4] << 8 | buffer[3];
        inout.target_position = buffer[8] << 24 | buffer[7] << 16 | buffer[6] << 8 | buffer[5];
        inout.target_velocity = buffer[12] << 24 | buffer[11] << 16 | buffer[10] << 8 | buffer[9];
        inout.offset_torque = buffer[16] << 24 | buffer[15] << 16 | buffer[14] << 8 | buffer[13];
        inout.tuning_command = buffer[20] << 24 | buffer[19] << 16 | buffer[18] << 8 | buffer[17];
        inout.digital_output1 = buffer[21];
        inout.digital_output2 = buffer[22];
        inout.digital_output3 = buffer[23];
        inout.digital_output4 = buffer[24];
        inout.user_mosi = buffer[28] << 24 | buffer[27] << 16 | buffer[26] << 8 | buffer[25];
    }

    size_t pdo_count = 0;
    if(count > 0)
    {
        buffer[0] = inout.statusword;
        buffer[1] = inout.statusword >> 8;
        buffer[2] = inout.op_mode_display;
        buffer[3] = inout.position_value;
        buffer[4] = inout.position_value >> 8;
        buffer[5] = inout.position_value >> 16;
        buffer[6] = inout.position_value >> 24;
        buffer[7] = inout.velocity_value;
        buffer[8] = inout.velocity_value >> 8;
        buffer[9] = inout.velocity_value >> 16;
        buffer[10] = inout.velocity_value >> 24;
        buffer[11] = inout.torque_value;
        buffer[12] = inout.torque_value >> 8;
        buffer[13] = inout.secondary_position_value;
        buffer[14] = inout.secondary_position_value >> 8;
        buffer[15] = inout.secondary_position_value >> 16;
        buffer[16] = inout.secondary_position_value >> 24;
        buffer[17] = inout.secondary_velocity_value;
        buffer[18] = inout.secondary_velocity_value >> 8;
        buffer[19] = inout.secondary_velocity_value >> 16;
        buffer[20] = inout.secondary_velocity_value >> 24;
        buffer[21] = inout.analog_input1;
        buffer[22] = inout.analog_input1 >> 8;
        buffer[23] = inout.analog_input2;
        buffer[24] = inout.analog_input2 >> 8;
        buffer[25] = inout.analog_input3;
        buffer[26] = inout.analog_input3 >> 8;
        buffer[27] = inout.analog_input4;
        buffer[28] = inout.analog_input4 >> 8;
        buffer[29] = inout.tuning_status;
        buffer[30] = inout.tuning_status >> 8;
        buffer[31] = inout.tuning_status >> 16;
        buffer[32] = inout.tuning_status >> 24;
        buffer[33] = inout.digital_input1;
        buffer[34] = inout.digital_input2;
        buffer[35] = inout.digital_input3;
        buffer[36] = inout.digital_input4;
        buffer[37] = inout.user_miso;
        buffer[38] = inout.user_miso >> 8;
        buffer[39] = inout.user_miso >> 16;
        buffer[40] = inout.user_miso >> 24;
        buffer[41] = inout.timestamp;
        buffer[42] = inout.timestamp >> 8;
        buffer[43] = inout.timestamp >> 16;
        buffer[44] = inout.timestamp >> 24;

        pdo_count = 45;
        i_pdo.set_pdos_value(buffer, pdo_count);
    }

    return count;
}

uint16_t pdo_get_controlword(pdo_handler_values_t InOut)
{
    return InOut.controlword;
}

int8_t pdo_get_op_mode(pdo_handler_values_t InOut)
{
    return InOut.op_mode;
}

int16_t pdo_get_target_torque(pdo_handler_values_t InOut)
{
    return InOut.target_torque;
}

int32_t pdo_get_target_position(pdo_handler_values_t InOut)
{
    return InOut.target_position;
}

int32_t pdo_get_target_velocity(pdo_handler_values_t InOut)
{
    return InOut.target_velocity;
}

int32_t pdo_get_offset_torque(pdo_handler_values_t InOut)
{
    return InOut.offset_torque;
}

uint32_t pdo_get_tuning_command(pdo_handler_values_t InOut)
{
    return InOut.tuning_command;
}

uint8_t pdo_get_digital_output1(pdo_handler_values_t InOut)
{
    return InOut.digital_output1;
}

uint8_t pdo_get_digital_output2(pdo_handler_values_t InOut)
{
    return InOut.digital_output2;
}

uint8_t pdo_get_digital_output3(pdo_handler_values_t InOut)
{
    return InOut.digital_output3;
}

uint8_t pdo_get_digital_output4(pdo_handler_values_t InOut)
{
    return InOut.digital_output4;
}

uint32_t pdo_get_user_mosi(pdo_handler_values_t InOut)
{
    return InOut.user_mosi;
}

void pdo_set_statusword(uint16_t value, pdo_handler_values_t &InOut)
{
    InOut.statusword = value;
}

void pdo_set_op_mode_display(int8_t value, pdo_handler_values_t &InOut)
{
    InOut.op_mode_display = value;
}

void pdo_set_position_value(int32_t value, pdo_handler_values_t &InOut)
{
    InOut.position_value = value;
}

void pdo_set_velocity_value(int32_t value, pdo_handler_values_t &InOut)
{
    InOut.velocity_value = value;
}

void pdo_set_torque_value(int16_t value, pdo_handler_values_t &InOut)
{
    InOut.torque_value = value;
}

void pdo_set_secondary_position_value(int32_t value, pdo_handler_values_t &InOut)
{
    InOut.secondary_position_value = value;
}

void pdo_set_secondary_velocity_value(int32_t value, pdo_handler_values_t &InOut)
{
    InOut.secondary_velocity_value = value;
}

void pdo_set_analog_input1(uint16_t value, pdo_handler_values_t &InOut)
{
    InOut.analog_input1 = value;
}

void pdo_set_analog_input2(uint16_t value, pdo_handler_values_t &InOut)
{
    InOut.analog_input2 = value;
}

void pdo_set_analog_input3(uint16_t value, pdo_handler_values_t &InOut)
{
    InOut.analog_input3 = value;
}

void pdo_set_analog_input4(uint16_t value, pdo_handler_values_t &InOut)
{
    InOut.analog_input4 = value;
}

void pdo_set_tuning_status(uint32_t value, pdo_handler_values_t &InOut)
{
    InOut.tuning_status = value;
}

void pdo_set_digital_input1(uint8_t value, pdo_handler_values_t &InOut)
{
    InOut.digital_input1 = value;
}

void pdo_set_digital_input2(uint8_t value, pdo_handler_values_t &InOut)
{
    InOut.digital_input2 = value;
}

void pdo_set_digital_input3(uint8_t value, pdo_handler_values_t &InOut)
{
    InOut.digital_input3 = value;
}

void pdo_set_digital_input4(uint8_t value, pdo_handler_values_t &InOut)
{
    InOut.digital_input4 = value;
}

void pdo_set_user_miso(uint32_t value, pdo_handler_values_t &InOut)
{
    InOut.user_miso = value;
}

void pdo_set_timestamp(uint32_t value, pdo_handler_values_t &InOut)
{
    InOut.timestamp = value;
}
