# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

LIBS += -lethercat -lm

ETHERCAT_PATH := ..
MOTORCONTROL_PATH := ..

ifneq (,$(wildcard ../../sc_sncn_ethercat/.))
	ETHERCAT_PATH := ../../sc_sncn_ethercat
endif

ifneq (,$(wildcard ../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../sc_sncn_motorcontrol
endif

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I include
INCLUDE_DIRS += -I ../inc_ctrlproto-common/
INCLUDE_DIRS += -I ../examples/config_motor_ethercat_drive
INCLUDE_DIRS += -I $(ETHERCAT_PATH)/module_ethercat/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol_common/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_motorcontrol/include

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib

# Needed for checking if Linux machine
UNAME := $(shell uname)

all:

ifneq "$(UNAME)" "Linux"
		@echo "----------------------------------------------------------------------------------------------------"
		@echo "||Your System isn't Linux, so the ctrlproto libary for the Linux Ethercat Master can not be built!||"
		@echo "----------------------------------------------------------------------------------------------------"
else
		@if test -d $(ETHERCAT_MASTER_INSTALLDIR); \
		then \
		mkdir lib -p;\
		gcc src/ctrlproto_m.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_ctrlproto.so -lstdc++ -shared -fPIC;\
		gcc -c src/ctrlproto_m.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_ctrlproto.o;\
		ar rcs lib/libsncn_ctrlproto.a lib/*.o;\
		rm -f lib/*.o;\
		rm -f lib/*.so;\
		else echo \
		"\n\
		-----------------------------------------------------------------------------------------------------------------\n\
		||Ethercat Master is not installed at given directory if you installed it elsewhere change location in Makefile||\n\
		-----------------------------------------------------------------------------------------------------------------\n";\
		fi
endif

clean:
	rm -f lib/*.so
	rm -f lib/*.a
