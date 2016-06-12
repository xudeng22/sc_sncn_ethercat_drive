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
#define POLE_PAIRS  15

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1

//equivalent to torque constant (Nm at 1000 A)
#define MAXIMUM_TORQUE          57

// (uOhm)
#define PHASE_RESISTANCE        552000

// (uH)
#define PHASE_INDUCTANCE        720

// SENSOR USED FOR COMMUTATION (if applicable) [BISS_SENSOR - 4, CONTELEC_SENSOR]
#define MOTOR_COMMUTATION_SENSOR   BISS_SENSOR

// SENSOR USED FOR CONTROL FEEDBACK [BISS_SENSOR, CONTELEC_SENSOR]
//#define MOTOR_FEEDBACK_SENSOR      BISS_SENSOR

// RESOLUTION OF YOUR ENCODER (increments)
#define SENSOR_RESOLUTION      262144 //0x40000  //!4000

// POLARITY OF YOUR ENCODER [1, -1]
#define SENSOR_POLARITY         1


///////////////////////////////////////////////
//////       CONTROL CONFIGURATION
/////////////////////////////////////////////

// POSITION/VELOCITY CONTROL LOOP PERIOD [us]
#define CONTROL_LOOP_PERIOD     1000

// PID FOR POSITION CONTROL (units * 10000)
#define POSITION_Kp       35
#define POSITION_Ki       20
#define POSITION_Kd       0

// PID FOR VELOCITY CONTROL (units * 10000)
#define VELOCITY_Kp       30
#define VELOCITY_Ki       0
#define VELOCITY_Kd       40

// PID FOR TORQUE CONTROL (units * 10000)
#define TORQUE_Kp         1000
//#define TORQUE_Ki         0
//#define TORQUE_Kd         0


//////////////////////////////////////////////
//////  COMMUTATION CONFIGURATION
////////////////////////////////////////////

// COMMUTATION/TORQUE CONTROL LOOP PERIOD [us]
#define COMMUTATION_LOOP_PERIOD     66

// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      2071

// COMMUTATION CCW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CCLK     0

//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
////////////////////////////////////////////

//maximum tolerable value of phase current (A)
#define I_MAX           60

//maximum tolerable value of dc-bus voltage (V)
#define V_DC_MAX        60

//minimum tolerable value of dc-bus voltave (V)
#define V_DC_MIN        20

//maximum tolerable value of board temperature (Degrees Celsius)
//#define TEMP_BOARD_MAX  100

// min range: -2^30, limited for safe operation (increments)
#define MIN_POSITION_LIMIT      -0x7fffffff

// max range: 2^30, limited for safe operation (increments)
#define MAX_POSITION_LIMIT      0x7fffffff

// (1/min)
#define MAX_VELOCITY             1300 //!200

// rpm/s
#define QUICK_STOP_DECELERATION  3000

// rpm/s
#define MAX_ACCELERATION         3000
#define MAX_DECELERATION         3000

// torque controller input limit (units * 1024)
#define TORQUE_CONTROL_LIMIT    1200000 //!1000000


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


