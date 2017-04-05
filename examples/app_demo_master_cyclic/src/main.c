 /*
  * main.c
  *
  * Synapticon GmbH
  */

#include "cia402.h"
#include "display.h"
#include "ecat_master.h"
#include "operation.h"
#include "profile.h"
#include "utils.h"

/* parameters */
#define VERSION    "v0.1-dev"
#define FREQUENCY 1000
static const char *default_sdo_config_file = "sdo_config/sdo_config.csv";


int main(int argc, char **argv)
{
    //default parameters
    int sdo_enable = 0;
    int num_slaves = 1;
    int profile_speed = 50;
    char *sdo_config_file = malloc(PATH_MAX);
    strncpy(sdo_config_file, default_sdo_config_file, PATH_MAX);

    //get parameters from cmdline
    cmdline(argc, argv, VERSION, &sdo_enable, &profile_speed, &sdo_config_file);

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

    num_slaves = ecw_master_slave_count(master);

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
/****************************************************/

    /* Init pdos */
    PDOInput  *pdo_input  = malloc(num_slaves*sizeof(PDOInput));
    PDOOutput *pdo_output = malloc(num_slaves*sizeof(PDOOutput));


    //init output structure
    OutputValues output = {0};
    output.app_mode = CYCLIC_SYNCHRONOUS_MODE;
    output.mode_1 = '@';
    output.mode_2 = '@';
    output.mode_3 = '@';
    output.sign = 1;
    output.target_state = malloc(num_slaves*sizeof(CIA402State));


    //init profiler
    PositionProfileConfig *profile_config = malloc(num_slaves*sizeof(PositionProfileConfig));

    //init for all slaves
    for (int i = 0; i < num_slaves; i++) {

        /* Init pdos */
        pdo_output[i].controlword = 0;
        pdo_output[i].op_mode = 0;
        pdo_output[i].target_position = 0;
        pdo_output[i].target_torque = 0;
        pdo_output[i].target_velocity = 0;
        pdo_input[i].op_mode_display = 0;
        pdo_input[i].statusword = 0;

        //init output structure
        output.target_state[i] = CIASTATE_SWITCH_ON_DISABLED;

        //init profiler
        profile_config[i].max_acceleration = 1000;
        profile_config[i].max_speed = 3000;
        profile_config[i].profile_speed = profile_speed;
        profile_config[i].profile_acceleration = 50;
        profile_config[i].max_position = 0x7fffffff;
        profile_config[i].min_position = -0x7fffffff;
        profile_config[i].ticks_per_turn = 65536; //default value
        if (sdo_enable) { //try to find the correct ticks_per_turn in the sdo config
            for (int sensor_port=1; sensor_port<=3; sensor_port++) {
                //get sensor config
                int sensor_config = read_local_sdo(i, slave_config, sdo_config_parameter.param_count, 0x2100, sensor_port); //0x2100 is DICT_FEEDBACK_SENSOR_PORTS
                int sensor_function = read_local_sdo(i, slave_config, sdo_config_parameter.param_count, sensor_config, 2);
                //check sensor function
                if (sensor_function == 1 || sensor_function == 3) { //sensor functions 1 and 3 are motion control
                    profile_config[i].ticks_per_turn = read_local_sdo(i, slave_config, sdo_config_parameter.param_count, sensor_config, 3); //subindex 3 is resolution
                    break;
                }
            }
        }
        init_position_profile_limits(&(profile_config[i].motion_profile), profile_config[i].max_acceleration, profile_config[i].max_speed, profile_config[i].max_position, profile_config[i].min_position, profile_config[i].ticks_per_turn);
    }

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
    setup_timer(&tv, FREQUENCY);
    int run_flag = 1;

    //start loop
    while (run_flag) {
        pause();
        /* wait for the timer to raise alarm */
        while (sig_alarms != user_alarms) {
            user_alarms++;

            //ethercat communication
            ecw_master_cyclic_function(master);
            pdo_handler(master, pdo_input, pdo_output, -1);

            if (output.app_mode == QUIT_MODE) {
                if (pdo_input[num_slaves-1].op_mode_display == 0) {
                    run_flag = 0;
                    break;
                }
            } else if (output.app_mode == CYCLIC_SYNCHRONOUS_MODE){
                cyclic_synchronous_mode(wnd, &cursor, pdo_output, pdo_input, num_slaves, &output, profile_config);
            }

            wrefresh(wnd); //refresh ncurses window
        }
    }

    //free
    ecw_master_stop(master);
    ecw_master_release(master);
    fclose(ecatlog);
    endwin(); // curses call to restore the original window and leave
    free(pdo_input);
    free(pdo_output);
    free(profile_config);
    free(output.target_state);

    return 0;
}
