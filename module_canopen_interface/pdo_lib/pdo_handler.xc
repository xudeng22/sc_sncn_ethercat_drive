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
	pdo_values_t InOut;

    InOut.control_word    = 0x00;           // shutdown
    InOut.operation_mode  = 0x00;           // undefined

    InOut.target_torque   = 0x0;
    InOut.target_velocity = 0x0;
    InOut.target_position = 0x0;

    InOut.user1_in        = 0x0;
    InOut.user2_in        = 0x0;
    InOut.user3_in        = 0x0;
    InOut.user4_in        = 0x0;

    InOut.status_word     = 0x0000;         // not set
    InOut.operation_mode_display = 0x00;    /* no operation mode selected */

    InOut.actual_torque   = 0x0;
    InOut.actual_velocity = 0x0;
    InOut.actual_position = 0x0;

    InOut.user1_out       = 0x0;
    InOut.user2_out       = 0x0;
    InOut.user3_out       = 0x0;
    InOut.user4_out       = 0x0;

	return InOut;
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

void pdo_exchange(pdo_values_t &InOut, pdo_values_t pdo_out, pdo_values_t &pdo_in)
{

    InOut.status_word    = pdo_out.status_word;
    InOut.operation_mode_display  = pdo_out.operation_mode_display;
    InOut.actual_torque   = pdo_out.actual_torque;
    InOut.actual_position = pdo_out.actual_position;
    InOut.actual_velocity = pdo_out.actual_velocity;
    InOut.user1_out       = pdo_out.user1_out;
    InOut.user2_out       = pdo_out.user2_out;
    InOut.user3_out       = pdo_out.user3_out;
    InOut.user4_out       = pdo_out.user4_out;

    pdo_in.control_word    = InOut.control_word;
    pdo_in.operation_mode  = InOut.operation_mode;
    pdo_in.target_torque   = InOut.target_torque;
    pdo_in.target_position = InOut.target_position;
    pdo_in.target_velocity = InOut.target_velocity;
    pdo_in.user1_in        = InOut.user1_in;
    pdo_in.user2_in        = InOut.user2_in;
    pdo_in.user3_in        = InOut.user3_in;
    pdo_in.user4_in        = InOut.user4_in;

}

void pdo_decode_buffer(pdo_size_t buffer[], pdo_values_t &InOut)
{
    InOut.control_word    = (buffer[0]) & 0xffff;
    InOut.operation_mode  = buffer[1] & 0xff;
    InOut.target_torque   = ((buffer[2]<<8 & 0xff00) | (buffer[1]>>8 & 0xff)) & 0x0000ffff;
    InOut.target_position = ((buffer[4]&0x00ff)<<24 | buffer[3]<<8 | (buffer[2] & 0xff00)>>8 )&0xffffffff;
    InOut.target_velocity = (buffer[6]<<24 | buffer[5]<<8 |  (buffer[4]&0xff00) >> 8)&0xffffffff;
    InOut.user1_in        = ((buffer[8]&0xff)<<24)  | ((buffer[7]&0xffff)<<8)  | ((buffer[6]>>8)&0xff);
    InOut.user2_in        = ((buffer[10]&0xff)<<24) | ((buffer[9]&0xffff)<<8)  | ((buffer[8]>>8)&0xff);
    InOut.user3_in        = ((buffer[12]&0xff)<<24) | ((buffer[11]&0xffff)<<8) | ((buffer[10]>>8)&0xff);
    InOut.user4_in        = ((buffer[14]&0xff)<<24) | ((buffer[13]&0xffff)<<8) | ((buffer[12]>>8)&0xff);
}

void pdo_encode_buffer(pdo_size_t buffer[], pdo_values_t InOut)
{
    buffer[0]  = InOut.status_word ;
    buffer[1]  = ((InOut.operation_mode_display&0xff) | (InOut.actual_position&0xff)<<8) ;
    buffer[2]  = (InOut.actual_position>> 8)& 0xffff;
    buffer[3]  = ((InOut.actual_position>>24) & 0xff) | ((InOut.actual_velocity&0xff)<<8);
    buffer[4]  = (InOut.actual_velocity>> 8)& 0xffff;
    buffer[5]  = ((InOut.actual_velocity>>24) & 0xff) | ((InOut.actual_torque&0xff)<<8) ;
    buffer[6]  = ((InOut.user1_out<<8)&0xff00) | ((InOut.actual_torque >> 8)&0xff);
    buffer[7]  = ((InOut.user1_out>>8)&0xffff);
    buffer[8]  = ((InOut.user2_out<<8)&0xff00) | ((InOut.user1_out>>24)&0xff);
    buffer[9]  = ((InOut.user2_out>>8)&0xffff);
    buffer[10] = ((InOut.user3_out<<8)&0xff00) | ((InOut.user2_out>>24)&0xff);
    buffer[11] = ((InOut.user3_out>>8)&0xffff);
    buffer[12] = ((InOut.user4_out<<8)&0xff00) | ((InOut.user3_out>>24)&0xff);
    buffer[13] = ((InOut.user4_out>>8)&0xffff);
    buffer[14] = ((InOut.user4_out>>24)&0xff);
}


void pdo_decode(unsigned char pdo_number, uint64_t value, pdo_values_t &InOut)
{
    switch (pdo_number)
    {
        case 0:
            InOut.control_word = value & 0xffff;
            InOut.operation_mode = (value >> 16) & 0xff;
            InOut.target_torque = (value >> 24) & 0xffff;
            //pdo_read_write_data_od((RPDO_COMMUNICATION_PARAMETER + pdo_number), (value, char[]), WRITE_TO_OD);
            break;
        case 1:
            InOut.target_position = value & 0xffffffff;
            InOut.target_velocity = (value >> 32) & 0xffffffff;
            //pdo_read_write_data_od(RPDO_0_COMMUNICATION_PARAMETER + pdo_number, (value, char[]), WRITE_TO_OD);
            break;
        case 2:
            InOut.user1_in = value & 0xffffffff;
            InOut.user2_in = (value >> 32) & 0xffffffff;
            break;
        case 3:
            InOut.user3_in = value & 0xffffffff;
            InOut.user4_in = (value >> 32) & 0xffffffff;
            break;
        default:
            break;
    }
}

{uint64_t, char} pdo_encode(unsigned char pdo_number, pdo_values_t InOut)
{
    char data_length = 0;
    uint64_t value = 0;

    switch (pdo_number)
    {
        case 0:
            value = (InOut.status_word & 0xffff) | (( (uint64_t)InOut.operation_mode_display << 16) & 0xff0000) | ((uint64_t)InOut.actual_torque << 24);
            data_length = 5;
            //data_length = pdo_read_write_data_od((TPDO_COMMUNICATION_PARAMETER + pdo_number), (value, char[]), WRITE_TO_OD);
            break;
        case 1:
            value = (( (uint64_t)InOut.actual_position) & 0xffffffff) | (( (uint64_t)InOut.actual_velocity << 32) & 0xffffffff00000000);
            data_length = 8;
            //data_length = pdo_read_write_data_od(TPDO_0_COMMUNICATION_PARAMETER + pdo_number, (value, char[]), WRITE_TO_OD);
            break;
        case 2:
            value = (( (uint64_t)InOut.user1_out) & 0xffffffff) | (( (uint64_t)InOut.user2_out << 32) & 0xffffffff00000000);
            data_length = 8;
            break;
        case 3:
            value = (( (uint64_t)InOut.user3_out) & 0xffffffff) | (( (uint64_t)InOut.user4_out << 32) & 0xffffffff00000000);
            data_length = 8;
            break;
        default:
            break;
    }

    return {value, data_length};
}

int pdo_get_target_torque(pdo_values_t InOut)
{
    return InOut.target_torque;
}

int pdo_get_target_velocity(pdo_values_t InOut)
{
    return InOut.target_velocity;
}

int pdo_get_target_position(pdo_values_t InOut)
{
    return InOut.target_position;
}

int pdo_get_controlword(pdo_values_t InOut)
{
    return InOut.control_word;
}

int pdo_get_opmode(pdo_values_t InOut)
{
    return InOut.operation_mode;
}

void pdo_set_actual_torque(int actual_torque, pdo_values_t &InOut)
{
    InOut.actual_torque = actual_torque;
}

void pdo_set_actual_velocity(int actual_velocity, pdo_values_t &InOut)
{
    InOut.actual_velocity = actual_velocity;
}

void pdo_set_actual_position(int actual_position, pdo_values_t &InOut)
{
    InOut.actual_position = actual_position;
}

void pdo_set_statusword(int statusword, pdo_values_t &InOut)
{
    InOut.status_word = statusword & 0xffff;
}

void pdo_set_opmode_display(int opmode, pdo_values_t &InOut)
{
    InOut.operation_mode_display = opmode & 0xff;
}
