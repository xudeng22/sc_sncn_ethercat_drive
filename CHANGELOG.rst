sc_sncn_ethercat_drive Change Log
==================================

3.1.2
-----

  * Add GPIO support in ethercat drive
  

3.1.1
-----

  * Fix data type of PID coefficients to use float.
  * Fix reload configuration from object dictionary

3.1
---

  * Add cogging torque calibration command. Possibility to store it in the flash memory.
  * New Object Dictionary (OD) structure:
    * Arbitrary value sizes (type aware)
    * Detection of changed values by master
    * Min, Max, Default, Unit values
  * Reading, storing, and automatic loading of OD (via file service of SPIFFS)
  * Support for watchdog error for DC1K rev.D1
  * Core C22 and C21-DX rev.A are no longer supported (memory limitation)


3.0.4
-----

  * Add GPIO support in ethercat drive
  

3.0.3
-----

  * Fix torque offset pdo unit (now in 1/1000 of rated torque)
  * Fix value of Encoder Number of Channels to 2 for AB and 3 for ABI.
  * Fix bug in CiA 402 state machine.
  * Put error code (0x603F object) into user_miso pdo when not in tuning mode.
  * Do not change the integral limits of position/velocity controllers in case automatic tuners are called
  * Fix bug in position feedback config manager in switching from dual sensor to one sensor.
  * Bug fixes and improvement in app_master_cyclic.
  * Fix units in ESI
  * Add position controller automatic tuning command options to master tuning app
  * Reload slave configuration on S_SWITCH_ON_DISABLED -> S_READY_TO_SWITCH_ON transition
  * Fix offset display when sensor polarity is wrong
  * Fix number of subitems for objects 0x2202


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
  
