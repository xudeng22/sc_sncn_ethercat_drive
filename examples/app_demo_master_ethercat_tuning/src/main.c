/**
 * @file main.c
 * @brief Example Master App to test EtherCAT (on PC)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ctrlproto_m.h>
#include <ecrt.h>
#include <stdio.h>
#include <motor_define.h>
#include <sys/time.h>
#include <time.h>
#include "ethercat_setup.h"
#include <curses.h> // required
#include <stdio.h>
#include <ctype.h>

int r,c, // current row and column (upper-left is (0,0))
nrows, // number of rows in window
ncols; // number of columns in window

//int main()
//{
//	int slave_number = 0;
//
//	/* Initialize EtherCAT Master */
//	init_master(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
//
//	printf("starting Master application\n");
//	while(1)
//	{
//		/* Update the process data (EtherCAT packets) sent/received from the node */
//		pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);
//
//		if(master_setup.op_flag) /*Check if the master is active*/
//		{
//			/* Write Process data */
//			slv_handles[slave_number].motorctrl_out = 12;
//			slv_handles[slave_number].torque_setpoint = 200;
//			slv_handles[slave_number].speed_setpoint = 4000;
//			slv_handles[slave_number].position_setpoint = 10000;
//			slv_handles[slave_number].operation_mode = 125;
//
//			/* Read Process data */
//			printf("Status: %d\n", slv_handles[slave_number].motorctrl_status_in);
//			printf("Position: %d \n", slv_handles[slave_number].position_in);
//			printf("Speed: %d\n", slv_handles[slave_number].speed_in);
//			printf("Torque: %d\n", slv_handles[slave_number].torque_in);
//			printf("Operation Mode disp: %d\n", slv_handles[slave_number].operation_mode_disp);
//		}
//	}
//
//	return 0;
//}

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
        if (r == nrows) r = 3;
    }
}

int main()
{
    char d;
    WINDOW *wnd;
    int slave_number = 0;

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

    r = 3; c = 0;
    int i = 0;
    int value = 0;
    char mode = 0;
    int sign = 1;
    int last_value = 0;
    int last_mode;
    int ack = 0;
    int quit = 0;

    /* Write Process data */
    slv_handles[slave_number].motorctrl_out = 0;
    slv_handles[slave_number].torque_setpoint = 0;
    slv_handles[slave_number].speed_setpoint = 0;
    slv_handles[slave_number].position_setpoint = 0;
    slv_handles[slave_number].operation_mode = 6;

    while (1) {
        /* Update the process data (EtherCAT packets) sent/received from the node */
        pdo_handle_ecat(&master_setup, slv_handles, TOTAL_NUM_OF_SLAVES);

        if (slv_handles[slave_number].operation_mode_disp == 6) {
            slv_handles[slave_number].operation_mode = 6;
        }

        if(master_setup.op_flag) /*Check if the master is active*/
        {   //print
            move(0, 0);
            clrtoeol();
            printw("Velocity %d", slv_handles[slave_number].speed_in);
        }

        d = getch(); // curses call to input from keyboard
        if (d == 'q') {
            slv_handles[slave_number].position_setpoint = 0;
            slv_handles[slave_number].operation_mode = 0;
            quit = 1;
        } else if (d != ERR) {
            draw(d); // draw the character
            if(isdigit(d)>0) {
                value *= 10;
                value += d - '0';
            } else if (d == '-') {
                sign = -1;
            } else if (d != ' ' && d != '\n') {
                mode = d;
            }

            if (d == '\n') {
                move(3, 0);
                clrtoeol();
                move(2, 0);
                clrtoeol();
                value *= sign;
                printw("value %d, mode %c", value, mode);
//                slv_handles[slave_number].motorctrl_out = -20;
                last_value = value;
                last_mode = mode;
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


