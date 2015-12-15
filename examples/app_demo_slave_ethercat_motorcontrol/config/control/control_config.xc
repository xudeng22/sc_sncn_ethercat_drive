/*
 * control_config.xc
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */
#include <refclk.h>
#include <control_config.h>
#include <user_config.h>


void init_position_control_config(ControlConfig &position_ctrl_params){

    position_ctrl_params.Kp_n = POSITION_Kp_NUMERATOR;
    position_ctrl_params.Kp_d = POSITION_Kp_DENOMINATOR;
    position_ctrl_params.Ki_n = POSITION_Ki_NUMERATOR;
    position_ctrl_params.Ki_d = POSITION_Ki_DENOMINATOR;
    position_ctrl_params.Kd_n = POSITION_Kd_NUMERATOR;
    position_ctrl_params.Kd_d = POSITION_Kd_DENOMINATOR;
    position_ctrl_params.Loop_time = 1 * MSEC_STD; // units - for CORE 2/1/0 only default

    position_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution

    if(position_ctrl_params.Ki_n != 0) // auto calculated using control_limit
    {
        position_ctrl_params.Integral_limit = position_ctrl_params.Control_limit * (position_ctrl_params.Ki_d/position_ctrl_params.Ki_n);
    } else {
        position_ctrl_params.Integral_limit = 0;
    }

    position_ctrl_params.sensor_used = SENSOR_USED; // units - for CORE 2/1/0 only default

    return;

}

void init_torque_control_config(ControlConfig &torque_ctrl_params){

     torque_ctrl_params.Kp_n = TORQUE_Kp_NUMERATOR;
     torque_ctrl_params.Kp_d = TORQUE_Kp_DENOMINATOR;
     torque_ctrl_params.Ki_n = TORQUE_Ki_NUMERATOR;
     torque_ctrl_params.Ki_d = TORQUE_Ki_DENOMINATOR;
     torque_ctrl_params.Kd_n = TORQUE_Kd_NUMERATOR;
     torque_ctrl_params.Kd_d = TORQUE_Kd_DENOMINATOR;
     torque_ctrl_params.Loop_time = 1 * MSEC_STD; // units - for CORE 2/1/0 only default

     torque_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution

     if(torque_ctrl_params.Ki_n != 0) {
         // auto calculated using control_limit
         torque_ctrl_params.Integral_limit = (torque_ctrl_params.Control_limit * torque_ctrl_params.Ki_d) / torque_ctrl_params.Ki_n;
     } else {
         torque_ctrl_params.Integral_limit = 0;
     }

    torque_ctrl_params.sensor_used = SENSOR_USED; // units - for CORE 2/1/0 only default

    return;

}

void init_velocity_control_config(ControlConfig &velocity_ctrl_params){

    velocity_ctrl_params.Kp_n = VELOCITY_Kp_NUMERATOR;
    velocity_ctrl_params.Kp_d = VELOCITY_Kp_DENOMINATOR;
    velocity_ctrl_params.Ki_n = VELOCITY_Ki_NUMERATOR;
    velocity_ctrl_params.Ki_d = VELOCITY_Ki_DENOMINATOR;
    velocity_ctrl_params.Kd_n = VELOCITY_Kd_NUMERATOR;
    velocity_ctrl_params.Kd_d = VELOCITY_Kd_DENOMINATOR;

    if (velocity_ctrl_params.Loop_time != MSEC_FAST)////FixMe: implement reference clock check
        velocity_ctrl_params.Loop_time = 1 * MSEC_STD; // units - core timer value //CORE 2/1/0 default

    velocity_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution
                                                                // CHANGE to BLDC_PWM_CONTROL_LIMIT
                                                                // FOR BDC!!!!!!!!!!!!!!!!*****

    if(velocity_ctrl_params.Ki_n != 0) {
        // auto calculated using control_limit
        velocity_ctrl_params.Integral_limit = velocity_ctrl_params.Control_limit * (velocity_ctrl_params.Ki_d/velocity_ctrl_params.Ki_n) ;
    } else {
        velocity_ctrl_params.Integral_limit = 0;
    }

    velocity_ctrl_params.sensor_used = SENSOR_USED;

    return;

}
