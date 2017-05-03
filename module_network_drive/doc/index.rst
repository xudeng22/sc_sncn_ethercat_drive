.. _network_drive_module:

=============================
Network Drive Module
=============================

This module provides a Service to perform Motor Control over different networks. It needs to be interfaced to the :ref:`CANopen Interface Service <module_canopen_interface>` 
and some Services belonging to the :ref:`Motor Control Library <somanet_motor_control>`.

It deploys over EtherCAT all the features of the SOMANET Motor Control Library and it responds to a **CiA402**-compliant control scheme. It features a state machine, configuration update from the Master application, different Cyclic modes for Position, Velocity and Torque, and a Special Engineering Mode for tuning.

.. contents:: In this document
    :backlinks: none
    :depth: 3

.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/module_ethercat_drive>`_
 
How to use
==========

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>`, :ref:`SOMANET Motor Control <somanet_motor_control>`, and :ref:`SOMANET EtherCAT <somanet_ethercat>` libraries. And therefore, your app includes the required **board support** files for your SOMANET device, and the required Motor Control and EtherCAT Services. 
         
.. seealso:: 
    You might find useful the :ref:`EtherCAT Drive Slave Firmware <ethercat_slave_demo>` example app, which illustrate the use of this module. 

The EtherCAT Drive Service implements a `CiA402` compliant slave with its state machine. It receives sdo configuration parameters from the master which are then used to configure all the Somanet Motorcontrol services. It receives opmode, controlword and position/velocity/torque target which is used to change the states of the state machine, enable the motion control in the desired mode and control the motor. Do do so the service is connected to multiple Somanet services:
 - :ref:`Ethercat service <somanet_ethercat_slave>` to communicate with the master with pdo and sdo.
 - :ref:`Motion control <module_motion_control>` to control the motor in torque, velocity or position control.
 - :ref:`Motorcontrol <lib_bldc_torque_control>` and :ref:`Posision Feedback <module_position_feedback>` to set the parameters received from the master.


API
===

.. doxygenfunction:: ethercat_drive_service
.. doxygenfunction:: init_checklist
.. doxygenfunction:: update_checklist
.. doxygenfunction:: update_statusword
.. doxygenfunction:: get_next_state
.. doxygenfunction:: update_opmode
.. doxygenfunction:: tuning_handler_ethercat
.. doxygenfunction:: tuning_command_handler
.. doxygenfunction:: tuning_set_flags

