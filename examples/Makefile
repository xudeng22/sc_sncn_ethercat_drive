# This variable should contain a space separated list of all
# the directories containing buildable applications (usually
# prefixed with the app_ prefix)
#
# If the variable is set to "all" then all directories that start with app_
# are built.
BUILD_SUBDIRS = app_demo_slave_ethercat_motorcontrol

XMOS_MAKE_PATH ?= ..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.toplevel

# Only for documentation generation
SPHINX_PROJECT_NAME = SOMANET Motor Control Demo Apps
FVERSION=2v0
XDOC_DIR ?= ../xdoc
-include $(XDOC_DIR)/Makefile.inc
