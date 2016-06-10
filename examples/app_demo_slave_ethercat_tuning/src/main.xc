/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <COM_ECAT-rev-a.bsp>
#include <IFM_DC1K-rev-c3.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_service.h>
#include <fw_update_service.h>
#include <pwm_server.h>
#include <torque_control.h>
#include <position_feedback_service.h>
#include <adc_service.h>
#include <user_config.h>
#include <tuning.h>

PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;
PositionFeedbackPorts position_feedback_ports = SOMANET_IFM_POSITION_FEEDBACK_PORTS;

#define POSITION_LIMIT 0 //+/- 4095

int main(void)
{
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

    interface WatchdogInterface i_watchdog[2];
    interface ADCInterface i_adc[2];
    interface update_pwm i_update_pwm;
    interface MotorcontrolInterface i_motorcontrol[4];
    interface PositionVelocityCtrlInterface i_position_control[3];
    interface PositionFeedbackInterface i_position_feedback[3];
    interface shared_memory_interface i_shared_memory[2];

    par
    {
        on tile[COM_TILE] : par {
            /* EtherCAT Communication Handler Loop */
            {
                ethercat_service(i_coe, eoe_out, eoe_in, eoe_sig,
                        foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
            }
            /* Firmware Update Loop over EtherCAT */
            {
                fw_update_service(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, null);
            }

        }


        /* tuning service */
        on tile[APP_TILE]: run_offset_tuning(0, i_motorcontrol[0], i_position_control[0], i_position_feedback[0], pdo_out, pdo_in, i_coe);


        on tile[APP_TILE_2]:
        /* Position Control Loop */
        {
            PosVelocityControlConfig pos_velocity_ctrl_config;
            /* Control Loop */
            pos_velocity_ctrl_config.control_loop_period = CONTROL_LOOP_PERIOD; //us

            //other
            pos_velocity_ctrl_config.int21_min_position =-0x7fffffff;
            pos_velocity_ctrl_config.int21_max_position = 0x7fffffff;
            pos_velocity_ctrl_config.int21_max_speed = 2000;
            pos_velocity_ctrl_config.int21_max_torque = 1000000;


            pos_velocity_ctrl_config.int10_P_position = 200;
            pos_velocity_ctrl_config.int10_I_position =200;
            pos_velocity_ctrl_config.int10_D_position = 0;
            pos_velocity_ctrl_config.int21_P_error_limit_position = 200000;
            pos_velocity_ctrl_config.int21_I_error_limit_position = 1;
            pos_velocity_ctrl_config.int22_integral_limit_position = 1000;

            pos_velocity_ctrl_config.int10_P_velocity = 5;
            pos_velocity_ctrl_config.int10_I_velocity = 0;//50;
            pos_velocity_ctrl_config.int10_D_velocity = 5;
            pos_velocity_ctrl_config.int21_P_error_limit_velocity = 200000;
            pos_velocity_ctrl_config.int21_I_error_limit_velocity = 2000;
            pos_velocity_ctrl_config.int22_integral_limit_velocity = 60000;


            pos_velocity_ctrl_config.position_ref_fc = POSITION_REF_FC;
            pos_velocity_ctrl_config.position_fc = POSITION_FC;
            pos_velocity_ctrl_config.velocity_ref_fc = VELOCITY_REF_FC;
            pos_velocity_ctrl_config.velocity_fc = VELOCITY_FC;
            pos_velocity_ctrl_config.velocity_d_fc = VELOCITY_D_FC;


            //MABI A1
//            pos_velocity_ctrl_config.int21_min_position = -1000000;
//            pos_velocity_ctrl_config.int21_max_position = 1000000;
//            pos_velocity_ctrl_config.int21_max_speed = 200;
//            pos_velocity_ctrl_config.int21_max_torque = 1200000;
//
//
//            pos_velocity_ctrl_config.int10_P_position = 40;
//            pos_velocity_ctrl_config.int10_I_position = 50;
//            pos_velocity_ctrl_config.int10_D_position = 0;
//            pos_velocity_ctrl_config.int21_P_error_limit_position = 40000;
//            pos_velocity_ctrl_config.int21_I_error_limit_position = 5;
//            pos_velocity_ctrl_config.int22_integral_limit_position = 10000;
//
//            pos_velocity_ctrl_config.int10_P_velocity = 60;
//            pos_velocity_ctrl_config.int10_I_velocity = 0;
//            pos_velocity_ctrl_config.int10_D_velocity = 65;
//            pos_velocity_ctrl_config.int21_P_error_limit_velocity = 200000;
//            pos_velocity_ctrl_config.int21_I_error_limit_velocity = 0;
//            pos_velocity_ctrl_config.int22_integral_limit_velocity = 0;

            position_velocity_control_service(pos_velocity_ctrl_config, i_motorcontrol[3], i_position_control);
        }


        on tile[IFM_TILE]:
        {
            par
            {
                {
                    /* Watchdog Service */
                    delay_milliseconds(500);
                    watchdog_service(wd_ports,i_watchdog);
                }

                {
                    pwm_config(pwm_ports);

                    //                    pwm_check(pwm_ports);//checks if pulses can be generated on pwm ports or not
                    delay_milliseconds(1000);
                    pwm_service_task(_MOTOR_ID, pwm_ports, i_update_pwm);
                }

                /* ADC Service */
                {
                    delay_milliseconds(1500);
                    adc_service(adc_ports, null/*c_trigger*/, i_adc /*ADCInterface*/, i_watchdog[1]);

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
                    delay_milliseconds(2000);

                    MotorcontrolConfig motorcontrol_config;

                    motorcontrol_config.v_dc =  VDC;
                    motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;
                    motorcontrol_config.commutation_angle_offset=COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.polarity_type=MOTOR_POLARITY;

                    motorcontrol_config.current_P_gain =  TORQUE_Kp;

                    motorcontrol_config.pole_pair =  POLE_PAIRS;
                    motorcontrol_config.max_torque =  MAXIMUM_TORQUE;
                    motorcontrol_config.phase_resistance =  PHASE_RESISTANCE;
                    motorcontrol_config.phase_inductance =  PHASE_INDUCTANCE;

                    motorcontrol_config.protection_limit_over_current =  I_MAX;
                    motorcontrol_config.protection_limit_over_voltage =  V_DC_MAX;
                    motorcontrol_config.protection_limit_under_voltage = V_DC_MIN;

                    Motor_Control_Service( fet_driver_ports, motorcontrol_config, i_adc[0],
                            i_shared_memory[0],
                            i_watchdog[0], i_motorcontrol, i_update_pwm);
                }
            }
        }
	}

	return 0;
}

