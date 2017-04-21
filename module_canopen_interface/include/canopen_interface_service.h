/**
 * @file canopen_service.h
 * @brief CANopen service between communication channels and CANopen drive.
 * @author Synapticon GmbH <support@synapticon.com>
*/


#ifndef CANOPEN_SERVICE_H_
#define CANOPEN_SERVICE_H_

#include "co_interface.h"
#include "dictionary_symbols.h"
#include "canod_datatypes.h"
#include "pdo_handler.h"

/**
 * @brief Provides a service, which managed the object dictionary communication and stores all necessary values.
 * @param i_pdo_handler   application interface for PDO exchange
 * @param i_od  Interface for setting and getting OD values.
 * @param co_endpoint_count  number of clients for i_co interface
 */
[[distributable]]
void canopen_interface_service(
        server interface i_pdo_handler_exchange i_pdo_handler,
        server interface i_co_communication i_co[co_endpoint_count],
        unsigned co_endpoint_count);

#endif /* CANOPEN_SERVICE_H_ */
