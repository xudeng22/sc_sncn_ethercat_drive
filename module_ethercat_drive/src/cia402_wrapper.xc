/**
 * @file cia402_wrapper.xc
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <refclk.h>
#include <ethercat_service.h>
#include <cia402_wrapper.h>
#include <foefs.h>

#define MAX_PDO_SIZE    15

ctrl_proto_values_t init_ctrl_proto(void)
{
	ctrl_proto_values_t InOut;

	InOut.control_word    = 0x00;    		// shutdown
	InOut.operation_mode  = 0xff;  			// undefined

	InOut.target_torque   = 0x0;
	InOut.target_velocity = 0x0;
	InOut.target_position = 0x0;

	InOut.user1_in        = 0x0;
	InOut.user2_in        = 0x0;
	InOut.user3_in        = 0x0;
	InOut.user4_in        = 0x0;

	InOut.status_word     = 0x0000;  		// not set
	InOut.operation_mode_display = 0xff; 	// undefined

	InOut.torque_actual   = 0x0;
	InOut.velocity_actual = 0x0;
	InOut.position_actual = 0x0;

	InOut.user1_out       = 0x0;
	InOut.user2_out       = 0x0;
	InOut.user3_out       = 0x0;
	InOut.user4_out       = 0x0;

	return InOut;
}



void config_sdo_handler(chanend coe_out)
{
	int sdo_value;
    GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 3, sdo_value); // Number of pole pairs
    printstr("Number of pole pairs: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 1, sdo_value); // Nominal Current
    printstr("Nominal Current: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 6, sdo_value);  //motor torque constant
	printstr("motor torque constant: ");printintln(sdo_value);
    GET_SDO_DATA(COMMUTATION_OFFSET_CLKWISE, 0, sdo_value); //Commutation offset CLKWISE
    printstr("Commutation offset CLKWISE: ");printintln(sdo_value);
    GET_SDO_DATA(COMMUTATION_OFFSET_CCLKWISE, 0, sdo_value); //Commutation offset CCLKWISE
    printstr("Commutation offset CCLKWISE: ");printintln(sdo_value);
    GET_SDO_DATA(MOTOR_WINDING_TYPE, 0, sdo_value); //Motor Winding type STAR = 1, DELTA = 2
    printstr("Motor Winding type: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 4, sdo_value);//Max Speed
    printstr("Max Speed: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_SENSOR_SELECTION_CODE, 0, sdo_value);//Position Sensor Types HALL = 1, QEI_INDEX = 2, QEI_NO_INDEX = 3
    printstr("Position Sensor Types: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_GEAR_RATIO, 0, sdo_value);//Gear ratio
    printstr("Gear ratio: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_POSITION_ENC_RESOLUTION, 0, sdo_value);//QEI resolution
    printstr("QEI resolution: ");printintln(sdo_value);
    GET_SDO_DATA(SENSOR_POLARITY, 0, sdo_value);//QEI_POLARITY_NORMAL = 0, QEI_POLARITY_INVERTED = 1
    printstr("QEI POLARITY: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_MAX_TORQUE, 0, sdo_value);//MAX_TORQUE
	printstr("MAX TORQUE: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 1, sdo_value);//negative positioning limit
    printstr("negative positioning limit: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 2, sdo_value);//positive positioning limit
    printstr("positive positioning limit: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_POLARITY, 0, sdo_value);//motor driving polarity
    printstr("motor driving polarity: ");printintln(sdo_value);  // -1 in 2'complement 255
	GET_SDO_DATA(CIA402_MAX_PROFILE_VELOCITY, 0, sdo_value);//MAX PROFILE VELOCITY
	printstr("MAX PROFILE VELOCITY: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_PROFILE_VELOCITY, 0, sdo_value);//PROFILE VELOCITY
	printstr("PROFILE VELOCITY: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_MAX_ACCELERATION, 0, sdo_value);//MAX ACCELERATION
    printstr("MAX ACCELERATION: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_PROFILE_ACCELERATION, 0, sdo_value);//PROFILE ACCELERATION
	printstr("PROFILE ACCELERATION: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_PROFILE_DECELERATION, 0, sdo_value);//PROFILE DECELERATION
	printstr("PROFILE DECELERATION: ");printintln(sdo_value);
	GET_SDO_DATA(CIA402_QUICK_STOP_DECELERATION, 0, sdo_value);//QUICK STOP DECELERATION
	printstr("QUICK STOP DECELERATION: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_TORQUE_SLOPE, 0, sdo_value);//TORQUE SLOPE
    printstr("TORQUE SLOPE: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_POSITION_GAIN, 1, sdo_value);//Position P-Gain
    printstr("Position P-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_POSITION_GAIN, 2, sdo_value);//Position I-Gain
    printstr("Position I-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_POSITION_GAIN, 3, sdo_value);//Position D-Gain
    printstr("Position D-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_VELOCITY_GAIN, 1, sdo_value);//Velocity P-Gain
    printstr("Velocity P-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_VELOCITY_GAIN, 2, sdo_value);//Velocity I-Gain
    printstr("Velocity I-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_VELOCITY_GAIN, 3, sdo_value);//Velocity D-Gain
    printstr("Velocity D-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_CURRENT_GAIN, 1, sdo_value);//Current P-Gain
    printstr("Current P-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_CURRENT_GAIN, 2, sdo_value);//Current I-Gain
    printstr("Current I-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_CURRENT_GAIN, 3, sdo_value);//Current D-Gain
    printstr("Current D-Gain: ");printintln(sdo_value);
    GET_SDO_DATA(LIMIT_SWITCH_TYPE, 0, sdo_value);//LIMIT SWITCH TYPE: ACTIVE_HIGH = 1, ACTIVE_LOW = 2
    printstr("LIMIT SWITCH TYPE: ");printintln(sdo_value);
    GET_SDO_DATA(CIA402_HOMING_METHOD, 0, sdo_value);//HOMING METHOD: HOMING_NEGATIVE_SWITCH = 1, HOMING_POSITIVE_SWITCH = 2
    printstr("HOMING METHOD: ");printintln(sdo_value);
}

{int, int} homing_sdo_update(chanend coe_out)
{
	int homing_method;
	int limit_switch_type;

	GET_SDO_DATA(LIMIT_SWITCH_TYPE, 0, limit_switch_type);
	GET_SDO_DATA(CIA402_HOMING_METHOD, 0, homing_method);

	return {homing_method, limit_switch_type};
}

{int, int, int} commutation_sdo_update(chanend coe_out)
{
	int hall_offset_clk;
	int hall_offset_cclk;
	int winding_type;

	GET_SDO_DATA(COMMUTATION_OFFSET_CLKWISE, 0, hall_offset_clk);
	GET_SDO_DATA(COMMUTATION_OFFSET_CCLKWISE, 0, hall_offset_cclk);
	GET_SDO_DATA(MOTOR_WINDING_TYPE, 0, winding_type);

	return {hall_offset_clk, hall_offset_cclk, winding_type};
}

{int, int, int, int, int, int, int, int, int} pp_sdo_update(chanend coe_out)
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

	GET_SDO_DATA(CIA402_MAX_PROFILE_VELOCITY, 0, max_profile_velocity);
	GET_SDO_DATA(CIA402_PROFILE_VELOCITY, 0, profile_velocity);
	GET_SDO_DATA(CIA402_PROFILE_ACCELERATION, 0, profile_acceleration);
	GET_SDO_DATA(CIA402_PROFILE_DECELERATION, 0, profile_deceleration);
	GET_SDO_DATA(CIA402_QUICK_STOP_DECELERATION, 0, quick_stop_deceleration);
	GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 1, min);
	GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 2, max);
	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	GET_SDO_DATA(CIA402_MAX_ACCELERATION, 0, max_acc);

	return {max_profile_velocity, profile_velocity, profile_acceleration, profile_deceleration, quick_stop_deceleration, min, max, polarity, max_acc};
}

{int, int, int, int, int} pv_sdo_update(chanend coe_out)
{
	int max_profile_velocity;
	int profile_acceleration;
	int profile_deceleration;
	int quick_stop_deceleration;
	int polarity;

	GET_SDO_DATA(CIA402_MAX_PROFILE_VELOCITY, 0, max_profile_velocity);
	GET_SDO_DATA(CIA402_PROFILE_ACCELERATION, 0, profile_acceleration);
	GET_SDO_DATA(CIA402_PROFILE_DECELERATION, 0, profile_deceleration);
	GET_SDO_DATA(CIA402_QUICK_STOP_DECELERATION, 0, quick_stop_deceleration);
	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	return {max_profile_velocity, profile_acceleration, profile_deceleration, quick_stop_deceleration, polarity};
}

{int, int} pt_sdo_update(chanend coe_out)
{
	int torque_slope;
	int polarity;
	GET_SDO_DATA(CIA402_TORQUE_SLOPE, 0, torque_slope);
	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	return {torque_slope, polarity};
}

{int, int, int} position_sdo_update(chanend coe_out)
{
	int Kp;
	int Ki;
	int Kd;

	GET_SDO_DATA(CIA402_POSITION_GAIN, 1, Kp);
	GET_SDO_DATA(CIA402_POSITION_GAIN, 2, Ki);
	GET_SDO_DATA(CIA402_POSITION_GAIN, 3, Kd);

	return {Kp, Ki, Kd};
}

{int, int, int} torque_sdo_update(chanend coe_out)
{
	int Kp;
	int Ki;
	int Kd;

	GET_SDO_DATA(CIA402_CURRENT_GAIN, 1, Kp);
	GET_SDO_DATA(CIA402_CURRENT_GAIN, 2, Ki);
	GET_SDO_DATA(CIA402_CURRENT_GAIN, 3, Kd);

	return {Kp, Ki, Kd};
}

{int, int, int} cst_sdo_update(chanend coe_out)
{
	//int  nominal_current;
	int max_motor_speed;
	int polarity;
	int max_torque;
	//int motor_torque_constant;

	//GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 1, nominal_current);
	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 4, max_motor_speed);
	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	GET_SDO_DATA(CIA402_MAX_TORQUE, 0, max_torque);
	//GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 6, motor_torque_constant);

	//return {nominal_current, max_motor_speed, polarity, max_torque, motor_torque_constant};
	return {max_motor_speed, polarity, max_torque};
}

{int, int, int} csv_sdo_update(chanend coe_out)
{
	int max_motor_speed;
	//int nominal_current;
	int polarity;
	//int motor_torque_constant;
	int max_acceleration;

	//GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 1, nominal_current);
	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 4, max_motor_speed);
	//GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 6, motor_torque_constant);

	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	GET_SDO_DATA(CIA402_MAX_ACCELERATION, 0, max_acceleration);
	//printintln(max_motor_speed);printintln(nominal_current);printintln(polarity);printintln(max_acceleration);printintln(motor_torque_constant);
	return {max_motor_speed, polarity, max_acceleration};
}

int speed_sdo_update(chanend coe_out)
{
	int max_motor_speed;
	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 4, max_motor_speed);
	return max_motor_speed;
}

{int, int, int, int, int} csp_sdo_update(chanend coe_out)
{
	int max_motor_speed;
	int polarity;
	//int nominal_current;
	int min;
	int max;
	int max_acc;

	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 4, max_motor_speed);
	GET_SDO_DATA(CIA402_POLARITY, 0, polarity);
	//GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 1, nominal_current);
	GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 1, min);
	GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 2, max);
	GET_SDO_DATA(CIA402_MAX_ACCELERATION, 0, max_acc);

	return {max_motor_speed, polarity, min, max, max_acc};
}

int sensor_select_sdo(chanend coe_out)
{
    int sensor_select;
    GET_SDO_DATA(CIA402_SENSOR_SELECTION_CODE, 0, sensor_select);
    if(sensor_select == 2 || sensor_select == 3)
        sensor_select = 2; //qei
    return sensor_select;
}
{int, int, int} velocity_sdo_update(chanend coe_out)
{
	int Kp;
	int Ki;
	int Kd;

	GET_SDO_DATA(CIA402_VELOCITY_GAIN, 1, Kp);
	GET_SDO_DATA(CIA402_VELOCITY_GAIN, 2, Ki);
	GET_SDO_DATA(CIA402_VELOCITY_GAIN, 3, Kd);

	return {Kp, Ki, Kd};
}

int hall_sdo_update(chanend coe_out)
{
	int pole_pairs;
	//int min;
	//int max;

	//GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 1, min);
	//GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 2, max);
	GET_SDO_DATA(CIA402_MOTOR_SPECIFIC, 3, pole_pairs);

	return pole_pairs; //{pole_pairs, max, min};
}



{int, int, int} qei_sdo_update(chanend coe_out)
{
	int ticks_resolution;
	int qei_type;
	//int min;
	//int max;
	int sensor_polarity;

	//GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 1, min);
	//GET_SDO_DATA(CIA402_SOFTWARE_POSITION_LIMIT, 2, max);
	GET_SDO_DATA(CIA402_POSITION_ENC_RESOLUTION, 0, ticks_resolution);
	GET_SDO_DATA(CIA402_SENSOR_SELECTION_CODE, 0, qei_type);
	GET_SDO_DATA(SENSOR_POLARITY, 0, sensor_polarity);

	if(qei_type == QEI_WITH_INDEX)
		return {ticks_resolution, QEI_WITH_INDEX, sensor_polarity};
	else if(qei_type == QEI_WITH_NO_INDEX)
		return {ticks_resolution, QEI_WITH_NO_INDEX, sensor_polarity};
	else
		return {ticks_resolution, QEI_WITH_INDEX, sensor_polarity};	//default
}

int ctrlproto_protocol_handler_function(chanend pdo_out, chanend pdo_in, ctrl_proto_values_t &InOut)
{

	int buffer[64];
	unsigned int count = 0;
	int i;


	pdo_in <: DATA_REQUEST;
	pdo_in :> count;
	//printstr("count  ");
	//printintln(count);
	for (i = 0; i < count; i++) {
		pdo_in :> buffer[i];
		//printhexln(buffer[i]);
	}

	//Test for matching number of words
	if(count > 0)
	{
		InOut.control_word    = (buffer[0]) & 0xffff;
		InOut.operation_mode  = buffer[1] & 0xff;
		InOut.target_torque   = ((buffer[2]<<8 & 0xff00) | (buffer[1]>>8 & 0xff)) & 0x0000ffff;
		InOut.target_position = ((buffer[4]&0x00ff)<<24 | buffer[3]<<8 | (buffer[2] & 0xff00)>>8 )&0xffffffff;
		InOut.target_velocity = (buffer[6]<<24 | buffer[5]<<8 |  (buffer[4]&0xff00) >> 8)&0xffffffff;
		InOut.user1_in        = (buffer[8]&0xff)  | ((buffer[7]&0xffff)<<8)  | ((buffer[6]>>8)&0xff);
		InOut.user2_in        = (buffer[10]&0xff) | ((buffer[9]&0xffff)<<8)  | ((buffer[8]>>8)&0xff);
		InOut.user3_in        = (buffer[12]&0xff) | ((buffer[11]&0xffff)<<8) | ((buffer[10]>>8)&0xff);
		InOut.user4_in        = (buffer[14]&0xff) | ((buffer[13]&0xffff)<<8) | ((buffer[12]>>8)&0xff);
//		printhexln(InOut.control_word);
//		printhexln(InOut.operation_mode);
//		printhexln(InOut.target_torque);
//		printhexln(InOut.target_position);
//		printhexln(InOut.target_velocity);
	}

	if(count > 0)
	{
		pdo_out <: MAX_PDO_SIZE;
		buffer[0]  = InOut.status_word ;
		buffer[1]  = (InOut.operation_mode_display | (InOut.position_actual&0xff)<<8) ;
		buffer[2]  = (InOut.position_actual>> 8)& 0xffff;
		buffer[3]  = ((InOut.position_actual>>24) & 0xff) | ((InOut.velocity_actual&0xff)<<8);
		buffer[4]  = (InOut.velocity_actual>> 8)& 0xffff;
		buffer[5]  = ((InOut.velocity_actual>>24) & 0xff) | ((InOut.torque_actual&0xff)<<8) ;
		buffer[6]  = ((InOut.user1_out<<8)&0xff00) | ((InOut.torque_actual >> 8)&0xff);
		buffer[7]  = ((InOut.user1_out>>8)&0xffff);
		buffer[8]  = ((InOut.user2_out<<8)&0xff00) | ((InOut.user1_out>>24)&0xff);
		buffer[9]  = ((InOut.user2_out>>8)&0xffff);
		buffer[10] = ((InOut.user3_out<<8)&0xff00) | ((InOut.user2_out>>24)&0xff);
		buffer[11] = ((InOut.user3_out>>8)&0xffff);
		buffer[12] = ((InOut.user4_out<<8)&0xff00) | ((InOut.user3_out>>24)&0xff);
		buffer[13] = ((InOut.user4_out>>8)&0xffff);
		buffer[14] = ((InOut.user4_out>>24)&0xff);
		for (i = 0; i < MAX_PDO_SIZE; i++)
		{
			pdo_out <: (unsigned) buffer[i];
		}
	}
	return count;
}

void init_sdo(chanend coe_out)
{
    unsigned int tmp;
    unsigned char status = 0;
    timer t;
    unsigned int time;
    coe_out <: CAN_GET_OBJECT;
    coe_out <: CAN_OBJ_ADR(0x60b0, 0);
    coe_out :> tmp;
    status= (unsigned char)(tmp&0xff);
    if (status == 0) {
        coe_out <: CAN_SET_OBJECT;
        coe_out <: CAN_OBJ_ADR(0x60b0, 0);
        status = 0xaf;
        coe_out <: (unsigned)status;
        coe_out :> tmp;
        if (tmp == status) {
            t :> time;
            t when timerafter(time + 500*100000) :> time;
        }
    }
}


int get_target_torque(ctrl_proto_values_t InOut)
{
    return InOut.target_torque;
}

int get_target_velocity(ctrl_proto_values_t InOut)
{
    return InOut.target_velocity;
}

int get_target_position(ctrl_proto_values_t InOut)
{
    return InOut.target_position;
}

void send_actual_torque(int actual_torque, ctrl_proto_values_t &InOut)
{
    InOut.torque_actual = actual_torque;
}

void send_actual_velocity(int actual_velocity, ctrl_proto_values_t &InOut)
{
    InOut.velocity_actual = actual_velocity;
}

void send_actual_position(int actual_position, ctrl_proto_values_t &InOut)
{
    InOut.position_actual = actual_position;
}

void update_hall_config_ecat(HallConfig &hall_config, chanend coe_out)
{
    //int min;
    //int max;

    //{hall_config.pole_pairs, max, min} = hall_sdo_update(coe_out);
    hall_config.pole_pairs = hall_sdo_update(coe_out);

    //min = abs(min);
    //max = abs(max);

    //hall_config.max_ticks = (max > min) ? max : min;

    //hall_config.max_ticks_per_turn = hall_config.pole_pairs * HALL_POSITION_INTERPOLATED_RANGE;
    //hall_config.max_ticks += hall_config.max_ticks_per_turn;
}

void update_qei_param_ecat(QEIConfig &qei_params, chanend coe_out)
{
    //int min;
    //int max;

    { qei_params.ticks_resolution, qei_params.index_type, qei_params.sensor_polarity } = qei_sdo_update(coe_out);

    //min = abs(min);
    //max = abs(max);

    //qei_params.max_ticks = (max > min) ? max : min;
    //qei_params.max_ticks += qei_params.max_ticks_per_turn;  // tolerance
}

void update_commutation_param_ecat(MotorcontrolConfig &commutation_params, chanend coe_out)
{
    {commutation_params.hall_offset[0], commutation_params.hall_offset[1],
            commutation_params.bldc_winding_type} = commutation_sdo_update(coe_out);
}

void update_cst_param_ecat(ProfilerConfig &cst_params, chanend coe_out)
{
    {cst_params.max_velocity, cst_params.polarity, cst_params.max_current} = cst_sdo_update(coe_out);

    if (cst_params.polarity >= 0) {
        cst_params.polarity = 1;
    } else if (cst_params.polarity < 0) {
        cst_params.polarity = -1;
    }
}

void update_csv_param_ecat(ProfilerConfig &csv_params, chanend coe_out)
{
    {csv_params.max_velocity,
        csv_params.polarity,
        csv_params.max_acceleration} = csv_sdo_update(coe_out);

    if (csv_params.polarity >= 0) {
        csv_params.polarity = 1;
    } else if (csv_params.polarity < 0) {
        csv_params.polarity = -1;
    }
}

void update_csp_param_ecat(ProfilerConfig &csp_params, chanend coe_out)
{
    {csp_params.max_velocity, csp_params.polarity, csp_params.min_position, csp_params.max_position,
            csp_params.max_acceleration} = csp_sdo_update(coe_out);
    if (csp_params.polarity >= 0) {
        csp_params.polarity = 1;
    } else if (csp_params.polarity < 0) {
        csp_params.polarity = -1;
    }
}

void update_pt_param_ecat(ProfilerConfig &pt_params, chanend coe_out)
{
    {pt_params.current_slope, pt_params.polarity} = pt_sdo_update(coe_out);
    if (pt_params.polarity >= 0) {
        pt_params.polarity = 1;
    } else if (pt_params.polarity < 0) {
        pt_params.polarity = -1;
    }
}

void update_pv_param_ecat(ProfilerConfig &pv_params, chanend coe_out)
{
    {pv_params.max_velocity, pv_params.acceleration,
            pv_params.deceleration,
            pv_params.max_deceleration,
            pv_params.polarity} = pv_sdo_update(coe_out);
}

void update_pp_param_ecat(ProfilerConfig &pp_params, chanend coe_out)
{
    {pp_params.max_velocity, pp_params.velocity,
            pp_params.acceleration, pp_params.deceleration,
            pp_params.max_deceleration,
            pp_params.min_position,
            pp_params.max_position,
            pp_params.polarity,
            pp_params.max_acceleration} = pp_sdo_update(coe_out);
}

void update_torque_ctrl_param_ecat(ControlConfig &torque_ctrl_params, chanend coe_out)
{
    {torque_ctrl_params.Kp_n, torque_ctrl_params.Ki_n, torque_ctrl_params.Kd_n} = torque_sdo_update(coe_out);
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


void update_velocity_ctrl_param_ecat(ControlConfig &velocity_ctrl_params, chanend coe_out)
{
    {velocity_ctrl_params.Kp_n, velocity_ctrl_params.Ki_n, velocity_ctrl_params.Kd_n} = velocity_sdo_update(coe_out);
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

void update_position_ctrl_param_ecat(ControlConfig &position_ctrl_params, chanend coe_out)
{
    {position_ctrl_params.Kp_n, position_ctrl_params.Ki_n, position_ctrl_params.Kd_n} = position_sdo_update(coe_out);
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
