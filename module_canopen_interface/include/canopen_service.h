/*
 * canopen_service.h
 *
 *  Created on: 14.12.2016
 *      Author: hstroetgen
 */


#ifndef CANOPEN_SERVICE_H_
#define CANOPEN_SERVICE_H_

#include "pdo_interface.h"
#include "od_interface.h"

void canopen_service(server interface ODCommunicationInterface i_od[3], server interface PDOCommunicationInterface ?i_pdo[3]);

#endif /* CANOPEN_SERVICE_H_ */
