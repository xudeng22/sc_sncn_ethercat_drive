/**
 * \file sdo.h
 * \brief SDO access to object dictionary
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>

#ifndef SDO_H
#define SDO_H

#include <stdint.h>

typedef enum {
    SDO_NO_ERROR = 0
    ,SDO_ERROR
    ,SDO_NOT_FOUND
    ,SDO_READ_ONLY
    ,SDO_WRITE_ONLY
    ,SDO_WRONG_TYPE
} SDO_Error;

enum eListType {
    LT_LIST_LENGTH = 0
    ,LT_ALL_OBJECTS = 1
    ,LT_RX_PDO_OBJECTS
    ,LT_TX_PDO_OBJECTS
    ,LT_BACKUP_OBJECTS
    ,LT_STARTUP_OJBECTS
};

int sdo_entry_set_value(uint16_t index, uint8_t subindex, void *value);

int sdo_entry_get_value(uint16_t index, uint8_t subindex, void *value);

/**
 * \brief Get object lists and listlength
 *
 * With `listtype == LT_LIST_LENGTH` a list with 5 elements is returned:
 * - list[0] := number of all objects in the dictionary
 * - list[1] := number of all RXPDO objects
 * - list[2] := number of all RXPDO objects
 * - list[3] := number of backup objects
 * - list[4] := number of startup objects
 *
 * A call with another listtype returns a list of object indexes for the
 * accoring list, \see enum eListType for more information on list types.
 */
void sdoinfo_get_list(enum eListType listtype, uint16_t *list, size_t capacity);

void sdoinfo_get_object(uint16_t index);

void sdoinfo_get_entry(uint16_t index, uint8_t subindex);

#endif /* SDO_H */
