/**
 * @file file_service.xc
 * @brief Simple flash command service to store object dictionary values to flash memory
 * @author Synapticon GmbH <support@synapticon.com>
 */

/*
 *  Flash read and write
 * Integration of commit 0a13cfd9aa4e98e8d46bb2de42d4648854d31e25 from sc_sncn_ethercatlib
 */

#include <file_service.h>
#include <xs1.h>
#include <print.h>
#include <string.h>
#include <stdio.h>

static int8_t foedata[FOE_DATA_BUFFER_SIZE];
char errormsg[] = "error";
struct _file_t file;
int file_item = 0;


static unsigned int set_configuration_to_dictionary(
        client interface i_co_communication i_canopen,
        ConfigParameter_t* Config)
{
    unsigned int i;

    for (i = 0; i < Config->param_count; i++) {
        i_canopen.od_set_object_value(Config->parameter[i][0].index, Config->parameter[i][0].subindex, Config->parameter[i][0].value);
    }
    return i;
}

static int exclude_object(uint16_t index)
{
    const uint16_t blacklist[] = {
            0x2000, 0x603f, /* special objects */
            0x6040, 0x6060, 0x6071, 0x607a, 0x60ff, 0x2300, 0x2a01, 0x2601, 0x2602, 0x2603, 0x2604, 0x2ffe, /* receive pdos */
            0x6041, 0x6061, 0x6064, 0x606c, 0x6077, 0x230a, 0x230b, 0x2401, 0x2402, 0x2403, 0x2404, 0x2a03, 0x2501, 0x2502, 0x2503, 0x2504, 0x2fff, 0x2ffd /* send pdos */
    };

    for (int i = 0; i < sizeof(blacklist)/sizeof(blacklist[0]); i++) {
        if (index == blacklist[i])
            return 1;
    }

    return 0;
}





static unsigned get_configuration_from_dictionary(
        client interface i_co_communication i_canopen,
        ConfigParameter_t* Config)
{
    uint16_t list_lengths[5];
    i_canopen.od_get_all_list_length(list_lengths);

    if (list_lengths[0] > MAX_CONFIG_SDO_ENTRIES) {
        printstrln("Warning OD to large, only get what fits.");
    }

    uint16_t all_od_objects[MAX_CONFIG_SDO_ENTRIES] = { 0 };
    i_canopen.od_get_list(all_od_objects, list_lengths[0], OD_LIST_ALL);

    struct _sdoinfo_entry_description od_entry;

    int count = 0;
    uint32_t value = 0;
    uint8_t error = 0;
    for (unsigned i = 0; i < list_lengths[0]; i++) {
        /* Skip objects below index 0x2000 */
        if (all_od_objects[i] < 0x2000) {
            continue;
        }

        /* filter out unnecessary objects (like PDOs and command objects or read only stuff) */
        if (exclude_object(all_od_objects[i])) {
            continue;
        }

        error = i_canopen.od_get_object_description(od_entry, all_od_objects[i], 0);

        /* object is no simple variable and subindex 0 holds the highest subindex then read all sub elements */
        if (od_entry.objectCode != CANOD_TYPE_VAR && od_entry.value > 0) {
            for (unsigned k = 1; k <= od_entry.value; k++) {
                {value, void, error } = i_canopen.od_get_object_value(all_od_objects[i], k);
                Config->parameter[count][0].index    = all_od_objects[i];
                Config->parameter[count][0].subindex = k;
                Config->parameter[count][0].value    = value;
                count++;
            }
        } else { /* simple variable object */
            {value, void, error } = i_canopen.od_get_object_value(all_od_objects[i], 0);
            Config->parameter[count][0].index    = od_entry.index;
            Config->parameter[count][0].subindex = 0;
            Config->parameter[count][0].value    = value;
            count++;
        }
    }

    Config->param_count = count;
    Config->node_count = 1;

    return count;
}

static int flash_write_od_config(
        client SPIFFSInterface i_spiffs,
        client interface i_co_communication i_canopen)
{
    int result = 0;
    ConfigParameter_t Config;

    get_configuration_from_dictionary(i_canopen, &Config);

    if ((result = write_config(CONFIG_FILE_NAME, &Config, i_spiffs, i_canopen)) >= 0)

    if (result == 0) {
        // put the flash configuration into the dictionary
        set_configuration_to_dictionary(i_canopen, &Config);
    }

    return result;
}

static int flash_read_od_config(
        client SPIFFSInterface i_spiffs,
        client interface i_co_communication i_canopen)
{
    int result = 0;
    ConfigParameter_t Config;

    if ((result = read_config(CONFIG_FILE_NAME, &Config, i_spiffs, i_canopen)) >= 0)

    if (result == 0) {
        // put the flash configuration into the dictionary
        set_configuration_to_dictionary(i_canopen, &Config);
    }
    return result;
}


int get_file_list(client interface i_foe_communication i_foe, client SPIFFSInterface i_spiffs)
{
    spiffs_stat file_list[SPIFFS_MAX_FILELIST_ITEMS];
    char list_text[MAX_FOE_DATA];
    char fsize_string[32];
    size_t wsize = 0;
    enum eFoeStat stat = FOE_STAT_DATA;

    if (file_item == 0)
        i_spiffs.ls_struct(file_list);

    memset(list_text, '\0', MAX_FOE_DATA);
    strcpy(list_text, "\n");
    while ((file_list[file_item].obj_id > 0)&&(strlen(list_text) < (MAX_FOE_DATA - SPIFFS_MAX_FILENAME_SIZE)))
    {
        sprintf(fsize_string, ", size: %u \n", file_list[file_item].size);
        strcat(list_text, file_list[file_item].name);
        strcat(list_text, fsize_string);
        file_item++;
    }

    {wsize, stat} = i_foe.write_data((int8_t *)list_text, strlen(list_text), FOE_ERROR_NONE);

    if (file_list[file_item].obj_id == 0)
    {
        file_item = 0;
        stat = FOE_STAT_EOF;
    }

    stat = FOE_STAT_DATA;
    return stat;
}


int process_fs_command(char cmd[], client interface i_foe_communication i_foe, client SPIFFSInterface i_spiffs)
{
    char msg_text[MAX_FOE_DATA];
    char par1[16], par2[SPIFFS_MAX_FILENAME_SIZE];
    char *eq_pos = null;
    int par_num, res, fd;
    size_t wsize = 0;
    enum eFoeStat stat = FOE_STAT_DATA;

    //space instead of "="
    eq_pos = strchr(cmd, '=');
    if (eq_pos) *eq_pos = ' ';

    par_num = sscanf(cmd, "fs-%s %s", par1, par2);

    if ((strcmp(par1, "getlist") == 0)||(file_item > 0))
    {
        stat = get_file_list(i_foe, i_spiffs);
        return stat;
    }
    else
    if (strcmp(par1, "remove") == 0)
    {
        if (par_num == 2)
        {
             fd =  i_spiffs.open_file(par2, strlen(par2), SPIFFS_RDWR);
             if (fd < 0)
                 strcpy(msg_text, "Error removing file\n");
             else
             {
                 res = i_spiffs.remove_file(fd);
                 if (res < 0)
                     strcpy(msg_text, "Error removing file\n");
                 else
                     strcpy(msg_text, "File successfully removed\n");
             }
        }
        else
            strcpy(msg_text, "Error: argument missing\n");
    }
    else
    if (strcmp(par1, "info") == 0)
    {
        unsigned int total, used;

        res = i_spiffs.fs_info(total, used);
        if (res < 0)
            strcpy(msg_text, "Error getting FS info\n");
        else
            sprintf(msg_text, "Memory usage:\n Total: %u b\n Used:  %u b\n", total, used);
    }
    else
        strcpy(msg_text, "Unknown FS command\n");

    {wsize, res} = i_foe.write_data((int8_t *)msg_text, strlen(msg_text), FOE_ERROR_NONE);
    stat = FOE_STAT_EOF;
    return stat;
}


static int received_filechunk_from_master(struct _file_t &file, client interface i_foe_communication i_foe, client SPIFFSInterface i_spiffs)
{
    int wait_for_reply = 0;
    size_t size = 0;
    int write_result = 0;
    unsigned packetnumber = 0;
    enum eFoeStat stat = FOE_STAT_DATA;
    enum eFoeError foe_error = FOE_ERROR_NONE;

    memset(foedata, '\0', MAX_FOE_DATA);
    {size, packetnumber, stat} = i_foe.read_data(foedata);

    printstr("Received packet: "); printint(packetnumber);
    printstr(" of size: "); printintln(size);

    if (stat == FOE_STAT_ERROR) {
        printstrln("Error Transmission - Aborting!");
        if (file.opened)
        {
            file.opened = 0;
            i_spiffs.close_file(file.cfd);
        }
    }

    if (!file.opened)
    {
        memset(file.filename, '\0', FOE_MAX_FILENAME_SIZE);
        i_foe.requested_filename(file.filename);
        file.cfd = i_spiffs.open_file(file.filename, strlen(file.filename), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
        if (file.cfd < 0)
        {
            printstrln("Error opening file");
            foe_error = FOE_ERROR_PROGRAM_ERROR;
            stat = FOE_STAT_ERROR;
        }
        else
        {
            printstr("File created: ");
            printintln(file.cfd);
            file.opened = 1;
        }
    }

    if (file.opened)
    {
        write_result = i_spiffs.write(file.cfd, (uint8_t *)foedata, size);
        if (write_result < 0)
        {
            if (write_result == SPIFFS_ERR_FULL)
                foe_error = FOE_ERROR_DISK_FULL;
            else
                foe_error = FOE_ERROR_PROGRAM_ERROR;

            i_spiffs.close_file(file.cfd);
            file.opened = 0;
            file.current = 0;
            file.length = 0;
            file.cfd = 0;
            stat = FOE_STAT_ERROR;
        }
        else
        {
            printstr("Written: ");
            printintln(write_result);

            if (stat == FOE_STAT_EOF) {
                printstrln("Read Transmission finished!");
                i_spiffs.close_file(file.cfd);
                file.opened = 0;
                file.current = 0;
                file.length = 0;
                file.cfd = 0;
            }
            foe_error = FOE_ERROR_NONE;
        }
    }

    i_foe.result(packetnumber, foe_error);
    if (foe_error != FOE_ERROR_NONE)
        i_foe.write_data((int8_t *)errormsg, strlen(errormsg), foe_error);

    wait_for_reply = ((stat == FOE_STAT_EOF)||(stat == FOE_STAT_ERROR)) ? 0 : 1;

    return wait_for_reply;
}


static int send_filechunk_to_master(struct _file_t &file, client interface i_foe_communication i_foe, client SPIFFSInterface i_spiffs)
{
    int wait_for_reply = 0;
    size_t size = 0;
    size_t wsize = 0;
    enum eFoeStat stat = FOE_STAT_DATA;
    enum eFoeError foe_error = FOE_ERROR_NONE;

    if (!file.opened)
    {
        memset(file.filename, '\0', FOE_MAX_FILENAME_SIZE);
        i_foe.requested_filename(file.filename);
        // if "fs-" prefix on begin of string
        if ((strstr(file.filename, "fs-") == file.filename))
        {
            stat = process_fs_command(file.filename, i_foe, i_spiffs);
        }
        else
        {
            file.cfd = i_spiffs.open_file(file.filename, strlen(file.filename), SPIFFS_RDONLY);
            if (file.cfd < 0)
            {
                if (file.cfd == SPIFFS_ERR_NOT_FOUND)
                {
                    printstrln("Error opening file not found");
                    foe_error = FOE_ERROR_NOT_FOUND;
                    stat = FOE_STAT_ERROR;
                }
                else
                {
                    printstr("Error opening file: code ");
                    printintln(file.cfd);
                    foe_error = FOE_ERROR_PROGRAM_ERROR;
                    stat = FOE_STAT_ERROR;
                }
            }
            else
             {
                 file.opened = 1;
                 printstr("File opened: ");
                 printintln(file.cfd);
                 file.length = i_spiffs.get_file_size(file.cfd);
             }
        }
    }
    if (file.opened)
    {
        size = file.length - file.current;
        size = (size > MAX_FOE_DATA ? MAX_FOE_DATA : size);

        if (size > 0)
        {
            memset(foedata, '\0', MAX_FOE_DATA);
            size = i_spiffs.read(file.cfd, (uint8_t *)foedata, size);
        }

        if ((size == SPIFFS_EOF)||(size == 0))
            stat = FOE_STAT_EOF;
        else
        if ((size < 0)&&(size != SPIFFS_EOF))
            stat = FOE_STAT_ERROR;
        else
        {
            {wsize, stat} = i_foe.write_data(foedata, size, FOE_ERROR_NONE);
            file.current += wsize;

            /* If writed data size less than readed (from file) data size , we are seeking back and trying to send lost data again */
            if (wsize < size) i_spiffs.seek(file.cfd, wsize , SPIFFS_SEEK_SET);

            printstr("Send packet of size: ");
            printintln(size);
        }

        if (stat == FOE_STAT_EOF) {
            printstrln("Write Transmission finished!");
            i_spiffs.close_file(file.cfd);
            file.opened = 0;
            file.current = 0;
            file.length = 0;
            file.cfd = 0;
        }

        if (stat == FOE_STAT_ERROR) {
            printstrln("Error Write Transmission!");
            i_spiffs.close_file(file.cfd);
            file.opened = 0;
            file.current = 0;
            file.length = 0;
            file.cfd = 0;
            foe_error = FOE_ERROR_PROGRAM_ERROR;
        }
    }

    if (foe_error != FOE_ERROR_NONE)
        i_foe.write_data((int8_t *)errormsg, strlen(errormsg), foe_error);

    wait_for_reply = ((stat == FOE_STAT_EOF)||(stat == FOE_STAT_ERROR)) ? 0 : 1;

    return wait_for_reply;
}


void file_service(
        server interface FileServiceInterface i_file_service [2],
        client SPIFFSInterface ?i_spiffs,
        client interface i_co_communication i_canopen,
        client interface i_foe_communication ?i_foe)
{
    timer t;
    unsigned time = 0, time2 = 0;

    file.length = 0;
    file.opened = 0;
    file.current = 0;
    file.cfd = 0;
    memset(file.filename, '\0', FOE_MAX_FILENAME_SIZE);

    enum eFoeNotificationType notify = FOE_NTYPE_UNDEF;

    int wait_for_reply = 0;

    if (isnull(i_spiffs)) {
            i_canopen.command_set_result(OD_COMMAND_STATE_ERROR);
            return;
        }

    select {
        case i_spiffs.service_ready():
        break;
    }

    while (1) {
        select
        {
            case i_file_service[int i].write_torque_array(int array_in[]) -> int status:
                    int file_id = i_spiffs.open_file(TORQUE_OFFSET_FILE_NAME, strlen(TORQUE_OFFSET_FILE_NAME), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
                    if (file_id < 0)
                    {
                        printstrln("Error opening file");
                        status = FS_TORQUE_ERR;
                        break;
                    }
                    else
                    {
                        printstr("File created: ");
                        printintln(file_id);
                        status = FS_TORQUE_OK;
                    }
                    unsigned char data [2] ={0} ;
                    for (int i = 0; i < 1024; i++)
                    {
                        data [0] = (array_in [i] & 0xFF00)>> 8;
                        data [1] = array_in [i] & 0x00FF;
                        int err_write = i_spiffs.write(file_id, data, 2);
                        if (err_write < 0)
                        {
                            printf("error writing torque array: %d\n", err_write);
                            status = FS_TORQUE_ERR;
                        }

                    }
                    i_spiffs.close_file(file_id);
                    break;

            case i_file_service[int i].read_torque_array(int array_out[]) -> int status:
                    int file_id = i_spiffs.open_file(TORQUE_OFFSET_FILE_NAME, strlen(TORQUE_OFFSET_FILE_NAME), (SPIFFS_RDONLY));
                    if (file_id < 0)
                    {
                        if (file_id == SPIFFS_ERR_NOT_FOUND)
                            status = SPIFFS_ERR_NOT_FOUND;
                        else
                            status = FS_TORQUE_ERR;
                        break;
                    }
                    else
                    {
                        status = FS_TORQUE_OK;
                    }

                    char buffer [2];
                    for (int i = 0; i < 1024; i++)
                    {
                        int err_read = i_spiffs.read(file_id, buffer, 2);
                        if (err_read < 0)
                        {
                            printf("error reading torque array: %d\n", err_read);
                            status = FS_TORQUE_ERR;
                        }

                        array_out[i] = (buffer[0] << 8) + buffer[1];
                        if(array_out[i] >= 0x7FFF)
                            array_out[i] -= 0x10000;
                    }

                    i_spiffs.close_file(file_id);
                    break;

            default:
                  break;
        }

        enum eSdoCommand command = i_canopen.command_ready();
        int command_result = 0;
        switch (command) {
            case OD_COMMAND_WRITE_CONFIG:
                command_result = flash_write_od_config(i_spiffs, i_canopen);
                i_canopen.command_set_result(command_result);
                command_result = 0;
                break;
            case OD_COMMAND_READ_CONFIG:
                command_result = flash_read_od_config(i_spiffs, i_canopen);
                i_canopen.command_set_result(command_result);
                command_result = 0;
                break;

            case OD_COMMAND_NONE:
               break;

            default:
              break;
        }

        select {

            case !isnull(i_foe) => i_foe.data_ready():
                notify = i_foe.get_notification_type();
                switch (notify) {
                case FOE_NTYPE_DATA:

                    wait_for_reply = received_filechunk_from_master(file, i_foe, i_spiffs);

                    t :> time;
                    break;

                case FOE_NTYPE_DATA_REQUEST:

                    wait_for_reply = send_filechunk_to_master(file, i_foe, i_spiffs);

                    t :> time;
                    break;

                default:
                    break;
                }
                break;

           case t when timerafter(time + FILE_SERVICE_DELAY_TIMEOUT) :> void :
                if (wait_for_reply) {
                    printstrln("[foe_testing()] Timeout catched");
                    i_spiffs.close_file(file.cfd);
                    file.length = 0;
                    file.opened = 0;
                    file.current = 0;
                    file.cfd = 0;
                    memset(file.filename, '\0', FOE_MAX_FILENAME_SIZE);

                    i_foe.write_data((int8_t *)errormsg, strlen(errormsg), FOE_ERROR_PROGRAM_ERROR);

                    wait_for_reply = 0;
                } else {
                    t :> time;
                }
                break;

            default:
                break;
        }

        t :> time2;
        t when timerafter(time2 + FILE_SERVICE_INITIAL_DELAY) :> void;
    }
}

