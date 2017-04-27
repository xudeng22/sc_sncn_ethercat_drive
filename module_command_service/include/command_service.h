/**
 * @file flash_service.h
 * @brief Simple flash command service to store configuration parameter
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <co_interface.h>
#include <stdint.h>

typedef struct {
    uint8_t index;
    unsigned char data[1024];
} DriveConfiguration;


/**
 * @brief This Service stores configuration data from the object dictionary to flash.
 *
 * @param i_flash_ecat_data   interface for writing ethercat data to flash
 * @param i_canopen           interface to the canopen interface service
 */
void command_service(
        client interface EtherCATFlashDataInterface ?i_flash_ecat_data,
        client interface i_co_communication i_canopen);
