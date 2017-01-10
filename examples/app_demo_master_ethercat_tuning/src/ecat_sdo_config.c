/*
 * ectconf.c
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#include "ecat_sdo_config.h"

#include <sncn_ethercat.h>
#include <sncn_slave.h>
#include <stdio.h>
#include <ecrt.h>

int write_sdo(SNCN_Master_t *master, int slave_number, struct _ecat_sdo_config *conf)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slave_number);
    if (slave == NULL) {
        fprintf(stderr, "Error could not get slave with id %d\n", slave_number);
        return -1;
    }

    int ret = sncn_slave_set_sdo_value(slave, conf->index, conf->subindex, conf->value);
    if (ret < 0) {
        fprintf(stderr, "Error, could not download object 0x%04x:%d\n",
                conf->index, conf->subindex);
        return -1;
    }

    return 0;
}


int write_sdo_config(SNCN_Master_t *master, int slave, struct _ecat_sdo_config *config, size_t max_objects)
{ 
    int ret = -1;

    for (size_t i = 0; i < max_objects; i++) {
        ret = write_sdo(master, slave, config+i);

        if (ret != 0)
            break;
    }

    return ret;
}
