FLAGS = -static
FLAGS += -std=c99

LIBS += -lsncn_ctrlproto
LIBS += -lethercat -lm

SOURCE_DIRS = src

# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

CTRL_PROTO_PATH := ..
MOTORCONTROL_PATH := ..

ifneq (,$(wildcard ../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../sc_sncn_motorcontrol
endif

ifneq (,$(wildcard ../../sc_sncn_ctrlproto/.)) 
	CTRL_PROTO_PATH := ../../sc_sncn_ctrlproto
endif

INCLUDE_DIRS += -I $(CTRL_PROTO_PATH)/inc_ctrlproto-common
INCLUDE_DIRS += -I $(CTRL_PROTO_PATH)/lib_linux_ctrlproto/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I ../motor_config

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib
LIB_DIRS += -L ../lib_linux_ctrlproto/lib

# Needed for checking if Linux machine
UNAME := $(shell uname)

all:
		@echo Bulding dependency: lib_linux_ctrlproto...
		@cd $(CTRL_PROTO_PATH)/lib_linux_ctrlproto; make
		@echo 
		@echo Bulding application $(notdir $(shell pwd))
ifneq "$(UNAME)" "Linux"
		@echo "------------------------------------------------------------------------------------------------------"
		@echo "||Your System isn't Linux, so the Master Application for the Linux Ethercat Master can not be built.||"
		@echo "------------------------------------------------------------------------------------------------------"
else
		@if test -d $(ETHERCAT_MASTER_INSTALLDIR); \
		then \
		mkdir bin -p;\
		gcc src/main.c $(LIBS) $(INCLUDE_DIRS) $(LIB_DIRS) $(FLAGS) -o bin/$(notdir $(shell pwd)); \
		else echo \
		"\n\
		-----------------------------------------------------------------------------------------------------------------\n\
		||Ethercat Master is not installed at given directory if you installed it elsewhere change location in Makefile||\n\
		-----------------------------------------------------------------------------------------------------------------\n";\
		fi
endif

##Add clean Master Application
clean: masterAppClean
masterAppClean:
	rm -f bin/app_linux_ctrlproto-master-example
