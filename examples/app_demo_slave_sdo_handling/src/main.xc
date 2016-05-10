/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_BOARD_REQUIRED>
#include <IMF_BOARD_REQUIRED>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_service.h>
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


static void sdo_handler(client interface i_coe_communication i_coe)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    while (1) {
        select {
            case i_coe.object_changed():
                uint16_t object = i_coe.get_object_changed();
                uint32_t value = i_coe.get_object_value(object, 0);

                printstr("Object changed: 0x");
                printhex(object);
                printstr(" = 0x"); printhexln(value);
                break;
        }

        t when timerafter(time+delay) :> time;

    }
}

int main(void)
{
	chan eoe_in;   		// Ethernet from module_ethercat to consumer
	chan eoe_out;  		// Ethernet from consumer to module_ethercat
	chan eoe_sig;
	chan foe_in;   		// File from module_ethercat to consumer
	chan foe_out;  		// File from consumer to module_ethercat
	chan pdo_in;
	chan pdo_out;

	interface i_coe_communication i_coecomm;

	par
	{
		/* EtherCAT Communication Handler Loop */
		on tile[COM_TILE] :
		{
			ethercat_service(i_coecomm, eoe_out, eoe_in, eoe_sig,
			                foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
		}

		/* Test application handling pdos from EtherCat */
		on tile[APP_TILE] :
		{
#if 0 /* Temporarily removed due to incompatibilities with the current cia402_wrapper.h */
			pdo_handler(pdo_out, pdo_in);
#endif
			sdo_handler(i_coecomm);
		}
	}

	return 0;
}

