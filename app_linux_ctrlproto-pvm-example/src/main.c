#include <ctrlproto_m.h>
#include <ecrt.h>
#include "ethercat_setup.h"
#include <stdio.h>
#include <stdbool.h>
#include "profile.h"
#include "drive_function.h"
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>

//#define print_slave


int main()
{
//	int ready = 0;
//	int switch_enable = 0;
//	int status_word = 0;
//	int switch_on_state = 0;
//	int op_enable_state = 0;
	int quick_stop_active = 0;
	int ack_stop = 0;
	int control_word;
	int flag = 0;

	int acc = 350;				//rpm/s
	int dec = 350;   			//rpm/s
	int actual_velocity = 0;	//rpm
	int target_velocity = 4000;	//rpm
	int tolerance = 20; 		//rpm

	int steps = 0;
	int i = 1;

	int flag_velocity_set = 0;

	int slave_number = 0;
	int ack = 0;

	int op_enable_state = 0;
	int status_word = 0;
	printf(" %d %d %d %d %d ", slv_handles[0].motor_config_param.s_max_profile_velocity.max_profile_velocity, slv_handles[0].motor_config_param.s_profile_velocity.profile_velocity,  \
	 				slv_handles[0].motor_config_param.s_profile_acceleration.profile_acceleration, slv_handles[0].motor_config_param.s_profile_deceleration.profile_deceleration,\
	 				slv_handles[0].motor_config_param.s_polarity.polarity);

	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	while(1)
	{

		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)//Check if we are up
		{
			set_velocity(target_velocity, slave_number, slv_handles);
			ack = target_velocity_reached(slave_number, target_velocity, tolerance, slv_handles);
			actual_velocity =  get_velocity_actual(slave_number, slv_handles);
			printf("velocity %d ack %d\n", actual_velocity, ack);
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
		if(master_setup.op_flag)//Check if we are up
		{
			actual_velocity =  get_velocity_actual(slave_number, slv_handles);
			if(actual_velocity > 0 || actual_velocity < 0)
			{
				quick_stop_velocity(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
				ack = 1;
			}
			printf("velocity %d ack %d\n", actual_velocity, ack);
		}
	}
	printf("reached \n");

//	while(1)
//	{
//		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
//		if(master_setup.op_flag)//Check if we are up
//		{
//			actual_velocity =  get_velocity_actual(slave_number, slv_handles);
//			printf("velocity %d \n", actual_velocity);
//		}
//	}


	renable_ctrl_quick_stop(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	set_operation_mode(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	enable_operation(slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	//shutdown_operation(PV, slave_number, &master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	target_velocity = -300;
	while(1)
	{

		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag)//Check if we are up
		{
			set_velocity(target_velocity, slave_number, slv_handles);
			ack = target_velocity_reached(slave_number, target_velocity, tolerance, slv_handles);
			actual_velocity =  get_velocity_actual(slave_number, slv_handles);
			printf("velocity %d ack %d\n", actual_velocity, ack);
		}
		if(ack == 1)
		{
			break;
		}
	}

	printf("reached \n");

	return 0;
}


