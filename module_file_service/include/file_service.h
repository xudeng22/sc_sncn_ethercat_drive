/**
 * @file file_service.h
 * @brief Simple flash file service to store configuration parameter
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <co_interface.h>
#include <spiffs_service.h>

#include <stdint.h>

/**
 * @brief This Service stores configuration data from the object dictionary to flash files.
 *
 * @param i_flash_ecat_data   interface for writing ethercat data to flash
 * @param i_canopen           interface to the canopen interface service
 */
void file_service(
        client SPIFFSInterface i_spiffs,
        client interface i_co_communication i_canopen);
