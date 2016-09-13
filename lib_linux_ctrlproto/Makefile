# Makefile for libsncn shared and static libraries
#
# 2016-03-16 Synapticon GmbH

#
# Common compiler settings
#

CC = gcc
LD = gcc
AR = ar
RM = rm
INSTALL = install

CFLAGS = -g -Wall -Wextra  -O0
LDFLAGS = -g
ARFLAGS =

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib
LIBS += -lethercat -lm -lstdc++ 

#
# Necessary paths
#

# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab
ETHERCAT_PATH := ..
MOTORCONTROL_PATH := ..
MOTORCONTROL_LIB_PATH := ..

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I include
INCLUDE_DIRS += -I ../inc_ctrlproto-common/
INCLUDE_DIRS += -I ../examples/config_motor_master
INCLUDE_DIRS += -I $(ETHERCAT_PATH)/module_ethercat/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_pwm_symmetrical/src/common
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_ams_rotary_sensor/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_gpio/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_advanced_torquecontrol_lib/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_misc/include

#
# Check if this is a Linux machine
#

UNAME := $(shell uname)
ifneq "$(UNAME)" "Linux"
  $(error Your System is not Linux, so the ctrlproto libary for the Linux EtherCAT Master can not be built!)
endif

#
# Special defines for compile options
#

TIME_MEASUREMENT = 0

CFLAGS += -DMAKE_TIME_MEASUREMENT=$(TIME_MEASUREMENT)

ifeq (,$(wildcard $(ETHERCAT_MASTER_INSTALLDIR)))
  $(error Master is not installed at given directory if you installed it elsewhere change location in Makefile.)
endif

ifneq (,$(wildcard ../../sc_sncn_ethercat/.))
	ETHERCAT_PATH := ../../sc_sncn_ethercat
endif

ifneq (,$(wildcard ../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../sc_sncn_motorcontrol
endif

ifneq (,$(wildcard ../../sc_sncn_motorcontrol_new/.))
	MOTORCONTROL_LIB_PATH := ../../sc_sncn_motorcontrol_new
endif

OUTDIR ?= ./lib
TARGET_DIR = /opt/synapticon/lib

#
# prototype to compile object files
#

src/%.o: src/%.c
	$(CC) $(CFLAGS) $(INCLUDE_DIRS) -c -o $@ $^

src/%.s.o: src/%.c
	$(CC) $(CFLAGS) -fPIC $(INCLUDE_DIRS) -c -o $@ $^

# Phony targets
.PHONY: clean install uninstall

# build rules

all: prerequisite libsncn_ctrlproto.so libsncn_ctrlproto.a

prerequisite:
	@mkdir -p $(OUTDIR)

libsncn_ctrlproto.so: src/ctrlproto_m.s.o
	$(LD) $(LDFLGAGS) -shared -o $(OUTDIR)/$@ $^ $(LIB_DIRS) $(LIB)

libsncn_ctrlproto.a: src/ctrlproto_m.o
	$(AR) rcs $(OUTDIR)/$@ $^

# simple lib installation, use -L to reference to $(TARGET_DIR)
install:
	#$(INSTALL) -D $(OUTDIR)/libsncn_ctrlproto.so $(TARGET_DIR)
	$(INSTALL) -D $(OUTDIR)/libsncn_ctrlproto.a $(TARGET_DIR)

uninstall:
	$(RM) -f $(TARGET_DIR)/libsncn_ctrlproto.a
	$(RM) -f $(TARGET_DIR)/libsncn_ctrlproto.so

clean:
	$(RM) -f $(OUTDIR)/*.so $(OUTDIR)/*.a src/*.o
	$(RM) -f -d $(OUTDIR)
