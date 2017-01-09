/*
 * ecat_master.c
 */

#include "ecat_master.h"
#include <sncn_ethercat.h>
#include <sncn_slave.h>
#include <ecrt.h>
#include <stdint.h>
#include <stdio.h>

/* FIMXE ??? */
static int get_slave_config(int id, enum eSlaveType type, struct _slave_config *slave)
{
    slave->id = id;
    slave->type = type;

    switch (type) {
    case SLAVE_TYPE_CIA402_DRIVE:
        slave->input  = malloc(sizeof(struct _pdo_cia402_input));
        slave->output = malloc(sizeof(struct _pdo_cia402_output));
        break;

    case SLAVE_TYPE_ECATIO:
        fprintf(stderr, "[ERROR %s] EtherCAT I/O is not supported for motor tuning\n", __func__);
        return -1;

    case SLAVE_TYPE_UNKNOWN:
    default:
        fprintf(stderr, "[ERROR %s] Unknown slave type\n", __func__);
        return -1;
    }

    return 0;
}


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

/* Chack the slaves statemachine and generate the correct controlword */
int master_update_slave_state(int *statusword, int *controlword)
{
    static int my_super_flag = 0;
    enum eCIAState slavestate = CONTROL_FAULT_RESET;

    if ((*statusword & STATUS_WORD_MASQ_A) == STATUS_FAULT) {         /* fault active */
        *controlword = CONTROL_FAULT_RESET;  /* Fault reset */
        slavestate = CIASTATE_FAULT;
    } else if ((*statusword & STATUS_WORD_MASQ_B) == STATUS_SWITCH_ON_DISABLED) {  /* slave ready to switch on */
        if (my_super_flag == 1) {
            *controlword = CONTROL_DISABLE_VOLTAGE;  /* stay in this state */
        } else {
            *controlword = CONTROL_SHUTDOWN;
        }
        slavestate = CIASTATE_SWITCH_ON_DISABLED;
    } else if ((*statusword & STATUS_WORD_MASQ_A) == STATUS_READY_SWITCH_ON) {  /* slave ready to switch on */
        *controlword = CONTROL_DISABLE_OP;
        slavestate = CIASTATE_READY_SWITCH_ON;
    } else if ((*statusword & STATUS_WORD_MASQ_A) == STATUS_SWITCHED_ON) {
        *controlword = CONTROL_ENABLE_OP;
        slavestate = CIASTATE_SWITCHED_ON;
    } else if ((*statusword & STATUS_WORD_MASQ_A) == STATUS_OP_ENABLED) {
        *controlword = CONTROL_ENABLE_OP;
        slavestate = CIASTATE_OP_ENABLED;
    } else if ((*statusword & STATUS_WORD_MASQ_A) == STATUS_QUICK_STOP) { /* Quick Stop */
        *controlword = CONTROL_QUICK_STOP;
        my_super_flag = 1;
        slavestate = CIASTATE_QUICK_STOP;
    }

    return slavestate;
}

#define PDO_INDEX_STATUSWORD       0
#define PDO_INDEX_OPMODEDISP       1
#define PDO_INDEX_POSITION_VALUE   2
#define PDO_INDEX_VELOCITY_VALUE   3
#define PDO_INDEX_TORQUE_VALUE     4
#define PDO_INDEX_USER_IN_1        5
#define PDO_INDEX_USER_IN_2        6
#define PDO_INDEX_USER_IN_3        7
#define PDO_INDEX_USER_IN_4        8

/*
 * PDO access functions
 */

uint32_t pd_get_statusword(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
}

uint32_t pd_get_opmodedisplay(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_OPMODEDISP);
}

uint32_t pd_get_position(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_POSITION_VALUE);
}

uint32_t pd_get_velocity(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_VELOCITY_VALUE);
}

uint32_t pd_get_torque(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_TORQUE_VALUE);
}

uint32_t pd_get_user1_in(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_USER_IN_1);
}
uint32_t pd_get_user2_in(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_USER_IN_2);
}
uint32_t pd_get_user3_in(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_USER_IN_3);
}
uint32_t pd_get_user4_in(SNCN_Master_t *master, int slaveid)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return (uint32_t)sncn_slave_get_in_value(slave, PDO_INDEX_USER_IN_4);
}

#define PDO_INDEX_CONTROLWORD       0
#define PDO_INDEX_OPMODE            1
#define PDO_INDEX_TORQUE_REQUEST    2
#define PDO_INDEX_POSITION_REQUEST  3
#define PDO_INDEX_VELOCITY_REQUEST  4
#define PDO_INDEX_USER_OUT_1        5
#define PDO_INDEX_USER_OUT_2        6
#define PDO_INDEX_USER_OUT_3        7
#define PDO_INDEX_USER_OUT_4        8

int pd_set_controlword(SNCN_Master_t *master, int slaveid, uint32_t controlword)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, controlword);
}

int pd_set_opmode(SNCN_Master_t *master, int slaveid, uint32_t opmode)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_OPMODE, opmode);
}

int pd_set_position(SNCN_Master_t *master, int slaveid, uint32_t position)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_POSITION_REQUEST, position);
}

int pd_set_torque(SNCN_Master_t *master, int slaveid, uint32_t torque)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_TORQUE_REQUEST, torque);
}

int pd_set_velocity(SNCN_Master_t *master, int slaveid, uint32_t velocity)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_VELOCITY_REQUEST, velocity);
}

int pd_set_user1_out(SNCN_Master_t *master, int slaveid, uint32_t user_out)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_USER_OUT_1, user_out);
}

int pd_set_user2_out(SNCN_Master_t *master, int slaveid, uint32_t user_out)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_USER_OUT_2, user_out);
}

int pd_set_user3_out(SNCN_Master_t *master, int slaveid, uint32_t user_out)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_USER_OUT_3, user_out);
}

int pd_set_user4_out(SNCN_Master_t *master, int slaveid, uint32_t user_out)
{
    SNCN_Slave_t *slave = sncn_slave_get(master, slaveid);
    return sncn_slave_set_out_value(slave, PDO_INDEX_USER_OUT_4, user_out);
}

void pd_get(SNCN_Master_t *master, int slaveid, struct _pdo_cia402_input *pdo_input)
{
    (*pdo_input).statusword = pd_get_statusword(master, slaveid);
    (*pdo_input).opmodedisplay = pd_get_opmodedisplay(master, slaveid);
    (*pdo_input).actual_position = pd_get_position(master, slaveid);
    (*pdo_input).actual_velocity = pd_get_velocity(master, slaveid);
    (*pdo_input).actual_torque = pd_get_torque(master, slaveid);
    (*pdo_input).user_in_1 = pd_get_user1_in(master, slaveid);
    (*pdo_input).user_in_2 = pd_get_user2_in(master, slaveid);
    (*pdo_input).user_in_3 = pd_get_user3_in(master, slaveid);
    (*pdo_input).user_in_4 = pd_get_user4_in(master, slaveid);

    return;
}

void pd_set(SNCN_Master_t *master, int slaveid, struct _pdo_cia402_output pdo_output)
{
    pd_set_controlword(master, slaveid, pdo_output.controlword);
    pd_set_opmode(master, slaveid, pdo_output.opmode);
    pd_set_position(master, slaveid, pdo_output.target_position);
    pd_set_velocity(master, slaveid, pdo_output.target_velocity);
    pd_set_torque(master, slaveid, pdo_output.target_torque);
    pd_set_user1_out(master, slaveid, pdo_output.user_out_1);
    pd_set_user2_out(master, slaveid, pdo_output.user_out_2);
    pd_set_user3_out(master, slaveid, pdo_output.user_out_3);
    pd_set_user4_out(master, slaveid, pdo_output.user_out_4);

    return;
}

