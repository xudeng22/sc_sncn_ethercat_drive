/**
 * @file statemachine.h
 * @brief Motor Drive defines and configurations
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <stdint.h>

#include <adc_service.h>
#include <motion_control_service.h>

//#include <position_feedback_service.h>


#define CTRL_QUICK_STOP_INIT           0x01
#define CTRL_QUICK_STOP_FINISHED       0x02
#define CTRL_COMMUNICATION_TIMEOUT     0x8000
#define CTRL_FAULT_REACTION_FINISHED   0x4000

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
    bool fault;
    bool fault_reset_wait;
} check_list;

typedef enum e_States {
    S_NOT_READY_TO_SWITCH_ON = 1,
    S_SWITCH_ON_DISABLED = 2,
    S_READY_TO_SWITCH_ON = 3,
    S_SWITCH_ON = 4,
    S_OPERATION_ENABLE = 5,
    S_QUICK_STOP_ACTIVE = 6,
    S_FAULT_REACTION_ACTIVE = 8,
    S_FAULT = 7
} states;

typedef states DriveState_t;

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
 * @param fault sets fault
 */
void update_checklist(check_list &check_list_param, int mode, int fault);


/**
 * @brief Update status word according to the current state of the statemachine
 *
 * @param current_status current statusword
 * @param state_reached current state of the statemachine
 * @param ack more internal state
 * @param q_active more internal state
 * @param shutdown_ack more internal state
 *
 * @return new statusword
 */
int16_t update_statusword(int current_status, DriveState_t state_reached, int ack, int q_active, int shutdown_ack);

/**
 * @brief Change state of the state machine according to master controlword and local conditions
 *
 * @param in_state current state
 * @param checklist local conditions checked before changing the state
 * @param controlword contains the control command from the master
 * @param localcontrol local command checked before changing the state
 *
 * @return new state
 */
int get_next_state(int in_state, check_list &checklist, int controlword, int localcontrol);

/**
 * @brief Update opmode, check if this opmode is supported
 *
 *  Also set the polarity if the new opmode it CSP or CSV
 *
 * @param opmode the current opmode
 * @param opmode_request the new opmode
 * @param i_motion_control client interface to the motion control
 * @param motion_control_config config of to the motion control
 * @param polarity CiA402 object 0x607E DICT_POLARITY
 * @param read_configuration to update configuration when switching to tuning mode
 *
 * @return new opmode, OPMODE_NONE if opmode is unsupported
 */
int8_t update_opmode(int8_t opmode, int8_t opmode_request,
        client interface MotionControlInterface i_motion_control,
        MotionControlConfig &motion_control_config,
        uint8_t polarity,
        int &read_configuration);

int read_controlword_switch_on(int control_word);

int read_controlword_quick_stop(int control_word);

int read_controlword_enable_op(int control_word);

int read_controlword_fault_reset(int control_word);

