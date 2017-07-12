/*
 * utils.c
 *
 *  Created on: Mar 29, 2017
 *      Author: synapticon
 */

#include "utils.h"

static inline const char *_basename(const char *prog)
{
    const char *p = prog;
    const char *i = p;
    for (i = p; *i != '\0'; i++) {
        if (*i == '/')
            p = i+1;
    }

    return p;
}

static void printversion(const char *prog, const char *version)
{
    printf("%s %s\n", _basename(prog), version);
}

static void printhelp(const char *prog)
{
    printf("Usage: %s [-h] [-v] [-o] [-c <SDO config filename>] [-s <profile velocity>]\n", _basename(prog));
    printf("\n");
    printf("  -h                          print this help and exit\n");
    printf("  -o                          enable sdo upload\n");
    printf("  -v                          print version and exit\n");
    printf("  -d                          enable debug display\n");
    printf("  -s <speed>                  profile velocity in rpm\n");
    printf("  -a <acceleration>           profile acceleration in rpm/s\n");
    printf("  -t <torque acceleration>    profile torque acceleration\n"
           "                              in 1/1000 of rated torque per second\n");
    printf("  -c <file>                   SDO config filename\n");
}

void cmdline(int argc, char **argv, const char *version, int *sdo_enable, int *profile_speed, int *profile_acc, int *profile_torque_acc, char **sdo_config, int *debug)
{
    int  opt;

    const char *options = "hvods:c:a:t:";

    while ((opt = getopt(argc, argv, options)) != -1) {
        switch (opt) {
        case 'v':
            printversion(argv[0], version);
            exit(0);
            break;

        case 'd':
            *debug = 1;
            break;

        case 's':
            *profile_speed = atoi(optarg);
            break;

        case 'a':
            *profile_acc = atoi(optarg);
            break;

        case 't':
            *profile_torque_acc = atoi(optarg);
            break;

        case 'o':
            *sdo_enable = 1;
            break;

        case 'c':
            strncpy(*sdo_config, optarg, PATH_MAX);
            break;

        case 'h':
        default:
            printhelp(argv[0]);
            exit(1);
            break;
        }
    }
}


// Timer functions
unsigned int sig_alarms = 0;
unsigned int user_alarms = 0;
void signal_handler(int signum) {
    switch (signum) {
        case SIGALRM:
            sig_alarms++;
            break;
    }
}
void setup_signal_handler(struct sigaction *sa)
{
    /* setup signal handler */
    sa->sa_handler = signal_handler;
    sigemptyset(&(sa->sa_mask));
    sa->sa_flags = 0;
    if (sigaction(SIGALRM, sa, 0)) {
        fprintf(stderr, "Failed to install signal handler!\n");
        exit(-1);
    }
}
void setup_timer(struct itimerval *tv, const int frequency)
{
    /* setup timer */
    tv->it_interval.tv_sec = 0;
    tv->it_interval.tv_usec = 1000000 / frequency;
    tv->it_value.tv_sec = 0;
    tv->it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }
}
