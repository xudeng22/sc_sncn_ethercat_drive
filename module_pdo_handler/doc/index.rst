.. _pdo_handler_module:

=============================
PDO Handler Module
=============================

This module provides the exchange of the current PDO values between
:ref:`SOMANET EtherCAT <somanet_ethercat>` and the user application.

.. contents:: In this document
    :backlinks: none
    :depth: 3

How to use
==========

For a example on how to use this module please see :ref:`EtherCAT Drive Module <ethercat_drive_module>`.

API
===

.. doxygenfunction::  pdo_get_target_torque
.. doxygenfunction::  pdo_get_target_velocity
.. doxygenfunction::  pdo_get_target_position
.. doxygenfunction::  pdo_get_controlword
.. doxygenfunction::  pdo_get_opmode
.. doxygenfunction::  pdo_get_offset_torque
.. doxygenfunction::  pdo_get_tuning_command
.. doxygenfunction::  pdo_get_dgitial_output1
.. doxygenfunction::  pdo_get_dgitial_output2
.. doxygenfunction::  pdo_get_dgitial_output3
.. doxygenfunction::  pdo_get_dgitial_output4
.. doxygenfunction::  pdo_get_user_mosi
.. doxygenfunction::  pdo_set_torque_value
.. doxygenfunction::  pdo_set_velocity_value
.. doxygenfunction::  pdo_set_position_value
.. doxygenfunction::  pdo_set_statusword
.. doxygenfunction::  pdo_set_opmode_display
.. doxygenfunction::  pdo_set_secondary_position_value
.. doxygenfunction::  pdo_set_secondary_velocity_value
.. doxygenfunction::  pdo_set_analog_input1
.. doxygenfunction::  pdo_set_analog_input2
.. doxygenfunction::  pdo_set_analog_input3
.. doxygenfunction::  pdo_set_analog_input4
.. doxygenfunction::  pdo_set_tuning_status
.. doxygenfunction::  pdo_set_digital_input1
.. doxygenfunction::  pdo_set_digital_input2
.. doxygenfunction::  pdo_set_digital_input3
.. doxygenfunction::  pdo_set_digital_input4
.. doxygenfunction::  pdo_set_user_miso
