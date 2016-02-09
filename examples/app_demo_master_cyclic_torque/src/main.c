/**
 * @file main.c
 * @brief Example Master App for Cyclic Synchronous Torque (on PC)
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
#include "ethercat_setup.h"

enum {ECAT_SLAVE_0};

int main() {

    float target_torque = 30.0; // mNm
    float torque_slope = 10.0; // mNm/s

    float actual_torque = 0.0; // mNm
    int actual_position = 0; // ticks
    int actual_velocity = 0; // rpm
    float torque_ramp = 0.0; // mNm
    int steps = 0;

    /* Initialize Ethercat Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize torque parameters */
    initialize_torque(ECAT_SLAVE_0, slv_handles);

    /* Initialize all connected nodes with Mandatory Motor Configurations (specified in config/motor/)*/
    init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize the node specified with ECAT_SLAVE_0 with CST configurations (specified in config/motor/)*/
    set_operation_mode(CST, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Enable operation of node in CST mode */
    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Compute steps needed for the target torque */
    steps = init_linear_profile_params(target_torque, actual_torque,
            torque_slope, ECAT_SLAVE_0, slv_handles);

    /* Just for better printing result */
    printf("\n");
    system("setterm -cursor off");

    for (int i = 1; i < steps + 1; i++) {
        /* Update the process data (EtherCat packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        if (master_setup.op_flag) /*Check if the master is active*/
        {
            /* Generate target torque steps */
            torque_ramp = generate_profile_linear(i, ECAT_SLAVE_0,
                    slv_handles);
            //printf("torque_ramp %f \n",torque_ramp);
            /* Send target torque for the node specified by ECAT_SLAVE_0 */
            set_torque_mNm(torque_ramp, ECAT_SLAVE_0, slv_handles);

            /* Read actual node sensor values */
            actual_torque = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);
            actual_position = get_position_actual_ticks(ECAT_SLAVE_0,
                    slv_handles);
            actual_velocity
                    = get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles);

            printf("\r    Torque: %f    Position: %d    Velocity: %d        ", torque_ramp, actual_position, actual_velocity);

        }
    }

    printf("\n");

    /* Quick stop torque mode (for emergency) */
    quick_stop_torque(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Regain control of node to continue after quick stop */
    renable_ctrl_quick_stop(CST, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    set_operation_mode(CST, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Shutdown node operations */
    shutdown_operation(CST, ECAT_SLAVE_0, &master_setup, slv_handles,
            TOTAL_NUM_OF_SLAVES);

    /* Just for better printing result */
    system("setterm -cursor on");

    return 0;
}

