/*
 * tuning.c
 *
 *  Created on: Nov 6, 2016
 *      Author: romuald
 */

#include "tuning.h"
#include "display.h"
#include <ctype.h>
#include <string.h>

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input)
{
    switch((pdo_input.tuning_status >> 16) & 0xff) {
    case 1://offset
        (*input).offset = pdo_input.user_miso;
        break;
    case 2://pole pairs
        (*input).pole_pairs = pdo_input.user_miso;
        break;
    case 3://target
        (*input).target = pdo_input.user_miso;
        break;
    case 4://min position limit
        (*input).min_position = pdo_input.user_miso;
        break;
    case 5://max position limit
        (*input).max_position = pdo_input.user_miso;
        break;
    case 6://max speed
        (*input).max_speed = pdo_input.user_miso;
        break;
    case 7://max torque
        (*input).max_torque = pdo_input.user_miso;
        break;
    case 8:
        (*input).P_pos = pdo_input.user_miso;
        break;
    case 9:
        (*input).I_pos = pdo_input.user_miso;
        break;
    case 10:
        (*input).D_pos = pdo_input.user_miso;
        break;
    case 11:
        (*input).integral_limit_pos = pdo_input.user_miso;
        break;
    case 12:
        (*input).P_velocity = pdo_input.user_miso;
        break;
    case 13:
        (*input).I_velocity = pdo_input.user_miso;
        break;
    case 14:
        (*input).D_velocity = pdo_input.user_miso;
        break;
    case 15:
        (*input).integral_limit_velocity = pdo_input.user_miso;
        break;
    case 16: //fault code
        (*input).error_status = pdo_input.user_miso;
        break;
    case 17://brake_release_strategy
        (*input).brake_release_strategy = pdo_input.user_miso;
        break;
    default://sensor error
        (*input).sensor_error = pdo_input.user_miso;
        break;
    }

    //tuning state
    (*input).motorctrl_status = pdo_input.tuning_status & 0xff;

    //flags
    uint8_t flags = (pdo_input.tuning_status >> 8) & 0xff;
    (*input).brake_flag = flags & 1;
    (*input).motion_polarity = (flags >> 1) & 1;
    (*input).sensor_polarity = (flags >> 2) & 1;
    return ;
}

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output,\
        PositionProfileConfig *profile_config, RecordConfig *record_config, Cursor *cursor)
{
    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    int c = wgetch(wnd); // curses call to input from keyboard
    switch(c) {
    //quit
    case 'q':
        pdo_output->tuning_command = TUNING_CMD_CONTROL_DISABLE;
        pdo_output->user_mosi = 0;
        pdo_output->op_mode = 0;
        output->app_mode = QUIT_MODE;
        break;

    //switch to cs mode
    case 'y': //switch to cs mode
        output->init = 0;
        pdo_output->op_mode = 0;
        pdo_output->tuning_command = 0;
        output->app_mode = CS_MODE;
        break;

    //auto offset
    case 'a': //auto offset
        pdo_output->tuning_command = TUNING_CMD_AUTO_OFFSET;
        break;

    //brake
    case 'b':
        pdo_output->tuning_command = TUNING_CMD_BRAKE;
        if ((pdo_input.tuning_status >> 8) & 1) { //brake is released
            pdo_output->user_mosi = 0;
        } else {
            pdo_output->user_mosi = 1;
        }
        break;

    //reverse command
    case 'r':
        pdo_output->target_velocity =  -pdo_output->target_velocity;
        pdo_output->target_torque =  -pdo_output->target_torque;
        break;

    //discard
    case KEY_BACKSPACE:
    case KEY_DC:
    case 127: //discard
        wmove(wnd, (*cursor).row, 0);
        wclrtoeol(wnd);
        wprintw(wnd, "> ");
        (*cursor).col = 2;
        output->mode_1 = 1;
        output->mode_2 = 1;
        output->mode_3 = 1;
        output->value = 0;
        output->sign = 1;
        break;
    default:
        if (0x20 <= c && c <= 0x7e) { //printable char
            //torque 0 command
            if (c == '0' && output->mode_1 == 1 && output->value == 0) { //first char is 0
                if ((pdo_input.tuning_status & 0xff) != TUNING_MOTORCTRL_OFF && (pdo_input.tuning_status & 0xff) != TUNING_MOTORCTRL_TORQUE) {
                    pdo_output->tuning_command = TUNING_CMD_CONTROL_TORQUE;
                }
                pdo_output->target_torque = 0;
            } else {
                (*cursor).col = draw(wnd, c, (*cursor).row, (*cursor).col); // draw the character
                //parse input
                if(isdigit(c)>0) {
                    output->value *= 10;
                    output->value += c - '0';
                } else if (c == '-') {
                    output->sign = -1;
                } else if (c != ' ' && c != '\n') {
                    if (output->mode_1 == 1) {
                        output->mode_1 = c;
                    } else if (output->mode_2 == 1) {
                        output->mode_2 = c;
                    } else {
                        output->mode_3 = c;
                    }
                }
            }
        //(enter) execute command
        } else if (c == '\n') {
            output->value *= output->sign;
            switch(output->mode_1) {
            case 'p':
                if (output->mode_2 == 'p') { //position profile
                    profile_config->mode = POSITION_PROFILER;
                    profile_config->step = 0;
                    profile_config->steps = init_position_profile(&(profile_config->motion_profile), output->value, pdo_input.position_value,\
                            profile_config->profile_speed, profile_config->profile_acceleration, profile_config->profile_acceleration, profile_config->ticks_per_turn);
                } else if (output->mode_2 == 's') {//position step
                    if (output->mode_3 == 'p') {//position step profiler
                        profile_config->mode = POSITION_STEP_PROFILER;
                        profile_config->step = 0;
                        profile_config->target_position = output->value;
                        profile_config->steps = init_position_profile(&(profile_config->motion_profile), profile_config->target_position, pdo_input.position_value,\
                                profile_config->profile_speed, profile_config->profile_acceleration, profile_config->profile_acceleration, profile_config->ticks_per_turn);
                    } else {
                        profile_config->mode = POSITION_STEP;
                        profile_config->step = 0;
                        profile_config->steps = 4500;
                        pdo_output->target_position = output->value; //put value in user_mosi
                    }
                } else { //position direct
                    profile_config->mode = POSITION_DIRECT;
                    pdo_output->target_position = output->value;
                }
                break;

            //set velocity
            case 'v':
                pdo_output->target_velocity = output->value;
                break;

            case 'e':
                pdo_output->tuning_command = TUNING_CMD_CONTROL_DISABLE;
                if (output->value) {
                    switch(output->mode_2) {
                    case 'p':
                        pdo_output->tuning_command = TUNING_CMD_CONTROL_POSITION;
                        pdo_output->target_position = pdo_input.position_value;
                        pdo_output->user_mosi = output->value;
                        break;
                    case 'v':
                        pdo_output->tuning_command = TUNING_CMD_CONTROL_VELOCITY;
                        pdo_output->target_velocity = 0;
                        break;
                    case 't':
                        pdo_output->tuning_command = TUNING_CMD_CONTROL_TORQUE;
                        pdo_output->target_torque = 0;
                        break;
                    }
                }
                break;

            //zero position
            case 'z':
                if (output->mode_2 == 'z') {
                    pdo_output->tuning_command = TUNING_CMD_ZERO_POSITION;
                } else {
                    pdo_output->tuning_command = TUNING_CMD_SET_MULTITURN;
                    pdo_output->user_mosi = output->value;
                }
                break;


            //set offset
            case 'o':
                pdo_output->tuning_command = TUNING_CMD_OFFSET;
                pdo_output->user_mosi = output->value;
                break;

            //sensor polarity
            case 's':
                pdo_output->tuning_command = TUNING_CMD_POLARITY_SENSOR;
                if ((pdo_input.tuning_status >> 8) & 0x04) { //sensor polarity is reverse
                    pdo_output->user_mosi = 0;
                } else {
                    pdo_output->user_mosi = 1;
                }
                break;

           //motion polarity
            case 'd':
            case 'm':
                pdo_output->tuning_command = TUNING_CMD_POLARITY_MOTION;
                if ((pdo_input.tuning_status >> 8) & 0x02) { //polarity is reverse
                    pdo_output->user_mosi = 0;
                } else {
                    pdo_output->user_mosi = 1;
                }
                break;

            //pole pairs
            case 'P':
                pdo_output->tuning_command = TUNING_CMD_POLE_PAIRS;
                pdo_output->user_mosi = output->value;
                break;


            //change pid coefficients
            case 'k':
                pdo_output->user_mosi = output->value;
                switch(output->mode_2) {
                case 'p': //position
                    switch(output->mode_3) {
                    case 'p':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KP;
                        break;
                    case 'i':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KI;
                        break;
                    case 'd':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KD;
                        break;
                    case 'l':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_I_LIM;
                        break;
                    case 'j':
                        pdo_output->tuning_command = TUNING_CMD_MOMENT_INERTIA;
                        break;
                    }
                    break;
                    case 'v': //velocity
                        switch(output->mode_3) {
                        case 'p':
                            pdo_output->tuning_command = TUNING_CMD_VELOCITY_KP;
                            break;
                        case 'i':
                            pdo_output->tuning_command = TUNING_CMD_VELOCITY_KI;
                            break;
                        case 'd':
                            pdo_output->tuning_command = TUNING_CMD_VELOCITY_KD;
                            break;
                        case 'l':
                            pdo_output->tuning_command = TUNING_CMD_VELOCITY_I_LIM;
                            break;
                        }
                        break;
                } /* end mode_2 */
                break;


            //limits
            case 'L':
                pdo_output->user_mosi = output->value;
                switch(output->mode_2) {
                //max torque
                case 't':
                    pdo_output->tuning_command = TUNING_CMD_MAX_TORQUE;
                    break;
                //max speed
                case 's':
                case 'v':
                    pdo_output->tuning_command = TUNING_CMD_MAX_SPEED;
                    break;
                //max position
                case 'p':
                    switch(output->mode_3) {
                    case 'u':
                        pdo_output->tuning_command = TUNING_CMD_MAX_POSITION;
                        break;
                    case 'l':
                        pdo_output->tuning_command = TUNING_CMD_MIN_POSITION;
                        break;
                    default:
                        pdo_output->tuning_command = TUNING_CMD_MAX_POSITION;
                        output->next_command = TUNING_CMD_MIN_POSITION;
                        output->next_value = -output->value;
                        break;
                    }
                    break;
                } /* end mode_2 */
                break;


            default:
                if (output->value) {
                    if ((pdo_input.tuning_status & 0xff) != TUNING_MOTORCTRL_TORQUE) {
                        pdo_output->tuning_command = TUNING_CMD_CONTROL_TORQUE;
                    }
                    pdo_output->target_torque = output->value;
                } else {
                    pdo_output->tuning_command = TUNING_CMD_CONTROL_DISABLE;
                }
                break;
            }


            //debug: print command on last line
            int nrows,ncols;
            if (ncols == 0);
            getmaxyx(wnd,nrows,ncols); // curses call to find size of window
            wmove(wnd, nrows-1, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "value %d, mode %c (%X), mode_2 %c, mode_3 %c", output->value, output->mode_1, output->mode_1, output->mode_2, output->mode_3);

            //reset
            output->mode_1 = 1;
            output->mode_2 = 1;
            output->mode_3 = 1;
            output->value = 0;
            output->sign = 1;

            //reset prompt
            wmove(wnd, (*cursor).row, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "> ");
            (*cursor).col = 2;
        }
        break;
    }
    return;
}

void tuning_position(PositionProfileConfig *config, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input)
{
    int max_follow_error = (3*config->ticks_per_turn)/2;

    if (config->mode == POSITION_PROFILER) {
        if (config->step <= config->steps) {
            pdo_output->target_position = position_profile_generate(&(config->motion_profile), config->step);
            (*config).step++;
            //check follow error
            int32_t follow_error = pdo_output->target_position - pdo_input.position_value;
            if (follow_error > max_follow_error || follow_error < -max_follow_error) {
                config->mode = POSITION_DIRECT;
                pdo_output->target_position = pdo_input.position_value;
            }
        } else {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
    } else if (config->mode == POSITION_STEP) {
        if (config->step == config->steps/3) {
            pdo_output->target_position = -pdo_output->target_position;
        } else if (config->step == (config->steps/3)*2) {
            pdo_output->target_position = 0;
        } else if (config->step == config->steps) {
            config->mode = POSITION_DIRECT;
        }
        (*config).step++;
    }
    else if (config->mode == POSITION_STEP_PROFILER) {
        if (config->step < config->steps) {
            pdo_output->target_position = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position == 0) { //small target pos = we are reached the end
            config->mode = POSITION_DIRECT;
        } else if (config->target_position > 0) { //positive target = end of first step
            config->step = 0;
            config->target_position = -config->target_position;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.position_value,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->target_position = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position < 0) { //negative target = end of second step
            config->step = 0;
            config->target_position = 0;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.position_value,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->target_position = position_profile_generate(&(config->motion_profile), config->step);
        }
        (*config).step++;
        //check follow error
        int32_t follow_error = pdo_output->target_position - pdo_input.position_value;
        if (follow_error > max_follow_error || follow_error < -max_follow_error) {
            config->mode = POSITION_DIRECT;
            pdo_output->target_position = pdo_input.position_value;
        }
    }
}

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, char *filename)
{
    if (config->state == RECORD_ON && config->count < config->max_values) {
        if (config->data == NULL) {
            config->data = malloc(sizeof(RecordData)*config->max_values); //malloc for 2 minutes of data
        }
        config->data[config->count].target_position = (int32_t)pdo_output.user_mosi;
        config->data[config->count].position = (int32_t)pdo_input.position_value;
        config->data[config->count].velocity = (int32_t)pdo_input.velocity_value;
        config->data[config->count].torque = (int16_t)pdo_input.torque_value;
        config->count++;
    } else {
        if (config->data != NULL) { //save to file
            FILE *fd = fopen(filename, "w");
            fprintf(fd, "count,target value,position,velocity,torque\n");
            for (int i=0 ; i<config->count ; i++) {
                fprintf(fd, "%d,%d,%d,%d,%d\n", i, config->data[i].target_position, config->data[i].position, config->data[i].velocity, config->data[i].torque);
            }
            fclose(fd);
            free(config->data);
            config->data = NULL;
            config->count = 0;
            config->state = RECORD_OFF;
        }
    }
}




void tuning(WINDOW *wnd, Cursor *cursor,
            struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input,
            OutputValues *output, InputValues *input,
            PositionProfileConfig *profile_config,
            RecordConfig *record_config, char *record_filename)
{
    if (output->init == 0) { //switch the slave to OPMODE_TUNING
        if (((*pdo_input).op_mode_display&0xff) != (OPMODE_TUNING & 0xff)) {
            pdo_output->op_mode = OPMODE_TUNING;
            enum eCIAState state = read_state((*pdo_input).statusword);
            pdo_output->controlword = go_to_state(state, CIASTATE_SWITCH_ON_DISABLED, pdo_output->controlword); // this state allow opmode change
        } else {
            output->init = 1;
            display_tuning_help(wnd, DISPLAY_LINE-HELP_ROW_COUNT);
            cursor->row = DISPLAY_LINE;
            cursor->col = 2;
            move(cursor->row, 0);
            printw("> ");
        }
    } else { // check if command is received by slave
        if (pdo_input->tuning_status & 0x80000000) { //command received by slave
            pdo_output->tuning_command = 0; //reset control word
        } else if (pdo_output->tuning_command == 0) { //last command cleared, we can now send a new one
            if  (output->next_command) {
                pdo_output->tuning_command = output->next_command;
                pdo_output->user_mosi = output->next_value;
                output->next_command = 0;
            }
        }
    }

    //demux received data
    tuning_input(*pdo_input, input);

    //print
    display_tuning(wnd, *pdo_input, *input, *record_config, 0);

    //recorder
    tuning_record(record_config, *pdo_input, (*pdo_output), record_filename);

    //position profile
    tuning_position(profile_config, pdo_output, *pdo_input);

    //read user input
    tuning_command(wnd, pdo_output, *pdo_input, output, profile_config, record_config, cursor);
}



void cs_command(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output)
{
    pdo_output[1].user_mosi = output->select;

    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    int c = wgetch(wnd); // curses call to input from keyboard
    if (c == 'q') { //quit
        pdo_output[output->select].op_mode = 0;
        output->app_mode = QUIT_MODE;
    } else if (c == 'y') { //switch to tuning mode
        pdo_output[output->select].op_mode = OPMODE_TUNING;
        output->init = 0;
        output->app_mode = TUNING_MODE;
    } else if (c == 'd') { //debug
        output->debug ^= 1;
    } else if (c == 27) { //arrow
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
    } else if (c == 's') { //stop
        pdo_output[output->select].op_mode = 0;
    } else if (c == 'p') { // CSP
        pdo_output[output->select].op_mode = 8;
    } else if (c == 'v') { // CSV
        pdo_output[output->select].op_mode = 9;
        pdo_output[output->select].target_velocity = 0;
    } else if (c == 't') { // CST
        pdo_output[output->select].op_mode = 10;
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
            output->value *= 10;
            output->value += c - '0';
        } else if (c == '-') {
            output->sign = -1;
        } else if (c != ' ' && c != '\n') {
            if (output->mode_1 == 1) {
                output->mode_1 = c;
            } else if (output->mode_2 == 1) {
                output->mode_2 = c;
            } else {
                output->mode_3 = c;
            }
        }

        //set command
        if (c == '\n') {
            output->value *= output->sign;
            if (output->mode_1 == 'o') {
                pdo_output[output->select].op_mode = output->value;
            } else if (output->mode_1 == 'c') {
                pdo_output[output->select].controlword = output->value;
            } else {
                pdo_output[output->select].target_position = output->value;
                pdo_output[output->select].target_velocity = output->value;
                pdo_output[output->select].target_torque = output->value;
            }

            //debug: print command on last line
            int nrows,ncols;
            if (ncols == 0);
            getmaxyx(wnd,nrows,ncols); // curses call to find size of window
            wmove(wnd, nrows-1, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "value %d, mode %c (%X), mode_2 %c, mode_3 %c", output->value, output->mode_1, output->mode_1, output->mode_2, output->mode_3);

            //reset
            output->mode_1 = 1;
            output->mode_2 = 1;
            output->mode_3 = 1;
            output->value = 0;
            output->sign = 1;

            //reset prompt
            wmove(wnd, (*cursor).row, 0);
            wclrtoeol(wnd);
            wprintw(wnd, "> ");
            (*cursor).col = 2;
        }
    }
    return;
}

void cs_mode(WINDOW *wnd, Cursor *cursor, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t number_slaves, OutputValues *output)
{
    if (output->init == 0) {
        output->init = 1;
        clear();
        cursor->row = number_slaves*3 + 2;
        cursor->col = 2;
        move(cursor->row, 0);
        printw("> ");
    }
    display_slaves(wnd, 0, pdo_output, pdo_input, number_slaves, *output);
    cs_command(wnd, cursor, pdo_output, pdo_input, number_slaves, output);

    switch(pdo_output[output->select].op_mode) {
    case 8://CSP
    case 9://CSV
    case 10://CST
        if (pdo_output[output->select].op_mode != pdo_input[output->select].op_mode_display) {
            // go to SWITCH_ON_DISABLED to change opmode
            pdo_output[output->select].controlword = go_to_state(read_state(pdo_input[output->select].statusword), CIASTATE_SWITCH_ON_DISABLED, pdo_output[output->select].controlword);
        } else {
            // opmode is set, enable operation
            enum eCIAState state = read_state(pdo_input[output->select].statusword);
            if (state != CIASTATE_OP_ENABLED) {
                //set the target position to the current position before enabling operation to prevent the motor for moving at start
                pdo_output[output->select].target_position = pdo_input[output->select].position_value;
                // go to CIASTATE_OP_ENABLED state
                pdo_output[output->select].controlword = go_to_state(state, CIASTATE_OP_ENABLED, pdo_output[output->select].controlword);
            }
        }
        break;
    case 0://no opmode
        pdo_output[output->select].controlword = go_to_state(read_state(pdo_input[output->select].statusword), CIASTATE_SWITCH_ON_DISABLED, pdo_output[output->select].controlword);
        break;
    }
}
