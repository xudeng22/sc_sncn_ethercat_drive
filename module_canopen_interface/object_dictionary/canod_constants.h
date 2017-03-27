
/**
 * @file canod_constants.h
 * @brief Common defines for object dictionary access
 */

#ifndef CANOD_CONSTANTS_H
#define CANOD_CONSTANTS_H

/* SDO Information operation code */
#define CANOD_OP_

/* local configuration defines */
#define USER_DEFINED_PDOS       1

/* list of dictionary lists identifiers */
#define CANOD_GET_NUMBER_OF_OBJECTS   0x00
#define CANOD_ALL_OBJECTS             0x01
#define CANOD_RXPDO_MAPABLE           0x02
#define CANOD_TXPDO_MAPABLE           0x03
#define CANOD_DEVICE_REPLACEMENT      0x04
#define CANOD_STARTUP_PARAMETER       0x05

/* possible object types of dictionary objects */
#define CANOD_TYPE_DOMAIN     0x0
#define CANOD_TYPE_DEFTYPE    0x5
#define CANOD_TYPE_DEFSTRUCT  0x6
#define CANOD_TYPE_VAR        0x7
#define CANOD_TYPE_ARRAY      0x8
#define CANOD_TYPE_RECORD     0x9

/* value info values */
#define CANOD_VALUEINFO_UNIT      0x08
#define CANOD_VALUEINFO_DEFAULT   0x10
#define CANOD_VALUEINFO_MIN       0x20
#define CANOD_VALUEINFO_MAX       0x40

/* list types */
#define CANOD_LIST_ALL        0x01  ///< all objects
#define CANOD_LIST_RXPDO_MAP  0x02  ///< only objects which are mappable in a RxPDO
#define CANOD_LIST_TXPDO_MAP  0x03  ///< only objects which are mappable in a TxPDO
#define CANOD_LIST_REPLACE    0x04  ///< objects which has to stored for a device replacement ???
#define CANOD_LIST_STARTUP    0x05  ///< objects which can be used as startup parameter


#define RPDO_COMMUNICATION_PARAMETER 0x1400 /**<CANOpen communication parameter index of receive PDO 0 */
#define RPDO_MAPPING_PARAMETER       0x1600 /**<CANOpen mapping parameter index of receive PDO 0 */
#define TPDO_COMMUNICATION_PARAMETER 0x1800 /**<CANOpen communication parameter index of transmit PDO 0 */
#define TPDO_MAPPING_PARAMETER       0x1A00 /**<CANOpen mapping parameter index of transmit PDO 0 */


/* object dictionary address defines for CIA 402 */
#define DICT_DEVICE_TYPE                              0x1000
#define DICT_ERROR_REGISTER                           0x1001
#define DICT_IDENTITY                                 0x1018
#define SUB_IDENTITY_VENDOR_ID                             1
#define SUB_IDENTITY_PRODUCT_CODE                          2
#define SUB_IDENTITY_REVISION                              3
#define SUB_IDENTITY_SERIALNUMBER                          4
#define DICT_RX_PDO_MAPPING                           0x1600
#define SUB_RX_PDO_MAPPING_CONTROLWORD                     1
#define SUB_RX_PDO_MAPPING_OP_MODE                         2
#define SUB_RX_PDO_MAPPING_TARGET_TORQUE                   3
#define SUB_RX_PDO_MAPPING_TARGET_POSITION                 4
#define SUB_RX_PDO_MAPPING_TARGET_VELOCITY                 5
#define SUB_RX_PDO_MAPPING_OFFSET_TORQUE                   6
#define SUB_RX_PDO_MAPPING_TUNING_COMMAND                  7
#define SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_1                8
#define SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_2                9
#define SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_3                10
#define SUB_RX_PDO_MAPPING_DIGITAL_OUTPUT_4                11
#define SUB_RX_PDO_MAPPING_USER_MOSI                       12
#define DICT_TX_PDO_MAPPING                           0x1A00
#define SUB_TX_PDO_MAPPING_STATUSWORD                      1
#define SUB_TX_PDO_MAPPING_OP_MODE_DISPLAY                 2
#define SUB_TX_PDO_MAPPING_POSITION_VALUE                  3
#define SUB_TX_PDO_MAPPING_VELOCITY_VALUE                  4
#define SUB_TX_PDO_MAPPING_TORQUE_VALUE                    5
#define SUB_TX_PDO_MAPPING_SECONDARY_POSITION_VALUE        6
#define SUB_TX_PDO_MAPPING_SECONDARY_VELOCITY_VALUE        7
#define SUB_TX_PDO_MAPPING_ANALOG_INPUT_1                  8
#define SUB_TX_PDO_MAPPING_ANALOG_INPUT_2                  9
#define SUB_TX_PDO_MAPPING_ANALOG_INPUT_3                  10
#define SUB_TX_PDO_MAPPING_ANALOG_INPUT_4                  11
#define SUB_TX_PDO_MAPPING_TUNING_STATUS                   12
#define SUB_TX_PDO_MAPPING_DIGITAL_INPUT_1                 13
#define SUB_TX_PDO_MAPPING_DIGITAL_INPUT_2                 14
#define SUB_TX_PDO_MAPPING_DIGITAL_INPUT_3                 15
#define SUB_TX_PDO_MAPPING_DIGITAL_INPUT_4                 16
#define SUB_TX_PDO_MAPPING_USER_MISO                       17
#define DICT_SYNC_MANAGER                             0x1C00
#define SUB_SYNC_MANAGER_SYNCMAN_0                         1
#define SUB_SYNC_MANAGER_SYNCMAN_1                         2
#define SUB_SYNC_MANAGER_SYNCMAN_2                         3
#define SUB_SYNC_MANAGER_SYNCMAN_3                         4
#define DICT_SM0_ASSINGMENT                           0x1C10
#define DICT_SM1_ASSINGMENT                           0x1C11
#define DICT_SM2_ASSINGMENT                           0x1C12
#define SUB_SM2_ASSINGMENT_SUBINDEX_001                    1
#define DICT_SM3_ASSINGMENT                           0x1C13
#define SUB_SM3_ASSINGMENT_SUBINDEX_001                    1
#define DICT_COMMUTATION_ANGLE_OFFSET                 0x2001
#define DICT_CONTROLWORD                              0x6040
#define DICT_STATUSWORD                               0x6041
#define DICT_OP_MODE                                  0x6060
#define DICT_OP_MODE_DISPLAY                          0x6061
#define DICT_POSITION_VALUE                           0x6064
#define DICT_VELOCITY_VALUE                           0x606C
#define DICT_TARGET_TORQUE                            0x6071
#define DICT_MOTOR_RATED_CURRENT                      0x6075
#define DICT_MOTOR_RATED_TORQUE                       0x6076
#define DICT_TORQUE_VALUE                             0x6077
#define DICT_TARGET_POSITION                          0x607A
#define DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT        0x607D
#define SUB_MAX_SOFTWARE_POSITION_RANGE_LIMIT_MIN_POSITION_LIMIT 1
#define SUB_MAX_SOFTWARE_POSITION_RANGE_LIMIT_MAX_POSITION_LIMIT 2
#define DICT_POSITION_RANGE_LIMITS                    0x607B
#define SUB_POSITION_RANGE_LIMITS_MIN_POSITION_RANGE_LIMIT 1
#define SUB_POSITION_RANGE_LIMITS_MAX_POSITION_RANGE_LIMIT 2
#define DICT_TARGET_VELOCITY                          0x60FF
#define DICT_SUPPORTED_DRIVE_MODES                    0x6502
#define DICT_QUICK_STOP_DECELERATION                  0x6085
#define DICT_MAX_MOTOR_SPEED                          0x6080
#define DICT_DC_LINK_CIRCUIT_VOLTAGE                  0x6079
#define DICT_POLARITY                                 0x607E
#define DICT_PROFILE_ACCELERATION                     0x6083
#define DICT_PROFILE_DECELERATION                     0x6084
#define DICT_MAX_PROFILE_VELOCITY                     0x607F
#define DICT_MAX_ACCELERATION                         0x60C5
#define DICT_PROFILE_VELOCITY                         0x6081
#define DICT_HOME_OFFSET                              0x607C
#define DICT_MOTOR_SPECIFIC_SETTINGS                  0x2003
#define SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS             1
#define SUB_MOTOR_SPECIFIC_SETTINGS_TORQUE_CONSTANT        2
#define SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE       3
#define SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE       4
#define SUB_MOTOR_SPECIFIC_SETTINGS_MOTOR_PHASES_INVERTED  5
#define DICT_BREAK_RELEASE                            0x2004
#define SUB_BREAK_RELEASE_PULL_BRAKE_VOLTAGE               1
#define SUB_BREAK_RELEASE_HOLD_BRAKE_VOLTAGE               2
#define SUB_BREAK_RELEASE_PULL_BRAKE_TIME                  3
#define SUB_BREAK_RELEASE_BRAKE_RELEASE_STRATEGY           4
#define SUB_BREAK_RELEASE_BRAKE_RELEASE_DELAY              5
#define SUB_BREAK_RELEASE_DC_BUS_VOLTAGE                   6
#define DICT_OFFSET_TORQUE                            0x2300
#define DICT_FEEDBACK_SENSOR_PORTS                    0x2100
#define SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_1            1
#define SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_2            2
#define SUB_FEEDBACK_SENSOR_PORTS_SENSOR_PORT_3            3
#define DICT_RECUPERATION                             0x2005
#define SUB_RECUPERATION_RECUPERATION_ENABLED              1
#define SUB_RECUPERATION_MIN_BATTERY_ENERGY                2
#define SUB_RECUPERATION_MAX_BATTERY_ENERGY                3
#define SUB_RECUPERATION_MIN_RECUPERATION_POWER            4
#define SUB_RECUPERATION_MAX_RECUPERATION_POWER            5
#define SUB_RECUPERATION_MINIMUM_RECUPERATION_SPEED        6
#define SUB_RECUPERATION_MAXIMUM_RECUPERATION_SPEED        7
#define DICT_PROTECTION                               0x2006
#define SUB_PROTECTION_MIN_DC_VOLTAGE                      1
#define SUB_PROTECTION_MAX_DC_VOLTAGE                      2
#define SUB_PROTECTION_MAX_CURRENT                         3
#define DICT_FILTER_COEFFICIENTS                      0x2007
#define SUB_FILTER_COEFFICIENTS_POSITION_FILTER_COEFFICIENT 1
#define SUB_FILTER_COEFFICIENTS_VELOCITY_FILTER_COEFFICIENT 2
#define DICT_APPLIED_TUNING_TORQUE_PERCENT            0x2A00
#define DICT_POSITION_CONTROL_STRATEGY                0x2002
#define DICT_MAX_TORQUE                               0x6072
#define DICT_MAX_CURRENT                              0x6073
#define DICT_MOTION_PROFILE_TYPE                      0x6086
#define DICT_TORQUE_CONTROLLER                        0x2010
#define SUB_TORQUE_CONTROLLER_CONTROLLER_KP                1
#define SUB_TORQUE_CONTROLLER_CONTROLLER_KI                2
#define SUB_TORQUE_CONTROLLER_CONTROLLER_KD                3
#define DICT_VELOCITY_CONTROLLER                      0x2011
#define SUB_VELOCITY_CONTROLLER_CONTROLLER_KP              1
#define SUB_VELOCITY_CONTROLLER_CONTROLLER_KI              2
#define SUB_VELOCITY_CONTROLLER_CONTROLLER_KD              3
#define SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT  4
#define DICT_POSITION_CONTROLLER                      0x2012
#define SUB_POSITION_CONTROLLER_CONTROLLER_KP              1
#define SUB_POSITION_CONTROLLER_CONTROLLER_KI              2
#define SUB_POSITION_CONTROLLER_CONTROLLER_KD              3
#define SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT    4
#define DICT_TUNING_COMMAND                           0x2A01
#define DICT_TUNING_STATUS                            0x2A03
#define DICT_ANALOG_INPUT_1                           0x2401
#define DICT_ANALOG_INPUT_2                           0x2402
#define DICT_ANALOG_INPUT_3                           0x2403
#define DICT_ANALOG_INPUT_4                           0x2404
#define DICT_SECONDARY_POSITION_VALUE                 0x230A
#define DICT_SECONDARY_VELOCITY_VALUE                 0x230B
#define DICT_MOMENT_OF_INERTIA                        0x200A

/* These two are common for all feedback sensor objects */
#define SUB_FEEDBACK_SENSOR_FUNCTION                       1
#define SUB_RESOLUTION                                     2

#define DICT_BISS_ENCODER_1                           0x2201
#define DICT_BISS_ENCODER_2                           0x2202
#define SUB_BISS_ENCODER_TYPE                              1
#define SUB_BISS_ENCODER_FUNCTION                          2
#define SUB_BISS_ENCODER_RESOLUTION                        3
#define SUB_BISS_ENCODER_VELOCITY_CALCULATION_PERIOD       4
#define SUB_BISS_ENCODER_POLARITY                          5
#define SUB_BISS_ENCODER_MULTITURN_RESOLUTION              6
#define SUB_BISS_ENCODER_CLOCK_FREQUENCY                   7
#define SUB_BISS_ENCODER_TIMEOUT                           8
#define SUB_BISS_ENCODER_CRC_POLYNOM                       9
#define SUB_BISS_ENCODER_CLOCK_PORT_CONFIG                 10
#define SUB_BISS_ENCODER_DATA_PORT_CONFIG                  11
#define SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS            12
#define SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY 13
#define DICT_REM_16MT_ENCODER                         0x2203
#define SUB_REM_16MT_ENCODER_TYPE                          1
#define SUB_REM_16MT_ENCODER_FUNCTION                      2
#define SUB_REM_16MT_ENCODER_RESOLUTION                    3
#define SUB_REM_16MT_ENCODER_VELOCITY_CALCULATION_PERIOD   4
#define SUB_REM_16MT_ENCODER_POLARITY                      5
#define SUB_REM_16MT_ENCODER_FILTER                        6
#define DICT_REM_14_ENCODER                           0x2204
#define SUB_REM_14_ENCODER_TYPE                             1
#define SUB_REM_14_ENCODER_FUNCTION                         2
#define SUB_REM_14_ENCODER_RESOLUTION                       3
#define SUB_REM_14_ENCODER_VELOCITY_CALCULATION_PERIOD      4
#define SUB_REM_14_ENCODER_POLARITY                         5
#define SUB_REM_14_ENCODER_HYSTERESIS                       6
#define SUB_REM_14_ENCODER_NOISE_SETTINGS                   7
#define SUB_REM_14_ENCODER_DYNAMIC_ANGLE_ERROR_COMPENSATION 8
#define SUB_REM_14_ENCODER_RESOLUTION_SETTINGS              9
#define DICT_INCREMENTAL_ENCODER_1                    0x2205
#define DICT_INCREMENTAL_ENCODER_2                    0x2206
#define SUB_INCREMENTAL_ENCODER_TYPE                        1
#define SUB_INCREMENTAL_ENCODER_FUNCTION                    2
#define SUB_INCREMENTAL_ENCODER_RESOLUTION                  3
#define SUB_INCREMENTAL_ENCODER_VELOCITY_CALCULATION_PERIOD 4
#define SUB_INCREMENTAL_ENCODER_POLARITY                    5
#define SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS          6
#define SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE          7
#define DICT_HALL_SENSOR_1                            0x2207
#define DICT_HALL_SENSOR_2                            0x2208
#define SUB_HALL_TYPE                                      1
#define SUB_HALL_SENSOR_FUNCTION                           2
#define SUB_HALL_SENSOR_RESOLUTION                         3
#define SUB_HALL_SENSOR_VELOCITY_CALCULATION_PERIOD        4
#define SUB_HALL_SENSOR_POLARITY                           5
#define SUB_HALL_SENSOR_STATE_ANGLE_0                      6
#define SUB_HALL_SENSOR_STATE_ANGLE_1                      7
#define SUB_HALL_SENSOR_STATE_ANGLE_2                      8
#define SUB_HALL_SENSOR_STATE_ANGLE_3                      9
#define SUB_HALL_SENSOR_STATE_ANGLE_4                      10
#define SUB_HALL_SENSOR_STATE_ANGLE_5                      10
#define DICT_GPIO                                     0x2210
#define SUB_GPIO_PIN_1                                     1
#define SUB_GPIO_PIN_2                                     2
#define SUB_GPIO_PIN_3                                     3
#define SUB_GPIO_PIN_4                                     4
#define DICT_DIGITAL_INPUT_1                          0x2501
#define DICT_DIGITAL_INPUT_2                          0x2502
#define DICT_DIGITAL_INPUT_3                          0x2503
#define DICT_DIGITAL_INPUT_4                          0x2504
#define DICT_DIGITAL_OUTPUT_1                         0x2601
#define DICT_DIGITAL_OUTPUT_2                         0x2602
#define DICT_DIGITAL_OUTPUT_3                         0x2603
#define DICT_DIGITAL_OUTPUT_4                         0x2604
#define DICT_USER_MISO                                0x2FFF
#define DICT_USER_MOSI                                0x2FFE
#define DICT_ERROR_CODE                               0x603F
#endif /* CANOD_CONSTANTS_H */
