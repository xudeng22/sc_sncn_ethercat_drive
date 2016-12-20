
#include <stdint.h>
#include <string.h>

#include "canod.h"
#include "od_interface.h"
#include "canod_constants.h"
#include "canopen_service.h"

void canopen_service(server interface ODCommunicationInterface i_od[3])
{
    int configuration_done = 0;

    while (1)
    {
        select
        {
            case i_od[int j].get_object_value(uint16_t index_, uint8_t subindex) -> { uint32_t value_out, uint32_t bitlength_out, uint8_t error_out }:
                    unsigned bitlength = 0;
                    unsigned value = 0;
                    error_out = canod_get_entry(index_, subindex, value, bitlength);
                    bitlength_out = bitlength;
                    value_out = value;
                    break;

            case i_od[int j].set_object_value(uint16_t index_, uint8_t subindex, uint32_t value) -> {uint8_t error_out }:
                    unsigned type = 0;
                    error_out = canod_set_entry(index_, subindex, value, type);
                    break;

            case i_od[int j].get_entry_description(uint16_t index_, uint8_t subindex, uint32_t valueinfo) -> {struct _sdoinfo_entry_description desc_out, uint8_t error_out }:
                    struct _sdoinfo_entry_description desc;
                    error_out = canod_get_entry_description(index_, subindex, valueinfo, desc);
                    desc_out = desc;
                    break;

            case i_od[int j].get_all_list_length(uint32_t list_out[]):
                    unsigned list[5];
                    canod_get_all_list_length(list);
                    memcpy(list_out, list, 5);
                    break;

            case i_od[int j].get_list(unsigned list_out[], unsigned size, unsigned listtype) -> {int size_out}:
                    unsigned list[100];
                    size_out = canod_get_list(list, 100, listtype);
                    memcpy(list_out, list, size);
                    break;

            case i_od[int j].get_object_description(struct _sdoinfo_entry_description &obj_out, unsigned index_) -> { int error }:
                    struct _sdoinfo_entry_description obj;
                    error = canod_get_object_description(obj, index_);
                    obj_out = obj;
                    break;

            case i_od[int j].configuration_ready(void):
                    configuration_done = 1;
                    break;

            case i_od[int j].configuration_get(void) -> { int value }:
                    value = configuration_done;
                    break;

            case i_od[int j].configuration_done(void):
                    configuration_done = 0;
                    break;


        }
    }
}
