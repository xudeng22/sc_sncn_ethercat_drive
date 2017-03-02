/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#define _XOPEN_SOURCE

#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
#include <ecrt.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <signal.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/resource.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

#define MAX_UINT16                  0xffff
#define MAX_UINT32                  0xffffffff

#define CMD_NORMAL_OP     0
#define CMD_LIST_SLVAVES  1

/* Index of receiving (in) PDOs */
#define PDO_INDEX_STATUSWORD        0
#define PDO_INDEX_USER_MISO        20

/* Index of sending (out) PDOs */
#define PDO_INDEX_CONTROLWORD       0
#define PDO_INDEX_USER_MOSI        15

#define MAX_WAIT_LOOPS            1000

#define BUILD_REQUEST(a, b, c)       (((a & 0xffff) << 16) | ((b & 0xff) << 8) | (c & 0xff))

static int g_running = 1;
static unsigned int sig_alarms  = 0;
static unsigned int user_alarms = 0;

/* set eventually higher priority */


static void set_priority(void)
{
    if (getuid() != 0) {
        fprintf(stderr, "Warning, be root to get higher priority\n");
        return;
    }

    pid_t pid = getpid();
    if (setpriority(PRIO_PROCESS, pid, -19))
        fprintf(stderr, "Warning: Failed to set priority: %s\n",
                strerror(errno));
}

/* Signal handling */

void signal_handler(int signum) {
    switch (signum) {
        case SIGINT:
        case SIGTERM:
            g_running = 0;
            break;
        case SIGALRM:
            sig_alarms++;
            break;
    }
}

static void setup_signal_handler(struct sigaction *sa)
{
    /* setup signal handler */
    sa->sa_handler = signal_handler;
    sigemptyset(&(sa->sa_mask));
    sa->sa_flags = 0;
    if (sigaction(SIGALRM, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }

    if (sigaction(SIGTERM, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }

    if (sigaction(SIGINT, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }
}

static void setup_timer(struct itimerval *tv)
{
    /* setup timer */
    tv->it_interval.tv_sec = 0;
    tv->it_interval.tv_usec = 1000000 / 1000;
    tv->it_value.tv_sec = 0;
    tv->it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }
}

static void print_usage(char *prog)
{
    char *basename = prog;
    char *c = basename;
    while (*c != '\0') {
        c++;
        if (*c == '/')
            basename = c;
    }

    printf("Usage: %s [-h] [-v] [-m <id>] [-n <id>] [-c] [-l]\n", basename);
}

static void parse_cmd_line(int argc, char *argv[], int *nodeid, int *command, int *masterid, int *cyclic)
{
    const char *optargs = "hVvn:lm:c";

    int opt = 0;

    while ((opt = getopt(argc, argv, optargs)) != -1) {
        switch (opt) {
        case 'n':
            *nodeid = atoi(optarg);
            break;

        case 'l':
            *command = CMD_LIST_SLVAVES;
            break;

        case 'm':
            *masterid = atoi(optarg);
            break;

        case 'c':
            *cyclic = 1;
            break;

        case 'h':
            print_usage(argv[0]);
            exit(0);

        case 'v': /* verbosity */
            /* FIXME set verbosity */

        case 'V': /* version??? */
            /* FIXME print version and exit */

        default:
            fprintf(stderr, "Error, parse command line option\n");
            exit(-1);
        }
    }
}

static void list_slaves(Ethercat_Master_t *master)
{
    int slave_count = ecw_master_slave_count(master);

    for (int i = 0; i < slave_count; i++) {
        Ethercat_Slave_t *slave = ecw_slave_get(master, i);

        Ethercat_Slave_Info_t info;
        ecw_slave_get_info(slave, &info);

        printf("%d: VID: 0x%.4x PID: 0x%.x \"%s\"\n", i, info.vendor_id, info.product_code, info.name);
    }
}

static int cyclic_operation(Ethercat_Master_t *master, Ethercat_Slave_t *slave)
{
    struct sigaction sa;
    struct itimerval tv;

    ecw_master_start(master);
	printf("starting Master application\n");

    set_priority();
    setup_signal_handler(&sa);
    setup_timer(&tv);

    uint16_t     statusword = 0;
    uint32_t     user_miso = 0;

    int get_master_identity = 1;
    size_t waitcounter = MAX_WAIT_LOOPS;

    uint32_t request_object = BUILD_REQUEST(0x1018, 1, 0);

	while(g_running) {
        pause();

        while (sig_alarms != user_alarms) {
            user_alarms++;

            ecw_master_cyclic_function(master);

            switch (get_master_identity) {
            case 1:
                printf("Send request to fetch object 0x%04x:%d\n", (request_object >> 16) & 0xffff, (request_object >> 8) & 0xff);
                ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, 1);
                ecw_slave_set_out_value(slave, PDO_INDEX_USER_MOSI, request_object);
                get_master_identity += 1;
                waitcounter = MAX_WAIT_LOOPS;
                break;

            case 2:
                statusword = ecw_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
                if (statusword == 1) {
                    user_miso = ecw_slave_get_in_value(slave, PDO_INDEX_USER_MISO);
                    printf("0x%04x:%d = 0x%x\n", (request_object >> 16) & 0xffff, (request_object >> 8) & 0xff, user_miso);

                    if (request_object == BUILD_REQUEST(0x1018, 2, 0)) {
                        get_master_identity = 0; /* finished */
                    } else {
                        request_object = BUILD_REQUEST(0x1018, 2, 0);
                        get_master_identity += 1;
                    }
                } else {
                    waitcounter--;
                    if (waitcounter <= 1) {
                        printf("Error receive requested object\n");
                        ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, 0);
                        ecw_slave_set_out_value(slave, PDO_INDEX_USER_MOSI, 0);
                        get_master_identity = 0;
                        waitcounter = MAX_WAIT_LOOPS;
                    }
                }
                break;

            case 3:
                ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, 0);
                get_master_identity += 1;
                waitcounter = MAX_WAIT_LOOPS;
                break;

            case 4:
                /* Wait until slave resets and is able to serve new requests */
                statusword = ecw_slave_get_in_value(slave, PDO_INDEX_STATUSWORD);
                if (statusword == 0) {
                    waitcounter = MAX_WAIT_LOOPS;
                    get_master_identity = 1;
                    printf("Slave recovered.\n");
                } else {
                    waitcounter--;
                    if (waitcounter <= 1) {
                        printf("Slave does not recover, giving up.\n");
                        get_master_identity = 0;
                    }
                }
                break;

            default:
                ecw_slave_set_out_value(slave, PDO_INDEX_CONTROLWORD, 0);
                ecw_slave_set_out_value(slave, PDO_INDEX_USER_MOSI, 0);
                break;
            }
        }
	}

	return 0;
}

static void printsdoinfo(Sdo_t *sdo)
{
    printf("  Index:    0x%04x\n",    sdo->index);
    printf("  Subindex: %d\n",        sdo->subindex);
    printf("  Name:     %s\n",        sdo->name);
    printf("  Value:    %d (0x%x)\n", sdo->value, sdo->value);

    int read_access  = (sdo->read_access[0]  + sdo->read_access[1]  + sdo->read_access[2]);
    int write_access = (sdo->write_access[0] + sdo->write_access[1] +  sdo->write_access[2]);
    if (((3 > read_access) && (read_access > 0)) || ((3 > write_access) && (write_access > 0)))
        fprintf(stderr, "Warning accessrights different for some EtherCAT states\n");

    printf("  Read Access:   %s\n", (read_access  > 0) ? "yes" : "no");
    printf("  Write Access:  %s\n", (write_access > 0) ? "yes" : "no");
}

static int object_test_write(Ethercat_Slave_t *slave, Sdo_t *sdo)
{
    int success     = 1; /* 0 = success; 1 = failed */
    int testvalue   = 1;
    int value       = 0;
    int backupvalue = 0;

    if (ecw_slave_get_sdo_value(slave, sdo->index, sdo->subindex, &value) != 0) {
        fprintf(stderr, "Error could not access object 0x%04x:%d on slave %d\n",
            sdo->index, sdo->subindex, ecw_slave_get_slaveid(slave));
        return -1;
    }

    int write_access = (sdo->write_access[0] + sdo->write_access[1] +  sdo->write_access[2]);

    if (ecw_slave_set_sdo_value(slave, sdo->index, sdo->subindex, testvalue) != 0) {
        if (write_access == 0) {
            success = 0;
        } else {
            success = 1;
        }
    }

    backupvalue = value;
    ecw_slave_get_sdo_value(slave, sdo->index, sdo->subindex, &value);
//printf("[DEBUG] value = %d; testvalue = %d; backupvalue = %d\n", value, testvalue, backupvalue);
    if (value == testvalue) {
        if (write_access == 0) {
            fprintf(stderr, "Written non-writeable object 0x%04x:%d\n", sdo->index, sdo->subindex);
            success = 1;
        } else {
            success = 0;
        }
    } else {
        if (write_access == 0) {
            success = 0;
        } else {
            fprintf(stderr, "Unable to write writeable object 0x%04x:%d\n", sdo->index, sdo->subindex);
            success = 1;
        }
    }

    /* reset the original value */
    ecw_slave_set_sdo_value(slave, sdo->index, sdo->subindex, backupvalue);

    return success;
}

static int access_object_dictionary(Ethercat_Slave_t *slave)
{
    size_t sdocount = ecw_slave_get_sdo_count(slave);
    Sdo_t **sdolist = malloc(sdocount * sizeof(Sdo_t *));

    for (size_t i = 0; i < sdocount; i++) {
        sdolist[i] = ecw_slave_get_sdo_index(slave, i);

        if (sdolist[i] == NULL) {
            printf("Warning object nubmer %lu not available\n", i);
        } else {
            printf("Object position: %lu\n", i);
            printsdoinfo(sdolist[i]);
        }
    }

    for (size_t i = 0; i < sdocount; i++) {
        if (sdolist[i]->index >= 0x2000) {
            int ret = object_test_write(slave, sdolist[i]);
            printf("Test 0x%04x:%d - %s\n",
                    sdolist[i]->index, sdolist[i]->subindex,
                    (ret == 0) ? "success" : "failed");
        }
    }

    return 0;
}

int main(int argc, char *argv[])
{
    int check_object_dictionary = 1;
    int startcyclic             = 0;
    int masterid                = 0;
    int slaveid                 = 0;
    int command                 = CMD_NORMAL_OP;

    /* FIXME use getopt(1) with -h, -v etc. * /
    if (argc > 1) {
        slaveid =  atoi(argv[1]);
    }
    */
    parse_cmd_line(argc, argv, &slaveid, &command, &masterid, &startcyclic);

    FILE *ecatlog = fopen("./ecat.log", "w");

	/* Initialize EtherCAT Master */
    Ethercat_Master_t *master = ecw_master_init(masterid, ecatlog);
    if (master == NULL) {
        fprintf(stderr, "Error, could not initialize master\n");
        return -1;
    }

    if (command == CMD_LIST_SLVAVES) {
        list_slaves(master);
        ecw_master_release(master);
        fclose(ecatlog);
        return 0;
    }

    size_t slave_count = ecw_master_slave_count(master);

    if (slave_count < ((unsigned int)slaveid + 1)) {
        fprintf(stderr, "Error only %lu slaves present, requested slave (%d) not available!\n",
                slave_count, slaveid);
        return -1;
    }

    printf("Testing slave %d on master %d.\n", slaveid, masterid);

    if (master == NULL) {
        fprintf(stderr, "Error could not initialize master\n");
        return -1;
    }

    /* only talk to specified slave */
    Ethercat_Slave_t *slave = ecw_slave_get(master, slaveid);
    if (slave == NULL) {
        fprintf(stderr, "Error could not retrieve slave %d", slaveid);
        return -1;
    }

    if (check_object_dictionary) {
        if (access_object_dictionary(slave)) {
            printf("Warning, something went wrong - cyclic operation is not started!\n");
            startcyclic = 0;
        }
    }

    if (startcyclic) {
        cyclic_operation(master, slave);
    }


    ecw_master_release(master);
    fclose(ecatlog);

    return 0;
}
