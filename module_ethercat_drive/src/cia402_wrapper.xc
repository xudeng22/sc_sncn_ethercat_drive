/**
 * @file cia402_wrapper.xc
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <refclk.h>
#include <ethercat_service.h>
#include <cia402_wrapper.h>

#define CIA402WRAPPER_USE_OBSOLETE    0

void config_sdo_handler(client interface i_coe_communication i_coe)
{
	int sdo_value;
    sdo_value = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3); // Number of pole pairs
    printstr("Number of pole pairs: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 1); // Nominal Current
    printstr("Nominal Current: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 6);  //motor torque constant
	printstr("motor torque constant: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0); //Commutation offset CLKWISE
    printstr("Commutation offset CLKWISE: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(COMMUTATION_OFFSET_CCLKWISE, 0); //Commutation offset CCLKWISE
    printstr("Commutation offset CCLKWISE: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0); //Motor Winding type STAR = 1, DELTA = 2
    printstr("Motor Winding type: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);//Max Speed
    printstr("Max Speed: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);//Position Sensor Types HALL = 1, QEI_INDEX = 2, QEI_NO_INDEX = 3
    printstr("Position Sensor Types: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_GEAR_RATIO, 0);//Gear ratio
    printstr("Gear ratio: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);//QEI resolution
    printstr("QEI resolution: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(SNCN_SENSOR_POLARITY, 0);//QEI_POLARITY_NORMAL = 0, QEI_POLARITY_INVERTED = 1
    printstr("QEI POLARITY: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_MAX_TORQUE, 0);//MAX_TORQUE
	printstr("MAX TORQUE: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);//negative positioning limit
    printstr("negative positioning limit: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);//positive positioning limit
    printstr("positive positioning limit: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_POLARITY, 0);//motor driving polarity
    printstr("motor driving polarity: ");printintln(sdo_value);  // -1 in 2'complement 255
	sdo_value = i_coe.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);//MAX PROFILE VELOCITY
	printstr("MAX PROFILE VELOCITY: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_PROFILE_VELOCITY, 0);//PROFILE VELOCITY
	printstr("PROFILE VELOCITY: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);//MAX ACCELERATION
    printstr("MAX ACCELERATION: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_PROFILE_ACCELERATION, 0);//PROFILE ACCELERATION
	printstr("PROFILE ACCELERATION: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_PROFILE_DECELERATION, 0);//PROFILE DECELERATION
	printstr("PROFILE DECELERATION: ");printintln(sdo_value);
	sdo_value = i_coe.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0);//QUICK STOP DECELERATION
	printstr("QUICK STOP DECELERATION: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_TORQUE_SLOPE, 0);//TORQUE SLOPE
    printstr("TORQUE SLOPE: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_POSITION_GAIN, 1);//Position P-Gain
    printstr("Position P-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_POSITION_GAIN, 2);//Position I-Gain
    printstr("Position I-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_POSITION_GAIN, 3);//Position D-Gain
    printstr("Position D-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 1);//Velocity P-Gain
    printstr("Velocity P-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 2);//Velocity I-Gain
    printstr("Velocity I-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 3);//Velocity D-Gain
    printstr("Velocity D-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_CURRENT_GAIN, 1);//Current P-Gain
    printstr("Current P-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_CURRENT_GAIN, 2);//Current I-Gain
    printstr("Current I-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_CURRENT_GAIN, 3);//Current D-Gain
    printstr("Current D-Gain: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0);//LIMIT SWITCH TYPE: ACTIVE_HIGH = 1, ACTIVE_LOW = 2
    printstr("LIMIT SWITCH TYPE: ");printintln(sdo_value);
    sdo_value = i_coe.get_object_value(CIA402_HOMING_METHOD, 0);//HOMING METHOD: HOMING_NEGATIVE_SWITCH = 1, HOMING_POSITIVE_SWITCH = 2
    printstr("HOMING METHOD: ");printintln(sdo_value);
}

{int, int} homing_sdo_update(client interface i_coe_communication i_coe)
{
	int homing_method;
	int limit_switch_type;

	limit_switch_type = i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0);
	homing_method = i_coe.get_object_value(CIA402_HOMING_METHOD, 0);

	return {homing_method, limit_switch_type};
}

/* FIXME obsoleted by cm_sync_config_motor_commutation() or cm_sync_config_motor_control() */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int} commutation_sdo_update(client interface i_coe_communication i_coe)
{
	int hall_offset_clk;
	int hall_offset_cclk;
	int winding_type;

	hall_offset_clk = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);
	hall_offset_cclk = i_coe.get_object_value(COMMUTATION_OFFSET_CCLKWISE, 0);
	winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0);

	return {hall_offset_clk, hall_offset_cclk, winding_type};
}
#endif

/* FIXME obsoleted by cm_sync_config_profiler */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int, int, int, int, int, int, int} pp_sdo_update(client interface i_coe_communication i_coe)
{
	int max_profile_velocity;
	int profile_acceleration;
	int profile_deceleration;
	int quick_stop_deceleration;
	int profile_velocity;
	int min;
	int max;
	int polarity;
	int max_acc;

	max_profile_velocity = i_coe.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
	profile_velocity = i_coe.get_object_value(CIA402_PROFILE_VELOCITY, 0);
	profile_acceleration = i_coe.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
	profile_deceleration = i_coe.get_object_value(CIA402_PROFILE_DECELERATION, 0);
	quick_stop_deceleration = i_coe.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0);
	min = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
	max = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	max_acc = i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);

	return {max_profile_velocity, profile_velocity, profile_acceleration, profile_deceleration, quick_stop_deceleration, min, max, polarity, max_acc};
}
#endif

{int, int, int, int, int} pv_sdo_update(client interface i_coe_communication i_coe)
{
	int max_profile_velocity;
	int profile_acceleration;
	int profile_deceleration;
	int quick_stop_deceleration;
	int polarity;

	max_profile_velocity = i_coe.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
	profile_acceleration = i_coe.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
	profile_deceleration = i_coe.get_object_value(CIA402_PROFILE_DECELERATION, 0);
	quick_stop_deceleration = i_coe.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0);
	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	return {max_profile_velocity, profile_acceleration, profile_deceleration, quick_stop_deceleration, polarity};
}

{int, int} pt_sdo_update(client interface i_coe_communication i_coe)
{
	int torque_slope;
	int polarity;
	torque_slope = i_coe.get_object_value(CIA402_TORQUE_SLOPE, 0);
	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	return {torque_slope, polarity};
}

/* FIXME obsolete by cm_sync_config_position_control() */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int} position_sdo_update(client interface i_coe_communication i_coe)
{
	int Kp;
	int Ki;
	int Kd;

	Kp = i_coe.get_object_value(CIA402_POSITION_GAIN, 1);
	Ki = i_coe.get_object_value(CIA402_POSITION_GAIN, 2);
	Kd = i_coe.get_object_value(CIA402_POSITION_GAIN, 3);

	return {Kp, Ki, Kd};
}
#endif

/* FIXME obsolete by cm_sync_config_rotque_control() */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int} torque_sdo_update(client interface i_coe_communication i_coe)
{
	int Kp;
	int Ki;
	int Kd;

	Kp = i_coe.get_object_value(CIA402_CURRENT_GAIN, 1);
	Ki = i_coe.get_object_value(CIA402_CURRENT_GAIN, 2);
	Kd = i_coe.get_object_value(CIA402_CURRENT_GAIN, 3);

	return {Kp, Ki, Kd};
}
#endif

{int, int, int} cst_sdo_update(client interface i_coe_communication i_coe)
{
	//int  nominal_current;
	int max_motor_speed;
	int polarity;
	int max_torque;
	//int motor_torque_constant;

	//nominal_current = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 1);
	max_motor_speed = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	max_torque = i_coe.get_object_value(CIA402_MAX_TORQUE, 0);
	//motor_torque_constant = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 6);

	//return {nominal_current, max_motor_speed, polarity, max_torque, motor_torque_constant};
	return {max_motor_speed, polarity, max_torque};
}

{int, int, int} csv_sdo_update(client interface i_coe_communication i_coe)
{
	int max_motor_speed;
	//int nominal_current;
	int polarity;
	//int motor_torque_constant;
	int max_acceleration;

	//nominal_current = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 1);
	max_motor_speed = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
	//motor_torque_constant = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 6);

	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	max_acceleration = i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);
	//printintln(max_motor_speed);printintln(nominal_current);printintln(polarity);printintln(max_acceleration);printintln(motor_torque_constant);
	return {max_motor_speed, polarity, max_acceleration};
}

/* FIXME obsoleted by direct call */
#if CIA402WRAPPER_USE_OBSOLETE
int speed_sdo_update(client interface i_coe_communication i_coe)
{
	int max_motor_speed;
	max_motor_speed = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
	return max_motor_speed;
}
#endif

{int, int, int, int, int} csp_sdo_update(client interface i_coe_communication i_coe)
{
	int max_motor_speed;
	int polarity;
	//int nominal_current;
	int min;
	int max;
	int max_acc;

	max_motor_speed = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
	polarity = i_coe.get_object_value(CIA402_POLARITY, 0);
	//nominal_current = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 1);
	min = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
	max = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
	max_acc = i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);

	return {max_motor_speed, polarity, min, max, max_acc};
}

/* FIXME obsoleted by direct call */
#if CIA402WRAPPER_USE_OBSOLETE
int sensor_select_sdo(client interface i_coe_communication i_coe)
{
    int sensor_select;
    sensor_select = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
    if(sensor_select == 2 || sensor_select == 3)
        sensor_select = 2; //qei
    return sensor_select;
}
#endif

/* FIXME obsolete by cm_sync_config_velocity_control() */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int} velocity_sdo_update(client interface i_coe_communication i_coe)
{
	int Kp;
	int Ki;
	int Kd;

	Kp = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 1);
	Ki = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 2);
	Kd = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 3);

	return {Kp, Ki, Kd};
}
#endif

/* FIXME obsolete by cm_sync_config_hall() */
#if CIA402WRAPPER_USE_OBSOLETE
int hall_sdo_update(client interface i_coe_communication i_coe)
{
	int pole_pairs;
	//int min;
	//int max;

	//min = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
	//max = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
	pole_pairs = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);

	return pole_pairs; //{pole_pairs, max, min};
}
#endif



/* FIXME obsoleted by sm_sync_config_qei() */
#if CIA402WRAPPER_USE_OBSOLETE
{int, int, int} qei_sdo_update(client interface i_coe_communication i_coe)
{
	int ticks_resolution;
	int qei_type;
	//int min;
	//int max;
	int sensor_polarity;

	//min = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
	//max = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
	ticks_resolution = i_coe.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);
	qei_type = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
	sensor_polarity = i_coe.get_object_value(SNCN_SENSOR_POLARITY, 0);

	if(qei_type == QEI_WITH_INDEX)
		return {ticks_resolution, QEI_WITH_INDEX, sensor_polarity};
	else if(qei_type == QEI_WITH_NO_INDEX)
		return {ticks_resolution, QEI_WITH_NO_INDEX, sensor_polarity};
	else
		return {ticks_resolution, QEI_WITH_INDEX, sensor_polarity};	//default
}
#endif


void init_sdo(client interface i_coe_communication i_coe)
{
#if 0 /* this doesn't make sense! */
    unsigned int tmp;
    unsigned char status = 0;
    timer t;
    unsigned int time;
    i_coe <: CAN_GET_OBJECT;
    i_coe <: CAN_OBJ_ADR(0x60b0, 0);
    i_coe :> tmp;
    status= (unsigned char)(tmp&0xff);
    if (status == 0) {
        i_coe <: CAN_SET_OBJECT;
        i_coe <: CAN_OBJ_ADR(0x60b0, 0);
        status = 0xaf;
        i_coe <: (unsigned)status;
        i_coe :> tmp;
        if (tmp == status) {
            t :> time;
            t when timerafter(time + 500*100000) :> time;
        }
    }
#endif
}


/* FIXME obsoleted by cm_sync_config_hall() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_hall_config_ecat(HallConfig &hall_config, client interface i_coe_communication i_coe)
{
    //int min;
    //int max;

    //{hall_config.pole_pairs, max, min} = hall_sdo_update(i_coe);
    hall_config.pole_pairs = hall_sdo_update(i_coe);

    //min = abs(min);
    //max = abs(max);

    //hall_config.max_ticks = (max > min) ? max : min;

    //hall_config.max_ticks_per_turn = hall_config.pole_pairs * HALL_POSITION_INTERPOLATED_RANGE;
    //hall_config.max_ticks += hall_config.max_ticks_per_turn;
}
#endif

/* FIXME obsoleted by sm_sync_config_qei() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_qei_param_ecat(QEIConfig &qei_params, client interface i_coe_communication i_coe)
{
    //int min;
    //int max;

    { qei_params.ticks_resolution, qei_params.index_type, qei_params.sensor_polarity } = qei_sdo_update(i_coe);

    //min = abs(min);
    //max = abs(max);

    //qei_params.max_ticks = (max > min) ? max : min;
    //qei_params.max_ticks += qei_params.max_ticks_per_turn;  // tolerance
}
#endif

/* FIXME obsoleted by cm_sync_config_motor_commutation() or cm_sync_config_motor_control() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_commutation_param_ecat(MotorcontrolConfig &commutation_params, client interface i_coe_communication i_coe)
{
    {commutation_params.hall_offset[0], commutation_params.hall_offset[1],
            commutation_params.bldc_winding_type} = commutation_sdo_update(i_coe);
}
#endif

/* FIXME obsoleted by cm_sync_config_profiler */
#if CIA402WRAPPER_USE_OBSOLETE
void update_pp_param_ecat(ProfilerConfig &pp_params, client interface i_coe_communication i_coe)
{
    {pp_params.max_velocity, pp_params.velocity,
            pp_params.acceleration, pp_params.deceleration,
            pp_params.max_deceleration,
            pp_params.min_position,
            pp_params.max_position,
            pp_params.polarity,
            pp_params.max_acceleration} = pp_sdo_update(i_coe);
}
#endif

/* FIXME obsoleted by cm_sync_config_velocity_control() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_torque_ctrl_param_ecat(ControlConfig &torque_ctrl_params, client interface i_coe_communication i_coe)
{
    {torque_ctrl_params.Kp_n, torque_ctrl_params.Ki_n, torque_ctrl_params.Kd_n} = torque_sdo_update(i_coe);
   // torque_ctrl_params.Kp_d = 65536;                // 16 bit precision PID gains
   // torque_ctrl_params.Ki_d = 65536;
   // torque_ctrl_params.Kd_d = 65536;

    torque_ctrl_params.control_loop_period = 1000; //1ms

   // torque_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT;  // PWM resolution

 //   if(torque_ctrl_params.Ki_n != 0)                // auto calculated using control_limit
 //       torque_ctrl_params.Integral_limit = torque_ctrl_params.Control_limit * (torque_ctrl_params.Ki_d/torque_ctrl_params.Ki_n) ;
 //   else
 //       torque_ctrl_params.Integral_limit = 0;
    return;
}
#endif


/* FIXME obsolete by cm_sync_config_velocity_control() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_velocity_ctrl_param_ecat(ControlConfig &velocity_ctrl_params, client interface i_coe_communication i_coe)
{
    {velocity_ctrl_params.Kp_n, velocity_ctrl_params.Ki_n, velocity_ctrl_params.Kd_n} = velocity_sdo_update(i_coe);
    //velocity_ctrl_params.Kp_d = 65536;              // 16 bit precision PID gains
    //velocity_ctrl_params.Ki_d = 65536;
    //velocity_ctrl_params.Kd_d = 65536;

    velocity_ctrl_params.control_loop_period = 1000; //1ms

   // velocity_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution

   /* if(velocity_ctrl_params.Ki_n != 0)              // auto calculated using control_limit
        velocity_ctrl_params.Integral_limit = velocity_ctrl_params.Control_limit * (velocity_ctrl_params.Ki_d/velocity_ctrl_params.Ki_n) ;
    else
        velocity_ctrl_params.Integral_limit = 0;
   */
    return;
}
#endif

/* FIXME obsolete by cm_sync_config_position_control() */
#if CIA402WRAPPER_USE_OBSOLETE
void update_position_ctrl_param_ecat(ControlConfig &position_ctrl_params, client interface i_coe_communication i_coe)
{
    {position_ctrl_params.Kp_n, position_ctrl_params.Ki_n, position_ctrl_params.Kd_n} = position_sdo_update(i_coe);
    //position_ctrl_params.Kp_d = 65536;              // 16 bit precision PID gains
    //position_ctrl_params.Ki_d = 65536;
    //position_ctrl_params.Kd_d = 65536;

    position_ctrl_params.control_loop_period = 1000; //1ms

    //position_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution
/*
    if(position_ctrl_params.Ki_n != 0)              // auto calculated using control_limit
        position_ctrl_params.Integral_limit = position_ctrl_params.Control_limit * (position_ctrl_params.Ki_d/position_ctrl_params.Ki_n) ;
    else
        position_ctrl_params.Integral_limit = 0;
  */
    return;
}
#endif
