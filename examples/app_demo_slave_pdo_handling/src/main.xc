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
    unsigned int analog_value = 0;

    uint16_t status = 255;
    int i = 0;
    pdo_handler_values_t InOut = {0};
    pdo_handler_values_t InOutOld = {0};
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

        t when timerafter(time+delay) :> time;
    }

}

int main(void) {
    /* EtherCat Communication channels */
interface    i_coe_communication i_coe;
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

