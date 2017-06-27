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

#ifndef MSEC_STD
#define MSEC_STD 100000
#endif

#ifndef CANOD_TYPE_VAR
#define CANOD_TYPE_VAR        0x7
#endif

#define TIME_FOR_LOOP            (500 * MSEC_STD)
#define MAX_CONFIG_SDO_ENTRIES   250
#define CMD_DRIVE_INDEX          5


#define FOE_MAX_SIM_FILE_SIZE    11 * 1024
#define FOE_MAX_FILENAME_SIZE    128
/* This is basically the same as FOE_DATA_SIZE in foe.h */
#define MAX_FOE_DATA     (1024 - 6 - 6)

#define CONFIG_FILE_NAME "config.csv"

#define FILE_SERVICE_DELAY_TIMEOUT 500000000
#define FILE_SERVICE_INITIAL_DELAY 100000

enum eRequestType {
    REQUEST_IDLE = 0
    ,REQUEST_READ
    ,REQUEST_WRITE
};


struct _file_t {
    char filename[FOE_MAX_FILENAME_SIZE];
    size_t length;
    size_t current;
    char opened;
    short cfd;
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
        client interface i_foe_communication ?i_foe);
