/*
 * ectconf.h
 *
 * configuration for the SDOs
 *
 * 2016-06-16, Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef CYCLICTASK_H
#define CYCLICTASK_H

#include "ecat_pdo_conf.h"
#include "ecat_master.h"

int pdo_handler(struct _master_config *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output, int slaveid);

#endif /* CYCLICTASK_H */
