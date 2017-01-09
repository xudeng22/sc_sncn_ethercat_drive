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

/* FIXME should use slave type from sncn_slave.h */
enum eSlaveType {
    SLAVE_TYPE_UNKNOWN = 0
    ,SLAVE_TYPE_CIA402_DRIVE
    ,SLAVE_TYPE_ECATIO
};

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

/* FIXME how are the I/O PDOs set up in this mode? */
struct _pdo_digi_input {
    uint8_t  input_a_0:1;
    uint8_t  input_a_1:1;
    uint8_t  input_a_2:1;
    uint8_t  input_a_3:1;
    uint8_t  input_a_4:1;
    uint8_t  input_a_5:1;
    uint8_t  input_a_6:1;
    uint8_t  input_a_7:1;
    uint8_t  input_b_0:1;
    uint8_t  input_b_1:1;
    uint8_t  input_b_2:1;
    uint8_t  input_b_3:1;
    uint8_t  input_b_4:1;
    uint8_t  input_b_5:1;
    uint8_t  input_b_6:1;
    uint8_t  input_b_7:1;
};

struct _pdo_digi_output {
    uint8_t  output0:1;
    uint8_t  output1:1;
    uint8_t  output2:1;
    uint8_t  output3:1;
    uint8_t  output4:1;
    uint8_t  output5:1;
    uint8_t  output6:1;
    uint8_t  output7:1;
};

int master_update_slave_state(int *statusword, int *controlword);

/*
 * Access functions for SLAVE_TYPE_CIA402_DRIVE
 * return error if slave is of the wrong type!
 */
uint32_t pd_get_statusword(struct _master_config *master, int slaveid);
uint32_t pd_get_opmodedisplay(struct _master_config *master, int slaveid);
uint32_t pd_get_position(struct _master_config *master, int slaveid);
uint32_t pd_get_velocity(struct _master_config *master, int slaveid);
uint32_t pd_get_torque(struct _master_config *master, int slaveid);
uint32_t pd_get_user1_in(struct _master_config *master, int slaveid);
uint32_t pd_get_user2_in(struct _master_config *master, int slaveid);
uint32_t pd_get_user3_in(struct _master_config *master, int slaveid);
uint32_t pd_get_user4_in(struct _master_config *master, int slaveid);
void pd_get(struct _master_config *master, int slaveid, struct _pdo_cia402_input *pdo_input);

int pd_set_controlword(struct _master_config *master, int slaveid, uint32_t controlword);
int pd_set_opmode(struct _master_config *master, int slaveid, uint32_t opmode);
int pd_set_position(struct _master_config *master, int slaveid, uint32_t position);
int pd_set_velocity(struct _master_config *master, int slaveid, uint32_t velocity);
int pd_set_torque(struct _master_config *master, int slaveid, uint32_t torque);
int pd_set_user1_out(struct _master_config *master, int slaveid, uint32_t user_out);
int pd_set_user2_out(struct _master_config *master, int slaveid, uint32_t user_out);
int pd_set_user3_out(struct _master_config *master, int slaveid, uint32_t user_out);
int pd_set_user4_out(struct _master_config *master, int slaveid, uint32_t user_out);
void pd_set(struct _master_config *master, int slaveid, struct _pdo_cia402_output pdo_output);

/*
 * Access functions for SLAVE_TYPE_ECATIO
 * return error if slave is of the wrong type
 */

uint8_t pd_get_digital_input(struct _master_config *master, int slaveid);
int pd_set_digital_output(struct _master_config *master, int slaveid);


#ifdef __cplusplus
}
#endif

#endif /* _ECAT_CONFIG_H */
