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

SDO_Error sdo_error = SDO_NO_ERROR;

static COD_Entry *find_entry(uint16_t index, uint8_t subindex, COD_Entry * entries)
{
    size_t num_entries = sizeof(entries) / sizeof(entries[0]);
    COD_Entry *found = NULL;

    for (size_t i = 0; i < num_entries; i++) {
        if (CODE_GET_INDEX(entries[i].index) == index &&
            CODE_GET_SUBINDEX(entries[i].index) == subindex) {
            found = &(entries[i]);
            break;
        }
    }

    return found;
}

/*
 * public functions
 */

int sdo_entry_get_value(uint16_t index, uint8_t subindex, uint8_t *value, size_t bytesize, int master_request)
{
    COD_Entry *entry = find_entry(index, subindex, object_entries);
    size_t bytes = (entry->bitlength + 8 - 1) / 8;
    if (bytes != bytesize) {
        sdo_error = SDO_WRONG_TYPE;
        return (int)-sdo_error;
    }

    if (master_request &&
            (entry->access & ACCESS_ALL_RD) == 0) {
        sdo_error = SDO_WRITE_ONLY;
        return (int)-sdo_error;
    }

    if (!master_request) {
        entry->index = CODE_CLR_ENTRY_FLAG(entry->index);
    }

    memmove(value, entry->value, bytesize);
    return 0;
}

int sdo_entry_set_value(uint16_t index, uint8_t subindex, uint8_t *value, size_t bytesize, int master_request)
{
    COD_Entry *entry = find_entry(index, subindex, object_entries);
    size_t bytes = (entry->bitlength + 8 - 1) / 8;
    if (bytes != bytesize) {
        sdo_error = SDO_WRONG_TYPE;
        return (int)-SDO_WRONG_TYPE;
    }

    if (master_request &&
            (entry->access & ACCESS_ALL_WR) == 0) {
        sdo_error = SDO_READ_ONLY;
        return (int)-sdo_error;
    }

    if (master_request) {
        entry->index = CODE_SET_ENTRY_FLAG(entry->index);
    }

    memmove(entry->value, value, bytesize);
    return 0;
}

int sdo_entry_get_int8(uint16_t index, uint8_t subindex, int8_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_INT8, 0));
}

int sdo_entry_get_uint8(uint16_t index, uint8_t subindex, uint8_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_UINT8, 0));
}

int sdo_entry_get_int16(uint16_t index, uint16_t subindex, int16_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_INT16, 0));
}

int sdo_entry_get_uint16(uint16_t index, uint16_t subindex, uint16_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_UINT16, 0));
}

int sdo_entry_get_int32(uint16_t index, uint32_t subindex, int32_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_INT32, 0));
}

int sdo_entry_get_uint32(uint16_t index, uint32_t subindex, uint32_t *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_UINT32, 0));
}

int sdo_entry_get_real32(uint16_t index, uint32_t subindex, float *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_REAL32, 0));
}

int sdo_entry_get_real64(uint16_t index, uint32_t subindex, double *value)
{
	return (sdo_entry_get_value(index, subindex, (uint8_t *)value, TYPE_REAL64, 0));
}


int sdo_entry_set_int8(uint16_t index, uint8_t subindex, int8_t value)
{
    uint8_t val[sizeof(int8_t)];
    memmove(val, &value, sizeof(int8_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT8, 0));
}

int sdo_entry_set_uint8(uint16_t index, uint8_t subindex, uint8_t value)
{
    uint8_t val[sizeof(uint8_t)];
    memmove(val, &value, sizeof(uint8_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT8, 0));
}

int sdo_entry_set_int16(uint16_t index, uint16_t subindex, int16_t value)
{
    uint8_t val[sizeof(int16_t)];
    memmove(val, &value, sizeof(int16_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT16, 0));
}

int sdo_entry_set_uint16(uint16_t index, uint16_t subindex, uint16_t value)
{
    uint8_t val[sizeof(uint16_t)];
    memmove(val, &value, sizeof(uint16_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT16, 0));
}

int sdo_entry_set_int32(uint16_t index, uint32_t subindex, int32_t value)
{
    uint8_t val[sizeof(int32_t)];
    memmove(val, &value, sizeof(int32_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_INT32, 0));
}

int sdo_entry_set_uint32(uint16_t index, uint32_t subindex, uint32_t value)
{
    uint8_t val[sizeof(uint32_t)];
    memmove(val, &value, sizeof(uint32_t));
	return (sdo_entry_set_value(index, subindex, val, TYPE_UINT32, 0));
}

int sdo_entry_set_real32(uint16_t index, uint32_t subindex, float value)
{
    uint8_t val[sizeof(float)];
    memmove(val, &value, sizeof(float));
	return (sdo_entry_set_value(index, subindex, val, TYPE_REAL32, 0));
}

int sdo_entry_set_real64(uint16_t index, uint32_t subindex, double value)
{
    uint8_t val[8];
    memmove(val, &value, 8);
	return (sdo_entry_set_value(index, subindex, val, TYPE_REAL64, 0));
}
