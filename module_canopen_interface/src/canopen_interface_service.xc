/**
 * @file canopen_service.xc
 * @brief CANopen service between communication channels and CANopen drive.
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <stdint.h>
#include <string.h>

#include "sdo.h"
#include "co_interface.h"
#include "dictionary_symbols.h"
#include "canopen_interface_service.h"
#include "pdo_handler.h"
#include "print.h"

#define MAX_PDO_SIZE 64

/* Number of bytes to store in the return value array.
 * This is necessary because with interface methods the "variable length array" gimmick of XC
 * (see https://www.xmos.com/published/xmos-programming-guide?version=B&page=25)
 * does not work and leads to an internal error of xcc.  */
#define MAX_VALUE_BUFFER    100

/* there are 5 list lengths for all, rx-, tx-mappable, startup, and backup objects */
#define ALL_LIST_LENGTH_SIZE    5

struct _sdo_command_object {
    enum eSdoCommand command;
    enum eSdoState   state;
};

[[distributable]]
void canopen_interface_service(
        server interface i_pdo_handler_exchange i_pdo_handler,
        server interface i_co_communication i_co[n],
        unsigned n)
{
    pdo_values_t InOut = pdo_init_data();
    pdo_size_t pdo_buffer[MAX_PDO_SIZE];
    char comm_state = 0;

    struct _sdo_command_object sdo_command_object = { OD_COMMAND_NONE, OD_COMMAND_STATE_IDLE };

    int configuration_done = 0;
    int drive_operational = 0;

    printstrln("SOMANET CANOPEN SERVICE STARTING...");

    while (1)
    {
        select
        {
            /* PDO */

            case i_co[int j].pdo_in(uint8_t pdo_number, unsigned int size_in, pdo_size_t data_in[]):
                unsigned pdo_size = size_in;
                memcpy(pdo_buffer, data_in, pdo_size * sizeof(pdo_size_t));
                pdo_decode(pdo_number, pdo_buffer, InOut);
                comm_state = 1;
                break;

            case i_co[int j].pdo_out(uint8_t pdo_number, pdo_size_t data_out[]) -> { unsigned int size_out }:
                unsigned pdo_size = pdo_encode(pdo_number, pdo_buffer, InOut);
                memcpy(data_out, pdo_buffer, pdo_size * sizeof(pdo_size_t));
                size_out = pdo_size;
                break;

//            case i_co[int j].pdo_exchange_app(pdo_values_t pdo_out) -> { pdo_values_t pdo_in, unsigned int status_out }:
            case i_pdo_handler.pdo_exchange_app(pdo_values_t pdo_out) -> { pdo_values_t pdo_in, unsigned int status_out }:
                pdo_exchange(InOut, pdo_out, pdo_in);
                status_out = comm_state;
                comm_state = 0;
                break;

//            case i_co[int j].pdo_init(void) -> {pdo_values_t pdo_out}:
            case i_pdo_handler.pdo_init(void) -> {pdo_values_t pdo_out}:
                pdo_out = pdo_init_data();
                break;


            /* SDO */

            /* FIXME this function was necessary on the ethercat service
             * side to check if the ethercat service is allowed to write or
             * read this value, with the use of the master access functions
             * this interface method becomes obsolete. */
            case i_co[int j].od_get_access(uint16_t index_, uint8_t subindex) -> { enum eAccessRights access, uint8_t error }:
                    struct _sdoinfo_entry_description entry;
                    error = sdoinfo_get_entry_description(index_, subindex, &entry);
                    if (!error) {
                        access = (enum eAccessRights)(entry.objectAccess & 0x3f);
                    }
                    break;

            case i_co[int j].od_get_object_value(uint16_t index_, uint8_t subindex) -> { uint32_t value_out, uint32_t bitlength_out, uint8_t error_out }:
                    unsigned value = 0;
                    size_t bitsize = 0;
                    int request_from = REQUEST_FROM_APP;

                    sdo_entry_get_value(index_, subindex, sizeof(value), request_from, (uint8_t*)&value, &bitsize);
                    bitlength_out = bitsize;

                    value_out = value;

                    /* After command is finished processing and the result is read by the master reset
                     * the command to allow the next command to be scheduled for execution.
                     * The command status is always written from the application requester
                     * FIXME still necessary for internal command handling! */
                    if (index_ == DICT_COMMAND_OBJECT && value > OD_COMMAND_STATE_PROCESSING) {
                        sdo_entry_set_uint16(index_, subindex, OD_COMMAND_STATE_IDLE, REQUEST_FROM_APP);
                        sdo_command_object.command = OD_COMMAND_NONE;
                        sdo_command_object.state = OD_COMMAND_STATE_IDLE;
                    }
                    break;

            case i_co[int j].od_set_object_value(uint16_t index_, uint8_t subindex, uint32_t value) -> { uint8_t error_out }:
                    if (index_ == DICT_COMMAND_OBJECT && sdo_command_object.state == OD_COMMAND_STATE_IDLE) {
                        sdo_command_object.command = (uint16_t)(value & 0xffff);
                        value = OD_COMMAND_STATE_IDLE;
                    }

                    uint8_t error = 0;
                    int request_from  = REQUEST_FROM_APP;
                    size_t bytecount = sdo_entry_get_bytecount(index_, subindex);
                    if (bytecount == 0) {
                        error = (uint8_t)sdo_error;
                    } else {
                        if (bytecount > sizeof(value)) {
                            bytecount = sizeof(value);
                        }
                        uint8_t valtmp[8];
                        memcpy(&valtmp, &value, bytecount);
                        error = sdo_entry_set_value(index_, subindex, (uint8_t *)&valtmp, bytecount, request_from);
                    }
                    error_out = error;
                    break;

            case i_co[int j].od_master_get_object_value(uint16_t index_, uint8_t subindex, size_t capacity, uint8_t value_out[]) -> { uint32_t bitlength_out, uint8_t error_out }:
                    unsigned value = 0;
                    size_t bitsize = 0;
                    int request_from = REQUEST_FROM_MASTER;
                    uint8_t tmp[MAX_VALUE_BUFFER] = { 0 };

                    int err = sdo_entry_get_value(index_, subindex, MAX_VALUE_BUFFER, request_from, (uint8_t*)&tmp, &bitsize);
                    if (err != 0) {
                        error_out = sdo_error;
                        bitlength_out = 0;
                    } else if (BYTES_FROM_BITS(bitsize) > capacity) {
                        error_out = SDO_ERROR_INSUFFICIENT_BUFFER;
                        bitlength_out = 0;
                    } else {
                        error_out = 0;
                        bitlength_out = bitsize;
                        memcpy(value_out, &tmp, BYTES_FROM_BITS(bitsize));
                    }

                    /* After command is finished processing and the result is read by the master reset
                     * the command to allow the next command to be scheduled for execution.
                     * The command status is always written from the application requester */
                    if (index_ == DICT_COMMAND_OBJECT) {
                        memcpy(&value, &tmp, BYTES_FROM_BITS(bitsize));
                        if (value > OD_COMMAND_STATE_PROCESSING) {
                            sdo_entry_set_uint16(index_, subindex, OD_COMMAND_STATE_IDLE, REQUEST_FROM_APP);
                            sdo_command_object.command = OD_COMMAND_NONE;
                            sdo_command_object.state = OD_COMMAND_STATE_IDLE;
                        }
                    }
                    break;

            case i_co[int j].od_master_set_object_value(uint16_t index_, uint8_t subindex, uint8_t value[], size_t capacity) -> { uint8_t error_out }:
                    int request_from  = REQUEST_FROM_MASTER;
                    int error = 0;

                    if (index_ == DICT_COMMAND_OBJECT && sdo_command_object.state == OD_COMMAND_STATE_IDLE) {
                        uint16_t tmpvalue = 0;
                        memcpy(&tmpvalue, value, sizeof(uint16_t));
                        sdo_command_object.command = (uint16_t)(tmpvalue & 0xffff);
                        tmpvalue = OD_COMMAND_STATE_IDLE;
                        // The slave controls the value of the command object.
                        error = sdo_entry_set_value(index_, subindex, (uint8_t *)&tmpvalue, sizeof(uint16_t), REQUEST_FROM_APP);
                    } else {
                        size_t bytecount = sdo_entry_get_bytecount(index_, subindex);
                        uint8_t tmpvalue[MAX_VALUE_BUFFER] = { 0 };
                        memcpy(&tmpvalue, value, capacity);
                        error = sdo_entry_set_value(index_, subindex, (uint8_t *)&tmpvalue, bytecount, request_from);
                    }

                    error_out = error;
                    break;

            case i_co[int j].od_slave_get_object_value(uint16_t index_, uint8_t subindex, size_t capacity, uint8_t value[]) -> { uint32_t bitlength_out, uint8_t error_out}:
                    size_t bitsize = 0;
                    int request_from = REQUEST_FROM_APP;
                    uint8_t tmp[MAX_VALUE_BUFFER] = { 0 };

                    int err = sdo_entry_get_value(index_, subindex, MAX_VALUE_BUFFER, request_from, (uint8_t*)&tmp, &bitsize);
                    if (err != 0) {
                        error_out = sdo_error;
                        bitlength_out = 0;
                    } else if (BYTES_FROM_BITS(bitsize) > capacity) {
                        error_out = SDO_ERROR_INSUFFICIENT_BUFFER;
                        bitlength_out = 0;
                    } else {
                        error_out = 0;
                        bitlength_out = bitsize;
                        memcpy(value, &tmp, BYTES_FROM_BITS(bitsize));
                    }

                    break;

            case i_co[int j].od_slave_set_object_value(uint16_t index_, uint8_t subindex, uint8_t value[], size_t capacity) -> { uint8_t error_out }:
                    int request_from  = REQUEST_FROM_APP;
                    int error = 0;

                    size_t bytecount = sdo_entry_get_bytecount(index_, subindex);
                    if (capacity > bytecount) {
                        error = SDO_ERROR_INSUFFICIENT_BUFFER;
                    } else {
                        uint8_t tmpvalue[MAX_VALUE_BUFFER] = { 0 };
                        memcpy(&tmpvalue, value, capacity);
                        error = sdo_entry_set_value(index_, subindex, (uint8_t *)&tmpvalue, bytecount, request_from);
                    }

                    error_out = error;
                    break;

            case i_co[int j].od_get_object_value_buffer(uint16_t index_, uint8_t subindex, uint8_t data_buffer[]) -> { uint32_t bitlength_out, uint8_t error_out }:
                    unsigned bitlength = 0;
                    unsigned error = 0;
                    bitlength = sdo_entry_get_bitsize(index_, subindex);
                    if (bitlength == 0)
                    {
                        error_out = sdo_error;
                        bitlength_out = 0;
                    }
                    else
                    {
                        uint8_t value[8]; /* 8 because CAN has max 8 bytes value */
                        sdo_entry_get_value(index_, subindex, (bitlength + 7) / 8, REQUEST_FROM_APP, value, &bitlength);
                        memcpy(data_buffer, value, (bitlength + 7) / 8);
                        bitlength_out = bitlength;
                    }
                    break;

            case i_co[int j].od_set_object_value_buffer(uint16_t index_, uint8_t subindex, uint8_t data_buffer[]) -> { uint8_t error_out }:
                    unsigned bytecount, error = 0;

                    bytecount = sdo_entry_get_bytecount(index_, subindex);
                    if (bytecount == 0)
                    {
                        error_out = sdo_error;
                    }
                    else
                    {
                        uint8_t value[8]; /* 8 because CAN has max 8 bytes value */
                        memcpy(value, data_buffer, bytecount);
                        int err = sdo_entry_set_value(index_, subindex, value, bytecount, REQUEST_FROM_APP);
                        if (err) {
                            error_out = sdo_error;
                        }
                    }
                    break;


            case i_co[int j].od_get_entry_description(uint16_t index_, uint8_t subindex) -> { struct _sdoinfo_entry_description desc_out, uint8_t error_out }:
                    struct _sdoinfo_entry_description desc;
                    error_out =  sdoinfo_get_entry_description(index_, subindex, &desc);
                    if (!error_out) {
                        memcpy(&desc_out, &desc, sizeof(struct _sdoinfo_entry_description));
                    }
                    break;

            case i_co[int j].od_get_entry_description_value(uint16_t index, uint8_t subindex, uint8_t valuetype, size_t capacity, uint8_t value[]) -> { size_t length_out }:
                    uint8_t value_tmp[MAX_VALUE_BUFFER];
                    size_t length = sdoinfo_get_entry_description_value(index, subindex, valuetype, capacity, value_tmp);
                    if (length == 0) {
                        length_out = 0;
                    } else {
                        length_out = length;
                        memcpy(value, value_tmp, length);
                    }
                    break;

            case i_co[int j].od_get_object_description(struct _sdoinfo_entry_description &obj_out, uint16_t index_, uint8_t subindex) -> { int error }:
                    struct _sdoinfo_entry_description obj;
                    /* FIXME misnomer, object description and entry description are separate now. */
                    error = sdoinfo_get_object_description(index_, &obj);
                    if (!error) {
                        memcpy(&obj_out, &obj, sizeof(struct _sdoinfo_entry_description));
                    }
                    break;

            /* Functions to handle changed object entry values */

            case i_co[int j].od_changed_values_count(void) -> { size_t changed_values }:
                    changed_values = sdo_entry_changed_count();
                    break;

            case i_co[int j].od_entry_has_changed(uint16_t index_, uint8_t subindex) -> { int changed }:
                    changed = sdo_entry_has_changed(index_, subindex);
                    break;

            case i_co[int j].od_get_next_changed_element(void) -> {uint16_t index_, uint8_t subindex}:
                    uint16_t idx;
                    uint8_t subidx;
                    sdo_entry_get_next_unread(&idx, &subidx);
                    index_ = idx;
                    subindex = subidx;
                    break;


            case i_co[int j].od_get_all_list_length(uint16_t list_out[]):
                    uint16_t list[ALL_LIST_LENGTH_SIZE];
                    sdoinfo_get_list(LT_LIST_LENGTH, ALL_LIST_LENGTH_SIZE, list);
                    memcpy(list_out, list, ALL_LIST_LENGTH_SIZE * sizeof(uint16_t));
                    break;

            case i_co[int j].od_get_list(uint16_t list_out[], unsigned size, unsigned listtype) -> {int size_out}:
                    uint16_t list[100];
                    size_out = sdoinfo_get_list(listtype, 100, list);
                    memcpy(list_out, list, size_out * sizeof(uint16_t));
                    break;

            case i_co[int j].od_get_data_length(uint16_t index_, uint8_t subindex) -> {uint32_t len, uint8_t error}:
                    struct _sdoinfo_entry_description entry;
                    error = sdoinfo_get_entry_description(index_, subindex, &entry);
                    if (!error) {
                        len = (uint32_t)(BYTES_FROM_BITS(entry.bitLength));
                    }
                    break;

            case i_co[int j].inactive_communication(void):
                    comm_state = 0;
                    break;


            /* Simple notification interface */

            case i_co[int j].operational_state_change(int opmode):
                    drive_operational = opmode;
                    if (opmode) {
                        configuration_done = 1;
                    }
                    break;

            case i_co[int j].in_operational_state(void) -> { int in_op_state }:
                    in_op_state = drive_operational;
                    break;

            case i_co[int j].configuration_get(void) -> { int value }:
                    value = configuration_done;
                    break;

            case i_co[int j].configuration_done(void):
                    configuration_done = 0;
                    break;

            /* command handling interface methods */

            case i_co[int j].command_ready(void) -> { enum eSdoCommand command }:
                    command = sdo_command_object.command;
                    if (command != OD_COMMAND_NONE) {
                        sdo_command_object.state = OD_COMMAND_STATE_PROCESSING;
                    }
                    sdo_entry_set_uint16(DICT_COMMAND_OBJECT, 0, sdo_command_object.state, REQUEST_FROM_APP);
                    break;

            case i_co[int j].command_set_result(int result):
                    sdo_command_object.command = OD_COMMAND_NONE;
                    sdo_command_object.state = result ? OD_COMMAND_STATE_ERROR : OD_COMMAND_STATE_SUCCESS;
                    sdo_entry_set_uint16(DICT_COMMAND_OBJECT, 0, sdo_command_object.state, REQUEST_FROM_APP);
                    break;
        }
    }
}
