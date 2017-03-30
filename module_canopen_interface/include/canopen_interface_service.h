/**
 * @file canopen_service.h
 * @brief CANopen service between communication channels and CANopen drive.
 * @author Synapticon GmbH <support@synapticon.com>
*/


#ifndef CANOPEN_SERVICE_H_
#define CANOPEN_SERVICE_H_

#include "co_interface.h"
#include "canod_constants.h"
#include "canod_datatypes.h"


/**
 * @brief Provides a service, which managed the object dictionary communication and stores all necessary values.
 * @param i_od  Interface for setting and getting OD values.
 */
[[distributable]]
void canopen_interface_service(server interface i_co_communication i_co[n], unsigned n);

#endif /* CANOPEN_SERVICE_H_ */
