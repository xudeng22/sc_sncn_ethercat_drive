/*
 * ecat_master.c
 */

#include "ecat_master.h"
#include <ecrt.h>
#include <stdint.h>
#include <stdio.h>

static struct _master_config master;

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
        slave->input  = malloc(sizeof(struct _pdo_digi_input));
        slave->output = malloc(sizeof(struct _pdo_digi_output));
        break;

    case SLAVE_TYPE_UNKNOWN:
    default:
        fprintf(stderr, "[ERROR %s] Unknown slave type\n", __func__);
        return -1;
    }

    return 0;
}

static ec_pdo_entry_reg_t *get_domain_regs_for_slaves(struct _master_config *master, size_t slave_count, ec_domain_t *domain)
{
    const int alias = 0;
    const int subindex = 0;

/* FIXME make more dynamically! */
#define MAX_NUMBER_PDOS   150
#define SOMANET_ID        0x000022d2, 0x00000201
    ec_pdo_entry_reg_t *domain_regs = malloc(MAX_NUMBER_PDOS * sizeof(ec_pdo_entry_reg_t));
    size_t domainregcount = 0;

    struct _slave_config *slaves = master->slave;

    for (size_t slave_id = 0; slave_id < slave_count; slave_id++) {
        struct _slave_config *slave = (slaves + slave_id);

        struct _pdo_cia402_output *pdo_output;
        struct _pdo_cia402_input  *pdo_input;


        switch (slave->type) {
        case SLAVE_TYPE_CIA402_DRIVE:
            /* FIXME make list of used indexes */
            pdo_output = (struct _pdo_cia402_output *)(slave->output);
            pdo_input  = (struct _pdo_cia402_input *)(slave->input);

            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6040, subindex, &(pdo_output->controlword), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6060, subindex, &(pdo_output->opmode), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6071, subindex, &(pdo_output->target_torque), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x607a, subindex, &(pdo_output->target_position), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x60ff, subindex, &(pdo_output->target_velocity), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4010, subindex, &(pdo_output->user_out_1), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4020, subindex, &(pdo_output->user_out_2), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4030, subindex, &(pdo_output->user_out_3), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4040, subindex, &(pdo_output->user_out_4), NULL };

            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6041, subindex, &(pdo_input->statusword), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6061, subindex, &(pdo_input->opmodedisplay), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6064, subindex, &(pdo_input->actual_position), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x606c, subindex, &(pdo_input->actual_velocity), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x6077, subindex, &(pdo_input->actual_torque), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4011, subindex, &(pdo_input->user_in_1), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4021, subindex, &(pdo_input->user_in_2), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4031, subindex, &(pdo_input->user_in_3), NULL };
            domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ alias, slave_id, SOMANET_ID, 0x4041, subindex, &(pdo_input->user_in_4), NULL };

            break;

        case SLAVE_TYPE_ECATIO:
            fprintf(stderr, "[FAILED %s] Sorry, type ECATIO not yet supported\n", __func__);
            return NULL;
            break;

        case SLAVE_TYPE_UNKNOWN:
        default:
            fprintf(stderr, "[ERROR %s] Registering domain pointers failed\n", __func__);
            return NULL;
        }
    }

    domain_regs[domainregcount++] = (ec_pdo_entry_reg_t){ 0 };
    return domain_regs;
}

struct _master_config *master_config(int number_of_slaves)
{
    master.master = ecrt_request_master(0); /* FIXME actually only use first master */
    master.domain1 = ecrt_master_create_domain(master.master);
    master.number_of_slaves = number_of_slaves;

    // for each slave:
    //ec_slave_config_t *sc_data_in = ecrt_master_slave_config(master.master, 0, slave, SOMANET_ID)

    master.slave = malloc(number_of_slaves * sizeof(struct _slave_config));

    /* configure slaves */
    for (int i = 0; i < number_of_slaves; i++) {
        struct _slave_config *slave = master.slave + i;

        if (get_slave_config(i, SLAVE_TYPE_CIA402_DRIVE, slave) != 0) {
            fprintf(stderr, "[ERROR %s] Unable to set slave configuration (slave %i)\n", __func__, i);
            return NULL;
        }
    }

    ec_pdo_entry_reg_t *domain1_regs = get_domain_regs_for_slaves(&master, number_of_slaves, master.domain1); /* FIXME */
    if (domain1_regs == NULL) {
        fprintf(stderr, "[ERROR %s] cannot register PDOs to domain\n", __func__);
        return NULL;
    }

    /* Configure PDOs */
    if (ecrt_domain_reg_pdo_entry_list(master.domain1, domain1_regs)) {
        fprintf(stderr, "[ERROR %s] PDO entry registration failed\n", __func__);
        return NULL;
    }

    master.processdata = NULL;

    return &master;
}

int master_start(struct _master_config *master)
{
    printf("Starting master...");

    if (ecrt_master_activate(master->master)) {
        fprintf(stderr, "[ERROR %s] Unable ot activate master\n", __func__);
        return -1;
    }

    if (!(master->processdata = ecrt_domain_data(master->domain1))) {
        fprintf(stderr, "[ERROR %s] Cannot access process data space\n", __func__);
        return -1;
    }

    return 0;
}

int master_stop(struct _master_config *master)
{
    /* ecrt_master_deactivate() cleans up everything that was used for
     * the master application, during this process the pointers to the
     * generated structures become invalid. */
    master->processdata = NULL;
    master->domain1 = NULL;
    //free(master->processdata);
    //free(master->domain1);
    ecrt_master_deactivate(master->master);
    return 0;
}

void master_free(struct _master_config *master)
{
    /* thse two are cleaned during ecrt_master_deactivate() which is called
     * internally in ecrt_release_master() or in a previous call to master_stop() */
    master->processdata = NULL;
    master->domain1 = NULL;

    ecrt_release_master(master->master);
    free(master->slave);
    //free(master);
    return;
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
int master_update_slave_state(struct _master_config *master, int slaveid,
                                int *statusword, int *controlword)
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

/*
 * PDO access functions
 */

uint32_t pd_get_statusword(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U16(master->processdata + input->statusword);
}

uint32_t pd_get_opmodedisplay(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U16(master->processdata + input->opmodedisplay);
}

uint32_t pd_get_position(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->actual_position);
}

uint32_t pd_get_velocity(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->actual_velocity);
}

uint32_t pd_get_torque(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U16(master->processdata + input->actual_torque);
}

uint32_t pd_get_user1_in(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->user_in_1);
}
uint32_t pd_get_user2_in(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->user_in_2);
}
uint32_t pd_get_user3_in(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->user_in_3);
}
uint32_t pd_get_user4_in(struct _master_config *master, int slaveid)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_input *input  = (struct _pdo_cia402_input *)slave->input;

    return EC_READ_U32(master->processdata + input->user_in_4);
}

int pd_set_controlword(struct _master_config *master, int slaveid, uint32_t controlword)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U16(master->processdata + output->controlword, controlword & 0xffff);

    return 0;
}

int pd_set_opmode(struct _master_config *master, int slaveid, uint32_t opmode)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U16(master->processdata + output->opmode, opmode & 0xffff);

    return 0;
}

int pd_set_position(struct _master_config *master, int slaveid, uint32_t position)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->target_position, position & 0xffffffff);

    return 0;
}

int pd_set_torque(struct _master_config *master, int slaveid, uint32_t torque)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->target_torque, torque & 0xffffffff);

    return 0;
}

int pd_set_velocity(struct _master_config *master, int slaveid, uint32_t velocity)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->target_velocity, velocity & 0xffffffff);

    return 0;
}

int pd_set_user1_out(struct _master_config *master, int slaveid, uint32_t user_out)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->user_out_1, user_out & 0xffffffff);

    return 0;
}

int pd_set_user2_out(struct _master_config *master, int slaveid, uint32_t user_out)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->user_out_2, user_out & 0xffffffff);

    return 0;
}

int pd_set_user3_out(struct _master_config *master, int slaveid, uint32_t user_out)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->user_out_3, user_out & 0xffffffff);

    return 0;
}

int pd_set_user4_out(struct _master_config *master, int slaveid, uint32_t user_out)
{
    struct _slave_config *slave = (master->slave + slaveid);
    struct _pdo_cia402_output *output  = (struct _pdo_cia402_output *)slave->output;

    EC_WRITE_U32(master->processdata + output->user_out_4, user_out & 0xffffffff);

    return 0;
}

void pd_get(struct _master_config *master, int slaveid, struct _pdo_cia402_input *pdo_input)
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

void pd_set(struct _master_config *master, int slaveid, struct _pdo_cia402_output pdo_output)
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

