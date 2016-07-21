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
//#include <user_config.h>
//#include <user_config_speedy_A1.h>
#include <user_config_foresight_1.h>
//#include <user_config_foresight.h>

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

            profiler_config.polarity = POLARITY;                 /* Set by Object Dictionary value! */
            profiler_config.max_position = MAX_POSITION_LIMIT;   /* Set by Object Dictionary value! */
            profiler_config.min_position = MIN_POSITION_LIMIT;   /* Set by Object Dictionary value! */

            profiler_config.max_velocity = MAX_SPEED;
            profiler_config.max_acceleration = MAX_ACCELERATION;
            profiler_config.max_deceleration = MAX_ACCELERATION;

#if 0
            ethercat_drive_service_debug( profiler_config,
                                    pdo_out, pdo_in, i_coe,
                                    i_motorcontrol[0],
                                    i_position_control[0], i_position_feedback[0]);
#else
            ethercat_drive_service( profiler_config,
                                    pdo_out, pdo_in, i_coe,
                                    i_motorcontrol[0],
                                    i_position_control[0], i_position_feedback[0]);
#endif
        }

        on tile[APP_TILE_2]:
        {
            par
            {
                /* Position Control Loop */
                {
                     PosVelocityControlConfig pos_velocity_ctrl_config;

                     pos_velocity_ctrl_config.control_loop_period = CONTROL_LOOP_PERIOD; //us

                     pos_velocity_ctrl_config.int21_min_position = MIN_POSITION_LIMIT;       /* Set by Object Dictionary value! */
                     pos_velocity_ctrl_config.int21_max_position =  MAX_POSITION_LIMIT;      /* Set by Object Dictionary value! */
                     pos_velocity_ctrl_config.int21_max_speed = MAX_SPEED;                /* Set by OD: CIA402_MOTOR_SPECIFIC subindex 4 */
                     pos_velocity_ctrl_config.int21_max_torque = TORQUE_CONTROL_LIMIT;       /* Set by Object Dictionary value CIA402_MAX_TORQUE */

                     pos_velocity_ctrl_config.int10_P_position = POSITION_Kp;    /* Set by OD: CIA402_POSITION_GAIN subindex 1 */
                     pos_velocity_ctrl_config.int10_I_position = POSITION_Ki;    /* Set by OD: CIA402_POSITION_GAIN subindex 2 */
                     pos_velocity_ctrl_config.int10_D_position = POSITION_Kd;    /* Set by OD: CIA402_POSITION_GAIN subindex 3 */
                     pos_velocity_ctrl_config.int21_P_error_limit_position = POSITION_P_ERROR_lIMIT;
                     pos_velocity_ctrl_config.int21_I_error_limit_position = POSITION_I_ERROR_lIMIT;
                     pos_velocity_ctrl_config.int22_integral_limit_position = POSITION_INTEGRAL_LIMIT;
                     //pos_velocity_ctrl_config.int32_cmd_limit_position = 15000;

                     pos_velocity_ctrl_config.int10_P_velocity = VELOCITY_Kp; /* Set by OD: CIA_VELOCITY_GAIN si: 1 */
                     pos_velocity_ctrl_config.int10_I_velocity = VELOCITY_Ki; /* Set by OD: CIA_VELOCITY_GAIN si: 2 */
                     pos_velocity_ctrl_config.int10_D_velocity = VELOCITY_Kd; /* Set by OD: CIA_VELOCITY_GAIN si: 3 */
                     pos_velocity_ctrl_config.int21_P_error_limit_velocity = VELOCITY_P_ERROR_lIMIT;
                     pos_velocity_ctrl_config.int21_I_error_limit_velocity = VELOCITY_I_ERROR_lIMIT;
                     pos_velocity_ctrl_config.int22_integral_limit_velocity = VELOCITY_INTEGRAL_LIMIT;
                     //pos_velocity_ctrl_config.int32_cmd_limit_velocity = 200000;

                     pos_velocity_ctrl_config.position_ref_fc = POSITION_REF_FC;
                     pos_velocity_ctrl_config.position_fc = POSITION_FC;
                     pos_velocity_ctrl_config.velocity_ref_fc = VELOCITY_REF_FC;
                     pos_velocity_ctrl_config.velocity_fc = VELOCITY_FC;
                     pos_velocity_ctrl_config.velocity_d_fc = VELOCITY_D_FC;

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

                    delay_milliseconds(10);
                    if (!isnull(fet_driver_ports.p_esf_rst_pwml_pwmh) && !isnull(fet_driver_ports.p_coast))
                        predriver(fet_driver_ports);

                    delay_milliseconds(5);
                    //pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                    pwm_service_task(_MOTOR_ID, pwm_ports, i_update_pwm, DUTY_START_BRAKE, DUTY_MAINTAIN_BRAKE);
                }

                /* ADC Service */
                {
                    delay_milliseconds(10);
                    adc_service(adc_ports, null/*c_trigger*/, i_adc /*ADCInterface*/, i_watchdog[1]);
                }

                /* Watchdog Service */
                {
                    delay_milliseconds(5);
                    watchdog_service(wd_ports, i_watchdog);
                }


                /* Motor Control Service */
                {
                    delay_milliseconds(20);

                    MotorcontrolConfig motorcontrol_config;

                    motorcontrol_config.v_dc =  VDC;
                    motorcontrol_config.commutation_loop_period = COMMUTATION_LOOP_PERIOD;
                    motorcontrol_config.commutation_angle_offset = COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.polarity_type = POLARITY;

                    motorcontrol_config.current_P_gain =  TORQUE_Kp;
                    motorcontrol_config.current_I_gain =  TORQUE_Ki;
                    motorcontrol_config.current_D_gain =  TORQUE_Kd;

                    motorcontrol_config.pole_pair =  POLE_PAIRS;
                    motorcontrol_config.max_torque =  MAXIMUM_TORQUE;
                    motorcontrol_config.phase_resistance =  PHASE_RESISTANCE;
                    motorcontrol_config.phase_inductance =  PHASE_INDUCTANCE;
                    motorcontrol_config.torque_constant =  PERCENT_TORQUE_CONSTANT;
                    motorcontrol_config.current_ratio =  CURRENT_RATIO;
                    motorcontrol_config.rated_current =  RATED_CURRENT;

                    motorcontrol_config.recuperation = RECUPERATION;
                    motorcontrol_config.battery_e_max = BATTERY_E_MAX;
                    motorcontrol_config.battery_e_min = BATTERY_E_MIN;
                    motorcontrol_config.regen_p_max = REGEN_P_MAX;
                    motorcontrol_config.regen_p_min = REGEN_P_MIN;
                    motorcontrol_config.regen_speed_max = REGEN_SPEED_MAX;
                    motorcontrol_config.regen_speed_min = REGEN_SPEED_MIN;

                    motorcontrol_config.protection_limit_over_current =  I_MAX;
                    motorcontrol_config.protection_limit_over_voltage =  V_DC_MAX;
                    motorcontrol_config.protection_limit_under_voltage = V_DC_MIN;

                    Motor_Control_Service(motorcontrol_config, i_adc[0], i_shared_memory[1],
                                          i_watchdog[0], i_motorcontrol, i_update_pwm);
                }

                {
                    /* Shared memory Service */
                    memory_manager(i_shared_memory, 2);
                }

                /* Position feedback service */
                {
                    PositionFeedbackConfig position_feedback_config;
                    position_feedback_config.sensor_type = MOTOR_COMMUTATION_SENSOR; /* Set by OD: CIA402_SENSOR_SELECTION_CODE */

                    position_feedback_config.biss_config.multiturn_length = BISS_MULTITURN_LENGTH;
                    position_feedback_config.biss_config.multiturn_resolution = BISS_MULTITURN_RESOLUTION;
                    position_feedback_config.biss_config.singleturn_length = BISS_SINGLETURN_LENGTH;
                    position_feedback_config.biss_config.singleturn_resolution = BISS_SINGLETURN_RESOLUTION; /* Set by OD CIA402_POSITION_ENC_RESOLUTION */
                    position_feedback_config.biss_config.status_length = BISS_STATUS_LENGTH;
                    position_feedback_config.biss_config.crc_poly = BISS_CRC_POLY;
                    position_feedback_config.biss_config.pole_pairs = POLE_PAIRS; /* Set by OD CIA402_MOTOR_SPECIFIC si: 3 */
                    position_feedback_config.biss_config.polarity = BISS_POLARITY; /* Set by OD: SENSOR_POLARITY */
                    position_feedback_config.biss_config.clock_dividend = BISS_CLOCK_DIVIDEND;
                    position_feedback_config.biss_config.clock_divisor = BISS_CLOCK_DIVISOR;
                    position_feedback_config.biss_config.timeout = BISS_TIMEOUT;
                    position_feedback_config.biss_config.max_ticks = BISS_MAX_TICKS;
                    position_feedback_config.biss_config.velocity_loop = BISS_VELOCITY_LOOP;
                    position_feedback_config.biss_config.offset_electrical = BISS_OFFSET_ELECTRICAL;
                    position_feedback_config.biss_config.enable_push_service = PushAll;

                    position_feedback_config.contelec_config.filter = CONTELEC_FILTER;
                    position_feedback_config.contelec_config.polarity = CONTELEC_POLARITY; /* Set by OD: SENSOR_POLARITY */
                    position_feedback_config.contelec_config.resolution_bits = CONTELEC_RESOLUTION; /* Set by OD CIA402_POSITION_ENC_RESOLUTION */
                    position_feedback_config.contelec_config.offset = CONTELEC_OFFSET;
                    position_feedback_config.contelec_config.pole_pairs = POLE_PAIRS; /* Set by OD CIA402_MOTOR_SPECIFIC si: 3 */
                    position_feedback_config.contelec_config.timeout = CONTELEC_TIMEOUT;
                    position_feedback_config.contelec_config.velocity_loop = CONTELEC_VELOCITY_LOOP;
                    position_feedback_config.contelec_config.enable_push_service = PushAll;

                    position_feedback_service(position_feedback_ports, position_feedback_config, i_shared_memory[0], i_position_feedback, null, null, null, null);
                }

            }
        }
    }

    return 0;
}
