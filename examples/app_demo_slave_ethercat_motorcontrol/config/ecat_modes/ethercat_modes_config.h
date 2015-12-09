/*
 * control_config.h
 *
 *  Created on: Nov 30, 2015
 *      Author: atena
 */


#pragma once

#include <profile_control.h>
#include <control_loops_common.h>

/**
 * @brief initialize cyclic synchronous velocity params
 *
 * @param csv_config struct defines cyclic synchronous velocity params
 */
void init_csv_config(CyclicSyncVelocityConfig &csv_config);

/**
 * @brief initialize cyclic synchronous position params
 *
 * @param csp_config struct defines cyclic synchronous position params
 */
void init_csp_config(CyclicSyncPositionConfig &csp_config);

/**
 * @brief initialize cyclic synchronous torque params
 *
 * @param cst_config struct defines cyclic synchronous torque params
 */
void init_cst_config(CyclicSyncTorqueConfig &cst_config);

/**
 * @brief initialize profile position params
 *
 * @param pp_config struct defines profileposition params
 */
void init_pp_config(ProfilePositionConfig &pp_config);

/**
 * @brief initialize profile velocity params
 *
 * @param pv_config struct defines profile velocity params
 */
void init_pv_config(ProfileVelocityConfig &pv_config);

/**
 * @brief initialize profile torque params
 *
 * @param pt_config struct defines profile torque params
 */
void init_pt_config(ProfileTorqueConfig &pt_config);
