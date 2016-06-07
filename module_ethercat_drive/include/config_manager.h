/**
 * @file config_manager.h
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <ethercat_service.h>
#include <motorcontrol_service.h>
#include <hall_service.h>
#include <qei_service.h>
#include <gpio_service.h>
#include <position_ctrl_service.h>
#include <profile_control.h>

/*
 * General, syncronize configuration with the object dictionary values provided
 * by the EtherCAT master.
 */

void cm_sync_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config);

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_commutation,
        MotorcontrolConfig &commutation_params);

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler);
