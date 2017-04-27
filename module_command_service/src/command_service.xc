/**
 * @file command_service.xc
 * @brief Simple flash command service to store object dictionary values to flash memory
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <command_service.h>
#include <xs1.h>

#define MAX_TIME_TO_WAIT_SDO      100000
#define TIME_FOR_LOOP            (500 * 1000 * 1000)

static int flash_write_od_config(client interface i_co_communication i_canopen)
{
    /* read object dictionsry values and write to flash */

    return 1;
}

void command_service(client interface i_co_communication i_canopen)
{
    timer t;
    unsigned int time;
    t :> time;

//    delay_milliseconds(30000);

    while (1) {
        enum eSdoCommand command = i_canopen.command_ready();
        int command_result = 0;

        switch (command) {
        case OD_COMMAND_WRITE_CONFIG:
            command_result = flash_write_od_config(i_canopen);
            i_canopen.command_set_result(command_result);
            command_result = 0;
            break;

        case OD_COMMAND_NONE:
            break;
        default:
            break;
        }

        t when timerafter(time + TIME_FOR_LOOP) :> time;
    }
}
