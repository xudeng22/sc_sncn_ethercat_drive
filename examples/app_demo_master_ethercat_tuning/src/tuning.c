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
    int status_mux = (pdo_input.statusword) & 0xff;

    switch(status_mux) {
    case 0://flags
        (*input).brake_flag = pdo_input.user_in_4 & 1;
        (*input).motion_polarity = (pdo_input.user_in_4 >> 1) & 1;
        (*input).sensor_polarity = (pdo_input.user_in_4 >> 2) & 1;
        (*input).motorctrl_status = (pdo_input.user_in_4 >> 3);
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
    case 8:
        (*input).P_pos = pdo_input.user_in_4;
        break;
    case 9:
        (*input).I_pos = pdo_input.user_in_4;
        break;
    case 10:
        (*input).D_pos = pdo_input.user_in_4;
        break;
    case 11:
        (*input).integral_limit_pos = pdo_input.user_in_4;
        break;
    case 12:
        (*input).P_velocity = pdo_input.user_in_4;
        break;
    case 13:
        (*input).I_velocity = pdo_input.user_in_4;
        break;
    case 14:
        (*input).D_velocity = pdo_input.user_in_4;
        break;
    case 15:
        (*input).integral_limit_velocity = pdo_input.user_in_4;
        break;
    case 16: //fault code
        (*input).error_status = pdo_input.user_in_4;
        break;
    default://brake_release_strategy
        (*input).brake_release_strategy = pdo_input.user_in_4;
        break;
    }
    return ;
}

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output,\
        PositionProfileConfig *profile_config, RecordConfig *record_config, Cursor *cursor)
{
    //read user input
    wmove(wnd, (*cursor).row, (*cursor).col);
    char c = wgetch(wnd); // curses call to input from keyboard
    if (c == 'q') { //quit
        (*pdo_output).controlword = 'e';
        (*pdo_output).user_out_3 = 0;
        (*pdo_output).opmode = 0;
    } else if (c == '.') { //record
        if (record_config->state == RECORD_OFF) {
            record_config->state = RECORD_ON;
        } else {
            record_config->state = RECORD_OFF;
        }
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
                            profile_config->profile_speed, profile_config->profile_acceleration, profile_config->profile_acceleration, profile_config->ticks_per_turn);
                } else if ((*output).mode_2 == 's') {//position step
                    if ((*output).mode_3 == 'p') {//position step profiler
                        profile_config->mode = POSITION_STEP_PROFILER;
                        profile_config->step = 0;
                        profile_config->target_position = (*output).value;
                        profile_config->steps = init_position_profile(&(profile_config->motion_profile), profile_config->target_position, pdo_input.actual_position,\
                                profile_config->profile_speed, profile_config->profile_acceleration, profile_config->profile_acceleration, profile_config->ticks_per_turn);
                    } else {
                        profile_config->mode = POSITION_STEP;
                        profile_config->step = 0;
                        profile_config->steps = 4500;
                        (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
                    }
                } else { //position direct
                    pdo_output->controlword = 'p';
                    profile_config->mode = POSITION_DIRECT;
                    (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
                }
            } else {
                (*pdo_output).controlword = (((*output).mode_2 & 0xff) << 8) | ((*output).mode_1 & 0xff); //put mode_1 and mode_2 in controlword
                (*pdo_output).user_out_4 = (*output).mode_3 & 0xff; //put mode_3 in user_out_4
                (*pdo_output).user_out_3 = (*output).value; //put value in user_out_3
            }

            //if last command was 0 send emergency stop
            if ((*output).value == 0 && (*output).mode_1 == '@') {
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

void tuning_position(PositionProfileConfig *config, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input)
{
    int max_follow_error = config->ticks_per_turn;

    if (config->mode == POSITION_PROFILER) {
        if (config->step <= config->steps) {
            pdo_output->user_out_3 = position_profile_generate(&(config->motion_profile), config->step);
            pdo_output->controlword = 'p';
            (*config).step++;
            //check follow error
            if (((int)pdo_output->user_out_3 - (int)pdo_input.actual_position) > max_follow_error || ((int)pdo_output->user_out_3 - (int)pdo_input.actual_position) < -max_follow_error)
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
            pdo_output->user_out_3 = -pdo_output->user_out_3;
        } else if (config->step == (config->steps/3)*2) {
            pdo_output->user_out_3 = 0;
        } else if (config->step == config->steps) {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
        (*config).step++;
    }
    else if (config->mode == POSITION_STEP_PROFILER) {
        pdo_output->controlword = 'p';
        if (config->step < config->steps) {
            pdo_output->user_out_3 = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position == 0) { //small target pos = we are reached the end
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        } else if (config->target_position > 0) { //positive target = end of first step
            config->step = 0;
            config->target_position = -config->target_position;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.actual_position,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->user_out_3 = position_profile_generate(&(config->motion_profile), config->step);
        } else if (config->target_position < 0) { //negative target = end of second step
            config->step = 0;
            config->target_position = 0;
            config->steps = init_position_profile(&(config->motion_profile), config->target_position, pdo_input.actual_position,\
                    config->profile_speed, config->profile_acceleration, config->profile_acceleration, config->ticks_per_turn);
            pdo_output->user_out_3 = position_profile_generate(&(config->motion_profile), config->step);
        }
        (*config).step++;
        //check follow error
        if (((int)pdo_output->user_out_3 - (int)pdo_input.actual_position) > max_follow_error || ((int)pdo_output->user_out_3 - (int)pdo_input.actual_position) < -max_follow_error)
        {
            config->mode = POSITION_DIRECT;
            pdo_output->controlword = 0;
        }
    }
}

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, char *filename)
{
    if (config->state == RECORD_ON && config->count < config->max_values) {
        if (config->data == NULL) {
            config->data = malloc(sizeof(RecordData)*config->max_values); //malloc for 2 minutes of data
        }
        config->data[config->count].target_position = (int32_t)pdo_output.user_out_3;
        config->data[config->count].position = (int32_t)pdo_input.actual_position;
        config->data[config->count].velocity = (int32_t)pdo_input.actual_velocity;
        config->data[config->count].torque = (int16_t)pdo_input.actual_torque;
        config->count++;
    } else {
        if (config->data != NULL) { //save to file
            FILE *fd = fopen(filename, "w");
            fprintf(fd, "count,target position,position,velocity,torque\n");
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
