/**
 * @file cia402_wrapper.xc
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <refclk.h>
#include <cia402_wrapper.h>

void print_object_dictionary(client interface i_co_communication i_co)
{
	int sdo_value;
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0); //Commutation offset
    printstr("Commutation offset: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS); // Number of pole pairs
    printstr("Number of pole pairs: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_TORQUE_CONSTANT);  //motor torque constant
    printstr("motor torque constant: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE);
    printstr("Phase Resistance: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE);
    printstr("Phase Inductance: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_MOTOR_PHASES_INVERTED);
    printstr("Phases Inverted: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MAX_TORQUE, 0);
    printstr("MAX TORQUE: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MAX_CURRENT, 0);
    printstr("MAX Current: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MIN_POSITION_RANGE_LIMIT);//negative positioning limit
    printstr("negative positioning limit: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MAX_POSITION_RANGE_LIMIT);//positive positioning limit
    printstr("positive positioning limit: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POLARITY, 0);//motor driving polarity
    printstr("motor driving polarity: ");printintln(sdo_value);  // -1 in 2'complement 255
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);//MAX PROFILE VELOCITY
    printstr("MAX PROFILE VELOCITY: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);//PROFILE VELOCITY
    printstr("PROFILE VELOCITY: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);//MAX ACCELERATION
    printstr("MAX ACCELERATION: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_PROFILE_ACCELERATION, 0);//PROFILE ACCELERATION
    printstr("PROFILE ACCELERATION: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_PROFILE_DECELERATION, 0);//PROFILE DECELERATION
    printstr("PROFILE DECELERATION: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_QUICK_STOP_DECELERATION, 0);//QUICK STOP DECELERATION
    printstr("QUICK STOP DECELERATION: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 1);//Position P-Gain
    printstr("Position P-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 2);//Position I-Gain
    printstr("Position I-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_POSITION_CONTROLLER, 3);//Position D-Gain
    printstr("Position D-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 1);//Velocity P-Gain
    printstr("Velocity P-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 2);//Velocity I-Gain
    printstr("Velocity I-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_VELOCITY_CONTROLLER, 3);//Velocity D-Gain
    printstr("Velocity D-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 1);//Current P-Gain
    printstr("Current P-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 2);//Current I-Gain
    printstr("Current I-Gain: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_TORQUE_CONTROLLER, 3);//Current D-Gain
    printstr("Current D-Gain: ");printintln(sdo_value);

    {sdo_value, void, void} = i_co.od_get_object_value(DICT_FEEDBACK_SENSOR_PORTS, SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_1);//Current D-Gain
    printstr("Feedback Sensor Port 1: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_FEEDBACK_SENSOR_PORTS, SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_2);//Current D-Gain
    printstr("Feedback Sensor Port 2: ");printintln(sdo_value);
    {sdo_value, void, void} = i_co.od_get_object_value(DICT_FEEDBACK_SENSOR_PORTS, SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_3);//Current D-Gain
    printstr("Feedback Sensor Port 3: ");printintln(sdo_value);

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
