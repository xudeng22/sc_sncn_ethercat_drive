/**
 * @file statemachine.h
 * @brief Motor Drive defines and configurations
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <stdint.h>
//#include <stdbool_xc.h>

#include <adc_service.h>

#include <position_ctrl_service.h>
#include <velocity_ctrl_service.h>
#include <torque_ctrl_service.h>

typedef int bool;
#define true 1
#define false 0

//#define S_NOT_READY_TO_SWITCH_ON    1
//#define S_SWITCH_ON_DISABLED        2
//#define S_READY_TO_SWITCH_ON        7
//#define S_SWITCH_ON                 3
//#define S_OPERATION_ENABLE          4
//#define S_FAULT                     5
//#define S_QUICK_STOP                6

typedef struct S_Check_list {
    bool ready;
    bool switch_on;
    bool operation_enable;
    bool mode_op;
    bool fault;

    bool _commutation_init;
    bool _hall_init;
    bool _qei_init;
    bool _biss_init;
    bool _ams_init;
    bool _adc_init;
    bool _torque_init;
    bool _velocity_init;
    bool _position_init;
} check_list;

typedef enum e_States {
    S_NOT_READY_TO_SWITCH_ON = 1,
    S_SWITCH_ON_DISABLED = 2,
    S_READY_TO_SWITCH_ON = 7,
    S_SWITCH_ON = 3,
    S_OPERATION_ENABLE = 4,
    S_FAULT = 5,
    S_QUICK_STOP = 6
} states;

bool __check_bdc_init(chanend c_signal);

int init_state(void);

/**
 * @brief Initialize checklist params
 *
 * @return check_list initialized checklist parameters
 */
check_list init_checklist(void);

/**
 * @brief Update Checklist
 *
 * @param check_list_param Check List to be updated
 * @param mode sets mode of operation
 * @param i_motorcontrol Interface to Commutation Service
 * @param i_hall Interface to Hall Service
 * @param i_qei Interface to Incremental Encoder Service
 * @param i_biss Interface to BiSS Encoder Service
 * @param i_adc Interface to ADC Service
 * @param i_torque_control Interface to Torque Control Service
 * @param i_velocity_control Interface to Velocity Control Service
 * @param i_position_control Interface to Position Control Service
 *
 */
void update_checklist(check_list &check_list_param, int mode,
                        interface MotorcontrolInterface client i_motorcontrol,
                        interface HallInterface client ?i_hall,
                        interface QEIInterface client ?i_qei,
                        interface BISSInterface client ?i_biss,
                        interface AMSInterface client ?i_ams,
                        interface ADCInterface client ?i_adc,
                        interface TorqueControlInterface client ?i_torque_control,
                        interface VelocityControlInterface client i_velocity_control,
                        interface PositionControlInterface client i_position_control);

int16_t update_statusword(int current_status, int state_reached, int ack, int q_active, int shutdown_ack);

int get_next_state(int in_state, check_list &checklist, int controlword);

int read_controlword_switch_on(int control_word);

int read_controlword_quick_stop(int control_word);

int read_controlword_enable_op(int control_word);

int read_controlword_fault_reset(int control_word);

