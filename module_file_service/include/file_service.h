/**
 * @file file_service.h
 * @brief Simple flash file service to store configuration parameter
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <ethercat_service.h>
#include <co_interface.h>
#include <spiffs_service.h>

#include <stdint.h>
#include <stddef.h>

#define FOE_MAX_SIM_FILE_SIZE    2048
#define FOE_MAX_FILENAME_SIZE    128

enum eRequestType {
    REQUEST_IDLE = 0
    ,REQUEST_READ
    ,REQUEST_WRITE
};

struct _file_t {
    char store[FOE_MAX_SIM_FILE_SIZE];
    char filename[FOE_MAX_FILENAME_SIZE];
    size_t length;
    size_t current;
};


/**
 * @brief This Service stores configuration data from the object dictionary to flash files.
 *
 * @param i_spiffs  SPIFFS interface
 * @param i_flash_ecat_data   interface for writing ethercat data to flash
 * @param i_canopen           interface to the canopen interface service
 * @param i_foe  FoE interface
 *
 */
void file_service(
        client SPIFFSInterface ?i_spiffs,
        client interface i_co_communication i_canopen,
        client interface i_foe_communication i_foe);
