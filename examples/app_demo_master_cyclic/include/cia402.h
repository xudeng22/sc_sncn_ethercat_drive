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


CIA402State read_state(uint16_t statusword);

uint16_t go_to_state(CIA402State current_state, CIA402State state, uint16_t controlword);


#endif /* _CIA402_H */
