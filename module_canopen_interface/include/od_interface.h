/*
 * od_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef OD_INTERFACE_H_
#define OD_INTERFACE_H_

#include <stdint.h>
#include "canod_constants.h"

/**
 * @brief Communication interface for OD communication
 */
interface ODCommunicationInterface {
    uint32_t get_object_value(uint16_t index, uint8_t subindex);
    void     set_object_value(uint16_t index, uint8_t subindex, uint32_t value);

    void configuration_done(void);
    int configuration_ready(void);
};

#endif /* OD_INTERFACE_H_ */
