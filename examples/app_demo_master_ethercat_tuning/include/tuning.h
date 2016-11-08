/*
 * tuning.h
 *
 *  Created on: Nov 6, 2016
 *      Author: romuald
 */

#ifndef TUNING_H_
#define TUNING_H_

typedef enum {
    TUNING_MOTORCTRL_OFF= 0,
    TUNING_MOTORCTRL_TORQUE= 1,
    TUNING_MOTORCTRL_POSITION= 2,
    TUNING_MOTORCTRL_VELOCITY= 3
} TuningMotorCtrlStatus;

typedef struct {
    TuningMotorCtrlStatus motorctrl_status;
    int target;
    int offset;
    int pole_pairs;
    int motor_polarity;
    int sensor_polarity;
    int torque_control_flag;
    int brake_flag;
    int max_position;
    int min_position;
    int max_speed;
    int max_torque;
    int P_pos;
    int I_pos;
    int D_pos;
    int integral_limit_pos;
} InputValues;

typedef struct {
    int mode_1;
    int mode_2;
    int mode_3;
    int value;
    int sign;
    int last_command;
    int last_value;
} OutputValues;

#include "ecat_master.h"
#include "display.h"

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input);

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, OutputValues *output, Cursor *cursor);

#endif /* TUNING_H_ */
