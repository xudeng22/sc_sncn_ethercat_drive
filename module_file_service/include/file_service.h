/**
 * @file file_service.h
 * @brief File service to read / store configuration parameters to flash via SPIFFS
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <flash_service.h>
#include <ethercat_service.h>
#include <co_interface.h>
#include <spiffs_service.h>
#include <config_parser.h>

#include <stdint.h>
#include <stddef.h>

/**
 * \brief OD definitions
 */
#ifndef CANOD_TYPE_VAR
#define CANOD_TYPE_VAR        0x7
#endif

#define MAX_CONFIG_SDO_ENTRIES   250

/**
 * \brief Max file name size for FoE service (we use FoE with SPIFFS, so should be the same as SPIFFS file name size)
 */
#define FOE_MAX_FILENAME_SIZE    SPIFFS_MAX_FILENAME_SIZE

/**
 * \brief Max size of one FoE packet
 */
#define MAX_FOE_DATA     (1024 - 6 - 6)

/**
 * \brief Size of buffer for FoE packets
 */
#define FOE_DATA_BUFFER_SIZE     1024

/**
 * \brief Name of config file to store / read device configuration
 */
#define CONFIG_FILE_NAME "config.csv"

/**
 * \brief Name of binary file to store / read torque offset
 */
#define TORQUE_OFFSET_FILE_NAME "cogging_torque.bin"

/**
 * \brief Name of binary file to store / read encoder non-linearity
 */
#define SENSOR_CALIBRATION_FILE_NAME "sensor_calibration.bin"

/**
 * \brief FoE service timeout
 */
#define FILE_SERVICE_DELAY_TIMEOUT 500000000

/**
 * \brief Delay for file service to not overload cpu
 */
#define FILE_SERVICE_INITIAL_DELAY 100000

typedef enum {
    TORQUE_OFFSET_FILE = 1,
    SENSOR_CALIBRATION_FILE = 2
}FileFunction;

/**
 * \brief Structure for current opened file (name, size, current position in file, status opened/not opened, SPIFFS file descriptor)
 */
struct _file_t {
    char filename[FOE_MAX_FILENAME_SIZE];
    size_t length;
    size_t current;
    char opened;
    short cfd;
};

typedef interface FileServiceInterface FileServiceInterface;

interface FileServiceInterface
{
    [[guarded]] int write_binary_array(int function, int array_in[]);

    [[guarded]] int read_binary_array(int function, int array_out[]);
};


/**
 * @brief This Service reads / stores configuration parameters to flash via SPIFFS
 *
 * @param i_spiffs    SPIFFS interface
 * @param i_canopen   interface to the canopen interface service
 * @param i_foe       FoE interface
 *
 */
void file_service(
        server FileServiceInterface i_file_service [2],
        client SPIFFSInterface ?i_spiffs,
        client interface i_co_communication i_canopen,
        client interface i_foe_communication ?i_foe);
