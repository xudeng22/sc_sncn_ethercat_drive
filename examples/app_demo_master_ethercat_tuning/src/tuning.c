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
        (*input).torque_control_flag = (pdo_input.user_in_4 >> 1) & 1;
        (*input).sensor_polarity = (pdo_input.user_in_4 >> 2) & 1;
        (*input).motor_polarity = (pdo_input.user_in_4 >> 3) & 1;
        (*input).motorctrl_status = (pdo_input.user_in_4 >> 4);
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

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output, PositionProfileConfig *profile_config, Cursor *cursor)
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
            if ((*output).mode_1 == 'p') {
                if ((*output).mode_2 == 'p') { //position profile
                    profile_config->mode = POSITION_PROFILER;
                    profile_config->step = 0;
                    profile_config->steps = init_position_profile(&(profile_config->motion_profile), (*output).value, pdo_input.actual_position,\
                            profile_config->profile_speed, profile_config->profile_acceleration, profile_config->profile_acceleration);
                } else if ((*output).mode_2 == 's') {//position step
                    profile_config->mode = POSITION_STEP;
                    profile_config->step = 0;
                    profile_config->steps = 4500;
                    (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
                } else { //position direct
                    pdo_output->controlword = 'p';
                    (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
                }
            } else {
                (*pdo_output).controlword = (((*output).mode_2 & 0xff) << 8) | ((*output).mode_1 & 0xff); //put mode_1 and mode_2 in controlword
                (*pdo_output).user_out_4 = (*output).mode_3 & 0xff; //put mode_3 in user_out_4
                (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
            }

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

void tuning_position(PositionProfileConfig *config, struct _pdo_cia402_output *pdo_output)
{
    if (config->mode == POSITION_PROFILER) {
        if (config->step <= config->steps) {
            pdo_output->user_out_3 = position_profile_generate(&(config->motion_profile), config->step);
            pdo_output->controlword = 'p';
            (*config).step++;
        } else {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
    } else if (config->mode == POSITION_STEP) {
        pdo_output->controlword = 'p';
        if (config->step == config->steps/3) {
            pdo_output->user_out_3 = -pdo_output->user_out_3;
        } else if (config->step == (config->steps/3)*2) {
            pdo_output->user_out_3 = 0;
        } else if (config->step == config->steps) {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
        (*config).step++;
    }
}
