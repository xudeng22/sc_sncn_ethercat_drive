/*
 * ectconf.c
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#include "ecat_sdo_config.h"

#include <stdio.h>
#include <ecrt.h>

int write_sdo(ec_master_t *master, int slave_number, struct _ecat_sdo_config *conf)
{
    uint32_t abortcode;

    uint8_t *value = (uint8_t *)&(conf->value);
    int ret = ecrt_master_sdo_download(master, slave_number, conf->index, conf->subindex, value, conf->bytesize, &abortcode);
//    int ret = 0;
//    printf("DEBUG: slave %d write 0x%04x:%d = %d (%d bytes)\n",
//            slave_number, conf->index, conf->subindex, conf->value, conf->bytesize);

    if (ret < 0) {
        /* TODO figure out what the abort codes are */
        fprintf(stderr, "Error, could not download object 0x%04x:%d cause: %d\n",
                conf->index, conf->subindex, abortcode);
        return -1;
    }

    return 0;
}


int write_sdo_config(ec_master_t *master, int slave, struct _ecat_sdo_config *config, size_t max_objects)
{ 
    //struct _ecat_config *config_objects;
    int ret = -1;

    for (size_t i = 0; i < max_objects; i++) {
        ret = write_sdo(master, slave, config+i);

        if (ret != 0)
            break;
    }

    return ret;
}
