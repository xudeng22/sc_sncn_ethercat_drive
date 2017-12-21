/**
 * @file cia402_wrapper.xc
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <refclk.h>
#include <cia402_wrapper.h>

{int, int, int, int, int} pv_sdo_update(client interface i_co_communication i_co)
{
	int max_profile_velocity;
	int profile_acceleration;
	int profile_deceleration;
	int quick_stop_deceleration;
	int polarity;

    {max_profile_velocity, void, void} = i_co.od_get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    {profile_acceleration, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);
    {profile_deceleration, void, void} = i_co.od_get_object_value(DICT_PROFILE_DECELERATION, 0);
    {quick_stop_deceleration, void, void} = i_co.od_get_object_value(DICT_QUICK_STOP_DECELERATION, 0);
    {polarity, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);
	return {max_profile_velocity, profile_acceleration, profile_deceleration, quick_stop_deceleration, polarity};
}


{int, int} pt_sdo_update(client interface i_co_communication i_co)
{
	int torque_slope;
	int polarity;

//    {torque_slope, void, void} = i_co.od_get_object_value(CIA402_TORQUE_SLOPE, 0);
    {polarity, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);
    return {torque_slope, polarity};
}


{int, int, int} cst_sdo_update(client interface i_co_communication i_co)
{
	int max_motor_speed;
	int polarity;
	int max_torque;

    {max_motor_speed, void, void} = i_co.od_get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    {polarity, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);
    {max_torque, void, void} = i_co.od_get_object_value(DICT_MAX_TORQUE, 0);

	return {max_motor_speed, polarity, max_torque};
}

{int, int, int} csv_sdo_update(client interface i_co_communication i_co)
{
	int max_motor_speed;
	int polarity;
	int max_acceleration;

    {max_motor_speed, void, void} = i_co.od_get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    {polarity, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);
    {max_acceleration, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);

	return {max_motor_speed, polarity, max_acceleration};
}


{int, int, int, int, int} csp_sdo_update(client interface i_co_communication i_co)
{
	int max_motor_speed;
	int polarity;
	int min;
	int max;
	int max_acc;

    {max_motor_speed, void, void} = i_co.od_get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    {polarity, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);
    {min, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, 1);
    {max, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, 2);
    {max_acc, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);

	return {max_motor_speed, polarity, min, max, max_acc};
}
