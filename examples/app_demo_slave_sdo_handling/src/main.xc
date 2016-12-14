/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C22-rev-a.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

//#include <canod.h>
#include <canopen_service.h>
#include <ethercat_service.h>
//#include <reboot.h>
#if 0 /* Temporarily removed due to incompatibilities with the current cia402_wrapper.h */
#include <cia402_wrapper.h>
#endif


EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

#if 0 /* Temporarily removed due to incompatibilities with the current cia402_wrapper.h */
/* Test application handling pdos from EtherCat */
static void pdo_handler(chanend pdo_out, chanend pdo_in)
{
	timer t;

	unsigned int delay = 100000;
	unsigned int time = 0;

	uint16_t status = 255;
	int i = 0;
	ctrl_proto_values_t InOut;
	ctrl_proto_values_t InOutOld;
	InOut = init_ctrl_proto();
	t :> time;

	while(1)
	{
		ctrlproto_protocol_handler_function(pdo_out,pdo_in,InOut);

		i++;
		if(i >= 999) {
			i = 100;
		}

		InOut.position_actual = InOut.target_position;
		InOut.torque_actual = InOut.target_torque;
		InOut.velocity_actual = InOut.target_velocity;
		InOut.status_word = InOut.control_word;
		InOut.operation_mode_display = InOut.operation_mode;

		/* Mirror user defined fields */
		InOut.user1_out = InOut.user1_in;
		InOut.user2_out = InOut.user2_in;
		InOut.user3_out = InOut.user3_in;
		InOut.user4_out = InOut.user4_in;

		if(InOutOld.control_word != InOut.control_word)
		{
			printstr("\nMotor: ");
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
#if 0
	   if (InOutOld.user1_in != InOut.user1_in)
	   {
	       printstr("\nUser 1 Data: ");
	       printhexln(InOut.user1_in);
	   }

	   if (InOutOld.user2_in != InOut.user2_in)
	   {
	       printstr("User 2 Data: ");
	       printhexln(InOut.user2_in);
	   }

	   if (InOutOld.user3_in != InOut.user3_in)
	   {
	       printstr("User 1 Data: ");
	       printhexln(InOut.user3_in);
	   }

	   if (InOutOld.user4_in != InOut.user4_in)
	   {
	       printstr("User 1 Data: ");
	       printhexln(InOut.user4_in);
	   }
#endif

	   InOutOld.control_word 	= InOut.control_word;
	   InOutOld.target_position = InOut.target_position;
	   InOutOld.target_velocity = InOut.target_velocity;
	   InOutOld.target_torque = InOut.target_torque;
	   InOutOld.operation_mode = InOut.operation_mode;
	   InOutOld.user1_in        = InOut.user1_in;
	   InOutOld.user2_in        = InOut.user2_in;
	   InOutOld.user3_in        = InOut.user3_in;
	   InOutOld.user4_in        = InOut.user4_in;


	   t when timerafter(time+delay) :> time;
	}

}
#endif

#define MAX_TIME_TO_WAIT_SDO      100000

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

static void read_od_config(client interface ODCommunicationInterface i_od)
{
    /* Read the values of hand picked objects */
    uint32_t value    = 0;

    size_t object_list_size = sizeof(g_listobjects) / sizeof(g_listobjects[0]);

    for (size_t i = 0; i < object_list_size; i++) {
        value = i_od.get_object_value(g_listobjects[i], 0);
        printstr("Object 0x"); printhex(g_listobjects[i]); printstr(" = "); printintln(value);
    }

    object_list_size = sizeof(g_listarrayobjects) / sizeof(g_listarrayobjects[0]);

    for (size_t i = 0; i < object_list_size; i+=2) {
        value = i_od.get_object_value(g_listarrayobjects[i], g_listarrayobjects[i+1]);
        printstr("Object 0x"); printhex(g_listarrayobjects[i]); printstr(":"); printhex(g_listarrayobjects[i+1]);
        printstr(" = "); printintln(value);
    }

    return;
}

static void sdo_handler(client interface ODCommunicationInterface i_od)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    int read_config = 0;

    while (1) {
//        select {
//            case i_od.configuration_ready():
//                printstrln("Master requests OP mode - cyclic operation is about to start.");
//                read_config = 1;
//                break;
//        }
        read_config = i_od.configuration_ready();

        if (read_config) {
            read_od_config(i_od);
            printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");
            i_od.configuration_done(); /* clear notification */
        }

        t when timerafter(time+delay) :> time;

    }
}

int main(void)
{
    /* EtherCat Communication channels */
    interface i_foe_communication i_foe;
    //interface EtherCATRebootInterface i_ecat_reboot;
    interface PDOCommunicationInterface i_pdo[3];
    interface ODCommunicationInterface i_od[3];

	par
	{
		/* EtherCAT Communication Handler Loop */
		on tile[COM_TILE] :
		{
		    par
		    {
                ethercat_service(null,
                                   i_od[0],
                                   i_pdo[0],
                                   null,
                                   i_foe,
                                   ethercat_ports);

                canopen_service(i_pdo, i_od);
            }
        }

		/* Test application handling pdos from EtherCat */
		on tile[APP_TILE] :
		{
#if 0 /* Temporarily removed due to incompatibilities with the current cia402_wrapper.h */
			pdo_handler(pdo_out, pdo_in);
#endif
			sdo_handler(i_od[2]);
		}
	}

	return 0;
}

