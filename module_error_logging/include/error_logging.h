/**
 * @file error_logging.h
 * @brief
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef ERR_LOGGING_H_

#include <spiffs_service.h>
#include <motion_control_service.h>
#include <motor_control_structures.h>

#define CONFIG_MAX_STRING_SIZE 128
#define CONFIG_MAX_ERROR_TITLES 32

typedef struct {

    int max_log_file_size;
    char log_file_name[2][SPIFFS_MAX_FILENAME_SIZE];

} ErrLoggingConfig;


int error_logging_init(client SPIFFSInterface ?i_spiffs);

int error_msg_save(client SPIFFSInterface ?i_spiffs, ErrItem_t ErrItem);



#endif
