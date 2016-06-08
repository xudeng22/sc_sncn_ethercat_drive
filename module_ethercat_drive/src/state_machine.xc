/**
 * @file state_machine.xc
 * @brief Motor Drive State Machine Implementation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <statemachine.h>
#include <state_modes.h>
#include <position_ctrl_service.h>

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
        && read_controlword_quick_stop(control_word);
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
        && !read_controlword_enable_voltage(control_word);
}

bool ctrl_enable_op(int control_word) {
    return read_controlword_switch_on(control_word)
        && read_controlword_enable_voltage(control_word)
        && read_controlword_quick_stop(control_word)
        && read_controlword_enable_voltage(control_word);
}

bool ctrl_quick_stop_enable(int control) {
    return ((control & CTRL_QUICK_STOP_INIT) == 0 ? 0 : 1);
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

    switch (state_reached) {
        case S_NOT_READY_TO_SWITCH_ON:
            //printstrln("Warning reaching state which is not supposed to be reached!\n");
            /* FIXME double check if this makes sense */
            status_word = current_status & ~READY_TO_SWITCH_ON_STATE
                & ~SWITCHED_ON_STATE & ~OPERATION_ENABLED_STATE
                & ~VOLTAGE_ENABLED_STATE;
            break;

        case S_SWITCH_ON_DISABLED:
            status_word = (current_status & ~READY_TO_SWITCH_ON_STATE
                           & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE
                           & ~VOLTAGE_ENABLED_STATE & ~FAULT_STATE) | SWITCH_ON_DISABLED_STATE;
            break;

        case S_READY_TO_SWITCH_ON:
            status_word = (current_status & ~OPERATION_ENABLED_STATE
                           & ~SWITCHED_ON_STATE & ~VOLTAGE_ENABLED_STATE
                           & ~SWITCH_ON_DISABLED_STATE) | QUICK_STOP_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_SWITCH_ON:
            status_word = (current_status & ~SWITCH_ON_DISABLED_STATE
                           & ~OPERATION_ENABLED_STATE) | QUICK_STOP_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE
                           | VOLTAGE_ENABLED_STATE;
            break;

        case S_OPERATION_ENABLE:
            status_word = current_status | QUICK_STOP_STATE | OPERATION_ENABLED_STATE | SWITCHED_ON_STATE | READY_TO_SWITCH_ON_STATE;
            break;

        case S_FAULT_REACTION_ACTIVE:
            status_word = (current_status & ~FAULT_REACTION_ACTIVE_MASQ) | FAULT_REACTION_ACTIVE_STATE; /* Note: guarantee bits which has to be '0' are '0' */
            break;

        case S_FAULT:
            status_word = (current_status& ~FAULT_MASQ) | FAULT_STATE; /* Note: guarantee bits which has to be '0' are '0' */
            break;

        case S_QUICK_STOP_ACTIVE:
            status_word = current_status | QUICK_STOP_STATE;
            break;

    }

    if (q_active == 1)
        return status_word & (~QUICK_STOP_STATE);
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
    int ctrl_input;

    switch(in_state)
    {
        case S_NOT_READY_TO_SWITCH_ON:
            if (checklist.fault)
                out_state = S_FAULT_REACTION_ACTIVE;
            else 
                out_state = S_SWITCH_ON_DISABLED;
            break;

        case S_SWITCH_ON_DISABLED:
            if (checklist.fault || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_shutdown(controlword)) // aka ready
                out_state = S_READY_TO_SWITCH_ON;
            else
                out_state = S_SWITCH_ON_DISABLED;
            break;

        case S_READY_TO_SWITCH_ON:
            ctrl_input = read_controlword_switch_on(controlword);
            if (checklist.fault || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_switch_on(controlword))
                out_state = S_SWITCH_ON;
            //else if (ctrl_shutdown(controlword))
            //    out_state = S_READY_TO_SWITCH_ON;
            else if ( (ctrl_disable_volt(controlword) || ctrl_quick_stop(controlword) ))
                out_state = S_SWITCH_ON_DISABLED;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_READY_TO_SWITCH_ON;
            break;

        case S_SWITCH_ON:
            ctrl_input = read_controlword_enable_op(controlword);
            if (checklist.fault || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_enable_op(controlword))
                out_state = S_OPERATION_ENABLE;
            else if (ctrl_switch_on(controlword))
                out_state = S_SWITCH_ON;
            else if (ctrl_shutdown(controlword))
                out_state = S_READY_TO_SWITCH_ON;
            else if ( ctrl_disable_volt(controlword) || ctrl_quick_stop(controlword) )
                out_state = S_SWITCH_ON_DISABLED;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_SWITCH_ON;
            break;

        case S_OPERATION_ENABLE:
            ctrl_input = read_controlword_quick_stop(controlword); //quick stop
            if (checklist.fault || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_disable_op(controlword))
                out_state = S_SWITCH_ON;
            else if (ctrl_shutdown(controlword))
                out_state = S_READY_TO_SWITCH_ON;
            else  if ( ctrl_quick_stop(controlword) )
                out_state = S_QUICK_STOP_ACTIVE;
            else if ( ctrl_disable_volt(controlword) )
                out_state = S_SWITCH_ON_DISABLED;
            else if ( ctrl_enable_op(controlword))
                out_state = S_OPERATION_ENABLE;
            else if (ctrl_quick_stop_enable(localcontrol))
                out_state = S_QUICK_STOP_ACTIVE;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_QUICK_STOP_ACTIVE; /* if we are running, then first do a quick stop */
            else
                out_state = S_OPERATION_ENABLE;
            break;

        case S_QUICK_STOP_ACTIVE:
            if (checklist.fault || ctrl_communication_timeout(localcontrol))
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_disable_volt(controlword))
                out_state = S_SWITCH_ON_DISABLED; /* FIXME Warning: quick stop has to be finished before switch back to SOD */
            else if (ctrl_quick_stop_finished(localcontrol))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_QUICK_STOP_ACTIVE;
            break;

        case S_FAULT_REACTION_ACTIVE:
            if (ctrl_fault_reaction_finished(localcontrol))
                out_state = S_FAULT;
            else
                out_state = S_FAULT_REACTION_ACTIVE;

            break;

        case S_FAULT:
            ctrl_input = read_controlword_fault_reset(controlword);
            if (!ctrl_input)
                out_state = S_FAULT;
            else
                out_state = S_SWITCH_ON_DISABLED;
            break;
    }

    return out_state;
}
