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

/* there are 5 list lengths for all, rx-, tx-mappable, startup, and backup objects */
#define ALL_LIST_LENGTH_SIZE    5

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

            case i_co[int j].od_get_access(uint16_t index_, uint8_t subindex) -> { enum eAccessRights access, uint8_t error }:
                    struct _sdoinfo_entry_description entry;
                    error = sdoinfo_get_entry_description(index_, subindex, 0, &entry);
                    if (!error) {
                        access = (enum eAccessRights)(entry.objectAccess & 0xff);
                    }
                    break;

            case i_co[int j].od_get_object_value(uint16_t index_, uint8_t subindex) -> { uint32_t value_out, uint32_t bitlength_out, uint8_t error_out }:
                    unsigned value = 0;
                    /* FIXME Need to distinguish between request from communication side (aka master) and local
                     * requests, one possible fix is the use of different interfaces for com side and app side (as
                     * planed). */
                    sdo_entry_get_value(index_, subindex, (uint8_t*)&value, sizeof(value), REQUEST_FROM_APP);
                    bitlength_out = sdo_entry_get_bitsize(index_, subindex);

                    value_out = value;

                    /* After command is finished processing and the result is read by the master reset
                     * the command to allow the next command to be scheduled for execution. */
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

                    size_t bytecount = sdo_entry_get_bytecount(index_, subindex);
                    error_out = sdo_entry_set_value(index_, subindex, (uint8_t *)&value, bytecount, REQUEST_FROM_APP);
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
                        sdo_entry_get_value(index_, subindex, value, (bitlength + 7) / 8, REQUEST_FROM_APP);
                        memcpy(data_buffer, value, (bitlength + 7) / 8);
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


            case i_co[int j].od_get_entry_description(uint16_t index_, uint8_t subindex, uint32_t valueinfo) -> { struct _sdoinfo_entry_description desc_out, uint8_t error_out }:
                    struct _sdoinfo_entry_description desc;
                    error_out = sdoinfo_get_entry_description(index_, subindex, valueinfo, &desc);
                    memcpy(&desc_out, &desc, sizeof(struct _sdoinfo_entry_description));
                    break;

            case i_co[int j].od_get_all_list_length(uint16_t list_out[]):
                    uint16_t list[ALL_LIST_LENGTH_SIZE];
                    sdoinfo_get_list(LT_LIST_LENGTH, ALL_LIST_LENGTH_SIZE, list);
                    memcpy(list_out, list, ALL_LIST_LENGTH_SIZE * sizeof(uint16_t));
                    break;

/* FIXME change listtype to enum eListType type
 * See sdo.h may put eListType and SDO_Error to co_interface.h
 */
            case i_co[int j].od_get_list(uint16_t list_out[], unsigned size, unsigned listtype) -> {int size_out}:
                    uint16_t list[100];
                    size_out = sdoinfo_get_list(listtype, 100, list);
                    /* FIXME this memcpy will not work since sdoinfo_get_list() expects a uint16_t[] */
                    memcpy(list_out, list, size_out * sizeof(unsigned));
                    break;

            case i_co[int j].od_get_object_description(struct _sdoinfo_entry_description &obj_out, uint16_t index_, uint8_t subindex) -> { int error }:
                    struct _sdoinfo_entry_description obj;
                    /* FIXME misnomer, object description and entry description are separate now. */
                    /* FIXME the current CoE handler does not distinguish between object and entry description */
                    error = sdoinfo_get_object_description(index_, &obj);
                    memcpy(&obj_out, &obj, sizeof(struct _sdoinfo_entry_description));
                    break;

            case i_co[int j].od_get_data_length(uint16_t index_, uint8_t subindex) -> {uint32_t len, uint8_t error}:
                    struct _sdoinfo_entry_description entry;
                    error = sdoinfo_get_entry_description(index_, subindex, 0, &entry);
                    if (!error) {
                        len = (uint32_t)((entry.bitLength + 8 - 1) / 8);
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
