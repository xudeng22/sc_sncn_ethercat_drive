/*
 * deviceconfig.h
 *
 * Read device configuration for the SDO transfers from CSV file.
 *
 * Frank Jeschke <fjeschke@synapticon.com>
 *
 * 2017 Synapticon GmbH
 */

#ifndef DEVICECONFIG_H
#define DEVICECONFIG_H

#include <stdint.h>

typedef struct {
    uint16_t index;
    uint8_t  subindex;
    uint8_t  *value;   /* FIXME hold value as array of bytes or stick to uint32_t? */
} SdoParam_t;

#endif /* DEVICECONFIG_H */
