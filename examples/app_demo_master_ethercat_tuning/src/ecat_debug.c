/*
 * ecat_debug.c
 *
 *  Created on: Nov 4, 2016
 *      Author: romuald
 */


#include "ecat_debug.h"
#include <stdio.h>

//#ifdef ENABLE_ETHERCAT

char *get_watchdog_mode_string(ec_watchdog_mode_t watchdog_mode)
{
    switch (watchdog_mode) {
    case EC_WD_DEFAULT:
        return "default";
    case EC_WD_ENABLE:
        return "enable";
    case EC_WD_DISABLE:
        return "disable";
    default:
        return "Fucked up";
    }

    return "none";
}

char *get_direction_string(ec_direction_t dir)
{
    switch (dir) {
    case EC_DIR_INVALID:
        return "invalid";
        break;
    case EC_DIR_OUTPUT:
        return "output";
        break;
    case EC_DIR_INPUT:
        return "input";
        break;
    case EC_DIR_COUNT:
        return "count";
        break;
    default:
        return "fucked up";
        break;
    }

    return "nothing";
}

const char *al_state_string(ec_al_state_t state)
{
    switch (state) {
    case EC_AL_STATE_INIT:
        return "Init";
    case EC_AL_STATE_PREOP:
        return "Pre OP";
    case EC_AL_STATE_SAFEOP:
        return "Safe OP";
    case EC_AL_STATE_OP:
        return "OP";
    default:
        break;
    }

    return "Unknown";
}

//#endif
