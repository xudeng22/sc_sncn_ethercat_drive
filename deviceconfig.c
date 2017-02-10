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

static uint16_t parse_index(char *index_str)
{
	uint16_t value = 0;
	printf("[DEBUG] Input: '%s'\n", index_str);
	if (strncmp(index_str, "0x", 2) >= 0) {
		sscanf(index_str, "0x%hx", &value);
	} else {
		sscanf(index_str, "%hd", &value);
	}

	printf("[DEBUG] Output: 0x%04x\n", value);

	return value;
}

static uint16_t parse_subindex(char *index_str)
{
	uint8_t value = 0;
	printf("[DEBUG] Input: '%s'\n", index_str);
	if (strncmp(index_str, "0x", 2) >= 0) {
		sscanf(index_str, "0x%x", (int *)&value);
	} else {
		sscanf(index_str, "%d", (int *)&value);
	}

	printf("[DEBUG] Output: 0x%02x\n", value);

	return value;
}

static size_t parse_value(char *value_str)
{
	return 0;
}

static void dc_parse_tokens(struct _token_t *token, SdoParam_t **params)
{
	(void)params;

	uint16_t index    = parse_index(*(token->token + 0));
	uint8_t  subindex = parse_subindex(*(token->token + 1));

	for (size_t k = 0; k < (token->count - 2); k++) {
		SdoParam_t *p = /*malloc(sizeof(SdoParam_t)); */ *(params + k); /* FIXME allocate the params memory! */
		p->index = index;
		p->subindex = subindex;
		p->bytecount = parse_value(*(token->token + k + 2));

		printf("I: 0x%04x:%d - bitsize: %lu\n", p->index, p->subindex, p->bytecount);
	}

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
