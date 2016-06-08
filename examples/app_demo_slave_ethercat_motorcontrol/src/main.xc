/* INCLUDE BOARD SUPPORT FILES FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C22-rev-a.bsp>
#include <IFM_BOARD_REQUIRED>

/**
 * @file test_ethercat-mode.xc
 * @brief Test illustrates usage of Motor Control with EtherCAT
 * @author Synapticon GmbH (www.synapticon.com)
 */

#include <ethercat_drive_service.h>

#include <ethercat_service.h>
#include <fw_update_service.h>
#include <memory_manager.h>

//BLDC Motor drive libs
#include <position_feedback_service.h>
#include <pwm_server.h>
#include <watchdog_service.h>
#include <torque_control.h>

//Position control + profile libs
#include <position_ctrl_service.h>
#include <profile_control.h>

// Please configure your slave's default motorcontrol parameters in config_motor_slave/user_config.h.
// These parameter will be eventually overwritten by the app running on the EtherCAT master
#include <user_config.h>

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;
PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
PositionFeedbackPorts position_feedback_ports = SOMANET_IFM_POSITION_FEEDBACK_PORTS;

int main(void)
{
    /* Motor control channels */
    interface WatchdogInterface i_watchdog[2];
    interface ADCInterface i_adc[2];
    interface MotorcontrolInterface i_motorcontrol[4];
    interface update_pwm i_update_pwm;
    interface shared_memory_interface i_shared_memory[2];
    interface PositionVelocityCtrlInterface i_position_control[3];
    interface PositionFeedbackInterface i_position_feedback[3];

    /* EtherCat Communication channels */
    interface i_coe_communication i_coe;
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
            ethercat_service(i_coe, eoe_out, eoe_in, eoe_sig,
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

            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, i_coe,
                                    i_motorcontrol[0],
                                    i_position_control[0], i_position_feedback[0]);
        }

        on tile[APP_TILE_2]:
        {
            par
            {
                /* Position Control Loop */
                {
                     PosVelocityControlConfig pos_velocity_ctrl_config;

                     pos_velocity_ctrl_config.control_loop_period = CONTROL_LOOP_PERIOD; //us

                     pos_velocity_ctrl_config.int21_min_position =-8000;
                     pos_velocity_ctrl_config.int21_max_position = 8000;
                     pos_velocity_ctrl_config.int10_P_position = POSITION_Kp;
                     pos_velocity_ctrl_config.int10_I_position = POSITION_Ki;
                     pos_velocity_ctrl_config.int10_D_position = POSITION_Kd;
                     pos_velocity_ctrl_config.int21_P_error_limit_position = 10000;
                     pos_velocity_ctrl_config.int21_I_error_limit_position = 0;
                     pos_velocity_ctrl_config.int22_integral_limit_position = 0;
                     //pos_velocity_ctrl_config.int32_cmd_limit_position = 15000;

                     pos_velocity_ctrl_config.int21_max_speed = 15000;
                     pos_velocity_ctrl_config.int10_P_velocity = 18;
                     pos_velocity_ctrl_config.int10_I_velocity = 22;
                     pos_velocity_ctrl_config.int10_D_velocity =25;
                     pos_velocity_ctrl_config.int21_P_error_limit_velocity = 10000;
                     pos_velocity_ctrl_config.int21_I_error_limit_velocity =10;
                     pos_velocity_ctrl_config.int22_integral_limit_velocity = 1000;
                     //pos_velocity_ctrl_config.int32_cmd_limit_velocity = 200000;

                     pos_velocity_ctrl_config.int21_max_torque = 1000;

                     position_velocity_control_service(pos_velocity_ctrl_config, i_motorcontrol[1], i_position_control);
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
                    //pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                    delay_milliseconds(1000); /* FIXME timing fixme */
                    pwm_service_task(_MOTOR_ID, pwm_ports, i_update_pwm);
                }

                /* ADC Service */
                {
                    delay_milliseconds(1500); /* FIXME timing fixme */
                    adc_service(adc_ports, null/*c_trigger*/, i_adc /*ADCInterface*/, i_watchdog[1]);
                }

                /* Watchdog Service */
                {
                    delay_milliseconds(500); /* FIXME timing fixme */
                    watchdog_service(wd_ports, i_watchdog);
                }

                /* Position feedback service */
                {
                    PositionFeedbackConfig position_feedback_config;
                    position_feedback_config.sensor_type = MOTOR_COMMUTATION_SENSOR;

                    position_feedback_config.biss_config.multiturn_length = BISS_MULTITURN_LENGTH;
                    position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                    position_feedback_config.biss_config.singleturn_length = BISS_SINGLETURN_LENGTH;
                    position_feedback_config.biss_config.singleturn_resolution = BISS_SINGLETURN_RESOLUTION;
                    position_feedback_config.biss_config.status_length = BISS_STATUS_LENGTH;
                    position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                    position_feedback_config.biss_config.pole_pairs = POLE_PAIRS;
                    position_feedback_config.biss_config.polarity = BISS_POLARITY;
                    position_feedback_config.biss_config.clock_dividend = BISS_CLOCK_DIVIDEND;
                    position_feedback_config.biss_config.clock_divisor = BISS_CLOCK_DIVISOR;
                    position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                    position_feedback_config.biss_config.max_ticks = BISS_MAX_TICKS;
                    position_feedback_config.biss_config.velocity_loop = BISS_VELOCITY_LOOP;
                    position_feedback_config.biss_config.offset_electrical = BISS_OFFSET_ELECTRICAL;
                    position_feedback_config.biss_config.enable_push_service = PushAll;

                    position_feedback_config.contelec_config.filter = CONTELEC_FILTER;
                    position_feedback_config.contelec_config.polarity = CONTELEC_POLARITY;
                    position_feedback_config.contelec_config.resolution_bits = CONTELEC_RESOLUTION;
                    position_feedback_config.contelec_config.offset = CONTELEC_OFFSET;
                    position_feedback_config.contelec_config.pole_pairs = POLE_PAIRS;
                    position_feedback_config.contelec_config.timeout = CONTELEC_TIMEOUT;
                    position_feedback_config.contelec_config.velocity_loop = CONTELEC_VELOCITY_LOOP;
                    position_feedback_config.contelec_config.enable_push_service = PushAll;

                    position_feedback_service(position_feedback_ports, position_feedback_config, i_shared_memory[1], i_position_feedback, null, null, null, null);
                }

                /* Shared memory Service */
                memory_manager(i_shared_memory, 2);

                /* Motor Control Service */
                {
                    MotorcontrolConfig motorcontrol_config;
                    motorcontrol_config.motor_type = BLDC_MOTOR;
                    motorcontrol_config.commutation_method = FOC;
                    motorcontrol_config.polarity_type = MOTOR_POLARITY;
                    motorcontrol_config.commutation_sensor = MOTOR_COMMUTATION_SENSOR;
                    motorcontrol_config.bldc_winding_type = BLDC_WINDING_TYPE;
                    motorcontrol_config.hall_offset[0] = COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.hall_offset[1] = COMMUTATION_OFFSET_CCLK;
                    motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;

                    Motor_Control_Service( fet_driver_ports, motorcontrol_config, i_adc[0],
                            i_shared_memory[0],
                            i_watchdog[0], i_motorcontrol, i_update_pwm);
                }

            }
        }
    }

    return 0;
}
