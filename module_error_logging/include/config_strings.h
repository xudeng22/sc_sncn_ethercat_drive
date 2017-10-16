/**
 * @file data_logging_service.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef CONFIG_STRINGS_H_
#define CONFIG_STRINGS_H_

/**
 * @brief Default file name of first log file
 */
#define DEFAULT_LOG_FILE_NAME1 "logging1.log"

/**
 * @brief Default file name of second log file
 */
#define DEFAULT_LOG_FILE_NAME2 "logging2.log"

/**
 * @brief Default max size of log file in bytes
 */
#define DEFAILT_LOG_FILE_MAX   8000

/**
 * @brief Name of configuration file
 */
#define LOG_CONFIG_FILE "log_config"

/**
 * @brief Max string size in config file
 */
#define CONFIG_MAX_STRING_SIZE         128

/**
 * @brief Title in config file to define max size of log file in bytes
 */
#define CONFIG_LOG_FILE_MAX_TITLE      "MAX_LOG_FILE_SIZE_BYTES="

/**
 * @brief Title in config file to define file name of first log file
 */
#define CONFIG_LOG_FILE_NAME1_TITLE    "LOG1_FILE_NAME="

/**
 * @brief Title in config file to define file name of second log file
 */
#define CONFIG_LOG_FILE_NAME2_TITLE    "LOG2_FILE_NAME="

/**
 * @brief Marker of end of config string
 */
#define CONFIG_END_OF_STRING_MARKER    "\n"

/**
 * @brief Max count of error type titles
 */
#define MAX_ERR_TITLES 6

/**
 * @brief Max size of error type title
 */
#define MAX_ERR_TITLES_SIZE 20

/**
 * @brief Array contains titles of error types
 */
const char ErrTypeTitles[MAX_ERR_TITLES][MAX_ERR_TITLES_SIZE] =
{
   "Error status      ",
   "Motion error      ",
   "Sensor error      ",
   "Sec. sensor error ",
   "Angle sensor error",
   "Watchdog error    "
};

#endif
