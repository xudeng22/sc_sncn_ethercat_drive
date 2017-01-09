
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

int pdo_handler(SNCN_Master_t *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output, int slaveid)
{
    if (counter > 0) {
        counter--;
    } else { // do this at 1 Hz
        counter = FREQUENCY;
    }

    size_t number_of_slaves = sncn_master_slave_count(master);

    if (slaveid >= 0 && slaveid < number_of_slaves) {
        pd_get(master, slaveid, &pdo_input[slaveid]);
        pd_set(master, slaveid, pdo_output[slaveid]);
    } else {
        for (int i = 0; i < number_of_slaves; i++) {
            pd_get(master, i, &pdo_input[i]);
            pd_set(master, i, pdo_output[i]);
        }
    }

    return 0;
}
