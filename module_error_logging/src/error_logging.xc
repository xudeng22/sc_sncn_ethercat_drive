
#include <data_logging_service.h>
#include <config_strings.h>
#include <xs1.h>
#include <print.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

short file_descriptor;
unsigned char curr_log_file_no = 0;
DataLoggingConfig Config;


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
        printstr("Config: ");
        printstr(title);
        printstrln(" not found");
        return -1;
    }

    value_str_length = end_pos - (begin_pos  + strlen(title));
    if (value_str_length >= CONFIG_MAX_STRING_SIZE)
    {
        printstrln("Config error: parameter is too large");
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
        printstr("Config: ");
        printstr(title);
        printstrln(" not found");
        return -1;
    }

    data_str_length = end_pos - (begin_pos  + strlen(title));
    if (data_str_length >= CONFIG_MAX_STRING_SIZE)
    {
         printstrln("Config error: parameter is too large");
         return -1;
    }

    memset(data_buffer, '\0', CONFIG_MAX_STRING_SIZE);
    memcpy(data_buffer, begin_pos + strlen(title), data_str_length);

    memset(begin_pos, ' ', (end_pos - begin_pos) + 1);
    memcpy(out_buffer, data_buffer, strlen(data_buffer));

    return 0;
}



int read_log_config(client SPIFFSInterface ?i_spiffs, DataLoggingConfig * config)
{
    char config_buffer[SPIFFS_MAX_DATA_BUFFER_SIZE];
    char err_title_buf[CONFIG_MAX_STRING_SIZE];
    int file_size;
    int res;

    file_descriptor = i_spiffs.open_file(LOG_CONFIG_FILE, strlen(LOG_CONFIG_FILE), SPIFFS_RDONLY);

    if (file_descriptor < 0)
    {
        if (file_descriptor == SPIFFS_ERR_NOT_FOUND)
        {
            printstrln("Log configuration file file not found ");
            return -1;
        }
        else
        {
            printstrln("Error opening log configuration file");
            return -1;
        }
    }
    else
    {
        printstr("File opened: ");
        printintln(file_descriptor);
    }

    file_size = i_spiffs.get_file_size(file_descriptor);
    if (file_size > SPIFFS_MAX_DATA_BUFFER_SIZE)
    {
        printstrln("Error opening log configuration file: file is too large");
        i_spiffs.close_file(file_descriptor);
        return -1;
    }

    memset(config_buffer, '\0', SPIFFS_MAX_DATA_BUFFER_SIZE);
    res = i_spiffs.read(file_descriptor, config_buffer, file_size);
    i_spiffs.close_file(file_descriptor);
    config_buffer[file_size] = CONFIG_END_OF_STRING_MARKER[0];

    config->data_timer_interval = get_config_value(CONFIG_DATA_INTERVAL_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer);

    if (config->data_timer_interval < MIN_LOG_INTERVAL)
    {
        printstrln("Config: Incorrect timer interval");
        return -1;
    }
    config->data_timer_interval *= LOG_INTERVAL_MULT;

    config->error_timer_interval = get_config_value(CONFIG_ERROR_LOG_INTERVAL_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer);

    config->max_log_file_size = get_config_value(CONFIG_LOG_FILE_MAX_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer);

    get_config_string(CONFIG_LOG_FILE_NAME1_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer, config->log_file_name[0]);

    get_config_string(CONFIG_LOG_FILE_NAME2_TITLE, CONFIG_END_OF_STRING_MARKER, config_buffer, config->log_file_name[1]);

    int i = 0;
    memset(err_title_buf, '\0', CONFIG_MAX_STRING_SIZE);
    sprintf(err_title_buf, CONFIG_LOG_ERR_TITLE, i + 1);
    //checking of all error titles
    while (get_config_string(err_title_buf, CONFIG_END_OF_STRING_MARKER, config_buffer, config->errors_titles[i]) == 0)
    {
        memset(err_title_buf, '\0', CONFIG_MAX_STRING_SIZE);
        i++;
        if (i >= CONFIG_MAX_ERROR_TITLES)
            break;

        sprintf(err_title_buf, CONFIG_LOG_ERR_TITLE, i + 1);
    }

    return 0;

}


int open_log_file(client SPIFFSInterface ?i_spiffs, char reset_existing_file)
{
    int res;
    char log_buf[768];
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
                printstr("LOG file not found, creating of new file: ");
                printstrln(Config.log_file_name[curr_log_file_no]);
                file_descriptor = i_spiffs.open_file(Config.log_file_name[curr_log_file_no], strlen(Config.log_file_name[curr_log_file_no]), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
                if (file_descriptor < 0)
                {
                    printstrln("Error opening file");
                    return -1;
                 }
                 else
                 {
                     printstr("File created: ");
                     printintln(file_descriptor);
                 }
           }
           else
           {
               printstrln("Error opening file");
               return -1;
           }
    }
    else
    {
        printstrln("LOG file opened");
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
        printstrln("Error getting file size");
        return -1;
    }

    if (res > Config.max_log_file_size)
    {
        if (curr_log_file_no == 0)
            curr_log_file_no = 1;
        else
          if (curr_log_file_no == 1)
              curr_log_file_no = 0;

        printstr("Switching LOG file to: ");
        printstrln(Config.log_file_name[curr_log_file_no]);

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
        //error in config file
        return -1;
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




void error_msg_save(client SPIFFSInterface ?i_spiffs, ErrItem_t ErrItem)
{
    int res;
    char log_buf[768];

    memset(log_buf, 0, sizeof(log_buf));
    sprintf(log_buf, " %d, %5d, %s", ucd.secondary_sensor_timestamp, ucd.secondary_sensor_error, Config.errors_titles[ucd.secondary_sensor_error]);
    res = i_spiffs.write(file_descriptor, log_buf, strlen(log_buf));
    i_spiffs.flush(file_descriptor);
}


/*void data_logging_service(
        interface DataLoggingInterface server ?i_logif[n_logif],
        client SPIFFSInterface ?i_spiffs,
        client interface MotionControlInterface i_motion_control,
        unsigned n_logif)
{
    timer timer_data_logging;
    timer timer_error_logging;
    unsigned time_data = 0;
    unsigned time_error = 0;
    unsigned start_time, end_time;

    if (isnull(i_spiffs)) {
            // error spiffs
            return;
        }

    if (isnull(i_motion_control)) {
              // error shared_memory
              return;
          }

    select {
        case i_spiffs.service_ready():
        break;
    }

    printstrln(">>   DATA LOGGING SERVICE STARTING...");

    if (data_logging_init(i_spiffs) != 0)
    {
       //service init
       return;
    }
    else
    {
        log_data_timer_active = 1;
        log_error_timer_active = 1;
    }

    while (1) {

        select {

            case !isnull(i_logif) => i_logif[int i].log_user_command(void) -> unsigned short res:
                    char command_buf[128];
                    UpstreamControlData ucd;
                    DownstreamControlData dcd;
                    {ucd, dcd} = i_motion_control.read_control_data();

                    memset(command_buf, 0, sizeof(command_buf));
                    sprintf(command_buf, "User command: Position: %d, Velocity %d, Torque: %d, Offset Torque: %d\n", dcd.position_cmd, dcd.velocity_cmd, dcd.torque_cmd, dcd.offset_torque);
                    res = i_spiffs.write(file_descriptor, command_buf, strlen(command_buf));
                    i_spiffs.flush(file_descriptor);

                    printintln(res);

                break;

            case !isnull(i_logif) => i_logif[int i].log_error(unsigned error_code) -> unsigned short res:

                break;

            case timer_data_logging when timerafter(time_data + Config.data_timer_interval) :> void :
                if (log_data_timer_active)
                {
                     if (check_log_file_size(i_spiffs, 1) != 0)
                     {
                         log_data_timer_active = 0;
                         log_error_timer_active = 0;
                     }
                     data_logging_save(i_spiffs, i_motion_control);
                }
                timer_data_logging :> time_data;

                break;

            case timer_error_logging when timerafter(time_error + Config.error_timer_interval) :> void :
                if (log_error_timer_active)
                {
                    if (check_log_file_size(i_spiffs, 1) != 0)
                    {
                         log_data_timer_active = 0;
                         log_error_timer_active = 0;
                    }

                }
                timer_error_logging :> time_error;

                break;

            default:
                break;


            }


    }
}*/

