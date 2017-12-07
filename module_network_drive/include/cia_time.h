
/**
 * @file cia_time.h
 * @brief Functions to parse and access CiA TIME_OF_DAY datatype
 * @author Synapticon GmbH <support@synapticon.com>
 */

/*
 *
 * These functions calculate the time based on the epoche starting at:
 * 1.1.1984 00:00 (Orwell Time)
 * Which is used in the CiA specification for the object TIME_OF_DAY.
 *
 * NOTE:
 * All this calculation could be far simpler if I used the functions in time.h
 * and sys/time.h but unfortunatly the XMOS guys f'uped this library calls.
 */

#pragma once

#include <stdint.h>

#define SECONDS_PER_DAY             (3600 * 24)

typedef uint64_t ciatime_t;
typedef uint64_t ciatime_sec_t;
typedef uint32_t ciatime_usec_t;

struct _cia_time_of_day {
    uint32_t msec;
    uint16_t days;
};

struct _ciatime_val {
	ciatime_sec_t  sec;
	ciatime_usec_t usec;
};

struct _ciatm {
	int ct_sec;     /* seconds (0 - 60) */
	int ct_min;     /* minutes (0 - 59) */
	int ct_hour;    /* hours (0 - 23) */
	int ct_mday;    /* day of month (1 - 31) */
	int ct_mon;     /* month of year (0 - 11) */
	int ct_year;    /* year - 1900 */
	int ct_wday;    /* day of week (Sunday = 0) */ /* UNUSED */
	int ct_yday;    /* day of year (0 - 365) */ /* UNUSED */
	int ct_isdst;   /* is summer time in effect? */ /* UNUSED */
	long ct_gmtoff; /* offset from UTC in seconds */ /* UNUSED */
};

/**
 * @brief Convert time value (seconds, mikroseconds) to break down time
 *
 * @param[in]  tval    time value to convert
 * @param[out] ciatm    output structure for broken down time
 * @return 0 on success, 1 on error
 */
int ciatime_localtime(struct _ciatime_val &tval, struct _ciatm &ciatm);

/**
 * @brief Split seconds to split up time
 *
 * @param[in] sec     Seconds since 1.1.1984
 * @param[out] ciatm  Ouputstruct \see struct _ciatm format
 */
int ciatime_split_seconds(ciatime_t sec, struct _ciatm &ciatm);

/**
 * @brief Perform some internal test routines.
 */
int ciatime_selftest(void);
