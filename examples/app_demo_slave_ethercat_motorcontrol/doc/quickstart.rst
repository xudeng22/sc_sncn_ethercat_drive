.. _SOMANET_EtherCAT_Slave_Motor_Control_Demo_Quickstart:

SOMANET EtherCAT Slave Motor Control Demo Quick Start Guide
===========================================================

This simple demonstration shows how to use ``module_ecat_drive``, which implements various motor control modes for EhterCAT enabled SOMANET node. It includes such control modes as:

* Cyclic Synchronous Positioning (CSP)
* Cyclic Synchronous Velocity (CSV)
* Cyclic Synchronous Torque (CST)

as well as profile modes:

* Profile Positioning Mode (PPM)
* Profile Velocity Mode (PVM)
* Profile Torque Mode (PTM)

All those control modes are to be selected from the master side and do not require any configuring on the slave side.

Hardware setup
++++++++++++++

A minimal requirement for this application to run is having the complete *SOMANET* stack assembled consisting of a *SOMANET Core-C22*, *SOMANET COM-EtherCAT*, *SOMANET* Core to xTAG-2 Debug Adapter, and a *SOMANET IFM Drive-DC100* modules.

.. note::  Once the application has been flashed, the *SOMANET Core* to xTAG-2 Debug Adapter will not be required.NOTE:

The stack should be powered via the *SOMANET IFM* board. An example of a stack consisting of the *SOMANET* COM-EtherCAT, Core-C22, Core to xTAG-2 Debug Adapter, and *IFM-Drive-DC100* boards is shown below. For the motor supplied with the kit required power supply voltage should be 24 Volts. For the best experience please make sure that your stabilized DC power supply is capable of delivering more that 2 Amperes of power. Please mind that at high motor accelerations starting current may be as high as 10 times the nominal.     

.. figure:: images/ethercat_stack.jpg
   :align: center

   Hardware Setup for SOMANET EtherCAT Slave Motor Control Demo

To setup the system:

   #. If you don't have the stack assembled, assemble it as shown in the image above. Make sure to connect the IFM side of the *SOMANET Core* module to the IFM-DC100 board and COM side to the Core Debug Adapter (see markings on the Core module)
   #. Connect the xTAG-2 Adapter to the Core Debug Adapter.
   #. Connect the xTAG-2 to host PC. 
   #. Connect the motor supplied with the kit as shown in the image bellow.
   #. Connect the *IFM-DC100* board to a 24 V DC power supply
   #. Connect one side of the Ethernet cable to the node and plug the RS-45 connector to your PC.
   #. Switch on the power supply. If everything is connected properly, drained current should not exceed 100mA. 

.. figure:: images/stack_and_motor.jpg
   :align: center

   Connecting the motor and cables to your kit


Import and build the application
++++++++++++++++++++++++++++++++

   #. Open *xTIMEcomposer* Studio and check that it is operating in online mode. Open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``'EtherCAT Motor Control CSP Demo'`` item in the *xSOFTip* pane on the bottom left of the window and drag it into the Project Explorer window in *xTIMEcomposer*. This will also cause the modules on which this application depends to be imported as well. 
   #. Click on the ``app_demo_slave_EtherCAT_motorcontrol`` item in the Project Explorer plane then click on the build icon (hammer) in *xTIMEcomposer*. Check the Console window to verify that the application has built successfully. 

For help in using *xTIMEcomposer*, try the *xTIMEcomposer* tutorial, which you can find by selecting Help->Tutorials from the *xTIMEcomposer* menu.

Note that the Developer Column in *xTIMEcomposer* Studio on the right hand side of your screen provides information on the *xSOFTip* components you are using. Select the ``sw_sncn_motorcontrol_EtherCAT_kit`` component in the Project Explorer, and you will see its description together with API documentation. Having done this, click the `back` icon until you return to this Quick Start Guide within the Developer Column.


Run the application
+++++++++++++++++++

When the application has been compiled, the next step is to run it on the *SOMANET Core* module using the tools to load the application over JTAG (via the xTAG-2 and Core Debug Adapter) into the xCORE multi-core micro-controller.

   #. Select the file ``demo-slave-EtherCAT-motorcontrol.xc`` in the ``app_demo_EtherCAT_motorcontrol`` project from the Project Explorer.
   #. Click on the ``Run`` icon (the white arrow in the green circle). 
   #. At the ``Select Device`` dialog, select ``XMOS xTAG-2 connect to L1[0..3]`` and click ``OK``.
   #. The debug console window in *xTIMEcomposer* will not display any message because the demo application is written to work with an EtherCAT master application and feedback is therefore provided via EtherCAT communication.
   #. Keep the stack powered and the application running until the next steps.


Next steps
++++++++++

As a next step you should run a Master motor control application for the motor to move. Currently three control modes are offered for the user to try:  Cyclic Synchronous Positioning (``app_demo_master_cyclic_position``), Cyclic Synchronous Velocity (``app_demo_master_cyclic_velocity``), and Cyclic Synchronous Torque (``app_demo_master_cyclic_torque``). Please refer to quick starting guides of those apps for further instructions.

You can also flash the node with this firmware. In this case for master applications to use you won't need the *SOMANET Core* to xTAG-2 Debug Adapter. The motors and controller settings are loaded to the slave controller from the master side.

Examine the code
................

#. In *xTIMEcomposer* navigate to the ``src`` directory under ``app_demo_EtherCAT_motorcontrol`` and double click on the ``demo-slave-EtherCAT-motorcontrol.xc`` file within it. The file will open in the central editor window.

#. Find the main function and note that application runs two logical cores on the COM_TILE (tile 0) for EtherCAT communication and firmware update, one logical core on tile 1 for the main motor drive loop, three cores on tile 2 for selectable control loops, and seven cores on the IFM_TILE for commutation, watchdog, and motor feedback sensor servers.

#. Core 1: EtherCAT Communication Handler. This core must be run on COM_TILE since this is only tile accessing the EtherCAT communication module (COM).

   ::
    
     ecat_handler(coe_out, coe_in, eoe_out, eoe_in, eoe_sig, foe_out, foe_in, pdo_out, pdo_in);

#. Core 2: Firmware update. This core must be run on COM_TILE since it has access to the flash SPI ports.

   ::

     firmware_update_loop(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, c_sig_1);

#. Core 3: EtherCAT Motor Drive Loop. This core can run on any tile as it doesn't need access to any ports of the XMOS chip. The application acts as a bridge between the EtherCAT communication and the actual controllers allowing the user to freely select a desired control mode. It also takes care of updating the motor configurations via EtherCAT (using SDOs) for proper control functionality.

   ::

     ecat_motor_drive(pdo_out, pdo_in, coe_out, c_signal, c_hall_p5, c_qei_p5, c_torque_ctrl, c_velocity_ctrl, c_position_ctrl, c_gpio_p1);

#. Core 4: Position Control Loop. This is the main position control loop server for cyclic positioning control mode. Some parameters have to be initialized prior starting the controller.

   ::
  
     position_control(position_ctrl_params, hall_params, qei_params, SENSOR_USED, c_hall_p4, c_qei_p4, c_position_ctrl, c_commutation_p3);

#. Core 5: Velocity Control Loop. This is the main velocity control loop server for cyclic velocity control mode. Some parameters have to be initialized prior starting the controller.

   ::

     velocity_control(velocity_ctrl_params, sensor_filter_params, hall_params, qei_params, SENSOR_USED, c_hall_p3, c_qei_p3, c_velocity_ctrl, c_commutation_p2);

#. Core 6: Torque Control Loop. This is the main torque control loop server for cyclic torque control mode. Some parameters have to be initialized prior starting the controller.

   ::

     torque_control( torque_ctrl_params, hall_params, qei_params, SENSOR_USED, c_adc, c_commutation_p1, c_hall_p2,c_qei_p2, c_torque_ctrl);

#. Core 7: ADC loop. It implements the ADC server for the AD7949 ADC used on the *SOMANET IFM Drive* boards.

   ::

     adc_ad7949_triggered(c_adc, c_adctrig, clk_adc, p_ifm_adc_sclk_conv_mosib_mosia, p_ifm_adc_misoa, p_ifm_adc_misob);

#. Core 8: PWM Loop. It implements the PWM Server.

   ::

     do_pwm_inv_triggered(c_pwm_ctrl, c_adctrig, p_ifm_dummy_port, p_ifm_motor_hi, p_ifm_motor_lo, clk_pwm);

#. Core 8: Motor Commutation loop. The main commutation loop that implements sinusoidal commutation. Some parameters have to be initialized prior starting the loop.

   ::
  
     commutation_sinusoidal(c_hall_p1,  c_qei_p1, c_signal, c_watchdog, c_commutation_p1, c_commutation_p2, c_commutation_p3, c_pwm_ctrl, p_ifm_esf_rstn_pwml_pwmh, p_ifm_coastn, p_ifm_ff1, p_ifm_ff2,     hall_params, qei_params, commutation_params);


#. Core 9: Watchdog Server. In case of application crash to prevent the hardware damages this server is required to constantly run. If the server is not running, the motor phases are disabled and no motor commutation is possible.

   ::

     run_watchdog(c_watchdog, p_ifm_wd_tick, p_ifm_shared_leds_wden);

#. Core 10: GPIO Digital Server. The server provides a possibility to read states of four GPIOs available on the *SOMANET IFM Drive* boards connectors.

   ::

     gpio_digital_server(p_ifm_ext_d, c_gpio_p1, c_gpio_p2);


#. Core 11: Hall Server. Reads states of the motor Hall feedback sensor and calculates velocity and incremental position. Some parameters have to be initialized prior starting the server.

   ::

     run_hall(c_hall_p1, c_hall_p2, c_hall_p3, c_hall_p4, c_hall_p5, c_hall_p6, p_ifm_hall, hall_params); 

#. Core 12: QEI Server. Reads states of an incremental encoder feedback sensor in a quadrature mode and calculates velocity and incremental position. Some parameters have to be initialized prior starting the server.

   ::

     run_qei(c_qei_p1, c_qei_p2, c_qei_p3, c_qei_p4, c_qei_p5, c_qei_p6, p_ifm_encoder, qei_params);  

NOTE: The user is not intended to change this application to use various EtherCAT-based controls as all configuration and controllers selection are performed form the master side.


