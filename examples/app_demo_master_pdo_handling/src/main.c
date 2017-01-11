/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#define _XOPEN_SOURCE

#include <sncn_ethercat.h>
#include <sncn_slave.h>
#include <ecrt.h>
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <signal.h>
#include <sys/types.h>
#include <errno.h>
#include <sys/resource.h>
#include <string.h>

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

int main()
{
	int slave_number = 0;
	int blink = 0;

    struct sigaction sa;
    struct itimerval tv;

    FILE *ecatlog = fopen("./ecat.log", "w");

	/* Initialize EtherCAT Master */
    SNCN_Master_t *master = sncn_master_init(0, ecatlog);

    if (master == NULL) {
        fprintf(stderr, "Error could not initialize master\n");
        return -1;
    }

    unsigned int sendvalue = 0;

    /* only talk to slave 0
     * FIXME add usage of all slaves! */
    SNCN_Slave_t *slave = sncn_slave_get(master, 0);
    sncn_slave_set_out_value(slave, 0, sendvalue);

    sncn_master_start(master);
	printf("starting Master application\n");

    set_priority();
    setup_signal_handler(&sa);
    setup_timer(&tv);

	while(g_running) {
        pause();

        while (sig_alarms != user_alarms) {
            user_alarms++;

            sncn_master_cyclic_function(master);

            unsigned int received = (unsigned int)sncn_slave_get_in_value(slave, 0);
            if (received == sendvalue) {
                sendvalue++;
                sncn_slave_set_out_value(slave, 0, sendvalue);
            }
        }
	}

    sncn_master_release(master);
    fclose(ecatlog);

	return 0;
}



