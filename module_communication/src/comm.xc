/**
 * @file comm.xc
 * @brief Ctrlproto data struct client
 * @author Synapticon GmbH <support@synapticon.com>
*/

#include <comm.h>
#include <refclk.h>

#include <ctrlproto.h>
#include <motorcontrol_service.h>

#include <control_loops_common.h>
#include <internal_config.h>
#include <stdlib.h>

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
    int min;
    int max;

    {hall_config.pole_pairs, max, min} = hall_sdo_update(coe_out);

    min = abs(min);
    max = abs(max);

    hall_config.max_ticks = (max > min) ? max : min;

    hall_config.max_ticks_per_turn = hall_config.pole_pairs * HALL_POSITION_INTERPOLATED_RANGE;
    hall_config.max_ticks += hall_config.max_ticks_per_turn;
}

void update_qei_param_ecat(QEIConfig &qei_params, chanend coe_out)
{
    int min;
    int max;

    { qei_params.real_counts, max, min, qei_params.index, qei_params.sensor_polarity } = qei_sdo_update(coe_out);

    min = abs(min);
    max = abs(max);

    qei_params.max_ticks = (max > min) ? max : min;
    qei_params.max_ticks += qei_params.max_ticks_per_turn;  // tolerance
}

void update_commutation_param_ecat(MotorcontrolConfig &commutation_params, chanend coe_out)
{
    {commutation_params.hall_offset_clk, commutation_params.hall_offset_cclk,
            commutation_params.bldc_winding_type} = commutation_sdo_update(coe_out);
}

void update_cst_param_ecat(cst_par &cst_params, chanend coe_out)
{
    {cst_params.nominal_current, cst_params.nominal_motor_speed, cst_params.polarity,
            cst_params.max_torque, cst_params.motor_torque_constant} = cst_sdo_update(coe_out);
    if (cst_params.polarity >= 0) {
        cst_params.polarity = 1;
    } else if (cst_params.polarity < 0) {
        cst_params.polarity = -1;
    }
}

void update_csv_param_ecat(csv_par &csv_params, chanend coe_out)
{
    {csv_params.max_motor_speed, csv_params.nominal_current, csv_params.polarity,
            csv_params.max_acceleration, csv_params.motor_torque_constant} = csv_sdo_update(coe_out);

    if (csv_params.polarity >= 0) {
        csv_params.polarity = 1;
    } else if (csv_params.polarity < 0) {
        csv_params.polarity = -1;
    }
}

void update_csp_param_ecat(csp_par &csp_params, chanend coe_out)
{
    {csp_params.base.max_motor_speed, csp_params.base.polarity, csp_params.base.nominal_current,
            csp_params.min_position_limit, csp_params.max_position_limit,
            csp_params.base.max_acceleration} = csp_sdo_update(coe_out);
    if (csp_params.base.polarity >= 0) {
        csp_params.base.polarity = 1;
    } else if (csp_params.base.polarity < 0) {
        csp_params.base.polarity = -1;
    }
}

void update_pt_param_ecat(pt_par &pt_params, chanend coe_out)
{
    {pt_params.profile_slope, pt_params.polarity} = pt_sdo_update(coe_out);
    if (pt_params.polarity >= 0) {
        pt_params.polarity = 1;
    } else if (pt_params.polarity < 0) {
        pt_params.polarity = -1;
    }
}

void update_pv_param_ecat(pv_par &pv_params, chanend coe_out)
{
    {pv_params.max_profile_velocity, pv_params.profile_acceleration,
            pv_params.profile_deceleration,
            pv_params.quick_stop_deceleration,
            pv_params.polarity} = pv_sdo_update(coe_out);
}

void update_pp_param_ecat(pp_par &pp_params, chanend coe_out)
{
    {pp_params.base.max_profile_velocity, pp_params.profile_velocity,
            pp_params.base.profile_acceleration, pp_params.base.profile_deceleration,
            pp_params.base.quick_stop_deceleration,
            pp_params.software_position_limit_min,
            pp_params.software_position_limit_max,
            pp_params.base.polarity,
            pp_params.max_acceleration} = pp_sdo_update(coe_out);
}

void update_torque_ctrl_param_ecat(ControlConfig &torque_ctrl_params, chanend coe_out)
{
    {torque_ctrl_params.Kp_n, torque_ctrl_params.Ki_n, torque_ctrl_params.Kd_n} = torque_sdo_update(coe_out);
    torque_ctrl_params.Kp_d = 65536;                // 16 bit precision PID gains
    torque_ctrl_params.Ki_d = 65536;
    torque_ctrl_params.Kd_d = 65536;

    torque_ctrl_params.Loop_time = 1 * MSEC_STD;    // units - core timer value //CORE 2/1/0 default

    torque_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT;  // PWM resolution

    if(torque_ctrl_params.Ki_n != 0)                // auto calculated using control_limit
        torque_ctrl_params.Integral_limit = torque_ctrl_params.Control_limit * (torque_ctrl_params.Ki_d/torque_ctrl_params.Ki_n) ;
    else
        torque_ctrl_params.Integral_limit = 0;
    return;
}


void update_velocity_ctrl_param_ecat(ControlConfig &velocity_ctrl_params, chanend coe_out)
{
    {velocity_ctrl_params.Kp_n, velocity_ctrl_params.Ki_n, velocity_ctrl_params.Kd_n} = velocity_sdo_update(coe_out);
    velocity_ctrl_params.Kp_d = 65536;              // 16 bit precision PID gains
    velocity_ctrl_params.Ki_d = 65536;
    velocity_ctrl_params.Kd_d = 65536;

    velocity_ctrl_params.Loop_time = 1 * MSEC_STD;  // units - core timer value //CORE 2/1/0 default

    velocity_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution

    if(velocity_ctrl_params.Ki_n != 0)              // auto calculated using control_limit
        velocity_ctrl_params.Integral_limit = velocity_ctrl_params.Control_limit * (velocity_ctrl_params.Ki_d/velocity_ctrl_params.Ki_n) ;
    else
        velocity_ctrl_params.Integral_limit = 0;
    return;
}

void update_position_ctrl_param_ecat(ControlConfig &position_ctrl_params, chanend coe_out)
{
    {position_ctrl_params.Kp_n, position_ctrl_params.Ki_n, position_ctrl_params.Kd_n} = position_sdo_update(coe_out);
    position_ctrl_params.Kp_d = 65536;              // 16 bit precision PID gains
    position_ctrl_params.Ki_d = 65536;
    position_ctrl_params.Kd_d = 65536;

    position_ctrl_params.Loop_time = 1 * MSEC_STD;  // units - core timer value //CORE 2/1/0 default

    position_ctrl_params.Control_limit = BLDC_PWM_CONTROL_LIMIT; // PWM resolution

    if(position_ctrl_params.Ki_n != 0)              // auto calculated using control_limit
        position_ctrl_params.Integral_limit = position_ctrl_params.Control_limit * (position_ctrl_params.Ki_d/position_ctrl_params.Ki_n) ;
    else
        position_ctrl_params.Integral_limit = 0;
    return;
}
