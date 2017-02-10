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
	struct _token_t *next;
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

static void free_token(struct _token_t *t)
{
	if (t->next == NULL) {
		free(t);
	} else {
		free_token(t->next);
	}
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

static unsigned parse_token(char *token_str)
{
	unsigned value = 0;

	printf("[DEBUG] Input: '%s'\n", token_str);
	if (strncmp(token_str, "0x", 2) >= 0) {
		sscanf(token_str, "0x%x", (int *)&value);
	} else {
		sscanf(token_str, "%u", &value);
	}

	printf("[DEBUG] Output: 0x%02x\n", value);

	return value;
}

static void dc_parse_tokens(struct _token_t *token, SdoParam_t **params)
{
	uint16_t index    = (uint16_t)parse_token(*(token->token + 0));
	uint8_t  subindex = (uint8_t)parse_token(*(token->token + 1));

	for (size_t k = 0; k < (token->count - 2); k++) {
		SdoParam_t *p = /*malloc(sizeof(SdoParam_t)); */ *(params + k); /* FIXME allocate the params memory! */
		p->index = index;
		p->subindex = subindex;
		p->value = (uint32_t)parse_token(*(token->token + k + 2));

		printf("I: 0x%04x:%d - bitsize: %lu\n", p->index, p->subindex, p->bytecount);
	}

	printf("[DEBUG tokens] ");
	for (size_t i = 0; i < token->count; i++) {
		printf("'%s', ", *(token->token + i));
	}
	printf("\n");
}

int dc_read_file(const char *path, SdoConfigParameter_t *parameter)
{
	if (parameter == NULL)
		return -1;

	FILE *f = fopen(path, "r");
	if (f == NULL) {
		return -1;
	}

	struct _token_t *token = malloc(sizeof(struct _token_t));
	token->token = NULL;
	token->count = 0;
	token->next  = NULL;

	struct _token_t *t = token;
	size_t token_count = 0;

	SdoParam_t **paramlist = NULL;

	char inbuf[MAX_INPUT_LINE];
	size_t inbuf_length = 0;
	int c;

	/* read file and tokenize */
	while ((c = fgetc(f)) != EOF) {
		if (c == '#') {
			while (c != '\n') {
				c = fgetc(f);
			}
		}

		if (c == '\n') {
			if (inbuf_length > 1) {
				inbuf[inbuf_length++] = '\0';
				dc_tokenize_inbuf(inbuf, inbuf_length, t);
				token_count++;
				t->next = calloc(1, sizeof(struct _token_t));
				if (t->next != NULL)
					t = t->next;

				//dc_parse_tokens(token, parameter->parameter);

			}

			inbuf_length = 0;
			continue;
		}

		if (c == ' ' || c == '\t') /* filter whitespaces - FIXME attention if strings are supported! */
			continue;

		inbuf[inbuf_length] = (char)c;
		inbuf_length++;
	}

	int retval = -1;
	if (feof(f)) {
		retval = 0;
	}

	free_token(token);

	return retval;
}
