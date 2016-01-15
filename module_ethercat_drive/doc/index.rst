=============================
SOMANET EtherCAT Drive Module
=============================

.. contents:: In this document
    :backlinks: none
    :depth: 3

How to use
==========

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>`, :ref:`SOMANET Motor Control <somanet_motor_control>`, and :ref:`SOMANET EtherCAT <somanet_ethercat>` libraries. And therefore, your app includes the required **board support** files for your SOMANET device, and the required Motor Control and EtherCAT Services. 

.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/master/module_ethercat_drive>`_
          
.. seealso:: 
    You might find useful the :ref:`EtherCAT Drive Slave Firmware <ethercat_slave_demo>` example app, which illustrate the use of this module. 
    
1. First, add the **SOMANET EtherCAT Drive** module to your app Makefile.

    ::

        USED_MODULES = module_ethercat_drive module_adc module_board-support module_ctrl_loops module_ethercat module_ethercat_fwupdate module_gpio module_hall module_misc module_motorcontrol module_profile module_pwm_symmetrical module_qei module_watchdog

    .. note:: Not all modules will be required, but when using a library it is recommended to include always all the contained modules. 
              This will help solving internal dependency issues.

2. Include the Service header in your app. 
3. Properly instanciate an **EtherCAT Drive Service**. For that, first you will have to fill up the Profiler configuration and provide channels/interfaces to the EtherCAT, Hall, Encoder, GPIO, Motor Control and Control Loop Services.

    .. code-block:: C

        #include <COM_ECAT-rev-a.bsp>   //Board Support file for SOMANET COM EtherCAT device 
        #include <CORE_C22-rev-a.bsp>   //Board Support file for SOMANET Core C22 device 
        #include <IFM_DC100-rev-b.bsp>  //Board Support file for SOMANET IFM DC100 device 
                                        //(select your board support files according to your device)

        #include <pwm_service.h>
        #include <qei_service.h>
        #include <hall_service.h>
        #include <watchdog_service.h>
        #include <adc_service.h>
        #include <motorcontrol_service.h>
        #include <gpio_service.h>

        #include <velocity_ctrl_service.h>
        #include <position_ctrl_service.h>
        #include <torque_ctrl_service.h>
        #include <profile_control.h>

        #include <ethercat_drive_service.h> // 2

        #include <ethercat_service.h>
        #include <fw_update_service.h>

        EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;
        PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
        WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
        ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
        FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
        HallPorts hall_ports = SOMANET_IFM_HALL_PORTS;
        QEIPorts qei_ports = SOMANET_IFM_QEI_PORTS;
        port gpio_ports[4] = {  SOMANET_IFM_GPIO_D0,
                                SOMANET_IFM_GPIO_D1,
                                SOMANET_IFM_GPIO_D2,
                                SOMANET_IFM_GPIO_D3 };

        int main(void)
        {
            chan c_adctrig, c_pwm_ctrl;

            interface GPIOInterface i_gpio[1];
            interface WatchdogInterface i_watchdog[2];
            interface ADCInterface i_adc[2];
            interface HallInterface i_hall[5];
            interface QEIInterface i_qei[5];
            interface MotorcontrolInterface i_motorcontrol[5];

            interface TorqueControlInterface i_torque_control[3];
            interface PositionControlInterface i_position_control[3];
            interface VelocityControlInterface i_velocity_control[3];

            /* EtherCat Communication channels */
            chan coe_in;          // CAN from module_ethercat to consumer
            chan coe_out;         // CAN from consumer to module_ethercat
            chan eoe_in;          // Ethernet from module_ethercat to consumer
            chan eoe_out;         // Ethernet from consumer to module_ethercat
            chan eoe_sig;
            chan foe_in;          // File from module_ethercat to consumer
            chan foe_out;         // File from consumer to module_ethercat
            chan pdo_in;
            chan pdo_out;
            chan c_nodes[1], c_flash_data; // Firmware channels

            par
            { 
                on tile[COM_TILE] : ethercat_service(coe_out, coe_in, eoe_out, eoe_in, eoe_sig,
                                                        foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
                
                on tile[COM_TILE] : fw_update_service(p_spi_flash, foe_out, foe_in, c_flash_data, 
                                                        c_nodes, null);
                
                on tile[APP_TILE_1] :
                {
                    ProfilerConfig profiler_config;
                    profiler_config.polarity = 1;
                    profiler_config.max_position = 128000000;
                    profiler_config.min_position = -128000000;
                    profiler_config.max_velocity = 5000;
                    profiler_config.max_acceleration = 10000;
                    profiler_config.max_deceleration = 10000;
                    profiler_config.max_current_slope = 1000;
                    profiler_config.max_current = 7000;

                    ethercat_drive_service( profiler_config,
                                                pdo_out, pdo_in, coe_out,
                                                i_motorcontrol[3], i_hall[4], 
                                                i_qei[4], i_gpio[0], i_torque_control[0], 
                                                i_velocity_control[0], i_position_control[0]); // 3
                }

                on tile[APP_TILE_2]:
                {
                    par
                    {
                        {
                             ControlConfig position_control_config;
                             position_control_config.feedback_sensor = QEI_SENSOR;
                             position_control_config.Kp_n = 100;    
                             position_control_config.Ki_n = 10;    
                             position_control_config.Kd_n = 0;    
                             position_control_config.control_loop_period = 60;
                             position_control_service(position_control_config, i_hall[1], i_qei[1], 
                                                        i_motorcontrol[0], i_position_control);
                        }

                        {
                            ControlConfig velocity_control_config;
                            velocity_control_config.feedback_sensor = QEI_SENSOR;
                            velocity_control_config.Kp_n = 100;
                            velocity_control_config.Ki_n = 10;
                            velocity_control_config.Kd_n = 0;
                            velocity_control_config.control_loop_period =  60;
                            velocity_control_service(velocity_control_config, i_hall[2], i_qei[2], 
                                                        i_motorcontrol[1], i_velocity_control);
                        }

                        {
                            ControlConfig torque_control_config;
                            torque_control_config.feedback_sensor = QEI_SENSOR;
                            torque_control_config.Kp_n = 100;
                            torque_control_config.Ki_n = 10;
                            torque_control_config.Kd_n = 0;
                            torque_control_config.control_loop_period = 100; 
                            torque_control_service(torque_control_config, i_adc[0], i_hall[3], i_qei[3], 
                                                        i_motorcontrol[2], i_torque_control);
                        }
                    }
                }

                on tile[IFM_TILE]:
                {
                    par
                    {
                        adc_service(adc_ports, c_adctrig, i_adc);
                        pwm_triggered_service(pwm_ports, c_adctrig, c_pwm_ctrl);
                        watchdog_service(wd_ports, i_watchdog);
                        gpio_service(gpio_ports, i_gpio);

                        {
                            HallConfig hall_config;
                            hall_config.pole_pairs = 1;
                            hall_service(hall_ports, hall_config, i_hall);
                        }

                        {
                             QEIConfig qei_config;
                             qei_config.signal_type = QEI_RS422_SIGNAL;        
                             qei_config.index_type = QEI_WITH_INDEX;          
                             qei_config.ticks_resolution = 4000;    
                             qei_config.sensor_polarity = 1;       
                             qei_service(qei_ports, qei_config, i_qei);
                        }

                        {
                             MotorcontrolConfig motorcontrol_config;
                             motorcontrol_config.motor_type = BLDC_MOTOR;
                             motorcontrol_config.commutation_sensor = HALL_SENSOR;
                             motorcontrol_config.bldc_winding_type = STAR_WINDING;
                             motorcontrol_config.hall_offset[0] =  0;
                             motorcontrol_config.hall_offset[1] = 0;
                             motorcontrol_config.commutation_loop_period =  60;
                             motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                                     c_pwm_ctrl, i_hall[0], i_qei[0], 
                                                     i_watchdog[0], i_motorcontrol);
                        }
                    }
                }
            }

            return 0;
        }

API
===


.. doxygenfunction:: ethercat_drive_service
.. doxygenfunction:: ctrlproto_protocol_handler_function
.. doxygenfunction:: init_ctrl_proto
.. doxygenfunction:: config_sdo_handler
.. doxygenfunction:: sensor_select_sdo
.. doxygenfunction:: qei_sdo_update
.. doxygenfunction:: hall_sdo_update
.. doxygenfunction:: commutation_sdo_update
.. doxygenfunction:: homing_sdo_update
.. doxygenfunction:: pt_sdo_update
.. doxygenfunction:: pv_sdo_update
.. doxygenfunction:: pp_sdo_update
.. doxygenfunction:: cst_sdo_update
.. doxygenfunction:: csv_sdo_update
.. doxygenfunction:: csp_sdo_update
.. doxygenfunction:: torque_sdo_update
.. doxygenfunction:: velocity_sdo_update
.. doxygenfunction:: position_sdo_update
.. doxygenfunction:: speed_sdo_update
