#include "deviceconfig.h"

#include <stdio.h>

int main(int argc, char *argv[])
{
  if (argc < 2) {
    printf("Usage: %s <filename>\n", argv[0]);
    return -1;
  }

  SdoConfigParameter_t config_parameter = { 0, 0, NULL };

  if (dc_read_file(argv[1], &config_parameter) != 0) {
    fprintf(stderr, "Error parsing file\n");
    return -1;
  }

  printf("Node Count = %lu; Parameter Count = %lu\n",
         config_parameter.node_count, config_parameter.param_count);

  SdoParam_t **paramlist = config_parameter.parameter;
  if (paramlist == NULL) {
    fprintf(stderr, "Error list of parameter per nodes is empty\n");
    return -1;
  }

  for (size_t i = 0; i < config_parameter.node_count; i++) {
    SdoParam_t *nparam = *paramlist + i;
    if (nparam == NULL) {
      fprintf(stderr, "Error parameter list of node is empty\n");
      return -1;
    }

    for (size_t k = 0; k < config_parameter.param_count; k++) {
      SdoParam_t *p = nparam + k;

      printf("N%zu: 0x%04x:%d = %d\n",
             i, p->index, p->subindex, p->value);
    }
  }

  return 0;
}
