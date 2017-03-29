/*
 * utils.h
 *
 *  Created on: Mar 29, 2017
 *      Author: synapticon
 */

#ifndef UTILS_H_
#define UTILS_H_

#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/time.h>
#include <linux/limits.h>

void cmdline(int argc, char **argv, const char *version, int *sdo_enable, int *profile_speed, char **sdo_config);

extern unsigned int sig_alarms;
extern unsigned int user_alarms;

void setup_signal_handler(struct sigaction *sa);

void setup_timer(struct itimerval *tv, const int frequency);


#endif /* UTILS_H_ */
