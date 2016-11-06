
#include <curses.h> // required
#include "display.h"

void init_window(WINDOW *wnd) {
    //init ncurses
    wnd = initscr(); // curses call to initialize window
    //cbreak(); // curses call to set no waiting for Enter key
//    noecho(); // curses call to set no echoing
    //getmaxyx(wnd,nrows,ncols); // curses call to find size of window
//    clear(); // curses call to clear screen, send cursor to position (0,0)
//    refresh(); // curses call to implement all changes since last refresh
//    nodelay(stdscr, TRUE); //no delay
}

void display(WINDOW *wnd, int *target_position, struct _pdo_cia402_input *pdo_input, size_t num_slaves)
{
    wmove(wnd,0,0);
//    wclrtoeol(wnd);
//    wprintw(wnd,"Target: %d, %d", *target_position, *(target_position+1));

    for (size_t i = 0; i < num_slaves; i++) {
        struct {signed int x:16;} s; //to sign extend 16 bit torque
        s.x = pdo_input[i].actual_torque;
        pdo_input[i].actual_torque = s.x;
    
        wmove(wnd, i, 0);
        wclrtoeol(wnd);
        wprintw(wnd,"Slave %d: Target %10d | Position %10d | Velocity %4d | Torque %d", i, target_position[i], pdo_input[i].actual_position, pdo_input[i].actual_velocity, pdo_input[i].actual_torque);
    }

    wrefresh(wnd);
}
