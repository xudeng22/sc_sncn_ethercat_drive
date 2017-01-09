/*
 * ecat_master.h
 */

#ifndef _ECAT_CONFIG_H
#define _ECAT_CONFIG_H

#include <ecrt.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

enum eCIAState {
     CIASTATE_NOT_READY = 0
    ,CIASTATE_SWITCH_ON_DISABLED
    ,CIASTATE_READY_SWITCH_ON
    ,CIASTATE_SWITCHED_ON
    ,CIASTATE_OP_ENABLED
    ,CIASTATE_QUICK_STOP
    ,CIASTATE_FAULT_REACTION_ACTIVE
    ,CIASTATE_FAULT
};

struct _slave_config {
    int id;
    enum eSlaveType type;
    void *input;
    void *output;
};

struct _pdo_cia402_input {
    unsigned int statusword;
    unsigned int opmodedisplay;
    unsigned int actual_torque;
    unsigned int actual_position;
    unsigned int actual_velocity;
    unsigned int user_in_1;
    unsigned int user_in_2;
    unsigned int user_in_3;
    unsigned int user_in_4;
};

struct _pdo_cia402_output {
    unsigned int controlword;
    unsigned int opmode;
    unsigned int target_position;
    unsigned int target_velocity;
    unsigned int target_torque;
    unsigned int user_out_1;
    unsigned int user_out_2;
    unsigned int user_out_3;
    unsigned int user_out_4;
};


int master_update_slave_state(int *statusword, int *controlword);

/*
 * Access functions for SLAVE_TYPE_CIA402_DRIVE
 * return error if slave is of the wrong type!
 */
uint32_t pd_get_statusword(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_opmodedisplay(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_position(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_velocity(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_torque(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_user1_in(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_user2_in(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_user3_in(SNCN_Master_t *master, int slaveid);
uint32_t pd_get_user4_in(SNCN_Master_t *master, int slaveid);
void pd_get(SNCN_Master_t *master, int slaveid, struct _pdo_cia402_input *pdo_input);

int pd_set_controlword(SNCN_Master_t *master, int slaveid, uint32_t controlword);
int pd_set_opmode(SNCN_Master_t *master, int slaveid, uint32_t opmode);
int pd_set_position(SNCN_Master_t *master, int slaveid, uint32_t position);
int pd_set_velocity(SNCN_Master_t *master, int slaveid, uint32_t velocity);
int pd_set_torque(SNCN_Master_t *master, int slaveid, uint32_t torque);
int pd_set_user1_out(SNCN_Master_t *master, int slaveid, uint32_t user_out);
int pd_set_user2_out(SNCN_Master_t *master, int slaveid, uint32_t user_out);
int pd_set_user3_out(SNCN_Master_t *master, int slaveid, uint32_t user_out);
int pd_set_user4_out(SNCN_Master_t *master, int slaveid, uint32_t user_out);
void pd_set(SNCN_Master_t *master, int slaveid, struct _pdo_cia402_output pdo_output);

#ifdef __cplusplus
}
#endif

#endif /* _ECAT_CONFIG_H */
