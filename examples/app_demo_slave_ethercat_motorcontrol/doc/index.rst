.. _ethercat_slave_demo:

===================================
EtherCAT Drive Slave Firmware Demo
===================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

The purpose of this app (app_demo_slave_ethercat_motorcontrol) is showing the use of the :ref:`EtherCAT Drive Module <ethercat_drive_module>` and serving as a standard firmware for EtherCAT Drive applications. It includes all Motor Control Services and utilities offered by the :ref:`Motor Control Library <somanet_motor_control>. It also supports :ref:`Firmware Update over EtherCAT <ecat_fw_update>`.

* **Minimum Number of Cores**: 14
* **Minimum Number of Tiles**: 4

Quick How-to
============

1. :ref:`Assemble your SOMANET device <assembling_somanet_node>`.
2. Wire up your device. Check how at your specific :ref:`hardware documentation <hardware>`. Connect your Hall sensor, Encoder Interface (if used), motor phases, power supply and EtherCAT cables, and XTAG. Power up!
3. :ref:`Set up your XMOS development tools <getting_started_xmos_dev_tools>`. 
4. Download and :ref:`import in your workspace <getting_started_importing_library>` the SOMANET EtherCAT Drive Library and its dependencies.
5. Open the **main.xc** within  the **app_demo_slave_ethercat**. Include the :ref:`board-support file according to your SOMANET IFM device <somanet_board_support_module>`.

.. important:: Make sure the SOMANET Motor Control Library supports your SOMANET device. For that, check the :ref:`Hardware compatibility <ecat_drive_hw_compatibility>` section of the library.

6. :ref:`Set the configuration <motor_configuration_label>` for Motor Control, Hall, Encoder (if used), and Position Control Services. Also for your Profiler. In any case, later on you will need to set proper configuration on your **Master Application** since the parameters are overwritten by the Master side before starting the operation.
7. :ref:`Run the application. Enabling XScope <running_an_application>` is recommended, since you could monitor the current phases in real-time.
8. Now it is time to start working from the EtherCAT master side, for that check our **EtherCAT Master applications quickstart guides**:

            * :ref:`EtherCAT Cyclic Position Control Demo <SOMANET_Cyclic_Positioning_Control_with_EtherCAT_Demo_Quickstart>`
            * :ref:`EtherCAT Cyclic Velocity Control Demo <SOMANET_Cyclic_Velocity_Control_with_EtherCAT_Demo_Quickstart>`
            * :ref:`EtherCAT Cyclic Torque Control Demo <SOMANET_Cyclic_Torque_Control_with_EtherCAT_Demo_Quickstart>`


.. important:: To be able to **run** EtherCAT Drive Master applications in your Linux machine, you first have to install all necessary **drivers**.
	
	Visit our :ref:`IgH EtherCAT Master for Linux Documentation <ethercat_master_software_linux>` for further information. 

.. seealso:: Did everything go well? If you need further support please check out our `forum <http://forum.synapticon.com/>`_.
        
