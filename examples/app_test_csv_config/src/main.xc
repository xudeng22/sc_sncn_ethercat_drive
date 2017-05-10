/*
 * SPIFFS_test_project.xc
 *
 *  Created on: 27 ����. 2016 �.
 *      Author: w
 */

#include <xs1.h>
#include <platform.h>
#include <flash_service.h>
#include <spiffs_service.h>
#include <command_processor.h>

#ifdef XCORE200
#include <quadflash.h>
#else
#include <flash.h>
#endif

#define MAX_SPIFFS_INTERFACES 2
#define MAX_FLASH_DATA_INTERFACES 2

//---------SPI flash definitions---------

// Ports for QuadSPI access on explorerKIT.
fl_QSPIPorts ports = {
PORT_SQI_CS,
PORT_SQI_SCLK,
PORT_SQI_SIO,
on tile[0]: XS1_CLKBLK_1
};



int main(void)
{
  FlashDataInterface i_data[MAX_FLASH_DATA_INTERFACES];
  FlashBootInterface i_boot;
  SPIFFSInterface i_spiffs[MAX_SPIFFS_INTERFACES];

  par
  {
    on tile[0]:
    {
        flash_service(ports, i_boot, i_data, 1);
    }

    on tile[1]:
    {
        spiffs_service(i_data[0], i_spiffs, 1);
    }

    on tile[1]:
    {
        spiffs_console(i_spiffs[0]);
    }
  }

  return 0;
}
