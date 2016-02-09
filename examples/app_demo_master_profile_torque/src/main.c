/**
 * @file main.c
 * @brief Example Master App for Profile Torque (on PC)
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
	float target_torque = -25.0; 	// mNm
	float actual_torque = 0;		// mNm
	float tolerance = 0.76; 		// mNm
	int actual_position = 0;		// ticks
	int actual_velocity = 0;		// rpm
	int ack = 0;
	int sdo_update = 1;             // 1- yes / 0 - no
	int slave_number = 0;

	/* Initialize EtherCAT Master */
	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize all connected nodes with Mandatory Motor Configurations (specified under config/motor/)*/
	init_nodes(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Initialize torque parameters */
	initialize_torque(slave_number, slv_handles);

	/* Initialize the node specified with slave_number with Profile Torque(TQ) configurations (specified under config/motor/)*/
	set_operation_mode(TQ, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/* Enable operation of node in TQ mode */
	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);


	while(1)
	{
		/* Update the process data (EtherCat packets) sent/received from the node */
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)		/*Check if the master is active*/
		{
			/* Send target torque for the node specified by slave_number */
			set_torque_mNm(target_torque, slave_number, slv_handles);

			/* Check if target torque is reached with specified tolerance */
			ack = target_torque_reached(slave_number, target_torque, tolerance, slv_handles);

			/* Read actual node sensor values */
			actual_torque= get_torque_actual_mNm(slave_number, slv_handles);
			actual_position = get_position_actual_ticks(slave_number, slv_handles);
			actual_velocity = get_velocity_actual_rpm(slave_number, slv_handles);
			printf("target_torque %f \n",target_torque);
			printf("actual_torque %f position %d velocity %d ack %d\n", actual_torque, actual_position, actual_velocity, ack);
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

		if(master_setup.op_flag)	/*Check if the master is active*/
		{
			actual_torque =  get_torque_actual_mNm(slave_number, slv_handles);
			actual_position = get_position_actual_ticks(slave_number, slv_handles);
			actual_velocity = get_velocity_actual_rpm(slave_number, slv_handles);
			if(actual_torque > tolerance || actual_torque < -tolerance)
			{
				/* Quick stop Profile Torque mode (for emergency) */
				quick_stop_torque(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
				ack = 1;
			}
			printf("actual_torque %f position %d velocity %d ack %d\n", actual_torque, actual_position, actual_velocity, ack);
		}
	}
	printf("reached \n");

	/* Regain control of node to continue after quick stop */
	renable_ctrl_quick_stop(TQ, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(TQ, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	/*target_torque = 15.0; // mNm
	while(1)
	{
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)	// Check if the master is active
		{

			set_torque_mNm(target_torque, slave_number, slv_handles);
			ack = target_torque_reached(slave_number, target_torque, tolerance, slv_handles);
			actual_torque = get_torque_actual_mNm(slave_number, slv_handles);
			printf("target_torque %f \n",target_torque);
			printf("actual_torque %f ack %d\n", actual_torque, ack);
		}

		if(ack == 1)
		{
			break;
		}
	}
*/
	/*printf("reached \n");

	while(1)
	{
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)//Check if we are up
		{

			actual_torque = get_torque_actual_mNm(slave_number, slv_handles);
			printf("actual_torque %f \n",actual_torque);
		}
	}*/


	/* Shutdown node operations */
	shutdown_operation(TQ, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	return 0;
}


