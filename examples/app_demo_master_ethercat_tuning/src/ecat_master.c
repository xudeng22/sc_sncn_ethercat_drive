/*
 * ecat_master.c
 */

#include "ecat_master.h"
#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
#include <ecrt.h>
#include <stdint.h>
#include <stdio.h>

/*
 * CiA402 State defines
 */

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

/*
 * Indexes of PDO elements
 */
#define PDO_INDEX_STATUSWORD                  0
#define PDO_INDEX_OPMODEDISP                  1
#define PDO_INDEX_POSITION_VALUE              2
#define PDO_INDEX_VELOCITY_VALUE              3
#define PDO_INDEX_TORQUE_VALUE                4
#define PDO_INDEX_SECONDARY_POSITION_VALUE    5
#define PDO_INDEX_SECONDARY_VELOCITY_VALUE    6
#define PDO_INDEX_ANALOG_INPUT1               7
#define PDO_INDEX_ANALOG_INPUT2               8
#define PDO_INDEX_ANALOG_INPUT3               9
#define PDO_INDEX_ANALOG_INPUT4              10
#define PDO_INDEX_TUNING_STATUS              11
#define PDO_INDEX_DIGITAL_INPUT1             12
#define PDO_INDEX_DIGITAL_INPUT2             14
#define PDO_INDEX_DIGITAL_INPUT3             16
#define PDO_INDEX_DIGITAL_INPUT4             18
#define PDO_INDEX_USER_MISO                  20
#define PDO_INDEX_TIMESTAMP                  21

/* Index of sending (out) PDOs */
#define PDO_INDEX_CONTROLWORD                 0
#define PDO_INDEX_OPMODE                      1
#define PDO_INDEX_TORQUE_REQUEST              2
#define PDO_INDEX_POSITION_REQUEST            3
#define PDO_INDEX_VELOCITY_REQUEST            4
#define PDO_INDEX_OFFSET_TORQUE               5
#define PDO_INDEX_TUNING_COMMAND              6
#define PDO_INDEX_DIGITAL_OUTPUT1             7
#define PDO_INDEX_DIGITAL_OUTPUT2             9
#define PDO_INDEX_DIGITAL_OUTPUT3            11
#define PDO_INDEX_DIGITAL_OUTPUT4            13
#define PDO_INDEX_USER_MOSI                  15


/* Chack the slaves statemachine and generate the correct controlword */
enum eCIAState read_state(uint16_t statusword)
{
    enum eCIAState slavestate = CIASTATE_NOT_READY;

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

uint16_t go_to_state(enum eCIAState current_state, enum eCIAState state, uint16_t controlword)
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

/*
 * PDO access functions
 */

uint32_t pd_get_statusword(Ethercat_Master_t *master, int slaveid)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
}

uint32_t pd_get_opmodedisplay(Ethercat_Master_t *master, int slaveid)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_OPMODEDISP);
}

uint32_t pd_get_position(Ethercat_Master_t *master, int slaveid)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_POSITION_VALUE);
}

uint32_t pd_get_velocity(Ethercat_Master_t *master, int slaveid)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_VELOCITY_VALUE);
}

uint32_t pd_get_torque(Ethercat_Master_t *master, int slaveid)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_TORQUE_VALUE);
}

int pd_set_controlword(Ethercat_Master_t *master, int slaveid, uint32_t controlword)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, controlword);
}

int pd_set_opmode(Ethercat_Master_t *master, int slaveid, uint32_t opmode)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return ecw_slave_set_out_value(slave, PDO_INDEX_OPMODE, opmode);
}

int pd_set_position(Ethercat_Master_t *master, int slaveid, uint32_t position)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return ecw_slave_set_out_value(slave, PDO_INDEX_POSITION_REQUEST, position);
}

int pd_set_torque(Ethercat_Master_t *master, int slaveid, uint32_t torque)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return ecw_slave_set_out_value(slave, PDO_INDEX_TORQUE_REQUEST, torque);
}

int pd_set_velocity(Ethercat_Master_t *master, int slaveid, uint32_t velocity)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    return ecw_slave_set_out_value(slave, PDO_INDEX_VELOCITY_REQUEST, velocity);
}

void pd_get(Ethercat_Master_t *master, int slaveid, struct _pdo_cia402_input *pdo_input)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);

    pdo_input->statusword = (uint16_t)ecw_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
    pdo_input->op_mode_display = (int8_t)ecw_slave_get_in_value(slave, PDO_INDEX_OPMODEDISP);
    pdo_input->position_value = (int32_t)ecw_slave_get_in_value(slave, PDO_INDEX_POSITION_VALUE);
    pdo_input->velocity_value = (int32_t)ecw_slave_get_in_value(slave, PDO_INDEX_VELOCITY_VALUE);
    pdo_input->torque_value = (int16_t)ecw_slave_get_in_value(slave, PDO_INDEX_TORQUE_VALUE);
    pdo_input->secondary_position_value = (int32_t)ecw_slave_get_in_value(slave, PDO_INDEX_SECONDARY_POSITION_VALUE);
    pdo_input->secondary_velocity_value = (int32_t)ecw_slave_get_in_value(slave, PDO_INDEX_SECONDARY_VELOCITY_VALUE);
    pdo_input->analog_input1 = (uint16_t)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT1);
    pdo_input->analog_input2 = (uint16_t)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT2);
    pdo_input->analog_input3 = (uint16_t)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT3);
    pdo_input->analog_input4 = (uint16_t)ecw_slave_get_in_value(slave, PDO_INDEX_ANALOG_INPUT4);
    pdo_input->tuning_status = (int32_t)ecw_slave_get_in_value(slave, PDO_INDEX_TUNING_STATUS);
    pdo_input->digital_input1 = (uint8_t)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT1);
    pdo_input->digital_input2 = (uint8_t)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT2);
    pdo_input->digital_input3 = (uint8_t)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT3);
    pdo_input->digital_input4 = (uint8_t)ecw_slave_get_in_value(slave, PDO_INDEX_DIGITAL_INPUT4);
    pdo_input->user_miso = (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_USER_MISO);
    pdo_input->timestamp = (uint32_t)ecw_slave_get_in_value(slave, PDO_INDEX_TIMESTAMP);

    return;
}

void pd_set(Ethercat_Master_t *master, int slaveid, struct _pdo_cia402_output pdo_output)
{
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);

    ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, pdo_output.controlword);
    ecw_slave_set_out_value(slave, PDO_INDEX_OPMODE, pdo_output.op_mode);
    ecw_slave_set_out_value(slave, PDO_INDEX_TORQUE_REQUEST, pdo_output.target_torque);
    ecw_slave_set_out_value(slave, PDO_INDEX_POSITION_REQUEST, pdo_output.target_position);
    ecw_slave_set_out_value(slave, PDO_INDEX_VELOCITY_REQUEST, pdo_output.target_velocity);
    ecw_slave_set_out_value(slave, PDO_INDEX_OFFSET_TORQUE, pdo_output.offset_torque);
    ecw_slave_set_out_value(slave, PDO_INDEX_TUNING_COMMAND, pdo_output.tuning_command);
    ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT1, pdo_output.digital_output1);
    ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT2, pdo_output.digital_output2);
    ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT3, pdo_output.digital_output3);
    ecw_slave_set_out_value(slave, PDO_INDEX_DIGITAL_OUTPUT4, pdo_output.digital_output4);
    ecw_slave_set_out_value(slave, PDO_INDEX_USER_MOSI, pdo_output.user_mosi);

    return;
}

