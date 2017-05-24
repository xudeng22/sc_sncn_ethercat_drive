/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C21-DX_G2.bsp>
#include <COM_ECAT-rev-a.bsp>

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
#include <file_service.h>
#include <spiffs_service.h>
#include <flash_service.h>

#define DEBUG_CONSOLE_PRINT       0
#define MAX_TIME_TO_WAIT_SDO      100000

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;

#ifdef CORE_C21_DX_G2 /* ports for the C21-DX-G2 */
port c21watchdog = WD_PORT_TICK;
port c21led = LED_PORT_4BIT_X_nG_nB_nR;
#endif

/* function declaration of later used functions */
static void read_od_config(client interface i_co_communication i_co);

/* Read most recent values for object dictionary values from flash (if existing) */
static int initial_od_read(client interface i_co_communication i_co)
{
    timer t;
    unsigned time;

    /* give the other services some time to start */
    t :> time;
    t when timerafter(time+100000000) :> void;

    printstrln("[DEBUG] start initial update dictionary");
    i_co.od_set_object_value(DICT_COMMAND_OBJECT, 0, OD_COMMAND_READ_CONFIG);
    enum eSdoState command_state = OD_COMMAND_STATE_IDLE;

    while (command_state <= OD_COMMAND_STATE_PROCESSING) {
        t :> time;
        t when timerafter(time+100000) :> void;

        {command_state, void, void} = i_co.od_get_object_value(DICT_COMMAND_OBJECT, 0);
        /* TODO: error handling, if the object could not be loaded then something weired happend and the online
         * dictionary should not be overwritten.
         *
         * FIXME: What happens if nothing is stored in flash?
         */
    }

    printstrln("[DEBUG] update dictionary complete");

    return 0;
}

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

        i_co.configuration_done();
        sdo_configured = 1;

        t when timerafter(time+delay) :> time;
    }

    /* comment in the read_od_config() function to print the object values */
//    read_od_config(i_coe);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_co.configuration_done();
}

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

    initial_od_read(i_co);
    printstrln("[DEBUG] update dictionary complete");

    sdo_configuration(i_co);
    device_in_opstate = 1; /* after sdo_configuration returns we are in opstate! */

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

    FlashDataInterface i_data[1];
    SPIFFSInterface i_spiffs[2];
    FlashBootInterface i_boot; /* FIXME necessary? */

    par
    {
        /* EtherCAT Communication Handler Loop */
        on tile[COM_TILE] :
        {
            par {
                ethercat_service(i_ecat_reboot, i_pdo, i_co, null,
                        i_foe, ethercat_ports);
                reboot_service_ethercat(i_ecat_reboot);

                flash_service(ports, i_boot, i_data, 1);
                file_service(i_spiffs[0], i_co[3]);
            }
        }

        /* Test application handling pdos from EtherCat */
        on tile[APP_TILE] :
        {
            pdo_service(i_pdo, i_co[1]);
        }

        on tile[IFM_TILE] :
        {
            spiffs_service(i_data[0], i_spiffs, 1);
        }
    }

    return 0;
}

