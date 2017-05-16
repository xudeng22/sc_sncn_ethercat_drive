/*
 * SPIFFS_test_project.xc
 *
 *  Created on: 27 ����. 2016 �.
 *      Author: w
 */

#include <CORE_C22-rev-a.bsp>
#include <flash_service.h>
#include <spiffs_service.h>
#include <command_processor.h>

#define MAX_SPIFFS_INTERFACES 2
#define MAX_FLASH_DATA_INTERFACES 1



int main(void)
{
  FlashDataInterface i_data[MAX_FLASH_DATA_INTERFACES];
  FlashBootInterface i_boot;
  SPIFFSInterface i_spiffs[MAX_SPIFFS_INTERFACES];

  par
  {
    on tile[COM_TILE]:
    {
        flash_service(p_spi_flash, i_boot, i_data, 1);

    }

    on tile[APP_TILE]:
    {
        spiffs_service(i_data[0], i_spiffs, 1);
    }

    on tile[APP_TILE_2]:
    {
        spiffs_console(i_spiffs[0]);
    }
  }

  return 0;
}
