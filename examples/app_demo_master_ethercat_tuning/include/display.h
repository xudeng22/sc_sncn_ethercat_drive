/*
 * ectconf.h
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef DISPLAY_H
#define DISPLAY_H

typedef struct {
    int row;
    int col;
} Cursor;

#include <curses.h> // required
#include "ecat_master.h"
#include "tuning.h"

void wmoveclr(WINDOW *wnd, int *row);

int draw(WINDOW *wnd, char c, int row, int column);

int display_tuning(WINDOW *wnd, struct _pdo_cia402_input pdo_input, InputValues input, int row);

int display_tuning_help(WINDOW *wnd, int row);

#endif /* DISPLAY_H */
