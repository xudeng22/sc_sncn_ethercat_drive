/**
 * \file co_dictionary.h
 * \brief Main implementation of the CANopen object dictionary
 */

#include <stdlib.h>
#include <stdint.h>

#ifndef OD_OBJECT_H
#define OD_OBJECT_H

/*
 * Definitions of bit fields for object access
 */

#define OBJECT_ACCESS_PO_RD     0x01
#define OBJECT_ACCESS_SO_RD     0x02
#define OBJECT_ACCESS_OP_RD     0x04
#define OBJECT_ACCESS_ALL_RD      (OBJECT_ACCESS_PO_RD | OBJECT_ACCESS_SO_RD | OBJECT_ACCESS_OP_RD)

#define OBJECT_ACCESS_PO_WR     0x08
#define OBJECT_ACCESS_SO_WR     0x10
#define OBJECT_ACCESS_OP_WR     0x20
#define OBJECT_ACCESS_ALL_WR      (OBJECT_ACCESS_PO_WR | OBJECT_ACCESS_SO_WR | OBJECT_ACCESS_OD_WR)

#define OBJECT_ACCESS_RXPDO_MAP   0x40
#define OBJECT_ACCESS_TXPDO_MAP   0x80

/*
 * Value info
 */

#define OBJECT_VALUEINFO_UNIT_TYPE      0x08
#define OBJECT_VALUEINFO_DEFAULT_VALUE  0x10
#define OBJECT_VALUEINFO_MIN_VALUE      0x20
#define OBJECT_VALUEINFO_MAX_VALUE      0x40

/*
 * list of dictionary lists identifiers
 */

#define OBJECT_LIST_ALL_LISTS               0x00
#define OBJECT_LIST_ALL_OBJECTS             0x01
#define OBJECT_LIST_RXPDO_MAPABLE           0x02
#define OBJECT_LIST_TXPDO_MAPABLE           0x03
#define OBJECT_LIST_DEVICE_REPLACEMENT      0x04
#define OBJECT_LIST_STARTUP_PARAMETER       0x05

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
 * value info values
 */

#define CANOD_VALUEINFO_UNIT      0x08
#define CANOD_VALUEINFO_DEFAULT   0x10
#define CANOD_VALUEINFO_MIN       0x20
#define CANOD_VALUEINFO_MAX       0x40


/*
 * Index of Basic Data Types
 */

#define DEFTYPE_BOOLEAN          0x0001
#define DEFTYPE_INTEGER8         0x0002
#define DEFTYPE_INTEGER16        0x0003
#define DEFTYPE_INTEGER32        0x0004
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

#ifdef __XC__
extern "C" {
#endif

typedef struct _cod_object COD_Object;
typedef struct _cod_entry COD_Entry;

struct _cod_object {
    uint16_t index;
    uint8_t type;                   /* VAR, RECORD, ARRAY */
    uint16_t access;                 /* Read/Write access flags */
    uint8_t entry_count;         /* Number of entries (including subindex 0) */
    char *name;                 /* pointer to element in \c *entry_name ??? */
    OD_Entry *entry;            /* pointer to entry */
} __attribute__((packed));

struct _cod_entry {
    uint8_t subindex;
    uint16_t data_type;         /* index of data type */
    size_t bitlength;
    uint16_t access;     /* object access flags, see also R/W flags and PDO Mapping above */
    uint8_t dirty;              /* 1: recently updated by EACT, 0: read by firmware client */
    char *name;                 /* pointer to element in \see *entry_name */
    void *value;                /* pointer to start in \see *entry_values - type is determined by `data_type` */
    void *default_value;        /* TODO pointer to start in default values field */
    void *min_value;            /* TODO pointer to start in default values field */
    void *max_value;            /* TODO pointer to start in default values field */
} __attribute__((packed));

typedef struct _object_index OD_Index;
struct _object_index {
    uint16_t index;
    OD_Object *object;
    OD_Entry *entry;            /* list of entries, even for deftype VAR, then only 1 element */
} __attribute__((packed));

typedef struct _object_entry_index OD_Entry_Index;

struct _object_entry_index {
    uint16_t index;
    uint8_t subindex;
    OD_Entry *entry;
} __attribute__((packed));

#ifdef __XC__
}
#endif

#endif /* OD_OBJECT_H */
