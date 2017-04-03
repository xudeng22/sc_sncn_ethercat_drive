/*
 * tuning.h
 *
 *  Created on: Nov 6, 2016
 *      Author: romuald
 */

#ifndef TUNING_H_
#define TUNING_H_

#include <stdint.h>

#define OPMODE_TUNING    (-128)
#define DISPLAY_LINE 27
#define HELP_ROW_COUNT 12

typedef enum {
    TUNING_CMD_AUTO_OFFSET                = 0x01,
    TUNING_CMD_BRAKE                      = 0x02,
    TUNING_CMD_SAFE_TORQUE                = 0x03,
    TUNING_CMD_ZERO_POSITION              = 0x04,
    TUNING_CMD_SET_MULTITURN              = 0x05,
    TUNING_CMD_FAULT_RESET                = 0x06,
    TUNING_CMD_CONTROL_DISABLE            = 0x07,
    TUNING_CMD_CONTROL_POSITION           = 0x08,
    TUNING_CMD_CONTROL_VELOCITY           = 0x09,
    TUNING_CMD_CONTROL_TORQUE             = 0x0A,
    TUNING_CMD_POSITION_KP                = 0xC0,
    TUNING_CMD_POSITION_KI                = 0xC1,
    TUNING_CMD_POSITION_KD                = 0xC2,
    TUNING_CMD_POSITION_I_LIM             = 0xC3,
    TUNING_CMD_MOMENT_INERTIA             = 0xC4,
    TUNING_CMD_POSITION_PROFILER          = 0xC5,
    TUNING_CMD_VELOCITY_KP                = 0xC6,
    TUNING_CMD_VELOCITY_KI                = 0xC7,
    TUNING_CMD_VELOCITY_KD                = 0xC8,
    TUNING_CMD_VELOCITY_I_LIM             = 0xC9,
    TUNING_CMD_MAX_SPEED                  = 0xCA,
    TUNING_CMD_MAX_POSITION               = 0xCB,
    TUNING_CMD_MIN_POSITION               = 0xCC,
    TUNING_CMD_BRAKE_RELEASE_STRATEGY     = 0xCD,
    TUNING_CMD_POLARITY_MOTION            = 0xCE,
    TUNING_CMD_MAX_TORQUE                 = 0xE0,
    TUNING_CMD_POLARITY_SENSOR            = 0x90,
    TUNING_CMD_POLE_PAIRS                 = 0xB0,
    TUNING_CMD_OFFSET                     = 0xA0,
    TUNING_CMD_PHASES_INVERTED            = 0xA1
} TuningCommands;

typedef enum {
    TUNING_MOTORCTRL_OFF= 0,
    TUNING_MOTORCTRL_TORQUE= 1,
    TUNING_MOTORCTRL_POSITION= 2,
    TUNING_MOTORCTRL_VELOCITY= 3,
    TUNING_MOTORCTRL_POSITION_PROFILER= 4
} TuningMotorCtrlStatus;

typedef enum {
    NO_MODE,
    QUIT_MODE,
    TUNING_MODE,
    CS_MODE
} AppMode;

typedef struct {
    TuningMotorCtrlStatus motorctrl_status;
    int target;
    int offset;
    int pole_pairs;
    int motion_polarity;
    int sensor_polarity;
    int profiler;
    int phases_inverted;
    int brake_release_strategy;
    int brake_flag;
    int error_status;
    int sensor_error;
    int max_position;
    int min_position;
    int max_speed;
    int max_torque;
    int P_pos;
    int I_pos;
    int D_pos;
    int integral_limit_pos;
    int P_velocity;
    int I_velocity;
    int D_velocity;
    int integral_limit_velocity;
} InputValues;

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
    int next_command;
    int next_value;
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

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input);

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output,\
        PositionProfileConfig *profile_config, RecordConfig *record_config, Cursor *cursor);

void tuning_position(PositionProfileConfig *config, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input);

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, char *filename);

void tuning(WINDOW *wnd, Cursor *cursor,
            struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input,
            OutputValues *output, InputValues *input,
            PositionProfileConfig *profile_config,
            RecordConfig *record_config, char *record_filename);

void cs_command(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output);

void cs_mode(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output);


#endif /* TUNING_H_ */
