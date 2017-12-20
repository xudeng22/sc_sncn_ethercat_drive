.. _file_service_module:

=============================
Flash File Service Module
=============================

This module provides a service to store and read configuration parameters from the object dictionary (OD) into flash.
Also module provides a service to store and read torque array values, error logging, managing of SPIFFS using special commands via EtherCAT FoE.

Dependent modules:
- ``module_spiffs``
- ``module_config_parser``
- ``lib_ethercat``
- ``module_reboot``
- ``module_error_logging``
- ``module_motion_control (and depended modules)``

.. contents:: In this document
    :backlinks: none
    :depth: 3

The module provides access to files in the SPIFFS file system via Ethercat, downloading data into OD and uploading data from OD to the human-readable csv file using the config parser module. To read or write files use standard commands: ethercat "foe_read (<file name>)", ethercat "foe_write (<file name>)". To load and save data from OD,use a special object-command 0x2000. The file name for OD data is "config.csv". To upload data from OD to a file, use the command "download 0x2000 1". To download data from a file to OD, use the command "download 0x2000 2". Also, when the system starts and if there is a "config.csv" file in the file system, data will be loaded automatically. If there is no file, OD uses default values.

**The module provides basic operations with SPIFFS using special commands via EtherCAT FoE:**
 Put in console:

 $ethercat foe_read fs-[command]=[argument]

 Where commands:

 - getlist - Print out all files in file system;

 - info - Print out size of file system and used space;

 - remove - remove file from file system (argument - file name);

 - help - print out help.

**The module provides a server interface (i_file_service) to store and read torque array values.**
 - To store torque array to file system call interface i_file_service.write_torque_array(int array_in[]);

 - To read torque array from file system call interface i_file_service.read_torque_array(int array_out[]);

**Valid parameters for the service:**
 - server interface to store and read torque array values
 - interface for writing ethercat data to flash
 - interface to the canopen interface service
 - interface to communication send, receive and signal for FoE
 - interface to motion control service

The service starts after receiving the notification "spiffs_ready" from the SPIFFS service. This notification indicates that file service is initialized and mounted.

How to use
==========
1. Pass options to xCORE build tools from makefile ::
  
  XCC_FLAGS = -g -O3 -DCOM_ETHERCAT -lquadflash

2. Add the following modules to your app Makefile ::

  USED_MODULES = module_board-support module_canopen_interface lib_ethercat module_file_service module_flash_service  module_spiffs module_config_parser module_error_logging module_motion_control module_reboot

 3. Include the following headers in your app::
  
#include <canopen_interface_service.h>
#include <ethercat_service.h>
#include <flash_service.h>
#include <spiffs_service.h>
#include <file_service.h>
#include <pdo_handler.h>

 4. Inside your main function, instantiate the interfaces array for the Service-Clients communication.

 5. Optionally, instantiate the shared memory interface.

 6. At whichever other core, now you can perform calls to the Flash Service through the interfaces connected to it.

    .. code-block:: c
#include <canopen_interface_service.h>
#include <ethercat_service.h>
#include <flash_service.h>
#include <spiffs_service.h>
#include <file_service.h>
#include <pdo_handler.h>

#define MAX_SPIFFS_INTERFACES 1
#define MAX_FLASH_DATA_INTERFACES 1

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
        on tile[IF1_TILE] :
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
                file_service(i_file_service, i_spiffs[0], i_co[3], i_foe, null);
            }
        }

       on tile[IF2_TILE] :
       {
           spiffs_service(i_data[0], i_spiffs, 1);
       }

    }

    return 0;
}



API
===


.. doxygenfunction:: file_service
