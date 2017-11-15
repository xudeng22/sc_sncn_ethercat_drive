/*
 * filelog.h
 *
 * log significant values to a file.
 */

#ifndef FILELOG_H
#define FILELOG_H

#include <stdio.h>

/**
 * @brief Write pdo timestamp to logfile
 *
 * @param logfile        pointer to opened logfile
 * @param pdo_timestamp  the timestamp to log (usual in 'ns')
 */
void filelogtimestamp(FILE *logfile, unsigned int pdo_timestamp);

#endif /* FILELOG_H */
