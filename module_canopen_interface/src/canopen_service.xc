
#include <stdint.h>
#include <string.h>

#include "canod.h"
#include "pdo_interface.h"
#include "od_interface.h"
#include "pdo_handler.h"
#include "canod_constants.h"
#include "canopen_service.h"

void canopen_service(server interface ODCommunicationInterface i_od[3], server interface PDOCommunicationInterface ?i_pdo[3])
{
    pdo_values_t InOut;

    pdo_size_t pdo_buffer[PDO_BUFFER_SIZE];

    int configuration_done = 0;

    printstr("SOMANET CANOpen Service started\n");

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

            //case i_pdo[int j].pdo_out(unsigned int &size, uint16_t data_out[]):
                    //break;
            //case i_pdo[int j].pdo_in(unsigned int size, uint16_t data_in[]):
              //      break;


            case i_pdo[int j].pdo_in_master(unsigned int size, pdo_size_t data_in[]):
                //memcpy(pdo_buffer, data_in, PDO_BUFFER_SIZE);
                //for (int i = 0; i < size; i++) printint(data_in[i]);
                //pdo_decode(pdo_buffer, InOut);
                //printcharln(' ');
                InOut.control_word    = (data_in[0]) & 0xffff;
                InOut.operation_mode  = data_in[1] & 0xff;
                InOut.target_torque   = ((data_in[2]<<8 & 0xff00) | (data_in[1]>>8 & 0xff)) & 0x0000ffff;
                InOut.target_position = ((data_in[4]&0x00ff)<<24 | data_in[3]<<8 | (data_in[2] & 0xff00)>>8 )&0xffffffff;
                InOut.target_velocity = (data_in[6]<<24 | data_in[5]<<8 |  (data_in[4]&0xff00) >> 8)&0xffffffff;
                InOut.user1_in        = ((data_in[8]&0xff)<<24)  | ((data_in[7]&0xffff)<<8)  | ((data_in[6]>>8)&0xff);
                InOut.user2_in        = ((data_in[10]&0xff)<<24) | ((data_in[9]&0xffff)<<8)  | ((data_in[8]>>8)&0xff);
                InOut.user3_in        = ((data_in[12]&0xff)<<24) | ((data_in[11]&0xffff)<<8) | ((data_in[10]>>8)&0xff);
                InOut.user4_in        = ((data_in[14]&0xff)<<24) | ((data_in[13]&0xffff)<<8) | ((data_in[12]>>8)&0xff);
                break;

            case i_pdo[int j].pdo_out_master(unsigned int size, pdo_size_t data_out[]):
                //pdo_encode(pdo_buffer, InOut);
                //memcpy(data_out, pdo_buffer, PDO_BUFFER_SIZE);
                data_out[0]  = InOut.status_word ;
                data_out[1]  = ((InOut.operation_mode_display&0xff) | (InOut.actual_position&0xff)<<8) ;
                data_out[2]  = (InOut.actual_position>> 8)& 0xffff;
                data_out[3]  = ((InOut.actual_position>>24) & 0xff) | ((InOut.actual_velocity&0xff)<<8);
                data_out[4]  = (InOut.actual_velocity>> 8)& 0xffff;
                data_out[5]  = ((InOut.actual_velocity>>24) & 0xff) | ((InOut.actual_torque&0xff)<<8) ;
                data_out[6]  = ((InOut.user1_out<<8)&0xff00) | ((InOut.actual_torque >> 8)&0xff);
                data_out[7]  = ((InOut.user1_out>>8)&0xffff);
                data_out[8]  = ((InOut.user2_out<<8)&0xff00) | ((InOut.user1_out>>24)&0xff);
                data_out[9]  = ((InOut.user2_out>>8)&0xffff);
                data_out[10] = ((InOut.user3_out<<8)&0xff00) | ((InOut.user2_out>>24)&0xff);
                data_out[11] = ((InOut.user3_out>>8)&0xffff);
                data_out[12] = ((InOut.user4_out<<8)&0xff00) | ((InOut.user3_out>>24)&0xff);
                data_out[13] = ((InOut.user4_out>>8)&0xffff);
                data_out[14] = ((InOut.user4_out>>24)&0xff);
                break;

            case i_pdo[int j].pdo_io(pdo_values_t pdo_out) -> { pdo_values_t pdo_in}:
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
