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

/* DEBUG output to check the values of the objects in the object dictionary */

/* list of OD objects, excluding PDO mapped and device specific objects */
static const uint16_t g_listobjects[] = {
   CIA402_FOLLOWING_ERROR_WINDOW,
   CIA402_FOLLOWING_ERROR_TIMEOUT,
   CIA402_POSITION_RANGELIMIT,
   CIA402_SOFTWARE_POSITION_LIMIT,
   CIA402_POSITION_OFFSET,
   CIA402_VELOCITY_OFFSET,
   CIA402_TORQUE_OFFSET,
   CIA402_INTERPOL_TIME_PERIOD,
   CIA402_FOLLOWING_ERROR,
   CIA402_SENSOR_SELECTION_CODE,
   CIA402_MAX_TORQUE,
   CIA402_MAX_CURRENT,
   CIA402_MOTOR_RATED_CURRENT,
   CIA402_MOTOR_RATED_TORQUE,
   CIA402_HOME_OFFSET,
   CIA402_POLARITY,
   CIA402_MAX_PROFILE_VELOCITY,
   CIA402_MAX_MOTOR_SPEED,
   CIA402_PROFILE_VELOCITY,
   CIA402_END_VELOCITY,
   CIA402_PROFILE_ACCELERATION,
   CIA402_PROFILE_DECELERATION,
   CIA402_QUICK_STOP_DECELERATION,
   CIA402_MOTION_PROFILE_TYPE,
   CIA402_TORQUE_SLOPE,
   CIA402_TORQUE_PROFILE_TYPE,
   CIA402_POSITION_ENC_RESOLUTION,
   CIA402_GEAR_RATIO,
   CIA402_POSITIVE_TORQUE_LIMIT,
   CIA402_NEGATIVE_TORQUE_LIMIT,
   CIA402_MAX_ACCELERATION,
   CIA402_HOMING_METHOD,
   CIA402_HOMING_SPEED,
   CIA402_HOMING_ACCELERATION,
   CIA402_MOTOR_TYPE,
   CIA402_SUPPORTED_DRIVE_MODES,
   LIMIT_SWITCH_TYPE,
   COMMUTATION_OFFSET_CLKWISE,
   COMMUTATION_OFFSET_CCLKWISE,
   MOTOR_WINDING_TYPE,
   SNCN_SENSOR_POLARITY
};

/* Array objects also need the subindex for complete addressing */
static const uint16_t g_listarrayobjects[] = {
   CIA402_SUPPORTED_DRIVE_MODES, 1,
   /* Sub 01 = nominal current, Sub 02 = ???, Sub 03 = pole pair number, Sub 04 = max motor speed, Sub 05 = motor torque constant */
   CIA402_MOTOR_SPECIFIC, 1,
   CIA402_MOTOR_SPECIFIC, 3,
   CIA402_MOTOR_SPECIFIC, 4,
   CIA402_MOTOR_SPECIFIC, 5,
   /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */
   CIA402_CURRENT_GAIN, 1,
   CIA402_CURRENT_GAIN, 2,
   CIA402_CURRENT_GAIN, 3,
   /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */
   CIA402_VELOCITY_GAIN, 1,
   CIA402_VELOCITY_GAIN, 2,
   CIA402_VELOCITY_GAIN, 3,
   /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */
   CIA402_POSITION_GAIN, 1,
   CIA402_POSITION_GAIN, 2,
   CIA402_POSITION_GAIN, 3,
};

/* This function simply iterates throuch the objects given in /see g_listobjects and /see g_listarrayobjects. */
static void read_od_config(client interface i_coe_communication i_coe)
{
    /* Read the values of hand picked objects */
    uint32_t value    = 0;

    size_t object_list_size = sizeof(g_listobjects) / sizeof(g_listobjects[0]);

    for (size_t i = 0; i < object_list_size; i++) {
        value = i_coe.get_object_value(g_listobjects[i], 0);
        printstr("Object 0x"); printhex(g_listobjects[i]); printstr(" = "); printintln(value);
    }

    object_list_size = sizeof(g_listarrayobjects) / sizeof(g_listarrayobjects[0]);

    for (size_t i = 0; i < object_list_size; i+=2) {
        value = i_coe.get_object_value(g_listarrayobjects[i], g_listarrayobjects[i+1]);
        printstr("Object 0x"); printhex(g_listarrayobjects[i]); printstr(":"); printhex(g_listarrayobjects[i+1]);
        printstr(" = "); printintln(value);
    }

    return;
}
/*/DEBUG */

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

