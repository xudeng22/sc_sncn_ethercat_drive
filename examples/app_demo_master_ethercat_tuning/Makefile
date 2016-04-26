#FLAGS = -static
FLAGS += -std=c99

LIBS += -lsncn_ctrlproto
LIBS += -lethercat -lm
LIBS_D += -lncurses

SOURCE_DIRS = src

# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

ETHERCAT_DRIVE_PATH := ../../.
MOTORCONTROL_PATH := ../../.

ifneq (,$(wildcard ../../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../../sc_sncn_motorcontrol
endif

INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/inc_ctrlproto-common
INCLUDE_DIRS += -I $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_ams_rotary_sensor/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_gpio/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_misc/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_pwm_symmetrical/src/common
INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I ../config_motor_master

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib
LIB_DIRS += -L ../../lib_linux_ctrlproto/lib
LIB_DIRS += -L/usr/lib

# Needed for checking if Linux machine
UNAME := $(shell uname)

all:
		@echo Bulding dependency: lib_linux_ctrlproto...
		@cd $(ETHERCAT_DRIVE_PATH)/lib_linux_ctrlproto; make
		@echo 
		@echo Bulding application $(notdir $(shell pwd))
ifneq "$(UNAME)" "Linux"
		@echo "------------------------------------------------------------------------------------------------------"
		@echo "||Your System isn't Linux, so the Master Application for the Linux EtherCAT Master can not be built.||"
		@echo "------------------------------------------------------------------------------------------------------"
else
		@if test -d $(ETHERCAT_MASTER_INSTALLDIR); \
		then \
		mkdir bin -p;\
		gcc -o bin/$(notdir $(shell pwd)) src/main.c -Wl,-Bstatic $(LIBS) $(INCLUDE_DIRS) $(LIB_DIRS) $(FLAGS) -Wl,-Bdynamic $(LIBS_D) $(FLAGS) ; \
		else echo \
		"\n\
		-----------------------------------------------------------------------------------------------------------------\n\
		||EtherCAT Master is not installed at given directory if you installed it elsewhere change location in Makefile||\n\
		-----------------------------------------------------------------------------------------------------------------\n";\
		fi
endif

##Add clean Master Application
clean: masterAppClean
masterAppClean:
	rm -r bin/
