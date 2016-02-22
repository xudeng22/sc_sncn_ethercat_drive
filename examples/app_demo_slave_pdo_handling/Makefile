# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
TARGET = SOMANET-C22

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = app_demo_slave_pdo_handling

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = module_adc module_biss module_board-support module_ctrl_loops module_ethercat module_ethercat_drive module_ethercat_fwupdate module_gpio module_hall module_misc module_motorcontrol module_profile module_pwm_symmetrical module_qei module_watchdog

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
XCC_FLAGS_Debug = -g -O0 -lflash -report
XCC_FLAGS_Release = -g -O3 -lflash

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 0

XMOS_MAKE_PATH ?= ../..
-include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
