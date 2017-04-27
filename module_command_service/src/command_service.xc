/**
 * @file command_service.xc
 * @brief Simple flash command service to store object dictionary values to flash memory
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <command_service.h>
#include <xs1.h>

#include <print.h>

#ifndef MSEC_STD
#define MSEC_STD 100000
#endif

#define TIME_FOR_LOOP            (500 * MSEC_STD)

static int flash_write_od_config(client interface i_co_communication i_canopen)
{
    /* read object dictionsry values and write to flash */

    printstrln("Command scheduled - notthing to do now");

    /* Simulate a huge amount of processing time */
    timer tsim;
    unsigned time_current = 0;
    const unsigned time_to_wait = (5000 * MSEC_STD);

    tsim :> time_current;
    tsim when timerafter(time_current + time_to_wait) :> void;

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
