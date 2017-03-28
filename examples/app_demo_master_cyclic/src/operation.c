/*
 * operation.c
 *
 *  Created on: Nov 6, 2016
 *      Author: synapticon
 */

#include "operation.h"
#include "display.h"
#include "cia402.h"
#include <ctype.h>
#include <string.h>


void tuning_position(PositionProfileConfig *config, PDOOutput *pdo_output, PDOInput pdo_input)
{
    int max_follow_error = config->ticks_per_turn;

    if (config->mode == POSITION_PROFILER) {
        if (config->step <= config->steps) {
            pdo_output->user_mosi = position_profile_generate(&(config->motion_profile), config->step);
            pdo_output->controlword = 'p';
            (*config).step++;
            //check follow error
            if (((int)pdo_output->user_mosi - (int)pdo_input.position_value) > max_follow_error || ((int)pdo_output->user_mosi - (int)pdo_input.position_value) < -max_follow_error)
            {
                config->mode = POSITION_DIRECT;
                pdo_output->controlword = 0;
            }
        } else {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
    } else if (config->mode == POSITION_STEP) {
        pdo_output->controlword = 'p';
        if (config->step == config->steps/3) {
            pdo_output->user_mosi = -pdo_output->user_mosi;
        } else if (config->step == (config->steps/3)*2) {
            pdo_output->user_mosi = 0;
        } else if (config->step == config->steps) {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
        (*config).step++;
    }
    else if (config->mode == POSITION_STEP_PROFILER) {
        pdo_output->controlword = 'p';
        if (config->step < config->steps) {
            pdo_output->user_mosi = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position == 0) { //small target pos = we are reached the end
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        } else if (config->target_position > 0) { //positive target = end of first step
            config->step = 0;
            config->target_position = -config->target_position;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.position_value,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->user_mosi = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position < 0) { //negative target = end of second step
            config->step = 0;
            config->target_position = 0;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.position_value,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->user_mosi = position_profile_generate(&(config->motion_profile), config->step);
        }
        (*config).step++;
        //check follow error
        if (((int)pdo_output->user_mosi - (int)pdo_input.position_value) > max_follow_error || ((int)pdo_output->user_mosi - (int)pdo_input.position_value) < -max_follow_error)
        {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
    }
}



void cs_command(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output)
{
    pdo_output[1].user_mosi = output->select;

    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    int c = wgetch(wnd); // curses call to input from keyboard
    if (c == 'q') { //quit
        pdo_output[output->select].op_mode = 0;
        output->app_mode = QUIT_MODE;
    } else if (c == 'd') { //enable debug display
        output->debug ^= 1;
    } else if (c == 27) { //arrow key to change the selected slave
        c = wgetch(wnd);
        if (c == '[') {
            c = wgetch(wnd);
            if (c == 'A') { // up arrow
                output->select -= 1;
            } else if (c == 'B') { //down arrow
                output->select += 1;
            }
            if (output->select > number_slaves-1) {
                output->select = 0;
            } else if (output->select < 0) {
                output->select = number_slaves-1;
            }
        }
    } else if (c == 'r') { //reverse command
        pdo_output[output->select].target_position = -pdo_output[output->select].target_position;
        pdo_output[output->select].target_velocity = -pdo_output[output->select].target_velocity;
        pdo_output[output->select].target_torque = -pdo_output[output->select].target_torque;
    } else if (c == 's') { //stop
        output->target_state = CIASTATE_SWITCH_ON_DISABLED;
//        pdo_output[output->select].op_mode = 0;
    } else if (c == 'p') { // CSP
        pdo_output[output->select].op_mode = 8;
        output->target_state = CIASTATE_OP_ENABLED;
    } else if (c == 'v') { // CSV
        pdo_output[output->select].op_mode = 9;
        output->target_state = CIASTATE_OP_ENABLED;
        pdo_output[output->select].target_velocity = 0;
    } else if (c == 't') { // CST
        pdo_output[output->select].op_mode = 10;
        output->target_state = CIASTATE_OP_ENABLED;
        pdo_output[output->select].target_torque = 0;
    } else if (c == KEY_BACKSPACE || c == KEY_DC || c == 127) {//discard
        wmove(wnd, (*cursor).row, 0);
        wclrtoeol(wnd);
        wprintw(wnd, "> ");
        (*cursor).col = 2;
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
            if ((*output).mode_1 == 'o') {
                pdo_output[output->select].op_mode = (*output).value;
            } else if ((*output).mode_1 == 'c') {
                pdo_output[output->select].controlword = (*output).value;
            } else {
                pdo_output[output->select].target_position = (*output).value;
                pdo_output[output->select].target_velocity = (*output).value;
                pdo_output[output->select].target_torque = (*output).value;
            }

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
    return;
}

void cs_mode(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output)
{
    //init display
    if (output->init == 0) {
        output->init = 1;
        clear();
        cursor->row = number_slaves*3 + 2;
        cursor->col = 2;
        move(cursor->row, 0);
        printw("> ");
    }

    //display slaves data
    display_slaves(wnd, 0, pdo_output, pdo_input, number_slaves, *output);

    //manage console commands
    cs_command(wnd, cursor, pdo_output, pdo_input, number_slaves, output);

    //manage slave state machine and opmode
    CIA402State state = read_state(pdo_input[output->select].statusword);
    switch(pdo_output[output->select].op_mode) {
    case OPMODE_CSP://CSP
    case OPMODE_CSV://CSV
    case OPMODE_CST://CST
        //if the opmode is not yet set in the slave we need to go to the SWITCH_ON_DISABLED state to be able to change the opmode
        if (pdo_output[output->select].op_mode != pdo_input[output->select].op_mode_display) {
            pdo_output[output->select].controlword = go_to_state(state, CIASTATE_SWITCH_ON_DISABLED, pdo_output[output->select].controlword);
        } else {
            //firt we set the target position to the current position before enabling operation to prevent the motor for moving at start
            if (state != CIASTATE_OP_ENABLED) {
                pdo_output[output->select].target_position = pdo_input[output->select].position_value;
            }
            // the opmode and the start target are set, we can now go to CIASTATE_OP_ENABLED state
            pdo_output[output->select].controlword = go_to_state(state, output->target_state, pdo_output[output->select].controlword);
        }
        break;
    default://for other opmodes disable operation
        pdo_output[output->select].controlword = go_to_state(state, CIASTATE_SWITCH_ON_DISABLED, pdo_output[output->select].controlword);
        break;
    }
}
