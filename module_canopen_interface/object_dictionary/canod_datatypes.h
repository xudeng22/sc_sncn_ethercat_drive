
/**
 *
 * @file canod_datatypes.h
 *
 * @brief definition of datatypes used in the object dictionary
 *
 */

#ifndef CANOD_DATATYPES_H
#define CANOD_DATATYPES_H

/* SDO Information operation code */
#define CANOD_OP_

/* list of dictionary lists identifiers */
#define CANOD_GET_NUMBER_OF_OBJECTS   0x00
#define CANOD_ALL_OBJECTS             0x01
#define CANOD_RXPDO_MAPABLE           0x02
#define CANOD_TXPDO_MAPABLE           0x03
#define CANOD_DEVICE_REPLACEMENT      0x04
#define CANOD_STARTUP_PARAMETER       0x05

/* possible object types of dictionary objects */
#define CANOD_TYPE_DOMAIN     0x0
#define CANOD_TYPE_DEFTYPE    0x5
#define CANOD_TYPE_DEFSTRUCT  0x6
#define CANOD_TYPE_VAR        0x7
#define CANOD_TYPE_ARRAY      0x8
#define CANOD_TYPE_RECORD     0x9

/* value info values */
#define CANOD_VALUEINFO_UNIT      0x08
#define CANOD_VALUEINFO_DEFAULT   0x10
#define CANOD_VALUEINFO_MIN       0x20
#define CANOD_VALUEINFO_MAX       0x40

/* list types */
#define CANOD_LIST_ALL        0x01  ///< all objects
#define CANOD_LIST_RXPDO_MAP  0x02  ///< only objects which are mappable in a RxPDO
#define CANOD_LIST_TXPDO_MAP  0x03  ///< only objects which are mappable in a TxPDO
#define CANOD_LIST_REPLACE    0x04  ///< objects which has to stored for a device replacement ???
#define CANOD_LIST_STARTUP    0x05  ///< objects which can be used as startup parameter

/* Basic Data Type Area */
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



#endif /* CANOD_DATATYPES_H */
