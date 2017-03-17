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
    uint32_t index; ///< 16 bit int should be sufficient
    uint32_t subindex; ///< 16 bit int should be sufficient
    uint32_t objectDataType;
    uint32_t dataType;
    uint8_t objectCode;
    uint32_t bitLength;
    uint32_t objectAccess;
    uint32_t value; ///< real data type is defined by .dataType
    uint8_t name[50];
};

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
    int8_t operation_mode;     //      Modes of Operation
    uint16_t control_word;     //      Control Word

    int16_t target_torque;
    int32_t target_velocity;
    int32_t target_position;

    /* User defined PDOs */
    int32_t user1_in;
    int32_t user2_in;
    int32_t user3_in;
    int32_t user4_in;


    int8_t operation_mode_display; //      Modes of Operation Display
    uint16_t status_word;                   //  Status Word

    int16_t actual_torque;
    int32_t actual_velocity;
    int32_t actual_position;

    /* User defined PDOs */
    int32_t user1_out;
    int32_t user2_out;
    int32_t user3_out;
    int32_t user4_out;
} pdo_values_t;

typedef uint16_t pdo_size_t;

/**
 * @brief Communication interface for OD service
 */
interface i_co_communication
{
    /**
     * @brief Transfers PDOs from slave to master
     */
    void pdo_in_buffer(unsigned int size, pdo_size_t data_out[]);

    /**
     * @brief Receives PDOs from master to slave
     */
    unsigned int pdo_out_buffer(pdo_size_t data_in[]);

    {pdo_values_t, unsigned int} pdo_exchange_app(pdo_values_t pdo_out);

    void pdo_in(uint8_t pdo_number, uint64_t value);

    {uint64_t, uint8_t} pdo_out(uint8_t pdo_number);

    pdo_values_t pdo_init(void);



    /**
     * @brief Returns an object value from dictionary.
     * @return Object value, bitlength, error
     */
    {uint32_t, uint32_t, uint8_t} od_get_object_value(uint16_t index_);

    /**
     * @brief Set an object value in dictionary.
     * @return Error
     */
    uint8_t od_set_object_value(uint16_t index_, uint32_t value);


    uint8_t od_set_object_value_buffer(uint16_t index_, uint8_t data_buffer[]);

    {uint32_t, uint8_t} od_get_object_value_buffer(uint16_t index_, uint8_t data_buffer[]);

    /**
     * @brief Get whole entry description of object.
     * @return entry description, error
     */
    {struct _sdoinfo_entry_description, uint8_t} od_get_entry_description(uint16_t index_, uint32_t valueinfo);

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
     * @return 0 if found else 1
     */
    int od_get_object_description(struct _sdoinfo_entry_description &obj, unsigned index_);


    uint32_t od_get_data_length(uint16_t index_);

    {unsigned, unsigned} od_find_index(uint16_t address, uint8_t subindex);

    uint8_t od_get_access(uint16_t index_);


//    // PDO Notification
//    [[clears_notification]]
//    void pdo_downstream_done(void);
//
//    [[notification]]
//    slave void pdo_downstream_ready(void);

    // SDO Notification
    /**
     * @brief Set flag "configuration done"
     */
    void configuration_ready(void);

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
