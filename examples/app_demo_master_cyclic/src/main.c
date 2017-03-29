 /*
  * main.c
  *
  * Synapticon GmbH
  */

//standard
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <linux/limits.h>

//other files
#include "cia402.h"
#include "display.h"
#include "ecat_master.h"
#include "operation.h"
#include "profile.h"

#define VERSION    "v0.1-dev"
#define FREQUENCY 1000
static const char *default_sdo_config_file = "sdo_config/sdo_config.csv";


/****************************************************************************/
// Timer
static unsigned int sig_alarms = 0;
static unsigned int user_alarms = 0;
void signal_handler(int signum) {
    switch (signum) {
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
}
static void setup_timer(struct itimerval *tv)
{
    /* setup timer */
    tv->it_interval.tv_sec = 0;
    tv->it_interval.tv_usec = 1000000 / FREQUENCY;
    tv->it_value.tv_sec = 0;
    tv->it_value.tv_usec = 1000;
    if (setitimer(ITIMER_REAL, tv, NULL)) {
        fprintf(stderr, "Failed to start timer: %s\n", strerror(errno));
        exit(-1);
    }
}
/****************************************************************************/


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
    printf("  -f <SDO config filename>\n");
    printf("  -F <record filename>\n");
}

static void cmdline(int argc, char **argv, int *sdo_enable,
                    int *profile_speed, char **sdo_config)
{
    int  opt;

    const char *options = "hvos:c:";

    while ((opt = getopt(argc, argv, options)) != -1) {
        switch (opt) {
        case 'v':
            printversion(argv[0]);
            exit(0);
            break;

        case 's':
            *profile_speed = atoi(optarg);
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

int main(int argc, char **argv)
{
    //default parameters
    int sdo_enable = 0;
    int num_slaves = 1;
    int profile_speed = 50;
    char *sdo_config_file = malloc(PATH_MAX);
    strncpy(sdo_config_file, default_sdo_config_file, PATH_MAX);

    //get parameters from cmdline
    cmdline(argc, argv, &sdo_enable, &profile_speed, &sdo_config_file);

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


//#define DISABLE_ETHERCAT
/********* ethercat init **************/
#ifndef DISABLE_ETHERCAT

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

    // send sdo parameters to the slaves
    if (sdo_enable) {
        for (int i = 0; i < num_slaves; i++) {
            int ret = write_sdo_config(master, i, slave_config[i], sdo_config_parameter.param_count);
            if (ret != 0) {
                fprintf(stderr, "Error configuring SDOs\n");
                return -1;
            }
        }
    }

    // Activate master and start operation
    if (ecw_master_start(master) != 0) {
        fprintf(stderr, "Error starting cyclic operation of master - giving up\n");
        return -1;
    }

    num_slaves = ecw_master_slave_count(master);
#endif
/****************************************************/

    /* Init pdos */
    PDOInput  *pdo_input  = malloc(num_slaves*sizeof(PDOInput));
    PDOOutput *pdo_output = malloc(num_slaves*sizeof(PDOOutput));
    for (int i=0; i<num_slaves; i++) {
        pdo_output[i].controlword = 0;
        pdo_output[i].op_mode = 0;
        pdo_output[i].target_position = 0;
        pdo_output[i].target_torque = 0;
        pdo_output[i].target_velocity = 0;
        pdo_input[i].op_mode_display = 0;
        pdo_input[i].statusword = 0;
    }


    //init output structure
    OutputValues output = {0};
    output.app_mode = CS_MODE;
    output.mode_1 = '@';
    output.mode_2 = '@';
    output.mode_3 = '@';
    output.sign = 1;


    //init profiler
    PositionProfileConfig profile_config;
    profile_config.max_acceleration = 1000;
    profile_config.max_speed = 3000;
    profile_config.profile_speed = profile_speed;
    profile_config.profile_acceleration = 50;
    profile_config.max_position = 0x7fffffff;
    profile_config.min_position = -0x7fffffff;
    profile_config.mode = POSITION_DIRECT;
    profile_config.ticks_per_turn = 65536;
    if (sdo_enable) {
        for (int sensor_port=1; sensor_port<=3; sensor_port++) {
            //get sensor config
            int sensor_config = read_sdo(num_slaves-1, slave_config, sdo_config_parameter.param_count, 0x2100, sensor_port); //0x2100 is DICT_FEEDBACK_SENSOR_PORTS
            int sensor_function = read_sdo(num_slaves-1, slave_config, sdo_config_parameter.param_count, sensor_config, 2);
            //check sensor function
            if (sensor_function == 1 || sensor_function == 3) { //sensor functions 1 and 3 are motion control
                profile_config.ticks_per_turn = read_sdo(num_slaves-1, slave_config, sdo_config_parameter.param_count, sensor_config, 3); //subindex 3 is resolution
                break;
            }
        }
    }
    init_position_profile_limits(&(profile_config.motion_profile), profile_config.max_acceleration, profile_config.max_speed, profile_config.max_position, profile_config.min_position, profile_config.ticks_per_turn);

    //init ncurses
    WINDOW *wnd;
    wnd = initscr(); // curses call to initialize window
    noecho(); // curses call to set no echoing
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay
    Cursor cursor;

    //setup timer
    struct sigaction sa;
    struct itimerval tv;
    setup_signal_handler(&sa);
    setup_timer(&tv);
    int run_flag = 1;

    //start loop
    while (run_flag) {
        pause();
        /* wait for the timer to raise alarm */
        while (sig_alarms != user_alarms) {
            user_alarms++;

#ifndef DISABLE_ETHERCAT
            ecw_master_cyclic_function(master);
            pdo_handler(master, pdo_input, pdo_output, -1);
#endif

            if (output.app_mode == QUIT_MODE) {
                if (pdo_input[num_slaves-1].op_mode_display == 0) {
                    run_flag = 0;
                    break;
                }
            } else if (output.app_mode == CS_MODE){
                cs_mode(wnd, &cursor, pdo_output, pdo_input, num_slaves, &output, &profile_config);
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
