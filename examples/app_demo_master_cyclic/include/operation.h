/*
 * operation.h
 *
 *  Created on: Nov 6, 2016
 *      Author: synapticon
 */

#ifndef OPERATION_H_
#define OPERATION_H_

#include <stdint.h>

#include "cia402.h"

typedef enum {
    NO_MODE,
    QUIT_MODE,
    CS_MODE
} AppMode;

typedef struct {
    int mode_1;
    int mode_2;
    int mode_3;
    int value;
    int sign;
    int last_command;
    int last_value;
    int init;
    int select;
    int debug;
    CIA402State target_state;
    AppMode app_mode;
} OutputValues;


#include "profile.h"

typedef enum {
    POSITION_DIRECT=0,
    POSITION_PROFILER=1,
    POSITION_STEP=2,
    POSITION_STEP_PROFILER=3
} PositionCtrlMode;

typedef struct {
    motion_profile_t motion_profile;
    int max_acceleration;
    int max_speed;
    int profile_speed;
    int profile_acceleration;
    int max_position;
    int min_position;
    int target_position;
    int ticks_per_turn;
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

void target_generate(PositionProfileConfig *config, PDOOutput *pdo_output, PDOInput pdo_input);

void cs_command(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output, PositionProfileConfig *profiler_config);

void cs_mode(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output, PositionProfileConfig *profile_config);


#endif /* OPERATION_H_ */
