
/**
 * @file common_config.h
 * @brief common internal configurations
 * @author Pavan Kanajar <pkanajar@synapticon.com>
 */

#define QEI_WITH_INDEX				1
#define QEI_WITH_NO_INDEX 			0

#define DC100_RESOLUTION 			740 	// resolution/A
#define DC300_RESOLUTION			400 	// resolution/A
#define OLD_DC300_RESOLUTION		264 	// resolution/A

#define HALL 						1
#define QEI_INDEX  					2
#define QEI_NO_INDEX				3

#define STAR_WINDING				1
#define DELTA_WINDING				2

#define HOMING_NEGATIVE_SWITCH		1
#define HOMING_POSITIVE_SWITCH		2

#define ACTIVE_HIGH					1       // the switch output is high upon activation
#define ACTIVE_LOW					2		// the switch output is low upon activation

#define QEI_POLARITY_NORMAL				0
#define QEI_POLARITY_INVERTED			1
