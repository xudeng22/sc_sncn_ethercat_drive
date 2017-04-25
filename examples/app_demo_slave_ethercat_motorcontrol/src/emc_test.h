/*
 * emc_test.h
 *
 *  Created on: 05.04.2017
 *      Author: hstroetgen
 */


#ifndef EMC_TEST_H_
#define EMC_TEST_H_

#include <motor_control_interfaces.h>

void dio_test(client interface shared_memory_interface i_mem, clock clk, port ?gpio_port_0, port ?gpio_port_1, port ?gpio_port_2, port ?gpio_port_3);

#endif /* EMC_TEST_H_ */
