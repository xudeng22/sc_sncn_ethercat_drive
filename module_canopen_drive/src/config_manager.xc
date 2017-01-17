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
        client interface ODCommunicationInterface i_od,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config)
{
    config = i_pos_feedback.get_config();

    int old_sensor_type = config.sensor_type;
    {config.sensor_type, void, void} = i_od.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
    {config.polarity, void, void}    = i_od.get_object_value(SNCN_SENSOR_POLARITY, 0);
    config.polarity = sext(config.polarity, 8);
    {config.pole_pairs, void, void}     = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 3);
    {config.resolution, void, void} = i_od.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);

    i_pos_feedback.set_config(config);
    if (old_sensor_type != config.sensor_type) { //restart the service if the sensor type is changed
        i_pos_feedback.exit();
    }
}

void cm_sync_config_motor_control(
        client interface ODCommunicationInterface i_od,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    //{motorcontrol_config.bldc_winding_type, void, void} = i_od.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */

    {motorcontrol_config.pole_pair, void, void}          = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 3);
    {motorcontrol_config.max_torque, void, void}         = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 6);
    //{motorcontrol_config.max_current, void, void}        = i_od.get_object_value(CIA402_MAX_CURRENT, 0);
    //{motorcontrol_config.rated_current, void, void}      = i_od.get_object_value(CIA402_MOTOR_RATED_CURRENT, 0);
    //{motorcontrol_config.rated_torque, void, void}       = i_od.get_object_value(CIA402_MOTOR_RATED_TORQUE, 0);
    {motorcontrol_config.commutation_angle_offset, void, void} = i_od.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);
    {motorcontrol_config.current_P_gain, void, void}     = i_od.get_object_value(CIA402_CURRENT_GAIN, 1);
    {motorcontrol_config.current_I_gain, void, void}     = i_od.get_object_value(CIA402_CURRENT_GAIN, 2);
    {motorcontrol_config.current_D_gain, void, void}     = i_od.get_object_value(CIA402_CURRENT_GAIN, 3);

    /* These are motor specific maybe we introduce a new object */
    {motorcontrol_config.phase_resistance, void, void}   = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 2);
    {motorcontrol_config.phase_inductance, void, void}   = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 5);
//    motorcontrol_config.v_dc; /* FIXME currently not setable - should it be? */

    {motorcontrol_config.protection_limit_over_current, void, void} = i_od.get_object_value(CIA402_MAX_CURRENT, 0);//motorcontrol_config.max_current;
    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_sync_config_profiler(
        client interface ODCommunicationInterface i_od,
        ProfilerConfig &profiler)
{
    /* FIXME check the objects */
    //{profiler.max_velocity, void, void}     = i_od.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
    //{profiler.velocity, void, void}         = i_od.get_object_value(CIA402_PROFILE_VELOCITY, 0);
    //{profiler.acceleration, void, void}     = i_od.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
    //{profiler.deceleration, void, void}     = i_od.get_object_value(CIA402_PROFILE_DECELERATION, 0);
    //{profiler.max_deceleration, void, void} = i_od.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0); /* */
    {profiler.min_position, void, void}     = i_od.get_object_value(CIA402_POSITION_RANGELIMIT, 1);
    {profiler.max_position, void, void}     = i_od.get_object_value(CIA402_POSITION_RANGELIMIT, 2);
    {profiler.polarity, void, void}         = i_od.get_object_value(CIA402_POLARITY, 0);
    //{profiler.max_acceleration, void, void} = i_od.get_object_value(CIA402_MAX_ACCELERATION, 0); /* */
}

void cm_sync_config_pos_velocity_control(
        client interface ODCommunicationInterface i_od,
        client interface PositionVelocityCtrlInterface i_position_control,
        PosVelocityControlConfig &position_config)
{
    i_position_control.get_position_velocity_control_config();

    {position_config.min_pos, void, void} = i_od.get_object_value(CIA402_POSITION_RANGELIMIT, 1);  /* -8000; */
    {position_config.max_pos, void, void} = i_od.get_object_value(CIA402_POSITION_RANGELIMIT, 2);  /* 8000; */
    {position_config.polarity, void, void}       = i_od.get_object_value(CIA402_POLARITY, 0);
    {position_config.P_pos, void, void}          = i_od.get_object_value(CIA402_POSITION_GAIN, 1); /* POSITION_Kp; */
    {position_config.I_pos, void, void}          = i_od.get_object_value(CIA402_POSITION_GAIN, 2); /* POSITION_Ki; */
    {position_config.D_pos, void, void}          = i_od.get_object_value(CIA402_POSITION_GAIN, 3); /* POSITION_Kd; */
    //{position_config.int32_cmd_limit_position, void, void}     = i_od.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);/* 15000; */
    //{position_config.int32_cmd_limit_position_min, void, void} = i_od.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);/* 15000; */

    {position_config.max_speed, void, void}           = i_od.get_object_value(CIA402_MOTOR_SPECIFIC, 4); /* 15000; */
    // FIXME use this in the future ESI: {position_config.max_speed, void, void}           = i_od.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    {position_config.max_torque, void, void}          = i_od.get_object_value(CIA402_MAX_TORQUE, 0);
    {position_config.P_velocity, void, void}          = i_od.get_object_value(CIA402_VELOCITY_GAIN, 1); /* 18; */
    {position_config.I_velocity, void, void}          = i_od.get_object_value(CIA402_VELOCITY_GAIN, 2); /* 22; */
    {position_config.D_velocity, void, void}          = i_od.get_object_value(CIA402_VELOCITY_GAIN, 2); /* 25; */

    /* FIXME check if these parameters are somehow mappable to OD objects */
    //position_config.control_loop_period = CONTROL_LOOP_PERIOD; //us
    //position_config.int21_P_error_limit_position = 10000;
    //position_config.int21_I_error_limit_position = 0;
    //position_config.int22_integral_limit_position = 0;
    //position_config.int21_P_error_limit_velocity = 10000;
    //position_config.int21_I_error_limit_velocity =10;
    //position_config.int22_integral_limit_velocity = 1000;
    //position_config.int32_cmd_limit_velocity = 200000;

    i_position_control.set_position_velocity_control_config(position_config);
}

/*
 *  Set default parameters
 */

void cm_default_config_position_feedback(
        client interface ODCommunicationInterface i_od,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config)
{
    config = i_pos_feedback.get_config();

//    int tick_resolution = i_od.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);
//    int bit_resolution = tick2bits(tick_resolution);
    //config.biss_config.singleturn_resolution = bit_resolution;
    //config.contelec_config.resolution_bits   = bit_resolution;
//    int tick_resolution = i_od.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);

    i_od.set_object_value(CIA402_SENSOR_SELECTION_CODE, 0, config.sensor_type);
    i_od.set_object_value(CIA402_POSITION_ENC_RESOLUTION, 0, config.resolution);
    i_od.set_object_value(SNCN_SENSOR_POLARITY, 0, config.polarity);

    if (config.pole_pairs != 0)
        i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 3, config.pole_pairs);
}

void cm_default_config_motor_control(
        client interface ODCommunicationInterface i_od,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    //{motorcontrol_config.bldc_winding_type, void, void} = i_od.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */

    i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 3, motorcontrol_config.pole_pair);
    i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 6, motorcontrol_config.max_torque);
    //{motorcontrol_config.max_current, void, void}        = i_od.get_object_value(CIA402_MAX_CURRENT, 0);
    //{motorcontrol_config.rated_current, void, void}      = i_od.get_object_value(CIA402_MOTOR_RATED_CURRENT, 0);
    //{motorcontrol_config.rated_torque, void, void}       = i_od.get_object_value(CIA402_MOTOR_RATED_TORQUE, 0);
    i_od.set_object_value(COMMUTATION_OFFSET_CLKWISE, 0, motorcontrol_config.commutation_angle_offset);
    i_od.set_object_value(CIA402_CURRENT_GAIN, 1, motorcontrol_config.current_P_gain);
    i_od.set_object_value(CIA402_CURRENT_GAIN, 2, motorcontrol_config.current_I_gain);
    i_od.set_object_value(CIA402_CURRENT_GAIN, 3, motorcontrol_config.current_D_gain);

    /* These are motor specific maybe we introduce a new object */
    i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 2, motorcontrol_config.phase_resistance);
    i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 5, motorcontrol_config.phase_inductance);
    i_od.set_object_value(CIA402_MAX_CURRENT, 0, motorcontrol_config.protection_limit_over_current);//motorcontrol_config.max_current;

//    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_default_config_profiler(
        client interface ODCommunicationInterface i_od,
        ProfilerConfig &profiler)
{
    /* FIXME check the objects */
    //{profiler.max_velocity, void, void}     = i_od.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
    //{profiler.velocity, void, void}         = i_od.get_object_value(CIA402_PROFILE_VELOCITY, 0);
    //{profiler.acceleration, void, void}     = i_od.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
    //{profiler.deceleration, void, void}     = i_od.get_object_value(CIA402_PROFILE_DECELERATION, 0);
    //{profiler.max_deceleration, void, void} = i_od.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0); /* */
    i_od.set_object_value(CIA402_POSITION_RANGELIMIT, 1, profiler.min_position);
    i_od.set_object_value(CIA402_POSITION_RANGELIMIT, 2, profiler.max_position);
    //i_od.set_object_value(CIA402_POLARITY, 0,            profiler.polarity);
    //{profiler.max_acceleration, void, void} = i_od.get_object_value(CIA402_MAX_ACCELERATION, 0); /* */
}

void cm_default_config_pos_velocity_control(
        client interface ODCommunicationInterface i_od,
        client interface PositionVelocityCtrlInterface i_position_control
        )
{
    PosVelocityControlConfig position_config = i_position_control.get_position_velocity_control_config();

    i_od.set_object_value(CIA402_POSITION_RANGELIMIT,  1, position_config.min_pos);  /* -8000; */
    i_od.set_object_value(CIA402_POSITION_RANGELIMIT,  2, position_config.max_pos);  /* 8000; */
    i_od.set_object_value(CIA402_POLARITY, 0, position_config.polarity);
    i_od.set_object_value(CIA402_POSITION_GAIN, 1, position_config.P_pos); /* POSITION_Kp; */
    i_od.set_object_value(CIA402_POSITION_GAIN, 2, position_config.I_pos); /* POSITION_Ki; */
    i_od.set_object_value(CIA402_POSITION_GAIN, 3, position_config.D_pos); /* POSITION_Kd; */
    //{position_config._cmd_limit_position, void, void}     = i_od.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);/* 15000; */
    //{position_config._cmd_limit_position_min, void, void} = i_od.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);/* 15000; */

    i_od.set_object_value(CIA402_MOTOR_SPECIFIC, 4, position_config.max_speed); /* 15000; */
    // FIXME use this in the future ESI: {position_config._max_speed, void, void}           = i_od.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    i_od.set_object_value(CIA402_MAX_TORQUE, 0,    position_config.max_torque);
    i_od.set_object_value(CIA402_VELOCITY_GAIN, 1, position_config.P_velocity); /* 18; */
    i_od.set_object_value(CIA402_VELOCITY_GAIN, 2, position_config.I_velocity); /* 22; */
    i_od.set_object_value(CIA402_VELOCITY_GAIN, 2, position_config.D_velocity); /* 25; */

    /* FIXME check if these parameters are somehow mappable to OD objects */
    //position_config.control_loop_period = CONTROL_LOOP_PERIOD; //us
    //position_config.int21_P_error_limit_position = 10000;
    //position_config.int21_I_error_limit_position = 0;
    //position_config.int22_integral_limit_position = 0;
    //position_config.int21_P_error_limit_velocity = 10000;
    //position_config.int21_I_error_limit_velocity =10;
    //position_config.int22_integral_limit_velocity = 1000;
    //position_config.int32_cmd_limit_velocity = 200000;

    i_position_control.set_position_velocity_control_config(position_config);
}
