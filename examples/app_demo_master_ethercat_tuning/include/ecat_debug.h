/*
 * ecat_debug.h
 *
 *  Created on: Nov 4, 2016
 *      Author: romuald
 */

#ifndef ECAT_DEBUG_H_
#define ECAT_DEBUG_H_


#include "ecat_master.h"

char *get_watchdog_mode_string(ec_watchdog_mode_t watchdog_mode);

char *get_direction_string(ec_direction_t dir);

const char *al_state_string(ec_al_state_t state);

#endif /* ECAT_DEBUG_H_ */
