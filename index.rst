SOMANET EtherCAT Drive Application
==================================

The **SOMANET EtherCAT Drive Component** is an application-specific component that contains services and utilities required to perform a BLDC Motor Motion Control over EtherCAT using SOMANET IFM DC-Drive and COM-EtherCAT devices.
It implements a CiA 402-compliant Motion Control protocol that gathers all the functionalities offered by the :ref:`SOMANET Motion Control Component <somanet_motor_control>` and gives flexibility for application-specific requirements.

.. cssclass:: downloadable-button 

  `Download Component <https://github.com/synapticon/sc_sncn_ethercat_drive/archive/master.zip>`_

.. cssclass:: github

  `Visit Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/>`_

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
| 1x SOMANET **IFM**        |
+---------------------------+

.. class:: float-left 

+-----------------------------------------------------------------------------------------------+
| Supported SOMANET Devices                                                                     |
+===============================================================================================+
| SOMANET COM: :ref:`EtherCAT <com_ethercat>`                                                   |
+-----------------------------------------------------------------------------------------------+
| SOMANET Core: :ref:`C22 <core_c22>`                                                           |
+-----------------------------------------------------------------------------------------------+
| SOMANET IFM: :ref:`DC 100 <ifm_dc100>`,  :ref:`DC 1000 <ifm_dc1000_b2>`                       |
+-----------------------------------------------------------------------------------------------+

Modules
-------

.. toctree::
    :maxdepth: 1
    :hidden:

    Drive Module <module_ethercat_drive/doc/index>
    EtherCAT PDO Handler Module <module_pdo_handler/doc/index>

* `Drive Module <module_ethercat_drive/doc/index.html>`_: Provides a Service that acts as a joint for EtherCAT and Motor Control Libraries and allows driving motors over EtherCAT.
* `EtherCAT PDO Handler Module <module_pdo_handler/doc/index.html>`_: Provides the exchange of the current PDO values between :ref:`SOMANET EtherCAT <somanet_ethercat>` and the user application


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

    * `Drive Slave Firmware <examples/app_demo_slave_ethercat_motorcontrol/doc/index.html>`_: EtherCAT Drive slave firmware for your SOMANET device.


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

    .. cssclass:: downloadable-button 

     `Download SOMANET Motion Control Component <https://github.com/synapticon/sc_sncn_motorcontrol/archive/master.zip>`_

    .. cssclass:: github

      `Visit SOMANET Motion Control Public Repository <https://github.com/synapticon/sc_sncn_motorcontrol>`_

* :ref:`SOMANET EtherCAT <somanet_ethercat>`

    .. cssclass:: downloadable-button 

     `Download SOMANET EtherCAT Component  <https://github.com/synapticon/sc_sncn_ethercat/archive/master.zip>`_

    .. cssclass:: github

      `Visit SOMANET EtherCAT Public Repository <https://github.com/synapticon/sc_sncn_ethercat>`_

* :ref:`SOMANET Base <somanet_base>`

    .. cssclass:: downloadable-button 

      `Download SOMANET Base Component <https://github.com/synapticon/sc_somanet-base/archive/master.zip>`_

    .. cssclass:: github

      `Visit SOMANET Base Public Repository <https://github.com/synapticon/sc_somanet-base>`_


.. important:: To be able to **run** EtherCAT Drive Master applications in your Linux machine, you first have to install all necessary **drivers**.
    
    Visit our :ref:`IgH EtherCAT Master for Linux Documentation <ethercat_master_software_linux>` for further information. 
