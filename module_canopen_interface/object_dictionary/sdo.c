/**
 * \file sdo.c
 * \brief SDO access to object dictionary
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */

#include "co_dictionary.h"
#include "sdo.h"

#include <stdint.h>

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
