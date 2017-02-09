/*
 * deviceconfig.c
 *
 * Read device configuration for the SDO transfers from CSV file.
 *
 * Frank Jeschke <fjeschke@synapticon.com>
 *
 * 2017 Synapticon GmbH
 */

#include "deviceconfig.h"

#include <stdio.h>
#include <string.h>

#define MAX_INPUT_LINE    1024

static void dc_tokenize_inbuf(char *buf, size_t size, char **token)
{
	static int line = 0;
	//printf("[DEBUG] parse(l = %lu): '%s'\n", size, buf);

	char *sep = ",";
	char *b = malloc(size * sizeof(char));
	char *word = NULL;

	memmove(b, buf, size * sizeof(char));
	printf("[DEBUG line %d] ", line);
	for (word = strtok(b, sep);  word; word = strtok(NULL, sep)) {
		printf("tok-'%s', ", word);
	}
	printf("\n");

	free(b);
	line++;
}

static void dc_parse_tokens(char **token, SdoParam_t **params)
{
	(void)token;
	(void)params;
}

int dc_read_file(const char *path, SdoParam_t **params)
{
	FILE *f = fopen(path, "r");
	if (f == NULL) {
		return -1;
	}

	char **tokens;
	size_t tokencount = 0;

	char inbuf[MAX_INPUT_LINE];
	size_t inbuf_length = 0;
	int c;
	while ((c = fgetc(f)) != EOF) {
		if (c == '#') {
			while (c != '\n') {
				c = fgetc(f);
			}
		}

		if (c == '\n') {
			if (inbuf_length > 1) {
				inbuf[inbuf_length++] = '\0';
				dc_tokenize_inbuf(inbuf, inbuf_length, tokens, &token_count);
				dc_parse_tokens(tokens, params);
			}

			inbuf_length = 0;
			continue;
		}

		if (c == ' ' || c == '\t') /* filter whitespaces - FIXME attention if strings are supported! */
			continue;

		inbuf[inbuf_length] = (char)c;
		inbuf_length++;
	}

	if (feof(f)) {
		return 0;
	}
	
	return -1;
}
