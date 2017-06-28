/*
 * ecat_master.h
 */

#ifndef _ECAT_CONFIG_H
#define _ECAT_CONFIG_H

#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
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
    uint16_t statusword;
    int8_t op_mode_display;
    int32_t position_value;
    int32_t velocity_value;
    int16_t torque_value;
    int32_t secondary_position_value;
    int32_t secondary_velocity_value;
    uint16_t analog_input1;
    uint16_t analog_input2;
    uint16_t analog_input3;
    uint16_t analog_input4;
    uint32_t tuning_status;
    uint8_t digital_input1;
    uint8_t digital_input2;
    uint8_t digital_input3;
    uint8_t digital_input4;
    uint32_t user_miso;
    uint32_t timestamp;
};

struct _pdo_cia402_output {
    uint16_t controlword;
    int8_t op_mode;
    int16_t target_torque;
    int32_t target_position;
    int32_t target_velocity;
    int32_t offset_torque;
    uint32_t tuning_command;
    uint8_t digital_output1;
    uint8_t digital_output2;
    uint8_t digital_output3;
    uint8_t digital_output4;
    uint32_t user_mosi;
};


enum eCIAState read_state(uint16_t statusword);

uint16_t go_to_state(enum eCIAState current_state, enum eCIAState state, uint16_t controlword);

/*
 * Access functions for SLAVE_TYPE_CIA402_DRIVE
 * return error if slave is of the wrong type!
 */
uint32_t pd_get_statusword(Ethercat_Master_t *master, int slaveid);
uint32_t pd_get_opmodedisplay(Ethercat_Master_t *master, int slaveid);
uint32_t pd_get_position(Ethercat_Master_t *master, int slaveid);
uint32_t pd_get_velocity(Ethercat_Master_t *master, int slaveid);
uint32_t pd_get_torque(Ethercat_Master_t *master, int slaveid);
void pd_get(Ethercat_Master_t *master, int slaveid, struct _pdo_cia402_input *pdo_input);

int pd_set_controlword(Ethercat_Master_t *master, int slaveid, uint32_t controlword);
int pd_set_opmode(Ethercat_Master_t *master, int slaveid, uint32_t opmode);
int pd_set_position(Ethercat_Master_t *master, int slaveid, uint32_t position);
int pd_set_velocity(Ethercat_Master_t *master, int slaveid, uint32_t velocity);
int pd_set_torque(Ethercat_Master_t *master, int slaveid, uint32_t torque);
void pd_set(Ethercat_Master_t *master, int slaveid, struct _pdo_cia402_output pdo_output);

#ifdef __cplusplus
}
#endif

#endif /* _ECAT_CONFIG_H */
