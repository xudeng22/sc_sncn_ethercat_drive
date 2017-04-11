
#include "display.h"
#include <stdint.h>

void wmoveclr(WINDOW *wnd, int *row)
{
    wmove(wnd, *row, 0);
    wclrtoeol(wnd);
    (*row)++;
}

int draw(WINDOW *wnd, char c, int row, int column)
{
    wmove(wnd, row,column); // curses call to move cursor to row r, column c
    wdelch(wnd); winsch(wnd, c); // curses calls to replace character under cursor by dc
    return (column+1);
}

void print_state(WINDOW *wnd, enum eCIAState state)
{
    switch(state) {
    case CIASTATE_NOT_READY:
        wprintw(wnd, "NOT_READY         ");
        break;
    case CIASTATE_SWITCH_ON_DISABLED:
        wprintw(wnd, "SWITCH_ON_DISABLED");
        break;
    case CIASTATE_READY_SWITCH_ON:
        wprintw(wnd, "READY_SWITCH_ON   ");
        break;
    case CIASTATE_SWITCHED_ON:
        wprintw(wnd, "SWITCHED_ON       ");
        break;
    case CIASTATE_OP_ENABLED:
        wprintw(wnd, "OP_ENABLED        ");
        break;
    case CIASTATE_QUICK_STOP:
        wprintw(wnd, "QUICK_STOP        ");
        break;
    case CIASTATE_FAULT_REACTION_ACTIVE:
        wprintw(wnd, "FAULT_REACTION    ");
        break;
    case CIASTATE_FAULT:
        wprintw(wnd, "FAULT             ");
        break;
    default:
        wprintw(wnd, "%04d              ", state);
        break;
    }
}

void print_motor_fault(WINDOW *wnd, int fault)
{
    switch(fault) {
    case DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1:
        wprintw(wnd, "Over Current");
        break;
    case OVER_VOLTAGE_NO_1:
        wprintw(wnd, "Over Voltage");
        break;
    case UNDER_VOLTAGE_NO_1:
        wprintw(wnd, "Under Voltage");
        break;
    case EXCESS_TEMPERATURE_DRIVE:
        wprintw(wnd, "Temperature");
        break;
    default:
        wprintw(wnd, "0x%04x", fault);
        break;
    }
}

int display_tuning(WINDOW *wnd, struct _pdo_cia402_output pdo_output, struct _pdo_cia402_input pdo_input, InputValues input, RecordConfig record_config, int row)
{
    //row 0
    wmoveclr(wnd, &row);
    //motorcontrol mode
    wprintw(wnd, "** Operation mode: ");
    switch(input.motorctrl_status) {
    case TUNING_MOTORCTRL_OFF:
        wprintw(wnd, "off");
        break;
    case TUNING_MOTORCTRL_POSITION_PID:
        wprintw(wnd, "Position control PID %9d", pdo_output.target_position);
        break;
    case TUNING_MOTORCTRL_POSITION_PID_VELOCITY_CASCADED:
        wprintw(wnd, "Position control Velocity Cascaded %9d", pdo_output.target_position);
        break;
    case TUNING_MOTORCTRL_POSITION_NL:
        wprintw(wnd, "Position control Non Linear %9d", pdo_output.target_position);
        break;
    case TUNING_MOTORCTRL_VELOCITY:
        wprintw(wnd, "Velocity control %5d", pdo_output.target_velocity);
        break;
    case TUNING_MOTORCTRL_TORQUE:
        wprintw(wnd, "Torque control %5d", pdo_output.target_torque);
        break;
    }
    wprintw(wnd, " **");
    //row 1
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position %14d | Velocity            %4d",  pdo_input.position_value, pdo_input.velocity_value);
    //row 2
    wmoveclr(wnd, &row);
    wprintw(wnd, "Torque computed    %4d | Torque sensor       %4d", (int16_t)pdo_input.torque_value, pdo_input.analog_input1);
    //row 3
    wmoveclr(wnd, &row);
    wprintw(wnd, "Offset             %4d | Pole pairs            %2d", input.offset, input.pole_pairs);
    //row 4
    wmoveclr(wnd, &row);
    if (input.motion_polarity == 0)
        wprintw(wnd, "Motion polarity normal  | ");
    else
        wprintw(wnd, "Motion polarity inverted| ");
    if (input.sensor_polarity == 0)
        wprintw(wnd, "Sensor polarity normal");
    else
        wprintw(wnd, "Sensor polarity inverted");
    //row 5
    wmoveclr(wnd, &row);
    if (input.profiler) {
        wprintw(wnd, "Integrated Profiler on  ");
    } else {
        wprintw(wnd, "Integrated Profiler off ");
    }
    if (input.phases_inverted) {
        wprintw(wnd, "| Phases connection inverted");
    } else {
        wprintw(wnd, "| Phases connection normal");
    }
    //row 6
    wmoveclr(wnd, &row);
    if (input.brake_flag == 0)
        wprintw(wnd, "Brake blocking          ");
    else
        wprintw(wnd, "Brake released          ");
    if (input.brake_release_strategy != 0)
        wprintw(wnd, "| Brake shaking %d\%", input.brake_release_strategy);
    //row 7
    wmoveclr(wnd, &row);
    wprintw(wnd, "Speed  limit      %5d | ", input.max_speed);
    wprintw(wnd, "Position min %11d", input.min_position);
    //row 8
    wmoveclr(wnd, &row);
    wprintw(wnd, "Torque limit      %5d | ", input.max_torque);
    wprintw(wnd, "Position max %11d", input.max_position);
    //row 9
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position P    %9d | ", input.P_pos);
    wprintw(wnd, "Velocity P     %9d", input.P_velocity);
    //row 10
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position I    %9d | ", input.I_pos);
    wprintw(wnd, "Velocity I     %9d", input.I_velocity);
    //row 11
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position D    %9d | ", input.D_pos);
    wprintw(wnd, "Velocity D     %9d", input.D_velocity);
    //row 12
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position I lim    %5d | ", input.integral_limit_pos);
    wprintw(wnd, "Velocity I lim     %5d", input.integral_limit_velocity);
    //row 13
    wmoveclr(wnd, &row);
    if (input.error_status != 0) {
        wprintw(wnd, "* Motor Fault ");
        print_motor_fault(wnd, input.error_status);
        wprintw(wnd, " * ");
    }
    if (input.sensor_error != 0)
        wprintw(wnd, "* Sensor Error %d * ", input.sensor_error);
    if (record_config.state == RECORD_ON)
        wprintw(wnd, "* Record ON *");
    return row;
}

int display_tuning_help(WINDOW *wnd, int row)
{
    //init prompt
    wmoveclr(wnd, &row);
    printw("Commands:");
    wmoveclr(wnd, &row);
    printw("b:          Release/Block Brake");
    wmoveclr(wnd, &row);
    printw("a:          Find offset (also release the brake)");
    wmoveclr(wnd, &row);
    printw("number:     Set torque command");
    wmoveclr(wnd, &row);
    printw("r:          Reverse torque command");
    wmoveclr(wnd, &row);
    printw("ep3:        Enable position control");
    wmoveclr(wnd, &row);
    printw("p + number: Set position command");
    wmoveclr(wnd, &row);
    printw("P + number: Set pole pairs");
    wmoveclr(wnd, &row);
    printw(".:          Start/stop recording");
    wmoveclr(wnd, &row);
    printw("L s/t/p + number: set speed/torque/position limit");
    wmoveclr(wnd, &row);
    printw("** single press Enter for emergency stop **");
    return row;
}

void wprintw_attr(WINDOW *wnd, char * str, int var, int attr)
{
    wattron(wnd, attr);
    wprintw(wnd, str, var);
    wattroff(wnd, attr);
}

int display_slaves(WINDOW *wnd, int row, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t num_slaves, OutputValues output)
{
    wmoveclr(wnd, &row);
    wprintw(wnd, "-----------------------------------------------------------------------");
    for (size_t i = 0; i < num_slaves; i++) {
        int attr = A_NORMAL;
        if (i == output.select) {
            attr = A_STANDOUT;
        }

        wmoveclr(wnd, &row);
        wprintw_attr(wnd,"Slave %2d:", i, attr);

        //display state
        enum eCIAState state = read_state(pdo_input[i].statusword);
        int target = 0;
        switch(state) {
        case CIASTATE_NOT_READY:
        case CIASTATE_SWITCH_ON_DISABLED:
        case CIASTATE_READY_SWITCH_ON:
        case CIASTATE_SWITCHED_ON:
            wprintw(wnd," Operation mode: Off        ");
            break;
        case CIASTATE_QUICK_STOP:
            wprintw(wnd," Quick Stop!                ");
            break;
        case CIASTATE_FAULT:
        case CIASTATE_FAULT_REACTION_ACTIVE:
            wprintw(wnd," Fault!                     ");
            break;
        case CIASTATE_OP_ENABLED:
            switch(pdo_input[i].op_mode_display) {
            case 8: //CSP
                target = pdo_output[i].target_position;
                wprintw(wnd," Position control %10d", target);
                break;
            case 9: //CSV
                target = pdo_output[i].target_velocity;
                wprintw(wnd," Velocity control %10d", target);
                break;
            case 10://CST
                target = pdo_output[i].target_torque;
                wprintw(wnd," Torque control   %10d", target);
                break;
            }
            break;
        }


        //dispay debug
        if (output.debug) {
            wprintw(wnd, " |");
            print_state(wnd, state);
            wprintw(wnd, "|%04x|%3d", pdo_input[i].statusword, pdo_input[i].op_mode_display);
        }

        wmoveclr(wnd, &row);
        wprintw_attr(wnd,"         ", 0, attr);
        wprintw(wnd, " Position         %10d | Velocity %7d | Torque %5d", pdo_input[i].position_value, pdo_input[i].velocity_value, pdo_input[i].torque_value);
        wmoveclr(wnd, &row);
        wprintw(wnd, "-----------------------------------------------------------------------");
    }
    return row;
}
