/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
//#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include "ethercat_setup.h"
#include <curses.h> // required
#include <stdio.h>
#include <stdint.h>
#include <ctype.h>

int r,c, // current row and column (upper-left is (0,0))
nrows, // number of rows in window
ncols; // number of columns in window

///* Write Process data */
//slv_handles[slave_number].motorctrl_out = 12;
//slv_handles[slave_number].torque_setpoint = 200;
//slv_handles[slave_number].speed_setpoint = 4000;
//slv_handles[slave_number].position_setpoint = 10000;
//slv_handles[slave_number].operation_mode = 125;
//
///* Read Process data */
//printf("Status: %d\n", slv_handles[slave_number].motorctrl_status_in);
//printf("Position: %d \n", slv_handles[slave_number].position_in);
//printf("Speed: %d\n", slv_handles[slave_number].speed_in);
//printf("Torque: %d\n", slv_handles[slave_number].torque_in);
//printf("Operation Mode disp: %d\n", slv_handles[slave_number].operation_mode_disp);

#define OPMODE_TUNING    (-128)
#define DISPLAY_LINE 10

void draw(char dc)
{
    move(r,c); // curses call to move cursor to row r, column c
    if (dc == '\n')
        dc = '.';
    delch(); insch(dc); // curses calls to replace character under cursor by dc
    refresh(); // curses call to update screen
    c++; // go to next row
    // check for need to shift right or wrap around
    if (c == ncols) {
        c = 0;
        r++;
        if (r == nrows) r = DISPLAY_LINE;
    }
}

int main(int argc, char *argv[])
{
    char d;
    WINDOW *wnd;
    int slave_number = 0;
    //take arg 1 as slave number (1 is the first slave)
    if (argc > 1)
        slave_number = strtol(argv[1], NULL, 10)-1;

    /* Initialize EtherCAT Master */
    init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
    master_activate_operation(&master_setup);

    //init ncurses
    wnd = initscr(); // curses call to initialize window
    //cbreak(); // curses call to set no waiting for Enter key
    noecho(); // curses call to set no echoing
    getmaxyx(wnd,nrows,ncols); // curses call to find size of window
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay

    r = DISPLAY_LINE; c = 0;
    int i = 0;
    int value = 0;
    char mode = '@';
    char mode_2 = '@';
    char mode_3 = '@';
    int sign = 1;
    int ack = 0;
    int quit = 0;
    int offset = 0;
    int motor_polarity = 0, sensor_polarity = 0, torque_control_flag = 0, position_ctrl_flag = 0, brake_flag = 0;
    int pole_pairs = 0;
    int target_position = 0;
    int target_torque = 0;
    int position_limit = 0;

    int status_mux = 0;
    unsigned char statusword = 0;
    unsigned short controlword = 0;

    /* Write Process data */
    slv_handles[slave_number].motorctrl_out = 0; //controlword
    slv_handles[slave_number].torque_setpoint = 0;
    slv_handles[slave_number].speed_setpoint = 0;
    slv_handles[slave_number].position_setpoint = 0;
    slv_handles[slave_number].operation_mode = OPMODE_TUNING;
    slv_handles[slave_number].operation_mode_disp = 0;
    /* Update the process data (EtherCAT packets) sent/received from the node */
    pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);


    //set the operation mode to tuning
    while (slv_handles[slave_number].operation_mode_disp != (OPMODE_TUNING & 0xff)) {
        /* Update the process data (EtherCAT packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        statusword = (unsigned char)((slv_handles[slave_number].motorctrl_status_in) & 0xff);
        if ((statusword & 0x08) == 0x08) {
            slv_handles[slave_number].motorctrl_out = 0x0080;  /* Fault reset */
        }
    }
    slv_handles[slave_number].motorctrl_out = 0;  //reset control word

    //init prompt
    move(DISPLAY_LINE, 0);
    clrtoeol();
    printw("> ");
    c=2;

    //main loop
    while (1) {
        /* Update the process data (EtherCAT packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        status_mux = (slv_handles[slave_number].motorctrl_status_in) & 0xff;
        statusword = (unsigned char)((slv_handles[slave_number].motorctrl_status_in >> 8) & 0xff);


        if (statusword == (controlword & 0xff)) { //control word received by slave
            slv_handles[slave_number].motorctrl_out = 0; //reset control word
            controlword = 0;
        }

        if (slv_handles[slave_number].operation_mode_disp == 0) { //quit
            break;
        }

        //receive and print data
        if(master_setup.op_flag) {/*Check if the master is active*/
            //demux received data

            switch(status_mux) {
            case 0://flags
                brake_flag = slv_handles[slave_number].user4_in & 1;
                position_ctrl_flag = (slv_handles[slave_number].user4_in >> 1) & 1;
                torque_control_flag = (slv_handles[slave_number].user4_in >> 2) & 1;
                sensor_polarity = (slv_handles[slave_number].user4_in >> 3) & 1;
                motor_polarity = (slv_handles[slave_number].user4_in >> 4) & 1;
                break;
            case 1://offset
                offset = slv_handles[slave_number].user4_in;
                break;
            case 2://pole pairs
                pole_pairs = slv_handles[slave_number].user4_in;
                break;
            case 3://target torque
                target_torque = slv_handles[slave_number].user4_in;
                break;
            case 4://position limit
                position_limit = slv_handles[slave_number].user4_in;
                break;
            default://target position
                target_position = slv_handles[slave_number].user4_in;
                break;
            }

            //print
            int line = 0;
            move(line, 0);
            clrtoeol();
            printw("Position %14d | Velocity %4d",  slv_handles[slave_number].position_in, slv_handles[slave_number].speed_in);
            line++;
            move(line, 0);
            clrtoeol();
            printw("Torque computed %4d    | Torque sensor %d", slv_handles[slave_number].torque_in, slv_handles[slave_number].user1_in);
//            printw("controlword %4d    | statusword %d", slv_handles[slave_number].motorctrl_out & 0xff, statusword);
            line++;
            move(line, 0);
            clrtoeol();
            printw("Offset %4d             | Pole pairs %2d", offset, pole_pairs);
            line++;
            move(line,0);
            clrtoeol();
            if (motor_polarity == 0)
                printw("Motor polarity normal   | ");
            else
                printw("Motor polarity inverted | ");
            if (sensor_polarity == 0)
                printw("Sensor polarity normal");
            else
                printw("Sensor polarity inverted");
            line++;
            move(line,0);
            clrtoeol();
            if (torque_control_flag == 0)
                printw("Torque control off      | ");
            else
                printw("Torque control %8d | ", target_torque);
            if (position_ctrl_flag == 0)
                printw("Position control off");
            else
                printw("Position control %9d", target_position);
            line++;
            move(line,0);
            clrtoeol();
            if (brake_flag == 0)
                printw("Brake blocking");
            else
                printw("Brake released");
            if (position_limit > 0) {
                printw("          | Position limit %d", position_limit);
            }
        }

        move(DISPLAY_LINE-3, 0);
        printw("Commands: b - Release/Block Brake; a - find offset");
        move(DISPLAY_LINE-2, 0);
        printw("Commands: t - activate torque mode; r - reverse direction");

        //read user input
        d = getch(); // curses call to input from keyboard
        if (d == 'q') {
            slv_handles[slave_number].position_setpoint = 0;
            slv_handles[slave_number].operation_mode = 0;
            quit = 1;
        } else if (d == KEY_BACKSPACE || d == KEY_DC || d == 127) {
            move(r,0);
            clrtoeol();
            value = 0;
            mode = '@';
            mode_2 = '@';
            mode_3 = '@';
            sign = 1;
            c = 0;
        } else if (d != ERR) {
            draw(d); // draw the character
            //parse input
            if(isdigit(d)>0) {
                value *= 10;
                value += d - '0';
            } else if (d == '-') {
                sign = -1;
            } else if (d != ' ' && d != '\n') {
                if (mode == '@') {
                    mode = d;
                } else if (mode_2 == '@') {
                    mode_2 = d;
                } else {
                    mode_3 = d;
                }
            }

            //set command
            if (d == '\n') {
                move(DISPLAY_LINE, 0);
                clrtoeol();
                printw("> ");
                c = 2;
                move(nrows-1, 0);
                clrtoeol();
                value *= sign;
                printw("value %d, mode %c (%X), mode_2 %c, mode_3 %c", value, mode, mode, mode_2, mode_3);
                slv_handles[slave_number].position_setpoint = value;
                controlword = ((mode_2 & 0xff) << 8) | (mode & 0xff);
                slv_handles[slave_number].motorctrl_out = controlword;
                slv_handles[slave_number].user4_out         = mode_3 & 0xff;
                value = 0;
                mode = '@';
                mode_2 = '@';
                mode_3 = '@';
                sign = 1;
            }
        }
    }

    endwin(); // curses call to restore the original window and leave

}


