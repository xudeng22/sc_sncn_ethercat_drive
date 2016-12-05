
/**
 * @file canod.h
 * @brief Common defines for object dictionary access
 */

#ifndef CANOD_H
#define CANOD_H

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

/* create pdo mapping parameter */
#define PDOMAPING(idx,sub,bit)    ( ((unsigned)idx<<16) | ((unsigned)sub<<8) | bit )

/* object dictionary address defines for CIA 402 */
#define CIA402_CONTROLWORD              0x6040 /* RPDO */
#define CIA402_STATUSWORD               0x6041 /* TPDO */
#define CIA402_OP_MODES                 0x6060 /* RPDO */
#define CIA402_OP_MODES_DISP            0x6061 /* TPDO */

#define CIA402_POSITION_VALUE           0x6064 /* TPDO - used with csp and csv*/
#define CIA402_FOLLOWING_ERROR_WINDOW   0x6065 /* used with csp */
#define CIA402_FOLLOWING_ERROR_TIMEOUT  0x6066 /* used with csp */
#define CIA402_VELOCITY_VALUE           0x606C /* TPDO - recommended if csv is used */
#define CIA402_TARGET_TORQUE            0x6071 /* RPDO - used with cst */
#define CIA402_TORQUE_VALUE             0x6077 /* TPDO - used with csp and csv */

#define CIA402_TARGET_POSITION          0x607A /* RPDO - used with csp */
#define CIA402_POSITION_RANGELIMIT      0x607B /* used with csp */
#define CIA402_SOFTWARE_POSITION_LIMIT  0x607D /* recommended with csp */

#define CIA402_POSITION_OFFSET          0x60B0
#define CIA402_VELOCITY_OFFSET          0x60B1 /* recommended with csp */
#define CIA402_TORQUE_OFFSET            0x60B2 /* recommended with csp or csv */

#define CIA402_INTERPOL_TIME_PERIOD     0x60C2  /* recommended if csp, csv or cst is used */
#define CIA402_FOLLOWING_ERROR          0x60F4 /* TPDO - recommended if csp is used */

#define CIA402_TARGET_VELOCITY          0x60FF /* RPDO  - mandatory if csv is used */

#define CIA402_SENSOR_SELECTION_CODE    0x606A
#define CIA402_MAX_TORQUE               0x6072
#define CIA402_MAX_CURRENT              0x6073
#define CIA402_MOTOR_RATED_CURRENT      0x6075
#define CIA402_MOTOR_RATED_TORQUE       0x6076
#define CIA402_HOME_OFFSET              0x607C
#define CIA402_POLARITY                 0x607E
#define CIA402_MAX_PROFILE_VELOCITY     0x607F
#define CIA402_MAX_MOTOR_SPEED          0x6080
#define CIA402_PROFILE_VELOCITY         0x6081
#define CIA402_END_VELOCITY             0x6082
#define CIA402_PROFILE_ACCELERATION     0x6083
#define CIA402_PROFILE_DECELERATION     0x6084
#define CIA402_QUICK_STOP_DECELERATION  0x6085
#define CIA402_MOTION_PROFILE_TYPE      0x6086
#define CIA402_TORQUE_SLOPE             0x6087
#define CIA402_TORQUE_PROFILE_TYPE      0x6088
#define CIA402_POSITION_ENC_RESOLUTION  0x308F /* FIXME this should be 0x608F ARRAY_TYPE !!! */
#define CIA402_GEAR_RATIO               0x6091
#define CIA402_POSITIVE_TORQUE_LIMIT    0x60E0
#define CIA402_NEGATIVE_TORQUE_LIMIT    0x60E1
#define CIA402_MAX_ACCELERATION 		0x60C5
#define CIA402_HOMING_METHOD			0x6098
#define CIA402_HOMING_SPEED				0x6099
#define CIA402_HOMING_ACCELERATION		0x609A
#define CIA402_MOTOR_TYPE               0x6402
#define CIA402_SUPPORTED_DRIVE_MODES    0x6502

/* Manufacturer Specific Objects */
#define LIMIT_SWITCH_TYPE 				0x2000
#define COMMUTATION_OFFSET_CLKWISE		0x2001
#define COMMUTATION_OFFSET_CCLKWISE		0x2002
#define MOTOR_WINDING_TYPE				0x2003
#define SENSOR_POLARITY					0x2004
#define CIA402_MOTOR_SPECIFIC           0x2410 /* Sub 01 = nominal current
	                                          Sub 02 = ???
						  Sub 03 = pole pair number
						  Sub 04 = max motor speed
						  sub 05 = motor torque constant */
#define CIA402_CURRENT_GAIN             0x20F6 /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */
#define CIA402_VELOCITY_GAIN            0x20F9 /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */
#define CIA402_POSITION_GAIN            0x20FB /* sub 1 = p-gain; sub 2 = i-gain; sub 3 = d-gain */


/* only if touch probe is supported */
#define CIA402_MAX_TORQUE        0x6072 /* RPDO */
#define CIA402_TOUCHPROBE_FUNC   0x60B8 /* RPDO */
#define CIA402_TOUCHPROBE_STAT   0x60B9 /* TPDO */
#define CIA402_TOUCHPROBE_VALUE  0x60BA /* TPDO - depends on touchprobe conf! */
#define CIA402_TOUCHPROBE_VALUE  0x60BB /* TPDO - depends on touchprobe conf! */
#define CIA402_TOUCHPROBE_VALUE  0x60BC /* TPDO - depends on touchprobe conf! */
#define CIA402_TOUCHPROBE_VALUE  0x60BD /* TPDO - depends on touchprobe conf! */

#define CIA402_SUPPORTED_DRIVE_MODES  0x6502 /* recommended */

/* Operating modes for use in objects CIA402_OP_MODES and CIA402_OP_MODES_DISPLAY */
#define CIA402_OP_MODE_CSP    8
#define CIA402_OP_MODE_CSV    9
#define CIA402_OP_MODE_CST   10

/* CAN Object Entry Access Flags */
#define COD_RD_PO_STATE         0x0001
#define COD_RD_SO_STATE         0x0002
#define COD_RD_OP_STATE         0x0004
#define COD_WR_PO_STATE         0x0008
#define COD_WR_SO_STATE         0x0010
#define COD_WR_OP_STATE         0x0020
#define COD_RXPDO_MAPABLE       0x0040
#define COD_TXPDO_MAPABLE       0x0080
#define COD_USED_BACKUP         0x0100
#define COD_USED_SETTINGS       0x0200

#if USER_DEFINED_PDOS == 1
#define USER_PDO_IN_1           0x4010
#define USER_PDO_IN_2           0x4020
#define USER_PDO_IN_3           0x4030
#define USER_PDO_IN_4           0x4040
#define USER_PDO_OUT_1          0x4011
#define USER_PDO_OUT_2          0x4021
#define USER_PDO_OUT_3          0x4031
#define USER_PDO_OUT_4          0x4041
#endif /* USER_DEFINED_PDOS */

#endif /* CANOD_H */
