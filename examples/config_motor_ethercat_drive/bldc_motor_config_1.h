/**
 * @file bldc_motor_config_1.h
 * @brief Motor Control config file for motor 1 (Please define your the motor specifications here)
 * @author Synapticon GmbH (www.synapticon.com)
 */

#ifndef _MOTOR_1
#define _MOTOR_1

/**
 * Define Motor Specific Constants (found in motor specification sheet)
 * Mandatory constants to be set
 */
#define POLE_PAIRS_1  				4	 	// Number of pole pairs
#define MAX_NOMINAL_SPEED_1  			4000	// rpm
#define MAX_NOMINAL_CURRENT_1  			2		// A
#define MOTOR_TORQUE_CONSTANT_1			72		// mNm/A

/**
 * If you have any gears added, specify gear-ratio
 * and any additional encoders attached specify encoder resolution here (Mandatory)
 */
#define GEAR_RATIO_1 				1		// if no gears are attached - set to gear ratio to 1
#define ENCODER_RESOLUTION_1          		4000            // Resolution of Incremental Encoder

/* Somanet IFM Internal Configuration:  Specifies the current sensor resolution per Ampere
 *  (DC300_RESOLUTION / DC100_RESOLUTION / OLD_DC300_RESOLUTION) */
#define IFM_RESOLUTION_1			DC100_RESOLUTION

/* Position Sensor Types (select your sensor type here)
 * (HALL/ QEI_WITH_INDEX/ QEI_NO_INDEX) */
#define SENSOR_SELECTION_CODE_1          	QEI_WITH_INDEX

/* Polarity is used to keep all position sensors to count ticks in the same direction
 *  (QEI_POLARITY_NORMAL/QEI_POLARITY_INVERTED) */
#define QEI_SENSOR_POLARITY_1			QEI_POLARITY_NORMAL

/* Commutation offset (range 0-4095) (HALL sensor based commutation) */
#define COMMUTATION_OFFSET_CLK_1		910
#define COMMUTATION_OFFSET_CCLK_1		2460

/* Motor Winding type (STAR_WINDING/DELTA_WINDING) */
#define WINDING_TYPE_1				DELTA_WINDING

/* Specify Switch Types (ACTIVE_HIGH/ACTIVE_LOW) when switch is closed
 * (Only if you have any limit switches in the system for safety/homing ) */
#define LIMIT_SWITCH_TYPES_1			ACTIVE_HIGH

/* Define Homing method (HOMING_POSITIVE_SWITCH/HOMING_NEGATIVE_SWITCH)
 * this specifies direction for the motor to find the home switch */
#define HOMING_METHOD_1                 	HOMING_NEGATIVE_SWITCH

/* Changes direction of the motor drive  (1 /-1) */
#define POLARITY_1 						1

/* Profile defines (Mandatory for profile modes) */
#define MAX_PROFILE_VELOCITY_1  		MAX_NOMINAL_SPEED_1
#define PROFILE_VELOCITY_1			1000	// rpm
#define MAX_ACCELERATION_1   			4000    // rpm/s
#define PROFILE_ACCELERATION_1			2000	// rpm/s
#define PROFILE_DECELERATION_1  		2000	// rpm/s
#define QUICK_STOP_DECELERATION_1 		2500 	// rpm/s
#define MAX_TORQUE_1				MOTOR_TORQUE_CONSTANT_1 * IFM_RESOLUTION_1 * MAX_NOMINAL_CURRENT_1 // calculated
#define TORQUE_SLOPE_1 				66 		// mNm/s


/* Control specific constants/variables */
	/* Torque Control (Mandatory if Torque control used)
	 * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
	 * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#define TORQUE_Kp_NUMERATOR_1 	   		2
#define TORQUE_Kp_DENOMINATOR_1  		10
#define TORQUE_Ki_NUMERATOR_1    		1
#define TORQUE_Ki_DENOMINATOR_1  		110
#define TORQUE_Kd_NUMERATOR_1    		0
#define TORQUE_Kd_DENOMINATOR_1  		10

	/* Velocity Control (Mandatory if Velocity control used)
	 * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
	 * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#define VELOCITY_Kp_NUMERATOR_1 		1
#define VELOCITY_Kp_DENOMINATOR_1  		15
#define VELOCITY_Ki_NUMERATOR_1    		2
#define VELOCITY_Ki_DENOMINATOR_1  		100
#define VELOCITY_Kd_NUMERATOR_1   		0
#define VELOCITY_Kd_DENOMINATOR_1 		1

	/* Position Control (Mandatory if Position control used)
	 * possible range of gains Kp/Ki/Kd: 1/65536 to 32760
	 * Note: gains are calculated as NUMERATOR/DENOMINATOR to give ranges */
#if(SENSOR_SELECTION_CODE_1 == HALL)		// PID gains for position control with Hall Sensor

	#define POSITION_Kp_NUMERATOR_1 	 	100
	#define POSITION_Kp_DENOMINATOR_1  		1000
	#define POSITION_Ki_NUMERATOR_1    		5
	#define POSITION_Ki_DENOMINATOR_1  		1200
	#define POSITION_Kd_NUMERATOR_1    		0
	#define POSITION_Kd_DENOMINATOR_1  		1000
	#define MAX_POSITION_LIMIT_1 			POLE_PAIRS_1*HALL_POSITION_INTERPOLATED_RANGE*GEAR_RATIO_1	// ticks (max range: 2^30, limited for safe operation)
	#define MIN_POSITION_LIMIT_1			-POLE_PAIRS_1*HALL_POSITION_INTERPOLATED_RANGE*GEAR_RATIO_1	// ticks (min range: -2^30, limited for safe operation)

#else // PID gains for position control with other Encoders
	#define POSITION_Kp_NUMERATOR_1         100
	#define POSITION_Kp_DENOMINATOR_1       1000
	#define POSITION_Ki_NUMERATOR_1         5
	#define POSITION_Ki_DENOMINATOR_1       1200
	#define POSITION_Kd_NUMERATOR_1         0
	#define POSITION_Kd_DENOMINATOR_1       100
	#define MAX_POSITION_LIMIT_1            GEAR_RATIO_1*ENCODER_RESOLUTION_1*QEI_CHANGES_PER_TICK*10       // ticks (max range: 2^30, limited for safe operation)
	#define MIN_POSITION_LIMIT_1            -GEAR_RATIO_1*ENCODER_RESOLUTION_1*QEI_CHANGES_PER_TICK*10      // ticks (min range: -2^30, limited for safe operation)

#endif

#endif

