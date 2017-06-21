/*
 * co_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef CO_INTERFACE_H_
#define CO_INTERFACE_H_

#include <coe_handling.h>
#include <stdint.h>

#define CO_IF_COUNT 4
#define OD_LIST_ALL 1

#ifndef REQUEST_FORM_MASTER
#define REQUEST_FROM_MASTER   1
#endif

#ifndef REQUEST_FROM_APP
#define REQUEST_FROM_APP      0
#endif

/**
 * \brief Available SDO commands
 */
enum eSdoCommand {
    OD_COMMAND_NONE = 0
    ,OD_COMMAND_WRITE_CONFIG
    ,OD_COMMAND_READ_CONFIG
};

/**
 * \brief State of the current SDO command
 */
enum eSdoState {
    OD_COMMAND_STATE_IDLE = 0       ///< SDO state is idle and ready to accept new commands
    ,OD_COMMAND_STATE_PROCESSING    ///< SDO command is currently processed
    ,OD_COMMAND_STATE_SUCCESS       ///< SDO command finished successfully
    ,OD_COMMAND_STATE_ERROR         ///< SDO command finished with a error
};

/**
 * @brief Access types
 */
enum eAccessRights {
  RO = 0x07,
  WO = 0x38,
  RW = 0x3f,
};

/* FIXME keep typedef for obfuscation? */
typedef uint8_t pdo_size_t;

/**
 * @brief Communication interface for OD service request to network service
 */
interface i_co_communication
{
    /**
     * @brief Receives PDOs from master to slave
     * @param[in] pdo_number    PDO number
     * @param[in] size          PDO buffer size
     * @param[in] data_in       PDO buffer
     */
    void pdo_in(uint8_t pdo_number, unsigned int size, pdo_size_t data_in[]);

    /**
     * @brief Transfers PDOs from slave to master
     * @param[in]  pdo_number    PDO number
     * @param[out] data_in       PDO buffer
     * @return     PDO buffer size
     */
    unsigned int pdo_out(uint8_t pdo_number, pdo_size_t data_out[]);


    /**
     * @brief Returns an object value from dictionary.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @return Object value, bitlength, Error: 0 -> No error, 2 -> Index not found, 3 -> Subindex not found
     */
    {uint32_t, uint32_t, uint8_t} od_get_object_value(uint16_t index_, uint8_t subindex);

    /**
     * @brief Set an object value in dictionary.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[in] value     Value, which will set in OD
     * @return Error: 0 -> No error, 1 -> RO, 2 -> Index not found, 3 -> Subindex not found
     */
    uint8_t od_set_object_value(uint16_t index_, uint8_t subindex, uint32_t value);

    /**
     * @brief Master reads an object value from dictionary.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[in] capacity  The capacity of the output array value_out
     * @param[out] value_out  The value as byte array of the requested entry
     * @return bitlength    Read bitlength of the entry value - Object value, bitlength, Error: 0 -> No error, 2 -> Index not found, 3 -> Subindex not found
     * @return error_out    0 on no error
     */
    {uint32_t, uint8_t} od_master_get_object_value(uint16_t index_, uint8_t subindex, static const size_t capacity, uint8_t value_out[]);

    /**
     * @brief Master set an object value in dictionary.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[in] value     Value array, which will set in OD
     * @param[in] capacity  Size of the value field
     * @return Error: 0 -> No error, 1 -> RO, 2 -> Index not found, 3 -> Subindex not found, 255 -> wrong capacity for entry
     */
    uint8_t od_master_set_object_value(uint16_t index_, uint8_t subindex, uint8_t value[], size_t capacity);

    /**
     * @brief Returns an object value from dictionary.
     *
     * NOTE: For CAN the data_buffer is maxiumum 8 byte wide.
     *
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[out] data_buffer  OD value
     * @return Bitlength, Error: 0 -> No error, 2 -> Index not found, 3 -> Subindex not found
     */
    {uint32_t, uint8_t} od_get_object_value_buffer(uint16_t index_, uint8_t subindex, uint8_t data_buffer[]);

    /**
     * @brief Set an object value in dictionary.
     *
     * NOTE: For CAN the data_buffer is maxiumum 8 byte wide.
     *
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[in] data_buffer     Value, which will set in OD
     * @return Error: 0 -> No error, 1 -> RO, 2 -> Index not found, 3 -> Subindex not found
     */
    uint8_t od_set_object_value_buffer(uint16_t index_, uint8_t subindex, uint8_t data_buffer[]);


    /**
     * @brief Get whole entry description of object.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @return entry description, error
     */
    {struct _sdoinfo_entry_description, uint8_t} od_get_entry_description(uint16_t index_, uint8_t subindex, uint32_t valueinfo);

    /**
     * @brief Returns an array with five length entrys (Currently just one entry).
     *
     * The list lengths are:
     * Arrary Index | List type
     * -------------+-----------
     *        0     | All objects (without subindex)
     *        1     | RxPDO Mappable
     *        2     | TxPDO Mappable
     *        3     | List Replace
     *        4     | List all Startup Parameters
     *
     * @param[out] Array with all list lengths
     */
    void od_get_all_list_length(uint16_t lists[]);

    /**
     * @brief Returns a list with all index.
     *
     * @param[out] list      array of indexes for \c listtype
     * @param[in]  size      capacity of the list
     * @param[in] listtype   type of indexes to return in the list
     *                       (values: 1 - all, 2 - RX mappable, 3 - TX mappable, 4 - backup, 5 - startup)
     * @return List length
     */
    int od_get_list(uint16_t list[], unsigned size, unsigned listtype);

    /**
     * @brief Get single entry description.
     * @param[out] obj      SDO info struct
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @return 0 if found else 1
     */
    int od_get_object_description(struct _sdoinfo_entry_description &obj, uint16_t index_, uint8_t subindex);

    /**
     * @brief Get data length of an single OD entry value.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @return Bitlength, Error
     */
    {uint32_t, uint8_t} od_get_data_length(uint16_t index_, uint8_t subindex);

    /**
     * @brief Get access type of an single OD entry value.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @return Access type, Error
     */
    {enum eAccessRights, uint8_t} od_get_access(uint16_t index_, uint8_t subindex);


//    // PDO Notification
//    [[clears_notification]]
//    void pdo_downstream_done(void);
//
//    [[notification]]
//    slave void pdo_downstream_ready(void);

    // SDO Notification
    /**
     * @brief Set flag "configuration done"
     *
     * @param[in] opmode  1 - if opmode is entered, 0 - if opmode is left.
     */
    void operational_state_change(int opmode);

    /**
     * @brief Check if the EtherCAT State Machine (ESM) is in operation mode
     *
     * @return  1 - if drive is in operational state; 0 - otherwise
     */
    int in_operational_state(void);

    /**
     * @brief Delete flag "configuration done"
     */
    void configuration_done(void);

    /**
     * @brief Get flag status.
     * @return Flag status.
     */
    int configuration_get(void);

    void inactive_communication(void);

    /*
     *  commanding handling
     */

    /* Since a notification cannot be send from a interface call this one is
     * necessary to poll if a command is ready to be executed */
    enum eSdoCommand command_ready(void);

    void command_set_result(int result);
};


#endif /* CO_INTERFACE_H_ */
