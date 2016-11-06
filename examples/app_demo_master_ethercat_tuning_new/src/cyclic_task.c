
#include <stdint.h>
#include <stdio.h>
#include <curses.h> // required

#include "ecrt.h"

#include "cyclic_task.h"
#include "display.h"
#include "ecat_master.h"

#define FREQUENCY 1000

#define CTRLWORD_TRANSITION_2   0x0006
#define CTRLWORD_TRANSITION_3   0x0007
#define CTRLWORD_TRANSITION_4   0x000f
#define CTRLWORD_QUICKSTOP      0x0002

#define NUM_CIA402_SLAVES       6 /* FIXME parameter or something */

// EtherCAT
static ec_master_state_t master_state/* = {}*/;
static ec_domain_state_t domain1_state/* = {}*/;
static ec_slave_config_state_t sc_data_in_state;

static unsigned int counter = 0;

void check_domain1_state(ec_domain_t *domain1)
{
    ec_domain_state_t ds;
    ecrt_domain_state(domain1, &ds);
    domain1_state = ds;
}

void check_master_state(ec_master_t *master)
{
    ec_master_state_t ms;
    ecrt_master_state(master, &ms);
    master_state = ms;
}

void check_slave_config_states(ec_slave_config_t *sc_data_in)
{
    ec_slave_config_state_t s;
    ecrt_slave_config_state(sc_data_in, &s);
    sc_data_in_state = s;
}

int cyclic_task(struct _master_config *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output, int *target_position, WINDOW *wnd)
{
    uint16_t controlword[master->number_of_slaves];
    int32_t position_request[master->number_of_slaves];
    int my_super_flag[master->number_of_slaves];

    // receive process data
    ecrt_master_receive(master->master);
    ecrt_domain_process(master->domain1);

    // check process data state (optional)
    check_domain1_state(master->domain1);

    if (counter > 0) {
        counter--;
    } else { // do this at 1 Hz
        counter = FREQUENCY;

        // check for master state (optional)
        check_master_state(master->master);
    }

    for (int slaveid = 0; slaveid < master->number_of_slaves; slaveid++) {
        pd_get(master, slaveid, &pdo_input[slaveid]);
        if (pdo_input[slaveid].opmodedisplay == 0) {
            target_position[slaveid] = pdo_input[slaveid].actual_position;
        }

/* FIXME mock for new update slave handling */
#if 0
        slavestate[slaveid] = master_update_slave_state(master, slaveid,
                         (int *)&(statusword[slaveid]), (int *)&(controlword[slaveid]));
#endif

        position_request[slaveid] = target_position[slaveid];

        /* FIXME this mini statemachine should be per slave */
        if ((pdo_input[slaveid].statusword & 0x0008) == 0x0008) {
            controlword[slaveid] = 0x0080;  /* Fault reset */
            target_position[slaveid] = pdo_input[slaveid].actual_position;
        } else if ((pdo_input[slaveid].statusword & 0x004f) == 0x0040) {
            target_position[slaveid] = pdo_input[slaveid].actual_position;
            if (my_super_flag[slaveid] == 1) {
                controlword[slaveid] = 0;
            } else {
                controlword[slaveid] = CTRLWORD_TRANSITION_2;
                position_request[slaveid] = pdo_input[slaveid].actual_position;
            }
        } else if ((pdo_input[slaveid].statusword & 0x006f) == 0x0021) {
            controlword[slaveid] = CTRLWORD_TRANSITION_3;
            target_position[slaveid] = pdo_input[slaveid].actual_position;
            position_request[slaveid] = pdo_input[slaveid].actual_position;
        } else if ((pdo_input[slaveid].statusword & 0x006f) == 0x0023) {
            controlword[slaveid] = CTRLWORD_TRANSITION_4;
            target_position[slaveid] = pdo_input[slaveid].actual_position;
            position_request[slaveid] = target_position[slaveid];
        } else if ((pdo_input[slaveid].statusword & 0x006f) == 0x0027) {
            controlword[slaveid] = CTRLWORD_TRANSITION_4;
            position_request[slaveid] = target_position[slaveid];
        } else if ((pdo_input[slaveid].statusword & 0x006f) == 0x0007) {
            printf("******************** Quick Stop active *****************************************\n");
            controlword[slaveid] = CTRLWORD_QUICKSTOP;
            my_super_flag[slaveid] = 1;
        }

        pd_set_controlword(master, slaveid, controlword[slaveid]);
        pd_set_opmode(master, slaveid, 8);
        pd_set_position(master, slaveid, position_request[slaveid]);
    }


    // send process data
    ecrt_domain_queue(master->domain1);
    ecrt_master_send(master->master);

    return (target_position[0] - pdo_input[0].actual_position);
}

int pdo_handler(struct _master_config *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output)
{
    // receive process data
    ecrt_master_receive(master->master);
    ecrt_domain_process(master->domain1);

    // check process data state (optional)
    check_domain1_state(master->domain1);

    if (counter > 0) {
        counter--;
    } else { // do this at 1 Hz
        counter = FREQUENCY;

        // check for master state (optional)
        check_master_state(master->master);
    }

    for (int slaveid = 0; slaveid < master->number_of_slaves; slaveid++) {
        pd_get(master, slaveid, &pdo_input[slaveid]);
        pd_set(master, slaveid, pdo_output[slaveid]);
    }


    // send process data
    ecrt_domain_queue(master->domain1);
    ecrt_master_send(master->master);

    return 0;
}
