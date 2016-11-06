/*
 * ectconf.h
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef DISPLAY_H
#define DISPLAY_H

#include <curses.h> // required
#include "ecat_master.h"


void init_window(WINDOW *wnd);

void display(WINDOW *wnd, int *target_position, struct _pdo_cia402_input *pdo_input, size_t count);


#endif /* DISPLAY_H */
