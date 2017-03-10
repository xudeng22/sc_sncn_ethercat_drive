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
#include <ethercat_wrapper.h>

int pdo_handler(Ethercat_Master_t *master, struct _pdo_cia402_input *pdo_input, struct _pdo_cia402_output *pdo_output, int slaveid);

#endif /* CYCLICTASK_H */
