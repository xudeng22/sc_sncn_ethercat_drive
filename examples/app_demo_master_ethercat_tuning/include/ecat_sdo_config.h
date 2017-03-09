/*
 * ectconf.h
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef ECATCONFIG_H
#define ECATCONFIG_H

#include <sncn_ethercat.h>
#include <stdint.h>

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
 * @param master  pointer to the master device
 * @param slave   slave number
 * @param *config pointer to SDO configuration object
 * @return 0 on success, != 0 otherwise
 */
int write_sdo(SNCN_Master_t *master, int slave_number, struct _ecat_sdo_config *conf);

/**
 * @brief Write list of configuration SDO objects to slave device
 *
 * @param master  pointer to the master device
 * @param slave   slave number
 * @param *config pointer to list of configuration objects
 * @param max_objects number of objects to transfer
 * @return 0 on success, != 0 otherwise
 */
int write_sdo_config(SNCN_Master_t *master, int slave, struct _ecat_sdo_config *config, size_t max_objects);

#ifdef __cplusplus
}
#endif
 
#endif /* ECATCONFIG_H */
