/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <COM_ECAT-rev-a.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_service.h>
#include <pdo_handler.h>
#include <reboot.h>

#define MAX_TIME_TO_WAIT_SDO      100000

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

/* function declaration of later used functions */
static void read_od_config(client interface i_coe_communication i_coe);

/* Wait until the EtherCAT enters operation mode. At this point the master
 * should have finished all client configuration. */
static void sdo_configuration(client interface i_coe_communication i_coe)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    int sdo_configured = 0;

    while (sdo_configured == 0) {
        select {
            case i_coe.configuration_ready():
                printstrln("Master requests OP mode - cyclic operation is about to start.");
                sdo_configured = 1;
                break;
        }

        t when timerafter(time+delay) :> time;
    }

    /* comment in the read_od_config() function to print the object values */
//    read_od_config(i_coe);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_coe.configuration_done();
}

/* Test application handling pdos from EtherCat */
static void pdo_service(client interface i_coe_communication i_coe, client interface i_pdo_communication i_pdo)
{
	timer t;

	unsigned int delay = 100000;
	unsigned int time = 0;

	uint16_t status = 255;
	int i = 0;
	pdo_handler_values_t InOut;
	pdo_handler_values_t InOutOld = { 0 };
	InOut = pdo_handler_init();
	t :> time;

	sdo_configuration(i_coe);

	printstrln("Starting PDO protocol");
	while(1)
	{
		pdo_handler(i_pdo, InOut);

		i++;
		if(i >= 999) {
			i = 100;
		}

		InOut.position_value = InOut.target_position;
		InOut.torque_value = InOut.target_torque;
		InOut.velocity_value = InOut.target_velocity;
		InOut.statusword = InOut.controlword;
		InOut.op_mode_display = InOut.op_mode;

		InOut.additional_feedbacksensor_value = InOut.offset_torque;
		InOut.tuning_result = InOut.tuning_status;

		/*
		 *  The PDOs InOut.tuning_control and InOut.command_pid_update don't have
		 * a associated incoming PDO so they are left out.
		 */

		if(InOutOld.controlword != InOut.controlword)
		{
			printstr("\nMotor: ");
			printintln(InOut.controlword);
		}

		if(InOutOld.op_mode != InOut.op_mode )
		{
			printstr("\nOperation mode: ");
			printintln(InOut.op_mode);
		}

		if(InOutOld.target_position != InOut.target_position)
		{
			printstr("\nPosition: ");
			printintln(InOut.target_position);
		}

		if(InOutOld.target_velocity != InOut.target_velocity)
		{
			printstr("\nSpeed: ");
			printintln(InOut.target_velocity);
		}

		if(InOutOld.target_torque != InOut.target_torque )
		{
			printstr("\nTorque: ");
			printintln(InOut.target_torque);
		}

	   InOutOld.controlword 	= InOut.controlword;
	   InOutOld.target_position = InOut.target_position;
	   InOutOld.target_velocity = InOut.target_velocity;
	   InOutOld.target_torque   = InOut.target_torque;
	   InOutOld.op_mode         = InOut.op_mode;

	   if (InOutOld.offset_torque != InOut.offset_torque)
	   {
	       printstr("\nOffset Torque Data: ");
	       printhexln(InOut.offset_torque);
	   }

	   if (InOutOld.tuning_status != InOut.tuning_status)
	   {
	       printstr("Tuning Status Data: ");
	       printhexln(InOut.tuning_status);
	   }

	   InOutOld.offset_torque        = InOut.offset_torque;
	   InOutOld.tuning_status        = InOut.tuning_status;

	   t when timerafter(time+delay) :> time;
	}

}

int main(void)
{
	/* EtherCat Communication channels */
    interface i_coe_communication i_coe;
    interface i_foe_communication i_foe;
    interface i_pdo_communication i_pdo;
    interface EtherCATRebootInterface i_ecat_reboot;

	par
	{
		/* EtherCAT Communication Handler Loop */
		on tile[COM_TILE] :
		{
		    par {
                    ethercat_service(i_ecat_reboot, i_coe, null,
                                     i_foe, i_pdo, ethercat_ports);
                    reboot_service_ethercat(i_ecat_reboot);
                }
        }

		/* Test application handling pdos from EtherCat */
		on tile[APP_TILE] :
		{
			pdo_service(i_coe, i_pdo);
		}
	}

	return 0;
}

