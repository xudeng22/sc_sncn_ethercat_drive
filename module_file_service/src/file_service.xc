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

    if ((result = write_config(CONFIG_FILE_NAME, &Config, i_spiffs)) >= 0)

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

    if ((result = read_config(CONFIG_FILE_NAME, &Config, i_spiffs)) >= 0)

    if (result == 0) {
        // put the flash configuration into the dictionary
        set_configuration_to_dictionary(i_canopen, &Config);
    }
    return result;
}




void file_service(
        server interface FileServiceInterface i_file_service [1],
        client SPIFFSInterface ?i_spiffs,
        client interface i_co_communication i_canopen)
{

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
            case i_file_service[int i].store_config() -> int status:

                    status = flash_write_od_config(i_spiffs, i_canopen);
                    i_canopen.command_set_result(status);
                    break;

            case i_file_service[int i].read_config() -> int status:

                    status = flash_read_od_config(i_spiffs, i_canopen);
                    i_canopen.command_set_result(status);
                    break;

            default:
                  break;
        }

    }
}

