/**
 * \brief Static object dictionary for Somanet devices.
 */

#ifndef DICTIONARY_H
#define DICTIONARY_H

#define CIA402
#define USER_DEFINED_PDOS     1
#define PDO_COUNT             5

#if USER_DEFINED_PDOS == 1
#undef PDO_COUNT
#define PDO_COUNT             9
#endif

struct _sdoinfo_entry_description SDO_Info_Entries[] = {
    /* device type value: Mode bits (8bits) | type (8bits) | device profile number (16bits)
     *                    *                 | 0x02 (Servo) | 0x0192
     *
     * Mode Bits: csp, csv, cst
     */
    { 0x1000, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x0007, 0x00020192, "Device Type" }, /* FIXME why is this entry not readable in opmode */
    { 0x1001, 0, 0, DEFTYPE_UNSIGNED8, CANOD_TYPE_VAR, 8, 0x0007, 0x00,  "Error Register" },
    /* identity object */
    { 0x1018, 0, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED8,  CANOD_TYPE_RECORD,  8, 0x0007, 4, "Identity" },
    { 0x1018, 1, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x000022d2, "Vendor ID" }, /* Vendor ID (by ETG) */
    { 0x1018, 2, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x00000201, "Product code" }, /* Product Code */
    { 0x1018, 3, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x0a000002, "Revision" }, /* Revision Number */
    { 0x1018, 4, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x00000000, "Serialnumber" }, /* Serial Number */
#if 1
    /* RxPDO Mapping */
    { 0x1600, 0, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD,  8, 0x0007, PDO_COUNT, "SubIndex 000" }, /* input */
    { 0x1600, 1, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_CONTROLWORD,0,16), "Controlword" },
    { 0x1600, 2, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_OP_MODES,0,8), "Op Mode" },
    { 0x1600, 3, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_TORQUE,0,16), "Target Torque" },
    { 0x1600, 4, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_POSITION,0,32), "Target Position" },
    { 0x1600, 5, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_VELOCITY,0,32), "Target Velocity" },
#if USER_DEFINED_PDOS == 1
    { 0x1600, 6, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_1,0,32), "User RX 1" },
    { 0x1600, 7, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_2,0,32), "User RX 2" },
    { 0x1600, 8, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_3,0,32), "User RX 3" },
    { 0x1600, 9, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_4,0,32), "User RX 4" },
#endif
    /* TxPDO Mapping */
    { 0x1A00, 0, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD,  8, 0x0007, PDO_COUNT, "SubIndex 000" }, /* output */
    { 0x1A00, 1, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_STATUSWORD,0,16), "Statusword" },
    { 0x1A00, 2, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_OP_MODES_DISP,0,8), "Op Mode Display" },
    { 0x1A00, 3, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_POSITION_VALUE,0,32), "Position Value" },
    { 0x1A00, 4, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_VELOCITY_VALUE,0,32), "Velocity Value" },
    { 0x1A00, 5, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TORQUE_VALUE,0,16), "Torque Value" },
#if USER_DEFINED_PDOS == 1
    { 0x1A00, 6, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_1,0,32), "User TX 1" },
    { 0x1A00, 7, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_2,0,32), "User TX 2" },
    { 0x1A00, 8, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_3,0,32), "User TX 3" },
    { 0x1A00, 9, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_4,0,32), "User TX 4" },
#endif
    /* SyncManager Communication Type */
    { 0x1C00, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 4, "SubIndex 000" },
    { 0x1C00, 1, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x01, "SyncMan 0" }, /* mailbox receive */
    { 0x1C00, 2, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x02, "SyncMan 1" }, /* mailbox send */
    { 0x1C00, 3, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x03, "SyncMan 2" }, /* PDO in (bufferd mode) */
    { 0x1C00, 4, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x04, "SyncMan 3" }, /* PDO output (bufferd mode) */
    /* Tx PDO and Rx PDO assignments */
    { 0x1C10, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0, "SyncMan 0 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C11, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0, "SyncMan 1 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C12, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 1, "SyncMan 2 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C12, 1, DEFTYPE_UNSIGNED16, DEFTYPE_UNSIGNED16, CANOD_TYPE_ARRAY, 16, 0x0007, 0x1600, "SyncMan 2 Assignment" },
    { 0x1C13, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 1, "SyncMan 3 assignment"}, /* assignment of SyncMan 3 */
    { 0x1C13, 1, DEFTYPE_UNSIGNED16, DEFTYPE_UNSIGNED16, CANOD_TYPE_ARRAY, 16, 0x0007, 0x1A00, "SyncMan 3 Assignment" },
    /* CiA objects */
    /* index, sub, value info, datatype, bitlength, object access, value, name */
    { CIA402_CONTROLWORD, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Controlword" }, /* map to PDO */
    { CIA402_STATUSWORD, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Statusword" },  /* map to PDO */
//  { CIA402_SUPPORTED_DRIVE_MODES, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x003f, 0x0280 /* csv, csp, cst */, "Supported drive modes" },
    { CIA402_OP_MODES,                0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR, 8, 0x003f, CIA402_OP_MODE_CSP, "Op Mode" },
    { CIA402_OP_MODES_DISP,           0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR, 8, 0x003f, CIA402_OP_MODE_CSP, "Operating mode" },
    { CIA402_POSITION_VALUE,          0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Position Value" }, /* csv, csp */
    { CIA402_FOLLOWING_ERROR_WINDOW,  0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Following Error Window"}, /* csp */
    { CIA402_FOLLOWING_ERROR_TIMEOUT, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Following Error Timeout"}, /* csp */
    { CIA402_VELOCITY_VALUE,          0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Velocity Value"}, /* csv */
    { CIA402_TARGET_TORQUE,           0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Target Torque"}, /* cst */
    { CIA402_TORQUE_VALUE,            0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Torque Value"}, /* csv, cst */
    { CIA402_TARGET_POSITION,         0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Target Position" }, /* csp */
    { CIA402_POSITION_RANGELIMIT,     0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x0007, 2, "Postition Range Limits"}, /* csp */
    { CIA402_POSITION_RANGELIMIT,     1, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Min Postition Range Limit"},
    { CIA402_POSITION_RANGELIMIT,     2, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Max Postition Range Limit"},
    { CIA402_SOFTWARE_POSITION_LIMIT, 0, 0, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY,  8, 0x0007, 2, "Software Postition Range Limits"}, /* csp */
    { CIA402_SOFTWARE_POSITION_LIMIT, 1, 0, DEFTYPE_INTEGER32, CANOD_TYPE_ARRAY, 32, 0x003f, 0, "Min Software Postition Range Limit"},
    { CIA402_SOFTWARE_POSITION_LIMIT, 2, 0, DEFTYPE_INTEGER32, CANOD_TYPE_ARRAY, 32, 0x003f, 0, "Max Software Postition Range Limit"},
    { CIA402_VELOCITY_OFFSET,         0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Velocity Offset" }, /* csp */
    { CIA402_TORQUE_OFFSET,           0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Torque Offset" }, /* csv, csp */
    { CIA402_FOLLOWING_ERROR,         0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Following Error" },
    { CIA402_TARGET_VELOCITY,         0, 0,  DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Target Velocity" }, /* csv */
    /* FIXME new objects, change description accordingly */
    { CIA402_SENSOR_SELECTION_CODE,   0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Sensor Selection Mode" },
    { CIA402_MAX_TORQUE,              0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Torque" },
    { CIA402_MAX_CURRENT,             0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Max Current" },
    { CIA402_MOTOR_RATED_CURRENT,     0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Motor Rated Current" },
    { CIA402_MOTOR_RATED_TORQUE,      0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Motor Rated Torque" },
    { CIA402_HOME_OFFSET,             0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Home Offset" },
    { CIA402_POLARITY,                0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 1,   "Polarity" },
    { CIA402_MAX_PROFILE_VELOCITY,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Profile Velocity" },
    { CIA402_MAX_MOTOR_SPEED,         0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Max Motor Speed" },
    { CIA402_PROFILE_VELOCITY,        0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Velocity" },
    { CIA402_PROFILE_ACCELERATION,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Acceleration" },
    { CIA402_PROFILE_DECELERATION,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Deceleration" },
    { CIA402_QUICK_STOP_DECELERATION, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Quick Stop Deceleration" },
    { CIA402_TORQUE_SLOPE,            0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Torque Slope" },
    { CIA402_POSITION_ENC_RESOLUTION, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Position Encoder Resolution" },
    { CIA402_GEAR_RATIO,              0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Gear Ratio" },
    { CIA402_MAX_ACCELERATION,        0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Acceleration" },
    { CIA402_HOMING_METHOD,           0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Homing Method"},
    { CIA402_HOMING_SPEED,            0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Homing Speed"},
    { CIA402_HOMING_ACCELERATION,     0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Homing Acceleration"},
    { COMMUTATION_OFFSET_CLKWISE,     0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Commutation Offset Clockwise"},
    { COMMUTATION_OFFSET_CCLKWISE,    0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Commutation Offset Counter Clockwise"},
    { MOTOR_WINDING_TYPE,             0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Motor Winding Type"},
    { SNCN_SENSOR_POLARITY,           0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 1,   "Position Sensor Polarity"},
    { LIMIT_SWITCH_TYPE,              0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Limit Switch Type"},
    { CIA402_MOTOR_TYPE,              0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR,  16, 0x003f, 0,   "Motor Type" },
    /* the following objects are vendor specific and defined by CiA402_Objects.xlsx */
    { CIA402_MOTOR_SPECIFIC,          0, 0, DEFTYPE_UNSIGNED8,  CANOD_TYPE_ARRAY,    8, 0x0007, 6,   "Motor Specific Settings" },
    { CIA402_MOTOR_SPECIFIC,          1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Nominal Current" },
    { CIA402_MOTOR_SPECIFIC,          2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Phase Resistance" },
    { CIA402_MOTOR_SPECIFIC,          3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific pole pair number" },
    { CIA402_MOTOR_SPECIFIC,          4, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Max Speed" },
    { CIA402_MOTOR_SPECIFIC,          5, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Phase Inductance" },
    { CIA402_MOTOR_SPECIFIC,          6, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Torque Constant" },
    { CIA402_MOTOR_SPECIFIC,          7, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Terminal Connection" },
    { CIA402_CURRENT_GAIN,            0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Current Gain" },
    { CIA402_CURRENT_GAIN,            1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current P-Gain" },
    { CIA402_CURRENT_GAIN,            2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current I-Gain" },
    { CIA402_CURRENT_GAIN,            3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current D-Gain" },
    { CIA402_VELOCITY_GAIN,           0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Velocity Gain" },
    { CIA402_VELOCITY_GAIN,           1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity P-Gain" },
    { CIA402_VELOCITY_GAIN,           2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity I-Gain" },
    { CIA402_VELOCITY_GAIN,           3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity D-Gain" },
    { CIA402_POSITION_GAIN,           0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Position Gain" },
    { CIA402_POSITION_GAIN,           1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position P-Gain" },
    { CIA402_POSITION_GAIN,           2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position I-Gain" },
    { CIA402_POSITION_GAIN,           3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position D-Gain" },
    { CIA402_POSITION_OFFSET,         0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Postion Offset" },
    { CIA402_SUPPORTED_DRIVE_MODES,   0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,     32, 0x0007, 0x00000700, "Supported Drive Modes" },
#endif
#if USER_DEFINED_PDOS == 1
    { USER_PDO_OUT_1,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 1" },
    { USER_PDO_OUT_2,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 2" },
    { USER_PDO_OUT_3,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 3" },
    { USER_PDO_OUT_4,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 4" },
    { USER_PDO_IN_1,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 1" },
    { USER_PDO_IN_2,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 2" },
    { USER_PDO_IN_3,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 3" },
    { USER_PDO_IN_4,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 4" },
#endif /* USER_DEFINED_PDOS */
    { 0, 0, 0, 0, 0, 0, 0, 0, "\0" }
};

#endif  /* DICTIONARY_H */
