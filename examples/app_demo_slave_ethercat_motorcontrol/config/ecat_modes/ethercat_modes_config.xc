/*
 * control_config.xc
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */
#include <ethercat_modes_config.h>
#include <user_config.h>


/*
MAX_POSITION
MIN_POSITION

MAX_VELOCITY

MAX_ACCELERATION
MAX_DECELERATION

MAX_CURRENT

TORQUE_CONSTANT*/

/*

void init_csv_config(ProfilerConfig &csv_config)
{
    csv_config.max_velocity = MAX_NOMINAL_SPEED;
        csv_config.max_acceleration = MAX_ACCELERATION;
    if(POLARITY >= 0)
        csv_config.polarity = 1;
    else if(POLARITY < 0)
        csv_config.polarity = -1;
    return;
}

void init_csp_config(ProfilerConfig &csp_config)
{
    csp_config.velocity_config.max_motor_speed = MAX_NOMINAL_SPEED;
        csp_config.velocity_config.max_acceleration = MAX_ACCELERATION;
    if(POLARITY >= 0)
        csp_config.velocity_config.polarity = 1;
    else if(POLARITY < 0)
        csp_config.velocity_config.polarity = -1;
    csp_config.max_following_error = 0;
    csp_config.max_position_limit = MAX_POSITION_LIMIT;
    csp_config.min_position_limit = MIN_POSITION_LIMIT;
    return;
}

void init_cst_config(ProfilerConfig &cst_config)
{
    cst_config.nominal_current = MAX_NOMINAL_CURRENT;
    cst_config.nominal_motor_speed = MAX_NOMINAL_SPEED;
    cst_config.polarity = POLARITY;
    cst_config.max_torque = MOTOR_TORQUE_CONSTANT * MAX_NOMINAL_CURRENT * IFM_RESOLUTION;
        cst_config.motor_torque_constant = MOTOR_TORQUE_CONSTANT;
}

void init_pt_config(ProfilerConfig &pt_config)
{
    pt_config.profile_slope = PROFILE_TORQUE_SLOPE;
    pt_config.polarity = POLARITY;
}

void init_pp_config(ProfilerConfig &pp_config)
{
    pp_config.velocity_config.max_profile_velocity = MAX_PROFILE_VELOCITY;
    pp_config.profile_velocity  = PROFILE_VELOCITY;
    pp_config.velocity_config.profile_acceleration = PROFILE_ACCELERATION;
    pp_config.velocity_config.profile_deceleration = PROFILE_DECELERATION;
    pp_config.velocity_config.quick_stop_deceleration = QUICK_STOP_DECELERATION;
    pp_config.max_acceleration = MAX_ACCELERATION;
    pp_config.velocity_config.polarity = POLARITY;
    pp_config.software_position_limit_max = MAX_POSITION_LIMIT;
    pp_config.software_position_limit_min = MIN_POSITION_LIMIT;
    return;
}

void init_pv_config(ProfilerConfig &pv_config)
{
    pv_config.max_profile_velocity = MAX_PROFILE_VELOCITY;
    pv_config.profile_acceleration = PROFILE_ACCELERATION;
    pv_config.profile_deceleration = PROFILE_DECELERATION;
    pv_config.quick_stop_deceleration = QUICK_STOP_DECELERATION;
    pv_config.polarity = POLARITY;
    return;
}
*/
