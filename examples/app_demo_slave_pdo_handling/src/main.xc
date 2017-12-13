/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <ComEtherCAT-rev-a.bsp>
#include <CoreC2X.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <co_interface.h>
#include <canopen_interface_service.h>
#include <pdo_handler.h>
#include <ethercat_service.h>
#include <reboot.h>

#define DEBUG_CONSOLE_PRINT       0
#define MAX_TIME_TO_WAIT_SDO      100000

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

#ifdef CORE_C2X /* ports for the C2X */
port c2Xwatchdog = WD_PORT_TICK;
port c2Xled = LED_PORT_4BIT_X_nG_nB_nR;
#endif

/* Test application handling pdos from EtherCat */
static void pdo_service(client interface i_pdo_handler_exchange i_pdo, client interface i_co_communication i_co)
{
    timer t;
    unsigned char device_in_opstate = 0;

    unsigned int delay = 100000;
    unsigned int time = 0;
    unsigned int analog_value = 0;
    unsigned int comm_status = 0;

    pdo_values_t InOut = {0};
    pdo_values_t InOutOld = {0};
    t :> time;

    printstrln("Starting PDO protocol");
    while(1)
    {
        device_in_opstate = i_co.in_operational_state();
        if (!device_in_opstate) {
            t :> time;
            t when timerafter(time+delay) :> time;

            continue;
        }

        { InOut, comm_status } = i_pdo.pdo_exchange_app(InOut);

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

        if (InOutOld.tuning_command != InOut.tuning_command)
        {
            printstr("Tuning Status Data: ");
            printhexln(InOut.tuning_status);
        }

        if (InOutOld.user_mosi != InOut.user_mosi)
        {
            printstr("MISO Data: ");
            printhexln(InOut.user_miso);
        }

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

//    for (size_t i = 0; i < object_list_size; i+=2) {
//        {value, void, error} = i_co.get_object_value(g_listarrayobjects[i], g_listarrayobjects[i+1]);
//        printstr("Object 0x"); printhex(g_listarrayobjects[i]); printstr(":"); printhex(g_listarrayobjects[i+1]);
//        printstr(" = "); printintln(value);
        t :> time;
        InOut.timestamp = time;

        t when timerafter(time+delay) :> time;
    }

}

int main(void) {
    /* EtherCat Communication channels */
    interface i_pdo_handler_exchange i_pdo;
    interface i_foe_communication i_foe;
    interface i_co_communication i_co[CO_IF_COUNT];
    interface EtherCATRebootInterface i_ecat_reboot;

    par
    {
        /* EtherCAT Communication Handler Loop */
        on tile[IF1_TILE] :
        {
            par {
                ethercat_service(i_ecat_reboot, i_pdo, i_co, null,
                        i_foe, ethercat_ports);
                reboot_service_ethercat(i_ecat_reboot);

            }
        }

        /* Test application handling pdos from EtherCat */
        on tile[APP_TILE] :
        {
            pdo_service(i_pdo, i_co[1]);
        }

    }

    return 0;
}

