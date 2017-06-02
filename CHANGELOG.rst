sc_sncn_ethercat_drive Change Log
==================================

3.0.2
-----

  * Fix issue with the value of position control strategy
  * Rename MOTOR_PHASES_CONFIGURATION in user_config.h and main.xc files
  * Change phase inverted parameter to 0 - normal and 1 - inverted
  * Fix bitsize and access rights in device configuration XML
  * Fix datatypes of PID controller


3.0.1
-----

  * Fix issue with a not working Debug/Release build configuration for demo apps
  * Fix issue with not supported data types 


3.0.0
-----

  * Synchronize version number with global SDK Version
  * New Object Dictionary enabling better components configurability
  * Removed ctrl_proto and linux_drive libraries
  * Fixed state-machine
  * Special tuing mode is added 
  * Fail-safe firmware update with FoE


1.0.0
-----

  * Initial Version
  * Includes old ctrlproto library
  * Includes module_ethercat_drive (formerly in scn_sncn_motorcontrol)
  * Includes all apps from sw_sncn_motorcontrol_ethercat_kit
  * Adds 2 new demo apps for PDO communication
  * Has new beautiful docs
  
