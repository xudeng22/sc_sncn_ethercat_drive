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
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <signal.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <curses.h> // required
#include <sys/mman.h>

/****************************************************************************/

#include "ecrt.h"

#include "ecat_master.h"
#include "ecat_debug.h"
#include "ecat_device.h"
#include "ecat_sdo_config.h"
#include "cyclic_task.h"
#include "display.h"

/****************************************************************************/

#define VERSION    "v0.1-dev"
#define MAXDBGLVL  3

// Application parameters
#define FREQUENCY 1000
#define PRIORITY 1

#define NUM_CONFIG_SDOS   26
#define MAX_FILENAME 500
#define DEFAULT_NUM_SLAVES 1

#ifndef NUM_SLAVES
#define NUM_SLAVES   DEFAULT_NUM_SLAVES
#endif

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
    printf("Usage: %s [-h] [-v] [-l <level>] [-n <number of slaves>]\n", _basename(prog));
    printf("\n");
    printf("  -h             print this help and exit\n");
    printf("  -v             print version and exit\n");
    //printf("  -l <level>     set log level (0..3)\n");
    printf("  -n <number of slaves>  number of connected ethercat slaves\n");
}

static void cmdline(int argc, char **argv, int *num_slaves)
{
    int  opt;

    const char *options = "hvl:s:f:n:";

    while ((opt = getopt(argc, argv, options)) != -1) {
        switch (opt) {
        case 'v':
            printversion(argv[0]);
            exit(0);
            break;

        case 'n':
            *num_slaves = atoi(optarg);
            if (*num_slaves == 0) {
                fprintf(stderr, "Use a number of slaves greater than 0\n");
                exit(1);
            }
            break;

        case 'l':
            g_dbglvl = atoi(optarg);
            if (g_dbglvl<0 || g_dbglvl>MAXDBGLVL) {
                fprintf(stderr, "Error unsuported debug level %d.\n", g_dbglvl);
                exit(1);
            }
            break;

        case 'h':
        default:
            printhelp(argv[0]);
            exit(1);
            break;
        }
    }
}

#define OPMODE_TUNING    (-128)
#define DISPLAY_LINE 19

/* ----------- OD setup -------------- */

//#include "sdo_config.inc"
#include "sdo_config_DT3.inc"

/* ----------- /OD setup -------------- */


typedef enum {
    TUNING_MOTORCTRL_OFF= 0,
    TUNING_MOTORCTRL_TORQUE= 1,
    TUNING_MOTORCTRL_POSITION= 2,
    TUNING_MOTORCTRL_VELOCITY= 3
} TuningMotorCtrlStatus;

typedef struct {
    int max_position;
    int min_position;
    int max_speed;
    int max_torque;
    int P_pos;
    int I_pos;
    int D_pos;
    int integral_limit_pos;
} InputValues;

typedef struct {
    int last_command;
    int last_value;
} OutputValues;

int r,c, // current row and column (upper-left is (0,0))
nrows, // number of rows in window
ncols; // number of columns in window



void draw(char dc)
{
    move(r,c); // curses call to move cursor to row r, column c
    if (dc == '\n')
        dc = '.';
    delch(); insch(dc); // curses calls to replace character under cursor by dc
    refresh(); // curses call to update screen
    c++; // go to next row
    // check for need to shift right or wrap around
    if (c == ncols) {
        c = 0;
        r++;
        if (r == nrows) r = DISPLAY_LINE;
    }
}



int main(int argc, char **argv)
{
    int num_slaves = 1;
    cmdline(argc, argv, &num_slaves);

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

    /* SDO configuration of the slave */
    /* FIXME set per slave SDO configuration */
    for (int i = 0; i < num_slaves; i++) {
        int ret = write_sdo_config(master->master, i, slave_config[i], NUM_CONFIG_SDOS);
        if (ret != 0) {
            fprintf(stderr, "Error configuring SDOs\n");
            return -1;
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


    char d;
    WINDOW *wnd;

    //init ncurses
    wnd = initscr(); // curses call to initialize window
    //cbreak(); // curses call to set no waiting for Enter key
    noecho(); // curses call to set no echoing
    getmaxyx(wnd,nrows,ncols); // curses call to find size of window
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay
    //    start_color();           /* Start color          */
    //    init_pair(1, COLOR_RED, -1);

    r = DISPLAY_LINE; c = 0;
    int value = 0;
    char mode = '@';
    char mode_2 = '@';
    char mode_3 = '@';
    int sign = 1;
    int offset = 0;
    int motor_polarity = 0, sensor_polarity = 0, torque_control_flag = 0, brake_flag = 0;
    TuningMotorCtrlStatus motorctrl_status = TUNING_MOTORCTRL_OFF;
    InputValues input = {0};
    OutputValues output = {0};
    int pole_pairs = 0;
    int target = 0;

    int status_mux = 0;
    unsigned char statusword = 0;
    unsigned short controlword = 0;

#ifndef DISABLE_ETHERCAT
    /* Init pdos */
    pdo_output[num_slaves].controlword = 0;
    pdo_output[num_slaves].opmode = OPMODE_TUNING;
    pdo_output[num_slaves].target_position = 0;
    pdo_output[num_slaves].target_torque = 0;
    pdo_output[num_slaves].target_velocity = 0;
    pdo_input[num_slaves].opmodedisplay = 0;
    /* Update the process data (EtherCAT packets) sent/received from the node */
    pdo_handler(master, pdo_input, pdo_output);

    //set the operation mode to tuning
    while (pdo_input[num_slaves].opmodedisplay != (OPMODE_TUNING & 0xff)) {
        /* Update the process data (EtherCAT packets) sent/received from the node */
        pdo_handler(master, pdo_input, pdo_output);

        statusword = (unsigned char)((pdo_input[num_slaves].statusword) & 0xff);
        if ((statusword & 0x08) == 0x08) {
            pdo_output[num_slaves].controlword = 0x0080;  /* Fault reset */
        }
    }
    pdo_output[num_slaves].controlword = 0;  //reset control word
#endif

    //init prompt
    move(DISPLAY_LINE-8, 0);
    printw("Commands:");
    move(DISPLAY_LINE-7, 0);
    printw("b: Release/Block Brake       | a: find offset (also release the brake)");
    move(DISPLAY_LINE-6, 0);
    printw("number: set torque command   | r: reverse torque command");
    move(DISPLAY_LINE-5, 0);
    printw("ep3: enable position control | p + number: set position command");
    move(DISPLAY_LINE-4, 0);
    printw("P + number: set pole pairs");
    move(DISPLAY_LINE-3, 0);
    printw("L s/t/p + number: set speed/torque/position limit");
    move(DISPLAY_LINE-2, 0);
    printw("** Double press Enter for emergency stop **");
    move(DISPLAY_LINE, 0);
    printw("> ");
    c=2;

    

    int run_flag = 1;
    while (run_flag) {
        pause();

        /* wait for the timer to raise alarm */
        while (sig_alarms != user_alarms) {
            user_alarms++;

#ifndef DISABLE_ETHERCAT
            pdo_handler(master, pdo_input, pdo_output);
#endif

            status_mux = (pdo_input[num_slaves].statusword) & 0xff;
            statusword = (unsigned char)((pdo_input[num_slaves].statusword >> 8) & 0xff);


            if (statusword == (controlword & 0xff)) { //control word received by slave
                pdo_output[num_slaves].controlword = 0; //reset control word
                controlword = 0;
            }

            if (pdo_input[num_slaves].opmodedisplay == 0) { //quit
                run_flag = 0;
            }

            //receive and print data
            //demux received data

            switch(status_mux) {
            case 0://flags
                brake_flag = pdo_input[num_slaves].user_in_4 & 1;
                motorctrl_status = (pdo_input[num_slaves].user_in_4 >> 1) & 0b11;
                torque_control_flag = (pdo_input[num_slaves].user_in_4 >> 3) & 1;
                sensor_polarity = (pdo_input[num_slaves].user_in_4 >> 4) & 1;
                motor_polarity = (pdo_input[num_slaves].user_in_4 >> 5) & 1;
                break;
            case 1://offset
                offset = pdo_input[num_slaves].user_in_4;
                break;
            case 2://pole pairs
                pole_pairs = pdo_input[num_slaves].user_in_4;
                break;
            case 3://target
                target = pdo_input[num_slaves].user_in_4;
                break;
            case 4://min position limit
                input.min_position = pdo_input[num_slaves].user_in_4;
                break;
            case 5://max position limit
                input.max_position = pdo_input[num_slaves].user_in_4;
                break;
            case 6://max speed
                input.max_speed = pdo_input[num_slaves].user_in_4;
                break;
            case 7://max torque
                input.max_torque = pdo_input[num_slaves].user_in_4;
                break;
            case 8://max speed
                input.P_pos = pdo_input[num_slaves].user_in_4;
                break;
            case 9://max speed
                input.I_pos = pdo_input[num_slaves].user_in_4;
                break;
            case 10://max speed
                input.D_pos = pdo_input[num_slaves].user_in_4;
                break;
            default://max torque
                input.integral_limit_pos = pdo_input[num_slaves].user_in_4;
                break;
            }

            //print
            int line = 0;
            //row 0
            move(line,0);
            clrtoeol();
            //motorcontrol mode
            //            attron(COLOR_PAIR(1));
            printw("** Operation mode: ");
            switch(motorctrl_status) {
            case TUNING_MOTORCTRL_OFF:
                printw("off");
                break;
            case TUNING_MOTORCTRL_TORQUE:
                printw("Torque control %5d", target);
                break;
            case TUNING_MOTORCTRL_POSITION:
                printw("Position control %9d", target);
                break;
            case TUNING_MOTORCTRL_VELOCITY:
                printw("Velocity control %5d", target);
                break;
            }
            printw(" **");
            //            attroff(COLOR_PAIR(1));
            line++;
            //row 1
            move(line, 0);
            clrtoeol();
            printw("Position %14d | Velocity %4d",  pdo_input[num_slaves].actual_position, pdo_input[num_slaves].actual_velocity);
            line++;
            //row 2
            move(line, 0);
            clrtoeol();
            printw("Torque computed %4d    | Torque sensor %d", pdo_input[num_slaves].actual_torque, pdo_input[num_slaves].user_in_1);
            //            printw("controlword %4d    | statusword %d", pdo_output[num_slaves].controlword & 0xff, statusword);
            line++;
            //row 3
            move(line, 0);
            clrtoeol();
            printw("Offset %4d             | Pole pairs %2d", offset, pole_pairs);
            line++;
            //row 4
            move(line,0);
            clrtoeol();
            if (motor_polarity == 0)
                printw("Motor polarity normal   | ");
            else
                printw("Motor polarity inverted | ");
            if (sensor_polarity == 0)
                printw("Sensor polarity normal");
            else
                printw("Sensor polarity inverted");
            line++;
            //row 5
            move(line,0);
            clrtoeol();
            if (torque_control_flag == 0)
                printw("Motor control off       | ");
            else
                printw("Motor control on        | ");
            if (brake_flag == 0)
                printw("Brake blocking");
            else
                printw("Brake released");
            line++;
            //row 6
            move(line,0);
            clrtoeol();
            printw("Speed  limit %5d      | ", input.max_speed);
            printw("Position min %d", input.min_position);
            line++;
            //row 7
            move(line,0);
            clrtoeol();
            printw("Torque limit %5d      | ", input.max_torque);
            printw("Position max %d", input.max_position);
            line++;
            //row 8
            move(line,0);
            clrtoeol();
            printw("Positon P %8d      | ", input.P_pos);
            printw("Position I %d", input.I_pos);
            line++;
            //row 9
            move(line,0);
            clrtoeol();
            printw("Positon D %8d      | ", input.D_pos);
            printw("Position I lim %d", input.integral_limit_pos);
            line++;
            move(DISPLAY_LINE, c);

            //read user input
            d = getch(); // curses call to input from keyboard
            if (d == 'q') {
                pdo_output[num_slaves].target_position = 0;
                pdo_output[num_slaves].opmode = 0;
            } else if (d == KEY_BACKSPACE || d == KEY_DC || d == 127) {
                move(DISPLAY_LINE, 0);
                clrtoeol();
                printw("> ");
                c = 2;
                value = 0;
                mode = '@';
                mode_2 = '@';
                mode_3 = '@';
                sign = 1;
            } else if (d != ERR) {
                draw(d); // draw the character
                //parse input
                if(isdigit(d)>0) {
                    value *= 10;
                    value += d - '0';
                } else if (d == '-') {
                    sign = -1;
                } else if (d != ' ' && d != '\n') {
                    if (mode == '@') {
                        mode = d;
                    } else if (mode_2 == '@') {
                        mode_2 = d;
                    } else {
                        mode_3 = d;
                    }
                }

                //set command
                if (d == '\n') {
                    move(nrows-1, 0);
                    clrtoeol();
                    value *= sign;
                    printw("value %d, mode %c (%X), mode_2 %c, mode_3 %c", value, mode, mode, mode_2, mode_3);
                    pdo_output[num_slaves].user_out_3 = value;
                    controlword = ((mode_2 & 0xff) << 8) | (mode & 0xff);
                    pdo_output[num_slaves].controlword = controlword;
                    pdo_output[num_slaves].user_out_4         = mode_3 & 0xff;
                    //check for emergency stop
                    if (output.last_command == '@' && output.last_value == 0 && value == 0 && mode == '@') {
                        pdo_output[num_slaves].controlword = 'e';
                        pdo_output[num_slaves].user_out_3 = 0;
                    }
                    output.last_command = mode;
                    output.last_value = value;
                    value = 0;
                    mode = '@';
                    mode_2 = '@';
                    mode_3 = '@';
                    sign = 1;
                    move(DISPLAY_LINE, 0);
                    clrtoeol();
                    printw("> ");
                    c = 2;
                }
            }

        }
    }
    endwin(); // curses call to restore the original window and leave
    free(pdo_input);
    free(pdo_output);


    return 0;
}
