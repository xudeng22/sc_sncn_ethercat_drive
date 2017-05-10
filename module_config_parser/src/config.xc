/*
 * readsdoconfig.c
 *
 * Read device configuration for the SDO transfers from CSV file.
 *
 * Frank Jeschke <fjeschke@synapticon.com>
 *
 * 2017 Synapticon GmbH
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <safestring.h>
#include <syscall.h>
#include <xccompat.h>
#include <flash_service.h>
#include <spiffs_service.h>
#include <sdoconfig.h>



struct _token_t {
  size_t count;
  char token[MAX_NODES_COUNT][MAX_TOKEN_SIZE];
};



static size_t get_token_count(char *buf, size_t bufsize)
{
  size_t separator = 0;
  char *c = buf;

  for (size_t i = 0; i < bufsize && *c != '\0'; i++, c++) {
    if (*c == ',') {
      separator++;
    }
  }

  return (separator + 1);
}



static void tokenize_inbuf(char *buf, size_t bufsize, struct _token_t *token)
{
  char sep = ',';
  int tok_pos, last_tok_pos = 0;

  size_t tokenitem = 0;
  token->count = get_token_count(buf, bufsize);

  while ((tok_pos = safestrchr(buf + last_tok_pos, sep)) > 0) {
    strncpy((token->token[tokenitem]), buf + last_tok_pos, tok_pos);
    token->token[tokenitem][tok_pos] = '\0';
    last_tok_pos += tok_pos + 1;
    tokenitem++;
  }

  strncpy((token->token[tokenitem]), buf + last_tok_pos, sizeof(buf + last_tok_pos));
  token->token[tokenitem][sizeof(buf + last_tok_pos)] = '\0';
}



static long parse_token(char *token_str)
{
  long value = strtol(token_str, NULL, 0);

  return value;
}

static void parse_token_for_node(struct _token_t *tokens, SdoParam_t *param,
                                 size_t node)
{
  param->index    = (uint16_t) parse_token(tokens->token[0]);
  param->subindex = (uint8_t)  parse_token(tokens->token[1]);
  param->value    = (uint32_t) parse_token(tokens->token[2 + node]);
}

int read_sdo_config(char path[], SdoConfigParameter_t *parameter, client SPIFFSInterface i_spiffs)
{

  int retval = 0;
  if (parameter == NULL) {
    return -1;
  }

  int cfd = i_spiffs.open_file(path, strlen(path), SPIFFS_RDONLY);
  if ((cfd < 0)||(cfd > 255)) {
    return -1;
  }

  struct _token_t t[120];
  size_t param_count = 0;

  char inbuf[MAX_INPUT_LINE];
  size_t inbuf_length = 0;
  char c[1];

  /* read file and tokenize */

  while ((retval = i_spiffs.read(cfd, c, 1)) > 0) {
    if (c[0] == '#') {
      while (c[0] != '\n') {
         retval = i_spiffs.read(cfd, c, 1);
         if ( retval < 0)
             return retval;
      }
    }

    if (c[0] == '\n') {
      if (inbuf_length > 1) {
        inbuf[inbuf_length++] = '\0';
        tokenize_inbuf(inbuf, inbuf_length, &t[param_count]);
        param_count++;
      }

      inbuf_length = 0;
      continue;
    }

    if (c[0] == ' ' ||
        c[0] == '\t') {
      continue;
    }

    inbuf[inbuf_length] = (char)c[0];
    inbuf_length++;
  }

  if ((retval < 0)&&(retval != SPIFFS_EOF))
      return retval;

  retval = i_spiffs.close_file(cfd);
  if ( retval < 0) {
    return retval;
  }


  parameter->param_count = param_count;
  parameter->node_count  = t->count - 2;
  if (parameter->node_count == 0 || parameter->param_count == 0) {
    return -1;
  }


  for (size_t node = 0; node < parameter->node_count; node++) {
    for (size_t param = 0; param < parameter->param_count; param++) {
      parse_token_for_node(&t[param], &parameter->parameter[param][node], node);

    }
  }

  return retval;
}




int write_sdo_config(char path[], SdoConfigParameter_t *parameter, client SPIFFSInterface i_spiffs)
{

  int retval = 0;
  if (parameter == NULL) {
    return -1;
  }

  char line_buf[255];
  int cfd = i_spiffs.open_file(path, strlen(path), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
  if ((cfd < 0)||(cfd > 255)) {
    return -1;
  }


  /*sprintf(line_buf, "#index, subindex,   ");
  for (size_t node = 0; node < parameter->node_count; node++) {
           sprintf(line_buf + strlen(line_buf), "axis %d,       ", node);
   }
   line_buf[strlen(line_buf)]='\n';

   retval = i_spiffs.write(cfd, line_buf, strlen(line_buf));*/

   for (size_t param = 0; param < parameter->param_count; param++) {
          uint16_t index = parameter->parameter[param][0].index;
          uint8_t subindex = parameter->parameter[param][0].subindex;
          uint32_t value = parameter->parameter[param][0].value;

          //memset(line_buf, NULL, sizeof(line_buf));
          sprintf(line_buf, "0x%x,  %3d", index, subindex, value);

          for (size_t node = 0; node < parameter->node_count; node++) {
              uint32_t value = parameter->parameter[param][node].value;
              sprintf(line_buf + strlen(line_buf), ", %12d", value);
          }
          line_buf[strlen(line_buf)]='\n';

          retval = i_spiffs.write(cfd, line_buf, strlen(line_buf));
          if (retval < 0)
              return retval;

  }


  retval = i_spiffs.close_file(cfd);
  if ( retval < 0) {
    return retval;
  }


  return retval;
}

