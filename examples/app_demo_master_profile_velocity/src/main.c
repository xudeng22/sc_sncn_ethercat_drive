
/**
 * @file main.c
 * @brief Example Master App for Profile Velocity (on PC)
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 * @author Christian Holl <choll@synapticon.com>
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

int main()
{
	int actual_velocity = 0;		// rpm
	int target_velocity = 500;		// rpm
	int tolerance = 20; 			// rpm
	int actual_position = 0; 		// ticks
	float actual_torque;			// mNm
	int slave_number = 0;
	int ack = 0;
	int sdo_update = 1;             // 1- yes / 0 - no

	/* Initialize EtherCAT Master */
	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize torque parameters */
	initialize_torque(slave_number, slv_handles);

	/* Initialize all connected nodes with Mandatory Motor Configurations (specified under config/motor/)*/
	init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize the node specified with slave_number with Profile Velocity(PV) configurations (specified under config/motor/)*/
	set_operation_mode(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Enable operation of node in PV mode */
	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	while(1)
	{
		/* Update the process data (EtherCat packets) sent/received from the node */
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)	// Check if the master is active
		{
			/* Send target velocity for the node specified by slave_number */
			set_velocity_rpm(target_velocity, slave_number, slv_handles);

			/* Check if target velocity is reached with specified tolerance */
			ack = target_velocity_reached(slave_number, target_velocity, tolerance, slv_handles);

			/* Read actual node sensor values */
			actual_velocity =  get_velocity_actual_rpm(slave_number, slv_handles);
			actual_position = get_position_actual_ticks(slave_number, slv_handles);
			actual_torque = get_torque_actual_mNm(slave_number, slv_handles);
			printf("Velocity: %d Positon: %d Torque: %f ack: %d\n", actual_velocity, actual_position, actual_torque, ack);
			fflush(stdout);
		}
		if(ack == 1)
		{
			break;
		}
	}

	printf("reached \n");

	ack = 0;
	while(!ack)
	{
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
		if(master_setup.op_flag)	// Check if the master is active
		{
			actual_velocity =  get_velocity_actual_rpm(slave_number, slv_handles);
			actual_position = get_position_actual_ticks(slave_number, slv_handles);
			actual_torque = get_torque_actual_mNm(slave_number, slv_handles);
			if(actual_velocity > 0 || actual_velocity < 0)
			{
				/* Quick stop Profile Velocity mode (for emergency) */
				quick_stop_velocity(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
				ack = 1;
			}
			printf("Velocity: %d Positon: %d Torque: %f ack: %d\n", actual_velocity, actual_position, actual_torque, ack);
			fflush(stdout);
		}
	}
	printf("reached \n");

//	while(1)
//	{
//		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
//		if(master_setup.op_flag)//Check if we are up
//		{
//			actual_velocity =  get_velocity_actual_rpm(slave_number, slv_handles);
//			printf("velocity %d \n", actual_velocity);
//		}
//	}

	/* Regain control of node to continue after quick stop */
	renable_ctrl_quick_stop(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Shutdown node operations */
	shutdown_operation(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/*target_velocity = -300;
	while(1)
	{

		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)	// Check if the master is active
		{
			set_velocity_rpm(target_velocity, slave_number, slv_handles);
			ack = target_velocity_reached(slave_number, target_velocity, tolerance, slv_handles);
			actual_velocity =  get_velocity_actual_rpm(slave_number, slv_handles);
			printf("velocity %d ack %d\n", actual_velocity, ack);
		}
		if(ack == 1)
		{
			break;
		}
	}*/

/*	printf("reached \n");
	while(1)
	{
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
		if(master_setup.op_flag)//Check if we are up
		{
			actual_velocity =  get_velocity_actual_rpm(slave_number, slv_handles);
			printf("velocity %d \n", actual_velocity);
		}
	}*/
	//shutdown_operation(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
	return 0;
}


