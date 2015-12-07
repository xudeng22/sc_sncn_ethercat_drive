/**
 * @file bldc_motor_init.xc
 * @brief Motor Control config initialization functions implementation
 * @author Synapticon GmbH
 */

#include <bldc_motor_config.h>
#include <drive_modes_config.h>
#include <drive_mode_helpers.h>

void init_csv_param(csv_par &csv_params)
{
	csv_params.max_motor_speed = MAX_NOMINAL_SPEED;
        csv_params.max_acceleration = MAX_ACCELERATION;
	if(POLARITY >= 0)
		csv_params.polarity = 1;
	else if(POLARITY < 0)
		csv_params.polarity = -1;
	return;
}

void init_csp_param(csp_par &csp_params)
{
	csp_params.base.max_motor_speed = MAX_NOMINAL_SPEED;
        csp_params.base.max_acceleration = MAX_ACCELERATION;
	if(POLARITY >= 0)
		csp_params.base.polarity = 1;
	else if(POLARITY < 0)
		csp_params.base.polarity = -1;
	csp_params.max_following_error = 0;
	csp_params.max_position_limit = MAX_POSITION_LIMIT;
	csp_params.min_position_limit = MIN_POSITION_LIMIT;
	return;
}

void init_pt_params(pt_par &pt_params)
{
	pt_params.profile_slope = PROFILE_TORQUE_SLOPE;
	pt_params.polarity = POLARITY;
}

void init_pp_params(pp_par &pp_params)
{
	pp_params.base.max_profile_velocity = MAX_PROFILE_VELOCITY;
	pp_params.profile_velocity	= PROFILE_VELOCITY;
	pp_params.base.profile_acceleration = PROFILE_ACCELERATION;
	pp_params.base.profile_deceleration = PROFILE_DECELERATION;
	pp_params.base.quick_stop_deceleration = QUICK_STOP_DECELERATION;
	pp_params.max_acceleration = MAX_ACCELERATION;
	pp_params.base.polarity = POLARITY;
	pp_params.software_position_limit_max = MAX_POSITION_LIMIT;
	pp_params.software_position_limit_min = MIN_POSITION_LIMIT;
	return;
}

void init_pv_params(pv_par &pv_params)
{
	pv_params.max_profile_velocity = MAX_PROFILE_VELOCITY;
	pv_params.profile_acceleration = PROFILE_ACCELERATION;
	pv_params.profile_deceleration = PROFILE_DECELERATION;
	pv_params.quick_stop_deceleration = QUICK_STOP_DECELERATION;
	pv_params.polarity = POLARITY;
	return;
}

void init_cst_param(cst_par &cst_params)
{
	cst_params.nominal_current = MAX_NOMINAL_CURRENT;
	cst_params.nominal_motor_speed = MAX_NOMINAL_SPEED;
	cst_params.polarity = POLARITY;
	cst_params.max_torque = MOTOR_TORQUE_CONSTANT * MAX_NOMINAL_CURRENT * IFM_RESOLUTION;
        cst_params.motor_torque_constant = MOTOR_TORQUE_CONSTANT;
}
/*
void init_sensor_filter_param(filter_par &sensor_filter_par) //optional for user to change
{
	sensor_filter_par.filter_length = VELOCITY_FILTER_SIZE;
	return;
}
*/
