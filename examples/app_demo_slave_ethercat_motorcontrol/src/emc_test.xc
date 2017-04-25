/*
 * emc_test.xc
 *
 *  Created on: 05.04.2017
 *      Author: hstroetgen
 */

#include <xs1.h>
#include <xscope.h>
#include <adc_service.h>
#include <print.h>
#include "emc_test.h"

void dio_test(client interface shared_memory_interface i_mem, clock clk, port ?gpio_port_0, port ?gpio_port_1, port ?gpio_port_2, port ?gpio_port_3)
{
    //gpio ports
    int gpio_ports_check = 1;
    unsigned int input = 0;
    if (isnull(gpio_port_0) || isnull(gpio_port_1) || isnull(gpio_port_2) || isnull(gpio_port_3))
        gpio_ports_check = 0;
    port? * movable gpio_0 = &gpio_port_0;
    port? * movable gpio_1 = &gpio_port_1;
    port? * movable gpio_2 = &gpio_port_2;
    port? * movable gpio_3 = &gpio_port_3;

    out port * movable gpio_1_out;
    in buffered port:8 * movable gpio_2_in;
    out port * movable gpio_3_out;
    out port * movable gpio_4_out;

    if (gpio_ports_check) {
        gpio_1_out = reconfigure_port(move(gpio_0), out port);
        gpio_2_in = reconfigure_port(move(gpio_1), in buffered port:8);
        gpio_3_out = reconfigure_port(move(gpio_2), out port);
        gpio_4_out = reconfigure_port(move(gpio_3), out port);
    }

    //configure_clock_rate(clk, 250, 12);
    configure_clock_rate(clk, 1, 1);
    configure_port_clock_output(*gpio_1_out, clk);
    configure_in_port(*gpio_2_in, clk);
    configure_out_port(*gpio_3_out, clk, 0);
    configure_out_port(*gpio_4_out, clk, 0);

    start_clock(clk);

    while(1)
    {
        *gpio_2_in :> input;
        *gpio_3_out <: 1;
        *gpio_3_out <: 0;
        *gpio_4_out <: 1;
        *gpio_4_out <: 0;


        i_mem.gpio_write_input_read_output(input);
        //xscope_int(INPUT_SIGNAL, input*1000);
    }
}
