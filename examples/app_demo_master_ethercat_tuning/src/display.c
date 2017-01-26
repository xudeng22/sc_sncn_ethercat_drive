
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

int display_tuning(WINDOW *wnd, struct _pdo_cia402_input pdo_input, InputValues input, RecordConfig record_config, int row)
{
    //row 0
    wmoveclr(wnd, &row);
    //motorcontrol mode
    wprintw(wnd, "** Operation mode: ");
    switch(input.motorctrl_status) {
    case TUNING_MOTORCTRL_OFF:
        wprintw(wnd, "off");
        break;
    case TUNING_MOTORCTRL_TORQUE:
        wprintw(wnd, "Torque control %5d", input.target);
        break;
    case TUNING_MOTORCTRL_POSITION:
        wprintw(wnd, "Position control %9d", input.target);
        break;
    case TUNING_MOTORCTRL_VELOCITY:
        wprintw(wnd, "Velocity control %5d", input.target);
        break;
    case TUNING_MOTORCTRL_POSITION_PROFILER:
        wprintw(wnd, "Position control with integrated profiler %5d", input.target);
        break;
    }
    wprintw(wnd, " **");
    //row 1
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position %14d | Velocity            %4d",  pdo_input.actual_position, pdo_input.actual_velocity);
    //row 2
    wmoveclr(wnd, &row);
    wprintw(wnd, "Torque computed    %4d | Torque sensor       %4d", (int16_t)pdo_input.actual_torque, pdo_input.user_in_1);
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
    if (input.brake_flag == 0)
        wprintw(wnd, "Brake blocking          ");
    else
        wprintw(wnd, "Brake released          ");
    if (input.brake_release_strategy != 0)
        wprintw(wnd, "| Brake shaking %d\%", input.brake_release_strategy);
    //row 6
    wmoveclr(wnd, &row);
    wprintw(wnd, "Speed  limit      %5d | ", input.max_speed);
    wprintw(wnd, "Position min %11d", input.min_position);
    //row 7
    wmoveclr(wnd, &row);
    wprintw(wnd, "Torque limit      %5d | ", input.max_torque);
    wprintw(wnd, "Position max %11d", input.max_position);
    //row 8
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position P    %9d | ", input.P_pos);
    wprintw(wnd, "Velocity P     %9d", input.P_velocity);
    //row 9
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position I    %9d | ", input.I_pos);
    wprintw(wnd, "Velocity I     %9d", input.I_velocity);
    //row 10
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position D    %9d | ", input.D_pos);
    wprintw(wnd, "Velocity D     %9d", input.D_velocity);
    //row 11
    wmoveclr(wnd, &row);
    wprintw(wnd, "Position I lim    %5d | ", input.integral_limit_pos);
    wprintw(wnd, "Velocity I lim     %5d", input.integral_limit_velocity);
    //row 12
    wmoveclr(wnd, &row);
    if (input.error_status != 0)
        wprintw(wnd, "* Error Status %d * ", input.error_status);
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
