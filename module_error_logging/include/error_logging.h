/**
 * @file data_logging_service.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef DATA_LOGGING_SERVICE_H_
#define DATA_LOGGING_SERVICE_H_

#include <spiffs_service.h>
#include <motion_control_service.h>
#include <motor_control_structures.h>

#define MIN_LOG_INTERVAL 100
#define LOG_INTERVAL_MULT 100000

#define CONFIG_MAX_STRING_SIZE 128
#define CONFIG_MAX_ERROR_TITLES 32


enum eLogMsgType {
    LOG_MSG_COMMAND = 0
    ,LOG_MSG_ERROR
    ,LOG_MSG_DATA
};


typedef struct {

    int data_timer_interval;
    int error_timer_interval;
    int max_log_file_size;
    char err_codes_count;
    char log_file_name[2][SPIFFS_MAX_FILENAME_SIZE];
    char errors_titles[CONFIG_MAX_ERROR_TITLES][CONFIG_MAX_STRING_SIZE];

} DataLoggingConfig;


int error_logging_init(client SPIFFSInterface ?i_spiffs);

void error_msg_save(client SPIFFSInterface ?i_spiffs, ErrItem_t ErrItem);



#endif
