/*
 * pdo_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef PDO_INTERFACE_H_
#define PDO_INTERFACE_H_

#include <pdo_handler.h>

/**
 * @brief Communication interface for PDO communication
 */
interface PDOCommunicationInterface {
    //void pdo_out(unsigned int &size, uint16_t data_out[]);
    //void pdo_in(unsigned int size, uint16_t data_in[]);

    void pdo_out_master(unsigned int size, pdo_size_t data_out[]);
    void pdo_in_master(unsigned int size, pdo_size_t data_in[]);
    pdo_values_t pdo_io(pdo_values_t pdo_in);
};

#endif /* PDO_INTERFACE_H_ */
