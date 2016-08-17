/**
 * @file user_config.h
 * @brief Motor Control config file (define your motor specifications here)
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once


//#include <motor_configs/motor_config_Nanotec_DB42C01.h>
//#include <motor_configs/motor_config_Nanotec_DB42C02.h>
//#include <motor_configs/motor_config_Nanotec_DB42C03.h>
//#include <motor_configs/motor_config_Nanotec_DB42L01.h>
//#include <motor_configs/motor_config_Nanotec_DB42M01.h>
//#include <motor_configs/motor_config_Nanotec_DB42M02.h>
//#include <motor_configs/motor_config_Nanotec_DB42M03.h>
//#include <motor_configs/motor_config_Nanotec_DB42S01.h>
//#include <motor_configs/motor_config_Nanotec_DB42S02.h>
//#include <motor_configs/motor_config_Nanotec_DB42S03.h>
//#include <motor_configs/motor_config_Nanotec_DB87S01.h>
//#include <motor_configs/motor_config_LDO_42BLS41.h>
//#include <motor_configs/motor_config_Moons_42BL30L2.h>
//#include <motor_config_Nanotec_DB59L024035-A.h>
//#include <motor_config_MABI_Hohlwellenservomotor_A5.h>
//#include <motor_config_MABI_A1.h>
//#include <motor_config_qmot_qbl5704.h>
//#include <motor_config_AMK_DT3.h>

/* content of motor_config.h */
//#include <motor_config.h>

/////////////////////////////////////////////
//////  MOTOR PARAMETERS
////////////////////////////////////////////

// motor model: DT4

// IMPORTANT PARAMETERS (=> lead to mulfunction or damage if set wrong)
#define POLE_PAIRS              2       //number of motor pole-pairs
#define PERCENT_TORQUE_CONSTANT 15      //motor torque constant multiplied by 100
#define RATED_CURRENT           8000    //rated phase current [milli-Amp-RMS]
#define MAXIMUM_TORQUE          2500    //maximum value of torque which can be produced by motor [milli-Nm]

// OTHER PARAMETERS (do not change if not having access to the following parameter values)
#define RATED_POWER             300     // rated power [W]
#define RATED_TORQUE            1250    // rated motor torque [milli-Nm]
#define PEAK_SPEED              3700    // maximum motor speed [rpm]
#define PHASE_RESISTANCE        490000  // motor phase resistance [micro-ohm]
#define PHASE_INDUCTANCE        580     // motor phase inductance [micro-Hunnry]

// GENERAL PARAMETERS
#define MOTOR_TYPE              BLDC_MOTOR      //MOTOR TYPE [BLDC_MOTOR, BDC_MOTOR]





/////////////////////////////////////////////
//////  MOTOR SENSORS CONFIGURATION
/////////////////////////////////////////////

// SENSOR USED FOR COMMUTATION (if applicable) [HALL_SENSOR]
#define MOTOR_COMMUTATION_SENSOR   HALL_SENSOR

// SENSOR USED FOR CONTROL FEEDBACK [HALL_SENSOR, QEI_SENSOR, BISS_SENSOR]
#define MOTOR_FEEDBACK_SENSOR      MOTOR_COMMUTATION_SENSOR

// TYPE OF INCREMENTAL ENCODER (if applicable) [QEI_WITH_INDEX, QEI_WITH_NO_INDEX]
#define QEI_SENSOR_INDEX_TYPE       QEI_WITH_INDEX

// TYPE OF SIGNAL FOR INCREMENTAL ENCODER (if applicable) [QEI_RS422_SIGNAL, QEI_TTL_SIGNAL]
#define QEI_SENSOR_SIGNAL_TYPE      QEI_RS422_SIGNAL

// RESOLUTION OF YOUR INCREMENTAL ENCODER (if applicable)
#define QEI_SENSOR_RESOLUTION       4000

// POLARITY OF YOUR INCREMENTAL ENCODER (if applicable) [1, -1]
#define QEI_SENSOR_POLARITY         1


//////////////////////////////////////////////
//////  RECUPERATION MODE PARAMETERS
//////////////////////////////////////////////

/*
 * WARNING: explosion danger. This mode shoule not be activated before evaluating battery behaviour.
 * */

// For not affecting higher controlling levels (such as position control),
// RECUPERATION should be set to 1, and REGEN_P_MAX should be set to a much higher value than the rated power
// (such as 50 kW),

#define RECUPERATION        1          // when RECUPERATION is 0, there will be no recuperation

#define BATTERY_E_MAX       80         // maximum energy status of battery
#define BATTERY_E_MIN       10         // minimum energy status of battery

#define REGEN_P_MAX         50000      // maximum regenerative power (in Watts)
#define REGEN_P_MIN         0          // minimum regenerative power (in Watts)

#define REGEN_SPEED_MAX     650
#define REGEN_SPEED_MIN     50         // minimum value of the speed which is considered in regenerative calculations


//////////////////////////////////////////////
//////  PROTECTION CONFIGURATION
//////////////////////////////////////////////

#define I_MAX           100      //maximum tolerable value of phase current (under abnormal conditions)
#define V_DC_MAX        60      //maximum tolerable value of dc-bus voltage (under abnormal conditions)
#define V_DC_MIN        15      //minimum tolerable value of dc-bus voltave (under abnormal conditions)
#define TEMP_BOARD_MAX  100     //maximum tolerable value of board temperature (optional)


//////////////////////////////////////////////
//////  BRAKE CONFIGURATION
//////////////////////////////////////////////
/*
//MABI PROJECT
#define DUTY_START_BRAKE    12000   // duty cycles for brake release (should be a number between 1500 and 13000)
#define DUTY_MAINTAIN_BRAKE 2000    // duty cycles for keeping the brake released (should be a number between 1500 and 13000)
*/

//FORESIGHT PROJECT
#define DUTY_START_BRAKE    10000   // duty cycles for brake release (should be a number between 1500 and 13000)
#define DUTY_MAINTAIN_BRAKE 1500    // duty cycles for keeping the brake released (should be a number between 1500 and 13000)

#define PERIOD_START_BRAKE  1000    // period in which high voltage is applied for realising the brake [milli-seconds]

//////////////////////////////////////////////
//////  MOTOR COMMUTATION CONFIGURATION
//////////////////////////////////////////////

#define VDC             24

// COMMUTATION LOOP PERIOD (if applicable) [us]
#define COMMUTATION_LOOP_PERIOD     66

// COMMUTATION CW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CLK      750

// COMMUTATION CCW SPIN OFFSET (if applicable) [0:4095]
#define COMMUTATION_OFFSET_CCLK     0

// MOTOR POLARITY [NORMAL_POLARITY, INVERTED_POLARITY]
#define MOTOR_POLARITY              NORMAL_POLARITY


///////////////////////////////////////////////
//////  MOTOR CONTROL CONFIGURATION
///////////////////////////////////////////////

// CONTROL LOOP PERIOD [us]
#define CONTROL_LOOP_PERIOD     1000

// PID FOR POSITION CONTROL (if applicable) [will be divided by 10000]
//#define POSITION_Kp       100
//#define POSITION_Ki       1
//#define POSITION_Kd       0

// PID FOR VELOCITY CONTROL (if applicable) [will be divided by 10000]
//#define VELOCITY_Kp       667
//#define VELOCITY_Ki       200
//#define VELOCITY_Kd       0

// PID FOR TORQUE CONTROL (if applicable) [will be divided by 10000]
#define TORQUE_Kp         40 //7
#define TORQUE_Ki         160  //3
#define TORQUE_Kd         0

// (maximum) generated torque while finding offset value as a percentage of rated torque
#define PERCENT_OFFSET_TORQUE 50


/////////////////////////////////////////////////
//////  PROFILES AND LIMITS CONFIGURATION
/////////////////////////////////////////////////

// POLARITY OF THE MOVEMENT OF YOUR MOTOR [1,-1]
#define POLARITY           1

// DEFAULT PROFILER SETTINGS FOR PROFILE ETHERCAT DRIVE
#define PROFILE_VELOCITY        1000        // rpm
#define PROFILE_ACCELERATION    2000        // rpm/s
#define PROFILE_DECELERATION    2000        // rpm/s
#define PROFILE_TORQUE_SLOPE    400         // adc_ticks

// PROFILER LIMITIS
//#define MAX_POSITION_LIMIT      0x7fffffff        // ticks (max range: 2^30, limited for safe operation)
//#define MIN_POSITION_LIMIT     -0x7fffffff        // ticks (min range: -2^30, limited for safe operation)
//#define MAX_VELOCITY            7000              // rpm
#define MAX_ACCELERATION        7000            // rpm/s
#define MAX_DECELERATION        7000            // rpm/s
#define MAX_CURRENT_VARIATION   800             // adc_ticks/s
#define MAX_CURRENT             800             // adc_ticks




// A1 Position Controller Config
// **motor offset: 2090
/*#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
#define MAX_VELOCITY            200             // rpm
#define MAX_TORQUE              1200000

#define POSITION_Kp             80
#define POSITION_Ki             20
#define POSITION_Kd             0
#define VELOCITY_Kp             60
#define VELOCITY_Ki             0
#define VELOCITY_Kd             60

#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         8
#define POSITION_FC             78
#define VELOCITY_REF_FC         25
#define VELOCITY_FC             80
#define VELOCITY_D_FC           80*/
//


// A2 Position Controller Config
// **motor offset: 1415
/*#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
#define MAX_VELOCITY            200             // rpm
#define MAX_TORQUE              1200000

#define POSITION_Kp             40
#define POSITION_Ki             50
#define POSITION_Kd             0
#define VELOCITY_Kp             60
#define VELOCITY_Ki             0
#define VELOCITY_Kd             65

#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         5
#define POSITION_FC             80
#define VELOCITY_REF_FC         35
#define VELOCITY_FC             77
#define VELOCITY_D_FC           75*/
//



// A3 Position Controller Config
// **motor offset: 740
/*#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
#define MAX_VELOCITY            200             // rpm
#define MAX_TORQUE              1200000

#define POSITION_Kp             40
#define POSITION_Ki             40
#define POSITION_Kd             0
#define VELOCITY_Kp             45
#define VELOCITY_Ki             0
#define VELOCITY_Kd             50

#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         10
#define POSITION_FC             82
#define VELOCITY_REF_FC         28
#define VELOCITY_FC             77
#define VELOCITY_D_FC           75*/
//


// A4 Position Controller Config
// **motor offset: 740
/*#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
#define MAX_VELOCITY            200             // rpm
#define MAX_TORQUE              1200000

#define POSITION_Kp             40
#define POSITION_Ki             30
#define POSITION_Kd             0
#define VELOCITY_Kp             55
#define VELOCITY_Ki             0
#define VELOCITY_Kd             50

#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         15
#define POSITION_FC             80
#define VELOCITY_REF_FC         45
#define VELOCITY_FC             78
#define VELOCITY_D_FC           75*/
//


// A5 Position Controller Config
// **motor offset: 740
/*#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
#define MAX_VELOCITY            200             // rpm
#define MAX_TORQUE              1000000

#define POSITION_Kp             35
#define POSITION_Ki             20
#define POSITION_Kd             0
#define VELOCITY_Kp             30
#define VELOCITY_Ki             0
#define VELOCITY_Kd             40

#define POSITION_P_ERROR_lIMIT  40000
#define POSITION_I_ERROR_lIMIT  5
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  200000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         25
#define POSITION_FC             82
#define VELOCITY_REF_FC         28
#define VELOCITY_FC             77
#define VELOCITY_D_FC           75*/
//


// A6 Position Controller Config
//**motor offset: 740
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            200             // rpm
//#define MAX_TORQUE              1000000
//
//#define POSITION_Kp             35
//#define POSITION_Ki             20
//#define POSITION_Kd             0
//#define VELOCITY_Kp             30
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             40
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  5
//#define POSITION_INTEGRAL_LIMIT 10000
//#define VELOCITY_P_ERROR_lIMIT  200000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         25
//#define POSITION_FC             82
//#define VELOCITY_REF_FC         28
//#define VELOCITY_FC             77
//#define VELOCITY_D_FC           75


// AMK or qmot
//**motor offset: AMK 2470, qmot 3450
#define MIN_POSITION_LIMIT     -0x7fffffff         // ticks (min range: -2^30, limited for safe operation)
#define MAX_POSITION_LIMIT      0x7fffffff         // ticks (max range: 2^30, limited for safe operation)
#define MAX_SPEED               3000             // rpm
#define TORQUE_CONTROL_LIMIT    1200000

#define POSITION_Kp             100
#define POSITION_Ki             80
#define POSITION_Kd             0
#define VELOCITY_Kp             90
#define VELOCITY_Ki             100
#define VELOCITY_Kd             0

#define POSITION_P_ERROR_lIMIT  2000000000
#define POSITION_I_ERROR_lIMIT  1
#define POSITION_INTEGRAL_LIMIT 10000
#define VELOCITY_P_ERROR_lIMIT  2000000000
#define VELOCITY_I_ERROR_lIMIT  0
#define VELOCITY_INTEGRAL_LIMIT 0
#define POSITION_REF_FC         1
#define POSITION_FC             100
#define VELOCITY_REF_FC         1
#define VELOCITY_FC             90
#define VELOCITY_D_FC           90


// Foresight: Joint 1 Position Controller Config
//**motor offset: 2040
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            1200             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             180
//#define POSITION_Ki             30
//#define POSITION_Kd             0
//#define VELOCITY_Kp             30
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             40
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  5
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  150000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60


// Foresight: Joint 2 Position Controller Config
//**motor offset: 2000
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            10000             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             300
//#define POSITION_Ki             100
//#define POSITION_Kd             0
//#define VELOCITY_Kp             15
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             5
//
//#define POSITION_P_ERROR_lIMIT  50000
//#define POSITION_I_ERROR_lIMIT  5
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  800000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60


// Foresight: Joint 3 Position Controller Config
//**motor offset: 300
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            1200             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             170
//#define POSITION_Ki             35
//#define POSITION_Kd             0
//#define VELOCITY_Kp             38
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             35
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  5
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  150000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60


// Foresight: Joint 4 Position Controller Config
//**motor offset: 330
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            1200             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             150
//#define POSITION_Ki             30
//#define POSITION_Kd             0
//#define VELOCITY_Kp             25
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             10
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  10
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  150000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60



// Foresight: Joint 5 Position Controller Config
//**motor offset: 1665
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            1200             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             210
//#define POSITION_Ki             40
//#define POSITION_Kd             0
//#define VELOCITY_Kp             25
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             15
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  4
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  150000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60



// Foresight: Joint 6 Position Controller Config
//**motor offset: 2850
//#define MIN_POSITION_LIMIT     -1500000         // ticks (min range: -2^30, limited for safe operation)
//#define MAX_POSITION_LIMIT      1500000         // ticks (max range: 2^30, limited for safe operation)
//#define MAX_VELOCITY            2500             // rpm
//#define MAX_TORQUE              1200000
//
//#define POSITION_Kp             250
//#define POSITION_Ki             90
//#define POSITION_Kd             0
//#define VELOCITY_Kp             25
//#define VELOCITY_Ki             0
//#define VELOCITY_Kd             10
//
//#define POSITION_P_ERROR_lIMIT  40000
//#define POSITION_I_ERROR_lIMIT  4
//#define POSITION_INTEGRAL_LIMIT 25000
//#define VELOCITY_P_ERROR_lIMIT  150000
//#define VELOCITY_I_ERROR_lIMIT  0
//#define VELOCITY_INTEGRAL_LIMIT 0
//#define POSITION_REF_FC         140
//#define POSITION_FC             80
//#define VELOCITY_REF_FC         100
//#define VELOCITY_FC             80
//#define VELOCITY_D_FC           60
