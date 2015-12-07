SOMANET EtherCAT CST Motor Control Two Nodes Demo
=================================================

:scope: Example
:description: This example demonstrates how to implement an EtherCAT master motor control application for a Linux PC and two connected nodes. A Cyclic Synchronous Torque mode for two nodes is demonstrated.
:keywords: COM-EtherCAT, Motor Control, EtherCAT master, Muti-node setup
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET Motor Control etherCAT Kit

Description
-----------

This application provides a multi-node example of a Master Application for Cyclic Synchronous Torque (host side). The SOMANET nodes must be running app_demo_slave_ethercat_motorcontrol before starting the Linux EtherCAT Master application.

In Cyclic Synchronous position mode a user can set a new target torque per node every millisecond making cyclic modes an ideal application for real-time motion control. An examples that generates a linear torque profile for a target torque with millisecond steps is included into the application.

NOTE: The application requires EtherCAT Master for Linux from IGH to be installed on your PC (`EtherLab EtherCAT Linux Driver <http://www.etherlab.org/en/ethercat/>`_
). 

