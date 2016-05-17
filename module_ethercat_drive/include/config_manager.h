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
#include <velocity_ctrl_service.h>
#include <position_ctrl_service.h>
#include <torque_ctrl_service.h>
#include <profile_control.h>

/*
 * General, syncronize configuration with the object dictionary values provided
 * by the EtherCAT master.
 */

void cm_sync_config_hall(
        client interface i_coe_communication i_coe,
        interface HallInterface client ?i_hall,
        HallConfig &hall_config);

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client i_commutation,
        MotorcontrolConfig &commutation_params);

void cm_sync_config_qei(
        client interface i_coe_communication i_coe,
        interface QEIInterface client ?i_qei,
        QEIConfig &qei_params);

void cm_sync_config_biss(
        client interface i_coe_communication i_coe,
        interface BISSInterface client ?i_biss,
        BISSConfig &biss_config);

void cm_sync_config_ams(
        client interface i_coe_communication i_coe,
        interface AMSInterface client ?i_ams,
        AMSConfig &ams_config);

void cm_sync_config_torque_control(
        client interface i_coe_communication i_coe,
        interface TorqueControlInterface client ?i_torque_control,
        ControlConfig &torque_ctrl_params);

void cm_sync_config_velocity_control(
        client interface i_coe_communication i_coe,
        interface VelocityControlInterface client i_velocity_control,
        ControlConfig &velocity_ctrl_params);

void cm_sync_config_position_control(
        client interface i_coe_communication i_coe,
        interface PositionControlInterface client i_position_control,
        ControlConfig &position_ctrl_params);
