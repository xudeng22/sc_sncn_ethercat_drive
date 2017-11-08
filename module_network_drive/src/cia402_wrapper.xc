/**
 * @file cia402_wrapper.xc
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <refclk.h>
#include <cia402_wrapper.h>
#include <config_manager.h>
#include <stdio.h>

void print_object_dictionary(client interface i_co_communication i_co)
{
    union sdo_value sdo_value;
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0); //Commutation offset CLKWISE
    printstr("Commutation offset: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, 1); // Number of pole pairs
    printstr("Number of pole pairs: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, 2);  //motor torque constant
    printstr("Motor torque constant: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, 3); // Phase Resistance
    printstr("Phase Resistance: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, 4); // Phase Inductance
    printstr("Phase Inductance: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROL_STRATEGY, 0);// Position control strategy
    printstr("Position control strategy: ");printintln(sdo_value.i);

    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MAX_TORQUE, 0); // MAX_TORQUE
    printstr("MAX TORQUE: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, 1);//negative positioning limit
    printstr("negative positioning limit: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, 2);//positive positioning limit
    printstr("positive positioning limit: ");printintln(sdo_value.i);

    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);//motor driving polarity
    printstr("motor driving polarity: ");printintln(sdo_value.i);  // -1 in 2'complement 255
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);//MAX PROFILE VELOCITY
    printstr("MAX PROFILE VELOCITY: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);//PROFILE ACCELERATION
    printstr("PROFILE ACCELERATION: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_PROFILE_DECELERATION, 0);//PROFILE DECELERATION
    printstr("PROFILE DECELERATION: ");printintln(sdo_value.i);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_QUICK_STOP_DECELERATION, 0);//QUICK STOP DECELERATION
    printstr("QUICK STOP DECELERATION: ");printintln(sdo_value.i);

    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 1);//Position P-Gain
    printstr("Position P-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 2);//Position I-Gain
    printstr("Position I-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 3);//Position D-Gain
    printstr("Position D-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 1);//Velocity P-Gain
    printstr("Velocity P-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 2);//Velocity I-Gain
    printstr("Velocity I-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 3);//Velocity D-Gain
    printstr("Velocity D-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 1);//Current P-Gain
    printstr("Current P-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 2);//Current I-Gain
    printstr("Current I-Gain: ");printf("%f\n", sdo_value.f);
    {sdo_value.i, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 3);//Current D-Gain
    printstr("Current D-Gain: ");printf("%f\n", sdo_value.f);

}


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
