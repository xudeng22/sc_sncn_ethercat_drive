
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <flash_service.h>
#include <spiffs_service.h>
#include <command_processor.h>
//#include <config_parser.h>
#include <syscall.h>

#define BUFFER_SIZE 1024


void spiffs_console(client SPIFFSInterface i_spiffs)
{
    //ConfigParameter_t Config;

    unsigned char buf[BUFFER_SIZE];
    char par1[MAX_FILENAME_SIZE], par2[MAX_FILENAME_SIZE], par3[MAX_FILENAME_SIZE];
    int par_num, res;
    unsigned short fd = 0;
    unsigned short flags = 0;

    select {
        case i_spiffs.service_ready():

            printf(">>   COMMAND SERVICE STARTING...\n");

            while(1)
            {
            printf(">");
            gets(buf);
            par_num = sscanf(buf, "%s %s %s", par1, par2, par3);
            if (par_num > 0)
            {
                if (strcmp(par1, "open") == 0)
                {
                    if (par_num > 2)
                    {
                        if (strcmp(par3, "rw") == 0)
                            flags = SPIFFS_RDWR;
                    else
                        if (strcmp(par3, "ro") == 0)
                            flags = SPIFFS_RDONLY;
                        else
                        if (strcmp(par3, "wo") == 0)
                            flags = SPIFFS_WRONLY;
                        else
                            if (strcmp(par3, "c") == 0)
                            flags = (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR);
                        else
                        {
                            flags = 0;
                            printf("Unknown parameter \n");
                        }

                        if (flags)
                        {
                            fd  = i_spiffs.open_file(par2, strlen(par2), flags);
                            if ((fd > 0)&&(fd < 255)) printf("File opened with file descriptor %i\n", fd);
                            else
                                printf("Error opening file \n");
                        }
                    }
                    else
                        printf("Missing parameter \n");
                }
                else
                if (strcmp(par1, "close") == 0)
                {
                     res = i_spiffs.close_file(fd);
                     if (res < 0) printf("errno %i\n", res);
                     else
                         printf("Success... \n");
                }
                else
                if (strcmp(par1, "write") == 0)
                {
                    if (par_num > 1)
                    {
                        memset(buf, 0 , sizeof(buf));
                        res = i_spiffs.write(fd, (unsigned char *)par2, strlen(par2) + 1);
                        if (res < 0) printf("errno %i\n", res);
                        else
                            printf("Writed: %i\n", res);
                    }
                    else
                        printf("Missing parameter \n");

                }
                else
                if (strcmp(par1, "read") == 0)
                {
                    if (par_num > 1)
                    {
                         memset(buf, 0 , sizeof(buf));
                         res = i_spiffs.read(fd, (unsigned char *)buf, atoi(par2));
                         if (res < 0) printf("Error\n");
                         else
                             printf("Readed: %i b\n %s \n",res, buf);
                    }
                    else
                        printf("Missing parameter \n");

                }
                else
                if (strcmp(par1, "fwrite") == 0)
                {
                    if (par_num > 1)
                    {
                        fd  = i_spiffs.open_file(par2, strlen(par2), (SPIFFS_CREAT | SPIFFS_TRUNC | SPIFFS_RDWR));
                        if ((fd < 0)&&(fd > 255))
                        {
                            printf("Error\n");
                            continue;
                        }
                        else
                            printf("File opened with file descriptor %i\n", fd);

                        int cfd = _open(par2, O_RDONLY, 0);
                        if (cfd == -1)
                        {
                            printf("Error\n");
                            continue;
                        }

                        printf("Writing...\n");
                        int fread_size = 1;
                        while (fread_size > 0)
                        {
                            memset(buf, 0 , sizeof(buf));
                            fread_size = _read(cfd, buf, BUFFER_SIZE);
                            res = i_spiffs.write(fd, buf, fread_size);
                            if (res < 0)
                            {
                                printf("errno %i\n", res);
                                continue;
                            }
                        }

                        if (_close(cfd) != 0)
                        {
                            printf("Error\n");
                            continue;
                        }

                        res = i_spiffs.close_file(fd);
                        if (res < 0) printf("errno %i\n", res);
                        else
                          printf("Success...\n");
                    }
                    else
                        printf("Missing param \n");

                }
                else
                if (strcmp(par1, "fread") == 0)
                {
                    if (par_num > 1)
                    {
                        unsigned short obj_id;
                        unsigned int size;
                        unsigned char type;
                        unsigned short pix;
                        unsigned char name[MAX_FILENAME_SIZE];

                        fd  = i_spiffs.open_file(par2, strlen(par2), SPIFFS_RDONLY);
                        if ((fd < 0)&&(fd > 255))
                        {
                            printf("Error\n");
                            continue;
                        }

                        int cfd = _open(par2, O_WRONLY | O_CREAT | O_TRUNC, S_IREAD | S_IWRITE);
                        if (cfd == -1)
                        {
                             printf("Error\n");
                             continue;
                        }

                        memset(buf, 0 , sizeof(buf));
                        res = i_spiffs.status(fd, obj_id, size, type, pix, name);
                        if (res < 0)
                        {
                            printf("errno %i\n", res);
                            continue;
                        }

                        printf("Reading...\n");
                        for (int il = size; il > 0; il = il - BUFFER_SIZE)
                        {
                            int read_len = (il > BUFFER_SIZE ? BUFFER_SIZE : il);
                            res = i_spiffs.read(fd, buf, read_len);
                            if (res < 0)
                            {
                                printf("Error\n");
                                continue;
                            }

                            int fwrite_size = _write(cfd, buf, read_len);
                        }

                        if (_close(cfd) != 0)
                        {
                            printf("Error\n");
                            continue;
                        }

                        res = i_spiffs.close_file(fd);
                        if (res < 0) printf("errno %i\n", res);
                        else
                           printf("Success...\n");
                    }
                    else
                        printf("Missing paramn");

                }
                /*else
                if (strcmp(par1, "confdown") == 0)
                {
                    if (par_num > 1)
                    {
                        printf("Parsing... \n");
                        if (read_config(par2, &Config, i_spiffs) >= 0)
                            printf("Success... \n");
                        else
                            printf("Error... \n");

                    }
                    else
                        printf("Missing param\n");
                }
                else
                if (strcmp(par1, "confup") == 0)
                {
                    if (par_num > 1)
                    {
                        printf("Generating... \n");
                        if (write_config(par2, &Config, i_spiffs) >= 0)
                            printf("Success... \n");
                        else
                            printf("Error... \n");
                    }
                    else
                        printf("Missing param\n");
                }*/
                else
                if (strcmp(par1, "remove") == 0)
                {
                      res = i_spiffs.remove_file(fd);
                      if (res < 0) printf("errno %i\n", res);
                      else
                          printf("Success... \n");
                }
                else
                if (strcmp(par1, "stat") == 0)
                {
                    unsigned short obj_id;
                    unsigned int size;
                    unsigned char type;
                    unsigned short pix;
                    char name[MAX_FILENAME_SIZE];
                    res = i_spiffs.status(fd, obj_id, size, type, pix, name);
                    if (res < 0) printf("errno %i\n", res);
                    else
                      printf("Object ID: %04x\nSize: %u\npix: %i\nName: %s\n", obj_id, size, pix, name);

                  }
                  else
                  if (strcmp(par1, "rename") == 0)
                  {
                      if (par_num > 2)
                      {
                           res  = i_spiffs.rename_file(par2, strlen(par2), par3, strlen(par3));
                           if (res < 0) printf("errno %i\n", res);
                           else
                               printf("Success... \n");

                       }
                       else
                           printf("Missing parameter \n");
                  }
                  else
                  if (strcmp(par1, "format") == 0)
                  {
                      printf("Formatting... \n");
                      res = i_spiffs.format();
                      if (res < 0) printf("errno %i\n", res);
                      else
                          printf("Success... \n");
                  }
                  else
                  if (strcmp(par1, "vis") == 0)
                  {
                      res = i_spiffs.vis();
                      if (res < 0) printf("errno %i\n", res);
                      else
                          printf("Success... \n");
                  }
                  else
                  if (strcmp(par1, "ls") == 0)
                  {
                      printf("Scanning file system... \n");
                      res = i_spiffs.ls();
                      if (res < 0) printf("errno %i\n", res);
                      else
                          printf("Success... \n");
                  }
                  else
                  if (strcmp(par1, "check") == 0)
                  {
                      printf("Checking... \n");
                      res = i_spiffs.check();
                      if (res < 0) printf("errno %i\n", res);
                      else
                          printf("Success... \n");
                  }
                  else
                  if (strcmp(par1, "unmount") == 0)
                  {
                      i_spiffs.unmount();
                      printf("Unmounted... \n");
                  }
                  else
                  if (strcmp(par1, "seek") == 0)
                  {
                      if (par_num > 2)
                      {
                          if (strcmp(par3, "set") == 0)
                              flags = SPIFFS_SEEK_SET;
                          else
                          if (strcmp(par3, "cur") == 0)
                              flags = SPIFFS_SEEK_CUR;
                          else
                          if (strcmp(par3, "end") == 0)
                              flags = SPIFFS_SEEK_END;
                          else
                          {
                              flags = 3;
                              printf("Missing parameter \n");
                          }
                          if (flags < 3)
                          {
                              res = i_spiffs.seek(fd, atoi(par2), flags);
                              if (res < 0) printf("errno %i\n", res);
                              else
                                  printf("Success... \n");
                          }
                       }
                   }
                   else
                   if (strcmp(par1, "tell") == 0)
                   {
                       res = i_spiffs.tell(fd);
                       if (res < 0) printf("errno %i\n", res);
                       else
                           printf("-> %i\n", res);
                   }
                   else
                   if (strcmp(par1, "set") == 0)
                   {
                       if (par_num > 1)
                       {
                           fd = atoi(par2);
                           printf("File descriptor: %i\n", fd);
                       }
                       else
                           printf("Missing parameter \n");

                   }
                   else
                   if (strcmp(par1, "info") == 0)
                   {
                       unsigned int total, used;
                       res = i_spiffs.fs_info(total, used);
                       if (res < 0) printf("errno %i\n", res);
                       else
                           printf("Total: %i, Used: %i\n", total, used);
                   }
                   else
                   if (strcmp(par1, "errno") == 0)
                   {
                       res = i_spiffs.errno();
                       if (res < 0) printf("errno %i\n", res);
                       else
                          printf("No errors\n");
                    }
                   else
                   if (strcmp(par1, "flush") == 0)
                   {
                       res = i_spiffs.flush(fd);
                       if (res < 0) printf("errno %i\n", res);
                       else
                           printf("Success... \n", res);
                    }
                    else
                    if (strcmp(par1, "gc") == 0)
                    {
                        if (par_num > 1)
                        {
                            res = i_spiffs.gc(atoi(par2));
                            if (res < 0) printf("errno %i\n", res);
                            else
                                printf("Success... \n", res);
                         }
                         else
                             printf("Missing parameter \n");
                    }
                    else
                    if (strcmp(par1, "gcq") == 0)
                    {
                        if (par_num > 1)
                        {
                            res = i_spiffs.gc_quick(atoi(par2));
                            if (res < 0) printf("errno %i\n", res);
                            else
                                printf("Success... \n", res);
                         }
                         else
                             printf("Missing parameter \n");
                    }
                    else
                      printf("Unknown command \n");
            }
        }
    break;
    }


}
