/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <motor_define.h>
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
        if (r == nrows) r = 4;
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

    //init ncurses
    wnd = initscr(); // curses call to initialize window
    //cbreak(); // curses call to set no waiting for Enter key
    noecho(); // curses call to set no echoing
    getmaxyx(wnd,nrows,ncols); // curses call to find size of window
    clear(); // curses call to clear screen, send cursor to position (0,0)
    refresh(); // curses call to implement all changes since last refresh
    nodelay(stdscr, TRUE); //no delay

    r = 4; c = 0;
    int i = 0;
    int value = 0;
    char mode = 0;
    int sign = 1;
    int ack = 0;
    int quit = 0;
    int offset_clk = 0, offset_cclk=0, sensor_offset = 0;
    int winding_type = 0, polarity = 0, field_control_flag = 0;
    int pole_pairs = 0;

    /* Write Process data */
    slv_handles[slave_number].motorctrl_out = 0;
    slv_handles[slave_number].torque_setpoint = 0;
    slv_handles[slave_number].speed_setpoint = 0;
    slv_handles[slave_number].position_setpoint = 0;
    slv_handles[slave_number].operation_mode = 0;
    slv_handles[slave_number].operation_mode_disp = 0;

    while (1) {
        /* Update the process data (EtherCAT packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        if (quit > 100)
            break;

        if (slv_handles[slave_number].operation_mode_disp & 0x80) {
            slv_handles[slave_number].operation_mode = 6;
        } else {
            if (slv_handles[slave_number].operation_mode == 6 && quit) //quit enabled and received
                quit++;
        }

        //receive and print data
        if(master_setup.op_flag) /*Check if the master is active*/
        {   //print
            move(0, 0);
            clrtoeol();
            int16_t peak_current = slv_handles[slave_number].position_in >> 16;
            int16_t field = slv_handles[slave_number].position_in;
            printw("Peak current %4d | Velocity %4d    | Field %4d          | Torque %4d",
                    peak_current, slv_handles[slave_number].speed_in, field, slv_handles[slave_number].torque_in);
            move(1, 0);
            clrtoeol();
            int status_mux = slv_handles[slave_number].operation_mode_disp & 0x7f;
            switch(status_mux) {
            case 0:
                offset_clk = slv_handles[slave_number].motorctrl_status_in;
                break;
            case 1:
                offset_cclk = slv_handles[slave_number].motorctrl_status_in;
                break;
            case 2:
                sensor_offset = slv_handles[slave_number].motorctrl_status_in;
                break;
            case 3:
                winding_type = (slv_handles[slave_number].motorctrl_status_in & 0b001);
                polarity = (slv_handles[slave_number].motorctrl_status_in & 0b010);
                field_control_flag = (slv_handles[slave_number].motorctrl_status_in & 0b100);
                pole_pairs = slv_handles[slave_number].motorctrl_status_in >> 3;
            }
            printw("Offset clk %4d   | Offset cclk %4d | Sensor Offset %5d | Pole pairs %2d",
                   offset_clk, offset_cclk, sensor_offset, pole_pairs);
            move(2, 0);
            clrtoeol();
            if (polarity)
                printw("Polarity Inverted | ");
            else
                printw("Polarity  Normal  | ");
            if (winding_type)
                printw("Delta Winding    | ");
            else
                printw("Star  Winding    | ");
            if (field_control_flag)
                printw("Field control on");
            else
                printw("Field control off");
        }

        //read user input
        d = getch(); // curses call to input from keyboard
        if (d == 'q') {
            slv_handles[slave_number].position_setpoint = 0;
            slv_handles[slave_number].operation_mode = 0;
            quit = 1;
        } else if (d != ERR) {
            draw(d); // draw the character
            //parse input
            if(isdigit(d)>0) {
                value *= 10;
                value += d - '0';
            } else if (d == '-') {
                sign = -1;
            } else if (d != ' ' && d != '\n') {
                mode = d;
            }

            //set command
            if (d == '\n') {
                move(4, 0);
                clrtoeol();
                move(3, 0);
                clrtoeol();
                value *= sign;
                printw("value %d, mode %c", value, mode);
                slv_handles[slave_number].position_setpoint = value;
                slv_handles[slave_number].operation_mode = mode;
                value = 0;
                mode = 0;
                sign = 1;
                c = 0;
            }
        }
    }

    endwin(); // curses call to restore the original window and leave

}


