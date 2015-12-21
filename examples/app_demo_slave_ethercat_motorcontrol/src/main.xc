/* INCLUDE BOARD SUPPORT FILES FROM module_board-support */
#include <COM_ECAT-rev-a.inc>
#include <CORE_C22-rev-a.inc>
#include <IFM_DC100-rev-b.inc>

/**
 * @file test_ethercat-mode.xc
 * @brief Test illustrates usage of Motor Control with Ethercat
 * @author Synapticon GmbH (www.synapticon.com)
 */

#include <qei_service.h>
#include <hall_service.h>
#include <pwm_service.h>
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

 //Configure your default motorcontrol parameters in config/motorcontrol_config.h
#include <user_config.h>
#include <ethercat_modes_config.h>

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
    /* Motor control channels */
    chan c_adctrig, c_pwm_ctrl;

    interface GPIOInterface i_gpio[2];
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
        /************************************************************
         *                          COM_TILE
         ************************************************************/

        /* Ethercat Communication Handler Loop */
        on tile[COM_TILE] :
        {
            ethercat_service(coe_out, coe_in, eoe_out, eoe_in, eoe_sig,
                                foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
        }

        /* Firmware Update Loop over Ethercat */
        on tile[COM_TILE] :
        {
            fw_update_service(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, null);
        }

        /* Ethercat Motor Drive Loop */
        on tile[APP_TILE_1] :
        {

            ProfilerConfig profiler_config;

            profiler_config.polarity = POLARITY;
            profiler_config.max_position = MAX_POSITION_LIMIT;
            profiler_config.min_position = MIN_POSITION_LIMIT;

            profiler_config.max_velocity = MAX_VELOCITY;
            profiler_config.max_acceleration = MAX_ACCELERATION;
            profiler_config.max_deceleration = MAX_ACCELERATION;

            profiler_config.polarity = POLARITY;
            profiler_config.max_current_slope = MAX_CURRENT_VARIATION;
            profiler_config.max_current = MAX_CURRENT;

            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, coe_out,
                                    i_motorcontrol[3], i_hall[4], i_qei[4], i_gpio[0],
                                    i_torque_control[0], i_velocity_control[0], i_position_control[0]);
        }

        on tile[APP_TILE_2]:
        {
            par
            {
                /* Position Control Loop */
                {
                     ControlConfig position_control_config;

                     position_control_config.position_sensor_type = SENSOR_USED;

                     position_control_config.Kp = POSITION_Kp_NUMERATOR;    // Divided by 10000
                     position_control_config.Ki = POSITION_Ki_NUMERATOR;    // Divided by 10000
                     position_control_config.Kd = POSITION_Kd_NUMERATOR;    // Divided by 10000

                     position_control_config.control_loop_period = COMMUTATION_LOOP_PERIOD; //us

                     /* Control Loop */
                     position_control_service(position_control_config, i_hall[1], i_qei[1], i_motorcontrol[0],
                                                 i_position_control);
                }

                /* Velocity Control Loop */
                {
                    ControlConfig velocity_control_config;

                    velocity_control_config.position_sensor_type = SENSOR_USED;

                    velocity_control_config.Kp = VELOCITY_Kp_NUMERATOR;
                    velocity_control_config.Ki = VELOCITY_Ki_NUMERATOR;
                    velocity_control_config.Kd = VELOCITY_Kd_NUMERATOR;

                    velocity_control_config.control_loop_period =  COMMUTATION_LOOP_PERIOD;

                    /* Control Loop */
                    velocity_control_service(velocity_control_config, i_hall[2], i_qei[2], i_motorcontrol[1],
                                                i_velocity_control);
                }

                /* Torque Control Loop */
                {
                    /* Torque Control Loop */
                    ControlConfig torque_control_config;

                    torque_control_config.position_sensor_type = SENSOR_USED;

                    torque_control_config.Kp = TORQUE_Kp_NUMERATOR;
                    torque_control_config.Ki = TORQUE_Ki_NUMERATOR;
                    torque_control_config.Kd = TORQUE_Kd_NUMERATOR;

                    torque_control_config.control_loop_period = 100; // us

                    /* Control Loop */
                    torque_control_service(torque_control_config, i_adc[0], i_motorcontrol[2], i_hall[3], i_qei[3],
                                                i_torque_control);
                }

                {
                    int phaseB, phaseC, actual_torque, target_torque;

                    while(1){
                        {phaseB, phaseC} = i_adc[1].get_currents();
                        actual_torque = i_torque_control[1].get_torque();
                        target_torque = i_torque_control[1].get_set_torque();

                        xscope_int(TARGET_TORQUE, target_torque);
                        xscope_int(ACTUAL_TORQUE, actual_torque);
                        xscope_int(PHASE_B, phaseB);
                        xscope_int(PHASE_C, phaseC);
                        delay_microseconds(50);
                    }
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
                adc_service(adc_ports, c_adctrig, i_adc);

                /* PWM Service */
                pwm_triggered_service(pwm_ports, c_adctrig, c_pwm_ctrl);

                /* Watchdog Service */
                watchdog_service(wd_ports, i_watchdog);

                /* Hall sensor Service */
                {
                    HallConfig hall_config;
                        hall_config.pole_pairs = POLE_PAIRS;

                    hall_service(hall_ports, hall_config, i_hall);
                }

                /* Quadrature encoder sensor Service */
                 {
                     QEIConfig qei_config;
                         qei_config.signal_type = QEI_SIGNAL_TYPE;               // Encoder signal type (if applicable to your board)
                         qei_config.index_type = QEI_INDEX_TYPE;                 // Indexed encoder?
                         qei_config.ticks_resolution = ENCODER_RESOLUTION;       // Encoder resolution
                         qei_config.sensor_polarity = QEI_SENSOR_POLARITY;       // CW

                     qei_service(qei_ports, qei_config, i_qei);
                 }

                 /* Motor Commutation Service */
                 {
                     MotorcontrolConfig motorcontrol_config;
                         motorcontrol_config.motor_type = BLDC_MOTOR;
                         motorcontrol_config.bldc_winding_type = BLDC_WINDING_TYPE;
                         motorcontrol_config.hall_offset_clk =  COMMUTATION_OFFSET_CLK;
                         motorcontrol_config.hall_offset_cclk = COMMUTATION_OFFSET_CCLK;
                         motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;

                     motorcontrol_service(fet_driver_ports, motorcontrol_config,
                                             c_pwm_ctrl, i_hall[0], i_qei[0], i_watchdog[0], i_motorcontrol);
                 }

                /* GPIO Digital Service */
                gpio_service(gpio_ports, i_gpio);
            }
        }
    }

    return 0;
}
