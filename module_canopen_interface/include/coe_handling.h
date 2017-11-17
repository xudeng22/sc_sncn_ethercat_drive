/**
 * \file coe_handling.h
 * \brief CoE specific definitions needed outside of this library
 *
 * Copyright 2017 Synapticon GmbH <support@synapticon.com>
 */

#ifndef COE_HANDLING_H
#define COE_HANDLING_H

#include <stdint.h>

/**
 * \brief Valueinfo flags to request specific values in SDO Infor Entry request
 */
#define VALUEINFO_UNIT           0x08
#define VALUEINFO_DEFAULT        0x10
#define VALUEINFO_MINIMUM        0x20
#define VALUEINFO_MAXIMUM        0x40


#define SDO_REQUEST_NO_ERROR                     0
#define SDO_REQUEST_ERROR                        1
#define SDO_REQUEST_ERROR_NOT_FOUND              2
#define SDO_REQUEST_ERROR_READ_ONLY              3
#define SDO_REQUEST_ERROR_WRITE_ONLY             4
#define SDO_REQUEST_ERROR_WRONG_TYPE             5
#define SDO_REQUEST_ERROR_INVALID_LIST           6
#define SDO_REQUEST_ERROR_INSUFFICIENT_BUFFER    7
#define SDO_REQUEST_ERROR_VALUEINFO_UNAVAILABLE  8


/**
 * \brief Exchange object for object and entry description
 */
struct _sdoinfo_entry_description {
    uint16_t index; ///< 16 bit int should be sufficient
    uint8_t subindex; ///< 16 bit int should be sufficient
    uint8_t objectDataType;
    uint8_t dataType;
    uint8_t objectCode;
    uint8_t bitLength;
    uint16_t objectAccess;
    uint32_t value; ///< real data type is defined by .dataType
    uint8_t name[50];
};

#endif /* COE_HANDLING_H */
