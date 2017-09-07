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


/*
 * Indexes of SDO elements
 */
#define DICT_GPIO                                     0x2210
#define SUB_GPIO_PIN_1                                     1
#define SUB_GPIO_PIN_2                                     2
#define SUB_GPIO_PIN_3                                     3
#define SUB_GPIO_PIN_4                                     4
#define DICT_FEEDBACK_SENSOR_PORTS                    0x2100
#define SUB_ENCODER_FUNCTION                               2
#define SUB_ENCODER_RESOLUTION                             3


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

/**
 * @brief Read a sdo object from a saved sdo list
 *
 * @param slave   slave number
 * @param *config pointer to list of configuration objects
 * @param max_objects number of objects to transfer
 * @param index of the object
 * @param subindex of the object
 *
 * @return value of the object, 0 or if not found
 */
int read_sdo_from_file(int slave_number, SdoParam_t **config, size_t max_objects, int index, int subindex);

/**
 * @brief Read a sdo object from a slave
 *
 * @param master  pointer to the master device
 * @param slave_number   slave number
 * @param index of the object
 * @param subindex of the object
 *
 * @return value of the object, -1 or if not found
 */
int read_sdo(Ethercat_Master_t *master, int slave_number, int index, int subindex);

#ifdef __cplusplus
}
#endif
 
#endif /* ECATCONFIG_H */
