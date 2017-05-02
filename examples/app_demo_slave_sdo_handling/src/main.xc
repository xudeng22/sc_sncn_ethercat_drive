/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IMF_BOARD_REQUIRED" WIT A APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <COM_ECAT-rev-a.bsp>
#include <CORE_C22-rev-a.bsp>

/**
 * @file main.xc
 * @brief Test application for Ctrlproto on Somanet
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <canopen_interface_service.h>
#include <ethercat_service.h>
#include <command_service.h>
#include <reboot.h>
#include <pdo_handler.h>
#include <stdint.h>
#include <dictionary_symbols.h>
#include <flash_service.h>

#define OBJECT_PRINT              0  /* enable object print with 1 */
#define MAX_TIME_TO_WAIT_SDO      100000

typedef enum {
    ECC_UNKNOWN       = -1
    ,ECC_IDLE         = 0
    ,ECC_READ_OBJECT  = 1
    ,ECC_WRITE_OBJECT = 2
} EC_Command_t;

typedef enum {
    ECC_UNDEFINED = 0
    ,ECC_OK = 1
    ,ECC_ERROR = 2
    ,ECC_UNKNOWN_OBJECT  = 3
} EC_Status_t;

struct _object_dictionary_request {
    uint16_t index;
    uint8_t  subindex;
};

EthercatPorts ethercat_ports = SOMANET_COM_ETHERCAT_PORTS;


interface i_command {
    int  get_object_value(uint16_t index, uint8_t subindex, uint32_t &user_value);
    int  set_object_value(uint16_t index, uint8_t subindex, uint32_t value);
};

/* Test application handling pdos from EtherCat */
static void pdo_service(client interface i_pdo_handler_exchange i_pdo, client interface i_co_communication i_co, client interface i_command i_cmd)

{
	timer t;

	unsigned int delay  = 100000;
	unsigned int time   = 0;

	uint16_t command    = 0;
	uint32_t user_value = 0;

	uint16_t index      = 0;
	uint8_t  subindex   = 0;

	pdo_values_t InOut    = { 0 };

	t :> time;

	while(1)
	{
        {InOut, void} = i_pdo.pdo_exchange_app(InOut);

		command = InOut.controlword;

		switch (command) {
		case ECC_UNKNOWN:
		    InOut.statusword = ECC_UNDEFINED;
		    InOut.user_miso = 0;
		    break;

		case ECC_IDLE:
		    InOut.statusword = ECC_UNDEFINED;
		    InOut.user_miso = 0;
		    break;

		case ECC_READ_OBJECT:
		    index      = (InOut.user_mosi >> 16) & 0xffff;
		    subindex   = (InOut.user_mosi >> 8) & 0xff;

		    EC_Status_t state = i_cmd.get_object_value(index, subindex, user_value);
		    InOut.statusword = state;
		    if (state == ECC_OK) {
		        InOut.user_miso = user_value;
		    } else {
		        InOut.user_miso = 0;
		    }
		    break;

		case ECC_WRITE_OBJECT:
		    index      = (InOut.user_mosi >> 16) & 0xffff;
		    subindex   = (InOut.user_mosi >> 8)  & 0xff;

		    user_value  = InOut.tuning_command;

		    if (i_cmd.set_object_value(index, subindex, user_value) == 0) {
		        InOut.statusword = ECC_OK;
		    } else {
		        InOut.statusword = ECC_ERROR;
		    }
		    break;


		}

	   t when timerafter(time+delay) :> time;
	}
}

static const struct _object_dictionary_request request_list[] = {
	{ DICT_DEVICE_TYPE,                        0 },
	{ DICT_ERROR_REGISTER,                     0 },
	{ DICT_IDENTITY,                           0 },
	{ DICT_IDENTITY,                           SUB_IDENTITY_VENDOR_ID },
	{ DICT_IDENTITY,                           SUB_IDENTITY_PRODUCT_CODE },
	{ DICT_IDENTITY,                           SUB_IDENTITY_REVISION },
	{ DICT_IDENTITY,                           SUB_IDENTITY_SERIALNUMBER },
	{ DICT_RX_PDO_MAPPING,                     0 },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_CONTROLWORD },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_OP_MODE },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_TARGET_TORQUE },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_TARGET_POSITION },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_TARGET_VELOCITY },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_OFFSET_TORQUE },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_TUNING_COMMAND },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_1 },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_2 },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_3 },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_4 },
	{ DICT_RX_PDO_MAPPING,                     SUB_RX_PDO_MAPPING_USER_MOSI },
	{ DICT_TX_PDO_MAPPING,                     0 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_STATUSWORD },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_OP_MODE_DISPLAY },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_POSITION_VALUE },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_VELOCITY_VALUE },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_TORQUE_VALUE },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_SECONDARY_POSITION_VALUE },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_SECONDARY_VELOCITY_VALUE },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_ANALOG_INPUT_1 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_ANALOG_INPUT_2 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_ANALOG_INPUT_3 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_ANALOG_INPUT_4 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_TUNING_STATUS },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_DIGITAL_INPUT_1 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_DIGITAL_INPUT_2 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_DIGITAL_INPUT_3 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_DIGITAL_INPUT_4 },
	{ DICT_TX_PDO_MAPPING,                     SUB_TX_PDO_MAPPING_USER_MISO },
	{ DICT_SYNC_MANAGER,                       0 },
	{ DICT_SYNC_MANAGER,                       SUB_SYNC_MANAGER_SYNCMAN_0 },
	{ DICT_SYNC_MANAGER,                       SUB_SYNC_MANAGER_SYNCMAN_1 },
	{ DICT_SYNC_MANAGER,                       SUB_SYNC_MANAGER_SYNCMAN_2 },
	{ DICT_SYNC_MANAGER,                       SUB_SYNC_MANAGER_SYNCMAN_3 },
	{ DICT_SM0_ASSINGMENT,                     0 },
	{ DICT_SM1_ASSINGMENT,                     0 },
	{ DICT_SM2_ASSINGMENT,                     0 },
	{ DICT_SM2_ASSINGMENT,                     SUB_SM2_ASSINGMENT_SUBINDEX_001 },
	{ DICT_SM3_ASSINGMENT,                     0 },
	{ DICT_SM3_ASSINGMENT,                     SUB_SM3_ASSINGMENT_SUBINDEX_001 },
	{ DICT_COMMUTATION_ANGLE_OFFSET,           0 },
	{ DICT_CONTROLWORD,                        0 },
	{ DICT_STATUSWORD,                         0 },
	{ DICT_OP_MODE,                            0 },
	{ DICT_OP_MODE_DISPLAY,                    0 },
	{ DICT_POSITION_VALUE,                     0 },
	{ DICT_VELOCITY_VALUE,                     0 },
	{ DICT_TARGET_TORQUE,                      0 },
	{ DICT_MOTOR_RATED_CURRENT,                0 },
	{ DICT_MOTOR_RATED_TORQUE,                 0 },
	{ DICT_TORQUE_VALUE,                       0 },
	{ DICT_TARGET_POSITION,                    0 },
	{ DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT,  0 },
	{ DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT,  SUB_MAX_SOFTWARE_POSITION_RANGE_LIMIT_MIN_POSITION_LIMIT },
	{ DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT,  SUB_MAX_SOFTWARE_POSITION_RANGE_LIMIT_MAX_POSITION_LIMIT },
	{ DICT_POSITION_RANGE_LIMITS,              0 },
	{ DICT_POSITION_RANGE_LIMITS,              SUB_POSITION_RANGE_LIMITS_MIN_POSITION_RANGE_LIMIT },
	{ DICT_POSITION_RANGE_LIMITS,              SUB_POSITION_RANGE_LIMITS_MAX_POSITION_RANGE_LIMIT },
	{ DICT_TARGET_VELOCITY,                    0 },
	{ DICT_SUPPORTED_DRIVE_MODES,              0 },
	{ DICT_QUICK_STOP_DECELERATION,            0 },
	{ DICT_MAX_MOTOR_SPEED,                    0 },
	{ DICT_DC_LINK_CIRCUIT_VOLTAGE,            0 },
	{ DICT_POLARITY,                           0 },
	{ DICT_PROFILE_ACCELERATION,               0 },
	{ DICT_PROFILE_DECELERATION,               0 },
	{ DICT_MAX_PROFILE_VELOCITY,               0 },
	{ DICT_MAX_ACCELERATION,                   0 },
	{ DICT_PROFILE_VELOCITY,                   0 },
	{ DICT_HOME_OFFSET,                        0 },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            0 },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            SUB_MOTOR_SPECIFIC_SETTINGS_TORQUE_CONSTANT },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE },
	{ DICT_MOTOR_SPECIFIC_SETTINGS,            SUB_MOTOR_SPECIFIC_SETTINGS_MOTOR_PHASES_INVERTED },
	{ DICT_BREAK_RELEASE,                      0 },
	{ DICT_BREAK_RELEASE,                      SUB_BREAK_RELEASE_PULL_BRAKE_VOLTAGE },
	{ DICT_BREAK_RELEASE,                      SUB_BREAK_RELEASE_HOLD_BRAKE_VOLTAGE },
	{ DICT_BREAK_RELEASE,                      SUB_BREAK_RELEASE_PULL_BRAKE_TIME },
	{ DICT_BREAK_RELEASE,                      SUB_BREAK_RELEASE_BRAKE_RELEASE_STRATEGY },
	{ DICT_BREAK_RELEASE,                      SUB_BREAK_RELEASE_BRAKE_RELEASE_DELAY },
	{ DICT_OFFSET_TORQUE,                      0 },
	{ DICT_FEEDBACK_SENSOR_PORTS,              0 },
	{ DICT_FEEDBACK_SENSOR_PORTS,              SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_1 },
	{ DICT_FEEDBACK_SENSOR_PORTS,              SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_2 },
	{ DICT_FEEDBACK_SENSOR_PORTS,              SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_3 },
	{ DICT_RECUPERATION,                       0 },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_RECUPERATION_ENABLED },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MIN_BATTERY_ENERGY },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MAX_BATTERY_ENERGY },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MIN_RECUPERATION_POWER },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MAX_RECUPERATION_POWER },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MINIMUM_RECUPERATION_SPEED },
	{ DICT_RECUPERATION,                       SUB_RECUPERATION_MAXIMUM_RECUPERATION_SPEED },
	{ DICT_PROTECTION,                         SUB_PROTECTION_MIN_DC_VOLTAGE },
	{ DICT_PROTECTION,                         SUB_PROTECTION_MAX_DC_VOLTAGE },
	{ DICT_FILTER_COEFFICIENTS,                0 },
	{ DICT_FILTER_COEFFICIENTS,                SUB_FILTER_COEFFICIENTS_POSITION_FILTER_COEFFICIENT },
	{ DICT_FILTER_COEFFICIENTS,                SUB_FILTER_COEFFICIENTS_VELOCITY_FILTER_COEFFICIENT },
	{ DICT_APPLIED_TUNING_TORQUE_PERCENT,      0 },
	{ DICT_POSITION_CONTROL_STRATEGY,          0 },
	{ DICT_MAX_TORQUE,                         0 },
	{ DICT_MAX_CURRENT,                        0 },
	{ DICT_MOTION_PROFILE_TYPE,                0 },
	{ DICT_TORQUE_CONTROLLER,                  0 },
	{ DICT_TORQUE_CONTROLLER,                  SUB_TORQUE_CONTROLLER_CONTROLLER_KP },
	{ DICT_TORQUE_CONTROLLER,                  SUB_TORQUE_CONTROLLER_CONTROLLER_KI },
	{ DICT_TORQUE_CONTROLLER,                  SUB_TORQUE_CONTROLLER_CONTROLLER_KD },
	{ DICT_VELOCITY_CONTROLLER,                0 },
	{ DICT_VELOCITY_CONTROLLER,                SUB_VELOCITY_CONTROLLER_CONTROLLER_KP },
	{ DICT_VELOCITY_CONTROLLER,                SUB_VELOCITY_CONTROLLER_CONTROLLER_KI },
	{ DICT_VELOCITY_CONTROLLER,                SUB_VELOCITY_CONTROLLER_CONTROLLER_KD },
	{ DICT_VELOCITY_CONTROLLER,                SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT },
	{ DICT_POSITION_CONTROLLER,                0 },
	{ DICT_POSITION_CONTROLLER,                SUB_POSITION_CONTROLLER_CONTROLLER_KP },
	{ DICT_POSITION_CONTROLLER,                SUB_POSITION_CONTROLLER_CONTROLLER_KI },
	{ DICT_POSITION_CONTROLLER,                SUB_POSITION_CONTROLLER_CONTROLLER_KD },
	{ DICT_POSITION_CONTROLLER,                SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT },
	{ DICT_TUNING_COMMAND,                     0 },
	{ DICT_TUNING_STATUS,                      0 },
	{ DICT_ANALOG_INPUT_1,                     0 },
	{ DICT_ANALOG_INPUT_2,                     0 },
	{ DICT_ANALOG_INPUT_3,                     0 },
	{ DICT_ANALOG_INPUT_4,                     0 },
	{ DICT_SECONDARY_POSITION_VALUE,           0 },
	{ DICT_SECONDARY_VELOCITY_VALUE,           0 },
	{ DICT_MOMENT_OF_INERTIA,                  0 },
	{ DICT_BISS_ENCODER_1,                     0 },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_TYPE },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_FUNCTION },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_RESOLUTION },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_MULTITURN_RESOLUTION },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_CLOCK_FREQUENCY },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_TIMEOUT },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_CRC_POLYNOM },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_CLOCK_PORT_CONFIG },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_DATA_PORT_CONFIG },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS },
	{ DICT_BISS_ENCODER_1,                     SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY },
	{ DICT_BISS_ENCODER_2,                     0 },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_TYPE },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_FUNCTION },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_RESOLUTION },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_MULTITURN_RESOLUTION },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_CLOCK_FREQUENCY },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_TIMEOUT },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_CRC_POLYNOM },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_CLOCK_PORT_CONFIG },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_DATA_PORT_CONFIG },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS },
	{ DICT_BISS_ENCODER_2,                     SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY },
	{ DICT_REM_16MT_ENCODER,                   0 },
	{ DICT_REM_16MT_ENCODER,                   SUB_REM_16MT_ENCODER_TYPE },
	{ DICT_REM_16MT_ENCODER,                   SUB_REM_16MT_ENCODER_FUNCTION },
	{ DICT_REM_16MT_ENCODER,                   SUB_REM_16MT_ENCODER_RESOLUTION },
	{ DICT_REM_16MT_ENCODER,                   SUB_REM_16MT_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_REM_16MT_ENCODER,                   SUB_REM_16MT_ENCODER_FILTER },
	{ DICT_REM_14_ENCODER,                     0 },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_TYPE },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_FUNCTION },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_RESOLUTION },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_HYSTERESIS },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_NOISE_SETTINGS },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_DYNAMIC_ANGLE_ERROR_COMPENSATION },
	{ DICT_REM_14_ENCODER,                     SUB_REM_14_ENCODER_RESOLUTION_SETTINGS },
	{ DICT_INCREMENTAL_ENCODER_1,              0 },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_TYPE },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_FUNCTION },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_RESOLUTION },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS },
	{ DICT_INCREMENTAL_ENCODER_1,              SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE },
	{ DICT_INCREMENTAL_ENCODER_2,              0 },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_TYPE },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_FUNCTION },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_RESOLUTION },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_VELOCITY_CALCULATION_PERIOD },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS },
	{ DICT_INCREMENTAL_ENCODER_2,              SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE },
	{ DICT_HALL_SENSOR_1,                      0 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_TYPE },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_FUNCTION },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_RESOLUTION },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_VELOCITY_CALCULATION_PERIOD },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_0 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_1 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_2 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_3 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_4 },
	{ DICT_HALL_SENSOR_1,                      SUB_HALL_SENSOR_STATE_ANGLE_5 },
	{ DICT_HALL_SENSOR_2,                      0 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_TYPE },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_FUNCTION },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_RESOLUTION },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_VELOCITY_CALCULATION_PERIOD },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_0 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_1 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_2 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_3 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_4 },
	{ DICT_HALL_SENSOR_2,                      SUB_HALL_SENSOR_STATE_ANGLE_5 },
	{ DICT_GPIO,                               0 },
	{ DICT_GPIO,                               SUB_GPIO_PIN_1 },
	{ DICT_GPIO,                               SUB_GPIO_PIN_2 },
	{ DICT_GPIO,                               SUB_GPIO_PIN_3 },
	{ DICT_GPIO,                               SUB_GPIO_PIN_4 },
	{ DICT_DIGITAL_INPUT_1,                    0 },
	{ DICT_DIGITAL_INPUT_2,                    0 },
	{ DICT_DIGITAL_INPUT_3,                    0 },
	{ DICT_DIGITAL_INPUT_4,                    0 },
	{ DICT_DIGITAL_OUTPUT_1,                   0 },
	{ DICT_DIGITAL_OUTPUT_2,                   0 },
	{ DICT_DIGITAL_OUTPUT_3,                   0 },
	{ DICT_DIGITAL_OUTPUT_4,                   0 },
	{ DICT_USER_MISO,                          0 },
	{ DICT_USER_MOSI,                          0 },
	{ DICT_ERROR_CODE,                         0 },
    { 0, 0 }
};

static void read_od_config(client interface i_co_communication i_co)
{
    /* Read and print the values of all known objects */
    uint32_t value    = 0;

    size_t object_list_size = sizeof(request_list) / sizeof(request_list[0]);

    for (size_t i = 0; i < object_list_size; i++) {
        {value, void, void} = i_co.od_get_object_value(request_list[i].index, request_list[i].subindex);

#if OBJECT_PRINT == 1
        printstr("Object 0x"); printhex(request_list[i].index);
        printstr(":");         printint(request_list[i].subindex);
        printstr(" = ");
        printintln(value);
#endif

    }

    return;
}


static void sdo_service(client interface i_co_communication i_co, server interface i_command i_cmd)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    int read_config = 0;

    /*
     *  Wait for initial configuration.
     *
     *  It is assumed that the master successfully configured the object dictionary values
     *  before the drive is switched into EtherCAT OP mode. The signal `configuration_ready()`
     *  is send by the `ethercat_service()` on this event. In the user application this is the
     *  moment to read all necessary configuration parameters from the dictionary.
     */
    while (!i_co.configuration_get());
    read_od_config(i_co);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");
    i_co.configuration_done(); /* clear notification */


    while (1) {
        read_config = i_co.configuration_get();

        select {
        case i_cmd.get_object_value(uint16_t index, uint8_t subindex, uint32_t &value) -> { int err }:
            {value, void, void} = i_co.od_get_object_value(index, subindex);
            err = ECC_OK;
            break;

        case i_cmd.set_object_value(uint16_t index, uint8_t subindex, uint32_t value) -> { int err }:
            i_co.od_set_object_value(index, subindex, value);
            err = 0;
            break;

        default:
            break;
        }

        if (read_config) {
            read_od_config(i_co);
            printstrln("Re-Configuration finished, ECAT in OP mode - start cyclic operation");
            i_co.configuration_done(); /* clear notification */
            read_config = 0;
        }

        t when timerafter(time+delay) :> time;
    }
}


int main(void)
{
    /* EtherCat Communication channels */
    interface i_command i_cmd;

    interface i_foe_communication i_foe;
    interface EtherCATRebootInterface i_ecat_reboot;
    interface i_co_communication i_co[CO_IF_COUNT];
    interface i_pdo_handler_exchange i_pdo;

    /* flash interfaces */
    interface EtherCATFlashDataInterface i_data_ecat;
    interface EtherCATFlashDataInterface i_boot_ecat;

	par
	{
		/* EtherCAT Communication Handler Loop */
		on tile[COM_TILE] :
		{
		    par
		    {
                ethercat_service(i_ecat_reboot,
                                   i_pdo,
                                   i_co,
                                   null,
                                   i_foe,
                                   ethercat_ports);

                reboot_service_ethercat(i_ecat_reboot);
                flash_service_ethercat(p_spi_flash, null, i_data_ecat);
            }
        }

        /* Test application handling pdos from EtherCat */
        on tile[APP_TILE] :
        {
            par
            {
                /* Start trivial PDO exchange service */
                pdo_service(i_pdo, i_co[1], i_cmd);


                /* Start the SDO / Object Dictionary test service */
                sdo_service(i_co[2], i_cmd);

                /* due to serious space problems on tile 0 because of the large object dictionary the command
                 * service is located here.
                 */
                command_service(i_data_ecat, i_co[3]);
            }
        }
    }

    return 0;
}
