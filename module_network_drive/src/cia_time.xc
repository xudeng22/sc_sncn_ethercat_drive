/**
 * @file cia_time.xc
 * @brief Functions to parse and access CiA TIME_OF_DAY datatype
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include "cia_time.h"

#define SECS_PER_HOUR  (60 * 60)
#define SECS_PER_DAY   (24 * 60 * 60)
#define ORWELL_YEAR    1984

const static int days_per_month[2][12] = {
	{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
	{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
};

static inline int is_leap(int y)
{
	return (y%4 == 0) && ((y%100 != 0) || (y%400 == 0));
}

static inline unsigned int days_of_year(int year)
{
	const int Yearsize = 365;
	return (Yearsize + is_leap(year));
}

int ciatime_selftest(void)
{
#if 0
	const int Startyear = 0;
	printf("Leap years since %d:\n", Startyear);
	for (int y = Startyear; y < 2200; y++) {
		if (is_leap(y))
			printf("Leap Year: %d\n", y);
	}

	printf("Days in the year:\n");
	for (int y = 1984; y < 2020; y++) {
		printf("Year: %d; Days: %d\n", y, days_of_year(y));

		printf("  Days after months sizes:\n");
		for (int m = 0, mday = 0; m < 12; m++) {
			mday += days_per_month[is_leap(y)][m];
			printf("  Month %d (%d) = %d\n",
			       m, days_per_month[is_leap(y)][m], mday);
		}
	}
#endif

	return 0;
}

int ciatime_split_seconds(ciatime_t sec, struct _ciatm &ciatm)
{
	ciatime_t daysecs  = (ciatime_t)(sec % SECS_PER_DAY);
	ciatime_t daycount = (ciatime_t)(sec / SECS_PER_DAY);

	int year = ORWELL_YEAR;

	while (daycount >= days_of_year(year)) {
		daycount -= days_of_year(year);
		year++;
	}

	ciatm.ct_year = year;

	int month = 0;
	while (daycount >= days_per_month[is_leap(year)][month]) {
		daycount -= days_per_month[is_leap(year)][month];
		month++;
	}

	ciatm.ct_mon = month;
	ciatm.ct_mday = daycount;

	/* finally parse the time */
	ciatm.ct_hour = daysecs / (60 * 60) + 1;
	ciatm.ct_min = (daysecs / 60) % 60;
	ciatm.ct_sec = daysecs % 60;

	return 0;
}

int ciatime_localtime(struct _ciatime_val &chval, struct _ciatm &ciatm)
{
	return -1;
}
