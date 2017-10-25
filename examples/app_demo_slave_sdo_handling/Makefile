# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
TARGET = SOMANET-CoreC2X

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = app_demo_slave_sdo_handling

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = module_board-support module_canopen_interface lib_ethercat module_reboot

ifeq ($(CONFIG), Debug)
MODULE_LIBRARIES = ethercat_service_standalone
else
MODULE_LIBRARIES = ethercat_service
endif

# Architecture specific flags, e.g. XCORE200 has quadflash
ifeq ($(TARGET),SOMANET-C22)
ARCH_SPEC_FLAGS = -lflash
else
ARCH_SPEC_FLAGS = -DXCORE200 -lquadflash
endif

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
XCC_FLAGS_Debug = -g -O3 -DCOM_ETHERCAT $(ARCH_SPEC_FLAGS) -report
XCC_FLAGS_Release = -g -O3 -DCOM_ETHERCAT $(ARCH_SPEC_FLAGS)

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 1

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
