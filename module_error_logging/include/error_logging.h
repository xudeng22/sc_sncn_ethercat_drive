/**
 * @file error_logging.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef ERR_LOGGING_H_
#define ERR_LOGGING_H_

#include <spiffs_service.h>
#include <motion_control_service.h>
#include <motor_control_structures.h>

/**
 * @brief Structure definition for logging configuration.
 * Filling in by startup from log_config file or default values if file not exist
 */
typedef struct {
    int max_log_file_size;
    char log_file_name[2][SPIFFS_MAX_FILENAME_SIZE];

} ErrLoggingConfig;

/**
 * @brief Logging status
 */
typedef enum {
  LOG_OK = 0,
  LOG_ERROR = -1
} LogStat;

/**
 * @brief Initialization of error logging
 *
 * @param i_spiffs    SPIFFS interface
 *
 * @return LOG_OK - success, LOG_ERROR - error
 */
LogStat error_logging_init(client SPIFFSInterface i_spiffs);

/**
 * @brief Add new record to error log file
 *
 * @param i_spiffs    SPIFFS interface
 * @param ErrItem     Structure definition for one error item
 *
 * @return LOG_OK - success, LOG_ERROR - error
 */
LogStat error_msg_save(client SPIFFSInterface i_spiffs, ErrItem_t ErrItem);

/**
 * @brief Close log file and check FS for incorrect data
 *
 * @param i_spiffs    SPIFFS interface
 *
 * @return LOG_OK - success, LOG_ERROR - error
 */
LogStat error_logging_close(client SPIFFSInterface i_spiffs);

#endif
