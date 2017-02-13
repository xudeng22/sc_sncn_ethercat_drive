/*
 * ectconf.c
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#include "ecat_sdo_config.h"

#include <readsdoconfig.h>
#include <stdio.h>
#include <ecrt.h>

int write_sdo(ec_master_t *master, int slave_number, SdoParam_t *conf)
{
    uint32_t abortcode;
    ec_sdo_info_entry_t info_entry;

    if (ecrt_sdo_get_info_entry(master, slave_number, conf->index, conf->subindex, &info_entry) != 0) {
        fprintf(stderr, "Error could not access object %04x:%d.\n", conf->index, conf->subindex);
        return -1;
    }

    if (info_entry.bit_length % 8 != 0) {
        fprintf(stderr, "Error object %04x:%d is not a multiple of 8, can not use!\n", conf->index, conf->subindex);
        return -1;
    }

    conf->bytecount = info_entry.bit_length / 8;

    uint8_t *value = (uint8_t *)&(conf->value);
    int ret = ecrt_master_sdo_download(master, slave_number, conf->index, conf->subindex, value, conf->bytecount, &abortcode);
//    int ret = 0;
    printf("DEBUG: slave %d write 0x%04x:%d = %d (%lu bytes)\n",
            slave_number, conf->index, conf->subindex, conf->value, conf->bytecount);

    if (ret < 0) {
        /* TODO figure out what the abort codes are */
        fprintf(stderr, "Error, could not download object 0x%04x:%d cause: %d\n",
                conf->index, conf->subindex, abortcode);
        return -1;
    }

    return 0;
}


int write_sdo_config(ec_master_t *master, int slave, SdoParam_t *config, size_t max_objects)
{ 
    //struct _ecat_config *config_objects;
    int ret = -1;

    /* FIXME add bytesize from SDO entry info into parameter list */
    for (size_t i = 0; i < max_objects; i++) {
        ret = write_sdo(master, slave, config+i);

        if (ret != 0)
            break;
    }

    return ret;
}
