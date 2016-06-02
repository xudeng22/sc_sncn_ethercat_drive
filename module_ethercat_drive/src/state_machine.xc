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
    return ((contol & CTRL_COMMUNICATION_TIMEOUT) == 0 ? false : true);
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
    check_list_param._adc_init = INIT_BUSY;
    check_list_param._commutation_init = INIT_BUSY;
    check_list_param._hall_init = INIT_BUSY;
    check_list_param._position_init = INIT_BUSY;
    check_list_param._qei_init = INIT_BUSY;
    check_list_param._torque_init = INIT_BUSY;
    check_list_param._velocity_init = INIT_BUSY;

    check_list_param.mode_op = false;
    check_list_param.fault = false;
    check_list_param.operation_enable = false;
    check_list_param.ready = false;
    check_list_param.switch_on = false;
    return check_list_param;
}

void update_checklist(check_list &check_list_param, int mode,
                        interface MotorcontrolInterface client i_motorcontrol,
                        interface HallInterface client ?i_hall,
                        interface QEIInterface client ?i_qei,
                        interface BISSInterface client ?i_biss,
                        interface AMSInterface client ?i_ams,
                        interface ADCInterface client ?i_adc,
                        interface TorqueControlInterface client ?i_torque_control,
                        interface VelocityControlInterface client i_velocity_control,
                        interface PositionControlInterface client i_position_control)
{
    bool check;
    bool skip = true;
    check =  check_list_param._commutation_init 
        & check_list_param._hall_init & check_list_param._qei_init;

    switch(check) {
        case INIT_BUSY:
            if (~check_list_param._commutation_init) {
                check_list_param._commutation_init = i_motorcontrol.check_busy();
                if(check_list_param._commutation_init) {
                    skip = false;
                }
            }

            if (~skip && ~check_list_param._adc_init) {
                check_list_param._adc_init = 0; // TODO NEED TO IMPLEMENT STATUS CHECKING HERE
            }

            if (~skip && ~check_list_param._hall_init && !isnull(i_hall)) {
                check_list_param._hall_init = i_hall.check_busy();
            }

            if (~skip &&  ~check_list_param._qei_init && !isnull(i_qei)) {
                check_list_param._qei_init = i_qei.check_busy();
            }

            if (~skip &&  ~check_list_param._biss_init && !isnull(i_biss)) {
                i_biss.get_biss_position_fast();
                check_list_param._biss_init = INIT;
            }
            if (~skip &&  ~check_list_param._ams_init && !isnull(i_ams)) {
                i_ams.get_ams_position();
                check_list_param._ams_init = INIT;
            }
            break;
        case INIT:
            if (~check_list_param._torque_init && mode == 1) {
                check_list_param._torque_init = i_torque_control.check_busy();
            }
            if (~check_list_param._velocity_init && mode == 2) {
                check_list_param._velocity_init = i_velocity_control.check_busy();
            }
            if (~check_list_param._position_init && mode == 3) {
                check_list_param._position_init = i_position_control.check_busy();
            }
            break;
    }

    if (check_list_param._commutation_init && ~check_list_param.fault) {
        check_list_param.ready = true;
    }

    if (check_list_param.ready 
        && (check_list_param._hall_init || isnull(i_hall)) 
        && (check_list_param._qei_init || isnull(i_qei)) 
        && (check_list_param._biss_init || isnull(i_biss)) 
        && (check_list_param._ams_init || isnull(i_ams)) && ~check_list_param.fault) 
    {
        check_list_param.switch_on = true;
        check_list_param.mode_op = true;
        check_list_param.operation_enable = true;
    }
}

int init_state(void) {
    return S_NOT_READY_TO_SWITCH_ON;
}

int16_t update_statusword(int current_status, int state_reached, int ack, int q_active, int shutdown_ack) {
    int16_t status_word;

    switch (state_reached) {
        case S_NOT_READY_TO_SWITCH_ON:
            //printstrln("Warning reaching state which is not supposed to be reached!\n");
            status_word = current_status & ~READY_TO_SWITCH_ON_STATE
                & ~SWITCHED_ON_STATE & ~OPERATION_ENABLED_STATE
                & ~VOLTAGE_ENABLED_STATE;
            break;

        case S_READY_TO_SWITCH_ON:
            status_word = (current_status & ~OPERATION_ENABLED_STATE
                           & ~SWITCHED_ON_STATE & ~VOLTAGE_ENABLED_STATE
                           & ~SWITCH_ON_DISABLED_STATE) | READY_TO_SWITCH_ON_STATE;
            break;

        case S_SWITCH_ON_DISABLED:
            status_word = (current_status & READY_TO_SWITCH_ON_STATE
                           & ~OPERATION_ENABLED_STATE & ~SWITCHED_ON_STATE
                           & ~VOLTAGE_ENABLED_STATE) | SWITCH_ON_DISABLED_STATE;
            break;

        case S_SWITCH_ON:
            status_word = (current_status & ~SWITCH_ON_DISABLED_STATE
                           & ~OPERATION_ENABLED_STATE) | SWITCHED_ON_STATE
                           | VOLTAGE_ENABLED_STATE;
            break;

        case S_OPERATION_ENABLE:
            status_word = current_status | OPERATION_ENABLED_STATE;
            break;

        case S_FAULT_REACTION_ACTIVE:
            status_word = (current_status & ~(FAULT_REACTION_ACTIVE_MASQ)) | FAULT_REACTION_ACTIVE_STATE; /* Note: garantee bits which has to be '0' are '0' */
            break;

        case S_FAULT:
            status_word = (current_status& ~(FAULT_MASQ)) | FAULT_STATE; /* Note: garantee bits which has to be '0' are '0' */
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
            if (checklist.fault)
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_shutdown(controlword) || checklist.ready) // aka ready
                out_state = S_READY_TO_SWITCH_ON;
            else
                out_state = S_SWITCH_ON_DISABLED;
            break;

        case S_READY_TO_SWITCH_ON:
            ctrl_input = read_controlword_switch_on(controlword);
            if (checklist.fault)
                out_state = S_FAULT_REACTION_ACTIVE;
            else if (ctrl_switch_on(controlword))
                out_state = S_SWITCH_ON;
            //else if (ctrl_shutdown(controlword))
            //    out_state = S_READY_TO_SWITCH_ON;
            else if ( (ctrl_disable_volt(controlword) || ctrl_quick_stop(controlword) ) && !checklist.ready)
                out_state = S_SWITCH_ON_DISABLED;
            else if (ctrl_communication_timeout(controlword))
                out_state = S_SWITCH_ON_DISABLED;
            else
                out_state = S_READY_TO_SWITCH_ON;
            break;

        case S_SWITCH_ON:
            ctrl_input = read_controlword_enable_op(controlword);
            if (checklist.fault)
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
            if (checklist.fault)
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
            if (checklist.fault)
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
