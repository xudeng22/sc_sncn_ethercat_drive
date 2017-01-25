/**
 * @file canopen_service.xc
 * @brief CANopen service between communication channels and CANopen drive.
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <stdint.h>
#include <string.h>

#include "canod.h"
#include "co_interface.h"
#include "canod_constants.h"
#include "canopen_service.h"

void canopen_service(server interface i_co_communication i_co[3])
{
    pdo_values_t InOut;
    pdo_size_t pdo_buffer[PDO_BUFFER_SIZE];
    unsigned pdo_size = 0;

    int configuration_done = 0;

    while (1)
    {
        select
        {
            case i_co[int j].get_object_value(uint16_t index_, uint8_t subindex) -> { uint32_t value_out, uint32_t bitlength_out, uint8_t error_out }:
                    unsigned bitlength = 0;
                    unsigned value = 0;
                    error_out = canod_get_entry(index_, subindex, value, bitlength);
                    bitlength_out = bitlength;
                    value_out = value;
                    break;

            case i_co[int j].set_object_value(uint16_t index_, uint8_t subindex, uint32_t value) -> {uint8_t error_out }:
                    unsigned type = 0;
                    error_out = canod_set_entry(index_, subindex, value, type);
                    break;

            case i_co[int j].get_entry_description(uint16_t index_, uint8_t subindex, uint32_t valueinfo) -> {struct _sdoinfo_entry_description desc_out, uint8_t error_out }:
                    struct _sdoinfo_entry_description desc;
                    error_out = canod_get_entry_description(index_, subindex, valueinfo, desc);
                    desc_out = desc;
                    break;

            case i_co[int j].get_all_list_length(uint32_t list_out[]):
                    unsigned list[5];
                    canod_get_all_list_length(list);
                    memcpy(list_out, list, 5);
                    break;

            case i_co[int j].get_list(unsigned list_out[], unsigned size, unsigned listtype) -> {int size_out}:
                    unsigned list[100];
                    size_out = canod_get_list(list, 100, listtype);
                    memcpy(list_out, list, size);
                    break;

            case i_co[int j].get_object_description(struct _sdoinfo_entry_description &obj_out, unsigned index_) -> { int error }:
                    struct _sdoinfo_entry_description obj;
                    error = canod_get_object_description(obj, index_);
                    obj_out = obj;
                    break;

            /* Simple notification interface */

            case i_co[int j].configuration_ready(void):
                    configuration_done = 1;
                    break;

            case i_co[int j].configuration_get(void) -> { int value }:
                    value = configuration_done;
                    break;

            case i_co[int j].configuration_done(void):
                    configuration_done = 0;
                    break;

            /* PDO */

            case i_co[int j].pdo_in_com(unsigned int size_in, pdo_size_t data_in[]):
                pdo_size = size_in;
                memcpy(pdo_buffer, data_in, pdo_size);
                //for (int i = 0; i < size; i++) printint(data_in[i]);
                pdo_decode(pdo_buffer, InOut);
                //printcharln(' ');
                break;

            case i_co[int j].pdo_out_com(pdo_size_t data_out[]) -> { unsigned int size_out }:
                pdo_encode(pdo_buffer, InOut);
                memcpy(data_out, pdo_buffer, pdo_size);
                size_out = pdo_size;
                break;

            case i_co[int j].pdo_exchange_app(pdo_values_t pdo_out) -> { pdo_values_t pdo_in }:
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
               break;
        }
    }
}
