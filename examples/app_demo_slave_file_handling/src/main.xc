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
#include <flash_service.h>
#include <spiffs_service.h>
#include <file_service.h>
#include <reboot.h>
#include <pdo_handler.h>
#include <stdint.h>
#include <dictionary_symbols.h>


#define OBJECT_PRINT              0  /* enable object print with 1 */
#define MAX_TIME_TO_WAIT_SDO      100000

#define MAX_SPIFFS_INTERFACES 2
#define MAX_FLASH_DATA_INTERFACES 1


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

/* currentlly not really necessary maybe */
static void sdo_service(client interface i_co_communication i_co)
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
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");
    i_co.configuration_done(); /* clear notification */


    while (1) {
        read_config = i_co.configuration_get();

        if (read_config) {
            printstrln("Re-Configuration signaled and finished, ECAT in OP mode - start cyclic operation");
            i_co.configuration_done(); /* clear notification */
            read_config = 0;
        }

        t when timerafter(time+delay) :> time;
    }
}


int main(void)
{
    interface i_foe_communication i_foe;
    interface EtherCATRebootInterface i_ecat_reboot;
    interface i_co_communication i_co[CO_IF_COUNT];
    interface i_pdo_handler_exchange i_pdo;

    FlashDataInterface i_data[MAX_FLASH_DATA_INTERFACES];
    FlashBootInterface i_boot;
    SPIFFSInterface i_spiffs[MAX_SPIFFS_INTERFACES];


    /* flash interfaces */
    //interface EtherCATFlashDataInterface i_data_ecat;

    par
    {
        /* EtherCAT Communication Handler Loop */
        on tile[COM_TILE] :
        {
            par
            {
#if 0
                ethercat_service(null,
                                   i_pdo,
                                   i_co,
                                   null,
                                   i_foe,
                                   ethercat_ports);
#endif
                _ethercat_service(null,
                                 i_co[0],
                                 null,
                                 i_foe,
                                 ethercat_ports);

                reboot_service_ethercat(i_ecat_reboot);

                flash_service(p_spi_flash, i_boot, i_data, 1);
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

                /* Start the SDO / Object Dictionary test service */
                sdo_service(i_co[2]);
                canopen_interface_service(i_pdo, i_co, CO_IF_COUNT);
            }
        }
       on tile[APP_TILE_2] :
       {
           spiffs_service(i_data[0], i_spiffs, 1);
       }

       on tile[IFM_TILE] :
       {
           file_service(i_spiffs[0], i_co[3]);
       }

    }

    return 0;
}
