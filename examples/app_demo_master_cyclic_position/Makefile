# Makefile for app_demo_master_cyclic_position_handling

CC = gcc
LD = gcc
MKDIR = mkdir
RM = rm -f
RMDIR = rm -f -r

CFLAGS = -g -Wall -Wextra  -O0 -std=c99 -static
LDFLAGS = -static

#
# Include and Library paths
#

# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

ETHERCAT_DRIVE_PATH := ../../.
MOTORCONTROL_PATH := ../../.
MOTORCONTROL_LIB_PATH := ../../.

ifneq (,$(wildcard ../../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../../sc_sncn_motorcontrol
endif

ifneq (,$(wildcard ../../../sc_sncn_motorcontrol_new/.))
	MOTORCONTROL_LIB_PATH := ../../../sc_sncn_motorcontrol_new
endif

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib
LIB_DIRS += -L $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto/lib
LIB_DIRS += -L $(ETHERCAT_DRIVE_PATH)/lib_linux_motor_drive/lib


LIBS += -lsncn_ctrlproto -lsncn_motor_drive
LIBS += -lethercat -lm

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I ../config_motor_master

INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/inc_ctrlproto-common
INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto/include
INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/lib_linux_motor_drive/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_pwm_symmetrical/src/common
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_rem_16mt/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/biss_configs
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_position_feedback/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_rem_14/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_gpio/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_bldc_torque_control_lib/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_misc/include

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


#
# Targets and Objects
#

TARGET = app_demo_master_cyclic_position
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

prerequisite: prerequisite_controlproto prerequisite_motorcontrol
	$(MKDIR) -p $(BUILD_DIR) $(OUT_DIR)

prerequisite_controlproto:
	$(MAKE) -C $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto

prerequisite_motorcontrol:
	$(MAKE) -C $(ETHERCAT_DRIVE_PATH)/lib_linux_motor_drive

clean:
	$(RM) $(BUILD_DIR)/*.o $(OUT_DIR)/$(TARGET)
	$(RMDIR) $(OUT_DIR) $(BUILD_DIR)
