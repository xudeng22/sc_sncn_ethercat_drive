/**
 * @file bldc_motor_init.h
 * @brief Motor Control init  API
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <drive_modes_config.h>

/**
 * @brief initialize Velocity sensor filter
 *
 * @param sensor_filter_par struct defines the velocity filter params
 */
//void init_sensor_filter_param(filter_par &sensor_filter_par) ;

/**
 * @brief initialize cyclic synchronous velocity params
 *
 * @param csv_params struct defines cyclic synchronous velocity params
 */
void init_csv_param(csv_par &csv_params);

/**
 * @brief initialize cyclic synchronous position params
 *
 * @param csp_params struct defines cyclic synchronous position params
 */
void init_csp_param(csp_par &csp_params);

/**
 * @brief initialize cyclic synchronous torque params
 *
 * @param cst_params struct defines cyclic synchronous torque params
 */
void init_cst_param(cst_par &cst_params);

/**
 * @brief initialize profile position params
 *
 * @param pp_params struct defines profileposition params
 */
void init_pp_params(pp_par &pp_params);

/**
 * @brief initialize profile velocity params
 *
 * @param pv_params struct defines profile velocity params
 */
void init_pv_params(pv_par &pv_params);

/**
 * @brief initialize profile torque params
 *
 * @param pt_params struct defines profile torque params
 */
void init_pt_params(pt_par &pt_params);
