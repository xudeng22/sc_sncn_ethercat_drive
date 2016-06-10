/*
 * tuning.h
 *
 *  Created on: Jul 13, 2015
 *      Author: Synapticon GmbH
 */


#pragma once

#include <platform.h>
#include <motorcontrol_service.h>
#include <pwm_service.h>
#include <refclk.h>
#include <adc_service.h>
#include <position_ctrl_service.h>
#include <profile_control.h>
#include <ethercat_service.h>
#include <pdo_handler.h>

#include <xscope.h>
#include <mc_internal_constants.h>
#include <user_config.h>

interface TuningInterface {
    void tune(int voltage);
    void set_limit(int limit);
    void set_position(int position);
    void set_torque(int in_torque);
    int get_velocity();
};


void run_offset_tuning(int position_limit, interface MotorcontrolInterface client i_motorcontrol,
                      interface PositionVelocityCtrlInterface client ?i_position_control,
                      chanend pdo_out, chanend pdo_in, client interface i_coe_communication i_coe);

