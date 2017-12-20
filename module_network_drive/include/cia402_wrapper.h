/**
 * @file cia402_wrapper.h
 * @brief CANopen CiA402 wrapper
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <stdlib.h>
#include <stdint.h>

#include <profile_control.h>
#include <co_interface.h>
#include <dictionary_symbols.h>

/* internal qei single variable selection code */
#define QEI_SENSOR_TYPE                         QEI_WITH_INDEX//QEI_WITH_NO_INDEX

/*
 * @brief Print whole object dictionary
 * @param i_co CANopen service communication Interface
 */
void print_object_dictionary(client interface i_co_communication i_co);

/**
 * @brief read profile velocity params from CANopen object dictionary
 *
 * @param i_co CANopen service communication Interface
 * @return max_profile_velocity
 * @return profile_acceleration
 * @return profile_deceleration
 * @return quick_stop_deceleration
 * @return polarity
 *
 */
{int, int, int, int, int} pv_sdo_update(client interface i_co_communication i_co);

/**
 * @brief read profile torque params from CANopen object dictionary
 *
 * @param i_co CANopen service communication Interface
 * @return torque_slope
 * @return polarity
 *
 */
{int, int} pt_sdo_update(client interface i_co_communication i_co);


/**
 * @brief read cyclic synchronous torque params from CANopen object dictionary
 *
 * @param i_co CANopen service communication Interface
 * @return max_motor_speed
 * @return polarity
 * @return max_torque
 *
 */
{int, int, int} cst_sdo_update(client interface i_co_communication i_co);


/**
 * @brief read cyclic synchronous velocity params from CANopen object dictionary
 *
 * @param i_co CANopen service communication Interface
 * @return max_motor_speed
 * @return polarity
 * @return max_acceleration
 *
 */
{int, int, int} csv_sdo_update(client interface i_co_communication i_co);


/**
 * @brief read cyclic synchronous position params from CANopen object dictionary
 *
 * @param i_co CANopen service communication Interface
 * @return max_motor_speed
 * @return polarity
 * @return min position
 * @return max position
 * @return max_acceleration
 *
 */
{int, int, int, int, int} csp_sdo_update(client interface i_co_communication i_co);


/**
 * @brief Update cyclic synchronous torque parameters from CANopen object dictionary
 *
 * @param cst_params struct defines the cyclic synchronous torque params
 * @param i_co CANopen service communication Interface
 */
void update_cst_param_ecat(ProfilerConfig &cst_params, client interface i_co_communication i_co);


/**
 * @brief Update cyclic synchronous velocity parameters from CANopen object dictionary
 *
 * @param csv_params struct defines the cyclic synchronous velocity params
 * @param i_co CANopen service communication Interface
 */
void update_csv_param_ecat(ProfilerConfig &csv_params, client interface i_co_communication i_co);


/**
 * @brief Update cyclic synchronous position parameters from CANopen object dictionary
 *
 * @param csp_params struct defines the cyclic synchronous position params
 * @param i_co CANopen service communication Interface
 */
void update_csp_param_ecat(ProfilerConfig &csp_params, client interface i_co_communication i_co);

/**
 * @brief Update profile torque parameters from CANopen object dictionary
 *
 * @param pt_params struct defines the profile torque params
 * @param i_co CANopen service communication Interface
 */
void update_pt_param_ecat(ProfilerConfig &pt_params, client interface i_co_communication i_co);

/**
 * @brief Update profile velocity parameters from CANopen object dictionary
 *
 * @param pv_params struct defines the profile velocity params
 * @param i_co CANopen service communication Interface
 */
void update_pv_param_ecat(ProfilerConfig &pv_params, client interface i_co_communication i_co);

