/**
 * \file sdo.c
 * \brief SDO access to object dictionary
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */

#include "co_dictionary.h"
#include "sdo.h"

#include <stdint.h>
#include <string.h>

#define TYPE_BOOL       1
#define TYPE_BIT        1
#define TYPE_INT8       1
#define TYPE_UINT8      1
#define TYPE_INT16      2
#define TYPE_UINT16     2
#define TYPE_INT32      4
#define TYPE_UINT32     4
#define TYPE_FLOAT      4
#define TYPE_REAL32     TYPE_FLOAT
#define TYPE_DOUBLE     8
#define TYPE_REAL64     TYPE_DOUBLE

#define INT_CEIL(a,b)         ((a + b - 1) / b)
#define BYTES_FROM_BITS(a)    INT_CEIL(a, 8)

SDO_Error sdo_error = SDO_NO_ERROR;

static COD_Object *find_object(uint16_t index)
{
    COD_Object *found = NULL;

    for (size_t i = 0; i < object_dictionary_length; i++) {
        if (object_dictionary[i].index == index) {
            found = &(object_dictionary[i]);
            break;
        }
    }

    sdo_error = (found == NULL) ? SDO_ERROR_NOT_FOUND : SDO_NO_ERROR;

    return found;
}

static COD_Entry *find_entry(uint16_t index, uint8_t subindex)
{
    COD_Entry *found = NULL;
    size_t start = 0;

    for (size_t i = 0; i < bookmark_length; i++) {
        if ((index & 0xf000) >= bookmark[i].index) {
            start = bookmark[i].entry_element;
        }
    }

    for (size_t i = start; i < object_entries_length; i++) {
        if (CODE_GET_INDEX(object_entries[i].index) == index &&
            CODE_GET_SUBINDEX(object_entries[i].index) == subindex) {
            found = &(object_entries[i]);
            break;
        }
    }

    return found;
}

/*
 * public functions
 */

size_t sdo_entry_get_bytecount(uint16_t index, uint8_t subindex)
{
    size_t bitsize = sdo_entry_get_bitsize(index, subindex);
    return BYTES_FROM_BITS(bitsize);
}

size_t sdo_entry_get_bitsize(uint16_t index, uint8_t subindex)
{
    COD_Entry *entry = find_entry(index, subindex);
    if (entry == NULL) {
        sdo_error = SDO_ERROR_NOT_FOUND;
        return 0;
    }
    return (entry->bitsize);
}

int sdo_entry_get_position(uint16_t index, uint8_t subindex)
{
    int position = -1;

    for (size_t i = 0; i < object_entries_length; i++) {
        if (CODE_GET_INDEX(object_entries[i].index) == index &&
            CODE_GET_SUBINDEX(object_entries[i].index) == subindex) {
            position = (int)i;
            break;
        }
    }

    return position;
}

int sdo_entry_get_value(uint16_t index, uint8_t subindex, size_t capacity, int master_request, uint8_t *value, size_t *bitsize)
{
    COD_Entry *entry = find_entry(index, subindex);
    if (entry == NULL) {
        sdo_error = SDO_ERROR_NOT_FOUND;
        return (int)-sdo_error;
    }

    size_t bytes = BYTES_FROM_BITS(entry->bitsize);
    /* I only give a error if the requested bytesize is smaller than the actual
     * bytesize to allow a larger return buffer than the actual data size is. */
    if (bytes > capacity) {
        sdo_error = SDO_ERROR_WRONG_TYPE;
        return (int)-sdo_error;
    }

    if (master_request &&
            (entry->access & ACCESS_ALL_RD) == 0) {
        sdo_error = SDO_ERROR_WRITE_ONLY;
        return (int)-sdo_error;
    }

    if (!master_request) {
        entry->index = CODE_CLR_ENTRY_FLAG(entry->index);
    }

    memmove(value, entry->value, bytes);
    if (bitsize != NULL) {
        *bitsize = entry->bitsize;
    }
    return 0;
}

int sdo_entry_set_value(uint16_t index, uint8_t subindex, uint8_t *value, size_t bytesize, int master_request)
{
    COD_Entry *entry = find_entry(index, subindex);
    if (entry == NULL) {
        sdo_error = SDO_ERROR_NOT_FOUND;
        return (int)-sdo_error;
    }

    size_t bytes = BYTES_FROM_BITS(entry->bitsize);
    if (bytes != bytesize) {
        sdo_error = SDO_ERROR_WRONG_TYPE;
        return (int)-SDO_ERROR_WRONG_TYPE;
    }

    if (master_request &&
            (entry->access & ACCESS_ALL_WR) == 0) {
        sdo_error = SDO_ERROR_READ_ONLY;
        return (int)-sdo_error;
    }

    if (master_request) {
        entry->index = CODE_SET_ENTRY_FLAG(entry->index);
    }

    memmove(entry->value, value, bytesize);
    return 0;
}

int sdo_entry_get_int8(uint16_t index, uint8_t subindex, int8_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_INT8, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_uint8(uint16_t index, uint8_t subindex, uint8_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_UINT8, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_int16(uint16_t index, uint16_t subindex, int16_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_INT16, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_uint16(uint16_t index, uint16_t subindex, uint16_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_UINT16, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_int32(uint16_t index, uint32_t subindex, int32_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_INT32, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_uint32(uint16_t index, uint32_t subindex, uint32_t *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_UINT32, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_real32(uint16_t index, uint32_t subindex, float *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_REAL32, master_request, (uint8_t *)value, &bitsize));
}

int sdo_entry_get_real64(uint16_t index, uint32_t subindex, double *value, int master_request)
{
    size_t bitsize = 0;
	return (sdo_entry_get_value(index, subindex, TYPE_REAL64, master_request, (uint8_t *)value, &bitsize));
}


int sdo_entry_set_int8(uint16_t index, uint8_t subindex, int8_t value, int master_request)
{
    uint8_t val[sizeof(int8_t)];
    memmove(val, &value, sizeof(int8_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT8, master_request));
}

int sdo_entry_set_uint8(uint16_t index, uint8_t subindex, uint8_t value, int master_request)
{
    uint8_t val[sizeof(uint8_t)];
    memmove(val, &value, sizeof(uint8_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT8, master_request));
}

int sdo_entry_set_int16(uint16_t index, uint16_t subindex, int16_t value, int master_request)
{
    uint8_t val[sizeof(int16_t)];
    memmove(val, &value, sizeof(int16_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT16, master_request));
}

int sdo_entry_set_uint16(uint16_t index, uint16_t subindex, uint16_t value, int master_request)
{
    uint8_t val[sizeof(uint16_t)];
    memmove(val, &value, sizeof(uint16_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT16, master_request));
}

int sdo_entry_set_int32(uint16_t index, uint32_t subindex, int32_t value, int master_request)
{
    uint8_t val[sizeof(int32_t)];
    memmove(val, &value, sizeof(int32_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT32, master_request));
}

int sdo_entry_set_uint32(uint16_t index, uint32_t subindex, uint32_t value, int master_request)
{
    uint8_t val[sizeof(uint32_t)];
    memmove(val, &value, sizeof(uint32_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT32, master_request));
}

int sdo_entry_set_real32(uint16_t index, uint32_t subindex, float value, int master_request)
{
    uint8_t val[sizeof(float)];
    memmove(val, &value, sizeof(float));
	return (sdo_entry_set_value(index, subindex, val, TYPE_REAL32, master_request));
}

int sdo_entry_set_real64(uint16_t index, uint32_t subindex, double value, int master_request)
{
    uint8_t val[8];
    memmove(val, &value, 8);
	return (sdo_entry_set_value(index, subindex, val, TYPE_REAL64, master_request));
}

/*
 * SDO Info access functions
 */

static size_t get_object_list_indexes(uint16_t flag_mask, size_t capacity, uint16_t *list)
{
    size_t length = object_dictionary_length;
    size_t listsize = 0;

    if (capacity < object_dictionary_length) {
        sdo_error = SDO_ERROR_INSUFFICIENT_BUFFER;
        length = capacity;
    }

    for (size_t i = 0; i < length; i++) {
        if (!flag_mask || ((object_dictionary[i].access & 0x3c0) & flag_mask)) {
            memcpy((void *)(list + listsize), &(object_dictionary[i].index), sizeof(uint16_t));
            listsize++;
        }
    }

    return listsize;
}

static size_t get_all_list_counts(size_t capacity, uint16_t *list)
{
    const size_t LIST_COUNT = 5;

    list[0] = object_dictionary_length;

    for (size_t i = 0; i < object_dictionary_length; i++) {
        if (object_dictionary[i].access & ACCESS_RXPDO_MAP) {
            list[LT_RX_PDO_OBJECTS - 1] += 1;
        }

        if (object_dictionary[i].access & ACCESS_TXPDO_MAP) {
            list[LT_TX_PDO_OBJECTS - 1] += 1;
        }

        if (object_dictionary[i].access & ACCESS_BACKUP) {
            list[LT_BACKUP_OBJECTS - 1] += 1;
        }

        if (object_dictionary[i].access & ACCESS_STARTUP) {
            list[LT_STARTUP_OJBECTS - 1] += 1;
        }
    }

    return (size_t)LIST_COUNT;
}

size_t sdoinfo_get_list(enum eListType listtype, size_t capacity, uint16_t *list)
{
    size_t listsize = 0;

    switch (listtype) {
        case LT_LIST_LENGTH:
            listsize = get_all_list_counts(capacity, list);
            break;

        case LT_ALL_OBJECTS:
            listsize = get_object_list_indexes(0, capacity, list);
            break;

        case LT_RX_PDO_OBJECTS:
            listsize = get_object_list_indexes(ACCESS_RXPDO_MAP, capacity, list);
            break;

        case LT_TX_PDO_OBJECTS:
            listsize = get_object_list_indexes(ACCESS_TXPDO_MAP, capacity, list);
            break;

        case LT_BACKUP_OBJECTS:
            listsize = get_object_list_indexes(ACCESS_BACKUP, capacity, list);
            break;

        case LT_STARTUP_OJBECTS:
            listsize = get_object_list_indexes(ACCESS_STARTUP, capacity, list);
            break;

        default:
            sdo_error = SDO_ERROR_INVALID_LIST;
            listsize = 0;
            break;
    }

    return listsize;
}

int sdoinfo_get_object_description(uint16_t index, struct _sdoinfo_entry_description *obj_out)
{
    COD_Object *object = find_object(index);
    if (object == NULL) {
        return (int)-sdo_error;
    }

    obj_out->index = object->index;
    obj_out->objectCode = object->type;
    obj_out->objectAccess = object->access;
    obj_out->dataType = object->data_type;
    obj_out->value = object->max_subindex;
    memcpy(obj_out->name, *object->name, 50);

    return 0;
}

int sdoinfo_get_entry_description(uint16_t index, uint8_t subindex, unsigned int valuleinfo,
        struct _sdoinfo_entry_description *obj_out)
{
    COD_Entry *entry = find_entry(index, subindex);
    if (entry == NULL) {
        return (int)-sdo_error;
    }

    /* FIXME value is not flexible, value is not necessary for description
     * SOLUTION: co_dictionary hold a export struct for object and entry where the values for
     * default, min and max are stored.
     */

    obj_out->index = CODE_GET_INDEX(entry->index);
    obj_out->subindex = CODE_GET_SUBINDEX(entry->index);
    obj_out->dataType = entry->data_type;
    obj_out->bitLength = entry->bitsize;
    obj_out->objectAccess = entry->access;
    memcpy(obj_out->name, *(entry->name), 50);
    /* FIXME use valueinfo to figure out what needs to be added in reply */
    size_t bytes_to_copy = BYTES_FROM_BITS(entry->bitsize);
    if (bytes_to_copy > sizeof(uint32_t)) {
        bytes_to_copy = sizeof(uint32_t);
    }
    memcpy((void *)&(obj_out->value), entry->value, bytes_to_copy);
    return 0;
}
