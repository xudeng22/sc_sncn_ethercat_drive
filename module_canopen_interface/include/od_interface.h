/*
 * od_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef OD_INTERFACE_H_
#define OD_INTERFACE_H_

#include <stdint.h>

/**
 * @brief Communication interface for OD communication
 */
interface i_od_communication {
    uint32_t get_object_value(uint16_t index, uint8_t subindex);
    void     set_object_value(uint16_t index, uint8_t subindex, uint32_t value);

    [[clears_notification]] void configuration_done(void);
    [[notification]] slave void configuration_ready(void);
};

#endif /* OD_INTERFACE_H_ */
