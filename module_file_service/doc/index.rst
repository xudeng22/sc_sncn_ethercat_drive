.. _file_service_module:

=============================
Flash File Service Module
=============================

This module provides a service to store configuration parameters from the object dictionary permanently into flash.

.. important:: This module is a (temporary) solution until the flash filesystem is integrated.

.. contents:: In this document
    :backlinks: none
    :depth: 3

.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/module_flash>`_ *obsolete*
  New is ``module_spiffs``

**The service takes as parameters:**
 - interface for writing ethercat data to flash
 - interface to the canopen interface service

The service starts after receiving notification from the SPIFFS service "spiffs_reday", This notification indicates, that file service initialized and mounted.
The service requires modules:

 
How to use
==========
  1. Pass options to xCORE build tools from makefile:
XCC_FLAGS = -g -O3 -DCOM_ETHERCAT -lflash

 2. Add the following modules to your app Makefile.

USED_MODULES = module_board-support module_canopen_interface lib_ethercat module_file_service module_flash_service module_spiffs module_config_parser

 3. Include the following headers in your app.
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
    interface i_co_communication i_co[CO_IF_COUNT];
    interface i_pdo_handler_exchange i_pdo;

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
                _ethercat_service(null,
                                 i_co[0],
                                 null,
                                 i_foe,
                                 ethercat_ports);

                flash_service(p_spi_flash, i_boot, i_data, 1);
            }
        }

       on tile[APP_TILE] :
       {
           canopen_interface_service(i_pdo, i_co, CO_IF_COUNT);
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



API
===


.. doxygenfunction:: file_service
