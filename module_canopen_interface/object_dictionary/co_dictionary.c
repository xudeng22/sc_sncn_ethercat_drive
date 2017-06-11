/**
 * \file co_dictionary.c
 * \brief Main implementation of the CANopen object dictionary
 */

#include "co_dictionary.h"

#include <xccompat.h>
#include <string.h>

#define TRY    3

#define BYTE_COUNT_ALL_ENTRY_VALUES   0
#define BYTE_COUNT_DEFAULT_VALUES     BYTE_COUNT_ALL_ENTRY_VALUES
#define BYTE_COUNT_MIN_VALUES         0
#define BYTE_COUNT_MAX_VALUES         0

/*
 * Local storage of entry values.
 *
 * All entries are stored as byte slices within this array. The value pointer
 * in \c OD_Entry points to the LSB of the value within this memory area.
 */
static uint8_t entry_values[BYTE_COUNT_ALL_ENTRY_VALUES];

/*
 * Local storage of default values \see OD_Entry
 */
static const uint8_t entry_default_values[BYTE_COUNT_DEFAULT_VALUES];

/*
 * Not every entry has a min and max value, to save some memory only the actual
 * necessary bytes for all available min and max values should be allocated.
 */
static const uint8_t entry_min_values[BYTE_COUNT_MIN_VALUES];
static const uint8_t entry_max_values[BYTE_COUNT_MAX_VALUES];

/*
 * This array contains all the strings found in the dictionary. Strings are
 * considered constant and not changeable by the master.
 *
 * TODO Make a second array for object names???
 */
static const char *entry_name[] = {
    "Identity Object",
    "Number of Entries",
    "Vendor ID",
    "Product Code",
    "Revision Number",
    "Serial Number",
    NULL
};

static COD_Entry object_entries[] = {
    {
        0,
        DEFTYPE_UNSIGNED8,
        8,
        OBJECT_ACCESS_ALL_RD,
        0,
        0,
        (char *)&(string[1]),
        &(entry_values[0]),
        &(entry_default_values[0]),
        &(entry_min_values[0]),
        &(entry_max_values[0])
    }, {
        1,
        DEFTYPE_UNSIGNED32,
        32,
        OBJECT_ACCESS_ALL_RD,
        0,
        0,
        (char *)&(string[2]),
        NULL,
        NULL,
        NULL,
        NULL
    }, {
        2,
        DEFTYPE_UNSIGNED32,
        32,
        OBJECT_ACCESS_ALL_RD,
        0,
        0,
        (char *)&(string[3]),
        NULL,
        NULL,
        NULL,
        NULL
    }, {
        3,
        DEFTYPE_UNSIGNED32,
        32,
        OBJECT_ACCESS_ALL_RD,
        0,
        0,
        (char *)&(string[4]),
        NULL,
        NULL,
        NULL,
        NULL
    }, {
        4,
        DEFTYPE_UNSIGNED32,
        32,
        OBJECT_ACCESS_ALL_RD,
        0,
        0,
        (char *)&(string[5]),
        NULL,
        NULL,
        NULL,
        NULL
    }
};

static COD_Object object_dictionary[] = {
    {
        0x1018,
        OBJECT_TYPE_RECORD,
        OBJECT_ACCESS_ALL_RD,
        5,                          /* max subindex */
        &(object_entries[0]),
        (char *)&(string[0])
    }
};

static COD_Index object_index[] = {
    {0x1018, &object_1018, &object_1018_entries}
};

/*
 * special indexing for faster access
 */

#define ENTRY_FLAGS   0x00  /* Dirty flag and maybe more */

static OD_Entry_Index entry_index[] = {
    {0x1018, 1, ENTRY_FLAGS, &(entry_values[1])},
    {0x1018, 2, ENTRY_FLAGS, &(entry_values[2])},
    {0x1018, 3, ENTRY_FLAGS, &(entry_values[3])},
    {0x1018, 4, ENTRY_FLAGS, &(entry_values[4])},
};

static COD_Entry *find_entry(uint16_t index, uint8_t subindex, OD_Entry_Index * entries)
{
    size_t num_entries = sizeof(entry_index) / sizeof(entry_index[0]);
    OD_Entry_Index *found = NULL;

    for (size_t i = 0; i < num_entries; i++) {
        if (entry_index[i].index == index && entry_index[i].subindex == subindex) {
            found = &entry_index[i];
            break;
        }
    }

    return found;
}

/*
 * public functions
 */

void object_entry_set_value(uint16_t index, uint8_t subindex, void *value, size_t bitsize)
{
#if TRY == 0
    /* first try */
    OD_Index *obj = find_index(index, object_index);
    OD_Entry *entry = get_subindex(obj, subindex);

#elif TRY == 1
    /* second try */
    OD_Entry *entry = (find_index(index, object_index))->entry[subindex];

#else
    /* thrid try */
    OD_Entry *entry = find_entry(index, subindex, entry_index);

#endif

    memmove(entry->value, value, bitsize / 8);
}
