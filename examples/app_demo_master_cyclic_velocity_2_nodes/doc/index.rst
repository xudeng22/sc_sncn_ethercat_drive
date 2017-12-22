.. _EtherCAT_Master_Cyclic_Velocity_Control_with_Two_Nodes_Demo_Quickstart:

EtherCAT Master Cyclic Velocity Control with Two Nodes Demo Quick Start Guide
=============================================================================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This simple demonstration shows how to control multiple motors using SOMANET EtherCAT Motor Control Kit from a Linux PC. This demo features the Cyclic Synchronous Velocity control mode with a simple linear profile generator. The CSV control mode is designed to follow a desired motion trajectory by using various motion profiles or cascaded control approach with closing the control loop over EtherCAT. The slave controller in its turn is taking the generated at a fixed time interval (1ms) target velocity set-points as a controller input and will be following them. That means that for the CSV the velocity control loop (PID loop) is closed on the slave and is not limited by any parameter. All the configurations are done from the master side.

Hardware setup
++++++++++++++

A minimal requirement for running this application is a complete SOMANET nodes assembled of the *SOMANET Core-C22*, *SOMANET COM-EtherCAT*, and *SOMANET IFM-Drive-DC100* modules. The nodes have to be flashed with the ``app_demo_slave_ethercat_motorcontrol`` firmware. An example of a single SOMANET node consisting of the *SOMANET COM-EtherCAT*, *SOMANET Core-C22*, and *SOMANET IFM-Drive-DC100* boards is shown in the image below. *SOMANET IFM-Drive-DC100* motor drivers can be supplied with 12 - 24 V DC power source. For the motor included in the kit, the required power supply voltage is 24 Volts. For the best experience please make sure that your stabilized DC power supply is capable of delivering more that 4 Amperes of power (in case of powering both nodes from the same source). Please mind that at high motor accelerations starting current may be as high as 10 times the nominal.     

.. figure:: images/assembly_p6.jpg
   :align: center

   Required hardware setup for this demo

To setup the system:

   #. If you don't have the *SOMANET* nodes assembled, assemble them as shown in the image above. Make sure to connect the IFM side of the *SOMANET Core* module to the *SOAMNET IFM-Drive-DC100* board and COM side to the Core Debug Adapter (see markings on the Core module)
   #. Connect the xTAG-2 Adapter to the Core Debug Adapter.
   #. Connect the xTAG-2 to host PC. 
   #. Connect the included motor as shown in the image bellow.
   #. Connect the *IFM-Drive-DC100* board to a 24 V DC power supply
   #. Connect one side of the cable ("S-002_O-03 SOMANET Option COM-EtherCAT") to the node (port one) and plug the RJ-45 connector to an Ethernet port of your PC.
   #. Connect port two of the EtherCAT node with the port one of the second EtherCAT node using the S-002_O-04 SOMANET Option COM-EtherCAT Cable.
   #. Switch on the power supply. If everything is connected properly, drained current should not exceed 200 mA. 

.. figure:: images/EtherCAT_two_nodes.jpg
   :align: center

   Connecting the motor and cables to your kit

|newpage|

Import and build the application
++++++++++++++++++++++++++++++++

   #. Open *xTIMEcomposer* Studio and check that it is operating in online mode. Open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``'SOMANET EtherCAT CSV Motor Control Two Nodes Demo'`` item in the *xSOFTip* pane on the bottom left of the window and drag it into the Project Explorer window in *xTIMEcomposer*. This will also cause the modules and Linux libraries on which this application depends on to be imported as well. 
   #. Click on the ``app_demo_master_cyclic_velocity_2_nodes`` item in the Project Explorer plane then click on the build icon (hammer) in *xTIMEcomposer*. Check the Console window to verify that the application has built successfully. Note that you require the EtherCAT master :ref:`IgH EtherLab to be installed <ethercat_master_software_linux>` on your system to build the application.

For help in using *xTIMEcomposer*, try the *xTIMEcomposer* tutorial, which you can find by selecting Help->Tutorials from the *xTIMEcomposer* menu.

Note that the Developer Column in *xTIMEcomposer* Studio on the right hand side of your screen provides information on the *xSOFTip* components you are using. Select one of the imported components in the Project Explorer, and you will see their description together with API documentation. Having done this, click the `back` icon until you return to this Quick Start Guide within the Developer Column.

|newpage|

Run the application
+++++++++++++++++++

When the application has been compiled, the next step is to run it on the Linux PC. Before doing that, make sure that the *SOMANET* EtherCAT nodes have been flashed with or are running a proper motor control software for the EtherCAT slave side, i.e. ``app_demo_slave_ethercat_motorcontrol``.  

   #. Make sure your EtherCAT Master is up and running. To start the Master on a Linux machine, execute the following command: ::

       sudo /etc/init.d/ethercat start

   #. Make sure your SOMANET nodes are accessible by the EtherCAT master by typing: ::

        ethercat slave 

      The output should indicate a presence of the SOMANET node and pre-operational state if the slave side software is running: ::

        0  0:0  PREOP  +  SNCN SOMANET COM ECAT
        1  0:1  PREOP  +  SNCN SOMANET COM ECAT

   #. Navigate with the terminal to your compiled application binary on the hard disk. Then execute the application with super user rights: ::

       sudo ./app_demo_master_cyclic_velocity_2_nodes 

   #. The application first will prompt to enter target velocity values for the two slaves in the setup one by one. Complete the entry by pressing Enter. Please try first some small values bellow a thousand. The application will not allow the motors to reach higher velocities than the defined in the motor configuration file maximum (4000 RPM). ::
       
       2 slaves are defined in the system
       enter target velocity for drive (slave) 1: 
       500
       enter target velocity for drive (slave) 2: 
       500

   #. After entering the target velocity values, the application will deploy the motor-specific configuration parameters over the EtherCAT and the rotors of the both motors will start rotating. The application can be interrupted at any time by the ``Ctrl + C`` keyboard interrupt sequence. In the terminal window you should be able to see the motor's feedback as current velocity, position, and torque of both motors: ::

       Velocity drive 1: 1336 Position drive 1: 595 Torque drive 1: 11.77
       Velocity drive 2: -1347 Position drive 2: -22317 Torque drive 2: 23.94

   #. The debug console window in *xTIMEcomposer* will not display any message because the demo application is written to work with an EtherCAT master application and feedback is therefore provided via EtherCAT communication.

|newpage|

Next steps
++++++++++

As a next step you can run another EtherCAT Master Motor Control Demo. Two more multi-node demo applications are offered for the Cyclic Synchronous Torque control mode (``app_demo_master_cyclic_torque_2_nodes``) and Cyclic Synchronous Position control mode (``app_demo_master_cyclic_position_2_nodes``).

Examine the code
................

   #. In *xTIMEcomposer* navigate to the ``src`` directory under ``app_demo_master_cyclic_velocity_2_nodes`` and double click on the ``main.c`` file within it. The file will open in the central editor window.

   #. Before the main function you see a global variable and an interrupt handling function. These are there only for handling interrupts when a user executes the ``Ctrl + C`` interrupt sequence. 

   #. For you convenience a user console input handling function ``read_user_input`` is included. 

   #. Now find and examine the main function. At the beginning you'll find variables declarations that will be used to define your desired motion profile and provide you feedback from the motor. The enumeration with ``ECAT_SLAVE_0`` and ``ECAT_SLAVE_1`` is used to address the two EtherCAT slave nodes based on the nodes' topology or on the slave nodes' alias.

   #. Before starting the main control routine you are required to initialize the EtherCAT master and to follow a motor starting state machine as defined in the CiA 402 directive (see the image bellow). These routines are performed for all connected nodes, except for the ``init_nodes`` function.

      .. figure:: images/statemachine.png
         :width: 100%
         :align: center

         Motor Control state machine

   #. ``init_master`` takes care of the EtherCAT communication initialization. In case of the multi-node system the EtherCAT nodes are configured from the ``ethercat_setup.h`` in the ``src`` directory. The default configuration allows you to get started with a two nodes setup without making any changes.

   #. The ``init_nodes`` routine will take care of loading your motor configurations into the slaves via EtherCAT. All slave nodes are running the same software and can be configured for using different motors from the master side. The motor configurations are included in the ``config`` folder, and the config files there have ``_N`` extensions to differentiate between various motors (N is a number starting from 1, e.g., ``bldc_motor_config_1.h``). When you specify a CONFIG_NUMBER in the ``SOMANET_C22_CTRLPROTO_SLAVE_HANDLES_ENTRY`` (defined in the ``ethercat_setup.h`` in your ``src`` folder), all corresponding configurations are being loaded to all the nodes. In case of this demo ``bldc_motor_config_1.h`` and ``bldc_motor_config_2.h`` configuration files are used.

   #. ``set_operation_mode`` defines the control mode to be used. In this example we are using the Cyclic Synchronous velocity mode (CSV) for both nodes.

   #. ``enable_operation`` is a part of the state machine control sequence as described above.

   #. After enabling the operation you should compute how many steps are required to perform the desired velocity profile. Call the ``init_velocity_profile_params`` function for that and provide it the desired motion profile parameters as arguments. 

   #. The ``signal`` function there is only for catching the ``Ctr + C`` process interrupt sequence. It can be freely removed when writing a custom motorcontrol application. 

   #. The motion control routine should be executed in a loop. The ``pdo_handle_ecat`` is a handler that takes care of a real-time information update over EtherCAT.  

   #. The computed prior steps are then used to calculate immediate velocity set-points at each step by calling the profile generator (``generate_profile_velocity``).  The immediate velocity set-points are then used as input for the velocity controller on the slave side (are sent over EtherCAT by the `set_velocity_rpm`` function call). We perform these cycles for all the nodes in the setup.

   #. When the profile motion is finished for both nodes the slaves will keep holding the last commanded target velocity value. The application can be interrupted with the ``Ctrl + C`` sequence. 

   #. To get the position, velocity and torque feedback from the controller the ``get_position_actual_ticks``, ``get_velocity_actual_rpm``, and ``get_torque_actual_mNm`` functions are used respectively.

   #. As an example for the steps of the state machine to be executed e.g. in case of emergency stop the methods as ``quick_stop_velocity``, ``renable_ctrl_quick_stop``, ``set_operation_mode``, ``enable_operation``, and ``shutdown_operation`` are included in the software and are executed when the user interrupts execution of the master application by pressing the ``Ctrl + C`` interrupt sequence. Please refer to the state machine diagram to include them properly when developing a custom application.

Examine the EtherCAT configuration file
.......................................

   #. Now please have a look at the ``ethercat_setup.h`` configuration file found in your ``src`` directory. It defines your multi-node EtherCAT setup.

   #. Define ``TOTAL_NUM_OF_SLAVES`` is used to tell the application how many slave nodes are included into your multi-slave setup. In this demo application we have two nodes.

   #. Two data structures have to be extended to enable multi-nodes data exchange. The ``ctrlproto_slv_handle`` structure has three paramters like ``ALIAS``, ``POSITION``, and ``CONFIG_NUMBER`` commented above. The alias and position parameters depend on your nodes topology, when the configuration number is your motor configuration file. In our case we have two motors with two configuration files ``bldc_motor_config_1.h`` and ``bldc_motor_config_2.h``. If the motor is the same, you can leave the same configuration number in both entries.

   #. The ``ec_pdo_entry_reg_t`` structure handles the domain entries for the PDOs. Again the alias and position parameters depend on your nodes topology, when the ``ARRAY POSITION`` entry defines the array position inside the ``slv_handles[]`` array and should be unique for each entry. 


