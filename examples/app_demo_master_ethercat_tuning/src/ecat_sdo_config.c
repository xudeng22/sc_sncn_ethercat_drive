/*
 * ectconf.c
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#include "ecat_sdo_config.h"

#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
#include <stdio.h>
#include <readsdoconfig.h>

int write_sdo(Ethercat_Master_t *master, int slave_number, SdoParam_t *conf)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slave_number);
    if (slave == NULL) {
        fprintf(stderr, "Error could not get slave with id %d\n", slave_number);
        return -1;
    }

    int ret = ecw_slave_set_sdo_value(slave, conf->index, conf->subindex, conf->value);
    if (ret < 0) {
        fprintf(stderr, "Error, could not download object 0x%04x:%d\n",
                conf->index, conf->subindex);
        return -1;
    }

    return 0;
}


int write_sdo_config(Ethercat_Master_t *master, int slave, SdoParam_t *config, size_t max_objects)
{ 
    int ret = -1;

    /* FIXME add bytesize from SDO entry info into parameter list */
    for (size_t i = 0; i < max_objects; i++) {
        ret = write_sdo(master, slave, config+i);

        if (ret != 0)
            break;
    }

    return ret;
}
