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

struct _token_t {
	char **token;
	size_t count;
};

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

static void dc_tokenize_inbuf(char *buf, size_t bufsize, struct _token_t *token)
{
	char *sep = ",";
	char *b = malloc(bufsize * sizeof(char));
	char *word = NULL;

	size_t tokenitem = 0;
	token->count = get_token_count(buf, bufsize);
	token->token = malloc(token->count * sizeof(char *));

	memmove(b, buf, bufsize * sizeof(char));

	for (word = strtok(b, sep);  word; word = strtok(NULL, sep)) {
		*(token->token + tokenitem) = malloc(strlen(word) + 1);
		strncpy(*(token->token + tokenitem), word, (strlen(word) + 1));
		tokenitem++;
	}

	free(b);
}

static void dc_parse_tokens(struct _token_t *token, SdoParam_t **params)
{
	(void)params;

	printf("[DEBUG tokens] ");
	for (size_t i = 0; i < token->count; i++) {
		printf("'%s', ", *(token->token + i));
	}
	printf("\n");
}

int dc_read_file(const char *path, SdoParam_t **params)
{
	FILE *f = fopen(path, "r");
	if (f == NULL) {
		return -1;
	}

	struct _token_t token;
	token.token = NULL;
	token.count = 0;

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
				dc_tokenize_inbuf(inbuf, inbuf_length, &token);
				dc_parse_tokens(&token, params);

				/* FIXME find out why this free's don't work */
				for (size_t k = 0; k < token.count; k++) {
					//free(*(token.token + k));
					//free(token.token);
				}
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
