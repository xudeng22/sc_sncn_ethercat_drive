/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <stdio.h>
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include "ethercat_setup.h"

int main()
{
	int slave_number = 0;
	int blink = 0;

	/* Initialize EtherCAT Master */
	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

	printf("starting Master application\n");
	while(1)
	{
		/* Update the process data (EtherCAT packets) sent/received from the node */
		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

		if(master_setup.op_flag) /*Check if the master is active*/
		{
			/* Write Process data */
			slv_handles[slave_number].motorctrl_out = 12;
			slv_handles[slave_number].torque_setpoint = 200;
			slv_handles[slave_number].speed_setpoint = 4000;
			slv_handles[slave_number].position_setpoint = 10000;
			slv_handles[slave_number].operation_mode = 125;

			slv_handles[slave_number].user1_out = ((blink == 0) ? 0xa5a5a5a5 : 0x5a5a5a5a);
			slv_handles[slave_number].user2_out = ((blink == 0) ? 0xdeadbeef : 0xbeefdead);
			slv_handles[slave_number].user3_out = ((blink == 0) ? 0xc0dec001 : 0xc001c0de);
			slv_handles[slave_number].user4_out = ((blink == 0) ? 0x55aa55aa : 0xaa55aa55);

			/* Read Process data */
			printf("Status: %d\n", slv_handles[slave_number].motorctrl_status_in);
			printf("Position: %d \n", slv_handles[slave_number].position_in);
			printf("Speed: %d\n", slv_handles[slave_number].speed_in);
			printf("Torque: %d\n", slv_handles[slave_number].torque_in);
			printf("Operation Mode disp: %d\n", slv_handles[slave_number].operation_mode_disp);

			printf("Userdata 1:      0x%x\n", slv_handles[slave_number].user1_in);
			printf("Userdata 2:      0x%x\n", slv_handles[slave_number].user2_in);
			printf("Userdata 3:      0x%x\n", slv_handles[slave_number].user3_in);
			printf("Userdata 4:      0x%x\n", slv_handles[slave_number].user4_in);

			blink = (blink + 1) % 2;
		}
	}

	return 0;
}



