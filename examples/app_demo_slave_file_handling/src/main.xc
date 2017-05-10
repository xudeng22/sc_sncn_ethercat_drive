/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C22-rev-a.bsp>

/**
 * @file main.xc
 * @brief Test application for file serivce
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <canopen_interface_service.h>
#include <ethercat_service.h>
#include <file_service.h>
#include <reboot.h>
#include <pdo_handler.h>
#include <stdint.h>
#include <dictionary_symbols.h>
#include <flash_service.h>

#define OBJECT_PRINT              0  /* enable object print with 1 */
#define MAX_TIME_TO_WAIT_SDO      100000

/* Set to 1 to activate initial read of object dictionary from flash at startup */
#define STARTUP_READ_FLASH_OBJECTS  0

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

interface i_command {
    int  get_object_value(uint16_t index, uint8_t subindex, uint32_t &user_value);
    int  set_object_value(uint16_t index, uint8_t subindex, uint32_t value);
};

/* Read most recent values for object dictionary values from flash (if existing) */
static int initial_od_read(client interface i_co_communication i_co)
{
    timer t;
    unsigned time;

    //printstrln("[DEBUG] start initial update dictionary");
    i_co.od_set_object_value(DICT_COMMAND_OBJECT, 0, OD_COMMAND_READ_CONFIG);
    enum eSdoState command_state = OD_COMMAND_STATE_IDLE;

    while (command_state <= OD_COMMAND_STATE_PROCESSING) {
        t :> time;
        t when timerafter(time+100000) :> void;

        {command_state, void, void} = i_co.od_get_object_value(DICT_COMMAND_OBJECT, 0);
        /* TODO: error handling, if the object could not be loaded then something weired happend and the online
         * dictionary should not be overwritten.
         *
         * FIXME: What happens if nothing is stored in flash?
         */
    }

    //printstrln("[DEBUG] finished initial update dictionary");

    return 0;
}

/* example function to read object dictionary entries */
static void read_od_config(client interface i_co_communication i_co)
{
    /* Read and print the values of all known objects */
    uint32_t value    = 0;

    size_t object_list_size = sizeof(request_list) / sizeof(request_list[0]);

    for (size_t i = 0; i < object_list_size; i++) {
        {value, void, void} = i_co.od_get_object_value(request_list[i].index, request_list[i].subindex);

#if OBJECT_PRINT == 1
        printstr("Object 0x"); printhex(request_list[i].index);
        printstr(":");         printint(request_list[i].subindex);
        printstr(" = ");
        printintln(value);
#endif

    }

    return;
}


/* currentlly not really necessary maybe */
static void sdo_service(client interface i_co_communication i_co, server interface i_command i_cmd)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;
    int read_config = 0;

    initial_od_read(i_co);

    printstrln("Start SDO service");

    /*
     *  Wait for initial configuration.
     *
     *  It is assumed that the master successfully configured the object dictionary values
     *  before the drive is switched into EtherCAT OP mode. The signal `configuration_ready()`
     *  is send by the `ethercat_service()` on this event. In the user application this is the
     *  moment to read all necessary configuration parameters from the dictionary.
     */
    while (!i_co.configuration_get());
    //read_od_config(i_co);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");
    i_co.configuration_done(); /* clear notification */


    while (1) {
        read_config = i_co.configuration_get();
#if 0
        select {
        case i_cmd.get_object_value(uint16_t index, uint8_t subindex, uint32_t &value) -> { int err }:
            {value, void, void} = i_co.od_get_object_value(index, subindex);
            err = ECC_OK;
            break;

        case i_cmd.set_object_value(uint16_t index, uint8_t subindex, uint32_t value) -> { int err }:
            i_co.od_set_object_value(index, subindex, value);
            err = 0;
            break;

        default:
            break;
        }
#endif
        if (read_config) {
            read_od_config(i_co);
            printstrln("Re-Configuration finished, ECAT in OP mode - start cyclic operation");
            i_co.configuration_done(); /* clear notification */
            read_config = 0;
        }

        t when timerafter(time+delay) :> time;
    }
}


int main(void)
{
    /* EtherCat Communication channels */
    interface i_command i_cmd;

    interface i_foe_communication i_foe;
    interface EtherCATRebootInterface i_ecat_reboot;
    interface i_co_communication i_co[CO_IF_COUNT];
    interface i_pdo_handler_exchange i_pdo;

    /* flash interfaces */
    interface EtherCATFlashDataInterface i_data_ecat;
    interface EtherCATFlashDataInterface i_boot_ecat;

    par
    {
        /* EtherCAT Communication Handler Loop */
        on tile[COM_TILE] :
        {
            par
            {
                ethercat_service(i_ecat_reboot,
                                   i_pdo,
                                   i_co,
                                   null,
                                   i_foe,
                                   ethercat_ports);

                reboot_service_ethercat(i_ecat_reboot);
                flash_service_ethercat(p_spi_flash, null, i_data_ecat); /* FIXME no longer used replace with spiffs service */
            }
        }

        /* Test application handling pdos from EtherCat */
        on tile[APP_TILE] :
        {
            par
            {
                /* due to serious space problems on tile 0 because of the large object dictionary the command
                 * service is located here.
                 */
                file_service(i_data_ecat, i_co[3]);

                /* Start the SDO / Object Dictionary test service */
                sdo_service(i_co[2], i_cmd);
            }
        }
    }

    return 0;
}
