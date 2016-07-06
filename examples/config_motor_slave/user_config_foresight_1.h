/**
 * @file user_config.h
 * @brief Defines user-configurable parameters for CiA402-Drive default obgect values
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

// DC bus nominal voltage (V)
#define VDC             48

//ratio between current received in control core, and real phase current
//depends on ADC and current sensor ratios
#define CURRENT_RATIO           20

/////////////////////////////////////////////
//////      MOTOR CONFIGURATION
////////////////////////////////////////////

// MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]
//#define MOTOR_TYPE  BLDC_MOTOR

// NUMBER OF POLE PAIRS (if applicable)
#define POLE_PAIRS  5               /* 0x2410:3 */

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1      /* 0x607E */

//equivalent to torque constant (Nm at 1000 A)
#define MAXIMUM_TORQUE          170   /* 0x2410:6 (Motor Specific Torque Constant */

// TORQUE CONSTANT
#define PERCENT_TORQUE_CONSTANT     15

// (uOhm)
#define PHASE_RESISTANCE        1270000   /* 0x2410:2 */

// (uH)
#define PHASE_INDUCTANCE        1330      /* 0x2410:5 */

// RATED CURRENT
#define RATED_CURRENT 13         // Amp

// SENSOR USED FOR COMMUTATION (if applicable) [BISS_SENSOR - 4, CONTELEC_SENSOR]
#define MOTOR_COMMUTATION_SENSOR   CONTELEC_SENSOR    /* 0x606A */

// SENSOR USED FOR CONTROL FEEDBACK [BISS_SENSOR, CONTELEC_SENSOR]
//#define MOTOR_FEEDBACK_SENSOR      BISS_SENSOR

// RESOLUTION OF YOUR ENCODER (increments)
#define SENSOR_RESOLUTION      65536 //0x40000  //!4000 /* 0x308f */

// POLARITY OF YOUR ENCODER [1, 0]
#define SENSOR_POLARITY         0      /* 0x2004 */


//////////////////////////////////////////////
//////  BRAKE CONFIGURATION
////////////////////////////////////////////

//FORESIGHT PROJECT
#define DUTY_START_BRAKE    10000   // duty cycles for brake release (should be a number between 1500 and 13000)
#define DUTY_MAINTAIN_BRAKE 1500    // duty cycles for keeping the brake released (should be a number between 1500 and 13000)

///////////////////////////////////////////////
//////       CONTROL CONFIGURATION
/////////////////////////////////////////////

// POSITION/VELOCITY CONTROL LOOP PERIOD [us]
#define CONTROL_LOOP_PERIOD     1000

// PID FOR POSITION CONTROL (units * 10000)
#define POSITION_Kp       180   /* 0x20fb:1 */
#define POSITION_Ki       30   /* 0x20fb:2 */
#define POSITION_Kd       0    /* 0x20fb:3 */

// PID FOR VELOCITY CONTROL (units * 10000)
#define VELOCITY_Kp       30   /* 0x20f9:1 */
#define VELOCITY_Ki       0    /* 0x20f9:2 */
#define VELOCITY_Kd       40   /* 0x20f9:3 */

// PID FOR TORQUE CONTROL (units * 10000)
#define TORQUE_Kp         10    /* 0x20f6:1 */
#define TORQUE_Ki         3     /* 0x20f6:2 */
#define TORQUE_Kd         0     /* 0x20f6:3 */


//////////////////////////////////////////////
//////  COMMUTATION CONFIGURATION
////////////////////////////////////////////

// COMMUTATION/TORQUE CONTROL LOOP PERIOD [us]
#define COMMUTATION_LOOP_PERIOD     66

// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      0    /* 0x2001 */

// COMMUTATION CCW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CCLK     0

//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
////////////////////////////////////////////

//maximum tolerable value of phase current (A)
#define I_MAX           90      /* 0x6073 */

//maximum tolerable value of dc-bus voltage (V)
#define V_DC_MAX        60

//minimum tolerable value of dc-bus voltave (V)
#define V_DC_MIN        20

//////////////////////////////////////////////
//////  RECUPERATION MODE PARAMETERS
////////////////////////////////////////////
/*recuperation mode
 * WARNING: explosion danger. This mode should not be activated before evaluating battery behaviour.*/
#define RECUPERATION        1

#define BATTERY_E_MAX       80         // maximum energy status of battery
#define BATTERY_E_MIN       10         // minimum energy status of battery

#define REGEN_P_MAX         5000        // maximum regenerative power (in Watts)
#define REGEN_P_MIN         0           // minimum regenerative power (in Watts)

#define REGEN_SPEED_MAX     650
#define REGEN_SPEED_MIN     50          // minimum value of the speed which is considered in regenerative calculations

//maximum tolerable value of board temperature (Degrees Celsius)
//#define TEMP_BOARD_MAX  100

// min range: -2^30, limited for safe operation (increments)
#define MIN_POSITION_LIMIT      -0x7fffffff    /* 0x607B:1 */

// max range: 2^30, limited for safe operation (increments)
#define MAX_POSITION_LIMIT      0x7fffffff    /* 0x607B:2 */

// (1/min)
#define MAX_SPEED               2500 //!200  /* now 0x2410:4 future: 0x607F */

// rpm/s
#define QUICK_STOP_DECELERATION  3000       /* 0x6085 (future use) */

// rpm/s
#define MAX_ACCELERATION         3000   /* 0x6083 (future use) */
#define MAX_DECELERATION         3000   /* 0x6085 (future use) */

// torque controller input limit (units * 1024)
#define TORQUE_CONTROL_LIMIT    1200000 //!1000000       /* 0x6072 MAX_TORQUE */

//////////////////////////////////////////////
//////  FILTERING CONFIGURATION
////////////////////////////////////////////

// Position controller limiters
#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 1000000

// Velocity controller limiters
#define VELOCITY_P_ERROR_lIMIT  20000000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0

// Position Feedback Frequency Cut-off
#define POSITION_REF_FC         140
#define POSITION_FC             80

// Velocity Feedback Frequency Cut-off
#define VELOCITY_REF_FC         100
#define VELOCITY_FC             80
#define VELOCITY_D_FC           60
