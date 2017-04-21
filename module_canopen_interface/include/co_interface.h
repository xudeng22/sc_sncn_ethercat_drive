/*
 * co_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef CO_INTERFACE_H_
#define CO_INTERFACE_H_

#include <stdint.h>

#define CO_IF_COUNT 3

/** entry description structure */
struct _sdoinfo_entry_description {
    uint16_t index; ///< 16 bit int should be sufficient
    uint8_t subindex; ///< 16 bit int should be sufficient
    uint8_t objectDataType;
    uint8_t dataType;
    uint8_t objectCode;
    uint8_t bitLength;
    uint8_t objectAccess;
    uint32_t value; ///< real data type is defined by .dataType
    uint8_t name[50];
};

/**
 * @brief Access types
 */
enum {
  RO = 0x07,
  WO = 0x38,
  RW = 0x3f,
};

/**
 * @brief
 *  Struct for Tx, Rx PDOs
 */
typedef struct
{
    uint16_t controlword;
    int8_t op_mode;
    int16_t target_torque;
    int32_t target_position;
    int32_t target_velocity;
    int32_t offset_torque;
    uint32_t tuning_command;
    uint8_t digital_output1;
    uint8_t digital_output2;
    uint8_t digital_output3;
    uint8_t digital_output4;
    uint32_t user_mosi;
    uint16_t statusword;
    int8_t op_mode_display;
    int32_t position_value;
    int32_t velocity_value;
    int16_t torque_value;
    int32_t secondary_position_value;
    int32_t secondary_velocity_value;
    uint16_t analog_input1;
    uint16_t analog_input2;
    uint16_t analog_input3;
    uint16_t analog_input4;
    uint32_t tuning_status;
    uint8_t digital_input1;
    uint8_t digital_input2;
    uint8_t digital_input3;
    uint8_t digital_input4;
    uint32_t user_miso;
    uint32_t timestamp;
} pdo_values_t;

#if COM_ETHERCAT || COM_ETHERNET
typedef uint8_t pdo_size_t;
#elif COM_CAN
typedef uint8_t pdo_size_t;
#endif

/**
 * @brief Communication interface for OD service
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
     * @brief Exchange PDOs with CANopen Interface Service and application
     * @param[in]   pdo_out PDOs, which will sent to the master.
     * @return  PDOs, which are received from the master.
     * @return  unsigned int    Communication state
     */
    {pdo_values_t, unsigned int} pdo_exchange_app(pdo_values_t pdo_out);


    /**
     * @brief Initialized PDO struct
     * @return Empty PDO struct
     */
    pdo_values_t pdo_init(void);



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
     * @brief Returns an object value from dictionary.
     * @param[in] index_    Object dictionary index
     * @param[in] subindex  Object dictionary subindex
     * @param[out] data_buffer  OD value
     * @return Bitlength, Error: 0 -> No error, 2 -> Index not found, 3 -> Subindex not found
     */
    {uint32_t, uint8_t} od_get_object_value_buffer(uint16_t index_, uint8_t subindex, uint8_t data_buffer[]);

    /**
     * @brief Set an object value in dictionary.
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
     */
    void od_get_all_list_length(uint32_t lists[]);

    /**
     * @brief Returns a list with all index.
     * @return List length
     */
    int od_get_list(unsigned list[], unsigned size, unsigned listtype);

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
    {uint8_t, uint8_t} od_get_access(uint16_t index_, uint8_t subindex);


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

};


#endif /* CO_INTERFACE_H_ */
