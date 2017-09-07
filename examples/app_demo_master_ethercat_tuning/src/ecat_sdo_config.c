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

int write_sdo(Ethercat_Slave_t *slave, SdoParam_t *conf)
{
    int ret = ecw_slave_set_sdo_value(slave, conf->index, conf->subindex, conf->value);
    if (ret < 0) {
        fprintf(stderr, "Error Slave %d, could not download object 0x%04x:%d, value: %d\n",
                ecw_slave_get_slaveid(slave), conf->index, conf->subindex, conf->value);
        return -1;
    }

    return 0;
}


int write_sdo_config(Ethercat_Master_t *master, int slave_number, SdoParam_t *config, size_t max_objects)
{ 
    int ret = -1;
    Ethercat_Slave_t *slave = ecw_slave_get(master, slave_number);
    if (slave == NULL) {
        fprintf(stderr, "Error could not get slave with id %d\n", slave_number);
        return -1;
    }

    /* FIXME add bytesize from SDO entry info into parameter list */
    for (size_t i = 0; i < max_objects; i++) {
        ret = write_sdo(slave, config+i);

        if (ret != 0)
            break;
    }

    return ret;
}

int read_sdo_from_file(int slave_number, SdoParam_t **config, size_t max_objects, int index, int subindex)
{
    for (int i=0 ; i<max_objects; i++) {
        if (config[slave_number][i].index == index && config[slave_number][i].subindex == subindex) {
            return config[slave_number][i].value;
        }
    }
    return 0;
}

int read_sdo(Ethercat_Master_t *master, int slave_number, int index, int subindex) {
    int sdo_value = 0;

    int ret = ecw_slave_get_sdo_value(ecw_slave_get(master, slave_number), index, subindex, &sdo_value);

    if (ret == 0) {
        return sdo_value;
    } else {
        fprintf(stderr, "Error Slave %d, could not read sdo object 0x%04x:%d, error code %d\n",
                slave_number, index, subindex, ret);
    }

    return -1;
}
