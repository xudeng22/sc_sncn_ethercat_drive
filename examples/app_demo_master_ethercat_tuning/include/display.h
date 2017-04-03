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

int display_tuning(WINDOW *wnd, struct _pdo_cia402_output pdo_output, struct _pdo_cia402_input pdo_input, InputValues input, RecordConfig record_config, int row);

int display_tuning_help(WINDOW *wnd, int row);

int display_slaves(WINDOW *wnd, int row, struct _pdo_cia402_output *pdo_output, struct _pdo_cia402_input *pdo_input, size_t num_slaves, OutputValues output);

#endif /* DISPLAY_H */
