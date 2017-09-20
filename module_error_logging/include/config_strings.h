/**
 * @file data_logging_service.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef CONFIG_STRINGS_H_
#define CONFIG_STRINGS_H_


#define DEFAULT_LOG_FILE_NAME1 "logging1.log"
#define DEFAULT_LOG_FILE_NAME2 "logging2.log"
#define DEFAILT_LOG_FILE_MAX   8000

#define LOG_CONFIG_FILE "log_config"

#define CONFIG_LOG_FILE_MAX_TITLE        "MAX_LOG_FILE_SIZE_BYTES="
#define CONFIG_LOG_FILE_NAME1_TITLE      "LOG1_FILE_NAME="
#define CONFIG_LOG_FILE_NAME2_TITLE      "LOG2_FILE_NAME="

#define CONFIG_END_OF_STRING_MARKER "\n"

#define MAX_ERR_TITLES 6
#define MAX_ERR_TITLES_SIZE 20

const char ErrTitles[MAX_ERR_TITLES][MAX_ERR_TITLES_SIZE] =
{
   "Error status      ",
   "Motion error      ",
   "Sensor error      ",
   "Sec. sensor error ",
   "Angle sensor error",
   "Watchdog error    "
};

#endif
