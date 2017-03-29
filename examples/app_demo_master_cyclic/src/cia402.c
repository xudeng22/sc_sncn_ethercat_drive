
/*
 * CiA402 State defines
 */

#include "cia402.h"

#define STATUS_WORD_MASQ_A           0x6f
#define STATUS_WORD_MASQ_B           0x4f

#define STATUS_NOT_READY             0x00   /* masq B */
#define STATUS_SWITCH_ON_DISABLED    0x40   /* masq B */
#define STATUS_READY_SWITCH_ON       0x21
#define STATUS_SWITCHED_ON           0x23
#define STATUS_OP_ENABLED            0x27
#define STATUS_QUICK_STOP            0x07
#define STATUS_FAULT_REACTION_ACTIVE 0x0f   /* masq B */
#define STATUS_FAULT                 0x08   /* masq B */

#define CONTROL_BIT_ENABLE_OP        0x08
#define CONTROL_BIT_QUICK_STOP       0x04
#define CONTROL_BIT_ENABLE_VOLTAGE   0x02
#define CONTROL_BIT_SWITCH_ON        0x01
#define CONTROL_BIT_FAULT_RESET      0x80



CIA402State cia402_read_state(uint16_t statusword)
{
    CIA402State slavestate = CIASTATE_NOT_READY;

    uint16_t status_test = statusword & STATUS_WORD_MASQ_B;
    switch(status_test) {
    case STATUS_NOT_READY:
        slavestate = CIASTATE_NOT_READY;
        break;
    case STATUS_SWITCH_ON_DISABLED:
        slavestate = CIASTATE_SWITCH_ON_DISABLED;
        break;
    case STATUS_FAULT_REACTION_ACTIVE:
        slavestate = CIASTATE_FAULT_REACTION_ACTIVE;
        break;
    case STATUS_FAULT:
        slavestate = CIASTATE_FAULT;
        break;
    default:
        status_test = statusword & STATUS_WORD_MASQ_A;
        switch(status_test) {
        case STATUS_READY_SWITCH_ON:
            slavestate = CIASTATE_READY_SWITCH_ON;
            break;
        case STATUS_SWITCHED_ON:
            slavestate = CIASTATE_SWITCHED_ON;
            break;
        case STATUS_OP_ENABLED:
            slavestate = CIASTATE_OP_ENABLED;
            break;
        case STATUS_QUICK_STOP:
            slavestate = CIASTATE_QUICK_STOP;
            break;
        }
        break;
    }
    return slavestate;
}


uint16_t cia402_command(CIA402Command command, uint16_t controlword)
{
    switch(command) {
    case CIA402_CMD_SHUTDOWN:
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET & ~CONTROL_BIT_SWITCH_ON)
                | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE;
        break;
    case CIA402_CMD_SWITCH_ON:
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET & ~CONTROL_BIT_ENABLE_OP)
                | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE | CONTROL_BIT_SWITCH_ON;
        break;
    case CIA402_CMD_DISABLE_VOLTAGE:
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET & ~CONTROL_BIT_ENABLE_VOLTAGE);
        break;
    case CIA402_CMD_QUICK_STOP: //quick stop
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET & ~CONTROL_BIT_QUICK_STOP)
                | CONTROL_BIT_ENABLE_VOLTAGE;
        break;
    case CIA402_CMD_DISABLE_OPERATION: //same as switch on
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET & ~CONTROL_BIT_ENABLE_OP)
                | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE | CONTROL_BIT_SWITCH_ON;
        break;
    case CIA402_CMD_ENABLE_OPERATION: //enable
        controlword = (controlword
                & ~CONTROL_BIT_FAULT_RESET)
                | CONTROL_BIT_ENABLE_OP | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE | CONTROL_BIT_SWITCH_ON;
        break;
    case CIA402_CMD_FAULT_RESET:
        controlword |= CONTROL_BIT_FAULT_RESET;
        break;
    case CIA402_CMD_NONE:
        break;
    }
    return controlword;
}

/* Check the slaves statemachine and generate the correct controlword */
uint16_t cia402_go_to_state(CIA402State target_state, CIA402State current_state , uint16_t controlword, uint16_t force_command)
{
    /* There are only 4 possible states we want to go:
     * SWITCH_ON_DISABLED -> READY_SWITCH_ON -> CIASTATE_SWITCHED_ON -> OP_ENABLED
     * with SWITCH_ON_DISABLED the lowest and OP_ENABLED the highest state
     * The other state transition are automatic, or the fault state
     * So we have only 4 options:
     *  - we are in the fault state so we send the reset fault command
     *  - we are one of the 4 states and we want to go to a higher state
     *  - we are one of the 4 states and we want to go to a lower state
     *  - we are in an other state (quick stop, fault reaction, no ready to switch on)
     *    and we just wait for the automatic transition
     * */


    if (current_state == CIASTATE_FAULT) {
        /* reset fault */
        controlword = cia402_command(CIA402_CMD_FAULT_RESET, controlword);
    } else if (CIASTATE_SWITCH_ON_DISABLED <= current_state && current_state <= CIASTATE_OP_ENABLED && current_state < target_state) { // disabled -> enabled transitions
        /* Those are the disabled to enable transitions
         * There is only one way to do it:
         * SWITCH_ON_DISABLED -> READY_SWITCH_ON -> CIASTATE_SWITCHED_ON -> OP_ENABLED
         * */
        switch(current_state) {
        case CIASTATE_SWITCH_ON_DISABLED: //transition 2: shutdown command
            controlword = cia402_command(CIA402_CMD_SHUTDOWN, controlword);
            break;
        case CIASTATE_READY_SWITCH_ON: //transition 3: switch on command
            controlword = cia402_command(CIA402_CMD_SWITCH_ON, controlword);
            break;
        case CIASTATE_SWITCHED_ON: //transition 4: enable operation command
            controlword = cia402_command(CIA402_CMD_ENABLE_OPERATION, controlword);
            break;
        default:
            break;
        }
    } else if (CIASTATE_SWITCH_ON_DISABLED <= current_state && current_state <= CIASTATE_OP_ENABLED && current_state > target_state) { //enabled -> disabled transitions
        /* Those are the enabled to disabled transitions.
         * There are multiple ways to do it.
         * We can follow the same path in reverse: OP_ENABLED -> SWITCHED_ON -> READY_SWITCH_ON -> SWITCH_ON_DISABLED
         * Use the quick stop: OP_ENABLED -> QUICK_STOP -> SWITCH_ON_DISABLED
         * Skip states by using the disable voltage command: OP_ENABLED/SWITCHED_ON/READY_SWITCH_ON -> SWITCH_ON_DISABLED
         * Or also OP_ENABLED -> READY_SWITCH_ON (shutdown command)
         * We select the path using the force_command argument
         * */
        if (force_command == CIA402_CMD_DISABLE_VOLTAGE) {
            controlword = cia402_command(CIA402_CMD_DISABLE_VOLTAGE, controlword);
        } else { // normal reverse path
            switch(current_state) {
            // in OP_ENABLED state we have three possible transitions
            case CIASTATE_OP_ENABLED:
                if (force_command == CIA402_CMD_SHUTDOWN) {
                    controlword = cia402_command(CIA402_CMD_SHUTDOWN, controlword);
                } else if (force_command == CIA402_CMD_DISABLE_OPERATION) {
                    controlword = cia402_command(CIA402_CMD_DISABLE_OPERATION, controlword);
                } else { // by default we use the quick stop
                    controlword = cia402_command(CIA402_CMD_QUICK_STOP, controlword);
                }
                break;
            case CIASTATE_SWITCHED_ON:
                controlword = cia402_command(CIA402_CMD_SHUTDOWN, controlword);
                break;
            case CIASTATE_READY_SWITCH_ON:
                controlword = cia402_command(CIA402_CMD_DISABLE_VOLTAGE, controlword);
                break;
            default: //if in any other state just wait
                break;
            }
        }
    }
    return controlword;
}
