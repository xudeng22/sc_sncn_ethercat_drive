
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

void print_state(WINDOW *wnd, CIA402State state)
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
        wprintw(wnd, "%04d              ");
        break;
    }
}

void print_help(WINDOW *wnd, int row)
{
    wmoveclr(wnd, &row);
    wprintw(wnd,
            "up | down arrows: select slave\n"
            "p | v | t: switch to CSP | CSV | CST operation mode\n"
            "[number]: set target (depends on the opmode)\n"
            "r: reverse target\n"
            "s: disable operation, 'ss' to stop all the slaves\n"
            "a: acknowledge fault\n"
            "q: quit"
    );
}

void wprintw_attr(WINDOW *wnd, char * str, int var, int attr)
{
    wattron(wnd, attr);
    wprintw(wnd, str, var);
    wattroff(wnd, attr);
}

int display_slaves(WINDOW *wnd, int row, PDOOutput *pdo_output, PDOInput *pdo_input, size_t num_slaves, OutputValues output)
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
        CIA402State state = cia402_read_state(pdo_input[i].statusword);
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
            case OPMODE_CSP: //CSP
                target = pdo_output[i].target_position;
                wprintw(wnd," Position control %10d", target);
                break;
            case OPMODE_CSV: //CSV
                target = pdo_output[i].target_velocity;
                wprintw(wnd," Velocity control %10d", target);
                break;
            case OPMODE_CST://CST
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
            wprintw(wnd, "|%04x|%3d|%04x", pdo_input[i].statusword, pdo_input[i].op_mode_display, pdo_input[i].user_miso);
        }

        wmoveclr(wnd, &row);
        wprintw_attr(wnd,"         ", 0, attr);
        wprintw(wnd, " Position         %10d | Velocity %7d | Torque %5d", pdo_input[i].position_value, pdo_input[i].velocity_value, pdo_input[i].torque_value);
        wmoveclr(wnd, &row);
        wprintw(wnd, "-----------------------------------------------------------------------");
    }
    return row;
}
