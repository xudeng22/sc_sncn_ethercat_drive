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
#include <linux/limits.h>

/****************************************************************************/

#include <ethercat_wrapper.h>
#include <ethercat_wrapper_slave.h>
#include <readsdoconfig.h>

#include "ecrt.h" //IgH lib

#include "ecat_master.h"
#include "ecat_debug.h"
#include "ecat_sdo_config.h"
#include "cyclic_task.h"
#include "display.h"
#include "tuning.h"
#include "profile.h"

/****************************************************************************/

// Application parameters
#define FREQUENCY 1000
#define PRIORITY 1
#define OPMODE_TUNING    (-128)
#define MAX_RECORD_MSEC 120000
#define MAX_RECORD_FILENAME 1024

#define VERSION    "v0.1-dev"
#define MAXDBGLVL  3

/****************************************************************************/

/* application global definitions */
static int g_dbglvl = 1;

// Timer
static unsigned int sig_alarms = 0;
static unsigned int user_alarms = 0;

static const char *default_sdo_config_file = "sdo_config/sdo_config.csv";

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
    printf("Usage: %s [-h] [-v] [-o] [-l <level>] [-n <slave number (starts at 0)>] [-s <profile velocity>] [-f <record filename>]\n", _basename(prog));
    printf("\n");
    printf("  -h             print this help and exit\n");
    printf("  -o             enable sdo upload\n");
    printf("  -v             print version and exit\n");
    //printf("  -l <level>     set log level (0..3)\n");
    printf("  -n <slave number>  first slave is 0\n");
    printf("  -s <profile velocity>\n");
    printf("  -c <SDO config filename>\n");
    printf("  -F <record filename>\n");
}

static void cmdline(int argc, char **argv, int *num_slaves, int *sdo_enable,
                    int *profile_speed, char **record_filename, char **sdo_config)
{
    int  opt;

    const char *options = "hvlos:n:c:F:";

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

        case 'c':
            strncpy(*sdo_config, optarg, PATH_MAX);
            break;

        case 'F':
            strncpy(*record_filename, optarg, PATH_MAX);
            break;

        case 'h':
        default:
            printhelp(argv[0]);
            exit(1);
            break;
        }
    }
}

int main(int argc, char **argv)
{
    //default parameters
    int sdo_enable = 0;
    int num_slaves = 1;
    int profile_speed = 50;
    char *record_filename = malloc(PATH_MAX);
    strncpy(record_filename, "record.csv", PATH_MAX);

    char *sdo_config_file = malloc(PATH_MAX);
    strncpy(sdo_config_file, default_sdo_config_file, PATH_MAX);

    //get parameters from cmdline
    cmdline(argc, argv, &num_slaves, &sdo_enable, &profile_speed, &record_filename, &sdo_config_file);

    struct sigaction sa;
    struct itimerval tv;
    PositionProfileConfig profile_config;

    //init tuning structure
    InputValues input = {0};
    OutputValues output = {0};
    output.app_mode = TUNING_MODE;
    output.mode_1 = 1;
    output.mode_2 = 1;
    output.mode_3 = 1;
    output.sign = 1;

    //read sdo parameters from file
    SdoConfigParameter_t sdo_config_parameter;
    SdoParam_t **slave_config = 0;
    if (sdo_enable) {
        if (read_sdo_config(sdo_config_file, &sdo_config_parameter) != 0) {
            fprintf(stderr, "Error, could not read SDO configuration file.\n");
            return -1;
        }
        free(sdo_config_file); /* filename and path to the SDO config parameters is no longer needed */
        slave_config = sdo_config_parameter.parameter;
    }

#ifndef DISABLE_ETHERCAT
/********* ethercat init **************/

    /* use master id 0 for the first ehtercat master interface (defined by the
     * libethercat).
     * The logging output must be redirected into a file, otherwise the output will
     * interfere with the ncurses windowing. */
    FILE *ecatlog = fopen("./ecat.log", "w");
    Ethercat_Master_t *master = ecw_master_init(0 /* master id */, ecatlog);

    if (master == NULL) {
        fprintf(stderr, "[ERROR %s] Cannot initialize master\n", __func__);
        return 1;
    }

    if (sdo_enable) {
        /* SDO configuration of the slave */
        int ret = write_sdo_config(master, num_slaves-1, slave_config[num_slaves-1], sdo_config_parameter.param_count);
        if (ret != 0) {
            fprintf(stderr, "Error configuring SDOs\n");
            return -1;
        }
    }

    //get GPIO SDO config
    for (int i=1; i<=4; i++) {
        input.gpio_config[i-1] = read_sdo(master, num_slaves-1, DICT_GPIO, i);
    }

    //init profiler
    profile_config.max_acceleration = 1000;
    profile_config.max_speed = 3000;
    profile_config.profile_speed = profile_speed;
    profile_config.profile_acceleration = 50;
    profile_config.max_position = 0x7fffffff;
    profile_config.min_position = -0x7fffffff;
    profile_config.mode = POSITION_DIRECT;
    profile_config.ticks_per_turn = 65536;
    for (int sensor_port=1; sensor_port<=3; sensor_port++) {
        int sensor_config = read_sdo(master, num_slaves-1, DICT_FEEDBACK_SENSOR_PORTS, sensor_port);
        if (sensor_config != 0) {
            int sensor_function = read_sdo(master, num_slaves-1, sensor_config, SUB_ENCODER_FUNCTION);
            if (sensor_function == 1 || sensor_function == 3) { //sensor functions 1 and 3 are motion control
                profile_config.ticks_per_turn = read_sdo(master, num_slaves-1, sensor_config, SUB_ENCODER_RESOLUTION);
                break;
            }
        }
    }
    init_position_profile_limits(&(profile_config.motion_profile), profile_config.max_acceleration, profile_config.max_speed, profile_config.max_position, profile_config.min_position, profile_config.ticks_per_turn);

    // Activate master and start operation
    if (ecw_master_start(master) != 0) {
        fprintf(stderr, "Error starting cyclic operation of master - giving up\n");
        return -1;
    }
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

    /* Init pdos */
    pdo_output[num_slaves-1].controlword = 0;
    pdo_output[num_slaves-1].op_mode = 0;
    pdo_output[num_slaves-1].target_position = 0;
    pdo_output[num_slaves-1].target_torque = 0;
    pdo_output[num_slaves-1].target_velocity = 0;
    pdo_input[num_slaves-1].op_mode_display = 0;

    //init recorder
    RecordConfig record_config = {0};
    record_config.count = 0;
    record_config.data = NULL;
    record_config.state = RECORD_OFF;
    record_config.max_values = MAX_RECORD_MSEC;

    //init ncurses
    WINDOW *wnd;
    wnd = initscr(); // curses call to initialize window
    noecho(); // curses call to set no echoing
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay
    Cursor cursor;
    
    int run_flag = 1;
    while (run_flag) {
        pause();

        /* wait for the timer to raise alarm */
        while (sig_alarms != user_alarms) {
            user_alarms++;

#ifndef DISABLE_ETHERCAT
            ecw_master_cyclic_function(master);
            pdo_handler(master, pdo_input, pdo_output, num_slaves-1);
#endif

            if (output.app_mode == QUIT_MODE) {
                if (pdo_input[num_slaves-1].op_mode_display == 0) {
                    run_flag = 0;
                    break;
                }
            } else if (output.app_mode == TUNING_MODE) {
                tuning(wnd, &cursor,
                        &pdo_output[num_slaves-1], &pdo_input[num_slaves-1],
                        &output, &input,
                        &profile_config,
                        &record_config, record_filename);
            } else if (output.app_mode == CS_MODE){
                cs_mode(wnd, &cursor, pdo_output, pdo_input, num_slaves, &output);
            }

            wrefresh(wnd); //refresh ncurses window
        }
    }

    //free
#ifndef DISABLE_ETHERCAT
    ecw_master_stop(master);
    ecw_master_release(master);
    fclose(ecatlog);
#endif
    endwin(); // curses call to restore the original window and leave
    free(pdo_input);
    free(pdo_output);

    return 0;
}
