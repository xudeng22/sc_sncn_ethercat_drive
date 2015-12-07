/*
 * commutation_config.xc
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */

#include <motorcontrol_config.h>

void init_motorcontrol_config(MotorcontrolConfig & motorcontrol_config)
{
    motorcontrol_config.motor_type = BLDC_MOTOR;
    motorcontrol_config.angle_variance = (60 * 4096) / (POLE_PAIRS * 2 * 360);

    if (POLE_PAIRS < 4) {
        motorcontrol_config.nominal_speed =  MAX_NOMINAL_SPEED * 4;
    } else if (POLE_PAIRS >= 4) {
        motorcontrol_config.nominal_speed =  MAX_NOMINAL_SPEED;
    }

    motorcontrol_config.commutation_loop_freq =  COMMUTATION_LOOP_FREQUENCY_KHZ;
    motorcontrol_config.hall_offset_clk =  COMMUTATION_OFFSET_CLK;
    motorcontrol_config.hall_offset_cclk = COMMUTATION_OFFSET_CCLK;
    motorcontrol_config.bldc_winding_type = WINDING_TYPE;
    motorcontrol_config.qei_forward_offset = 0;
    motorcontrol_config.qei_backward_offset = 0;
}
