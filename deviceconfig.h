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
#include <stdlib.h>

typedef struct {
  uint16_t index;
  uint8_t  subindex;
  uint32_t value;      /* FIXME hold values of arbitrary size! */
  size_t   bytecount;  /* for this value I need access to the object dictionary! FIXME may remove from here! */
} SdoParam_t;

typedef struct {
  size_t
  node_count;   ///< Number of nodes in the config parameters file, this value needs to be checked against the real number of nodes on the bus
  size_t
  param_count;  ///< Number of configuration parameters, aka non commented lines in the config file
  SdoParam_t
  **parameter;  ///< array of node_count x param_count of configuration parameters, for every node is a list of SdoParam_t objects.
} SdoConfigParameter_t;

int dc_read_file(const char *path, SdoConfigParameter_t *params);

void dc_release(void);

#endif /* DEVICECONFIG_H */
