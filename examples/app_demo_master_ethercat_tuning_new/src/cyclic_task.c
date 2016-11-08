
#include <stdint.h>
#include <stdio.h>

#include "ecrt.h"

#include "cyclic_task.h"
#include "ecat_master.h"

#define FREQUENCY 1000

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

int pdo_handler(struct _master_config *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output, int slaveid)
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

    if (slaveid >= 0 && slaveid < master->number_of_slaves) {
        pd_get(master, slaveid, &pdo_input[slaveid]);
        pd_set(master, slaveid, pdo_output[slaveid]);
    } else {
        for (int i = 0; i < master->number_of_slaves; i++) {
            pd_get(master, i, &pdo_input[i]);
            pd_set(master, i, pdo_output[i]);
        }
    }

    // send process data
    ecrt_domain_queue(master->domain1);
    ecrt_master_send(master->master);

    return 0;
}
