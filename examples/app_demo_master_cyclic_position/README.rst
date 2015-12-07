SOMANET EtherCAT CSP motor control demo
=======================================

:scope: Example
:description: This example demonstrates how to implement an EtherCAT master motor control application for a Linux PC. A Cyclic Synchronous Positioning mode is demonstrated.
:keywords: COM-EtherCAT, Motor Control, EtherCAT master
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET Motor Control etherCAT Kit

Description
-----------

This application provides an example of a Master Application for Cyclic Synchronous Position (host side). The SOMANET nodes must be running app_demo_slave_ethercat_motorcontrol before starting the Linux EtherCAT Master application.

In Cyclic Synchronous position mode a user can set a new target position per node every millisecond making cyclic modes an ideal application for real-time control. An examples that generates a linear position profile for a target position with millisecond steps is included into the application.
taken care of. 

The motor configuration and control parameter for each node connected to the motor must be specified at config/bldc_motor_config_N.h

NOTE: The application requires EtherCAT Master for Linux from IGH to be installed on your PC (`EtherLab EtherCAT Linux Driver <http://www.etherlab.org/en/ethercat/>`_
). You can also refer to the `Synapticon installation documentation <http://doc.synapticon.com/wiki/index.php/EtherCAT_Master_Software>`_ for a simplified EtherCAT driver installation procedure.

