/**
 * @file state_modes.h
 * @brief Drive mode definitions
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once


/* Manufacturer specific mode -128...-1 optional */

/* Controlword */

//Common for all Modes of Operation (CiA402)

#define SHUTDOWN                0x0006
#define SWITCH_ON               0x000F
#define QUICK_STOP              0x000B
#define CLEAR_FAULT             0x0080

//Operation Mode specific control words (complies with CiA402)

/* Homing mode */
#define START_HOMING            0x001F
#define HALT_HOMING             0x011F

/* Profile Position Mode */
#define ABSOLUTE_POSITIONING    0x001F
#define RELATIVE_POSITIONING    0x005F   // supported currently
#define STOP_POSITIONING        0x010F

/*Profile Velocity Mode*/
#define HALT_PROFILE_VELOCITY   0x010F

/* Statusword */
//state defined is ORed with current state

#define TARGET_REACHED          0x0400

/* Homing Mode */
#define HOMING_ATTAINED         0x1000

/* Profile Position Mode */
#define SET_POSITION_ACK        0x1000

/* Profile Velocity Mode */
#define TARGET_VELOCITY_REACHED 0x0400

/*Controlword Bits*/
#define SWITCH_ON_CONTROL                 0x1
#define ENABLE_VOLTAGE_CONTROL            0x2
#define QUICK_STOP_CONTROL                0x4
#define ENABLE_OPERATION_CONTROL          0x8
#define OPERATION_MODES_SPECIFIC_CONTROL  0x70  /*3 bits*/
#define FAULT_RESET_CONTROL               0x80
#define HALT_CONTROL                      0x100
#define OPERATION_MODE_SPECIFIC_CONTROL   0x200
#define RESERVED_CONTROL                  0x400
#define MANUFACTURER_SPECIFIC_CONTROL     0xf800

/*Statusword Bits*/
#define READY_TO_SWITCH_ON_STATE          0x1
#define SWITCHED_ON_STATE                 0x2
#define OPERATION_ENABLED_STATE           0x4
#define FAULT_STATE                       0x8
#define VOLTAGE_ENABLED_STATE             0x10
#define QUICK_STOP_STATE                  0x20
#define SWITCH_ON_DISABLED_STATE          0x40
#define WARNING_STATE                     0x80
#define MANUFACTURER_SPECIFIC_STATE       0x100
#define REMOTE_STATE                      0x200
#define TARGET_REACHED_OR_RESERVED_STATE  0x400
#define INTERNAL_LIMIT_ACTIVE_STATE       0x800
#define OPERATION_MODE_SPECIFIC_STATE     0x1000  // 12 CSP/CSV/CST  13
#define MANUFACTURER_SPECIFIC_STATES      0xC000  // 14-15

