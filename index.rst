SOMANET EtherCAT Drive Application
==================================

The **SOMANET EtherCAT Drive Component** is an application-specific component that contains services and utilities required to perform a BLDC Motor Motion Control over EtherCAT using SOMANET Drive and COM-EtherCAT devices.
It implements a CiA 402-compliant Motion Control protocol that gathers all the functionalities offered by the :ref:`SOMANET Motion Control Component <somanet_motor_control>` and gives flexibility for application-specific requirements.

.. _ecat_drive_hw_compatibility:

Hardware Compatibility
----------------------

.. class:: float-left 

+---------------------------+
| Required SOMANET Hardware |
+===========================+
| 1x SOMANET **Core**       |
+---------------------------+
| 1x SOMANET **COM**        |
+---------------------------+
| 1x SOMANET **Drive**      |
+---------------------------+

.. class:: float-left 

+-----------------------------------------------------------------------------------------------+
| Supported SOMANET Devices                                                                     |
+===============================================================================================+
| SOMANET COM: :ref:`EtherCAT <com_ethercat>`                                                   |
+-----------------------------------------------------------------------------------------------+
| SOMANET Core: :ref:`C22 <core_c22>`                                                           |
+-----------------------------------------------------------------------------------------------+
| SOMANET Drive: :ref:`Drive 100 <ifm_dc100>`,  :ref:`Drive 1000 <ifm_dc1000>`               |
+-----------------------------------------------------------------------------------------------+

Modules
-------

.. toctree::
    :maxdepth: 1
    :hidden:

    Drive Module <module_network_drive/doc/index>
    Canopen Interface Service <module_canopen_interface/doc/index>

* `Drive Module <module_network_drive/doc/index.html>`_: Provides a Service that acts as a joint for EtherCAT and Motor Control Libraries and allows driving motors over EtherCAT.
* `Canopen Interface Service <module_canopen_interface/doc/index.html>`_: Provides a service to access the PDO values and accesses the object dictionary. This service is the connection point between the communication library or module, for example :ref:`SOMANET EtherCAT <somanet_ethercat>` and the user application.


Examples
--------

.. toctree::
    :hidden:
    :maxdepth: 1

    Drive Slave Firmware <examples/app_demo_slave_ethercat_motorcontrol/doc/index>

    Cyclic Position/Velocity/Torque Control Demo <examples/app_demo_master_cyclic/doc/index>
    Special Tuning Mode Application <examples/app_demo_master_ethercat_tuning/doc/index>

    SDO Handling Demo Slave <examples/app_demo_slave_sdo_handling/doc/index>
    SDO Handling Demo Master <examples/app_demo_master_object_dictionary/doc/index>

    PDO Handling Demo Slave <examples/app_demo_slave_pdo_handling/doc/index>
    PDO Handling Demo Master <examples/app_linux_ctrlproto-master-example/doc/index>

* **Slave examples (for SOMANET devices):**

    * `Drive Slave Firmware <examples/app_slave_ethercat_motorcontrol/doc/index.html>`_: EtherCAT Drive slave firmware for your SOMANET device.


* **Master examples (for Linux machines):**

    * `Cyclic Position/Velocity/Torque Control Demo <examples/app_demo_master_cyclic/doc/index.html>`_: Example to do cyclic position/velocity/torque control on one/multiple axis over EtherCAT.

    * `Special Tuning Mode Application <examples/app_demo_master_ethercat_tuning/doc/index.html>`_: Provides access to extended features of the EtherCAT Slave Drive Controller like PID or commutation angle offset tining over EtherCAT.


* **Test Master+Slave examples (for Linux Master machines):**
    * `PDO Handling Demo Slave <examples/app_demo_slave_pdo_handling/doc/index.html>`_: Showcases simple PDO communication (Slave)
    * `PDO Handling Demo Master <examples/app_demo_master_pdo_handling/doc/index.html>`_: Showcases simple PDO communication (Master)

    * `SDO Handling Demo Slave <examples/app_demo_slave_sdo_handling/doc/index.html>`_: Showcases how to handle parameters over SDO (Slave)
    * `SDO Handling Demo Master <examples/app_demo_master_object_dictionary/doc/index.html>`_: Show access to the slaves object dictionary and tests reading and writing of the objects value (Master)


Dependencies
------------

To run **EtherCAT Drive applications** it is necessary to include additionally the following libraries:

* :ref:`SOMANET Motion Control <somanet_motion_control>`

* :ref:`SOMANET EtherCAT <somanet_ethercat>`

* :ref:`SOMANET Base <somanet_base>`

.. important:: To be able to **run** EtherCAT Drive Master applications in your Linux machine, you first have to install all necessary **drivers**.
    
    Visit our :ref:`IgH EtherCAT Master for Linux Documentation <ethercat_master_software_linux>` for further information. 

