/**
 * @file pdo_handler.xc
 * @brief Control Protocol PDO Parser
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include "pdo_handler.h"
#include "canod_constants.h"
#include "canod.h"

#define MAX_PDO_BUFFER_SIZE    15

enum {
    READ_FROM_OD = 0,
    WRITE_TO_OD = 1,
};

pdo_values_t pdo_init_data(void)
{
	pdo_values_t inout;

    inout.controlword    = 0x00;           // shutdown
    inout.op_mode  = 0x00;           // undefined

    inout.target_torque   = 0x0;
    inout.target_velocity = 0x0;
    inout.target_position = 0x0;

    inout.offset_torque        = 0x0;
    inout.tuning_command        = 0x0;
    inout.digital_output1        = 0x0;
    inout.digital_output2        = 0x0;
    inout.digital_output3        = 0x0;
    inout.digital_output4        = 0x0;
    inout.user_mosi        = 0x0;


    inout.statusword     = 0x0000;         // not set
    inout.op_mode_display = 0x00;    /* no operation mode selected */

    inout.actual_torque   = 0x0;
    inout.actual_velocity = 0x0;
    inout.actual_position = 0x0;

    inout.secondary_position_value       = 0x0;
    inout.secondary_velocity_value       = 0x0;
    inout.analog_input1       = 0x0;
    inout.analog_input2       = 0x0;
    inout.analog_input3       = 0x0;
    inout.analog_input4       = 0x0;

    inout.tuning_status       = 0x0;
    inout.digital_input1       = 0x0;
    inout.digital_input2       = 0x0;
    inout.digital_input3       = 0x0;
    inout.digital_input4       = 0x0;
    inout.user_miso         = 0x0;

	return inout;
}

char pdo_read_write_data_od(int index, char data_buffer[], char write)
{
    int address = 0;
    char count = 0,
        no_of_entries = 0,
        sub_index = 0,
        data_length = 0,
        data_counter = 0;
    unsigned bitlength = 0,
            entries = 0,
            value;

    canod_get_entry(index, 0, entries, bitlength);
    no_of_entries = entries & 0xff;

    while(count != no_of_entries)
    {
        canod_get_entry(index, count + 1, entries, bitlength);
        address = (entries >> 16) & 0xffff;
        sub_index = (entries >> 8) & 0xff;
        data_length = (entries & 0xff)/8;
        count++;

        if (write) {
            for (unsigned i = 0; i < data_length; i++) {
                value |= (unsigned) (data_buffer[data_counter + i] << (8*i) );
            }
            canod_set_entry(address, sub_index, value, 1);
        } else {
            canod_get_entry(address, sub_index, value, bitlength);
            for (unsigned i = 0; i < data_length; i++) {
                data_buffer[data_counter + i] = (value >> (8*i) ) & 0xff;
            }
        }
        data_counter += data_length;
    }
    return data_counter;
}

//char pdo_read_data_from_od(unsigned address, char data_buffer[8])
//{
//    int index = 0,
//        temp_index = 0;
//    char entries[4], count = 0, no_of_entries, sub_index, data_length,
//    data_counter = 0;
//    char error = 0, bitlength = 0;
//
//    index = canod_find_index(address, 0);
//    canod_get_entry(index, (entries, unsigned), bitlength);
//    no_of_entries = entries[0];
//
//    while(count != no_of_entries)
//    {
//        canod_get_entry(index + count + 1, (entries, unsigned), bitlength);
//        address = (entries[2]) | (entries[3] << 8);
//        sub_index = entries[1];
//        data_length = entries[0];
//        count++;
//
//        temp_index = i_co.od_find_index(mapping_parameter, sub_index);
//
//        if (temp_index != -1) {
//            canod_get_entry(temp_index, &data_buffer[(int)data_counter], bitlength);
//        }
//        data_counter += data_length/8;
//    }
//    return (data_counter);
//}

void pdo_exchange(pdo_values_t &inout, pdo_values_t pdo_out, pdo_values_t &pdo_in)
{

    inout.statusword    = pdo_out.statusword;
    inout.op_mode_display  = pdo_out.op_mode_display;
    inout.actual_torque   = pdo_out.actual_torque;
    inout.actual_position = pdo_out.actual_position;
    inout.actual_velocity = pdo_out.actual_velocity;
    inout.secondary_position_value       = pdo_out.secondary_position_value;
    inout.secondary_velocity_value       = pdo_out.secondary_velocity_value;
    inout.analog_input1       = pdo_out.analog_input1;
    inout.analog_input2       = pdo_out.analog_input2;
    inout.analog_input3       = pdo_out.analog_input3;
    inout.analog_input4       = pdo_out.analog_input4;
    inout.tuning_status       = pdo_out.tuning_status;
    inout.digital_input1       = pdo_out.digital_input1;
    inout.digital_input2       = pdo_out.digital_input2;
    inout.digital_input3       = pdo_out.digital_input3;
    inout.digital_input4       = pdo_out.digital_input4;
    inout.user_miso       = pdo_out.user_miso;

    pdo_in.controlword    = inout.controlword;
    pdo_in.op_mode  = inout.op_mode;
    pdo_in.target_torque   = inout.target_torque;
    pdo_in.target_position = inout.target_position;
    pdo_in.target_velocity = inout.target_velocity;
    pdo_in.offset_torque        = inout.offset_torque;
    pdo_in.tuning_command        = inout.tuning_command;
    pdo_in.digital_output1        = inout.digital_output1;
    pdo_in.digital_output2        = inout.digital_output2;
    pdo_in.digital_output3        = inout.digital_output3;
    pdo_in.digital_output4        = inout.digital_output4;
    pdo_in.user_mosi        = inout.user_mosi;

}

#if COM_ETHERCAT || COM_ETHERNET

void pdo_decode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t &inout)
{
    switch (pdo_number)
    {
        case 0:
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
            break;
        default:
            break;
    }
}

char pdo_encode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t inout)
{
    char data_length = 0;

    switch (pdo_number)
    {
        case 0:
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
            data_length = 41;
            break;
        default:
            break;
    }
    return data_length;
}

#elif COM_CAN

void pdo_decode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t &inout)
{
    switch (pdo_number)
    {
        case 0:
            inout.controlword = buffer[1] << 8 | buffer[0];
            inout.op_mode = buffer[2];
            inout.target_torque = buffer[4] << 8 | buffer[3];
            //pdo_read_write_data_od((RPDO_COMMUNICATION_PARAMETER + pdo_number), (value, char[]), WRITE_TO_OD);
            break;
        case 1:
            inout.target_position = buffer[3] << 24 | buffer[2] << 16 | buffer[1] << 8 | buffer[0];
            inout.target_velocity = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
            //pdo_read_write_data_od(RPDO_0_COMMUNICATION_PARAMETER + pdo_number, (value, char[]), WRITE_TO_OD);
            break;
        case 2:
            inout.offset_torque = buffer[3] << 24 | buffer[2] << 16 | buffer[1] << 8 | buffer[0];
            inout.tuning_command = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
            break;
        case 3:
            inout.digital_output1 = buffer[0];
            inout.digital_output2 = buffer[1];
            inout.digital_output3 = buffer[2];
            inout.digital_output4 = buffer[3];
            inout.user_mosi = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
            break;
        default:
            break;
    }
}

char pdo_encode(unsigned char pdo_number, pdo_size_t buffer[], pdo_values_t inout)
{
    char data_length = 0;

    switch (pdo_number)
    {
        case 0:
            buffer[0] = inout.statusword;
            buffer[1] = inout.statusword >> 8;
            buffer[2] = inout.op_mode_display;
            buffer[3] = inout.actual_torque & 0xff;
            buffer[4] = (inout.actual_torque >> 8) & 0xff;
            data_length = 5;
            //data_length = pdo_read_write_data_od((TPDO_COMMUNICATION_PARAMETER + pdo_number), (value, char[]), WRITE_TO_OD);
            break;
        case 1:
            buffer[0] = inout.actual_position & 0xff;
            buffer[1] = (inout.actual_position >> 8) & 0xff;
            buffer[2] = (inout.actual_position >> 16) & 0xff;
            buffer[3] = (inout.actual_position >> 24) & 0xff;
            buffer[4] = (inout.actual_velocity) & 0xff;
            buffer[5] = (inout.actual_velocity >> 8) & 0xff;
            buffer[6] = (inout.actual_velocity >> 16) & 0xff;
            buffer[7] = (inout.actual_velocity >> 24) & 0xff;
            data_length = 8;
            //data_length = pdo_read_write_data_od(TPDO_0_COMMUNICATION_PARAMETER + pdo_number, (value, char[]), WRITE_TO_OD);
            break;
        case 2:
            buffer[0] = inout.secondary_position_value;
            buffer[1] = inout.secondary_position_value >> 8;
            buffer[2] = inout.secondary_position_value >> 16;
            buffer[3] = inout.secondary_position_value >> 24;
            buffer[4] = inout.secondary_velocity_value;
            buffer[5] = inout.secondary_velocity_value >> 8;
            buffer[6] = inout.secondary_velocity_value >> 16;
            buffer[7] = inout.secondary_velocity_value >> 24;
            data_length = 8;
            break;
        case 3:
            buffer[0] = inout.analog_input1;
            buffer[1] = inout.analog_input1 >> 8;
            buffer[2] = inout.analog_input2;
            buffer[3] = inout.analog_input2 >> 8;
            buffer[4] = inout.analog_input3;
            buffer[5] = inout.analog_input3 >> 8;
            buffer[6] = inout.analog_input4;
            buffer[7] = inout.analog_input4 >> 8;
            data_length = 8;
            break;
        case 4:
            buffer[0] = inout.tuning_status;
            buffer[1] = inout.tuning_status >> 8;
            buffer[2] = inout.tuning_status >> 16;
            buffer[3] = inout.tuning_status >> 24;
            buffer[4] = inout.user_miso;
            buffer[5] = inout.user_miso >> 8;
            buffer[6] = inout.user_miso >> 16;
            buffer[7] = inout.user_miso >> 24;
            data_length = 8;
            break;
        case 5:
            buffer[0] = inout.digital_input1;
            buffer[1] = inout.digital_input2;
            buffer[2] = inout.digital_input3;
            buffer[3] = inout.digital_input4;
            data_length = 4;
            break;
        default:
            break;
    }

    return data_length;
}

#endif

int pdo_get_target_torque(pdo_values_t inout)
{
    return inout.target_torque;
}

int pdo_get_target_velocity(pdo_values_t inout)
{
    return inout.target_velocity;
}

int pdo_get_target_position(pdo_values_t inout)
{
    return inout.target_position;
}

int pdo_get_controlword(pdo_values_t inout)
{
    return inout.controlword;
}

int pdo_get_opmode(pdo_values_t inout)
{
    return inout.op_mode;
}

void pdo_set_torque_value(int actual_torque, pdo_values_t &inout)
{
    inout.actual_torque = actual_torque;
}

void pdo_set_velocity_value(int actual_velocity, pdo_values_t &inout)
{
    inout.actual_velocity = actual_velocity;
}

void pdo_set_position_value(int actual_position, pdo_values_t &inout)
{
    inout.actual_position = actual_position;
}

void pdo_set_statusword(int statusword, pdo_values_t &inout)
{
    inout.statusword = statusword & 0xffff;
}

void pdo_set_opmode_display(int opmode, pdo_values_t &inout)
{
    inout.op_mode_display = opmode & 0xff;
}

int pdo_get_offset_torque(pdo_values_t &inout)
{
    return inout.offset_torque;
}

int pdo_get_tuning_command(pdo_values_t &inout)
{
    return inout.tuning_command;
}

int pdo_get_dgitial_output1(pdo_values_t &inout)
{
    return inout.digital_output1;
}

int pdo_get_dgitial_output2(pdo_values_t &inout)
{
    return inout.digital_output2;
}

int pdo_get_dgitial_output3(pdo_values_t &inout)
{
    return inout.digital_output3;
}

int pdo_get_dgitial_output4(pdo_values_t &inout)
{
    return inout.digital_output4;
}

int pdo_get_user_mosi(pdo_values_t &inout)
{
    return inout.user_mosi;
}

void pdo_set_secondary_position_value(int value, pdo_values_t &inout)
{
    inout.secondary_position_value = value;
}

void pdo_set_secondary_velocity_value(int value, pdo_values_t &inout)
{
    inout.secondary_velocity_value = value;
}

void pdo_set_analog_input1(int value, pdo_values_t &inout)
{
    inout.analog_input1 = value;
}

void pdo_set_analog_input2(int value, pdo_values_t &inout)
{
    inout.analog_input2 = value;
}

void pdo_set_analog_input3(int value, pdo_values_t &inout)
{
    inout.analog_input3 = value;
}

void pdo_set_analog_input4(int value, pdo_values_t &inout)
{
    inout.analog_input4 = value;
}

void pdo_set_tuning_status(int value, pdo_values_t &inout)
{
    inout.tuning_status = value;
}

void pdo_set_digital_input1(int value, pdo_values_t &inout)
{
    inout.digital_input1 = value;
}

void pdo_set_digital_input2(int value, pdo_values_t &inout)
{
    inout.digital_input2 = value;
}

void pdo_set_digital_input3(int value, pdo_values_t &inout)
{
    inout.digital_input3 = value;
}

void pdo_set_digital_input4(int value, pdo_values_t &inout)
{
    inout.digital_input4 = value;
}

void pdo_set_user_miso(int value, pdo_values_t &inout)
{
    inout.user_miso = value;
}
