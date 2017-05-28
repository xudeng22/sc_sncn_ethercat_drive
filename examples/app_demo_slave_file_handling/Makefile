# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
TARGET = SOMANET-C22

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = app_demo_slave_file_handling

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = module_board-support module_canopen_interface module_spiffs lib_ethercat module_reboot module_file_service module_flash_service module_config_parser

ifeq ($(CONFIG), Debug)
MODULE_LIBRARIES = ethercat_service_standalone
else
MODULE_LIBRARIES = ethercat_service
endif

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
XCC_FLAGS_Debug = -g -O3 -DCOM_ETHERCAT -lflash -report
XCC_FLAGS_Release = -g -O3 -DCOM_ETHERCAT -lflash

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 1

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
