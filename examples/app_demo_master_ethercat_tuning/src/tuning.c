/*
 * tuning.c
 *
 *  Created on: Nov 6, 2016
 *      Author: romuald
 */

#include "tuning.h"
#include "display.h"
#include <ctype.h>

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input)
{
    int status_mux = (pdo_input.statusword) & 0xff;

    switch(status_mux) {
    case 0://flags
        (*input).brake_flag = pdo_input.user_in_4 & 1;
        (*input).motorctrl_status = (pdo_input.user_in_4 >> 1) & 0b11;
        (*input).torque_control_flag = (pdo_input.user_in_4 >> 3) & 1;
        (*input).sensor_polarity = (pdo_input.user_in_4 >> 4) & 1;
        (*input).motor_polarity = (pdo_input.user_in_4 >> 5) & 1;
        break;
    case 1://offset
        (*input).offset = pdo_input.user_in_4;
        break;
    case 2://pole pairs
        (*input).pole_pairs = pdo_input.user_in_4;
        break;
    case 3://target
        (*input).target = pdo_input.user_in_4;
        break;
    case 4://min position limit
        (*input).min_position = pdo_input.user_in_4;
        break;
    case 5://max position limit
        (*input).max_position = pdo_input.user_in_4;
        break;
    case 6://max speed
        (*input).max_speed = pdo_input.user_in_4;
        break;
    case 7://max torque
        (*input).max_torque = pdo_input.user_in_4;
        break;
    case 8://max speed
        (*input).P_pos = pdo_input.user_in_4;
        break;
    case 9://max speed
        (*input).I_pos = pdo_input.user_in_4;
        break;
    case 10://max speed
        (*input).D_pos = pdo_input.user_in_4;
        break;
    default://max torque
        (*input).integral_limit_pos = pdo_input.user_in_4;
        break;
    }
    return ;
}

#if 1
void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, OutputValues *output, Cursor *cursor)
{
    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    char c = wgetch(wnd); // curses call to input from keyboard
    if (c == 'q') { //quit
        (*pdo_output).target_position = 0;
        (*pdo_output).opmode = 0;
    } else if (c == KEY_BACKSPACE || c == KEY_DC || c == 127) {//discard
        wmove(wnd, (*cursor).row, 0);
        wclrtoeol(wnd);
        wprintw(wnd, "> ");
        (*cursor).col = 2;
        (*output).mode_1 = '@';
        (*output).mode_2 = '@';
        (*output).mode_3 = '@';
        (*output).value = 0;
        (*output).sign = 1;
    } else if (c != ERR) {
        (*cursor).col = draw(wnd, c, (*cursor).row, (*cursor).col); // draw the character
        //parse input
        if(isdigit(c)>0) {
            (*output).value *= 10;
            (*output).value += c - '0';
        } else if (c == '-') {
            (*output).sign = -1;
        } else if (c != ' ' && c != '\n') {
            if ((*output).mode_1 == '@') {
                (*output).mode_1 = c;
            } else if ((*output).mode_2 == '@') {
                (*output).mode_2 = c;
            } else {
                (*output).mode_3 = c;
            }
        }

        //set command
        if (c == '\n') {
            (*output).value *= (*output).sign;
            (*pdo_output).controlword = (((*output).mode_2 & 0xff) << 8) | ((*output).mode_1 & 0xff); //put mode_1 and mode_2 in controlword
            (*pdo_output).user_out_4 = (*output).mode_3 & 0xff; //put mode_3 in user_out_4
            (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3

            //if last command was 0 send emergency stop
            if ((*output).last_command == '@' && (*output).last_value == 0 && (*output).value == 0 && (*output).mode_1 == '@') {
                (*pdo_output).controlword = 'e';
                (*pdo_output).user_out_3 = 0;
            }
            (*output).last_command = (*output).mode_1;
            (*output).last_value = (*output).value;

            //debug: print command on last line
            int nrows,ncols;
            if (ncols == 0);
            getmaxyx(wnd,nrows,ncols); // curses call to find size of window
            wmove(wnd, nrows-1, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "value %d, mode %c (%X), mode_2 %c, mode_3 %c", (*output).value, (*output).mode_1, (*output).mode_1, (*output).mode_2, (*output).mode_3);

            //reset
            (*output).mode_1 = '@';
            (*output).mode_2 = '@';
            (*output).mode_3 = '@';
            (*output).value = 0;
            (*output).sign = 1;

            //reset prompt
            wmove(wnd, (*cursor).row, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "> ");
            (*cursor).col = 2;
        }
    }
}
#endif
