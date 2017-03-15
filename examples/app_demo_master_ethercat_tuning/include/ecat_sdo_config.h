/*
 * ectconf.h
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef ECATCONFIG_H
#define ECATCONFIG_H

#include <ethercat_wrapper.h>
#include <stdint.h>
#include <readsdoconfig.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief configuration object for SDO download
 */
struct _ecat_sdo_config {
    uint16_t index;
    uint8_t  subindex;
    uint32_t value;
    int bytesize;
};

/**
 * @brief Write specific SDO to slave device
 *
 * @param slave  pointer to the slave device
 * @param *config pointer to SDO configuration object
 * @return 0 on success, != 0 otherwise
 */
int write_sdo(Ethercat_Slave_t *slave, SdoParam_t *conf);

/**
 * @brief Write list of configuration SDO objects to slave device
 *
 * @param master  pointer to the master device
 * @param slave   slave number
 * @param *config pointer to list of configuration objects
 * @param max_objects number of objects to transfer
 * @return 0 on success, != 0 otherwise
 */
int write_sdo_config(Ethercat_Master_t *master, int slave_number, SdoParam_t *config, size_t max_objects);

#ifdef __cplusplus
}
#endif
 
#endif /* ECATCONFIG_H */
