/*
 * cia402.h
 *
 *
 * 2016-06-16, synapticon
 */

#ifndef _CIA402_H
#define _CIA402_H

#include <stdint.h>

#define OPMODE_NONE                  0
#define OPMODE_CSP                   8
#define OPMODE_CSV                   9
#define OPMODE_CST                   10

typedef enum {
     CIASTATE_NOT_READY = 0
    ,CIASTATE_SWITCH_ON_DISABLED
    ,CIASTATE_READY_SWITCH_ON
    ,CIASTATE_SWITCHED_ON
    ,CIASTATE_OP_ENABLED
    ,CIASTATE_QUICK_STOP
    ,CIASTATE_FAULT_REACTION_ACTIVE
    ,CIASTATE_FAULT
} CIA402State;

typedef enum {
    CIA402_CMD_NONE = 0,
    CIA402_CMD_SHUTDOWN,
    CIA402_CMD_SWITCH_ON,
    CIA402_CMD_DISABLE_VOLTAGE,
    CIA402_CMD_QUICK_STOP,
    CIA402_CMD_DISABLE_OPERATION,
    CIA402_CMD_ENABLE_OPERATION,
    CIA402_CMD_FAULT_RESET,
} CIA402Command;


CIA402State cia402_read_state(uint16_t statusword);

uint16_t cia402_command(CIA402Command command, uint16_t controlword);

uint16_t cia402_go_to_state(CIA402State target_state, CIA402State current_state , uint16_t controlword, int skip_state);


#endif /* _CIA402_H */
