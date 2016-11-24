# Installation directory of the  EtherCAT Master by IgH EtherLAB
ETHERCAT_MASTER_INSTALLDIR := /opt/etherlab

LIBS += -lethercat -lm

MOTORCONTROL_PATH := ..
MOTORCONTROL_LIB_PATH := ..

ifneq (,$(wildcard ../../sc_sncn_motorcontrol/.))
	MOTORCONTROL_PATH := ../../sc_sncn_motorcontrol
endif

ifneq (,$(wildcard ../../sc_sncn_motorcontrol_new/.))
	MOTORCONTROL_LIB_PATH := ../../sc_sncn_motorcontrol_new
endif

INCLUDE_DIRS += -I $(ETHERCAT_MASTER_INSTALLDIR)/include
INCLUDE_DIRS += -I include
INCLUDE_DIRS += -I ../inc_ctrlproto-common/
INCLUDE_DIRS += -I ../lib_linux_ctrlproto/include/
INCLUDE_DIRS += -I ../examples/config_motor_master
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_pwm_symmetrical/src/common
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_profile/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_qei/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_biss/biss_configs
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_contelec_encoder/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_ams_rotary_sensor/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_hall/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_position_feedback/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_gpio/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_advanced_torquecontrol_lib/include
INCLUDE_DIRS += -I $(MOTORCONTROL_PATH)/module_misc/include

LIB_DIRS += -L $(ETHERCAT_MASTER_INSTALLDIR)/lib

# Needed for checking if Linux machine
UNAME := $(shell uname)

all:

ifneq "$(UNAME)" "Linux"
		@echo "----------------------------------------------------------------------------------------------------"
		@echo "||Your System isn't Linux, so the ctrlproto libary for the Linux EtherCAT Master can not be built!||"
		@echo "----------------------------------------------------------------------------------------------------"
else
		@if test -d $(ETHERCAT_MASTER_INSTALLDIR); \
		then \
		mkdir lib -p;\
		gcc $(MOTORCONTROL_PATH)/module_profile/profile_velocity_mode/profile_velocity.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_velocity.so -lstdc++ -shared -fPIC;\
		gcc -c $(MOTORCONTROL_PATH)/module_profile/profile_velocity_mode/profile_velocity.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_velocity.o;\
		gcc $(MOTORCONTROL_PATH)/module_profile/profile_position_mode/profile_position.c $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_position.so -lstdc++ -shared -fPIC;\
		gcc -c $(MOTORCONTROL_PATH)/module_profile/profile_position_mode/profile_position.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_position.o;\
		gcc $(MOTORCONTROL_PATH)/module_profile/profile_linear_mode/profile_linear.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_linear.so -lstdc++ -shared -fPIC;\
		gcc -c $(MOTORCONTROL_PATH)/module_profile/profile_linear_mode/profile_linear.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_linear.o;\
		gcc src/drive_function.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_drive_function.so -lstdc++ -shared -fPIC;\
		gcc -c src/drive_function.c  $(INCLUDE_DIRS) $(LIBS) $(LIB_DIRS) -o lib/libsncn_drive_function.o;\
		ar rcs lib/libsncn_motor_drive.a lib/*.o;\
		rm -f lib/*.o;\
		rm -f lib/*.so;\
		else echo \
		"\n\
		-----------------------------------------------------------------------------------------------------------------\n\
		||EtherCAT Master is not installed at given directory if you installed it elsewhere change location in Makefile||\n\
		-----------------------------------------------------------------------------------------------------------------\n";\
		fi
endif

clean:
	rm -f lib/*.so
	rm -f lib/*.a
