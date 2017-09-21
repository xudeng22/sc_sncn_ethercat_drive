
#include <error_logging.h>
#include <config_strings.h>
#include <xs1.h>
#include <print.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

short file_descriptor;
unsigned char curr_log_file_no = 0;
ErrLoggingConfig Config;


int get_config_value(char title[], char end_marker[], char buffer[])
{
    char * begin_pos;
    char * end_pos;
    char value_buffer[CONFIG_MAX_STRING_SIZE];
    int value_str_length;

    int res = 0;

    begin_pos = strstr(buffer, title);
    if (begin_pos)
        end_pos =  strstr(begin_pos,  end_marker);
    else
    {
        return -1;
    }

    value_str_length = end_pos - (begin_pos  + strlen(title));
    if (value_str_length >= CONFIG_MAX_STRING_SIZE)
    {
        return -1;
    }

    memset(value_buffer, '\0', CONFIG_MAX_STRING_SIZE);
    memcpy(value_buffer, begin_pos + strlen(title), value_str_length);
    res = atoi(value_buffer);

    memset(begin_pos, ' ', (end_pos - begin_pos) + 1);

    return res;
}


int get_config_string(char title[], char end_marker[], char buffer[], char out_buffer[])
{
    char * begin_pos;
    char * end_pos;
    char data_buffer[CONFIG_MAX_STRING_SIZE];
    int data_str_length;

    begin_pos = strstr(buffer, title);
    if (begin_pos)
        end_pos =  strstr(begin_pos,  end_marker);
    else
    {
        return -1;
    }

    data_str_length = end_pos - (begin_pos  + strlen(title));
    if (data_str_length >= CONFIG_MAX_STRING_SIZE)
    {
         return -1;
    }

    memset(data_buffer, '\0', CONFIG_MAX_STRING_SIZE);
    memcpy(data_buffer, begin_pos + strlen(title), data_str_length);

    memset(begin_pos, ' ', (end_pos - begin_pos) + 1);
    memcpy(out_buffer, data_buffer, strlen(data_buffer));

    return 0;
}



int read_log_config(client SPIFFSInterface ?i_spiffs, ErrLoggingConfig * config)
{
    char config_buffer[SPIFFS_MAX_DATA_BUFFER_SIZE];
    int file_size;
    int res;

    file_descriptor = i_spiffs.open_file(LOG_CONFIG_FILE, strlen(LOG_CONFIG_FILE), SPIFFS_RDONLY);

    if (file_descriptor < 0)
    {
        if (file_descriptor == SPIFFS_ERR_NOT_FOUND)
        {
            return -1;
        }
        else
        {
            return -1;
        }
    }
    else
    {
        printintln(file_descriptor);
    }

    file_size = i_spiffs.get_file_size(file_descriptor);
    if (file_size > SPIFFS_MAX_DATA_BUFFER_SIZE)
    {
        i_spiffs.close_file(file_descriptor);
        return -1;
    }

    memset(config_buffer, '\0', SPIFFS_MAX_DATA_BUFFER_SIZE);
    res = i_spiffs.read(file_descriptor, config_buffer, file_size);
    i_spiffs.close_file(file_descriptor);
    config_buffer[file_size] = CONFIG_END_OF_STRING_MARKER[0];

    config->max_log_file_size = get_config_value(CONFIG_LOG_FILE_MAX_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer);

    get_config_string(CONFIG_LOG_FILE_NAME1_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer, config->log_file_name[0]);

    get_config_string(CONFIG_LOG_FILE_NAME2_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer, config->log_file_name[1]);

    return 0;

}


int open_log_file(client SPIFFSInterface ?i_spiffs, char reset_existing_file)
{
    unsigned short flags = 0;

    if (reset_existing_file)
        //clear existing file
        flags = (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR);
    else
        //just continue to recording
        flags = SPIFFS_RDWR;

    //close previous file, if opened
    if (file_descriptor > 0) i_spiffs.close_file(file_descriptor);

    //Trying to open existing LOG file
    file_descriptor = i_spiffs.open_file(Config.log_file_name[curr_log_file_no], strlen(Config.log_file_name[curr_log_file_no]), flags);

    if (file_descriptor < 0)
    {
           if (file_descriptor == SPIFFS_ERR_NOT_FOUND)
           {
                file_descriptor = i_spiffs.open_file(Config.log_file_name[curr_log_file_no], strlen(Config.log_file_name[curr_log_file_no]), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
                if (file_descriptor < 0)
                {
                    return -1;
                 }
           }
           else
           {
               return -1;
           }
    }
    else
    {
        i_spiffs.seek(file_descriptor, 0, SPIFFS_SEEK_END);
    }

    return 0;
}



int check_log_file_size(client SPIFFSInterface ?i_spiffs, char reset_existing_file)
{
    int res;

    res = i_spiffs.get_file_size(file_descriptor);

    if (res < 0)
    {
        return -1;
    }

    if (res > Config.max_log_file_size)
    {
        if (curr_log_file_no == 0)
            curr_log_file_no = 1;
        else
          if (curr_log_file_no == 1)
              curr_log_file_no = 0;

        if (open_log_file(i_spiffs, reset_existing_file) != 0)
        {
            //error opening file
            return -1;
        }
    }

    return 0;
}

int error_logging_init(client SPIFFSInterface ?i_spiffs)
{

    if (read_log_config(i_spiffs, &Config) != 0)
    {
        //If config file failed or not found, use default config
        Config.max_log_file_size = DEFAILT_LOG_FILE_MAX;
        strcpy(Config.log_file_name[0], DEFAULT_LOG_FILE_NAME1);
        strcpy(Config.log_file_name[1], DEFAULT_LOG_FILE_NAME2);
    }

    if (open_log_file(i_spiffs, 0) != 0)
    {
        //error opening file
        return -1;
    }

    if (check_log_file_size(i_spiffs, 0) != 0)
    {
        //error checking of file
        return -1;
    }

    return 0;
}



int error_msg_save(client SPIFFSInterface ?i_spiffs, ErrItem_t ErrItem)
{
    int res;
    char log_buf[256];

    res = check_log_file_size(i_spiffs, 1);
    if (res != 0) return res;

    memset(log_buf, 0, sizeof(log_buf));

    sprintf(log_buf, "%9d %s 0x%x\n", ErrItem.timestamp, ErrTitles[ErrItem.err_type - 1], ErrItem.err_code);

    res = i_spiffs.write(file_descriptor, log_buf, strlen(log_buf));
    if (res < 0) return res;
    res = i_spiffs.flush(file_descriptor);
    return res;
}



