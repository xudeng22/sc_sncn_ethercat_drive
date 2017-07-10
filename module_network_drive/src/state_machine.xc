/**
 * @file state_machine.xc
 * @brief Motor Drive State Machine Implementation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <statemachine.h>
#include <state_modes.h>
#include <motion_control_service.h>
#include <mc_internal_constants.h>

#include "print.h"

int read_controlword_switch_on(int control_word) {
    return (control_word & SWITCH_ON_CONTROL);
}

int read_controlword_enable_voltage(int control_word) {
    return (control_word & ENABLE_VOLTAGE_CONTROL) >> 1;
}

int read_controlword_quick_stop(int control_word) {
    return (control_word & QUICK_STOP_CONTROL) >> 2;
}

int read_controlword_enable_op(int control_word) {
    return (control_word & ENABLE_OPERATION_CONTROL) >> 3;
}

int read_controlword_fault_reset(int control_word) {
    return (control_word & FAULT_RESET_CONTROL) >> 7;
}

bool ctrl_shutdown(int control_word) {
    return !read_controlword_switch_on(control_word)
        && read_controlword_enable_voltage(control_word)
        && read_controlword_quick_stop(control_word);
}

bool ctrl_switch_on(int control_word) {
    return read_controlword_switch_on(control_word)
        && read_controlword_enable_voltage(control_word)
        && read_controlword_quick_stop(control_word)
        && !read_controlword_enable_op(control_word);
}

bool ctrl_disable_volt(int control_word) {
    return !read_controlword_enable_voltage(control_word);
}

bool ctrl_quick_stop(int control_word) {
    return read_controlword_enable_voltage(control_word)
        && !read_controlword_quick_stop(control_word);
}

bool ctrl_disable_op(int control_word) {
    return read_controlword_switch_on(control_word)
        && read_controlword_enable_voltage(control_word)
        && read_controlword_quick_stop(control_word)
        && !read_controlword_enable_op(control_word);
}

bool ctrl_enable_op(int control_word) {
    return read_controlword_switch_on(control_word)
        && read_controlword_enable_voltage(control_word)
        && read_controlword_quick_stop(control_word)
        && read_controlword_enable_op(control_word);
}

bool ctrl_quick_stop_finished(int control) {
    return ((control & CTRL_QUICK_STOP_FINISHED) == 0 ? 0 : 1);
}

bool ctrl_fault_reaction_finished(int control)
{
    return ((control & CTRL_FAULT_REACTION_FINISHED) == 0 ? false : true);
}

bool ctrl_communication_timeout(int control) {
    return ((control & CTRL_COMMUNICATION_TIMEOUT) == 0 ? false : true);
}

bool __check_bdc_init(chanend c_signal)
{
    bool init_state;
    c_signal <: CHECK_BUSY;
    c_signal :> init_state;
    return init_state;
}

bool __check_adc_init()
{
    return 0;
}

check_list init_checklist(void)
{
    check_list check_list_param;

    check_list_param.fault = false;
    check_list_param.fault_reset_wait = false;
    return check_list_param;
}

void update_checklist(check_list &check_list_param, int mode, int fault)
{
    check_list_param.fault = fault;
}


int init_state(void) {
    return S_NOT_READY_TO_SWITCH_ON;
}

int16_t update_statusword(int current_status, DriveState_t state_reached, int ack, int q_active, int shutdown_ack) {
    int16_t status_word;

    //set quick stop bit to 0 when quick stop active
    if (q_active == 0)
        status_word |= (QUICK_STOP_STATE);
    else
        status_word &= (~QUICK_STOP_STATE);

    /* set/clear the corresponding bits in the statusword using this pattern:
     * status_word = (current_status
     *                & ~bit_to_clear & ~bit_to_clear & ... )
     *                | bit_to_set | bit_to_set | ... ;
     */
    switch (state_reached) {
        case S_NOT_READY_TO_SWITCH_ON:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE
                           & ~FAULT_STATE & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE & ~READY_TO_SWITCH_ON_STATE);
            break;

        case S_SWITCH_ON_DISABLED:
            status_word = (current_status
                           & ~FAULT_STATE & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE & ~READY_TO_SWITCH_ON_STATE)
                           | SWITCH_ON_DISABLED_STATE;
            break;

        case S_READY_TO_SWITCH_ON:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE & ~FAULT_STATE & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE)
                           | QUICK_STOP_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_SWITCH_ON:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE & ~FAULT_STATE & ~OPERATION_ENABLED_STATE)
                           | QUICK_STOP_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_OPERATION_ENABLE:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE & ~FAULT_STATE)
                           | QUICK_STOP_STATE | OPERATION_ENABLED_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_FAULT_REACTION_ACTIVE:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE)
                           | FAULT_STATE | OPERATION_ENABLED_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_FAULT:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE
                           & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE & ~READY_TO_SWITCH_ON_STATE)
                           | FAULT_STATE;
            break;

        case S_QUICK_STOP_ACTIVE:
            status_word = (current_status
                           & ~SWITCH_ON_DISABLED_STATE & ~QUICK_STOP_STATE & ~FAULT_STATE)
                           | OPERATION_ENABLED_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        default:
            status_word = current_status;
            break;
    }
    if (shutdown_ack == 1)
        return status_word & (~VOLTAGE_ENABLED_STATE);
    if (ack == 1)
        return status_word | TARGET_REACHED;
    else if (ack == 0)
        return status_word & (~TARGET_REACHED);

    return status_word;
}

/* localcontrol is used for internal (aka automatic) state transitions */
int get_next_state(int in_state, check_list &checklist, int controlword, int localcontrol) {
    int out_state = -1;

    switch(in_state)
    {
        case S_NOT_READY_TO_SWITCH_ON:
            if (checklist.fault != NO_FAULT)
                out_state = S_FAULT_REACTION_ACTIVE;
            else // transition 1 auto
                out_state = S_SWITCH_ON_DISABLED;
            break;

        case S_SWITCH_ON_DISABLED:
            if ( (checklist.fault != NO_FAULT) || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_shutdown(controlword)) // transition 2
                out_state = S_READY_TO_SWITCH_ON;
            else
                out_state = S_SWITCH_ON_DISABLED;
            break;

        case S_READY_TO_SWITCH_ON:
            if ( (checklist.fault != NO_FAULT) || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_switch_on(controlword)) // transition 3
                out_state = S_SWITCH_ON;
            else if ( (ctrl_disable_volt(controlword) || ctrl_quick_stop(controlword) )) // transition 7
                out_state = S_SWITCH_ON_DISABLED;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_READY_TO_SWITCH_ON;
            break;

        case S_SWITCH_ON:
            if ( (checklist.fault != NO_FAULT) || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_enable_op(controlword)) // transition 4
                out_state = S_OPERATION_ENABLE;
            else if (ctrl_switch_on(controlword)) //stay on the state
                out_state = S_SWITCH_ON;
            else if (ctrl_shutdown(controlword)) // transition 6
                out_state = S_READY_TO_SWITCH_ON;
            else if ( ctrl_disable_volt(controlword) || ctrl_quick_stop(controlword) ) // transition 10
                out_state = S_SWITCH_ON_DISABLED;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_SWITCH_ON;
            break;

        case S_OPERATION_ENABLE:
            if ( (checklist.fault != NO_FAULT) || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_disable_op(controlword)) // transition 5
                out_state = S_SWITCH_ON;
            else if (ctrl_shutdown(controlword)) // transition 8
                out_state = S_READY_TO_SWITCH_ON;
            else  if ( ctrl_quick_stop(controlword) ) // transition 11
                out_state = S_QUICK_STOP_ACTIVE;
            else if ( ctrl_disable_volt(controlword) ) // transition 9
                out_state = S_SWITCH_ON_DISABLED;
            else if ( ctrl_enable_op(controlword)) //stay on the state
                out_state = S_OPERATION_ENABLE;
            else if (ctrl_quick_stop(localcontrol)) // transition 11
                out_state = S_QUICK_STOP_ACTIVE;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_QUICK_STOP_ACTIVE; /* if we are running, then first do a quick stop */
            else
                out_state = S_OPERATION_ENABLE;
            break;

        case S_QUICK_STOP_ACTIVE:
            if ( (checklist.fault != NO_FAULT) || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_disable_volt(controlword)) // transition 12 (forced)
                out_state = S_SWITCH_ON_DISABLED; /* FIXME Warning: quick stop has to be finished before switch back to SOD */
            else if (ctrl_quick_stop_finished(localcontrol)) // transition 12 (auto)
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_QUICK_STOP_ACTIVE;
            break;

        case S_FAULT_REACTION_ACTIVE:
            if (ctrl_fault_reaction_finished(localcontrol)) // transition 14
                out_state = S_FAULT;
            else
                out_state = S_FAULT_REACTION_ACTIVE;

            break;

        case S_FAULT:
            if (read_controlword_fault_reset(controlword) && checklist.fault_reset_wait == false && !checklist.fault) { // transition 15
                out_state = S_SWITCH_ON_DISABLED;
            } else {
                out_state = S_FAULT;
            }
            break;
    }

    return out_state;
}


int8_t update_opmode(int8_t opmode, int8_t opmode_request,
        client interface MotionControlInterface i_motion_control,
        MotionControlConfig &motion_control_config,
        uint8_t polarity)
{
    if (opmode != opmode_request) {
        motion_control_config = i_motion_control.get_motion_control_config();
        motion_control_config.polarity = MOTION_POLARITY_NORMAL;
        switch(opmode_request) {
        case OPMODE_NONE:
        case OPMODE_CST:
        case OPMODE_SNCN_TUNING:
            break;
        //for CSP and CSV we also check the polarity object DICT_POLARITY (0x607E)
        case OPMODE_CSP:
            if (polarity & MOTION_POLARITY_POSITION) {
                motion_control_config.polarity = MOTION_POLARITY_INVERTED;
            }
            break;
        case OPMODE_CSV:
            if (polarity & MOTION_POLARITY_VELOCITY) {
                motion_control_config.polarity = MOTION_POLARITY_INVERTED;
            }
            break;
        default:
            opmode_request = OPMODE_NONE;
            break;
        }
        i_motion_control.set_motion_control_config(motion_control_config);
        return opmode_request;
    }
    return opmode;
}
