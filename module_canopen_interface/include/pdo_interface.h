/*
 * pdo_interface.h
 *
 *  Created on: 05.12.2016
 *      Author: hstroetgen
 */


#ifndef PDO_INTERFACE_H_
#define PDO_INTERFACE_H_

/**
 * @brief Communication interface for PDO communication
 */
interface i_pdo_communication {
    void pdo_out(unsigned int size, uint16_t data_out[]);
    void pdo_in(unsigned int &size, uint16_t data_in[]);
};

#endif /* PDO_INTERFACE_H_ */
