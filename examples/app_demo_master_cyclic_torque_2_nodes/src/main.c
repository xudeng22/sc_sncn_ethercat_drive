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
#include <unistd.h>
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
    printf("%d slaves are defined in the system\n", TOTAL_NUM_OF_SLAVES);

    for (int i = 0; i < TOTAL_NUM_OF_SLAVES; i++){

        printf("enter target torque for slave %d: \n", i+1);
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
	float final_target_torque = 0.0;			// mNm
	float torque_slope = 10.0;					// mNm/s
	int steps[TOTAL_NUM_OF_SLAVES];
	int inc_drive_1 = 1;
	int inc_drive_2 = 1;

	float target_torque_drive_1 = 0.0;  		// mNm
    float target_torque_drive_2 = 0.0;          // mNm

	float actual_torque_drive_1 = 0.0;		    // mNm
	float actual_torque_drive_2 = 0.0;          // mNm

	int actual_position_drive_1 = 0;			// ticks
	int actual_velocity_drive_1 = 0;			// rpm

    int actual_position_drive_2 = 0;            // ticks
    int actual_velocity_drive_2 = 0;            // rpm

    #define MAX_VELOCITY 4000

    bool new_target_drive_1 = true;
    bool new_target_drive_2 = true;

    int *p;
    p = read_user_input();

    printf("\n*****************************\nLoading motor configurations\n*****************************\n");

    /* Initialize Ethercat Master */
	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Initialize all connected nodes with Mandatory Motor Configurations (specified under config/motor/)*/
	init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize the node specified with slave_number with CST configurations (specified under config/motor/)*/
	set_operation_mode(CST, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	set_operation_mode(CST, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Enable operation of node in CST mode */
	enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Compute steps needed for the target torque */
    for (int i = 0; i < TOTAL_NUM_OF_SLAVES; i++ )
    {
        printf("DRIVE %d TORQUE SP:  %d\n", i+1, *(p + i));
        final_target_torque = *(p + i);
        steps[i] = init_linear_profile_params(final_target_torque, actual_torque_drive_1, torque_slope, i, slv_handles);
    }

	/* catch interrupt signal */
	signal(SIGINT, INThandler);

    /* Just for better printing result */
    system("setterm -cursor off");

	while(1)
	{
		/* Update the process data (EtherCat packets) sent/received from the node */
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag && !break_loop) /*Check if the master is active*/
		{
			if(inc_drive_1 < steps[ECAT_SLAVE_0])
			{
				/* Generate target torque steps */
				target_torque_drive_1 = generate_profile_linear(inc_drive_1, ECAT_SLAVE_0, slv_handles);

				/* Send target torque for the node specified by slave_number */
				set_torque_mNm(target_torque_drive_1, ECAT_SLAVE_0, slv_handles);

				inc_drive_1++;
			}

			if(inc_drive_2 < steps[ECAT_SLAVE_1])
            {
                /* Generate target torque steps */
                target_torque_drive_2 = generate_profile_linear(inc_drive_2, ECAT_SLAVE_1, slv_handles);

                /* Send target torque for the node specified by slave_number */
                set_torque_mNm(target_torque_drive_2, ECAT_SLAVE_1, slv_handles);

                inc_drive_2++;
            }

			if(inc_drive_1 >= steps[ECAT_SLAVE_0] && inc_drive_2 >= steps[ECAT_SLAVE_1])
			{
			    actual_torque_drive_1 = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);
			    actual_torque_drive_2 = get_torque_actual_mNm(ECAT_SLAVE_1, slv_handles);
                actual_velocity_drive_1 = get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles);
                actual_velocity_drive_2 = get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles);
			    actual_position_drive_1 = get_position_actual_ticks(ECAT_SLAVE_0, slv_handles);
			    actual_position_drive_2 = get_position_actual_ticks(ECAT_SLAVE_1, slv_handles);

				printf("Target torques are reached. ");
				printf("DRIVE 1: tq:%6.2f vel:%5.d pos:%8.d  |  DRIVE 2: tq:%6.2f vel:%5.d pos:%8.d    \r",
				        actual_torque_drive_1, actual_velocity_drive_1, actual_position_drive_1,
				        actual_torque_drive_2, actual_velocity_drive_2, actual_position_drive_2);
			}
			else{
	            /* Read actual node sensor values */
	            actual_torque_drive_1 = get_torque_actual_mNm(ECAT_SLAVE_0, slv_handles);
	            actual_torque_drive_2 = get_torque_actual_mNm(ECAT_SLAVE_1, slv_handles);
	            printf("target tq DRIVE 1: %6.2f actual torque DRIVE 1: %6.2f | target tq DRIVE 2: %6.2f actual torque DRIVE 2: %6.2f \r",
	                    target_torque_drive_1, actual_torque_drive_1, target_torque_drive_2, actual_torque_drive_2);
			}

            /* Trigger emergency stop if max velocity is reached*/
            actual_velocity_drive_1 = get_velocity_actual_rpm(ECAT_SLAVE_0, slv_handles);
            actual_velocity_drive_2 = get_velocity_actual_rpm(ECAT_SLAVE_1, slv_handles);
            if (actual_velocity_drive_1 > MAX_VELOCITY || actual_velocity_drive_2 > MAX_VELOCITY){
                printf("\nDanger! Max velocity is reached\n");
                break_loop = true;
            }

		}
		else if (break_loop){
		    break;
		}
	}

	/* Quick stop torque mode (for emergency) */
	quick_stop_torque(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	quick_stop_torque(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Regain control of node to continue after quick stop */
	renable_ctrl_quick_stop(CST, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	renable_ctrl_quick_stop(CST, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(CST, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	set_operation_mode(CST, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	enable_operation(ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Shutdown node operations */
	shutdown_operation(CST, ECAT_SLAVE_0, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	shutdown_operation(CST, ECAT_SLAVE_1, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

    /* Just for better printing result */
    system("setterm -cursor on");

	return 0;
}


