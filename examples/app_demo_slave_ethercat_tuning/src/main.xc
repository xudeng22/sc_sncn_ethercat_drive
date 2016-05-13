/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <COM_ECAT-rev-a.bsp>
#include <IFM_BOARD_REQUIRED>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_service.h>
#include <fw_update_service.h>
#include <cia402_wrapper.h>
#include <pwm_service.h>
#include <hall_service.h>
#include <adc_service.h>
#include <user_config.h>
#include <tuning.h>

PwmPorts pwm_ports = SOMANET_IFM_PWM_PORTS;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;
ADCPorts adc_ports = SOMANET_IFM_ADC_PORTS;
EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;
#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
BISSPorts biss_ports = SOMANET_IFM_BISS_PORTS;
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
AMSPorts ams_ports = { {
        IFM_TILE_CLOCK_2,
        IFM_TILE_CLOCK_3,
        SOMANET_IFM_GPIO_D3, //D3,    //mosi
        SOMANET_IFM_GPIO_D1, //D1,    //sclk
        SOMANET_IFM_GPIO_D2  },//D2     //miso
        SOMANET_IFM_GPIO_D0 //D0         //slave select
};
#else
HallPorts hall_ports = SOMANET_IFM_HALL_PORTS;
#endif

#define POSITION_LIMIT 0 //+/- 4095

int main(void)
{
	chan coe_in;  	 	// CAN from module_ethercat to consumer
	chan coe_out;  		// CAN from consumer to module_ethercat
	chan eoe_in;   		// Ethernet from module_ethercat to consumer
	chan eoe_out;  		// Ethernet from consumer to module_ethercat
	chan eoe_sig;
	chan foe_in;   		// File from module_ethercat to consumer
	chan foe_out;  		// File from consumer to module_ethercat
	chan pdo_in;
	chan pdo_out;
    chan c_nodes[1], c_flash_data; // Firmware channels

    // Motor control interfaces
    chan c_pwm_ctrl, c_adctrig; // pwm channels

    interface WatchdogInterface i_watchdog[2];
    interface ADCInterface i_adc[2];
    interface MotorcontrolInterface i_motorcontrol[4];
    interface PositionControlInterface i_position_control[3];
    interface BrakeInterface i_brake;
#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
    interface BISSInterface i_biss[5];
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
    interface AMSInterface i_ams[5];
#else
    interface HallInterface i_hall[5];
#endif

	par
	{
        on tile[COM_TILE] : par {
            /* EtherCAT Communication Handler Loop */
            ethercat_service(coe_out, coe_in, eoe_out, eoe_in, eoe_sig,
                             foe_out, foe_in, pdo_out, pdo_in, ethercat_ports);
            /* Firmware Update Loop over EtherCAT */
            fw_update_service(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, null);
        }

        /* tuning service */
#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
        on tile[APP_TILE]: run_offset_tuning(POSITION_LIMIT, i_motorcontrol[0], i_adc[1], coe_out, pdo_out, pdo_in,
                                             i_position_control[0], null, i_biss[1], null);
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
        on tile[APP_TILE]: run_offset_tuning(POSITION_LIMIT, i_motorcontrol[0], i_adc[1], coe_out, pdo_out, pdo_in,
                                             i_position_control[0], null, null, i_ams[1]);
#else
        on tile[APP_TILE]: run_offset_tuning(POSITION_LIMIT, i_motorcontrol[0], i_adc[1], coe_out, pdo_out, pdo_in,
                                             i_position_control[0], i_hall[1], null, null);
#endif


        on tile[APP_TILE_2]:
        /* Position Control Loop */
        {
            ControlConfig position_control_config;
            position_control_config.feedback_sensor = MOTOR_FEEDBACK_SENSOR;
            position_control_config.Kp_n = POSITION_Kp;    // Divided by 10000
            position_control_config.Ki_n = POSITION_Ki;    // Divided by 10000
            position_control_config.Kd_n = POSITION_Kd;    // Divided by 10000
            position_control_config.control_loop_period = CONTROL_LOOP_PERIOD; //us
            /* Control Loop */
#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
            position_control_service(position_control_config, null, null, i_biss[2], null, i_motorcontrol[3],
                    i_position_control);
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
            position_control_service(position_control_config, null, null, null, i_ams[2], i_motorcontrol[3],
                    i_position_control);
#else
            position_control_service(position_control_config, i_hall[2], null, null, null, i_motorcontrol[3],
                    i_position_control);
#endif
        }


        on tile[IFM_TILE]:
        {
            par
            {
                /* Triggered PWM Service */
                pwm_triggered_service( pwm_ports, c_adctrig, c_pwm_ctrl, i_brake);
                i_brake.set_brake(0);

                /* ADC Service */
                adc_service(adc_ports, c_adctrig, i_adc, i_watchdog[1]);

                /* Watchdog Service */
                watchdog_service(wd_ports, i_watchdog);

#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
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

                    biss_service(biss_ports, biss_config, i_biss);
                }
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
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

                    ams_service(ams_ports, ams_config, i_ams);
                }
#else
                /* Hall sensor Service */
                {
                    HallConfig hall_config;
                    hall_config.pole_pairs = POLE_PAIRS;

                    hall_service(hall_ports, hall_config, i_hall);
                }
#endif

                /* Motor Control Service */
                {
                    MotorcontrolConfig motorcontrol_config;
                    motorcontrol_config.motor_type = BLDC_MOTOR;
                    motorcontrol_config.polarity_type = MOTOR_POLARITY;
                    motorcontrol_config.commutation_method = FOC;
                    motorcontrol_config.commutation_sensor = MOTOR_COMMUTATION_SENSOR;
                    motorcontrol_config.bldc_winding_type = BLDC_WINDING_TYPE;
                    motorcontrol_config.hall_offset[0] = COMMUTATION_OFFSET_CLK;
                    motorcontrol_config.hall_offset[1] = COMMUTATION_OFFSET_CCLK;
                    motorcontrol_config.commutation_loop_period =  COMMUTATION_LOOP_PERIOD;
#if(MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
                    motorcontrol_service(fet_driver_ports, motorcontrol_config,
                            c_pwm_ctrl, i_adc[0], null, null, i_biss[0], null, i_watchdog[0], null, i_motorcontrol);
#elif(MOTOR_COMMUTATION_SENSOR == AMS_SENSOR)
                    motorcontrol_service(fet_driver_ports, motorcontrol_config,
                            c_pwm_ctrl, i_adc[0], null, null, null, i_ams[0], i_watchdog[0], null, i_motorcontrol);
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

