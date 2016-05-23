/* INCLUDE BOARD SUPPORT FILES FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C22-rev-a.bsp>
#include <IFM_BOARD_REQUIRED>

/**
 * @file test_ethercat-mode.xc
 * @brief Test illustrates usage of Motor Control with EtherCAT
 * @author Synapticon GmbH (www.synapticon.com)
 */
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

#include <ethercat_drive_service.h>

#include <ethercat_service.h>
#include <fw_update_service.h>
#include <memory_manager.h>

// Please configure your slave's default motorcontrol parameters in config_motor_slave/user_config.h.
// These parameter will be eventually overwritten by the app running on the EtherCAT master
#include <user_config.h>

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;
PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
HallPorts hall_ports = SOMANET_IFM_HALL_PORTS;
#if(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
QEIPorts qei_ports = SOMANET_IFM_QEI_PORTS;
#elif (MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
AMSPorts ams_ports = SOMANET_IFM_AMS_PORTS;
#elif (MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
BISSPorts biss_ports = SOMANET_IFM_BISS_PORTS;
#endif
#if(MOTOR_FEEDBACK_SENSOR != BISS_SENSOR && MOTOR_FEEDBACK_SENSOR != AMS_SENSOR)
port gpio_ports[4] = { SOMANET_IFM_GPIO_D0,
                       SOMANET_IFM_GPIO_D1,
                       SOMANET_IFM_GPIO_D2,
                       SOMANET_IFM_GPIO_D3 };
#endif


int main(void)
{
    /* Motor control channels */
    chan c_adctrig, c_pwm_ctrl;

    interface WatchdogInterface i_watchdog[2];
    interface ADCInterface i_adc[2];
    interface HallInterface i_hall[5];
    interface MotorcontrolInterface i_motorcontrol[4];
#if(MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
    interface BISSInterface i_biss[5];
#elif(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
    interface QEIInterface i_qei[5];
    interface GPIOInterface i_gpio[1];
#elif (MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
    interface AMSInterface i_ams[5];
#else
    interface GPIOInterface i_gpio[1];
#endif

    interface shared_memory_interface i_shared_memory[2];
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
        /************************************************************
         *                          COM_TILE
         ************************************************************/

        /* EtherCAT Communication Handler Loop */
        on tile[COM_TILE] :
        {
            ethercat_service(coe_out, coe_in, eoe_out, eoe_in, eoe_sig,
                                foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
        }

        /* Firmware Update Loop over EtherCAT */
        on tile[COM_TILE] :
        {
            fw_update_service(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, null);
        }

        /* EtherCAT Motor Drive Loop */
        on tile[APP_TILE_1] :
        {
            ProfilerConfig profiler_config;

            profiler_config.polarity = POLARITY;
            profiler_config.max_position = MAX_POSITION_LIMIT;
            profiler_config.min_position = MIN_POSITION_LIMIT;

            profiler_config.max_velocity = MAX_VELOCITY;
            profiler_config.max_acceleration = MAX_ACCELERATION;
            profiler_config.max_deceleration = MAX_ACCELERATION;

            profiler_config.max_current_slope = MAX_CURRENT_VARIATION;
            profiler_config.max_current = MAX_CURRENT;

#if(MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, coe_out,
                                    i_motorcontrol[3], null, null, i_biss[4], null, null,
                                    null, i_velocity_control[0], i_position_control[0]);
#elif(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, coe_out,
                                    i_motorcontrol[3], i_hall[4], i_qei[4], null, null, i_gpio[0],
                                    null, i_velocity_control[0], i_position_control[0]);
#elif(MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, coe_out,
                                    i_motorcontrol[3], null, null, null, i_ams[4], null,
                                    null, i_velocity_control[0], i_position_control[0]);
#else
            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, coe_out,
                                    i_motorcontrol[3], i_hall[4], null, null, null, i_gpio[0],
                                    null, i_velocity_control[0], i_position_control[0]);
#endif
        }

        on tile[APP_TILE_2]:
        {
            par
            {
                /* Position Control Loop */
                {
                     ControlConfig position_control_config;

                     position_control_config.feedback_sensor = MOTOR_FEEDBACK_SENSOR;

                     position_control_config.Kp_n = POSITION_Kp;    // Divided by 10000
                     position_control_config.Ki_n = POSITION_Ki;    // Divided by 10000
                     position_control_config.Kd_n = POSITION_Kd;    // Divided by 10000

                     position_control_config.control_loop_period = CONTROL_LOOP_PERIOD; //us
                     position_control_config.cascade_with_torque = 0;

                     /* Control Loop */
#if(MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
                     position_control_service(position_control_config, null, null, i_biss[1], null, i_motorcontrol[0],
                                                 i_position_control);
#elif(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
                     position_control_service(position_control_config, i_hall[1], i_qei[1], null, null, i_motorcontrol[0],
                                                 i_position_control);
#elif (MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
                     position_control_service(position_control_config, null, null, null, i_ams[1], i_motorcontrol[0],
                                                 i_position_control);
#else
                     position_control_service(position_control_config, i_hall[1], null, null, null, i_motorcontrol[0],
                                                 i_position_control);
#endif
                }

                /* Velocity Control Loop */
                {
                    ControlConfig velocity_control_config;

                    velocity_control_config.feedback_sensor = MOTOR_FEEDBACK_SENSOR;

                    velocity_control_config.Kp_n = VELOCITY_Kp;
                    velocity_control_config.Ki_n = VELOCITY_Ki;
                    velocity_control_config.Kd_n = VELOCITY_Kd;

                    velocity_control_config.control_loop_period =  CONTROL_LOOP_PERIOD;
                    velocity_control_config.cascade_with_torque = 0;

                    /* Control Loop */
#if(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
                    velocity_control_service(velocity_control_config, i_hall[2], i_qei[2], null, null, i_motorcontrol[1],
                                             i_velocity_control);
#elif (MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
                    velocity_control_service(velocity_control_config, null, null, null, i_ams[2], i_motorcontrol[1],
                                             i_velocity_control);
#elif (MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
                    velocity_control_service(velocity_control_config, null, null, i_biss[2], null, i_motorcontrol[1],
                                             i_velocity_control);
#else
                    velocity_control_service(velocity_control_config, i_hall[2], null, null, null, i_motorcontrol[1],
                                             i_velocity_control);
#endif
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
                /* ADC Service */
                adc_service(adc_ports, c_adctrig, i_adc, i_watchdog[1]);

                /* PWM Service */
                pwm_triggered_service(pwm_ports, c_adctrig, c_pwm_ctrl, null);


                [[combine]]
                par{
                    /* Watchdog Service */
                    watchdog_service(wd_ports, i_watchdog);
#if(MOTOR_FEEDBACK_SENSOR != BISS_SENSOR && MOTOR_FEEDBACK_SENSOR != AMS_SENSOR)
                    /* GPIO Digital Service */
                    gpio_service(gpio_ports, i_gpio);
#endif
                }

#if(MOTOR_FEEDBACK_SENSOR != BISS_SENSOR && MOTOR_FEEDBACK_SENSOR != AMS_SENSOR)
                /* Hall sensor Service */
                {
                    HallConfig hall_config;
                    hall_config.pole_pairs = POLE_PAIRS;

                    hall_service(hall_ports, hall_config, null, i_hall);
                }


#endif
#if(MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
                /* Quadrature encoder sensor Service */
                {
                     QEIConfig qei_config;
                     qei_config.signal_type = QEI_SENSOR_SIGNAL_TYPE;        // Encoder signal type (if applicable to your board)
                     qei_config.index_type = QEI_SENSOR_INDEX_TYPE;          // Indexed encoder?
                     qei_config.ticks_resolution = QEI_SENSOR_RESOLUTION;    // Encoder resolution
                     qei_config.sensor_polarity = QEI_SENSOR_POLARITY;       // CW

                     qei_service(qei_ports, qei_config, null, i_qei);
                }
#elif (MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
                /* AMS Rotary Sensor Service */
                {
                    AMSConfig ams_config;
                    ams_config.factory_settings = 1;
                    ams_config.polarity = AMS_POLARITY;
                    ams_config.hysteresis = 1;
                    ams_config.noise_setting = AMS_NOISE_NORMAL;
                    ams_config.uvw_abi = 0;
                    ams_config.dyn_angle_comp = 0;
                    ams_config.data_select = 0;
                    ams_config.pwm_on = AMS_PWM_OFF;
                    ams_config.abi_resolution = 0;
                    ams_config.resolution_bits = AMS_RESOLUTION;
                    ams_config.offset = AMS_OFFSET;
                    ams_config.pole_pairs = POLE_PAIRS;
                    ams_config.max_ticks = 0x7fffffff;
                    ams_config.cache_time = AMS_CACHE_TIME;
                    ams_config.velocity_loop = AMS_VELOCITY_LOOP;

                    ams_service(ams_ports, ams_config, null, i_ams);
                }
#elif (MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
                /* BiSS service */
                {
                    BISSConfig biss_config;
                    biss_config.multiturn_length = BISS_MULTITURN_LENGTH;
                    biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                    biss_config.singleturn_length = BISS_SINGLETURN_LENGTH;
                    biss_config.singleturn_resolution = BISS_SINGLETURN_RESOLUTION;
                    biss_config.status_length = BISS_STATUS_LENGTH;
                    biss_config.crc_poly = BISS_CRC_POLY;
                    biss_config.pole_pairs = POLE_PAIRS;
                    biss_config.polarity = BISS_POLARITY;
                    biss_config.clock_dividend = BISS_CLOCK_DIVIDEND;
                    biss_config.clock_divisor = BISS_CLOCK_DIVISOR;
                    biss_config.timeout = BISS_TIMEOUT;
                    biss_config.max_ticks = BISS_MAX_TICKS;
                    biss_config.velocity_loop = BISS_VELOCITY_LOOP;
                    biss_config.offset_electrical = BISS_OFFSET_ELECTRICAL;

                    biss_service(biss_ports, biss_config, null, i_biss);
                }
#endif

                memory_manager(i_shared_memory, 2);

                /* Motor Commutation Service */
                {
                     MotorcontrolConfig motorcontrol_config;
                     motorcontrol_config.motor_type = BLDC_MOTOR;
                     motorcontrol_config.polarity_type = MOTOR_POLARITY;
                     motorcontrol_config.commutation_method = FOC;
                     motorcontrol_config.commutation_sensor = MOTOR_COMMUTATION_SENSOR;
                     motorcontrol_config.bldc_winding_type = BLDC_WINDING_TYPE;
                     motorcontrol_config.hall_offset[0] =  COMMUTATION_OFFSET_CLK;
                     motorcontrol_config.hall_offset[1] = COMMUTATION_OFFSET_CCLK;
                     motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;

#if(MOTOR_FEEDBACK_SENSOR == AMS_SENSOR)
                    motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                             c_pwm_ctrl, i_adc[0], null, null, null, i_ams[0], i_watchdog[0], null, i_motorcontrol);
#elif(MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
                    motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                             c_pwm_ctrl, i_adc[0], null, null, i_biss[0], null, i_watchdog[0], null, i_motorcontrol);
#else
                     motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                             c_pwm_ctrl, i_adc[0], i_hall[0], null, null, null, i_watchdog[0], null, i_motorcontrol);
#endif
                }

            }
        }
    }

    return 0;
}
