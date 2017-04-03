.. module_canopen_interface:

=============================
CANopen Interface Module
=============================

.. contents:: In this document
    :backlinks: none
    :depth: 3

This module provides a service between any communication stack and CANopen applications. This service is managing the Object Dictionary and the PDO handling.


.. cssclass:: github

  `See Module on Public Repository <https://github.com/synapticon/sc_sncn_ethercat_drive/tree/develop/module_canopen_interface>`
 
How to use CANopen Interface Service
====================================

.. important:: We assume that you are using :ref:`SOMANET Base <somanet_base>`, :ref:`SOMANET Motor Control <somanet_motor_control>` libraries 
   and one of our communication stacks (:ref:`SOMANET EtherCAT <somanet_ethercat>`, :ref:`SOMANET Ethernet <somanet_ethernet>` or :ref:`SOMANET CAN <somanet_can>`). And therefore, your app includes the required **board support** files for your SOMANET device, and the required Motor Control and Communication Stack Services. 
         
.. seealso:: You might find useful the :ref:`EtherCAT Drive Slave Firmware <ethercat_slave_demo>` example app, which illustrate the use of this module. 
    
1. First, add the **SOMANET CANopen Service** module to your app Makefile.

    ::

        USED_MODULES = config_motor lib_bldc_torque_control lib_can lib_canopen module_adc module_biss module_board-support module_canopen_interface module_controllers module_filters module_flash_service module_gpio module_hall module_misc module_motion_control module_network_drive module_position_feedback module_profile module_pwm module_qei module_reboot module_rem_14 module_rem_16mt module_serial_encoder module_shared_memory module_spi_master module_watchdog


    .. note:: Not all modules will be required, but when using a library it is recommended to include always all the contained modules. 
              This will help solving internal dependency issues.

2. Include the Network Drive Service header **network_drive_service.h** in your app. 
3. Properly instantiate an **EtherCAT Drive Service**. For that, first you will have to fill up the Profiler configuration and provide channels/interfaces to the EtherCAT, Hall, Encoder, GPIO, Motor Control and Control Loop Services.

    .. code-block:: c

        #include <COM_ECAT-rev-a.bsp>   //Board Support file for SOMANET COM EtherCAT device 
        #include <CORE_C22-rev-a.bsp>   //Board Support file for SOMANET Core C22 device 
        #include <IFM_DC100-rev-b.bsp>  //Board Support file for SOMANET IFM DC100 device 
                                        //(select your board support files according to your device)

        #include <user_config.h>
        
        #include <network_drive_service.h>
        #include <canopen_service.h>

        
        //BLDC Motor drive libs
        #include <position_feedback_service.h>
        #include <pwm_server.h>
        #include <adc_service.h>
        #include <watchdog_service.h>
        #include <motor_control_interfaces.h>
        #include <advanced_motor_control.h>
        
        //Position control + profile libs
        #include <motion_control_service.h>
        #include <profile_control.h>
        
        #include <flash_service.h>
        #include <reboot.h>
        
        CANPorts can_ports = SOMANET_COM_CAN_PORTS;
        CANClock can_clock = SOMANET_COM_CAN_CLOCK;
        on tile[0]: port mode_select = SOMANET_COM_CAN_MODE_SELECT;
        PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
        WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
        ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
        FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
        QEIHallPort qei_hall_port_1 = SOMANET_IFM_HALL_PORTS;
        QEIHallPort qei_hall_port_2 = SOMANET_IFM_QEI_PORTS;
        HallEncSelectPort hall_enc_select_port = SOMANET_IFM_QEI_PORT_INPUT_MODE_SELECTION;
        SPIPorts spi_ports = SOMANET_IFM_SPI_PORTS;
        port ?gpio_port_0 = SOMANET_IFM_GPIO_D0;
        port ?gpio_port_1 = SOMANET_IFM_GPIO_D1;
        port ?gpio_port_2 = SOMANET_IFM_GPIO_D2;
        port ?gpio_port_3 = SOMANET_IFM_GPIO_D3;
        
        
        int main(void)
        {
            /* Motor control channels */
            interface WatchdogInterface i_watchdog[2];
            interface update_pwm i_update_pwm;
            interface update_brake i_update_brake;
            interface ADCInterface i_adc[2];
            interface MotorcontrolInterface i_motorcontrol[2];
            interface PositionVelocityCtrlInterface i_position_control[3];
            interface PositionFeedbackInterface i_position_feedback_1[3];
            interface PositionFeedbackInterface i_position_feedback_2[3];
            interface shared_memory_interface i_shared_memory[3];
        
            /* Flash-Service interfaces */
            FlashBootInterface i_flash_boot;
            FlashDataInterface i_flash_data[1];
        
            /* Reboot interface */
            RebootInterface i_reboot;
        
        
            /* CAN Open Communication channels */
            interface i_co_communication i_co[3];
        
            par
            {
                /************************************************************
                 *                          COM_TILE
                 ************************************************************/
        
                /* EtherCAT Communication Handler Loop */
                on tile[COM_TILE] :
                {
                    par
                    {
                        {
                            CANTimings can_timings = CAN_BAUDRATE_1000K_TIMINGS;
        
        
                            can_service(i_co, can_ports, can_clock, mode_select, can_timings, 16, i_flash_data[0], i_reboot);
                        }
        
                        {
                            flash_service(p_spi_flash, i_flash_boot, i_flash_data, 1);
                        }
        
                        {
                            reboot_service(i_reboot);
                        }
                    }
                }
        
                /* EtherCAT Motor Drive Loop */
                on tile[APP_TILE_1] :
                {
                    par
                    {
                        {
                            ProfilerConfig profiler_config;
        
                            profiler_config.polarity = MOTOR_PHASES_NORMAL;        /* Set by Object Dictionary value! */
                            profiler_config.max_position = MAX_POSITION_RANGE_LIMIT;   /* Set by Object Dictionary value! */
                            profiler_config.min_position = MIN_POSITION_RANGE_LIMIT;   /* Set by Object Dictionary value! */
        
                            profiler_config.max_velocity = MAX_MOTOR_SPEED;
                            profiler_config.max_acceleration = MAX_ACCELERATION;
                            profiler_config.max_deceleration = MAX_ACCELERATION;
        
                #if 0
        
                            network_drive_service_debug( profiler_config,
                                                    i_co[1],
                                                    i_motorcontrol[0],
                                                    i_position_control[0], i_position_feedback_1[0]);
                #else
                            network_drive_service( profiler_config,
                                                    i_co[1],
                                                    i_motorcontrol[0],
                                                    i_position_control[0], i_position_feedback_1[0], null);
                #endif
                        }
                    }
                }
        
                on tile[APP_TILE_2]:
                {
                    par
                    {
                        /* Position Control Loop */
                        {
                            MotionControlConfig pos_velocity_ctrl_config;
        
                            pos_velocity_ctrl_config.min_pos_range_limit =                  MIN_POSITION_RANGE_LIMIT;
                            pos_velocity_ctrl_config.max_pos_range_limit =                  MAX_POSITION_RANGE_LIMIT;
                            pos_velocity_ctrl_config.max_motor_speed =                      MAX_MOTOR_SPEED;
                            pos_velocity_ctrl_config.max_torque =                           TORQUE_CONTROL_LIMIT;
                            pos_velocity_ctrl_config.polarity =                             POLARITY;
        
                            pos_velocity_ctrl_config.enable_profiler =                      ENABLE_PROFILER;
                            pos_velocity_ctrl_config.max_acceleration_profiler =            MAX_ACCELERATION_PROFILER;
                            pos_velocity_ctrl_config.max_speed_profiler =                   MAX_SPEED_PROFILER;
        
                            pos_velocity_ctrl_config.position_control_strategy =            POS_PID_CONTROLLER;//NL_POSITION_CONTROLLER;
        
                            pos_velocity_ctrl_config.position_kp =                                POSITION_Kp;
                            pos_velocity_ctrl_config.position_ki =                                POSITION_Ki;
                            pos_velocity_ctrl_config.position_kd =                                POSITION_Kd;
                            pos_velocity_ctrl_config.position_integral_limit =                   POSITION_INTEGRAL_LIMIT;
                            pos_velocity_ctrl_config.moment_of_inertia =                    MOMENT_OF_INERTIA;
        
                            pos_velocity_ctrl_config.velocity_kp =                           VELOCITY_Kp;
                            pos_velocity_ctrl_config.velocity_ki =                           VELOCITY_Ki;
                            pos_velocity_ctrl_config.velocity_kd =                           VELOCITY_Kd;
                            pos_velocity_ctrl_config.velocity_integral_limit =              VELOCITY_INTEGRAL_LIMIT;
        
                            pos_velocity_ctrl_config.special_brake_release =                ENABLE_SHAKE_BRAKE;
                            pos_velocity_ctrl_config.brake_shutdown_delay =                 BRAKE_SHUTDOWN_DELAY;
        
                            //select resolution of sensor used for motion control
                            if (SENSOR_2_FUNCTION == SENSOR_FUNCTION_COMMUTATION_AND_MOTION_CONTROL || SENSOR_2_FUNCTION == 
                                SENSOR_FUNCTION_MOTION_CONTROL) {
                                pos_velocity_ctrl_config.resolution  =                          SENSOR_2_RESOLUTION;
                            } else {
                                pos_velocity_ctrl_config.resolution  =                          SENSOR_1_RESOLUTION;
                            }
        
                            pos_velocity_ctrl_config.dc_bus_voltage=                        DC_BUS_VOLTAGE;
                            pos_velocity_ctrl_config.pull_brake_voltage=                    PULL_BRAKE_VOLTAGE;
                            pos_velocity_ctrl_config.pull_brake_time =                      PULL_BRAKE_TIME;
                            pos_velocity_ctrl_config.hold_brake_voltage =                   HOLD_BRAKE_VOLTAGE;
        
                             motion_control_service(APP_TILE_USEC, pos_velocity_ctrl_config, i_motorcontrol[1], 
                             i_position_control, i_update_brake);
                        }
                    }
                }
        
                /************************************************************
                 *                          IFM_TILE
                 ************************************************************/
                on tile[IFM_TILE]:
                {
                    par
                    {
                        /* PWM Service */
                        {
                            pwm_config(pwm_ports);
        
                            if (!isnull(fet_driver_ports.p_esf_rst_pwml_pwmh) && !isnull(fet_driver_ports.p_coast))
                                predriver(fet_driver_ports);
        
                            //pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                            pwm_service_task(MOTOR_ID, pwm_ports, i_update_pwm,
                                    i_update_brake, IFM_TILE_USEC);
        
                        }
        
                        /* ADC Service */
                        {
                            adc_service(adc_ports, i_adc /*ADCInterface*/, i_watchdog[1], IFM_TILE_USEC, SINGLE_ENDED);
                        }
        
                        /* Watchdog Service */
                        {
                            watchdog_service(wd_ports, i_watchdog, IFM_TILE_USEC);
                        }
        
                        /* Motor Control Service */
                        {
                            MotorcontrolConfig motorcontrol_config;
        
                            motorcontrol_config.v_dc =  DC_BUS_VOLTAGE;
                            motorcontrol_config.phases_inverted = MOTOR_PHASES_NORMAL;
                            motorcontrol_config.torque_P_gain =  TORQUE_P_VALUE;
                            motorcontrol_config.torque_I_gain =  TORQUE_I_VALUE;
                            motorcontrol_config.torque_D_gain =  TORQUE_D_VALUE;
                            motorcontrol_config.pole_pairs =  MOTOR_POLE_PAIRS;
                            motorcontrol_config.commutation_sensor=SENSOR_1_TYPE;
                            motorcontrol_config.commutation_angle_offset=COMMUTATION_ANGLE_OFFSET;
                            motorcontrol_config.hall_state_angle[0]=HALL_STATE_1_ANGLE;
                            motorcontrol_config.hall_state_angle[1]=HALL_STATE_2_ANGLE;
                            motorcontrol_config.hall_state_angle[2]=HALL_STATE_3_ANGLE;
                            motorcontrol_config.hall_state_angle[3]=HALL_STATE_4_ANGLE;
                            motorcontrol_config.hall_state_angle[4]=HALL_STATE_5_ANGLE;
                            motorcontrol_config.hall_state_angle[5]=HALL_STATE_6_ANGLE;
                            motorcontrol_config.max_torque =  MOTOR_MAXIMUM_TORQUE;
                            motorcontrol_config.phase_resistance =  MOTOR_PHASE_RESISTANCE;
                            motorcontrol_config.phase_inductance =  MOTOR_PHASE_INDUCTANCE;
                            motorcontrol_config.torque_constant =  MOTOR_TORQUE_CONSTANT;
                            motorcontrol_config.current_ratio =  CURRENT_RATIO;
                            motorcontrol_config.voltage_ratio =  VOLTAGE_RATIO;
                            motorcontrol_config.rated_current =  MOTOR_RATED_CURRENT;
                            motorcontrol_config.rated_torque  =  MOTOR_RATED_TORQUE;
                            motorcontrol_config.percent_offset_torque =  APPLIED_TUNING_TORQUE_PERCENT;
                            motorcontrol_config.protection_limit_over_current =  PROTECTION_MAXIMUM_CURRENT;
                            motorcontrol_config.protection_limit_over_voltage =  PROTECTION_MAXIMUM_VOLTAGE;
                            motorcontrol_config.protection_limit_under_voltage = PROTECTION_MINIMUM_VOLTAGE;
        
                            motor_control_service(motorcontrol_config, i_adc[0], i_shared_memory[2],
                                    i_watchdog[0], i_motorcontrol, i_update_pwm, IFM_TILE_USEC);
                        }
        
                        /* Shared memory Service */
                        [[distribute]] shared_memory_service(i_shared_memory, 3);
        
                        /* Position feedback service */
                        {
                            PositionFeedbackConfig position_feedback_config;
                            position_feedback_config.sensor_type = SENSOR_1_TYPE;
                            position_feedback_config.resolution  = SENSOR_1_RESOLUTION;
                            position_feedback_config.polarity    = SENSOR_1_POLARITY;
                            position_feedback_config.velocity_compute_period = SENSOR_1_VELOCITY_COMPUTE_PERIOD;
                            position_feedback_config.pole_pairs  = MOTOR_POLE_PAIRS;
                            position_feedback_config.ifm_usec    = IFM_TILE_USEC;
                            position_feedback_config.max_ticks   = SENSOR_MAX_TICKS;
                            position_feedback_config.offset      = 0;
                            position_feedback_config.sensor_function = SENSOR_1_FUNCTION;
        
                            position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                            position_feedback_config.biss_config.filling_bits = BISS_FILLING_BITS;
                            position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                            position_feedback_config.biss_config.clock_frequency = BISS_CLOCK_FREQUENCY;
                            position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                            position_feedback_config.biss_config.busy = BISS_BUSY;
                            position_feedback_config.biss_config.clock_port_config = BISS_CLOCK_PORT;
                            position_feedback_config.biss_config.data_port_number = BISS_DATA_PORT_NUMBER;
        
                            position_feedback_config.rem_16mt_config.filter = REM_16MT_FILTER;
        
                            position_feedback_config.rem_14_config.hysteresis     = REM_14_SENSOR_HYSTERESIS ;
                            position_feedback_config.rem_14_config.noise_setting  = REM_14_SENSOR_NOISE;
                            position_feedback_config.rem_14_config.dyn_angle_comp = REM_14_SENSOR_DAE;
                            position_feedback_config.rem_14_config.abi_resolution = REM_14_SENSOR_ABI_RES;
        
                            position_feedback_config.qei_config.index_type  = QEI_SENSOR_INDEX_TYPE;
                            position_feedback_config.qei_config.signal_type = QEI_SENSOR_SIGNAL_TYPE;
                            position_feedback_config.qei_config.port_number = QEI_SENSOR_PORT_NUMBER;
        
                            position_feedback_config.hall_config.port_number = HALL_SENSOR_PORT_NUMBER;
        
                            //setting second sensor
                            PositionFeedbackConfig position_feedback_config_2 = position_feedback_config;
                            position_feedback_config_2.sensor_type = 0;
                            if (SENSOR_2_FUNCTION != SENSOR_FUNCTION_DISABLED) //enable second sensor
                            {
                                position_feedback_config_2.sensor_type = SENSOR_2_TYPE;
                                position_feedback_config_2.polarity    = SENSOR_2_POLARITY;
                                position_feedback_config_2.resolution  = SENSOR_2_RESOLUTION;
                                position_feedback_config_2.velocity_compute_period = SENSOR_2_VELOCITY_COMPUTE_PERIOD;
                                position_feedback_config_2.sensor_function = SENSOR_2_FUNCTION;
                            }
        
                            position_feedback_service(qei_hall_port_1, qei_hall_port_2, hall_enc_select_port, spi_ports, 
                                    gpio_port_0, gpio_port_1, gpio_port_2, gpio_port_3,
                                    position_feedback_config, i_shared_memory[0], i_position_feedback_1,
                                    position_feedback_config_2, i_shared_memory[1], i_position_feedback_2);
                        }
                    }
                }
            }


API
===


.. doxygeninterface:: canopen_interface_service
.. doxygeninterface:: pdo_in
.. doxygeninterface:: pdo_out
.. doxygeninterface:: pdo_exchange_app
.. doxygeninterface:: pdo_init
.. doxygeninterface:: od_set_object_value
.. doxygeninterface:: od_get_object_value
.. doxygeninterface:: od_get_object_value_buffer
.. doxygeninterface:: od_set_object_value_buffer
.. doxygeninterface:: od_get_entry_description
.. doxygeninterface:: od_get_all_list_length
.. doxygeninterface:: od_get_list
.. doxygeninterface:: od_get_object_description
.. doxygeninterface:: od_get_data_length
.. doxygeninterface:: od_get_access
.. doxygeninterface:: configuration_ready
.. doxygeninterface:: configuration_done
.. doxygeninterface:: configuration_get
.. doxygeninterface:: speed_sdo_update
