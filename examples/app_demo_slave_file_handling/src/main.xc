/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C21-DX_G2.bsp>

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

#define MAX_SPIFFS_INTERFACES 2
#define MAX_FLASH_DATA_INTERFACES 1


/* Set to 1 to activate initial read of object dictionary from flash at startup */
#define STARTUP_READ_FLASH_OBJECTS  0

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

/* currentlly not really necessary maybe */

#ifdef CORE_C21_DX_G2 /* ports for the C21-DX-G2 */
    port c21watchdog = WD_PORT_TICK;
    port c21led = LED_PORT_4BIT_X_nG_nB_nR;
#endif


int main(void)
{
    interface i_foe_communication i_foe;
    interface EtherCATRebootInterface i_ecat_reboot;
    interface i_co_communication i_co[CO_IF_COUNT];
    interface i_pdo_handler_exchange i_pdo;
    interface FileServiceInterface i_file_service[2];

    FlashDataInterface i_data[MAX_FLASH_DATA_INTERFACES];
    FlashBootInterface i_boot;
    SPIFFSInterface i_spiffs[MAX_SPIFFS_INTERFACES];

    par
    {
        /* EtherCAT Communication Handler Loop */
        on tile[COM_TILE] :
        {
            par
            {
                ethercat_service(null,
                                   i_pdo,
                                   i_co,
                                   null,
                                   i_foe,
                                   ethercat_ports);

                reboot_service_ethercat(i_ecat_reboot);

                flash_service(p_qspi_flash, i_boot, i_data, 1);
                file_service(i_file_service, i_spiffs[0], i_co[3], i_foe);
            }
        }

       on tile[IFM_TILE] :
       {
           spiffs_service(i_data[0], i_spiffs, 1);
       }

    }

    return 0;
}
