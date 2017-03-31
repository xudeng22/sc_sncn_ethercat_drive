/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <COM_ECAT-rev-a.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <canopen_service.h>
#include <ethercat_service.h>

#include <reboot.h>

#define DEBUG_CONSOLE_PRINT       0
#define MAX_TIME_TO_WAIT_SDO      100000

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

/* function declaration of later used functions */
static void read_od_config(client interface i_co_communication i_co);

/* Wait until the EtherCAT enters operation mode. At this point the master
 * should have finished all client configuration. */
static void sdo_configuration(client interface i_co_communication i_co)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    int sdo_configured = 0;

    while (sdo_configured == 0) {
        if (i_co.configuration_get()) {
            printstrln("Master requests OP mode - cyclic operation is about to start.");
            sdo_configured = 1;
        }

        t when timerafter(time+delay) :> time;
    }

    /* comment in the read_od_config() function to print the object values */
//    read_od_config(i_coe);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_co.configuration_done();
}

/* Test application handling pdos from EtherCat */
static void pdo_service(client interface i_co_communication i_co)
{
<<<<<<< HEAD
	timer t;

	unsigned int delay = 100000;
	unsigned int time = 0;

	uint16_t status = 255;
	int i = 0;
	pdo_values_t InOut;
	pdo_values_t InOutOld;
	InOut = pdo_init();
	t :> time;

	sdo_configuration(i_co);

	printstrln("Starting PDO protocol");

	while(1)
	{
		InOut = i_co.pdo_exchange_app(InOut);

		i++;
		if(i >= 999) {
			i = 100;
		}

        InOut.actual_position        = InOut.target_position;
        InOut.actual_torque          = InOut.target_torque;
        InOut.actual_velocity        = InOut.target_velocity;
        InOut.status_word            = InOut.control_word;
        InOut.operation_mode_display = InOut.operation_mode;

#if 1 /* Mirror user defined fields */
		InOut.user1_out = InOut.user1_in;
		InOut.user2_out = InOut.user2_in;
		InOut.user3_out = InOut.user3_in;
		InOut.user4_out = InOut.user4_in;
#endif

#if 0
<<<<<<< HEAD

=======
>>>>>>> develop
		if(InOutOld.control_word != InOut.control_word)
		{
			printstr("\nControl word: ");
			printintln(InOut.control_word);
		}

		if(InOutOld.operation_mode != InOut.operation_mode )
		{
			printstr("\nOperation mode: ");
			printintln(InOut.operation_mode);
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
#endif
<<<<<<< HEAD

=======
>>>>>>> develop
	   InOutOld.control_word 	= InOut.control_word;
	   InOutOld.target_position = InOut.target_position;
	   InOutOld.target_velocity = InOut.target_velocity;
	   InOutOld.target_torque   = InOut.target_torque;
	   InOutOld.operation_mode  = InOut.operation_mode;

#if 0 /* Print user PDOs */
	   if (InOutOld.user1_in != InOut.user1_in)
	   {
	       printstr("\nUser 1 Data: ");
	       printintln(InOut.user1_in);
	   }

	   if (InOutOld.user2_in != InOut.user2_in)
	   {
	       printstr("User 2 Data: ");
	       printintln(InOut.user2_in);
	   }

	   if (InOutOld.user3_in != InOut.user3_in)
	   {
	       printstr("User 3 Data: ");
	       printintln(InOut.user3_in);
	   }

	   if (InOutOld.user4_in != InOut.user4_in)
	   {
	       printstr("User 4 Data: ");
	       printintln(InOut.user4_in);
	   }
#endif
=======
    timer t;

    unsigned int delay = 100000;
    unsigned int time = 0;
    unsigned int analog_value = 0;

    pdo_handler_values_t InOut = {0};
    pdo_handler_values_t InOutOld = {0};
    t :> time;

    sdo_configuration(i_coe);

    printstrln("Starting PDO protocol");
    while(1)
    {
        pdo_handler(i_pdo, InOut);

        /* Mirror incomimng value to the output */
        InOut.position_value  = InOut.target_position;
        InOut.torque_value    = InOut.target_torque;
        InOut.velocity_value  = InOut.target_velocity;
        InOut.statusword      = InOut.controlword;
        InOut.op_mode_display = InOut.op_mode;

        InOut.tuning_status            = InOut.tuning_command;
        InOut.user_miso                = InOut.user_mosi;
        InOut.secondary_position_value = InOut.offset_torque;
        InOut.secondary_velocity_value = ~InOut.offset_torque;

        /* mirror digital inputs */
        InOut.digital_input1 = InOut.digital_output1;
        InOut.digital_input2 = InOut.digital_output2;
        InOut.digital_input3 = InOut.digital_output3;
        InOut.digital_input4 = InOut.digital_output4;

        /* increment analog values */
        InOut.analog_input1 = analog_value + 1000;
        InOut.analog_input2 = analog_value + 2000;
        InOut.analog_input3 = analog_value + 3000;
        InOut.analog_input4 = analog_value + 4000;

        analog_value = analog_value >= 1000 ? 0 : analog_value + 1;

#if DEBUG_CONSOLE_PRINT == 1
        /*
         * Print updated values to the console
         */
        if(InOutOld.controlword != InOut.controlword)
        {
            printstr("\nMotor: ");
            printintln(InOut.controlword);
        }
>>>>>>> develop

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

<<<<<<< HEAD
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
static void read_od_config(client interface i_co_communication i_co)
{
    /* Read the values of hand picked objects */
    uint32_t value    = 0;
    uint8_t error = 0;
=======
        if(InOutOld.target_torque != InOut.target_torque )
        {
            printstr("\nTorque: ");
            printintln(InOut.target_torque);
        }
>>>>>>> develop

        if (InOutOld.tuning_command != InOut.tuning_command)
        {
            printstr("Tuning Status Data: ");
            printhexln(InOut.tuning_status);
        }

<<<<<<< HEAD
    for (size_t i = 0; i < object_list_size; i++) {
        {value, void, error} = i_co.get_object_value(g_listobjects[i], 0);
        printstr("Object 0x"); printhex(g_listobjects[i]); printstr(" = "); printintln(value);
    }
=======
        if (InOutOld.digital_output1 != InOut.digital_output1) {
            printstr("Digital output 1 = ");
            printintln(InOut.digital_output1);
        }

        if (InOutOld.digital_output2 != InOut.digital_output2) {
            printstr("Digital output 2 = ");
            printintln(InOut.digital_output2);
        }

        if (InOutOld.digital_output3 != InOut.digital_output3) {
            printstr("Digital output 3 = ");
            printintln(InOut.digital_output3);
        }

        if (InOutOld.digital_output4 != InOut.digital_output4) {
            printstr("Digital output 4 = ");
            printintln(InOut.digital_output4);
        }
#endif
>>>>>>> develop

        /*
         *  Update the local stored structure to recognize value changes
         */
        InOutOld.controlword     = InOut.controlword;
        InOutOld.target_position = InOut.target_position;
        InOutOld.target_velocity = InOut.target_velocity;
        InOutOld.target_torque   = InOut.target_torque;
        InOutOld.op_mode         = InOut.op_mode;
        InOutOld.tuning_command  = InOut.tuning_command;
        InOutOld.user_mosi       = InOut.user_mosi;
        InOutOld.offset_torque   = InOut.offset_torque;
        InOutOld.digital_output1 = InOut.digital_output1;
        InOutOld.digital_output2 = InOut.digital_output2;
        InOutOld.digital_output3 = InOut.digital_output3;
        InOutOld.digital_output4 = InOut.digital_output4;

<<<<<<< HEAD
    for (size_t i = 0; i < object_list_size; i+=2) {
        {value, void, error} = i_co.get_object_value(g_listarrayobjects[i], g_listarrayobjects[i+1]);
        printstr("Object 0x"); printhex(g_listarrayobjects[i]); printstr(":"); printhex(g_listarrayobjects[i+1]);
        printstr(" = "); printintln(value);
=======
        t when timerafter(time+delay) :> time;
>>>>>>> develop
    }

}

<<<<<<< HEAD

int main(void)
{
	/* EtherCat Communication channels */
=======
int main(void) {
    /* EtherCat Communication channels */
    interface i_coe_communication i_coe;
>>>>>>> develop
    interface i_foe_communication i_foe;
    interface i_co_communication i_co[3];
    interface EtherCATRebootInterface i_ecat_reboot;

<<<<<<< HEAD
	par
	{
		/* EtherCAT Communication Handler Loop */
		on tile[COM_TILE] :
		{
		    par {
                    ethercat_service(i_ecat_reboot, i_co,
                                     null, i_foe, ethercat_ports);

                    reboot_service_ethercat(i_ecat_reboot);
                }
        }

		/* Test application handling pdos from EtherCat */
		on tile[APP_TILE] :
		{
             pdo_service(i_co[1]);
		}
	}
=======
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
>>>>>>> develop

    return 0;
}

