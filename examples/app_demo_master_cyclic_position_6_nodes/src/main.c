/**
 * @file main.c
 * @brief Example Master App for Cyclic Synchronous Position (on PC)
 * @author Synapticon GmbH (www.synapticon.com)
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <stdio.h>
#include <stdbool.h>
#include <profile.h>
#include <drive_function.h>
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include <signal.h>
#include "ethercat_setup.h"

enum {ECAT_SLAVE_0, ECAT_SLAVE_1, ECAT_SLAVE_2, ECAT_SLAVE_3, ECAT_SLAVE_4, ECAT_SLAVE_5};

/* Only here for interrupt signaling */
bool break_loop = false;

/* Interrupt signal handler */
void  INThandler(int sig)
{
     signal(sig, SIG_IGN);
     break_loop = true;
     signal(SIGINT, INThandler);
}


int main() {

    int target_position[6] = { 1048576, 1048576, 1048576, 1048576, 1048576, 0 }; // ticks
//    int target_position[6] = { 0, 0, 0, 0, 262144, 0 }; // ticks
    int acceleration[6] = { 20, 50, 50, 50, 50, 50 }; // rpm/s
    int deceleration[6] = { 20, 50, 50, 50, 50, 50 }; // rpm/s
    int velocity[6] = { 100, 100, 100, 100, 100, 50 }; // rpm

    int actual_position[6]; // ticks
    int start_position[6];
    int relative_target_position[6] = {0}; // ticks
    int step[6] = {0};
    int steps[6] = {0};
    int end_reached[6] = {0};
    int steps_reached[6] = {0};
    int steps_reached_count = 0;
    bool end_flag = false;
    bool update_target_flag = false;
    const int error_margin = 500;

    int actual_velocity = 0; // rpm
    float actual_torque; // mNm

    /* Initialize EtherCAT Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);


    /* Initialize all connected nodes with Mandatory Motor Configurations (specified in config)*/
    init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    for (int slaveid=0 ; slaveid<TOTAL_NUM_OF_SLAVES ; slaveid++) {
        /* Getting start position */
        actual_position[slaveid] = get_position_actual_ticks(slaveid, slv_handles);
        start_position[slaveid] = actual_position[slaveid];
        printf("Motor %d start position: %i ticks\n", slaveid, start_position[slaveid]);
    }
    for (int slaveid=0 ; slaveid<TOTAL_NUM_OF_SLAVES ; slaveid++) {
        /* Initialize the node specified with ECAT_SLAVE_0 with CSP configurations (specified in config)*/
        set_operation_mode(CSP, slaveid, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        /* Enable operation of node in CSP mode */
        enable_operation(slaveid, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        /* Initialize position profile parameters */
        initialize_position_profile_limits(slaveid, slv_handles);
    }

    /* Just for better printing result */
    printf("\n");
    system("setterm -cursor off");

    /* catch interrupt signal */
    signal(SIGINT, INThandler);


    /* Moving back and forth */
    while(1) {
        /* go to start position on first SIGINT, stop immediatly on second SIGINT */
        if (break_loop) {
            if (end_flag) {
                break;
            } else {
                end_flag = true;
                printf("\nReturn to start position\n");
                break_loop = false;
            }
        }

        /* Update the process data (EtherCat packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        //all slave have finished their steps, activate the target update
        if (steps_reached_count >= TOTAL_NUM_OF_SLAVES) {
            update_target_flag = true;
        }

        /* go through all slaves */
        int end = 0;
        steps_reached_count = 0;
        for (int slaveid=0 ; slaveid<TOTAL_NUM_OF_SLAVES ; slaveid++) {
            /* update target position */
            if (update_target_flag) {
                /* Compute a new target position */
                if (end_flag) { //return to start position
                    relative_target_position[slaveid] = start_position[slaveid];
                    if ((actual_position[slaveid] - start_position[slaveid]) < error_margin && (actual_position[slaveid] - start_position[1]) > -error_margin)
                        end_reached[slaveid] = 1;
                } else { //move to the opposite direction
                    if (relative_target_position[slaveid] == (start_position[slaveid] + target_position[slaveid]))
                        relative_target_position[slaveid] = start_position[slaveid] - target_position[slaveid];
                    else
                        relative_target_position[slaveid] = start_position[slaveid] + target_position[slaveid];
                }

                /* Compute steps needed for the target position */
                steps[slaveid] = init_position_profile_params(relative_target_position[slaveid],
                        actual_position[slaveid], velocity[slaveid], acceleration[slaveid],
                        deceleration[slaveid], slaveid, slv_handles);
                step[slaveid] = 1;
            }

            if (master_setup.op_flag) /*Check if the master is active*/
            {

                /* Generate target position steps */
                int position_ramp = generate_profile_position(step[slaveid], slaveid,
                        slv_handles);

                /* Send target position for the node specified by ECAT_SLAVE_0 */
                set_position_ticks(position_ramp, slaveid, slv_handles);

                /* Read actual node sensor values */
                actual_position[slaveid] = get_position_actual_ticks(slaveid, slv_handles);
//                actual_velocity = get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles);
//                actual_torque = get_torque_actual_mNm(ECAT_SLAVE_1, slv_handles);
//
//                printf("\r    Position: %7.d    Velocity: %6.d    Torque: %6.2f        ", actual_position[1], actual_velocity, actual_torque);
            }

            //check if the steps are finished
            if (step[slaveid] >= steps[slaveid]) {
                steps_reached[slaveid] = 1;
            } else {
                steps_reached[slaveid] = 0;
            }
            step[slaveid]++;

            end += end_reached[slaveid];
            steps_reached_count += steps_reached[slaveid];
        }
        update_target_flag = false;
        // stop when all motors are at their start position
        if (end >= TOTAL_NUM_OF_SLAVES)
            break;

        // display motors positon
        if (master_setup.op_flag) {/*Check if the master is active*/
            printf("A1:%8.d A2:%8.d A3:%8.d A4:%8.d A5:%8.d \r",
                    actual_position[0], actual_position[1], actual_position[2], actual_position[3], actual_position[4]);
        }
    }


    printf("\n");

    // stop
    for (int slaveid=0 ; slaveid<TOTAL_NUM_OF_SLAVES ; slaveid++) {
        /* Quick stop position mode (for emergency) */
        quick_stop_position(slaveid, &master_setup, slv_handles,
                TOTAL_NUM_OF_SLAVES);

        /* Regain control of node to continue after quick stop */
        renable_ctrl_quick_stop(CSP, slaveid, &master_setup, slv_handles,
                TOTAL_NUM_OF_SLAVES); //after quick-stop

        set_operation_mode(CSP, slaveid, &master_setup, slv_handles,
                TOTAL_NUM_OF_SLAVES);

        enable_operation(slaveid, &master_setup, slv_handles,
                TOTAL_NUM_OF_SLAVES);

        /* Shutdown node operations */
        shutdown_operation(CSP, slaveid, &master_setup, slv_handles,
                TOTAL_NUM_OF_SLAVES);
    }

    /* Just for better printing result */
    system("setterm -cursor on");

    return 0;
}

