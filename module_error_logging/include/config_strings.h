/**
 * @file data_logging_service.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef CONFIG_STRINGS_H_
#define CONFIG_STRINGS_H_


#define LOG_FILE_NAME1 "logging1"
#define LOG_FILE_NAME2 "logging2"

#define LOG_CONFIG_FILE "log_config"

#define CONFIG_DATA_INTERVAL_TITLE       "LOG_DATA_INTERVAL_MS="
#define CONFIG_ERROR_LOG_INTERVAL_TITLE  "LOG_ERRORS_INTERVAL_MS="
#define CONFIG_LOG_FILE_MAX_TITLE        "MAX_LOG_FILE_SIZE_BYTES="
#define CONFIG_ERR_CODES_COUNT           "ERR_CODES_COUNT="
#define CONFIG_LOG_FILE_NAME1_TITLE      "LOG1_FILE_NAME="
#define CONFIG_LOG_FILE_NAME2_TITLE      "LOG2_FILE_NAME="
#define CONFIG_LOG_ERR_TITLE "ERR_%d="

#define CONFIG_END_OF_STRING_MARKER "\n"

#define CONFIG_MAX_DATA_TITLES 23
#define CONFIG_MAX_DATA_TITLES_SIZE 20

const char DataValuesTitles[CONFIG_MAX_DATA_TITLES][CONFIG_MAX_DATA_TITLES_SIZE] =
{
    "COMP_TORQ",
    "SET_TORQ",
    "V_DC",
    "I_B",
    "I_C",
    "ANGLE",
    "HALL",
    "QEI_INDEX",
    "AGLE_VEL",
    "POS",
    "SINGLET",
    "VEL",
    "SENS_TSTAMP",
    "SEC_POS",
    "SEC_SINGLET",
    "SEC_VEL",
    "SEC_SENS_TSTAMP",
    "TEMP",
    "AI_A1",
    "AI_A2",
    "AI_A3",
    "AI_A4"
};

#endif
