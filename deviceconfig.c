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
#define MAX_TOKEN_SIZE    255

static size_t get_token_count(char *buf, size_t bufsize)
{
	size_t separator = 0;
	char *c = buf;

	for (size_t i = 0; i < bufsize && *c != '\0'; i++, c++) {
		if (*c == ',')
			separator++;
	}

	return (separator + 1);
}

static void dc_tokenize_inbuf(char *buf, size_t bufsize, char **token, size_t *token_count)
{
	char *sep = ",";
	char *b = malloc(bufsize * sizeof(char));
	char *word = NULL;

	size_t tokenitem = 0;
	*token_count = get_token_count(buf, bufsize);
	token = malloc(*token_count);

	memmove(b, buf, bufsize * sizeof(char));

	for (word = strtok(b, sep);  word; word = strtok(NULL, sep)) {
		*(token + tokenitem) = malloc(strlen(word) + 1);
		strncpy(*(token + tokenitem), word, strlen(word));
		tokenitem++;
	}


	free(b);
}

static void dc_parse_tokens(char **token, size_t token_count, SdoParam_t **params)
{
	(void)params;

	printf("[DEBUG tokens] ");
	for (size_t i = 0; i < token_count; i++) {
		printf("'%s', ", *(token + i));
	}
	printf("\n");
}

int dc_read_file(const char *path, SdoParam_t **params)
{
	FILE *f = fopen(path, "r");
	if (f == NULL) {
		return -1;
	}

	char **token = NULL;
	size_t token_count = 0;

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
				dc_tokenize_inbuf(inbuf, inbuf_length, token, &token_count);
				dc_parse_tokens(token, token_count, params);
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
