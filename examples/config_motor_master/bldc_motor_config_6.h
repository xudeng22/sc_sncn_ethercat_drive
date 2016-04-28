/**
 * @file bldc_motor_config_6.h
 * @brief Motor Control config file for motor 6 (Please define your the motor specifications here)
 * @author Synapticon GmbH (www.synapticon.com)
 */

#ifndef _MOTOR_6
#define _MOTOR_6
//#include <common_config.h>

/**
 * Define Motor Specific Constants (found in motor specification sheet)
 * Mandatory constants to be set
 */
#define POLE_PAIRS_6                    10       // Number of pole pairs
#define MAX_NOMINAL_SPEED_6             4000    // rpm
#define MAX_NOMINAL_CURRENT_6           2       // A
#define MOTOR_TORQUE_CONSTANT_6         72      // mNm/A

/**
 * If you have any gears added, specify gear-ratio
 * and any additional encoders attached specify encoder resolution here (Mandatory)
 */
#define GEAR_RATIO_6                    1       // if no gears are attached - set to gear ratio to 1
#define ENCODER_RESOLUTION_6            262144    // Resolution of Incremental Encoder

/* Somanet IFM Internal Configuration:  Specifies the current sensor resolution per Ampere
 *  (DC300_RESOLUTION / DC100_RESOLUTION / OLD_DC300_RESOLUTION) */
#define IFM_RESOLUTION_6                DC100_RESOLUTION

/* Position Sensor Types (select your sensor type here)
 * (HALL/ QEI_INDEX/ QEI_NO_INDEX) */
#define SENSOR_SELECTION_CODE_6         BISS_SENSOR

/* Polarity is used to keep all position sensors to count ticks in the same direction
 *  (QEI_POLARITY_NORMAL/QEI_POLARITY_INVERTED) */
#define QEI_SENSOR_POLARITY_6           QEI_POLARITY_NORMAL

/* Commutation offset (range 0-4095) (HALL sensor based commutation) */
#define COMMUTATION_OFFSET_CLK_6        2400
#define COMMUTATION_OFFSET_CCLK_6       2460

/* Motor Winding type (STAR_WINDING/DELTA_WINDING) */
#define WINDING_TYPE_6                  STAR_WINDING

/* Specify Switch Types (ACTIVE_HIGH/ACTIVE_LOW) when switch is closed
 * (Only if you have any limit switches in the system for safety/homing ) */
#define LIMIT_SWITCH_TYPES_6            ACTIVE_HIGH

/* Define Homing method (HOMING_POSITIVE_SWITCH/HOMING_NEGATIVE_SWITCH)
 * this specifies direction for the motor to find the home switch */
#define HOMING_METHOD_6                 HOMING_NEGATIVE_SWITCH

/* Changes direction of the motor drive  (1 /-1) */
#define POLARITY_6                      1

/* Profile defines (Mandatory for profile modes) */
#define MAX_PROFILE_VELOCITY_6          MAX_NOMINAL_SPEED_6
#define PROFILE_VELOCITY_6              1000    // rpm
#define MAX_ACCELERATION_6              4000    // rpm/s
#define PROFILE_ACCELERATION_6          2000    // rpm/s
#define PROFILE_DECELERATION_6          2000    // rpm/s
#define QUICK_STOP_DECELERATION_6       2500    // rpm/s
#define MAX_TORQUE_6                    MOTOR_TORQUE_CONSTANT_6 * IFM_RESOLUTION_6 * MAX_NOMINAL_CURRENT_6 // calculated
#define TORQUE_SLOPE_6                  66      // mNm/s


/* Control specific constants/variables */
    /* Torque Control (Mandatory if Torque control used)
     * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
     * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#define TORQUE_Kp_NUMERATOR_6           2
#define TORQUE_Kp_DENOMINATOR_6         10
#define TORQUE_Ki_NUMERATOR_6           1
#define TORQUE_Ki_DENOMINATOR_6         110
#define TORQUE_Kd_NUMERATOR_6           0
#define TORQUE_Kd_DENOMINATOR_6         10

    /* Velocity Control (Mandatory if Velocity control used)
     * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
     * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#define VELOCITY_Kp_NUMERATOR_6         1
#define VELOCITY_Kp_DENOMINATOR_6       15
#define VELOCITY_Ki_NUMERATOR_6         2
#define VELOCITY_Ki_DENOMINATOR_6       100
#define VELOCITY_Kd_NUMERATOR_6         0
#define VELOCITY_Kd_DENOMINATOR_6       1

    /* Position Control (Mandatory if Position control used)
     * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
     * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#if(SENSOR_SELECTION_CODE_6 == HALL)        // PID gains for position control with Hall Sensor
    #define POSITION_Kp_NUMERATOR_6         100
    #define POSITION_Kp_DENOMINATOR_6       1000
    #define POSITION_Ki_NUMERATOR_6         1
    #define POSITION_Ki_DENOMINATOR_6       1200
    #define POSITION_Kd_NUMERATOR_6         0
    #define POSITION_Kd_DENOMINATOR_6       1000
    #define MAX_POSITION_LIMIT_6            POLE_PAIRS_6*HALL_POSITION_INTERPOLATED_RANGE*GEAR_RATIO_6 * 10     // ticks (max range: 2^30, limited for safe operation) qei/hall/any position sensor
    #define MIN_POSITION_LIMIT_6            -POLE_PAIRS_6*HALL_POSITION_INTERPOLATED_RANGE*GEAR_RATIO_6 * 10    // ticks (min range: -2^30, limited for safe operation) qei/hall/any position sensor
#else // PID gains for position control with other Encoders
    #define POSITION_Kp_NUMERATOR_6     100    //Denominator is 10000
    #define POSITION_Ki_NUMERATOR_6     1   //Denominator is 10000
    #define POSITION_Kd_NUMERATOR_6     0   //Denominator is 10000

    #define MAX_POSITION_LIMIT_6        0x7fffffff       // ticks (max range: 2^30, limited for safe operation)
    #define MIN_POSITION_LIMIT_6        -0x7fffffff      // ticks (min range: -2^30, limited for safe operation)

#endif

#endif

