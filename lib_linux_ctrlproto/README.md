Protocol for Motor Control Library
=======================
<a href="https://github.com/synapticon/sc_sncn_motorctrl_sin/blob/master/SYNAPTICON.md">
<img align="left" src="https://s3-eu-west-1.amazonaws.com/synapticon-resources/images/logos/synapticon_fullname_blackoverwhite_280x48.png"/>
</a>
<br/>
<br/>

This library provides initialization for multinode setup via config defines, for EtherCAT master setup, EtherCAT Process data and Service data update functions.

In order to access this library from your application:

1. Include the header files on your code:

* ctrlproto_m.h - To access the all library functions.

* motor_define.h - To access the motor configurations structs.

Note: All motor configuration (bldc_motor_config_N.h) header files must be included in 
ctrlproto_m.h

###Quick API
The API for the CiA402 based ctrlproto component can be found on the lib_linux_motor_drive folder. this is the basic API, if further functions are need please a look to the drive_function header file.

####Cyclic Synchronous Position mode
The set of functions used in the loop update:
```
set_position_degree(target_position, slave_number, slv_handles)
get_position_actual_degree(slave_number, slv_handles)
```

Excluding the profile generation functions used in the test app.

####Cyclic Synchronous Velocity mode
The set of functions used in the loop update:
```
set_velocity_rpm(target_velocity, slave_number, slv_handles)
get_velocity_actual_rpm(slave_number, slv_handles)
```

Excluding the profile generation functions used in the test app.

####Cyclic Synchronous Torque mode
The set of functions used in the loop update.
```
set_torque_mNm(target_torque, slave_number, slv_handles)
get_torque_actual_mNm(slave_number, slv_handles)
```

Excluding the profile generation functions used in the test app.

* The frequency of loop update can be changed through the define FREQUENCY (in KHz) parameter at *lib_linux_ctrlproto/src/ctrlproto_m.c*

####Profile Position mode
The set of functions used in the loop update:
```
set_profile_position_degree(target_position, slave_number, slv_handles)
target_position_reached(slave_number, target_position, tolerance, slv_handles)
get_position_actual_degree(slave_number, slv_handles)
```

####Profile Velocity mode
The set of functions used in the loop update:
```
set_velocity_rpm(target_velocity, slave_number, slv_handles)
target_velocity_reached(slave_number, target_velocity, tolerance, slv_handles)
get_velocity_actual_rpm(slave_number, slv_handles)
```

####Profile Torque mode
The set of functions used in the loop update:
```
set_torque_mNm(target_torque, slave_number, slv_handles)
target_torque_reached(slave_number, target_torque, tolerance, slv_handles)
get_torque_actual_mNm(slave_number, slv_handles)
```

####Emergency Actions
In case of emergency we provide safety functions to enable safe operation of the motor. By calling quick stop functions the drive can be stopped quickly for position, torque and velocity modes. As along as the ethercat master still can maintain the connection to the nodes this function can be called.

* **Quick stop** : quick_stop_position, quick_stop_torque and quick_stop_velocity are the set of functions provided to perform quick stop actions.
* **Renable Ctrl quick stop**: To resume the mode of operation again after quick stop action – renable ctrl quick stop should be called.Either the user can decide to continue with normal Loop Operations or could shut down the node as shown in the flow chart.If the ethercat connection is lost, the nodes will automatically perform quick stop action as a safety procedure.
