/**
 * @file flash_service.h
 * @brief Simple flash command service to store configuration parameter
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <co_interface.h>

/**
 * @brief This Service stores configuration data from the object dictionary to flash.
 */
void command_service(client interface i_co_communication i_canopen);
