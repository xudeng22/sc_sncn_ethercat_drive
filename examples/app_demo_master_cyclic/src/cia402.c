
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

#define CONTROL_SHUTDOWN             0x06   /* masq 0x06 */
#define CONTROL_SWITCH_ON            0x07   /* masq 0x0f */
#define CONTROL_DISABLE_VOLTAGE      0x00   /* masq 0x02 */
#define CONTROL_QUICK_STOP           0x02   /* masq 0x06 */
#define CONTROL_DISABLE_OP           0x07   /* masq 0x0f */
#define CONTROL_ENABLE_OP            0x0f   /* masq 0x0f */
#define CONTROL_FAULT_RESET          0x80   /* masq 0x80 */

#define CONTROL_BIT_ENABLE_OP        0x08
#define CONTROL_BIT_QUICK_STOP       0x04
#define CONTROL_BIT_ENABLE_VOLTAGE   0x02
#define CONTROL_BIT_SWITCH_ON        0x01


/* Chack the slaves statemachine and generate the correct controlword */
CIA402State read_state(uint16_t statusword)
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

uint16_t go_to_state(CIA402State current_state, CIA402State state, uint16_t controlword)
{
    if (current_state != state) {
        if (state == CIASTATE_SWITCH_ON_DISABLED) { //enabde -> disable transitions
            switch(current_state) {
            case CIASTATE_FAULT:
                controlword |= CONTROL_FAULT_RESET;
                break;
            case CIASTATE_OP_ENABLED:
            case CIASTATE_SWITCHED_ON:
            case CIASTATE_READY_SWITCH_ON: //quick stop
                controlword = (controlword
                        & ~CONTROL_FAULT_RESET & ~CONTROL_BIT_QUICK_STOP)
                        | CONTROL_BIT_ENABLE_VOLTAGE;
                break;
            default:
                break;
            }
        } else if (state == CIASTATE_OP_ENABLED) { // disabled -> enabled transitions
            switch(current_state) {
            case CIASTATE_FAULT:
                controlword |= CONTROL_FAULT_RESET;
                break;
            case CIASTATE_SWITCH_ON_DISABLED: //shutdown command
                controlword = (controlword
                        & ~CONTROL_FAULT_RESET & ~CONTROL_BIT_SWITCH_ON)
                        | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE;
                break;
            case CIASTATE_READY_SWITCH_ON: //switch on
                controlword = (controlword
                        & ~CONTROL_FAULT_RESET & ~CONTROL_BIT_ENABLE_OP)
                        | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE | CONTROL_BIT_SWITCH_ON;
                break;
            case CIASTATE_SWITCHED_ON: //enable
                controlword = (controlword
                        & ~CONTROL_FAULT_RESET)
                        | CONTROL_BIT_ENABLE_OP | CONTROL_BIT_QUICK_STOP | CONTROL_BIT_ENABLE_VOLTAGE | CONTROL_BIT_SWITCH_ON;
                break;
            default:
                break;
            }
        }
    }

    return controlword;
}
