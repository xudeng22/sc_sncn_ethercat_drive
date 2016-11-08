/*
 * ecat_debug.c
 *
 *  Created on: Nov 4, 2016
 *      Author: romuald
 */


#include "ecat_debug.h"
#include <stdio.h>

//#ifdef ENABLE_ETHERCAT

/* debugging functions */
void get_master_information(ec_master_t *master)
{
    ec_master_info_t master_info;

    if (ecrt_master(master, &master_info) != 0) {
        fprintf(stderr, "[%s] Error retrieve master informations.\n", __func__);
        return;
    }

    printf("Master Info:\n");
    printf("  Slave Count ... : %d\n", master_info.slave_count);
    printf("  Link Up     ... : %s\n", (master_info.link_up == 0) ? "false" : "true");
    printf("  Scan Busy   ... : %s\n", (master_info.scan_busy == 0) ? "not scanning" : "scanning");
    printf("  ... end of info\n\n");
}

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

void get_slave_information(ec_master_t *master, int slaveid)
{
    ec_slave_info_t slave_info;
    ec_sync_info_t  syncman_info;

    /* FIXME assuming only one slave at position 0 */
    ecrt_master_get_slave(master, slaveid, &slave_info);

    printf("General slave information:\n");
    printf("  Number of SDOs: ....... %d\n", slave_info.sdo_count);
    printf("  AL State: ............. %s\n", al_state_string(slave_info.al_state));

    uint8_t sync_count = slave_info.sync_count;
    printf("  Sync Manager Count: ... %d\n", sync_count);

    for (uint8_t i = 0; i < sync_count; i++) {
        ecrt_master_get_sync_manager(master, 0, i, &syncman_info);

        printf("    Sync Manager:  %d\n", syncman_info.index);
        printf("    direction:     %s\n", get_direction_string(syncman_info.dir));
        printf("    number of PDO: %d\n", syncman_info.n_pdos);
        printf("    watchdog mode: %s\n", get_watchdog_mode_string(syncman_info.watchdog_mode));
        printf("\n");
    }
}
//#endif
