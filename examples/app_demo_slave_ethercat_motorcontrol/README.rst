SOMANET EtherCAT slave application
==================================

:scope: Example
:description: This example demonstrates how to implement a motor control software for the slave side to be used for EtherCAT based control. The example includes all control modes that can be freely selected from the master side.
:keywords: COM-EtherCAT, Motor Control, EtherCAT, slave
:boards: XK-SN-1BH12-E, XK-SN-1BQ12-E, SOMANET EtherCAT Motor Control Kit

Description
-----------

This demonstrative application illustrates usage of Motor Control with EtherCAT. It includes such control modes as Cyclic Synchronous Positioning (CSP), Cyclic Synchronous Velocity (CSV), and Cyclic Synchronous Torque (CST) as well as Profile Positioning Mode (PPM), Profile Velocity Mode (PVM), and Profile Torque Mode (PTM). The cyclic modes require the motion control loop to be closed from the Master side, when the profile modes implements ramps locally on the slave side and do not provide real-time feedback till the control task is finished (the motion profile is executed).



