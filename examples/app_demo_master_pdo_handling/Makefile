# Makefile for app_demo_master_pdo_handling
#
# 2016-03-15 Synapticon GmbH

CC = gcc
LD = gcc
MKDIR = mkdir
RM = rm -f
RMDIR = rm -f -d

CFLAGS = -g -Wall -Wextra  -O0 -std=c99 -static
LDFLAGS = -static

#
# Include and Library paths
#

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib

LIBS += -lethercat_wrapper -lethercat -lm

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include

#
# Check for Linux machine
#
UNAME := $(shell uname)

ifneq ($(UNAME),Linux)
  $(error This software only runs on Linux.)
endif

#
# Directories
#

SOURCE_DIRS = src
BUILD_DIR = build
OUT_DIR = bin

ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab
# Installation directory of the  EtherCAT Master by IgH EtherLAB
ifeq (,$(wildcard /opt/etherlab))
  $(error Directory /opt/etherlab does not exist, please check your EtherLAB installation and fix the path)
endif

#
# Targets and Objects
#

TARGET = app_demo_master_pdo_handling
OBJECTS = main.o

#
# Implicit Target
#

$(BUILD_DIR)/%.o: $(SOURCE_DIRS)/%.c
	$(CC) $(CFLAGS) $(INCLUDE_DIRS) -c -o $@ $^

#
# Target
#

all: prerequisite $(TARGET)

$(TARGET): $(BUILD_DIR)/main.o
	$(LD) $(LDFLAGS) -o $(OUT_DIR)/$@ $^ $(LIB_DIRS) $(LIBS)
	@echo "Build finished: $(OUTDIR)/$(TARGET)"

.PHONY: clean prerequisite justpreprocess

justpreprocess:
	$(CC) $(CFLAGS) $(INCLUDE_DIRS) -E -o main.preproc.c $(SOURCE_DIRS)/main.c

prerequisite:
	$(MKDIR) -p $(BUILD_DIR) $(OUT_DIR)

clean:
	$(RM) $(BUILD_DIR)/*.o $(OUT_DIR)/$(TARGET)
	$(RMDIR) $(OUT_DIR) $(BUILD_DIR)
