SOMANET EtherCAT CST Motor Control Demo
=======================================

:scope: Example
:description: This example demonstrates how to implement an EtherCAT master motor control application for a Linux PC. A Cyclic Synchronous Torque mode is demonstrated.
:keywords: COM-EtherCAT, Motor Control, EtherCAT master
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET Motor Control etherCAT Kit

Description
-----------

This application provides an example of a Master Application for Cyclic Synchronous Torque (host side) control mode. The SOMANET nodes must be running ``app_demo_slave_ethercat_motorcontrol`` before starting the Linux EtherCAT Master application.

In Cyclic Synchronous Torque (CST) mode a user can set a new target torque per node every millisecond making cyclic modes an ideal application for real-time control. An example that generates a linear torque profile for a target torque with millisecond steps is included into the application.

The motor configuration and control parameters for each node connected to the motor must be specified at config/bldc_motor_config_N.h

NOTE: The application requires EtherCAT Driver for Linux from IgH EtherLAB to be installed on your PC (`EtherLab EtherCAT Linux Driver <http://www.etherlab.org/en/ethercat/>`_
). You can also refer to the `Synapticon installation documentation <http://doc.synapticon.com/wiki/index.php/EtherCAT_Master_Software>`_ for a simplified EtherCAT driver installation procedure.

