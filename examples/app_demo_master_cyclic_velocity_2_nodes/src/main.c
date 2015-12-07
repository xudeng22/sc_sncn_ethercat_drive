/**
 * @file main.c
 * @brief Example Master App for Cyclic Synchronous Velocity (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
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

/* Reading user-entered values */
int * read_user_input(){

    int number, number_of_items;
    static int targets[TOTAL_NUM_OF_SLAVES];

    printf("%d drives are defined in the system\n", TOTAL_NUM_OF_SLAVES);
    printf("MAX_NOMINAL_SPEED DRIVE1: %d\n", MAX_NOMINAL_SPEED_1);
    printf("MAX_NOMINAL_SPEED DRIVE2: %d\n", MAX_NOMINAL_SPEED_2);

    for (int i = 0; i < TOTAL_NUM_OF_SLAVES; i++){

        printf("enter target velocity for drive (slave) %d: \n", i+1);
        number_of_items = scanf("%d", &number);

        if (number_of_items == EOF) {
          /* Handle EOF/Failure */
          printf("Input failure\n");
          break_loop = true;
        } else if (number_of_items == 0) {
          /* Handle no match */
          printf("Please type a number without a space!\n");
          break_loop = true;
        } else {
          targets[i] = number;
        }
    }
    return targets;
}


int main()
{
	int flag = 0;

	int final_target_velocity = 2000;			     //rpm
	int acceleration= 500;					    	 //rpm/s
	int deceleration = 500;			       		     //rpm/s
	int steps[TOTAL_NUM_OF_SLAVES];
	int inc[TOTAL_NUM_OF_SLAVES];
	int target_velocity = 0;					     // rpm
	int actual_velocity[TOTAL_NUM_OF_SLAVES] = {0,0};// rpm
	int actual_position[TOTAL_NUM_OF_SLAVES];        // ticks
	float actual_torque[TOTAL_NUM_OF_SLAVES];	     // mNm

	int *p;
	p = read_user_input();

	printf("\n*****************************\nLoading motor configurations\n*****************************\n");

	/* Initialize Ethercat Master */
	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize all connected nodes with Mandatory Motor Configurations (specified under config/motor/)*/
	init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize the node specified with slave_number with CSV configurations (specified under config/motor/)*/
	set_operation_mode(CSV, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	set_operation_mode(CSV, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Enable operation of node in CSV mode */
	enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Compute steps needed to execute velocity profile */
    for (int i = 0; i < TOTAL_NUM_OF_SLAVES; i++ )
    {
        printf("DRIVE %d VELOCITY SP:  %d\n", i+1, *(p + i));
        final_target_velocity = *(p + i);
        steps[i] = init_velocity_profile_params(final_target_velocity, actual_velocity[i], acceleration, deceleration, i, slv_handles);
        inc[i] = 1;
    }

	/* catch interrupt signal */
	signal(SIGINT, INThandler);

    /* Just for better printing result */
    printf("\n");
    system("setterm -cursor off");


	while(1)
	{
		/* Update the process data (EtherCat packets) sent/received from the node */
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag && !break_loop) /*Check if the master is active*/
		{
			/* Handling Slave 1 */
		    if(inc[ECAT_SLAVE_0] < steps[ECAT_SLAVE_0])
			{
				/* Generate target velocity steps */
				target_velocity = generate_profile_velocity( inc[ECAT_SLAVE_0], ECAT_SLAVE_0, slv_handles);

				/* Send target velocity for the node specified by slave_number */
				set_velocity_rpm(target_velocity, ECAT_SLAVE_0, slv_handles);

				inc[ECAT_SLAVE_0]++;
			}

		    /* Handling Slave 2 */
            if(inc[ECAT_SLAVE_1] < steps[ECAT_SLAVE_1])
            {
                /* Generate target velocity steps */
                target_velocity = generate_profile_velocity( inc[ECAT_SLAVE_1], ECAT_SLAVE_1, slv_handles);

                /* Send target velocity for the node specified by slave_number */
                set_velocity_rpm(target_velocity, ECAT_SLAVE_1, slv_handles);

                inc[ECAT_SLAVE_1]++;
            }

            if(inc[ECAT_SLAVE_0] >= steps[ECAT_SLAVE_0] && inc[ECAT_SLAVE_1] >= steps[ECAT_SLAVE_1])
			{
                printf("Target velocities are reached. Press 'Ctrl + C' to quit! |  ");
                printf("DRIVE 1: %4d   DRIVE 2: %4d     \r",
                        get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles),
                        get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles));
			}
            else{
                /* Read actual node sensor values */
                actual_velocity[ECAT_SLAVE_0] = get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles);
                actual_velocity[ECAT_SLAVE_1] = get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles);
                actual_position[ECAT_SLAVE_0] = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
                actual_position[ECAT_SLAVE_1] = get_position_actual_ticks(ECAT_SLAVE_1, slv_handles);
                actual_torque[ECAT_SLAVE_0] = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);
                actual_torque[ECAT_SLAVE_1] = get_torque_actual_mNm(ECAT_SLAVE_1, slv_handles);
                printf("DRIVE 1: vel:%5.d pos:%8.d tq:%6.2f  |  DRIVE 2: vel:%5.d pos:%8.d tq:%6.2f     \r",
                        actual_velocity[ECAT_SLAVE_0], actual_position[ECAT_SLAVE_0], actual_torque[ECAT_SLAVE_0],
                        actual_velocity[ECAT_SLAVE_1], actual_position[ECAT_SLAVE_1], actual_torque[ECAT_SLAVE_1]);
            }
		}
		else if (break_loop){
            break;
        }
	}

	/* Quick stop velocity mode (for emergency) */
	quick_stop_velocity(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	quick_stop_velocity(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Regain control of node to continue after quick stop */
	renable_ctrl_quick_stop(CSV, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	renable_ctrl_quick_stop(CSV, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(CSV, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	set_operation_mode(CSV, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Shutdown node operations */
	shutdown_operation(CSV, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	shutdown_operation(CSV, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Just for better printing result */
    system("setterm -cursor on");

	return 0;
}


