/*
 * filelog.c
 *
 * Log significant values to a file.
 */

/* To be able to use the newer POSIX function clock_gettime() it is necessary to
 * mark the code this this define. See also `man 2 clock_gettime`. */
#define _POSIX_C_SOURCE  199309L

#include "filelog.h"
#include <stdarg.h>
#include <stdio.h>
#include <time.h>

void filelogtimestamp(FILE *logfile, unsigned int pdo_timestamp)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) < 0) {
        fprintf(logfile, "INVALID local time\n");
        return;
    }

    unsigned long localtimestamp = ts.tv_sec * 1000000 + ts.tv_nsec / 1000; /* use microseconds since epoche */

    fprintf(logfile, "%lu, %u\n", localtimestamp, pdo_timestamp);
}
