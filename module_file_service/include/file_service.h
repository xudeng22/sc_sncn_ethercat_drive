/**
 * @file file_service.h
 * @brief File service to read / store configuration parameters to flash via SPIFFS
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <flash_service.h>
#include <motion_control_service.h>
//#include <ethercat_service.h>
#include <co_interface.h>
#include <spiffs_service.h>
#include <config_parser.h>
#include <error_logging.h>

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
 * \brief Prefix of firmware file name. Should be checked to avoid downloading of FW to file system
 */
#define FW_FILE_NAME_PREFIX "app_"

/**
 * \brief Suffix of firmware file name. Should be checked to avoid downloading of FW to file system
 */
#define FW_FILE_NAME_SUFFIX ".bin"

/**
 * \brief FoE service timeout
 */
#define FILE_SERVICE_DELAY_TIMEOUT 500000000

/**
 * \brief Delay for file service to not overload cpu
 */
#define FILE_SERVICE_INITIAL_DELAY 100000


/**
 * \brief Status of accessing to torque array file
 */
#define FS_TORQUE_OK   1
#define FS_TORQUE_ERR -1

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
    [[guarded]] int write_torque_array(int array_in[]);

    [[guarded]] int read_torque_array(int array_out[]);
};


#if 1
/*
* Each time @see data_ready() signal is raised the client needs to get the notification
* type by @see get_notification_type().
*/
enum eFoeNotificationType {
   FOE_NTYPE_UNDEF  = 0       ///< The notification could not be associated
   ,FOE_NTYPE_BOOT            ///< The system should reboot
   ,FOE_NTYPE_DATA            ///< Incomming data available @see read_data()
   ,FOE_NTYPE_DATA_REQUEST    ///< Master requested data @see write_data()
   ,FOE_NTYPE_RESTART         ///< Restart into application (only in bootloader)
};

/**
 * @brief Error codes from application.
 */
enum eFoeError {
    FOE_ERROR_NONE            = -1   ///< No error
    ,FOE_ERROR_UNDEFINED      = 0    ///< Undefined error
    ,FOE_ERROR_NOT_FOUND      = 1    ///< File was not found or is unavailable
    ,FOE_ERROR_ACCESS_DENIED  = 2    ///< File exists but could not be accessed
    ,FOE_ERROR_DISK_FULL      = 3    ///< Disk full, no space left on device
    ,FOE_ERROR_ALREADY_EXISTS = 6    ///< File already exists
    ,FOE_ERROR_BOOTSTRAP_ONLY = 8    ///< Transfer only allowed in BOOTSTRAP state
    ,FOE_ERROR_NOT_BOOTSTRAP  = 9    ///< Transfer not allowed in BOOTSTRAP state
    ,FOE_ERROR_NO_RIGHTS      = 10   ///< Insufficient rights to acccess file
    ,FOE_ERROR_PROGRAM_ERROR  = 11   ///< Internal program error
};

/**
 * @brief Status of FoE request command
 */
enum eFoeStat {
    FOE_STAT_DATA   = 0    ///< expecting more data
    ,FOE_STAT_ERROR = -1   ///< a error occured in FoE transfer
    ,FOE_STAT_EOF   = 1    ///< end of file reached (no error)
};

interface i_foe_communication {
    /* handle FoE upload / write request */
    /**
     * @brief Read data from FoE service
     *
     * These fetches the packet the master send to this device.
     *
     * @param[out] data  array of bytes received, maximum FOE_DATA_SIZE
     * @return  the size of the acutal received bytes (last packet is a incomplete read)
     *          the packet number received (this must be confirmed with @see result()
     *          state of the FoE transfer @see eFoeStat
     */
    [[guarded]] {size_t, uint32_t, enum eFoeStat} read_data(int8_t data[]);

    /**
     * @brief Result of the recently received packet
     *
     * @param packet_number  The packet_number of the recently processed packet.
     * @param error          For valid error values @see eFoeError
     */
    [[guarded]] void result(uint32_t packet_number, enum eFoeError error);

    /* handle FoE download / read request */
    /**
     * @brief Write data to the FoE handler to fullfill a FoE read request
     *
     * If foedata and byte_count is larger than FOE_DATA_SIZE only the first
     * FOE_DATA_SIZE bytes are transfered. The calling function needs to make
     * sure that the next chunk of data will start appropreatly.
     *
     * If write data returns with FOE_STAT_FOE it indicates the caller that the
     * Transfer is finished (aborted because of a error or fully transfered). A
     * proper error handling is not usefull on the slave side.
     */
    [[guarded]] {size_t, enum eFoeStat} write_data(int8_t foedata[], size_t byte_count, enum eFoeError foe_error);

    /**
     * @brief Get the requested filename to write to the master.
     *
     * @param[out]  foename filename of the request (max FOE_MAX_FILENAME_SIZE long)
     */
    [[guarded]] void requested_filename(uint8_t foename[]);

    /**
     * @brief Get notification type
     *
     * It is mandatory to call this command after every notification raised by @see data_read().
     *
     * @return Type of notification @see eFoeNotificationType
     */
    [[guarded]] [[clears_notification]] int get_notification_type(void);

    /**
     * @brief Notification call when a new FoE request occures.
     */
    [[notification]] slave void data_ready(void);
};
#endif


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
        client SPIFFSInterface i_spiffs,
        client interface i_co_communication i_canopen,
        client interface i_foe_communication ?i_foe,
        client interface MotionControlInterface ?i_motion_control);
