#include <canod.h>

#include <od_interface.h>
#include <pdo_interface.h>
#include <stdint.h>
#include <string.h>

#include "pdo_handler.h"


void canopen_service(server interface i_od[3], server interface i_pdo[3])
{
    pdo_values_t InOut;

    pdo_size_t pdo_buffer[PDO_BUFFER_SIZE];

    while (1)
    {
        select
        {
            case i_od[i].get_object_value(uint16_t index, uint8_t subindex) -> { uint32_t value }:
                    unsigned bitlength = 32;
                    unsigned val = 0;
                    canod_get_entry(index, subindex, val, bitlength);
                    value = val;
                    break;

            case i_od[i].set_object_value(uint16_t index, uint8_t subindex, uint32_t value):
                    unsigned type = 0;
                    canod_set_entry(index, subindex, value, type);
                    break;

            case i_od[i].configuration_done():
                /* just clean the notification */
                break;

            //case i_pdo[i].pdo_out(unsigned int &size, uint16_t data_out[]):
                    //break;
            //case i_pdo[i].pdo_in(unsigned int size, uint16_t data_in[]):
              //      break;

//            case i_pdo[i].pdo_io_master(unsigned int &size, uint16_t data_io[]):
//                pdo_protocol_handler(data_io, InOut);
//                break;

            case i_pdo[i].pdo_in_master(unsigned int size, pdo_size_t data_in[]):
                memcpy(pdo_buffer, data_in, PDO_BUFFER_SIZE);
                pdo_decode(pdo_buffer, InOut);
                break;

            case i_pdo[i].pdo_out_master(unsigned int size, pdo_size_t data_out[]):
                pdo_encode(pdo_buffer, InOut);
                memcpy(data_out, pdo_buffer, PDO_BUFFER_SIZE);

                break;

            case i_pdo[i].pdo_io_slave(pdo_values_t pdo_in) -> {pdo_out}:
                pdo_out = InOut;
                InOut = pdo_in;
                break;


        }
    }
}
