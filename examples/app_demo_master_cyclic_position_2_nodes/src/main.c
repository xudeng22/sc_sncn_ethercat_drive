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

enum {ECAT_SLAVE_0, ECAT_SLAVE_1};

/* Only here for interrupt signaling */
bool break_loop = false;

/* Interrupt signal handler */
void  INThandler(int sig)
{
     signal(sig, SIG_IGN);
     break_loop = true;
     signal(SIGINT, INThandler);
}


int main()
{

    int acceleration_drive_1 = 350;     // rpm/s
    int acceleration_drive_2 = 350;     // rpm/s

    int deceleration_drive_1 = 350;     // rpm/s
    int deceleration_drive_2 = 350;     // rpm/s

    int velocity_drive_1 = 350;         // rpm
    int velocity_drive_2 = 350;         // rpm

    int actual_position_drive_1 = 0;    // ticks
    int actual_position_drive_2 = 0;    // ticks

    int zero_position_drive_1 = 0;      // ticks
    int zero_position_drive_2 = 0;      // ticks

    int target_position_drive_1 = 0;    // ticks
    int target_position_drive_2 = 0;    // ticks

    int actual_velocity_drive_1 = 0;    // rpm
    int actual_velocity_drive_2 = 0;    // rpm

    float actual_torque_drive_1;        // mNm
    float actual_torque_drive_2;        // mNm

    int steps_drive_1 = 0;
    int steps_drive_2 = 0;

    int inc_drive_1 = 1;
    int inc_drive_2 = 1;

    int next_target_position_drive_1 = 0;     // ticks
    int next_target_position_drive_2 = 0;     // ticks

    #define  ECAT_SLAVE_0 0
    #define  ECAT_SLAVE_1 1

    int one_rotation = 3 * 4096 * 1; //pole pairs * interpolation constant * gear ratio
    bool absolute_position_taken = false;

    bool new_target = true;
    int delay_inc = 0;

    /* Initialize EtherCAT Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize torque parameters */
    initialize_torque(ECAT_SLAVE_0, slv_handles);
    initialize_torque(ECAT_SLAVE_1, slv_handles);

    /* Initialize all connected nodes with Mandatory Motor Configurations (specified in config)*/
    init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize the node specified with slave_number with CSP configurations (specified in config)*/
    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    set_operation_mode(CSP, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Enable operation of node in CSP mode */
    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize position profile parameters */
    initialize_position_profile_limits(ECAT_SLAVE_0, slv_handles);
    initialize_position_profile_limits(ECAT_SLAVE_1, slv_handles);

    /* catch interrupt signal */
    signal(SIGINT, INThandler);

    /* Just for better printing result */
    system("setterm -cursor off");

    while(1)
    {
        /* Update the process data (EtherCat packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        if(master_setup.op_flag && !break_loop)    /*Check if the master is active*/
        {
            if (new_target) { //has to be done only once for a new target value

                /* Read Actual Position from the node for initialization */
                if (!absolute_position_taken) {
                    printf("taking abs position\n");
                    zero_position_drive_1 = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
                    zero_position_drive_2 = get_position_actual_ticks(ECAT_SLAVE_1, slv_handles);
                    pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
                    absolute_position_taken = true;
                    printf("abs positions are taken: \n%i\n%i\n", zero_position_drive_1, zero_position_drive_2);
                }

                /* Setup Target Position */
                target_position_drive_1 =  zero_position_drive_1 + one_rotation * 5;
                target_position_drive_2 =  zero_position_drive_2 + one_rotation * 5;

                /* Read Actual Position */
                actual_position_drive_1 = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
                actual_position_drive_2 = get_position_actual_ticks(ECAT_SLAVE_1, slv_handles);

                /* Compute steps needed for the target position */
                steps_drive_1 = init_position_profile_params(target_position_drive_1, actual_position_drive_1,
                                velocity_drive_1, acceleration_drive_1, deceleration_drive_1, ECAT_SLAVE_0, slv_handles);
                steps_drive_2 = init_position_profile_params(target_position_drive_2, actual_position_drive_2,
                                velocity_drive_2, acceleration_drive_2, deceleration_drive_2, ECAT_SLAVE_1, slv_handles);

                printf("drive 1: steps %d target_position %d actual_position %d                                    \n",
                        steps_drive_1, target_position_drive_1, actual_position_drive_1);
                printf("drive 2: steps %d target_position %d actual_position %d                                    \n\n",
                        steps_drive_2, target_position_drive_2, actual_position_drive_2);
                new_target = false;
            }

            if(inc_drive_1 < steps_drive_1)
            {
                /* Generate target position steps */
                next_target_position_drive_1 =  generate_profile_position(inc_drive_1, ECAT_SLAVE_0, slv_handles);

                /* Send target position for the node specified by slave_number */
                set_position_ticks(next_target_position_drive_1, ECAT_SLAVE_0, slv_handles);
                inc_drive_1 = inc_drive_1 + 1;
            }
            if(inc_drive_2 < steps_drive_2)
            {
                /* Generate target position steps */
                next_target_position_drive_2 =  generate_profile_position(inc_drive_2, ECAT_SLAVE_1, slv_handles);

                /* Send target position for the node specified by slave_number */
                set_position_ticks(next_target_position_drive_2, ECAT_SLAVE_1, slv_handles);
                inc_drive_2 = inc_drive_2 + 1;
            }
            if(inc_drive_1 >= steps_drive_1 && inc_drive_2 >= steps_drive_2)
            {
              delay_inc++;
              if(delay_inc > 500)//some delay to hold the position
              {
                  /* Set a new target position */
                  one_rotation = -one_rotation;

                  /* Reset increments */
                  inc_drive_1 = 1;
                  inc_drive_2 = 1;
                  delay_inc = 0;

                  /* Enable ramp calculation for new target position */
                  new_target = true;
              }
            }

            /* Read actual node sensor values */
            actual_position_drive_1 = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
            actual_velocity_drive_1 = get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles);
            actual_torque_drive_1 = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);

            actual_position_drive_2 = get_position_actual_ticks(ECAT_SLAVE_1, slv_handles);
            actual_velocity_drive_2 = get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles);
            actual_torque_drive_2 = get_torque_actual_mNm(ECAT_SLAVE_1, slv_handles);

            printf("DRIVE 1: pos:%7.d  vel:%6.d  tq:%6.2f    DRIVE 2: pos:%7.d  vel:%6.d  tq:%6.2f    \r", actual_position_drive_1, actual_velocity_drive_1, actual_torque_drive_1, actual_position_drive_2, actual_velocity_drive_2, actual_torque_drive_2);

        }
        else if (break_loop){
            break;
        }

    }

    printf("\n");

    /* Quick stop position mode (for emergency) */
    quick_stop_position(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    quick_stop_position(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Regain control of node to continue after quick stop */
    renable_ctrl_quick_stop(CSP, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES); //after quick-stop
    renable_ctrl_quick_stop(CSP, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES); //after quick-stop

    set_operation_mode(CSP, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    set_operation_mode(CSP, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Shutdown node operations */
    shutdown_operation(CSP, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    shutdown_operation(CSP, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Just for better printing result */
    system("setterm -cursor on");

    return 0;
}

