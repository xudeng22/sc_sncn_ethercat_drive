/**
 * @file ethercat_setup.h
 * @brief EtherCAT Node Setup: Please define your the node structure and configuration for each node.
 * @author Synapticon GmbH <support@synapticon.com>
 */

#ifndef ETHERCAT_SETUP_H_
#define ETHERCAT_SETUP_H_

/**
 * SOMANET Slave Configuration
 */
#define TOTAL_NUM_OF_SLAVES 1

#define SLAVE_ALIAS                    0
#define SLAVE_POSITION                 0
#define SLAVE_CONFIG_NUMBER            1
#define SLAVE_POSITION_IN_SLV_HANDLES  0

/**
 * Increase priority of the master process
 * !! YOU WILL NEED TO RUN THIS AS ROOT OTHERWISE THE PRIORITY WILL NOT CHANGE!!
 */
#define PRIORITY

#endif /* ETHERCAT_SETUP_H_ */
