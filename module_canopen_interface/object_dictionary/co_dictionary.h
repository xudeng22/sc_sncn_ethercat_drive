/**
 * \file co_dictionary.h
 * \brief Main implementation of the CANopen object dictionary
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */

#include <stdlib.h>
#include <stdint.h>

#ifndef OD_OBJECT_H
#define OD_OBJECT_H

/*
 * Definitions of bit fields for object access
 */

#define ACCESS_PO_RD       0x0001
#define ACCESS_SO_RD       0x0002
#define ACCESS_OP_RD       0x0004
#define ACCESS_ALL_RD      (ACCESS_PO_RD | ACCESS_SO_RD | ACCESS_OP_RD)

#define ACCESS_PO_WR       0x0008
#define ACCESS_SO_WR       0x0010
#define ACCESS_OP_WR       0x0020
#define ACCESS_ALL_WR      (ACCESS_PO_WR | ACCESS_SO_WR | ACCESS_OP_WR)

#define ACCESS_PO_RDWR       (ACCESS_PO_RD | ACCESS_PO_WR)
#define ACCESS_SO_RDWR       (ACCESS_SO_RD | ACCESS_SO_WR)
#define ACCESS_OP_RDWR       (ACCESS_OP_RD | ACCESS_OP_WR)
#define ACCESS_ALL_RDWR      (ACCESS_PO_RDWR | ACCESS_SO_RDWR | ACCESS_OP_RDWR)

#define ACCESS_RXPDO_MAP   0x0040
#define ACCESS_TXPDO_MAP   0x0080
#define ACCESS_RXTXPDO_MAP 0x00C0

#define ACCESS_BACKUP      0x0100
#define ACCESS_STARTUP     0x0200

#define ACCESS_ALL_LIST_FLAGS   (ACCESS_RXPDO_MAP |ACCESS_TXPDO_MAP | ACCESS_BACKUP | ACCESS_STARTUP)

#define ACCESS_SET_FLAGS(b, s, p,a)    (b | s | p | a)

/*
 * Value info
 */

#define VALUEINFO_UNIT_TYPE      0x08
#define VALUEINFO_DEFAULT_VALUE  0x10
#define VALUEINFO_MIN_VALUE      0x20
#define VALUEINFO_MAX_VALUE      0x40

/*
 * list of dictionary lists identifiers
 */

#define LIST_ALL_LIST_LENGTH         0x00
#define LIST_ALL_OBJECTS             0x01
#define LIST_RXPDO_MAPABLE           0x02
#define LIST_TXPDO_MAPABLE           0x03
#define LIST_DEVICE_REPLACEMENT      0x04
#define LIST_STARTUP_PARAMETER       0x05

/*
 * possible object types of dictionary objects
 *
 * FIXME according to ETG1000.6 v1.0.3 only VAR, RECORD and ARRAY are expected
 * in SDO Info reply.
 */

#define OBJECT_TYPE_DOMAIN     0x0
#define OBJECT_TYPE_DEFTYPE    0x5
#define OBJECT_TYPE_DEFSTRUCT  0x6
#define OBJECT_TYPE_VAR        0x7
#define OBJECT_TYPE_ARRAY      0x8
#define OBJECT_TYPE_RECORD     0x9

/*
 * Index of Basic Data Types
 */

#define DEFTYPE_BOOLEAN          0x0001
#define DEFTYPE_INTEGER8         0x0002
#define DEFTYPE_INTEGER16        0x0003
#define DEFTYPE_INTEGER32        0x0004
#define DEFTYPE_INTEGER64        0x0015
#define DEFTYPE_UNSIGNED8        0x0005
#define DEFTYPE_UNSIGNED16       0x0006
#define DEFTYPE_UNSIGNED32       0x0007
#define DEFTYPE_REAL32           0x0008
#define DEFTYPE_VISIBLE_STRING   0x0009
#define DEFTYPE_OCTET_STRING     0x000A
#define DEFTYPE_UNICODE_STRING   0x000B
#define DEFTYPE_TIME_OF_DAY      0x000C
#define DEFTYPE_TIME_DIFFERENCE  0x000D

#define DEFTYPE_DOMAIN           0x000F

#define DEFSTRUCT_PDO_PARAMETER  0x0020
#define DEFSTRUCT_PDO_MAPPING    0x0021
#define DEFSTRUCT_IDENTITY       0x0023
#define DEFSTRUCT_VENDOR_MOTOR   0x0040

#define CODE_GET_INDEX(a)        ((a >> 16) & 0xffff)
#define CODE_GET_SUBINDEX(a)     ((a >> 8)  & 0xff)
#define CODE_GET_FLAGS(a)        (a         & 0xff)
#define CODE_SET_ENTRY_INDEX(i,s,f)   (((i & 0xffff) << 16) | ((s & 0xff) << 8) | (f & 0xff))

#define CODE_SET_ENTRY_FLAG(i)    (i | 1)
#define CODE_CLR_ENTRY_FLAG(i)    (i & ~1)

#define OD_COMMUNICATION_AREA     0x1000
#define OD_MANUFACTURER_AREA      0x2000
#define OD_PROFILE_AREA           0x6000

#ifdef __XC__
#warning co_dictionary is not intended to be accessed directly from XC!
extern "C" {
#endif

typedef struct _cod_object COD_Object;
typedef struct _cod_entry COD_Entry;

struct _cod_object {
    uint16_t index;
    uint8_t type;                   /* object code: VAR, RECORD, ARRAY */
    uint16_t data_type;         /* index of data type, e.g. for VAR it is the basic data type, some
                                   complex objects have special types like DEVSTRUCT_IDENTITY */
    uint16_t access;                 /* Read/Write access flags */
    uint8_t max_subindex;         /* number of the largest subindex */
    const char **name;                 /* pointer to element in \c *entry_name ??? */
    COD_Entry *entry;            /* pointer to entry */
} __attribute__((packed));

struct _cod_entry {
    uint32_t index;             /* := | obj_index:16 | sub_index:8 | flags:8 */
    uint16_t data_type;         /* index of data type */
    size_t bitsize;
    uint16_t access;     /* object access flags, see also R/W flags and PDO Mapping above */
    uint32_t unit;
    const char **name;                 /* pointer to element in \see *entry_name */
    uint8_t *value;                /* pointer to start in \see *entry_values - type is determined by `data_type` */
    const uint8_t *default_value;        /* TODO pointer to start in default values field */
    const uint8_t *min_value;            /* TODO pointer to start in default values field */
    const uint8_t *max_value;            /* TODO pointer to start in default values field */
} __attribute__((packed));

typedef struct _object_index OD_Index;
struct _object_index {
    uint16_t index;
    COD_Object *object;
    COD_Entry *entry;            /* list of entries, even for deftype VAR, then only 1 element */
} __attribute__((packed));

typedef struct _object_entry_index COD_Entry_Index;
struct _object_entry_index {
    uint16_t index;
    uint8_t subindex;
    COD_Entry *entry;
} __attribute__((packed));

/* FIXME redundant with entry in OD_Object! */
struct _entry_index {
    uint16_t index;
    unsigned *start_entry;
};

/*
 * please see table 64 in ETG1000.6
 * Complex types like DEFSTRUCT needs further specification, but the rest is normal.
 * This is basically a static list.
 *
 * \see DEFTYPE_* above
 */
struct _base_type {
    uint16_t index;
    uint16_t type;
    char *name;
} __attribute__((packed));;

struct _bookmarks {
    uint16_t index;
    uint16_t entry_element;
} __attribute__((packed));

/*
 * Define variable to be accessible from the application
 */

extern uint8_t        entry_values[];
extern const uint8_t  entry_default_values[];
extern const uint8_t  entry_min_values[];
extern const uint8_t  entry_max_values[];
extern const char     *string[];
extern COD_Entry      object_entries[];
extern COD_Object     object_dictionary[];
extern struct _bookmarks bookmark[];

/* sizes */
extern const size_t         entry_values_length;
extern const size_t         entry_default_values_length;
extern const size_t         entry_min_values_length;
extern const size_t         entry_max_values_length;
extern const size_t         string_length;
extern const size_t         object_entries_length;
extern const size_t         object_dictionary_length;
extern const size_t         bookmark_length;

#ifdef __XC__
}
#endif

#endif /* OD_OBJECT_H */
