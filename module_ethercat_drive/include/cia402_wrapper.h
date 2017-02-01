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
#include <dictionary_symbols.h>

#include <hall_service.h>
#include <qei_service.h>
#include <control_loops_common.h>
#include <profile_control.h>
#include <ethercat_service.h>

/* internal qei single variable selection code */
#define QEI_SENSOR_TYPE                         QEI_WITH_INDEX//QEI_WITH_NO_INDEX

/**
 * @brief Debug function to print content of the boject dictionary
 *
 * FIXME: Update to print (again) the complete object dictionary
 *
 * @param i_coe interface to communicate with the dictionary service
 */
void config_print_dictionary(client interface i_coe_communication i_coe);

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
