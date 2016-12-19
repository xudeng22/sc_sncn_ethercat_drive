/*
 * od_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef OD_INTERFACE_H_
#define OD_INTERFACE_H_

#include <stdint.h>
#include "canod.h"

/**
 * @brief Communication interface for OD communication
 */
interface ODCommunicationInterface {
    {uint32_t, uint32_t, uint8_t} get_object_value(uint16_t index_, uint8_t subindex);
    uint8_t set_object_value(uint16_t index_, uint8_t subindex, uint32_t value);
    {struct _sdoinfo_entry_description, uint8_t} get_entry_description(uint16_t index_, uint8_t subindex, uint32_t valueinfo);
    void get_all_list_length(uint32_t lists[]);
    int get_list(unsigned list[], unsigned size, unsigned listtype);
    int get_object_description(struct _sdoinfo_entry_description &obj, unsigned index_);

    void configuration_ready(void);
    void configuration_done(void);
    int configuration_get(void);

    //int get_list_length(unsigned list[], unsigned size, unsigned listtype);
};

#endif /* OD_INTERFACE_H_ */
