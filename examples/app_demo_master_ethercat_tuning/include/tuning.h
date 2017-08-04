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
#define DISPLAY_LINE 30
#define HELP_ROW_COUNT 12


/**
 * @brief CiA 402 Fault Codes
 */
typedef enum {
    //having no fault:
    NO_FAULT=0,

    //standard defined faults (IEC-61800)
    DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1 = 0x2221,
    OVER_VOLTAGE_NO_1                           = 0x3211,
    UNDER_VOLTAGE_NO_1                          = 0x3221,
    EXCESS_TEMPERATURE_DRIVE                    = 0x4310,

    //user specific faults
    WRONG_REF_CLK_FRQ=0xFF01
} CIA402ErrorCodes;


/**
 * @brief Type for Motion control Error
 *
 */
typedef enum {
    MOTION_CONTROL_NO_ERROR=0,
    MOTION_CONTROL_BRAKE_NOT_RELEASED=1
} MotionControlError;

#define TUNING_ACK                          0x80000000

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
    TUNING_CMD_AUTO_POS_CTRL_TUNE         = 0x0B,
    TUNING_CMD_AUTO_VEL_CTRL_TUNE         = 0x0C,
    TUNING_CMD_COGGING_TORQUE             = 0x0D,
    TUNING_CMD_AUTO_RECORD_COGGING        = 0x0E,
    TUNING_CMD_SAVE_RECORD_COGGING        = 0x0F,
    TUNING_CMD_LOAD_RECORD_COGGING        = 0x10,
    TUNING_CMD_AUTO_CALIBRATE_SENSOR      = 0x11,
    TUNING_CMD_SENSOR_CALIBRATION         = 0x12,
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
    TUNING_CMD_FILTER                     = 0xCF,
    TUNING_CMD_TUNE_AMPLITUDE             = 0xD0,
    TUNING_CMD_TUNE_PERIOD                = 0xD1,
    TUNING_CMD_MAX_TORQUE                 = 0xE0,
    TUNING_CMD_POLARITY_SENSOR            = 0x90,
    TUNING_CMD_POLE_PAIRS                 = 0xB0,
    TUNING_CMD_OFFSET                     = 0xA0,
    TUNING_CMD_PHASES_INVERTED            = 0xA1,
    TUNING_CMD_RATED_TORQUE               = 0xA2
} TuningCommands;

typedef enum {
    TUNING_STATUS_MUX_OFFSET            = 1,
    TUNING_STATUS_MUX_POLE_PAIRS        = 2,
    TUNING_STATUS_MUX_MIN_POS           = 3,
    TUNING_STATUS_MUX_MAX_POS           = 4,
    TUNING_STATUS_MUX_MAX_SPEED         = 5,
    TUNING_STATUS_MUX_MAX_TORQUE        = 6,
    TUNING_STATUS_MUX_POS_KP            = 7,
    TUNING_STATUS_MUX_POS_KI            = 8,
    TUNING_STATUS_MUX_POS_KD            = 9,
    TUNING_STATUS_MUX_POS_I_LIM         = 10,
    TUNING_STATUS_MUX_VEL_KP            = 11,
    TUNING_STATUS_MUX_VEL_KI            = 12,
    TUNING_STATUS_MUX_VEL_KD            = 13,
    TUNING_STATUS_MUX_VEL_I_LIM         = 14,
    TUNING_STATUS_MUX_FAULT             = 15,
    TUNING_STATUS_MUX_BRAKE_STRAT       = 16,
    TUNING_STATUS_MUX_SENSOR_ERROR      = 17,
    TUNING_STATUS_MUX_MOTION_CTRL_ERROR = 18,
    TUNING_STATUS_MUX_RATED_TORQUE      = 19,
    TUNING_STATUS_MUX_FILTER            = 20,
    TUNING_STATUS_MUX_TUNE_AMPLITUDE    = 21,
    TUNING_STATUS_MUX_TUNE_PERIOD       = 22
} TuningStatusMux;

typedef enum {
    TUNING_FLAG_BRAKE               = 0,
    TUNING_FLAG_MOTION_POLARITY     = 1,
    TUNING_FLAG_SENSOR_POLARITY     = 2,
    TUNING_FLAG_PHASES_INVERTED     = 3,
    TUNING_FLAG_INTEGRATED_PROFILER = 4,
    TUNING_FLAG_COGGING_TORQUE      = 5,
    TUNING_FLAG_SENSOR_CALIBRATION  = 6
} TuningFlagsBit;

typedef enum {
    TUNING_MOTORCTRL_OFF                            = 0,
    TUNING_MOTORCTRL_POSITION_PID                   = 1,
    TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED = 2,
    TUNING_MOTORCTRL_POSITION_LT                    = 3,
    TUNING_MOTORCTRL_VELOCITY                       = 4,
    TUNING_MOTORCTRL_TORQUE                         = 5,
} TuningMotorCtrlStatus;

typedef enum {
    NO_MODE,
    QUIT_MODE,
    TUNING_MODE,
    CS_MODE
} AppMode;

typedef struct {
    TuningMotorCtrlStatus motorctrl_status;
    int offset;
    int pole_pairs;
    int motion_polarity;
    int sensor_polarity;
    int profiler;
    int phases_inverted;
    int brake_release_strategy;
    int brake_flag;
    int cogging_torque_flag;
    int sensor_calibration_flag;
    int error_status;
    int sensor_error;
    int motion_control_error;
    int max_position;
    int min_position;
    int max_speed;
    int max_torque;
    int rated_torque;
    int P_pos;
    int I_pos;
    int D_pos;
    int integral_limit_pos;
    int P_velocity;
    int I_velocity;
    int D_velocity;
    int integral_limit_velocity;
    int filter;
    int tune_amplitude;
    int tune_period;
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
    int32_t target;
    int32_t position;
    int32_t velocity;
    int16_t torque;
    int32_t timestamp;
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

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, InputValues input, char *filename);

void tuning(WINDOW *wnd, Cursor *cursor,
            struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input,
            OutputValues *output, InputValues *input,
            PositionProfileConfig *profile_config,
            RecordConfig *record_config, char *record_filename);

void cs_command(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output);

void cs_mode(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output);


#endif /* TUNING_H_ */
