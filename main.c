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

    return 0;
}
