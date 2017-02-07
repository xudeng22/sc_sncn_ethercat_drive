/**
 * @file config_manager.xc
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include <dictionary_symbols.h>
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
        PositionFeedbackConfig &config,
        int sensor_index)
{
    config = i_pos_feedback.get_config();

    uint16_t feedback_sensor_object = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_LIST, sensor_index);

    int old_sensor_type = config.sensor_type;
    config.sensor_type = i_coe.get_object_value(feedback_sensor_object, DICT_SUB_FEEDBACK_SENSOR_TYPE);

    switch (config.sensor_type) {
    case FEEDBACK_SENSOR_QEI:
        config.qei_config.index_type  = i_coe.get_object_value(DICT_QEI_SENSOR, DICT_SUB_NUMBER_OF_CHANNELS);
        config.qei_config.signal_type = i_coe.get_object_value(DICT_QEI_SENSOR, DICT_SUB_ACCESS_SIGNAL_TYPE);
        break;

    case FEEDBACK_SENSOR_BISS:
        config.biss_config.multiturn_resolution   = i_coe.get_object_value(DICT_BISS_SENSOR, DICT_SUB_MULTITURN_RESOLUTION);
        config.biss_config.singleturn_resolution  = i_coe.get_object_value(DICT_BISS_SENSOR, DICT_SUB_SINGLETURN_RESOLUTION);
        /* FIXME `clock_divident` is not part of the objdict record for the BISS sensor, instead there is a
         * entry `clock`. Where does this belong and how is it used? */
        //config.biss_config.clock_divdent          = i_coe.get_object_value(DICT_BISS_SENSOR, DICT_SUB_CLOCK);
        config.biss_config.clock_divisor          = i_coe.get_object_value(DICT_BISS_SENSOR, DICT_SUB_CLOCK_DIVISOR);
        config.biss_config.timeout                = i_coe.get_object_value(DICT_BISS_SENSOR, DICT_SUB_TIMEOUT);
        break;
    case FEEDBACK_SENSOR_UNDEFINED: /* FIXME need error handling here, or in position feedback service */
        break;

    default: /* REM16MT, REM14 and HALL don't need any special handling */
        break;
    }

    // FIXME the polarity object changed to a uint8_t bitfield with
    // - bit 7: polarity for position
    // - bit 6: polarity for velocity
    // where to figure out which polarity is necessary ot use?
    //config.polarity       = sext(i_coe.get_object_value(DICT_POLARITY, 0), 8);
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    if ((polarity & 0xC0) != 0) {
        config.polarity = -1;
    } else {
        config.polarity = 1;
    }
    config.pole_pairs     = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_POLE_PAIRS);
    config.resolution = i_coe.get_object_value(feedback_sensor_object, DICT_SUB_FEEDBACK_RESOLUTION);

    i_pos_feedback.set_config(config);
    if (old_sensor_type != config.sensor_type) { //restart the service if the sensor type is changed
        i_pos_feedback.exit();
    }
}

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    //motorcontrol_config.bldc_winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */

    motorcontrol_config.pole_pair          = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_POLE_PAIRS);
    motorcontrol_config.max_torque         = i_coe.get_object_value(DICT_MAX_TORQUE, 0);
    motorcontrol_config.max_current        = i_coe.get_object_value(DICT_MAX_CURRENT, 0);
    motorcontrol_config.rated_current      = i_coe.get_object_value(DICT_MOTOR_RATED_CURRENT, 0);
    motorcontrol_config.rated_torque       = i_coe.get_object_value(DICT_MOTOR_RATED_TORQUE, 0);
    motorcontrol_config.commutation_angle_offset = i_coe.get_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0);
    motorcontrol_config.current_P_gain     = i_coe.get_object_value(DICT_TORQUE_PID, 1);
    motorcontrol_config.current_I_gain     = i_coe.get_object_value(DICT_TORQUE_PID, 2);
    motorcontrol_config.current_D_gain     = i_coe.get_object_value(DICT_TORQUE_PID, 3);

    /* These are motor specific maybe we introduce a new object */
    motorcontrol_config.phase_resistance   = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_PHASE_RESISTANCE);
    motorcontrol_config.phase_inductance   = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_PHASE_INDUCTANCE);
//    motorcontrol_config.v_dc; /* FIXME currently not setable - should it be? */

    motorcontrol_config.protection_limit_over_current = i_coe.get_object_value(DICT_MAX_CURRENT, 0);//motorcontrol_config.max_current;
    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    /* FIXME check the parameters - are they acutally used? */
    profiler.max_velocity     =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    //profiler.velocity         =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    profiler.acceleration     =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    profiler.deceleration     =  i_coe.get_object_value(DICT_PROFILE_DECELERATION, 0);
    profiler.max_deceleration =  i_coe.get_object_value(DICT_QUICK_STOP_DECELERATION, 0); /* */
    profiler.min_position     =  i_coe.get_object_value(DICT_POSITION_LIMIT, 1);
    profiler.max_position     =  i_coe.get_object_value(DICT_POSITION_LIMIT, 2);
    /* FIXME does this belong here? */
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    if ((polarity & 0xC0) != 0) {
        profiler.polarity = -1;
    } else {
        profiler.polarity = 1;
    }
    //profiler.max_acceleration =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0); /* */
}

void cm_sync_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control,
        PosVelocityControlConfig &position_config)
{
    i_position_control.get_position_velocity_control_config();

    position_config.min_pos = i_coe.get_object_value(DICT_POSITION_LIMIT, 1);  /* -8000; */
    position_config.max_pos = i_coe.get_object_value(DICT_POSITION_LIMIT, 2);  /* 8000; */
    /* FIXME does this belong here? */
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    if ((polarity & 0xC0) != 0) {
        position_config.polarity = -1;
    } else {
        position_config.polarity = 1;
    }
    position_config.P_pos          = i_coe.get_object_value(DICT_POSITION_PID, 1); /* POSITION_P_VALUE; */
    position_config.I_pos          = i_coe.get_object_value(DICT_POSITION_PID, 2); /* POSITION_I_VALUE; */
    position_config.D_pos          = i_coe.get_object_value(DICT_POSITION_PID, 3); /* POSITION_D_VALUE; */
    //position_config.int32_cmd_limit_position     = i_coe.get_object_value(DICT_POSITION_LIMIT, 2);/* 15000; */
    //position_config.int32_cmd_limit_position_min = i_coe.get_object_value(DICT_POSITION_LIMIT, 1);/* 15000; */

    position_config.max_speed           = i_coe.get_object_value(DICT_MAX_MOTOR_SPEED, 0); /* 15000; */
    // FIXME use this in the future ESI: position_config.max_speed           = i_coe.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    position_config.max_torque          = i_coe.get_object_value(DICT_MAX_TORQUE, 0);
    position_config.P_velocity          = i_coe.get_object_value(DICT_VELOCITY_PID, 1); /* 18; */
    position_config.I_velocity          = i_coe.get_object_value(DICT_VELOCITY_PID, 2); /* 22; */
    position_config.D_velocity          = i_coe.get_object_value(DICT_VELOCITY_PID, 2); /* 25; */

    //FIXME use a proper object to set the control mode
    switch(i_coe.get_object_value(DICT_POSITION_CONTROL_STRATEGY, 0))
    //set integral limits depending on the mode
    {
    case POS_PID_CONTROLLER:
        position_config.control_mode = POS_PID_CONTROLLER;
        position_config.integral_limit_pos = position_config.max_torque; //set pos integral limit = max torque
        break;
    case POS_PID_VELOCITY_CASCADED_CONTROLLER:
        position_config.control_mode = POS_PID_VELOCITY_CASCADED_CONTROLLER;
        position_config.integral_limit_pos = position_config.max_speed; //set pos integral limit = max speed
        break;
    default:
        position_config.control_mode = NL_POSITION_CONTROLLER;
        position_config.integral_limit_pos = 1000; //set pos integral limit = max torque
        break;
    }
    position_config.integral_limit_velocity = position_config.max_torque; //set vel integral limit = max torque


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
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index)
{
    config = i_pos_feedback.get_config();

    uint16_t feedback_sensor_index = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_LIST, sensor_index);
    i_coe.set_object_value(feedback_sensor_index, DICT_SUB_FEEDBACK_SENSOR_TYPE, config.sensor_type);
    i_coe.set_object_value(feedback_sensor_index, DICT_SUB_FEEDBACK_RESOLUTION, config.resolution);
    // @see FIXME in cm_sync_config_position_feedback()!
    if (config.polarity == -1) {
        i_coe.set_object_value(DICT_POLARITY, 0, 0xC0);
    } else {
        i_coe.set_object_value(DICT_POLARITY, 0, 0x0);
    }

    if (config.pole_pairs != 0)
        i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_POLE_PAIRS, config.pole_pairs);
}

void cm_default_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    //motorcontrol_config.bldc_winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */

    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_POLE_PAIRS, motorcontrol_config.pole_pair);
    i_coe.set_object_value(DICT_MAX_TORQUE, 0, motorcontrol_config.max_torque);
    //i_coe.set_object_value(DICT_POLARITY, 0, motorcontrol_config.polarity_type); /* ??? FIXME the object DICT_POLARITY is for the sensor! */
    //motorcontrol_config.max_current        = i_coe.get_object_value(DICT_MAX_CURRENT, 0);
    //motorcontrol_config.rated_current      = i_coe.get_object_value(DICT_MOTOR_RATED_CURRENT, 0);
    //motorcontrol_config.rated_torque       = i_coe.get_object_value(DICT_MOTOR_RATED_TORQUE, 0);
    i_coe.set_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0, motorcontrol_config.commutation_angle_offset);
    i_coe.set_object_value(DICT_TORQUE_PID, 1, motorcontrol_config.current_P_gain);
    i_coe.set_object_value(DICT_TORQUE_PID, 2, motorcontrol_config.current_I_gain);
    i_coe.set_object_value(DICT_TORQUE_PID, 3, motorcontrol_config.current_D_gain);

    /* These are motor specific maybe we introduce a new object */
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_PHASE_RESISTANCE, motorcontrol_config.phase_resistance);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, DICT_SUB_PHASE_INDUCTANCE, motorcontrol_config.phase_inductance);
    i_coe.set_object_value(DICT_MAX_CURRENT, 0, motorcontrol_config.protection_limit_over_current);//motorcontrol_config.max_current;

//    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_default_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    /* FIXME check the objects */
    //profiler.max_velocity     =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    //profiler.velocity         =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    //profiler.acceleration     =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    //profiler.deceleration     =  i_coe.get_object_value(DICT_PROFILE_DECELERATION, 0);
    //profiler.max_deceleration =  i_coe.get_object_value(DICT_QUICK_STOP_DECELERATION, 0); /* */
    i_coe.set_object_value(DICT_POSITION_LIMIT, 1, profiler.min_position);
    i_coe.set_object_value(DICT_POSITION_LIMIT, 2, profiler.max_position);
    //i_coe.set_object_value(DICT_POLARITY, 0,            profiler.polarity);
    //profiler.max_acceleration =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0); /* */
}

void cm_default_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control
        )
{
    PosVelocityControlConfig position_config = i_position_control.get_position_velocity_control_config();

    i_coe.set_object_value(DICT_POSITION_LIMIT,  1, position_config.min_pos);  /* -8000; */
    i_coe.set_object_value(DICT_POSITION_LIMIT,  2, position_config.max_pos);  /* 8000; */
    //i_coe.set_object_value(DICT_POLARITY, 0, position_config.polarity);
    i_coe.set_object_value(DICT_POSITION_PID, 1, position_config.P_pos); /* POSITION_P_VALUE; */
    i_coe.set_object_value(DICT_POSITION_PID, 2, position_config.I_pos); /* POSITION_I_VALUE; */
    i_coe.set_object_value(DICT_POSITION_PID, 3, position_config.D_pos); /* POSITION_D_VALUE; */
    //position_config._cmd_limit_position     = i_coe.get_object_value(DICT_POSITION_LIMIT, 2);/* 15000; */
    //position_config._cmd_limit_position_min = i_coe.get_object_value(DICT_POSITION_LIMIT, 1);/* 15000; */

    i_coe.set_object_value(DICT_MAX_MOTOR_SPEED, 0, position_config.max_speed); /* 15000; */
    // FIXME use this in the future ESI: position_config._max_speed           = i_coe.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    i_coe.set_object_value(DICT_MAX_TORQUE, 0,    position_config.max_torque);
    i_coe.set_object_value(DICT_VELOCITY_PID, 1, position_config.P_velocity); /* 18; */
    i_coe.set_object_value(DICT_VELOCITY_PID, 2, position_config.I_velocity); /* 22; */
    i_coe.set_object_value(DICT_VELOCITY_PID, 3, position_config.D_velocity); /* 25; */

    //i_coe.set_object_value(DICT_POSITION_CONTROL_STRATEGY, 0, position_config.control_mode);

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
