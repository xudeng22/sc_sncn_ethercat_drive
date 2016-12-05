/*
 * od_handler.xc
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */

void od_handler()
{

    while (1) {
                select {
                case i_coe.get_object_value(uint16_t index, uint8_t subindex) -> { uint32_t value }:
                    unsigned bitlength = 32;
                    unsigned val = 0;
                    canod_get_entry(index, subindex, val, bitlength);
                    value = val;
                    break;

                case i_coe.set_object_value(uint16_t index, uint8_t subindex, uint32_t value):
                    unsigned type = 0;
                    canod_set_entry(index, subindex, value, type);
                    break;
                }
    }
}
