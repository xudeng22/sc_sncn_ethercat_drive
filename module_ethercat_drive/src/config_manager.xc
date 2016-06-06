/**
 * @file config_manager.xc
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include <canod.h>
#include <position_feedback_service.h>
#include "config_manager.h"

struct _config_object {
    uint16_t index;
    uint8_t subindex;
    uint8_t type;
};


static int tick2bits(int tick_resolution)
{
    unsigned r = 0;

    while (tick_resolution >>= 1) {
        r++;
    }

    return r;
}

void cm_sync_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config)
{
    config.sensor_type = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
    int tick_resolution = i_coe.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);
    int bit_resolution = tick2bits(tick_resolution);

    config.biss_config.singleturn_resolution = bit_resolution;
    config.contelec_config.resolution_bits   = bit_resolution;


    config.biss_config.polarity       = i_coe.get_object_value(SENSOR_POLARITY, 0);
    config.contelec_config.polarity   = i_coe.get_object_value(SENSOR_POLARITY, 0);
    config.biss_config.pole_pairs     = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);
    config.contelec_config.pole_pairs = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);
}

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_commutation,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_commutation))
        return;

    motorcontrol_config = i_commutation.get_config();

    motorcontrol_config.bldc_winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */
    motorcontrol_config.hall_offset[0] = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);;
    motorcontrol_config.hall_offset[1] = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);;

    i_commutation.set_config(motorcontrol_config);
}

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    profiler.max_velocity     =  i_coe.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
    profiler.velocity         =  i_coe.get_object_value(CIA402_PROFILE_VELOCITY, 0);
    profiler.acceleration     =  i_coe.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
    profiler.deceleration     =  i_coe.get_object_value(CIA402_PROFILE_DECELERATION, 0);
    profiler.max_deceleration =  i_coe.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0);
    profiler.min_position     =  i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
    profiler.max_position     =  i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
    profiler.polarity         =  i_coe.get_object_value(CIA402_POLARITY, 0);
    profiler.max_acceleration =  i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);
}

