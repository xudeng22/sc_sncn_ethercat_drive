.. _module_error_logging:

=========================================
Module Error Logging
=========================================


This module provides storing (logging) of error messages from errors circular buffer in motion_control_service to SPIFFS in text format.
Logging should be initialized by startup after starting spiffs_service using ''function error_logging_init(client SPIFFSInterface ?i_spiffs)''.
In case of successful init, function returns LOG_OK.
To store new error message to log file, use function ''error_msg_save(client SPIFFSInterface ?i_spiffs, ErrItem_t ErrItem)'', 
where ''ErrItem'' is structure, which contains message information:

   - unsigned int index;
   - unsigned int timestamp;
   - unsigned int err_code;
   - ErrType err_type;

Types of errors:

  - ERR_STATUS;
  - ERR_MOTION;
  - ERR_SENSOR;
  - ERR_SEC_SENSOR;
  - ERR_ANGLE_SENSOR;
  - ERR_WATCHDOG;

Dependent modules:
- ``module_spiffs``
- ``module_file_service``
- ``module_motion_control``


API
===

Service
--------

.. doxygenfunction:: error_logging_init

.. doxygenfunction:: error_msg_save


