/**
 * @file pdo_handler.xc
 * @brief Control Protocol PDO Parser
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include "pdo_handler.h"
#include "dictionary_symbols.h"
#include <sdo.h>

#define CANOPEN_WRITE_PDO_IN_OD

enum {
    READ_FROM_OD = 0,
    WRITE_TO_OD = 1,
};

typedef struct pdo_mapping_t
{
    uint16_t pdo_mapping_index[10];
    uint8_t pdo_mapping_subindex[10];
    uint16_t od_struct_index[10];
    uint8_t pdo_mapping_datalength[10]; // in bit


} pdo_mapping_t;

pdo_mapping_t pdo_map_tx[6];
pdo_mapping_t pdo_map_rx[4];

/**
 * @brief Save PDO index in struct for fast OD access without search.
 * @param[in] pdo_mapping_address Either 0x1600 or 0x1A00 for Tx/Rx PDOs
 * @param[out] pdo_map  Struct for Rx or Tx PDO OD data.
 */
void pdo_init_mapping_struct(unsigned pdo_mapping_address, pdo_mapping_t pdo_map[], size_t pdo_map_size)
{
    unsigned error = 0, pdo_num = 0, value = 0, pdo_entries = 0, bitlength = 0;
    int od_index;

    while (!error)
    {
        error = sdo_entry_get_value(pdo_mapping_address + pdo_num, 0,
                                    sizeof(value), REQUEST_FROM_APP,
                                    (uint8_t *)&value, &bitlength);
        if (error) break;

        pdo_entries = value;

        /* avoid out of bounds exception
         * FIXME apply proper error handling */
        if (pdo_map_size < pdo_entries)
            return;

        for (int i = 0; i < pdo_entries; i++)
        {
            error = sdo_entry_get_value(pdo_mapping_address + pdo_num, i+1,
                                        sizeof(value), REQUEST_FROM_APP,
                                        (uint8_t *)&value, &bitlength);
            if (error) break;

            pdo_map[pdo_num].pdo_mapping_index[i] = (value >> 16) & 0xffff;
            pdo_map[pdo_num].pdo_mapping_subindex[i] = (value >> 8) & 0xff;
            pdo_map[pdo_num].pdo_mapping_datalength[i] = (value & 0xff);
            od_index = sdo_entry_get_position(pdo_map[pdo_num].pdo_mapping_index[i], pdo_map[pdo_num].pdo_mapping_subindex[i]);
            if (od_index < 0) {
                error++;
                break;
            }
            pdo_map[pdo_num].od_struct_index[i] = (unsigned)od_index;
        }

        pdo_num++;
    }
}

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

    inout.torque_value   = 0x0;
    inout.velocity_value = 0x0;
    inout.position_value = 0x0;

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
    inout.timestamp         = 0x0;

    pdo_init_mapping_struct(TPDO_MAPPING_PARAMETER, pdo_map_tx, 6);
    pdo_init_mapping_struct(RPDO_MAPPING_PARAMETER, pdo_map_rx, 4);

	return inout;
}

void pdo_exchange(pdo_values_t &inout, pdo_values_t pdo_out, pdo_values_t &pdo_in)
{

    inout.statusword        = pdo_out.statusword;
    inout.op_mode_display   = pdo_out.op_mode_display;
    inout.torque_value      = pdo_out.torque_value;
    inout.position_value    = pdo_out.position_value;
    inout.velocity_value    = pdo_out.velocity_value;
    inout.secondary_position_value       = pdo_out.secondary_position_value;
    inout.secondary_velocity_value       = pdo_out.secondary_velocity_value;
    inout.analog_input1     = pdo_out.analog_input1;
    inout.analog_input2     = pdo_out.analog_input2;
    inout.analog_input3     = pdo_out.analog_input3;
    inout.analog_input4     = pdo_out.analog_input4;
    inout.tuning_status     = pdo_out.tuning_status;
    inout.digital_input1    = pdo_out.digital_input1;
    inout.digital_input2    = pdo_out.digital_input2;
    inout.digital_input3    = pdo_out.digital_input3;
    inout.digital_input4    = pdo_out.digital_input4;
    inout.user_miso         = pdo_out.user_miso;
    inout.timestamp         = pdo_out.timestamp;

    pdo_in.controlword      = inout.controlword;
    pdo_in.op_mode          = inout.op_mode;
    pdo_in.target_torque    = inout.target_torque;
    pdo_in.target_position  = inout.target_position;
    pdo_in.target_velocity  = inout.target_velocity;
    pdo_in.offset_torque    = inout.offset_torque;
    pdo_in.tuning_command   = inout.tuning_command;
    pdo_in.digital_output1  = inout.digital_output1;
    pdo_in.digital_output2  = inout.digital_output2;
    pdo_in.digital_output3  = inout.digital_output3;
    pdo_in.digital_output4  = inout.digital_output4;
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
            buffer[41] = inout.timestamp;
            buffer[42] = inout.timestamp >> 8;
            buffer[43] = inout.timestamp >> 16;
            buffer[44] = inout.timestamp >> 24;

            data_length = 45;
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
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[0], inout.controlword, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[1], inout.op_mode, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[2], inout.target_torque, 1);
#endif
            break;
        case 1:
            inout.target_position = buffer[3] << 24 | buffer[2] << 16 | buffer[1] << 8 | buffer[0];
            inout.target_velocity = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[0], inout.target_position, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[1], inout.target_velocity, 1);
#endif
            break;
        case 2:
            inout.offset_torque = buffer[3] << 24 | buffer[2] << 16 | buffer[1] << 8 | buffer[0];
            inout.tuning_command = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[0], inout.offset_torque, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[1], inout.tuning_command, 1);
#endif
            break;
        case 3:
            inout.digital_output1 = buffer[0];
            inout.digital_output2 = buffer[1];
            inout.digital_output3 = buffer[2];
            inout.digital_output4 = buffer[3];
            inout.user_mosi = buffer[7] << 24 | buffer[6] << 16 | buffer[5] << 8 | buffer[4];
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[0], inout.digital_output1, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[1], inout.digital_output2, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[2], inout.digital_output3, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[3], inout.digital_output4, 1);
            canod_set_entry_fast(pdo_map_rx[pdo_number].od_struct_index[4], inout.user_mosi, 1);
#endif
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
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.statusword, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.op_mode_display, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[2], inout.torque_value, 1);
#endif
            buffer[0] = inout.statusword;
            buffer[1] = inout.statusword >> 8;
            buffer[2] = inout.op_mode_display;
            buffer[3] = inout.torque_value & 0xff;
            buffer[4] = (inout.torque_value >> 8) & 0xff;
            data_length = 5;
            break;
        case 1:
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.position_value, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.velocity_value, 1);
#endif
            buffer[0] = inout.position_value & 0xff;
            buffer[1] = (inout.position_value >> 8) & 0xff;
            buffer[2] = (inout.position_value >> 16) & 0xff;
            buffer[3] = (inout.position_value >> 24) & 0xff;
            buffer[4] = (inout.velocity_value) & 0xff;
            buffer[5] = (inout.velocity_value >> 8) & 0xff;
            buffer[6] = (inout.velocity_value >> 16) & 0xff;
            buffer[7] = (inout.velocity_value >> 24) & 0xff;
            data_length = 8;
            break;
        case 2:
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.secondary_position_value, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.secondary_velocity_value, 1);
#endif
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
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.analog_input1, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.analog_input2, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[2], inout.analog_input3, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[3], inout.analog_input4, 1);
#endif
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
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.tuning_status, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.user_miso, 1);
#endif
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
#ifdef CANOPEN_WRITE_PDO_IN_OD
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[0], inout.digital_input1, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[1], inout.digital_input2, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[2], inout.digital_input3, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[3], inout.digital_input4, 1);
            canod_set_entry_fast(pdo_map_tx[pdo_number].od_struct_index[4], inout.timestamp, 1);
#endif
            buffer[0] = inout.digital_input1;
            buffer[1] = inout.digital_input2;
            buffer[2] = inout.digital_input3;
            buffer[3] = inout.digital_input4;
            buffer[4] = inout.timestamp;
            buffer[5] = inout.timestamp >> 8;
            buffer[6] = inout.timestamp >> 16;
            buffer[7] = inout.timestamp >> 24;
            data_length = 8;
            break;
        default:
            break;
    }

    return data_length;
}

#endif

int16_t pdo_get_target_torque(pdo_values_t inout)
{
    return inout.target_torque;
}

int32_t pdo_get_target_velocity(pdo_values_t inout)
{
    return inout.target_velocity;
}

int32_t pdo_get_target_position(pdo_values_t inout)
{
    return inout.target_position;
}

int32_t pdo_get_offset_torque(pdo_values_t InOut)
{
    return InOut.offset_torque;
}

uint16_t pdo_get_controlword(pdo_values_t inout)
{
    return inout.controlword;
}

int8_t pdo_get_op_mode(pdo_values_t inout)
{
    return inout.op_mode;
}

void pdo_set_torque_value(int16_t torque_value, pdo_values_t &inout)
{
    inout.torque_value = torque_value;
}

void pdo_set_velocity_value(int32_t velocity_value, pdo_values_t &inout)
{
    inout.velocity_value = velocity_value;
}

void pdo_set_position_value(int32_t position_value, pdo_values_t &inout)
{
    inout.position_value = position_value;
}

void pdo_set_statusword(uint16_t statusword, pdo_values_t &inout)
{
    inout.statusword = statusword & 0xffff;
}

void pdo_set_op_mode_display(int8_t opmode, pdo_values_t &inout)
{
    inout.op_mode_display = opmode & 0xff;
}

uint32_t pdo_get_tuning_command(pdo_values_t inout)
{
    return inout.tuning_command;
}

uint8_t pdo_get_digital_output1(pdo_values_t inout)
{
    return inout.digital_output1;
}

uint8_t pdo_get_digital_output2(pdo_values_t inout)
{
    return inout.digital_output2;
}

uint8_t pdo_get_digital_output3(pdo_values_t inout)
{
    return inout.digital_output3;
}

uint8_t pdo_get_digital_output4(pdo_values_t inout)
{
    return inout.digital_output4;
}

uint32_t pdo_get_user_mosi(pdo_values_t inout)
{
    return inout.user_mosi;
}

void pdo_set_secondary_position_value(int32_t value, pdo_values_t &inout)
{
    inout.secondary_position_value = value;
}

void pdo_set_secondary_velocity_value(int32_t value, pdo_values_t &inout)
{
    inout.secondary_velocity_value = value;
}

void pdo_set_analog_input1(uint16_t value, pdo_values_t &inout)
{
    inout.analog_input1 = value;
}

void pdo_set_analog_input2(uint16_t value, pdo_values_t &inout)
{
    inout.analog_input2 = value;
}

void pdo_set_analog_input3(uint16_t value, pdo_values_t &inout)
{
    inout.analog_input3 = value;
}

void pdo_set_analog_input4(uint16_t value, pdo_values_t &inout)
{
    inout.analog_input4 = value;
}

void pdo_set_tuning_status(uint32_t value, pdo_values_t &inout)
{
    inout.tuning_status = value;
}

void pdo_set_digital_input1(uint8_t value, pdo_values_t &inout)
{
    inout.digital_input1 = value;
}

void pdo_set_digital_input2(uint8_t value, pdo_values_t &inout)
{
    inout.digital_input2 = value;
}

void pdo_set_digital_input3(uint8_t value, pdo_values_t &inout)
{
    inout.digital_input3 = value;
}

void pdo_set_digital_input4(uint8_t value, pdo_values_t &inout)
{
    inout.digital_input4 = value;
}

void pdo_set_user_miso(uint32_t value, pdo_values_t &inout)
{
    inout.user_miso = value;
}

void pdo_set_timestamp(uint32_t value, pdo_values_t &inout)
{
    inout.timestamp = value;
}
