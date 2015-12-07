/*
 * qei_config.xc
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */

#include <qei_config.h>
#include <stdlib.h>

void init_qei_config(QEIConfig &qei_config)
{
    qei_config.index = QEI_SENSOR_TYPE;
    qei_config.max_ticks_per_turn = ENCODER_RESOLUTION;
    qei_config.real_counts = ENCODER_RESOLUTION;
    qei_config.sensor_polarity = QEI_SENSOR_POLARITY;
    qei_config.poles = POLE_PAIRS;

    // Find absolute maximum position deviation from origin
    qei_config.max_ticks = (abs(MAX_POSITION_LIMIT) > abs(MIN_POSITION_LIMIT)) ? abs(MAX_POSITION_LIMIT) : abs(MIN_POSITION_LIMIT);
    qei_config.max_ticks += qei_config.max_ticks_per_turn;  // tolerance

    return;
}
