/*****************************************************************************
 *
 *  $Id$
 *
 *  Copyright (C) 2007-2009  Florian Pose, Ingenieurgemeinschaft IgH
 *
 *  This file is part of the IgH EtherCAT Master.
 *
 *  The IgH EtherCAT Master is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License version 2, as
 *  published by the Free Software Foundation.
 *
 *  The IgH EtherCAT Master is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 *  Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with the IgH EtherCAT Master; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  ---
 *
 *  The license mentioned above concerns the source code only. Using the
 *  EtherCAT technology and brand is only permitted in compliance with the
 *  industrial property and similar rights of Beckhoff Automation GmbH.
 *
 ****************************************************************************/
 /*
  * Adaption to Synapticon SOMANET by Frank Jeschke <fjeschke@synapticon.com>
  *
  * for Synapticon GmbH
  */

#include <errno.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <signal.h>
#include <getopt.h>
#include <fcntl.h>
#include <curses.h> // required

/****************************************************************************/

#include "ecrt.h" //IgH lib

#include "ecat_master.h"
#include "ecat_debug.h"
#include "ecat_device.h"
#include "ecat_sdo_config.h"
#include "cyclic_task.h"
#include "display.h"
#include "tuning.h"
#include "profile.h"

/****************************************************************************/

#define VERSION    "v0.1-dev"
#define MAXDBGLVL  3

// Application parameters
#define FREQUENCY 1000
#define PRIORITY 1
#define OPMODE_TUNING    (-128)
#define DISPLAY_LINE 19
#define NUM_CONFIG_SDOS   26

/****************************************************************************/

/* application global definitions */
static int g_dbglvl = 1;

// Timer
static unsigned int sig_alarms = 0;
static unsigned int user_alarms = 0;

/****************************************************************************/


/****************************************************************************/

static void logmsg(int lvl, const char *format, ...);

/*****************************************************************************/


/****************************************************************************/

void signal_handler(int signum) {
    switch (signum) {
        case SIGALRM:
            sig_alarms++;
            break;
    }
}

/****************************************************************************/

static void set_priority(void)
{
    if (getuid() != 0) {
        logmsg(0, "Warning, be root to get higher priority\n");
        return;
    }

    pid_t pid = getpid();
    if (setpriority(PRIO_PROCESS, pid, -19))
        fprintf(stderr, "Warning: Failed to set priority: %s\n",
                strerror(errno));
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
}

static void setup_timer(struct itimerval *tv)
{
    /* setup timer */
    logmsg(1, "Starting timer...\n");
    tv->it_interval.tv_sec = 0;
    tv->it_interval.tv_usec = 1000000 / FREQUENCY;
    tv->it_value.tv_sec = 0;
    tv->it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }
}

static void logmsg(int lvl, const char *format, ...)
{
    if (lvl > g_dbglvl)
        return;

    va_list ap;
    va_start(ap, format);
    vprintf(format, ap);
    va_end(ap);
}

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

static void printversion(const char *prog)
{
    printf("%s %s\n", _basename(prog), VERSION);
}

static void printhelp(const char *prog)
{
    printf("Usage: %s [-h] [-v] [-o] [-l <level>] [-n <slave number (starts at 0)>] [-s <profile velocity>]\n", _basename(prog));
    printf("\n");
    printf("  -h             print this help and exit\n");
    printf("  -o             enable sdo upload\n");
    printf("  -v             print version and exit\n");
    //printf("  -l <level>     set log level (0..3)\n");
    printf("  -n <slave number>  first slave is 0\n");
    printf("  -s <profile velocity>\n");
}

static void cmdline(int argc, char **argv, int *num_slaves, int *sdo_enable, int *profile_speed)
{
    int  opt;

    const char *options = "hvlo:s:n:";

    while ((opt = getopt(argc, argv, options)) != -1) {
        switch (opt) {
        case 'v':
            printversion(argv[0]);
            exit(0);
            break;

        case 'n':
            *num_slaves = atoi(optarg)+1;
            if (*num_slaves == 0) {
                fprintf(stderr, "Use a slave number at least 0\n");
                exit(1);
            }
            break;

        case 's':
            *profile_speed = atoi(optarg);
            break;

        case 'l':
            g_dbglvl = atoi(optarg);
            if (g_dbglvl<0 || g_dbglvl>MAXDBGLVL) {
                fprintf(stderr, "Error unsuported debug level %d.\n", g_dbglvl);
                exit(1);
            }
            break;

        case 'o':
            *sdo_enable = 1;
            break;

        case 'h':
        default:
            printhelp(argv[0]);
            exit(1);
            break;
        }
    }
}


/* ----------- OD setup -------------- */

#include "sdo_config.inc"

/* ----------- /OD setup -------------- */


int main(int argc, char **argv)
{
    int sdo_enable = 0;
    int num_slaves = 1;
    int profile_speed = 50;
    cmdline(argc, argv, &num_slaves, &sdo_enable, &profile_speed);

    struct sigaction sa;
    struct itimerval tv;
    
#ifndef DISABLE_ETHERCAT
/********* ethercat init **************/

    struct _master_config *master = master_config(num_slaves);

    if (master == NULL) {
        fprintf(stderr, "[ERROR %s] Cannot initialize master\n", __func__);
        return 1;
    }

    /* Debug information */
    get_master_information(master->master);
    for (int i = 0; i < num_slaves; i++) {
        get_slave_information(master->master, i);
    }
    /* /Debug */

    /*
     * Activate master and start operation
     */
    if (sdo_enable) {
        /* SDO configuration of the slave */
        /* FIXME set per slave SDO configuration */
        for (int i = 0; i < num_slaves; i++) {
            int ret = write_sdo_config(master->master, i, slave_config[i], NUM_CONFIG_SDOS);
            if (ret != 0) {
                fprintf(stderr, "Error configuring SDOs\n");
                return -1;
            }
        }
    }


#if 0
    /* Start the Master and set readiness for cyclic opertation */
    logmsg(1, "Activating master...\n");
    if (ecrt_master_activate(master)) {
        logmsg(0, "Error, master activation failed.\n");
        return -1;
    }

    if (!(domain1_pd = ecrt_domain_data(domain1))) {
        return -1;
    }

    logmsg(4, "Pointer of the domain_pd: 0x%x\n", domain1_pd);
#endif

    master_start(master);
/****************************************************/
#endif

    //log and priority
#if PRIORITY
    set_priority();
#endif
    setup_signal_handler(&sa);
    setup_timer(&tv);
    logmsg(0, "Started.\n");

    //pdo structures
    struct _pdo_cia402_input  *pdo_input  = malloc(num_slaves*sizeof(struct _pdo_cia402_input));
    struct _pdo_cia402_output *pdo_output = malloc(num_slaves*sizeof(struct _pdo_cia402_output));

    //init tuning structure
    InputValues input = {0};
    OutputValues output = {0};
    output.mode_1 = '@';
    output.mode_2 = '@';
    output.mode_3 = '@';
    output.sign = 1;

    /* Init pdos */
    pdo_output[num_slaves-1].controlword = 0;
    pdo_output[num_slaves-1].opmode = OPMODE_TUNING;
    pdo_output[num_slaves-1].target_position = 0;
    pdo_output[num_slaves-1].target_torque = 0;
    pdo_output[num_slaves-1].target_velocity = 0;
    pdo_input[num_slaves-1].opmodedisplay = 0;

    //init profiler
    PositionProfileConfig profile_config;
    profile_config.max_acceleration = 1000;
    profile_config.max_speed = 3000;
    profile_config.profile_speed = profile_speed;
    profile_config.profile_acceleration = 50;
    profile_config.max_position = 0x7fffffff;
    profile_config.min_position = -0x7fffffff;
    profile_config.mode = POSITION_DIRECT;
    init_position_profile_limits(&(profile_config.motion_profile), profile_config.max_acceleration, profile_config.max_speed, profile_config.max_position, profile_config.min_position);

    //init ncurses
    WINDOW *wnd;
    wnd = initscr(); // curses call to initialize window
    noecho(); // curses call to set no echoing
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay

    //init prompt
    Cursor cursor = { DISPLAY_LINE, 2 };
    display_tuning_help(wnd, DISPLAY_LINE-8);
    move(cursor.row, 0);
    printw("> ");
    
    int run_flag = 1;
    int init_tuning = 0;
    while (run_flag) {
        pause();

        /* wait for the timer to raise alarm */
        while (sig_alarms != user_alarms) {
            user_alarms++;

#ifndef DISABLE_ETHERCAT
            pdo_handler(master, pdo_input, pdo_output, num_slaves-1);
#endif

            uint16_t statusword = ((pdo_input[num_slaves-1].statusword >> 8) & 0xff);
            if (statusword == (pdo_output[num_slaves-1].controlword & 0xff)) { //control word received by slave
                pdo_output[num_slaves-1].controlword = 0; //reset control word
            }

            if (init_tuning == 0) { //switch the slave to OPMODE_TUNING
                if (pdo_input[num_slaves-1].opmodedisplay != (OPMODE_TUNING & 0xff)) {
                    if ((statusword & 0x08) == 0x08) {
                        pdo_output[num_slaves-1].controlword = 0x0080;  /* Fault reset */
                    } else { //FIXME: fix check status word
                        pdo_output[num_slaves-1].controlword = 0x0080;  /* Fault reset */
                    }
                } else {
                    init_tuning = 1;
                }
            } else if (pdo_input[num_slaves-1].opmodedisplay == 0) { //quit
                run_flag = 0;
                break;
            }

            //demux received data
            tuning_input(pdo_input[num_slaves-1], &input);

            //print
            display_tuning(wnd, pdo_input[num_slaves-1], input, 0);

            //position profile
            tuning_position(&profile_config, &pdo_output[num_slaves-1]);

            //read user input
            tuning_command(wnd, &pdo_output[num_slaves-1], pdo_input[num_slaves-1], &output, &profile_config, &cursor);

            wrefresh(wnd); //refresh ncurses window
        }
    }

    //free
    endwin(); // curses call to restore the original window and leave
    free(pdo_input);
    free(pdo_output);

    return 0;
}
