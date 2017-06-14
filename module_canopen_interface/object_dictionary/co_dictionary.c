/**
 * \file co_dictionary.c
 * \brief Main implementation of the CANopen object dictionary
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */


#include "co_dictionary.h"

#define BYTE_COUNT_ALL_ENTRY_VALUES   56
#define BYTE_COUNT_DEFAULT_VALUES     BYTE_COUNT_ALL_ENTRY_VALUES
#define BYTE_COUNT_MIN_VALUES         0
#define BYTE_COUNT_MAX_VALUES         0

const size_t entry_values_length           = 56;
const size_t entry_default_values_length   = 56;
const size_t entry_min_values_length       = 0;
const size_t entry_max_values_length       = 0;
const size_t string_length                 = 23;
const size_t object_entries_length         = 25;
const size_t object_dictionary_length      = 12;
const size_t bookmark_length               = 3;

struct _bookmarks bookmark[] = {
    { 0x1000, 0 },
    { 0x2000, 12 },
    { 0x3000, 24 }
};

/*
 * Local storage of entry values.
 *
 * All entries are stored as byte slices within this array. The value pointer
 * in \c COD_Entry points to the LSB of the value within this memory area.
 */
uint8_t entry_values[entry_values_length] = {
    0x92, 0x01, 0x02, 0x00, /* 0x1000:0 Start: 0 */
    0x04,                   /* 0x1018:0 Start: 4 */
    0xd2, 0x22, 0x00, 0x00, /* 0x1018:1 Start: 5 */
    0x01, 0x02, 0x00, 0x00, /* 0x1018:2 Start: 9 */
    0x02, 0x00, 0x00, 0x0A, /* 0x1018:3 Start: 13 */
    0x00, 0x00, 0x00, 0x00, /* 0x1018:4 Start: 17 */
    0x01,                   /* 0x1600:0 Start: 18 */
    0x20, 0x00, 0x01, 0x20, /* 0x1600:1 Start: 19 */
    0x01,                   /* 0x1a00:0 Start: 23 */
    0x20, 0x00, 0x02, 0x20, /* 0x1a00:1 Start: 24 */
    0x04,                   /* 0x1c00:0 Start: 28 */
    0x00, 0x00, 0x03, 0x04, /* 0x1c00:1..4 */
    0x00,                   /* 0x1c10:0 Start: 33 */
    0x00,                   /* 0x1c11:0 Start: 34 */
    0x01,                   /* 0x1c12:0 Start: 35 */
    0x00, 0x16,             /* 0x1c12:1 Start: 36 */
    0x01,                   /* 0x1c13:0 Start: 38 */
    0x00, 0x1a,             /* 0x1c13:1 Start: 39 */
    0x00, 0x00, 0x00, 0x00, /* 0x2001:0 Start: 41 */
    0x00, 0x00, 0x00, 0x00, /* 0x2002:0 Start: 45 */
    0x00, 0x00, 0x00, 0x00, /* 0x3000:0 Start: 49 */
};

/*
 * Local storage of default values \see OD_Entry
 */
const uint8_t entry_default_values[entry_default_values_length] = {
    0x92, 0x01, 0x02, 0x00, /* 0x1000:0 Start: 0 */
    0x04,                   /* 0x1018:0 Start: 4 */
    0xd2, 0x22, 0x00, 0x00, /* 0x1018:1 Start: 5 */
    0x01, 0x02, 0x00, 0x00, /* 0x1018:2 Start: 9 */
    0x02, 0x00, 0x00, 0x0A, /* 0x1018:3 Start: 13 */
    0x00, 0x00, 0x00, 0x00, /* 0x1018:4 Start: 17 */
    0x01,                   /* 0x1600:0 Start: 18 */
    0x20, 0x00, 0x01, 0x20, /* 0x1600:1 Start: 19 */
    0x01,                   /* 0x1a00:0 Start: 23 */
    0x20, 0x00, 0x02, 0x20, /* 0x1a00:1 Start: 24 */
    0x04,                   /* 0x1c00:0 Start: 28 */
    0x00, 0x00, 0x03, 0x04, /* 0x1c00:1..4 */
    0x00,                   /* 0x1c10:0 Start: 33 */
    0x00,                   /* 0x1c11:0 Start: 34 */
    0x01,                   /* 0x1c12:0 Start: 35 */
    0x00, 0x16,             /* 0x1c12:1 Start: 36 */
    0x01,                   /* 0x1c13:0 Start: 38 */
    0x00, 0x1a,             /* 0x1c13:1 Start: 39 */
    0x00, 0x00, 0x00, 0x00, /* 0x2001:0 Start: 41 */
    0x00, 0x00, 0x00, 0x00, /* 0x2002:0 Start: 45 */
    0x00, 0x00, 0x00, 0x00, /* 0x3000:0 Start: 49 */
};

/*
 * Not every entry has a min and max value, to save some memory only the actual
 * necessary bytes for all available min and max values should be allocated.
 */
const uint8_t entry_min_values[entry_min_values_length];

const uint8_t entry_max_values[entry_max_values_length];

/*
 * This array contains all the strings found in the dictionary. Strings are
 * considered constant and not changeable by the master.
 *
 * TODO Make a second array for object names???
 */
const char *string[] = {
    "Device Type",        /* 0x1000 */
    "Identity",           /* 0x1018 */
    "Subindex 000",
    "Vendor ID",
    "Product Code",
    "Revision Number",
    "Serial Number",
    "SubIndex 000",       /* 7: SubIndex for mutliple objects */
    "Rx PDO Mapping",     /* 8: 0x1600 */
    "Test Output PDO",
    "Tx PDO Mapping",     /* 10: 0x1a00 */
    "Test Input PDO",
    "Sync Manager",       /* 12: 0x1c00 */
    "SyncMan 0",
    "SyncMan 1",
    "SyncMan 2",
    "SyncMan 3",
    "SM 0 Assingment",    /* 17: 0x1c10 */
    "SM 1 Assingment",    /* 18: 0x1c11 */
    "SM 2 Assingment",    /* 19: 0x1c12 */
    "SubIndex 1",         /* 20: SubIndex 1 - can be used by multiple objects */
    "SM 3 Assingment",    /* 21: 0x1c13 */
    "Command Object",     /* 22: 0x3000 */
};

COD_Entry object_entries[] = {
    {
        CODE_SET_ENTRY_INDEX(0x1000, 0, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[0]),
        &(entry_values[0]),
        NULL,
        NULL,
        NULL
    },
    {
        CODE_SET_ENTRY_INDEX(0x1018, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[2]),
        &(entry_values[4]),
        &(entry_default_values[0]),
        &(entry_min_values[0]),
        &(entry_max_values[0])
    }, {
        CODE_SET_ENTRY_INDEX(0x1018, 1, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[3]),
        &(entry_values[5]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1018, 2, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[4]),
        &(entry_values[9]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1018, 3, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[5]),
        &(entry_values[13]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1018, 4, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[6]),
        &(entry_values[17]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1600, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[5]),
        &(entry_values[18]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1600, 1, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[5]),
        &(entry_values[19]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1a00, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[5]),
        &(entry_values[23]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1a00, 1, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[5]),
        &(entry_values[24]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c00, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[7]),
        &(entry_values[28]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c00, 1, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[13]),
        &(entry_values[29]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c00, 2, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[14]),
        &(entry_values[30]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c00, 3, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[15]),
        &(entry_values[31]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c00, 4, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[16]),
        &(entry_values[32]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c10, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[7]),
        &(entry_values[33]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c11, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[7]),
        &(entry_values[34]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c12, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[7]),
        &(entry_values[35]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c12, 1, 0),
        DEFTYPE_UNSIGNED16,
        16,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[20]),
        &(entry_values[36]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c13, 0, 0),
        DEFTYPE_UNSIGNED8,
        8,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[7]),
        &(entry_values[38]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x1c13, 1, 0),
        DEFTYPE_UNSIGNED16,
        16,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[20]),
        &(entry_values[39]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x2001, 0, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, ACCESS_TXPDO_MAP, ACCESS_ALL_RD),
        0,
        &(string[11]),
        &(entry_values[41]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x2002, 0, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, ACCESS_RXPDO_MAP, ACCESS_ALL_RDWR),
        0,
        &(string[9]),
        &(entry_values[45]),
        NULL,
        NULL,
        NULL
    }, {
        CODE_SET_ENTRY_INDEX(0x3000, 0, 0),
        DEFTYPE_UNSIGNED32,
        32,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RDWR),
        0,
        &(string[22]),
        &(entry_values[49]),
        NULL,
        NULL,
        NULL
    }
};

COD_Object object_dictionary[] = {
    {
        0x1000,
        OBJECT_TYPE_VAR,
        ACCESS_ALL_RD,
        0,
        &(string[0]),
        &(object_entries[0])
    },
    {
        0x1018,
        OBJECT_TYPE_RECORD,
        ACCESS_ALL_RD,
        4,                          /* max subindex */
        &(string[1]),
        &(object_entries[1])
    }, {
        0x1600, /* RxPDO: Output: Master->Slave */
        OBJECT_TYPE_RECORD,
        ACCESS_ALL_RD,
        1,
        &(string[8]),
        &(object_entries[6])
    }, {
        0x1A00, /* TxPDO: Input: Slave-> Master */
        OBJECT_TYPE_RECORD,
        ACCESS_ALL_RD,
        1,
        &(string[10]),
        &(object_entries[8]) /* previous object + number of entries of previous object */
    }, {
        0x1C00,
        OBJECT_TYPE_ARRAY,
        ACCESS_ALL_RD,
        4,
        &(string[12]),
        &(object_entries[10])
    }, {
        0x1C10,
        OBJECT_TYPE_ARRAY,
        ACCESS_ALL_RD,
        0,
        &(string[17]),
        &(object_entries[16])
    }, {
        0x1C11,
        OBJECT_TYPE_ARRAY,
        ACCESS_ALL_RD,
        0,
        &(string[18]),
        &(object_entries[17])
    }, {
        0x1C12,
        OBJECT_TYPE_ARRAY,
        ACCESS_ALL_RD,
        1,
        &(string[19]),
        &(object_entries[18])
    }, {
        0x1C13,
        OBJECT_TYPE_ARRAY,
        ACCESS_ALL_RD,
        1,
        &(string[21]),
        &(object_entries[20])
    }, {
        0x2001,
        OBJECT_TYPE_VAR,
        ACCESS_SET_FLAGS(0, 0, ACCESS_TXPDO_MAP, ACCESS_ALL_RD),
        0,
        &(string[11]),
        &(object_entries[22])
    }, {
        0x2002,
        OBJECT_TYPE_VAR,
        ACCESS_SET_FLAGS(0, 0, ACCESS_RXPDO_MAP, ACCESS_ALL_RD),
        0,
        &(string[9]),
        &(object_entries[23])
    }, {
        0x3000,
        OBJECT_TYPE_VAR,
        ACCESS_SET_FLAGS(0, 0, 0, ACCESS_ALL_RD),
        0,
        &(string[9]),
        &(object_entries[24])
    }
};
