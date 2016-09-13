/**
 * @file cia402_wrapper.h
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>
#include <canod.h>

#include <hall_service.h>
#include <qei_service.h>
#include <control_loops_common.h>
#include <profile_control.h>
#include <ethercat_service.h>

/* internal qei single variable selection code */
#define QEI_SENSOR_TYPE                         QEI_WITH_INDEX//QEI_WITH_NO_INDEX

/*
 * FIXME: documentation missing
 */
void config_sdo_handler(client interface i_coe_communication i_coe);

/**
 * @brief read sensor select from EtherCAT
 *
 * obsoleted by direct call
 *
 * @return sensor_select HALL/QEI
 *
 */
int sensor_select_sdo(client interface i_coe_communication i_coe);

/**
 * @brief read qei params from EtherCAT
 *
 * obsoleted by sm_sync_config_qei()
 *
 * @return real counts
 * @return max position
 * @return min position
 * @return qei type
 * @return sensor polarity
 *
 */
{int, int, int} qei_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read hall params from EtherCAT
 *
 * obsolete by cm_sync_config_hall()
 * @return pole pairs
 *
 */
int hall_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read commutation parameters from EtherCAT
 *
 * @return hall_offset_clk
 * @return hall_offset_cclk
 * @return winding_type
 *
 */
{int, int, int} commutation_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read homing parameters from EtherCAT
 *
 * @return homing_method
 * @return limit_switch_type
 *
 */
{int, int} homing_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read profile torque params from EtherCAT
 *
 * @return torque_slope
 * @return polarity
 *
 */
{int, int} pt_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read profile velocity params from EtherCAT
 *
 * @return max_profile_velocity
 * @return profile_acceleration
 * @return profile_deceleration
 * @return quick_stop_deceleration
 * @return polarity
 *
 */
{int, int, int, int, int} pv_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read profile position params from EtherCAT
 *
 * @return max_profile_velocity
 * @return profile_velocity
 * @return profile_acceleration
 * @return profile_deceleration
 * @return quick_stop_deceleration
 * @return min
 * @return max
 * @return polarity
 * @return max_acceleration
 *
 */
{int, int, int, int, int, int, int, int, int} pp_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read cyclic synchronous torque params from EtherCAT
 *
 * @return nominal_current
 * @return max_motor_speed
 * @return polarity
 * @return max_torque
 * @return motor_torque_constant
 *
 */
{int, int, int} cst_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read cyclic synchronous velocity params from EtherCAT
 *
 * @return max_motor_speed
 * @return nominal_current
 * @return polarity
 * @return motor_torque_constant
 * @return max_acceleration
 *
 */
{int, int, int} csv_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read cyclic synchronous position params from EtherCAT
 *
 * @return max_motor_speed
 * @return polarity
 * @return nominal_current
 * @return min position
 * @return max position
 * @return max_acceleration
 *
 */
{int, int, int, int, int} csp_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read torque control params from EtherCAT
 *
 * obsolete by cm_sync_config_rotque_control()
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} torque_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read velocity control params from EtherCAT
 *
 * obsolete by cm_sync_config_velocity_control()
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} velocity_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read position control params from EtherCAT
 *
 * obsolete by cm_sync_config_position_control()
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} position_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief read nominal speed from EtherCAT
 *
 * obsoleted by direct call
 *
 * @return nominal_speed
 *
 */
int speed_sdo_update(client interface i_coe_communication i_coe);

/**
 * @brief Update Hall sensor parameters from EtherCAT
 *
 * obsoleted by cm_sync_config_hall()
 *
 * @param hall_config struct defines the pole-pairs and gear ratio
 * @param coe_out
 */
void update_hall_config_ecat(HallConfig &hall_config, client interface i_coe_communication i_coe);

/**
 * @brief Update QEI sensor parameters from EtherCAT
 *
 * obsoleted by sm_sync_config_qei()
 *
 * @param qei_params struct defines the quadrature encoder (QEI) resolution, sensor type and
 *    gear-ratio used for the motor
 * @param coe_out
 */
void update_qei_param_ecat(QEIConfig &qei_params, client interface i_coe_communication i_coe);

/* obsoleted by cm_sync_config_motor_commutation() or cm_sync_config_motor_control() */
void update_commutation_param_ecat(MotorcontrolConfig &commutation_params, client interface i_coe_communication i_coe);


/**
 * @brief Update cyclic synchronous torque parameters from EtherCAT
 *
 * @param cst_params struct defines the cyclic synchronous torque params
 * @param coe_out
 */
void update_cst_param_ecat(ProfilerConfig &cst_params, client interface i_coe_communication i_coe);

/**
 * @brief Update cyclic synchronous velocity parameters from EtherCAT
 *
 * @param csv_params struct defines the cyclic synchronous velocity params
 * @param coe_out
 *
 */
void update_csv_param_ecat(ProfilerConfig &csv_params, client interface i_coe_communication i_coe);

/**
 * @brief Update cyclic synchronous position parameters from EtherCAT
 *
 * @param csp_params struct defines the cyclic synchronous position params
 * @param coe_out
 */
void update_csp_param_ecat(ProfilerConfig &csp_params, client interface i_coe_communication i_coe);

/**
 * @brief Update profile torque parameters from EtherCAT
 *
 * @param pt_params struct defines the profile torque params
 * @param coe_out
 */
void update_pt_param_ecat(ProfilerConfig &pt_params, client interface i_coe_communication i_coe);

/**
 * @brief Update profile velocity parameters from EtherCAT
 *
 * @param pv_params struct defines the profile velocity params
 * @param coe_out
 */
void update_pv_param_ecat(ProfilerConfig &pv_params, client interface i_coe_communication i_coe);

/**
 * @brief Update profile position parameters from EtherCAT
 *
 * obsoleted by cm_sync_config_profiler
 *
 * @param pp_params struct defines the profile position params
 * @param coe_out
 */
void update_pp_param_ecat(ProfilerConfig &pp_params, client interface i_coe_communication i_coe);

/**
 * @brief Update torque control PID parameters from EtherCAT
 *
 * obsoleted by cm_sync_config_velocity_control()
 *
 * @param torque_ctrl_params struct defines torque control PID params
 * @param coe_out
 */
void update_torque_ctrl_param_ecat(ControlConfig &torque_ctrl_params, client interface i_coe_communication i_coe);

/**
 * @brief Update velocity control PID parameters from EtherCAT
 *
 * obsolete by cm_sync_config_velocity_control()
 *
 * @param velocity_ctrl_params struct defines velocity control PID params
 * @param coe_out
 */
void update_velocity_ctrl_param_ecat(ControlConfig &velocity_ctrl_params, client interface i_coe_communication i_coe);

/**
 * @brief Update position control PID params from EtherCAT
 *
 * obsolete by cm_sync_config_position_control()
 *
 * @param position_ctrl_params struct defines position control PID params
 * @param coe_out
 */
void update_position_ctrl_param_ecat(ControlConfig &position_ctrl_params, client interface i_coe_communication i_coe);

