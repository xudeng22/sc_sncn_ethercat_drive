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
#include <readsdoconfig.h>

void tuning_input(struct _pdo_cia402_input pdo_input, InputValues *input)
{
    union Data value;
    switch((pdo_input.tuning_status >> 16) & 0xff) {
    case TUNING_STATUS_MUX_OFFSET://offset
        (*input).offset = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_POLE_PAIRS://pole pairs
        (*input).pole_pairs = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_MIN_POS://min position limit
        (*input).min_position = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_MAX_POS://max position limit
        (*input).max_position = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_MAX_SPEED://max speed
        (*input).max_speed = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_MAX_TORQUE://max torque
        (*input).max_torque = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_POS_KP:
        value.i = pdo_input.user_miso;
        (*input).P_pos = value.f;
        break;
    case TUNING_STATUS_MUX_POS_KI:
        value.i = pdo_input.user_miso;
        (*input).I_pos = value.f;
        break;
    case TUNING_STATUS_MUX_POS_KD:
        value.i = pdo_input.user_miso;
        (*input).D_pos = value.f;
        break;
    case TUNING_STATUS_MUX_POS_I_LIM:
        (*input).integral_limit_pos = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_VEL_KP:
        value.i = pdo_input.user_miso;
        (*input).P_velocity = value.f;
        break;
    case TUNING_STATUS_MUX_VEL_KI:
        value.i = pdo_input.user_miso;
        (*input).I_velocity = value.f;
        break;
    case TUNING_STATUS_MUX_VEL_KD:
        value.i = pdo_input.user_miso;
        (*input).D_velocity = value.f;
        break;
    case TUNING_STATUS_MUX_VEL_I_LIM:
        (*input).integral_limit_velocity = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_FAULT: //fault code
        (*input).error_status = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_BRAKE_STRAT://brake_release_strategy
        (*input).brake_release_strategy = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_SENSOR_ERROR://sensor error
        (*input).sensor_error = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_MOTION_CTRL_ERROR://sensor error
        (*input).motion_control_error = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_RATED_TORQUE://rated torque
        (*input).rated_torque = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_FILTER://filter
        (*input).filter = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_TUNE_AMPLITUDE:
        (*input).tune_amplitude = pdo_input.user_miso;
        break;
    case TUNING_STATUS_MUX_TUNE_PERIOD:
        (*input).tune_period = pdo_input.user_miso;
        break;
    }

    //tuning state
    (*input).motorctrl_status = pdo_input.tuning_status & 0xff;

    //flags
    uint8_t flags = (pdo_input.tuning_status >> 8) & 0xff;
    (*input).brake_flag = (flags >> TUNING_FLAG_BRAKE) & 1;
    (*input).motion_polarity = (flags >> TUNING_FLAG_MOTION_POLARITY) & 1;
    (*input).sensor_polarity = (flags >> TUNING_FLAG_SENSOR_POLARITY) & 1;
    input->phases_inverted = (flags >> TUNING_FLAG_PHASES_INVERTED) & 1;
    input->profiler = (flags >> TUNING_FLAG_INTEGRATED_PROFILER) & 1;
    input->cogging_torque_flag = (flags >> TUNING_FLAG_COGGING_TORQUE) & 1;
    return ;
}

void tuning_command(WINDOW *wnd, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input pdo_input, OutputValues *output,\
        PositionProfileConfig *profile_config, RecordConfig *record_config, Cursor *cursor)
{
    //read user input
    union Data value;
    wmove(wnd, (*cursor).row, (*cursor).col);
    int c = wgetch(wnd); // curses call to input from keyboard
    switch(c) {

    /* One letter commands */

    //quit
    case 'q':
        pdo_output->tuning_command = TUNING_CMD_CONTROL_DISABLE;
        pdo_output->user_mosi = 0;
        pdo_output->op_mode = 0;
        output->app_mode = QUIT_MODE;
        break;

    //torque 0
    case '0':
        if (output->mode_1 == 1 && output->value == 0) { //the first char entered is 0
            if ((pdo_input.tuning_status & 0xff) != TUNING_MOTORCTRL_OFF && (pdo_input.tuning_status & 0xff) != TUNING_MOTORCTRL_TORQUE) {
                pdo_output->tuning_command = TUNING_CMD_CONTROL_TORQUE;
            }
            pdo_output->target_torque = 0;
        } else { //normal 0
            (*cursor).col = draw(wnd, c, (*cursor).row, (*cursor).col); // draw the character
            if (output->float_count == 0) {
                output->value *= 10;
            } else {
                output->float_count *= 10;
            }
        }
        break;

    //record
    case ',':
        if (record_config->state == RECORD_ON) {
            record_config->state = RECORD_OFF;
        } else {
            record_config->state = RECORD_ON;
        }
        break;


#if 0 //continuous cyclic mode is disabled in tuning app. Use the dedicated app_master_cyclic.
    //switch to cs mode
    case 'y': //switch to cs mode
        output->init = 0;
        pdo_output->op_mode = 0;
        pdo_output->tuning_command = 0;
        output->app_mode = CS_MODE;
        break;
#endif

    //reverse command
    case 'r':
        if (output->mode_1 == 1) {
            pdo_output->target_velocity =  -pdo_output->target_velocity;
            pdo_output->target_torque =  -pdo_output->target_torque;
        } else {
            (*cursor).col = draw(wnd, c, (*cursor).row, (*cursor).col); // draw the character
            if (output->mode_2 == 1) {
                output->mode_2 = c;
            } else {
                output->mode_3 = c;
            }
        }
        break;

    //discard command
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
        output->value_float = 0;
        output->float_count = 0;
        output->sign = 1;
        break;


    /* multiple letters commands */
    default:
        //parse letters and numbers as they come
        if (0x20 <= c && c <= 0x7e) { //printable char
            (*cursor).col = draw(wnd, c, (*cursor).row, (*cursor).col); // draw the character
            //parse input
            if(isdigit(c)>0) {
                if (output->float_count == 0) {
                    output->value *= 10;
                    output->value += c - '0';
                } else {
                    output->float_count *= 10;
                    output->value_float +=  (float)(c - '0') / (float)output->float_count;
                }
            } else if (c == '-') {
                output->sign = -1;
            } else if (c == '.' && output->float_count == 0) {
                output->float_count = 1;
                output->value_float = output->value;
            } else if (c != ' ' && c != '\n') {
                if (output->mode_1 == 1) {
                    output->mode_1 = c;
                } else if (output->mode_2 == 1) {
                    output->mode_2 = c;
                } else {
                    output->mode_3 = c;
                }
            }

        //(enter): parse and execute the whole command
        } else if (c == '\n') {
            if (output->float_count == 0) {
                output->value_float = (float)output->value;
            }
            output->value *= output->sign;
            output->value_float *= output->sign;
            switch(output->mode_1) {

            // offset finding, position/velocity control auto tune, and cogging torque commands
            case 'a':
                pdo_output->tuning_command = TUNING_CMD_AUTO_OFFSET;
                switch(output->mode_2) {
                case 'p':
                    switch(output->mode_3) {
                    case 'a':
                        pdo_output->tuning_command = TUNING_CMD_TUNE_AMPLITUDE;
                        break;
                    case 'p':
                        pdo_output->tuning_command = TUNING_CMD_TUNE_PERIOD;
                        break;
                    default:
                        pdo_output->tuning_command = TUNING_CMD_AUTO_POS_CTRL_TUNE;
                        pdo_output->target_position = pdo_input.position_value;
                        break;
                    }
                    pdo_output->user_mosi = output->value;
                    break;

                case 'c':
                    switch(output->mode_3) {
                    case 's':
                        pdo_output->tuning_command = TUNING_CMD_SAVE_RECORD_COGGING;
                        break;
                    case 'l':
                        pdo_output->tuning_command = TUNING_CMD_LOAD_RECORD_COGGING;
                        break;

                    default:
                        pdo_output->tuning_command = TUNING_CMD_AUTO_RECORD_COGGING;
                        break;
                    }
                    break;
                case 'v':
                    pdo_output->tuning_command = TUNING_CMD_AUTO_VEL_CTRL_TUNE;
                    pdo_output->target_velocity = 0;
                    break;
                }
                break;

            //brake
            case 'b':
                if (output->mode_2 == 's') { // bs: set brake selease strategy value
                    pdo_output->tuning_command = TUNING_CMD_BRAKE_RELEASE_STRATEGY;
                    pdo_output->user_mosi = output->value;
                } else { //b: toggle brake
                    pdo_output->tuning_command = TUNING_CMD_BRAKE;
                    if ((pdo_input.tuning_status >> 8) & 1) { //brake is released
                        pdo_output->user_mosi = 0;
                    } else {
                        pdo_output->user_mosi = 1;
                    }
                }
                break;

            //set position commands
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

            // enable/disable motorcontrol commands
            case 'e':
                pdo_output->tuning_command = TUNING_CMD_CONTROL_DISABLE;
                if (output->mode_2 == 'c') {
                    pdo_output->tuning_command = TUNING_CMD_COGGING_TORQUE;
                    if (((pdo_input.tuning_status >> 8) >> TUNING_FLAG_COGGING_TORQUE) & 1) { //read cogging torque flag
                        pdo_output->user_mosi = 0;
                    } else {
                        pdo_output->user_mosi = 1;
                    }
                } else if (output->value) {
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
                pdo_output->tuning_command = TUNING_CMD_POLARITY_MOTION;
                if ((pdo_input.tuning_status >> 8) & 0x02) { //polarity is reverse
                    pdo_output->user_mosi = 0;
                } else {
                    pdo_output->user_mosi = 1;
                }
                break;

            //phases inverted
            case 'm':
                pdo_output->tuning_command = TUNING_CMD_PHASES_INVERTED;
                if ((pdo_input.tuning_status >> 8) & 0x08) { //phase inverted
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


            //reset fault
            case 'f':
                pdo_output->tuning_command = TUNING_CMD_FAULT_RESET;
                break;


            //torque safe enable (tss)
            case 't':
                if (output->mode_2 == 's' && output->mode_3 == 's') {
                    pdo_output->tuning_command = TUNING_CMD_SAFE_TORQUE;
                }
                break;

            //change pid coefficients
            case 'k':
                value.f = output->value_float;
                pdo_output->user_mosi = output->value;
                switch(output->mode_2) {
                case 'p': //position
                    switch(output->mode_3) {
                    case 'p':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KP;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'i':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KI;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'd':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_KD;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'l':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_I_LIM;
                        break;
                    case 'j':
                        pdo_output->tuning_command = TUNING_CMD_MOMENT_INERTIA;
                        break;
                    case 'P':
                        pdo_output->tuning_command = TUNING_CMD_POSITION_PROFILER;
                        if ((pdo_input.tuning_status >> 8) & 0x10) { //profiler on
                            pdo_output->user_mosi = 0;
                        } else {
                            pdo_output->user_mosi = 1;
                        }
                        break;
                    }
                    break;
                case 'v': //velocity
                    switch(output->mode_3) {
                    case 'p':
                        pdo_output->tuning_command = TUNING_CMD_VELOCITY_KP;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'i':
                        pdo_output->tuning_command = TUNING_CMD_VELOCITY_KI;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'd':
                        pdo_output->tuning_command = TUNING_CMD_VELOCITY_KD;
                        pdo_output->user_mosi = value.i;
                        break;
                    case 'l':
                        pdo_output->tuning_command = TUNING_CMD_VELOCITY_I_LIM;
                        break;
                    }
                    break;
                case 't': //torque
                    switch(output->mode_3) {
                    case 'r':
                        pdo_output->tuning_command = TUNING_CMD_RATED_TORQUE;
                        break;
                    }
                    break;
                case 'f': //filter
                    pdo_output->tuning_command = TUNING_CMD_FILTER;
                    break;
                } /* end mode_2 */
                break;


            //set limits
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

            //GPIO output
            case 'g':
                if (output->value <= 1111) {
                    char * input = malloc(5*sizeof(char));
                    sprintf(input, "%04d", output->value);
                    uint8_t gpio_output = 0;
                    for (int i=3; i>=0; i--) {
                        if (input[i] != '0') {
                            gpio_output |= 0b1000 >> i;
                        }
                    }
                    free(input);
                    pdo_output->digital_output1 = (gpio_output & 0b0001);
                    pdo_output->digital_output2 = (gpio_output & 0b0010) >> 1;
                    pdo_output->digital_output3 = (gpio_output & 0b0100) >> 2;
                    pdo_output->digital_output4 = (gpio_output & 0b1000) >> 3;
                }
                break;


            // default is enable torque control and set torque command
            // if the value is 0 stop everything. So just pressing Enter without a command act as an emergency stop
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

            //reset commmands
            output->mode_1 = 1;
            output->mode_2 = 1;
            output->mode_3 = 1;
            output->value = 0;
            output->value_float = 0;
            output->float_count = 0;
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

void tuning_record(RecordConfig * config, struct _pdo_cia402_input pdo_input, struct _pdo_cia402_output pdo_output, InputValues input, char *filename)
{
    if (config->state == RECORD_ON && config->count < config->max_values) {
        if (config->data == NULL) {
            config->data = malloc(sizeof(RecordData)*config->max_values); //malloc for 2 minutes of data
        }
        switch(input.motorctrl_status) {
        case TUNING_MOTORCTRL_POSITION_PID:
        case TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED:
        case TUNING_MOTORCTRL_POSITION_LT:
            config->data[config->count].target = pdo_output.target_position;
            break;
        case TUNING_MOTORCTRL_VELOCITY:
            config->data[config->count].target = pdo_output.target_velocity;
            break;
        case TUNING_MOTORCTRL_TORQUE:
            config->data[config->count].target = pdo_output.target_torque;
            break;
        default:
            config->data[config->count].target = 0;
            break;
        }
        config->data[config->count].position = (int32_t)pdo_input.position_value;
        config->data[config->count].velocity = (int32_t)pdo_input.velocity_value;
        config->data[config->count].torque = (int16_t)pdo_input.torque_value;
        config->data[config->count].timestamp = (int32_t)pdo_input.timestamp;
        config->count++;
    } else {
        if (config->data != NULL) { //save to file
            FILE *fd = fopen(filename, "w");
            fprintf(fd, "count,timestamp,target,position,velocity,torque\n");
            for (int i=0 ; i<config->count ; i++) {
                fprintf(fd, "%d,%d,%d,%d,%d,%d\n", i, config->data[i].timestamp, config->data[i].target, config->data[i].position, config->data[i].velocity, config->data[i].torque);
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
        if (pdo_input->tuning_status & TUNING_ACK) { //command received by slave
            pdo_output->tuning_command = 0; //reset command
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
    display_tuning(wnd, *pdo_output, *pdo_input, *input, *record_config, 0);

    //recorder
    tuning_record(record_config, *pdo_input, (*pdo_output), *input, record_filename);

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
