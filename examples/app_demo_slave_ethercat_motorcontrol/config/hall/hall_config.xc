/*
 * hall_config.xc
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */
#include <hall_config.h>
#include <stdlib.h>

void init_hall_config(HallConfig &hall_config)

{
    hall_config.pole_pairs = POLE_PAIRS;
    hall_config.sensor_polarity = POLARITY;

    // Find absolute maximum position deviation from origin
    hall_config.max_ticks = (abs(MAX_POSITION_LIMIT) > abs(MIN_POSITION_LIMIT)) ? abs(MAX_POSITION_LIMIT) : abs(MIN_POSITION_LIMIT);
    hall_config.max_ticks_per_turn = POLE_PAIRS * HALL_POSITION_INTERPOLATED_RANGE;
    hall_config.max_ticks += hall_config.max_ticks_per_turn ;  // tolerance


    return;
}
