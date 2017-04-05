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


void target_generate(PositionProfileConfig *config, PDOOutput *pdo_output, PDOInput *pdo_input, int number_slaves)
{
    for (int i=0; i<number_slaves; i++) {
        if (config[i].step <= config[i].steps) {
            switch(pdo_input[i].op_mode_display) {
            case OPMODE_CSP:
                pdo_output[i].target_position = position_profile_generate(&(config[i].motion_profile), config[i].step);
                //check follow error
                int max_follow_error = (3*config[i].ticks_per_turn)/2;
                int follow_error = pdo_output[i].target_position - pdo_input[i].position_value;
                if (follow_error > max_follow_error || follow_error < -max_follow_error) {
                    config[i].step = 1;
                    config[i].steps = 0;
                    pdo_output[i].target_position = pdo_input[i].position_value;
                }
                break;
            case OPMODE_CSV:
                pdo_output[i].target_velocity = velocity_profile_generate_in_steps(&(config[i].motion_profile), config[i].step);
                break;
            }
            config[i].step++;
        }
    }
}



void cs_command(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output, PositionProfileConfig *profile_config)
{
    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    int c2 = 0;
    int c = wgetch(wnd); // curses call to input from keyboard
    switch(c) {
    //quit
    case 'q':
        for (int i=0; i<number_slaves; i++) {
            pdo_output[i].op_mode = 0;
        }
        output->app_mode = QUIT_MODE;
        break;

    //enable debug display
    case 'd':
        output->debug ^= 1;
        break;

    //arrow keys to change the selected slave
    case 27:
        // arrow key is an escape code so we need to check the next chars
        c2 = wgetch(wnd);
        if (c2 == '[') {
            c2 = wgetch(wnd);
            if (c2 == 'A') { // up arrow
                output->select -= 1;
            } else if (c2 == 'B') { //down arrow
                output->select += 1;
            }
            if (output->select > number_slaves-1) {
                output->select = 0;
            } else if (output->select < 0) {
                output->select = number_slaves-1;
            }
        }
        break;

    //reverse command
    case 'r':
        switch(pdo_input[output->select].op_mode_display) {
        case OPMODE_CSP:
            //init profile
            profile_config[output->select].step = 0;
            profile_config[output->select].steps = init_position_profile(&(profile_config[output->select].motion_profile), -pdo_output[output->select].target_position, pdo_input[output->select].position_value,\
                    profile_config[output->select].profile_speed, profile_config[output->select].profile_acceleration, profile_config[output->select].profile_acceleration, profile_config[output->select].ticks_per_turn);
            break;
        case OPMODE_CSV:
            profile_config[output->select].step = 0;
            profile_config[output->select].steps = init_velocity_profile(&(profile_config[output->select].motion_profile), -pdo_input[output->select].velocity_value, pdo_input[output->select].velocity_value,
                    profile_config[output->select].profile_acceleration, profile_config[output->select].profile_acceleration, profile_config[output->select].ticks_per_turn);
            break;
        case OPMODE_CST:
            pdo_output[output->select].target_torque = -pdo_output[output->select].target_torque;
            break;
        }
        break;

    //stop
    case 's':
        if (output->last_command == 's') {
            for (int i=0; i<number_slaves; i++) {
                (output->target_state)[i] = CIASTATE_SWITCH_ON_DISABLED;
            }
        } else {
            (output->target_state)[output->select] = CIASTATE_SWITCH_ON_DISABLED;
        }
        break;

    //CSP opmode
    case  'p':
        pdo_output[output->select].op_mode = OPMODE_CSP;
        (output->target_state)[output->select] = CIASTATE_OP_ENABLED;
        break;

    //CSV opmode
    case 'v':
        pdo_output[output->select].op_mode = OPMODE_CSV;
        (output->target_state)[output->select] = CIASTATE_OP_ENABLED;
        break;

    //CST opmode
    case 't':
        pdo_output[output->select].op_mode = OPMODE_CST;
        (output->target_state)[output->select] = CIASTATE_OP_ENABLED;
        break;

    // (backspace) discard current command
    case KEY_BACKSPACE:
    case KEY_DC:
    case 127: //discard
        wmove(wnd, (*cursor).row, 0);
        wclrtoeol(wnd);
        wprintw(wnd, "> ");
        (*cursor).col = 2;
        break;

    // (enter) process command
    case '\n':
        (*output).value *= (*output).sign;
        if ((*output).mode_1 == 'o') {
            pdo_output[output->select].op_mode = (*output).value;
        } else if ((*output).mode_1 == 'c') {
            pdo_output[output->select].controlword = (*output).value;
        } else {
            // set target position/velocity/torque
            switch(pdo_input[output->select].op_mode_display) {
            case OPMODE_CSP:
                //init profile
                profile_config[output->select].step = 0;
                profile_config[output->select].steps = init_position_profile(&(profile_config[output->select].motion_profile), (*output).value, pdo_input[output->select].position_value,\
                        profile_config[output->select].profile_speed, profile_config[output->select].profile_acceleration, profile_config[output->select].profile_acceleration, profile_config[output->select].ticks_per_turn);
                break;
            case OPMODE_CSV:
                profile_config[output->select].step = 0;
                profile_config[output->select].steps = init_velocity_profile(&(profile_config[output->select].motion_profile), (*output).value, pdo_input[output->select].velocity_value, profile_config[output->select].profile_acceleration,
                        profile_config[output->select].profile_acceleration, profile_config[output->select].ticks_per_turn);
                break;
            case OPMODE_CST:
                pdo_output[output->select].target_torque = (*output).value;
                break;
            }
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
        break;

    // process and draw the character
    default:
        if (c != ERR) {
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
        }
        break;
    }
    if (c != ERR && c != '\n') {
        output->last_command = c;
    }
    return;
}


void state_machine_control(PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output)
{
    for (int i=0; i<number_slaves; i++) {
        CIA402State current_state = cia402_read_state(pdo_input[i].statusword);
        switch(pdo_output[i].op_mode) {
        case OPMODE_CSP://CSP
        case OPMODE_CSV://CSV
        case OPMODE_CST://CST
            //if the opmode is not yet set in the slave we need to go to the SWITCH_ON_DISABLED state to be able to change the opmode
            if (pdo_output[i].op_mode != pdo_input[i].op_mode_display) {
                pdo_output[i].controlword = cia402_go_to_state(CIASTATE_SWITCH_ON_DISABLED, current_state, pdo_output[i].controlword, 0);
            } else {
                if (current_state != CIASTATE_OP_ENABLED) {
                    /* iniatialize position/velocity/torque target
                     * this is a safeguard so when we switch to op enable the motor does not move before the user sets the real target
                     * */
                    pdo_output[i].target_position = pdo_input[i].position_value;
                    pdo_output[i].target_velocity = 0;
                    pdo_output[i].target_torque = 0;
                }
                // the opmode and is set, we can now go to target state
                pdo_output[i].controlword = cia402_go_to_state((output->target_state)[i], current_state, pdo_output[i].controlword, 0);
            }
            break;
        default://for other opmodes disable operation
            pdo_output[i].controlword = cia402_go_to_state(CIASTATE_SWITCH_ON_DISABLED, current_state, pdo_output[i].controlword, 0);
            break;
        }
    }
}


void cyclic_synchronous_mode(WINDOW *wnd, Cursor *cursor, PDOOutput *pdo_output, PDOInput *pdo_input, size_t number_slaves, OutputValues *output, PositionProfileConfig *profile_config)
{
    //init display
    if (output->init == 0) {
        output->init = 1;
        clear();
        cursor->row = number_slaves*3 + 2;
        //print help
        print_help(wnd, (cursor->row)+2);
        cursor->col = 2;
        move(cursor->row, 0);
        printw("> ");
    }

    //display slaves data
    display_slaves(wnd, 0, pdo_output, pdo_input, number_slaves, *output);

    //manage console commands
    cs_command(wnd, cursor, pdo_output, pdo_input, number_slaves, output, profile_config);

    //manage slaves state machines and opmode
    state_machine_control(pdo_output, pdo_input, number_slaves, output);

    //use profile to generate a target for position/velocity
    target_generate(profile_config, pdo_output, pdo_input, number_slaves);
}
