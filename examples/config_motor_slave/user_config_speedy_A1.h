/**
 * @file user_config.h
 * @brief Defines user-configurable parameters for CiA402-Drive default obgect values
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

// DC bus nominal voltage (V)
#define VDC             48

/////////////////////////////////////////////
//////      MOTOR CONFIGURATION
////////////////////////////////////////////

// MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
//#define MOTOR_TYPE  BLDC_MOTOR

// NUMBER OF POLE PAIRS (if applicable)
#define POLE_PAIRS  15               /* 0x2410:3 */

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1      /* 0x607E */

//equivalent to torque constant (Nm at 1000 A)
#define MAXIMUM_TORQUE          57   /* 0x20F6:6 (Motor Specific Torque Constant */

// (uOhm)
#define PHASE_RESISTANCE        552000   /* 0x2410:2 */

// (uH)
#define PHASE_INDUCTANCE        720      /* 0x2410:5 */

// SENSOR USED FOR COMMUTATION (if applicable) [BISS_SENSOR - 4, CONTELEC_SENSOR]
#define MOTOR_COMMUTATION_SENSOR   BISS_SENSOR    /* 0x606A */

// SENSOR USED FOR CONTROL FEEDBACK [BISS_SENSOR, CONTELEC_SENSOR]
//#define MOTOR_FEEDBACK_SENSOR      BISS_SENSOR

// RESOLUTION OF YOUR ENCODER (increments)
#define SENSOR_RESOLUTION      262144 //0x40000  //!4000 /* 0x308f */

// POLARITY OF YOUR ENCODER [1, -1]
#define SENSOR_POLARITY         1      /* 0x2004 */


///////////////////////////////////////////////
//////       CONTROL CONFIGURATION
/////////////////////////////////////////////

// POSITION/VELOCITY CONTROL LOOP PERIOD [us]
#define CONTROL_LOOP_PERIOD     1000

// PID FOR POSITION CONTROL (units * 10000)
#define POSITION_Kp       35   /* 0x20f9:1 */
#define POSITION_Ki       20   /* 0x20f9:2 */
#define POSITION_Kd       0    /* 0x20f9:3 */

// PID FOR VELOCITY CONTROL (units * 10000)
#define VELOCITY_Kp       30   /* 0x20fb:1 */
#define VELOCITY_Ki       0    /* 0x20fb:2 */
#define VELOCITY_Kd       40   /* 0x20fb:3 */

// PID FOR TORQUE CONTROL (units * 10000)
#define TORQUE_Kp         1000    /* 0x20f6:1 */
//#define TORQUE_Ki         0     /* 0x20f6:2 */
//#define TORQUE_Kd         0     /* 0x20f6:3 */


//////////////////////////////////////////////
//////  COMMUTATION CONFIGURATION
////////////////////////////////////////////

// COMMUTATION/TORQUE CONTROL LOOP PERIOD [us]
#define COMMUTATION_LOOP_PERIOD     66

// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      2071    /* 0x2001 */

// COMMUTATION CCW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CCLK     0

//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
////////////////////////////////////////////

//maximum tolerable value of phase current (A)
#define I_MAX           60      /* 0x6073 */

//maximum tolerable value of dc-bus voltage (V)
#define V_DC_MAX        60

//minimum tolerable value of dc-bus voltave (V)
#define V_DC_MIN        20

//maximum tolerable value of board temperature (Degrees Celsius)
//#define TEMP_BOARD_MAX  100

// min range: -2^30, limited for safe operation (increments)
#define MIN_POSITION_LIMIT      -0x7fffffff    /* 0x607B:1 */

// max range: 2^30, limited for safe operation (increments)
#define MAX_POSITION_LIMIT      0x7fffffff    /* 0x607B:2 */

// (1/min)
#define MAX_SPEED               1300 //!200  /* now 0x2410:4 future: 0x607F */

// rpm/s
#define QUICK_STOP_DECELERATION  3000       /* 0x6085 (future use) */

// rpm/s
#define MAX_ACCELERATION         3000   /* 0x6083 (future use) */
#define MAX_DECELERATION         3000   /* 0x6085 (future use) */

// torque controller input limit (units * 1024)
#define TORQUE_CONTROL_LIMIT    1200000 //!1000000       /* 0x6072 */


//////////////////////////////////////////////
//////  FILTERING CONFIGURATION
////////////////////////////////////////////

// Position controller limiters
#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000

// Velocity controller limiters
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0

// Position Feedback Frequency Cut-off
#define POSITION_REF_FC         25
#define POSITION_FC             82

// Velocity Feedback Frequency Cut-off
#define VELOCITY_REF_FC         28
#define VELOCITY_FC             77
#define VELOCITY_D_FC           75


