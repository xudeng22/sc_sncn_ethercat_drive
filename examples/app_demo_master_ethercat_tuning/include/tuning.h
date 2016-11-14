/*
 * tuning.h
 *
 *  Created on: Nov 6, 2016
 *      Author: romuald
 */

#ifndef TUNING_H_
#define TUNING_H_

#include <stdint.h>

typedef enum {
    TUNING_MOTORCTRL_OFF= 0,
    TUNING_MOTORCTRL_TORQUE= 1,
    TUNING_MOTORCTRL_POSITION= 2,
    TUNING_MOTORCTRL_VELOCITY= 3,
    TUNING_MOTORCTRL_POSITION_PROFILER= 4
} TuningMotorCtrlStatus;

typedef struct {
    TuningMotorCtrlStatus motorctrl_status;
    int target;
    int offset;
    int pole_pairs;
    int motion_polarity;
    int sensor_polarity;
    int brake_release_strategy;
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


#include "profile.h"

typedef enum {
    POSITION_DIRECT=0,
    POSITION_PROFILER=1,
    POSITION_STEP=2
} PositionCtrlMode;

typedef struct {
    motion_profile_t motion_profile;
    int max_acceleration;
    int max_speed;
    int profile_speed;
    int profile_acceleration;
    int max_position;
    int min_position;
    int step;
    int steps;
    PositionCtrlMode mode;
} PositionProfileConfig;

typedef struct {
    int32_t target_position;
    int32_t position;
    int32_t velocity;
    int16_t torque;
} RecordData;

typedef enum {
    RECORD_ON,
    RECORD_OFF
} RecordState;

typedef struct {
    uint32_t count;
    uint32_t max_values;
    RecordData *data;
    RecordState state;
} RecordConfig;

#include "ecat_master.h"
#include "display.h"

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input);

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output,\
        PositionProfileConfig *profile_config, RecordConfig *record_config, Cursor *cursor);

void tuning_position(PositionProfileConfig *config, struct _pdo_cia402_output *pdo_output);

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, char *filename);

#endif /* TUNING_H_ */
