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
LIB_DIRS += -L ../../lib_linux_ctrlproto/lib

LIBS += -lsncn_ctrlproto
LIBS += -lethercat -lm

INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/inc_ctrlproto-common
INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_gpio/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_misc/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_pwm_symmetrical/src/common
INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I ../config_motor_master

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

ETHERCAT_DRIVE_PATH := ../../.
MOTORCONTROL_PATH := ../../.

ifneq (,$(wildcard ../../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../../sc_sncn_motorcontrol
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
	$(MAKE) -C $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto

clean:
	$(RM) $(BUILD_DIR)/*.o $(OUT_DIR)/$(TARGET)
	$(RMDIR) $(OUT_DIR) $(BUILD_DIR)
