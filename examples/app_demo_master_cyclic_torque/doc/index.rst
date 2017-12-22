.. _SOMANET_Cyclic_Torque_Control_with_EtherCAT_Demo_Quickstart:

SOMANET EtherCAT Drive Cyclic Torque Control Master Demo
========================================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This simple demonstration shows how to control your motor using SOMANET EtherCAT Motor Control Kit from a Linux PC. Only Cyclic Synchronous Torque (CST) control mode is included into this demo with a simple linear profile generator example. The CST control mode is designed to achieve a desired motion trajectory with a controlled force by using various motion profiles and closing the control loop over EtherCAT. The slave controller in its turn is taking the generated at a fixed time interval (1ms) target torque setpoints as a controller input and will be following them. 

Hardware setup
++++++++++++++

A minimal requirement for this application to run is having the complete SOMANET stack assembled consisting of a *SOMANET Core-C22*, *SOMANET COM-EtherCAT*, and a *SOMANET IFM-Drive-DC100/300* modules. The stack should be powered via the *SOMANET IFM* board. An example of a stack consisting of the *SOMANET* COM-EtherCAT, Core-C22, and IFM-Drive-DC100 boards is shown below. In this case the *IFM-DC100* board can be supplied with 12 - 24 V DC power source. For the motor supplied with the kit required power supply voltage should be 24 Volts. For the best experience please make sure that your stabilized DC power supply is capable of delivering more that 2 Amperes of power. Please mind that at high motor accelerations the starting current may be as high as 10 times the nominal.     

.. figure:: images/ethercat_stack.jpg
   :align: center

   Hardware Setup for SOMANET Cyclic Torque Control with EtherCAT Demo

|newpage|

To setup the system:

   #. If you don't have the stack assembled, assemble it as shown in the image above. Make sure to connect the IFM side of the *SOMANET Core* module to the IFM-DC100 board and COM side to the Core Debug Adapter (see markings on the Core module)
   #. Connect the xTAG-2 Adapter to the Core Debug Adapter.
   #. Connect the xTAG-2 to host PC. 
   #. Connect the motor supplied with the kit as shown in the image bellow.
   #. Connect the *IFM-DC100* board to a 24 V DC power supply
   #. Connect one side of the Ethernet cable to the node and plug the RJ-45 connector to your PC.
   #. Switch on the power supply. If everything is connected properly, the drained current should not exceed 100mA. 

.. figure:: images/stack_and_motor.jpg
   :align: center

   Connecting the motor and cables to your kit


Import and build the application
++++++++++++++++++++++++++++++++

   #. Open *xTIMEcomposer* Studio and check that it is operating in online mode. Open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``'SOMANET EtherCAT CST Motor Control Demo'`` item in the *xSOFTip* pane on the bottom left of the window and drag it into the Project Explorer window in *xTIMEcomposer*. This will also cause the modules on which this application depends to be imported as well. 
   #. Click on the ``app_demo_master_cyclic_torque`` item in the Project Explorer plane then click on the build icon (hammer) in *xTIMEcomposer*. Check the Console window to verify that the application has built successfully. Note that you require the EtherCAT master :ref:`IgH EtherLab to be installed <ethercat_master_software_linux>` on your system to build the application. Otherwise the build will fail.

For help in using *xTIMEcomposer*, try the *xTIMEcomposer* tutorial, which you can find by selecting Help->Tutorials from the *xTIMEcomposer* menu.

Note that the Developer Column in *xTIMEcomposer* Studio on the right hand side of your screen provides information on the *xSOFTip* components you are using. Select one of the imported components in the Project Explorer, and you will see their description together with API documentation. Having done this, click the `back` icon until you return to this Quick Start Guide within the Developer Column.


Run the application
+++++++++++++++++++

When the application has been compiled, the next step is to run it on the Linux PC. Before doing that, make sure that the SOMANET EtherCAT stack is running a proper motor control software for the EtherCAT slave side, i.e. ``app_demo_slave_ethercat_motorcontrol``.  

   #. Make sure your EtherCAT Master is up and running. To start the Master on a Linux machine, execute the following command: ::

       sudo /etc/init.d/ethercat start

   #. Make sure your SOMANET node is accessible by the EtherCAT master by typing: ::

        ethercat slave 

      The output should indicate a presence of the SOMANET node and pre-operational state if the slave side software is running: ::

        0  0:0  PREOP  +  SNCN SOMANET COM ECAT

   #. Navigate with the terminal to your compiled application binary on the hard disk. Then execute the application with super user rights: ::

       sudo ./app_demo_master_cyclic_torque 

   #. The application will deploy the motor-specific configuration parameters over the EtherCAT and the rotor of the motor should start rotating. In the terminal window you should be able to see the motor's feedback as actual torque, position, and velocity along with the commanded to the slave target torque value ::

       target_torque 99.990005 
       actual_torque 100.410812 actual_position 7763 actual_velocity 732

   #. The debug console window in *xTIMEcomposer* will not display any message because the demo application is written to work with an EtherCAT master application and feedback is therefore provided via EtherCAT communication.


Next steps
++++++++++

As a next step you can run another EtherCAT Master Motor Control Demo. Two more control modes are offered: Cyclic Synchronous Position (``app_demo_master_cyclic_position``) and Cyclic Synchronous Velocity (``app_demo_master_cyclic_velocity``).

Examine the code
................

   #. In *xTIMEcomposer* navigate to the ``src`` directory under ``app_demo_master_cyclic_torque`` and double click on the ``main.c`` file within it. The file will open in the central editor window.

   #. Find and examine the main function. At the beginning you'll find variables declarations that will be used to define your desired motion profile and provide you feedback from the motor. The ``slave_number`` variable is used when the nodes are operating in a multi-node setup.

   #. Before starting the main control routine you are required to initialise a set of parameters and to follow a motor starting state machine as defined in the CiA 402 directive (see the image bellow).

      .. figure:: images/statemachine.png
         :width: 100%
         :align: center

         Motor Control state machine

   #. ``init_master`` is taking care of the EtherCAT communication initialization. In case of the multi-node system the EtherCAT nodes can be configured from the ``ethercat_setup.h`` in the ``src`` directory. The default configuration allows you to get started with a single node setup without making any changes.

   #. ``initialize_torque`` is required to have a torque feedback, even if you are not using the torque control.

   #. The ``init_nodes`` routine will take care of loading your motor configuration(s) into the slaves via EtherCAT. All slave nodes are running the same software and can be configured for using different motors from the master side. The motor configurations are included in the ``config`` folder, and the config files there have ``_N`` extensions to differentiate between various motors. When you specify a CONFIG_NUMBER in the ``SOMANET_C22_CTRLPROTO_SLAVE_HANDLES_ENTRY`` (defined in the ``ethercat_setup.h``), all corresponding configurations are being loaded to all the nodes. For the single-node setup only ``bldc_motor_config_1.h`` is used.

   #. ``set_operation_mode`` defines the control mode to be used. In this example we are using the Cyclic Synchronous Torque mode (CST).

   #. ``enable_operation`` is a part of the state machine control sequence as described above.

   #. To compute the number of steps required to achieve the desired torque profile we need to call the ``init_linear_profile_params`` function and provide it our desired profile parameters as the target and actual torque values and an equivalent to acceleration - the torque slope parameter.

   #. The motion control routine should be executed in a loop. In the example we are ramping up to the target torque value and then executing a quick stop action. The ``pdo_handle_ecat`` is a handler that takes care of a real-time information update over EtherCAT.  

   #. The steps are then provided in a cyclic way to the motion profile generator (``generate_profile_linear``) that calculates the immediate torque setpoint (``target_torque``) that is used as input for the torque controller on the slave side (is sent over EtherCAT by the ``set_torque_mNm`` function call). 

   #. To get the torque, position, and velocity feedback from the controller the ``get_torque_actual_mNm``, ``get_position_actual_ticks``, and ``get_velocity_actual_rpm`` functions are used respectively.

   #. As an example for the state machine the methods as ``quick_stop_position``, ``renable_ctrl_quick_stop``, ``set_operation_mode``, ``enable_operation``, and ``shutdown_operation`` are included in the software, and the master application will properly exit and disable the motor after the torque target value is reached. Please refer to the state machine diagram to include them properly when developing your custom application.


