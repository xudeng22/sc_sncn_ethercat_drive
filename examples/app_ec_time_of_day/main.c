/*
 * ec_time_of_day - get the current time and print EtherCAT's TIME_OF_DAY
 *                  formatted string of the hex representation.
 *
 * Copyright 2017, Synapticon GmbH
 */

#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>

/* days (in ms) between Jan, 1 1973 and Jan, 1 1984 */
#define SEC_UNIXTIME_TO_ORWELLTIME  441763200
#define SEC_PER_DAYS                (3600 * 24)

enum eDisplay {
	DISP_NONE=0
	,DISP_HEX
	,DISP_OCTET
	,DISP_ROCTET
};

typedef struct _ec_time_of_day {
	uint32_t millis_since_midnight;
	uint16_t days_since_1984;
} EC_Time_Of_Day;

/* calculate the time of day from current local time */
static int calc_time_of_day(enum eDisplay display)
{
	EC_Time_Of_Day ec_time_alt;
	struct timeval current_time;

	if (gettimeofday(&current_time, NULL) < 0) {
		fprintf(stderr, "Error getting local time!\n");
		return -1;
	}

	ec_time_alt.days_since_1984 = (current_time.tv_sec - SEC_UNIXTIME_TO_ORWELLTIME) / SEC_PER_DAYS;
	ec_time_alt.millis_since_midnight = (current_time.tv_sec % (24 * 60 * 60) * 1000) + (current_time.tv_usec / 1000);

#if DEBUG == 1
	printf("DEBUG: Days since Orwelll: %u (0x%x) Milliseconds since midnight: %lu (0x%x)\n",
	       ec_time_alt.days_since_1984, ec_time_alt.days_since_1984,
	       ec_time_alt.millis_since_midnight, ec_time_alt.millis_since_midnight);

	printf("MSB Formatted TIME_OF_DAY value:\n");
#endif

	uint64_t outvalue = ((uint64_t)(ec_time_alt.days_since_1984 & 0xffff) << 32) |
	                    ((uint64_t)ec_time_alt.millis_since_midnight & 0xfffffff);

	switch (display) {
	case DISP_OCTET:
		printf("%02x %02x %02x %02x %02x %02x %02x %02x\n",
		      (unsigned int)(outvalue>>56)&0xff,
		      (unsigned int)(outvalue>>48)&0xff,
		      (unsigned int)(outvalue>>40)&0xff,
		      (unsigned int)(outvalue>>32)&0xff,
		      (unsigned int)(outvalue>>24)&0xff,
		      (unsigned int)(outvalue>>16)&0xff,
		      (unsigned int)(outvalue>>8)&0xff,
		      (unsigned int)(outvalue)&0xff);
		break;

	case DISP_ROCTET:
		printf("%02x %02x %02x %02x %02x %02x %02x %02x\n",
		      (unsigned int)(outvalue)&0xff,
		      (unsigned int)(outvalue>>8)&0xff,
		      (unsigned int)(outvalue>>16)&0xff,
		      (unsigned int)(outvalue>>24)&0xff,
		      (unsigned int)(outvalue>>32)&0xff,
		      (unsigned int)(outvalue>>40)&0xff,
		      (unsigned int)(outvalue>>48)&0xff,
		      (unsigned int)(outvalue>>56)&0xff);
		break;

	case DISP_NONE:
	case DISP_HEX:
	default:
		printf("0x%llx\n", outvalue);
		break;
	}


#if DEBUG == 1
	EC_Time_Of_Day check;
	check.days_since_1984 = (outvalue >> 32) & 0xffff;
	check.millis_since_midnight = outvalue & 0xfffffff;
	printf("DEBUG: Days since Orwelll: %u (0x%x) Milliseconds since midnight: %lu (0x%x)\n",
	       check.days_since_1984, check.days_since_1984,
	       check.millis_since_midnight, check.millis_since_midnight);
#endif

	return 0;
}

/* no, timzone stuff is not supported */
static int get_time_val(char *argv, struct timeval *tv)
{
	uint64_t tstmp = 0;
	EC_Time_Of_Day tod = { 0, 0 };

	sscanf(argv, "0x%llx", (unsigned long long *)&tstmp);
	tod.millis_since_midnight = tstmp & 0xfffffff;
	tod.days_since_1984 = (tstmp >> 32) & 0xffff;

#if DEBUG == 1
	printf("%s = 0x%x\n", argv, tstmp);
	printf("days since 1984: %u | millis since midnight %lu\n", tod.days_since_1984, tod.millis_since_midnight);
#endif
	tv->tv_sec =  tod.days_since_1984 * SEC_PER_DAYS + SEC_UNIXTIME_TO_ORWELLTIME;
	uint32_t tmp = tod.millis_since_midnight / 1000;
	tv->tv_sec += tmp;
	tv->tv_usec = tod.millis_since_midnight - tmp;

	return 0;
}

static void reverse_print_time(int argc, char *argv[])
{
	struct timeval t;
	for (int i = 0; i < argc; i++) {
#if DEBUG == 1
		printf("%d: '%s'\n", i, argv[i]);
#endif
		get_time_val(argv[i], &t);
		printf("%lu.%d\n", t.tv_sec, t.tv_usec);
		char *tstr = ctime(&t.tv_sec);
		if (tstr == NULL) {
			fprintf(stderr, "Error: can not convert to time string\n");
			continue;
		}
		printf("Time: %s\n", tstr);
	}
}

static enum eDisplay get_format(char *fstring)
{
	enum eDisplay ret = DISP_NONE;
	const char *values[] = {
		"normall",
		"msb_octets",
		"lsb_octets" };

	for (int i = 0; i < 3; i++) {
		if (strncmp(fstring, values[i], strlen(fstring)) == 0) {
			ret = (enum eDisplay)(i+1);
		}
	}

	return ret;
}

static char *basename(char * path)
{
	char *lslash = path;
	char *p = path;
	while (*p != '\0') {
		if (*p == '/') lslash = p;
		p++;
	}

	return (lslash+1);
}

static void usage(char *prog)
{
	printf("Usage: %s [-h] [-v] [-f <format>] [time_of_day timestamp]\n", prog);
	printf("\n");
	printf("  -h           print this help and exit\n");
	printf("  -v           print version and exit\n");
	printf("  -f <format>  choose output format (normal, lsb_octets, msb_octets)\n");
	printf("\n");
	printf("If TIME_OF_DAY timestamp (in normal display with 0x-prefix) is given the time field is parsed an printed.\nThe output format is ignored.\n");
}

int main(int argc, char *argv[])
{
	enum eDisplay disp = DISP_NONE;
	const char *optstring = "hvf:";
	int ch = 0;

	while ((ch = getopt(argc, argv, optstring)) != -1) {
		switch (ch) {
		case 'h':
			usage(basename(argv[0]));
			return 0;

		case 'v':
			printf("vNIL\n");
			return 0;

		case 'f':
			disp = get_format(optarg);
			break;

		default:
			fprintf(stderr, "Invalid option.\n");
			return 1;
		}
	}

	argc -= optind;
	if (argc > 0) {
		argv += optind;
		reverse_print_time(argc, argv);
		return 0;
	}


	return calc_time_of_day(disp);
}
