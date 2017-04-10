# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
TARGET = SOMANET-C22

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = app_demo_slave_ethercat_motorcontrol

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = config_motor module_adc module_biss module_board-support module_controllers lib_bldc_torque_control lib_ethercat module_ethercat_drive module_filters module_gpio module_hall module_misc module_motion_control module_pdo_handler module_position_feedback module_profile module_pwm module_qei module_reboot module_rem_14 module_rem_16mt module_serial_encoder module_shared_memory module_spi_master module_watchdog
# I expect this one to link against the wrong library
#USED_MODULES = config_motor module_adc module_biss module_board-support module_controllers lib_bldc_torque_control module_ethercat  module_ethercat_drive module_filters module_gpio module_hall module_misc module_motion_control module_pdo_handler module_position_feedback module_profile module_pwm module_qei module_reboot module_rem_14 module_rem_16mt module_serial_encoder module_shared_memory module_spi_master module_watchdog

# When running the app with xtime (or xrun) you need to use the ethercat_service_standalone library.
# When flashing the node you need to use the ethercat_service library (selected by default).
# Here when compilling in Debug mode it uses the ethercat_service_standalone library
# and when compilling in Release mode it uses the ethercat_service library.
ifeq ($(CONFIG),Debug)
	MODULE_LIBRARIES = ethercat_service_standalone
endif

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
XCC_FLAGS_Debug = -g -O3 -DCOM_ETHERCAT -lflash -report
XCC_FLAGS_Release = -g -O3 -DCOM_ETHERCAT  -lflash

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 1

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
