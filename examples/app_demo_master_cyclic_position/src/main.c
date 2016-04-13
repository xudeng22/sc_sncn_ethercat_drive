/**
 * @file main.c
 * @brief Example Master App for Cyclic Synchronous Position (on PC)
 * @author Synapticon GmbH (www.synapticon.com)
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <stdio.h>
#include <signal.h>
#include <stdbool.h>
#include <profile.h>
#include <drive_function.h>
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include "ethercat_setup.h"

enum {ECAT_SLAVE_0};

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

    int target_position = 524288; // ticks
//    int target_position = 2620000; // ticks
    //int target_position = 2621440; // ticks
    int acceleration = 100; // rpm/s
    int deceleration = 100; // rpm/s
    int velocity = 300; // rpm

    int actual_position = 0; // ticks
    int start_position;
    int actual_velocity = 0; // rpm
    float actual_torque; // mNm
    int relative_target_position = 0; // ticks
    int steps = 0;
    int position_ramp = 0;
    int direction = -1;
    int n_init_ticks = 3;

    /* Initialize EtherCAT Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize torque parameters */
    initialize_torque(ECAT_SLAVE_0, slv_handles);

    /* Initialize all connected nodes with Mandatory Motor Configurations (specified in config)*/
    init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize the node specified with ECAT_SLAVE_0 with CSP configurations (specified in config)*/
    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Enable operation of node in CSP mode */
    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Initialize position profile parameters */
    initialize_position_profile_limits(ECAT_SLAVE_0, slv_handles);

    /* Just for better printing result */
    printf("\n");
    system("setterm -cursor off");

    /* Getting actual position */
    actual_position = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
    start_position = actual_position;
    printf("our start position: %i ticks\n",start_position);

    /* catch interrupt signal */
    signal(SIGINT, INThandler);

    /* Moving one rotation back and forth */
    while(1) {
        if (break_loop)
            break;

        /* Compute a target position */
        relative_target_position = start_position + direction
                * target_position;

        /* Compute steps needed for the target position */
        steps = init_position_profile_params(relative_target_position,
                actual_position, velocity, acceleration,
                deceleration, ECAT_SLAVE_0, slv_handles);

        for (int step = 1; step < steps + 1; step++) {
            if (break_loop)
                break;

            /* Update the process data (EtherCat packets) sent/received from the node */
            pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

            if (master_setup.op_flag) /*Check if the master is active*/
            {

                /* Generate target position steps */
                position_ramp = generate_profile_position(step, ECAT_SLAVE_0,
                        slv_handles);

                /* Send target position for the node specified by ECAT_SLAVE_0 */
                set_position_ticks(position_ramp, ECAT_SLAVE_0, slv_handles);

                /* Read actual node sensor values */
                actual_position = get_position_actual_ticks(ECAT_SLAVE_0,
                        slv_handles);
                actual_velocity = get_velocity_actual_rpm(ECAT_SLAVE_0,
                        slv_handles);
                actual_torque = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);

                printf("\r    Position: %7.d    Velocity: %6.d    Torque: %6.2f        ", actual_position, actual_velocity, actual_torque);
            }
        }
        direction = direction * -1;
    }
    break_loop = false;

    printf("\nReturn to start position\n");
    /* return to start position */
    while ((actual_position - start_position) > 200 || (actual_position - start_position) < -200 ) {
        if (break_loop)
            break;

        /* Compute steps needed for the target position */
        steps = init_position_profile_params(start_position,
                actual_position, velocity, acceleration,
                deceleration, ECAT_SLAVE_0, slv_handles);

        for (int step = 1; step < steps + 1; step++) {
            if (break_loop)
                break;

            /* Update the process data (EtherCat packets) sent/received from the node */
            pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

            if (master_setup.op_flag) /*Check if the master is active*/
            {

                /* Generate target position steps */
                position_ramp = generate_profile_position(step, ECAT_SLAVE_0,
                        slv_handles);

                /* Send target position for the node specified by ECAT_SLAVE_0 */
                set_position_ticks(position_ramp, ECAT_SLAVE_0, slv_handles);

                /* Read actual node sensor values */
                actual_position = get_position_actual_ticks(ECAT_SLAVE_0,
                        slv_handles);
                actual_velocity = get_velocity_actual_rpm(ECAT_SLAVE_0,
                        slv_handles);
                actual_torque = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);

                printf("\r    Position: %7.d    Velocity: %6.d    Torque: %6.2f        ", actual_position, actual_velocity, actual_torque);
            }
        }
    }

    printf("\n");

    /* Quick stop position mode (for emergency) */
    quick_stop_position(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Regain control of node to continue after quick stop */
    renable_ctrl_quick_stop(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES); //after quick-stop

    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    printf("enable_operation\n");
    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    printf("shutdown_operation\n");
    /* Shutdown node operations */
    shutdown_operation(CSP, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Just for better printing result */
    system("setterm -cursor on");

    return 0;
}

