.. _ethercat_slave_demo:

===================================
EtherCAT Drive Slave Firmware Demo
===================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

The purpose of this app (app_demo_slave_ethercat_motorcontrol) is to demonstrate the use of the :ref:`EtherCAT Drive Module <ethercat_drive_module>` and to serve as a standard firmware for EtherCAT Drive applications. It includes all Motion Control Services and utilities offered by the :ref:`Motion Control Library <somanet_motion_control>. It also supports :ref:`Firmware Update over EtherCAT <ecat_fw_update>`.

* **Minimum Number of Cores**: 14
* **Minimum Number of Tiles**: 4

.. cssclass:: github

  `See Application on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/examples/app_demo_slave_ethercat_motorcontrol/>`_

Quick How-to
============

1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.

.. figure:: images/ethercat_stack.jpg
   :align: center
   
2. Wire up your device. Check your specific :ref:`hardware documentation <hardware>` how. Connect your sensor, motor phases, power supply, EtherCAT cables and XTAG. Power up!

.. figure:: images/stack_and_motor.jpg
   :align: center

3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`. 
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET EtherCAT Drive Library and its dependencies.
5. Open the **main.xc** within  the **app_demo_slave_ethercat**. Include the :ref:`board-support file according to your SOMANET IFM device <somanet_board_support_module>`.

.. important:: Make sure the SOMANET Motor Control Library supports your SOMANET device. For that, check the :ref:`Hardware compatibility <ecat_drive_hw_compatibility>` section of the library.

6. Set the **user_config.h** configuration file. Most of the parameters can be update over EtherCat by the master so you can leave default values.
   Some parameters which need to be set at compile time are:

   - IF2_TILE_USEC
   - PROTECTION_MAXIMUM_CURRENT
   - PROTECTION_MINIMUM_VOLTAGE 
   - PROTECTION_MAXIMUM_VOLTAGE
   - TEMP_BOARD_MAX


7. Run the application. The application use the :ref:`Somanet Ethercat slave service <somanet_ethercat_slave>` as well as all the Somanet Motor and Motion control services: :ref:`Motion control <module_motion_control>`, :ref:`PWM <module_pwm>`, :ref:`ADC <module_adc>`, :ref:`Watchdog <module_watchdog>`, :ref:`Torque Control <lib_bldc_torque_control>`, :ref:`Shared Memory <module_shared_memory>`, :ref:`Posision Feedback <module_position_feedback>`

8. Now it is time to start working from the EtherCAT master side, for that check our **EtherCAT Master applications quickstart guides**:

            * :ref:`Cyclic Position/Velocity/Torque Control Demo <app_demo_master_cyclic>`
            * :ref:`Special Engineering Mode Application <app_demo_master_ethercat_tuning>`


.. important:: To be able to **run** EtherCAT Drive Master applications in your Linux machine, you first have to install all necessary **drivers**.
	
	Visit our :ref:`IgH EtherCAT Master for Linux Documentation <ethercat_master_software_linux>` for further information. 

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.

