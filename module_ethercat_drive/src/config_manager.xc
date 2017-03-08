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

void cm_sync_config_hall_states(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        interface MotorcontrolInterface client ?i_motorcontrol,
        PositionFeedbackConfig &feedback_config,
        MotorcontrolConfig &motorcontrol_config,
        int sensor_index)
{
    if (feedback_config.sensor_type != HALL_SENSOR) {
        return;
    }

    uint16_t feedback_sensor_object = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_index);

    /* See Wrike https://www.wrike.com/workspace.htm#path=folder&id=127649023&a=1384194&c=list&t=135832278&ot=135832278&so=5&sd=0
     * for more information.
     */
    motorcontrol_config.commutation_sensor  = feedback_config.sensor_type;
    motorcontrol_config.hall_state_angle[0] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_0);
    motorcontrol_config.hall_state_angle[1] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_1);
    motorcontrol_config.hall_state_angle[2] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_2);
    motorcontrol_config.hall_state_angle[3] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_3);
    motorcontrol_config.hall_state_angle[4] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_4);
    motorcontrol_config.hall_state_angle[5] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_5);
}

void cm_sync_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index)
{
    config = i_pos_feedback.get_config();

    uint16_t feedback_sensor_object = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_index);

    /*
     *  FIXME the type of the sensor is currently not available from the dictionary.
     * See also https://www.wrike.com/open.htm?id=136659543 this is about to change
     */
    int old_sensor_type = config.sensor_type;

    //config.sensor_type = i_coe.get_object_value(feedback_sensor_object, DICT_SUB_FEEDBACK_SENSOR_TYPE);
    if (feedback_sensor_object == DICT_BISS_ENCODER_1 || feedback_sensor_object == DICT_BISS_ENCODER_2) {
        config.sensor_type = BISS_SENSOR;
    } else if (feedback_sensor_object == DICT_REM_16MT_ENCODER) {
        config.sensor_type = REM_16MT_SENSOR;
    } else if (feedback_sensor_object == DICT_REM_14_ENCODER) {
        config.sensor_type = REM_14_SENSOR;
    } else if (feedback_sensor_object == DICT_HALL_SENSOR_1 || feedback_sensor_object == DICT_HALL_SENSOR_2) {
        config.sensor_type = HALL_SENSOR;
    } else if (feedback_sensor_object == DICT_INCREMENTAL_ENCODER_1 || feedback_sensor_object == DICT_INCREMENTAL_ENCODER_2) {
        /* FIXME the QEI is now known as incremental encoder to the EtherCAT world. Needs to be fixed here too. */
        config.sensor_type = QEI_SENSOR;
    } else {
        config.sensor_type = 0;
    }

    switch (config.sensor_type) {
    case QEI_SENSOR:
        //i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_FUNCTION);
        config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_RESOLUTION);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_VELOCITY_CALCULATION_PERIOD);
        config.qei_config.index_type  = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS);
        config.qei_config.signal_type = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE);
        break;

    case BISS_SENSOR:
        //i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_FUNCTION);
        config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_RESOLUTION);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_VELOCITY_CALCULATION_PERIOD);
        config.biss_config.multiturn_resolution   = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_MULTITURN_RESOLUTION);
        config.biss_config.clock_frequency  = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_FREQUENCY);
        config.biss_config.timeout                = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_TIMEOUT);
        config.biss_config.crc_poly  = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CRC_POLYNOM);

        /* FIXME add check for valid enum data of clock_port_config */
        config.biss_config.clock_port_config = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_PORT_CONFIG);

        config.biss_config.data_port_config = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_DATA_PORT_CONFIG);
        config.biss_config.filling_bits = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS);
        config.biss_config.busy = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY);
        break;

    case HALL_SENSOR:
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_FUNCTION);
        config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_RESOLUTION);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_VELOCITY_CALCULATION_PERIOD);
        /* FIXME see cm_sync_config_hall_states() */
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_0);
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_1);
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_2);
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_3);
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_4);
        //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_5);
        break;

    case REM_14_SENSOR:
        //i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_FUNCTION);
        config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_RESOLUTION);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_VELOCITY_CALCULATION_PERIOD);

        config.rem_14_config.hysteresis      = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_HYSTERESIS);
        config.rem_14_config.noise_setting   = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_NOISE_SETTINGS);
        config.rem_14_config.dyn_angle_comp  = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_DYNAMIC_ANGLE_ERROR_COMPENSATION);
        config.rem_14_config.abi_resolution  = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_RESOLUTION_SETTINGS);
        break;

    case REM_16MT_SENSOR:
        //i_coe.get_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_FUNCTION);
        config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_RESOLUTION);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_VELOCITY_CALCULATION_PERIOD);

        config.rem_16mt_config.filter = i_coe.get_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_FILTER);
        break;

    case 0: /* FIXME need error handling here, or in position feedback service */
        break;

    default:
        break;
    }

    // FIXME the polarity object changed to a uint8_t bitfield with
    // - bit 7: polarity for position
    // - bit 6: polarity for velocity
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    if ((polarity & 0xC0) != 0) {
        config.polarity = -1;
    } else {
        config.polarity = 1;
    }
    config.pole_pairs = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS);
    //config.resolution = i_coe.get_object_value(feedback_sensor_object, SUB_RESOLUTION);

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

    motorcontrol_config.pole_pair          = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS);
    motorcontrol_config.max_torque         = i_coe.get_object_value(DICT_MAX_TORQUE, 0);
    motorcontrol_config.max_current        = i_coe.get_object_value(DICT_MAX_CURRENT, 0);
    motorcontrol_config.rated_current      = i_coe.get_object_value(DICT_MOTOR_RATED_CURRENT, 0);
    motorcontrol_config.rated_torque       = i_coe.get_object_value(DICT_MOTOR_RATED_TORQUE, 0);
    motorcontrol_config.commutation_angle_offset = i_coe.get_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0);
    motorcontrol_config.current_P_gain     = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KP);
    motorcontrol_config.current_I_gain     = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KI);
    motorcontrol_config.current_D_gain     = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KD);

    /* These are motor specific maybe we introduce a new object */
    motorcontrol_config.phase_resistance   = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE);
    motorcontrol_config.phase_inductance   = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE);
//    motorcontrol_config.v_dc; /* FIXME currently not setable - should it be? */

    motorcontrol_config.protection_limit_over_current = i_coe.get_object_value(DICT_MAX_CURRENT, 0); // FIXME aren't the protection limits separately?
    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler,
        enum eProfileType type)
{
    profiler.max_velocity     =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    profiler.acceleration     =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    profiler.deceleration     =  i_coe.get_object_value(DICT_PROFILE_DECELERATION, 0);
    profiler.max_acceleration =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    profiler.velocity         =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    /* FIXME this profiler is only used for Quick Stop so the max deceleration is read from the quick stop deceleration */
    profiler.max_deceleration =  i_coe.get_object_value(DICT_QUICK_STOP_DECELERATION, 0);
    profiler.min_position     =  i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, 1);
    profiler.max_position     =  i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, 2);
    /* FIXME does this belong here? */
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    switch (type) {
    case PROFILE_TYPE_POSITION:
        profiler.polarity = ((polarity & 0x80) != 0) ? -1 : 1;
        break;
    case PROFILE_TYPE_VELOCITY:
        profiler.polarity = ((polarity & 0x40) != 0) ? -1 : 1;
        break;
    default:
        profiler.polarity = 0;
        break;
    }
}

void cm_sync_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control,
        PosVelocityControlConfig &position_config)
{
    i_position_control.get_position_velocity_control_config();

    position_config.min_pos = i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, 1);  /* -8000; */
    position_config.max_pos = i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, 2);  /* 8000; */
    /* FIXME does this belong here? */
    uint8_t polarity = i_coe.get_object_value(DICT_POLARITY, 0);
    if ((polarity & 0xC0) != 0) {
        position_config.polarity = -1;
    } else {
        position_config.polarity = 1;
    }
    position_config.P_pos          = i_coe.get_object_value(DICT_POSITION_CONTROLLER, 1); /* POSITION_P_VALUE; */
    position_config.I_pos          = i_coe.get_object_value(DICT_POSITION_CONTROLLER, 2); /* POSITION_I_VALUE; */
    position_config.D_pos          = i_coe.get_object_value(DICT_POSITION_CONTROLLER, 3); /* POSITION_D_VALUE; */
    position_config.integral_limit_pos = i_coe.get_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT);
    //position_config.int32_cmd_limit_position     = i_coe.get_object_value(DICT_POSITION_LIMIT, 2);/* 15000; */
    //position_config.int32_cmd_limit_position_min = i_coe.get_object_value(DICT_POSITION_LIMIT, 1);/* 15000; */

    position_config.max_speed           = i_coe.get_object_value(DICT_MAX_MOTOR_SPEED, 0); /* 15000; */
    // FIXME use this in the future ESI: position_config.max_speed           = i_coe.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    position_config.max_torque          = i_coe.get_object_value(DICT_MAX_TORQUE, 0);
    position_config.P_velocity          = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, 1); /* 18; */
    position_config.I_velocity          = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, 2); /* 22; */
    position_config.D_velocity          = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, 2); /* 25; */
    position_config.integral_limit_velocity  = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT);

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

    uint16_t feedback_sensor_index = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_index);
    // FIXME the type field will be added soon (2017-02-22) see also FIXME in line 40
    //i_coe.set_object_value(feedback_sensor_index, DICT_SUB_FEEDBACK_SENSOR_TYPE, config.sensor_type);
    i_coe.set_object_value(feedback_sensor_index, SUB_RESOLUTION, config.resolution);
    // @see FIXME in cm_sync_config_position_feedback()!
    if (config.polarity == -1) {
        i_coe.set_object_value(DICT_POLARITY, 0, 0xC0);
    } else {
        i_coe.set_object_value(DICT_POLARITY, 0, 0x0);
    }

    if (config.pole_pairs != 0)
        i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS, config.pole_pairs);
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

    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS, motorcontrol_config.pole_pair);
    i_coe.set_object_value(DICT_MAX_TORQUE, 0, motorcontrol_config.max_torque);
    //i_coe.set_object_value(DICT_POLARITY, 0, motorcontrol_config.polarity_type); /* ??? FIXME the object DICT_POLARITY is for the sensor! */
    //motorcontrol_config.max_current        = i_coe.get_object_value(DICT_MAX_CURRENT, 0);
    //motorcontrol_config.rated_current      = i_coe.get_object_value(DICT_MOTOR_RATED_CURRENT, 0);
    //motorcontrol_config.rated_torque       = i_coe.get_object_value(DICT_MOTOR_RATED_TORQUE, 0);
    i_coe.set_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0, motorcontrol_config.commutation_angle_offset);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, 1, motorcontrol_config.current_P_gain);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, 2, motorcontrol_config.current_I_gain);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, 3, motorcontrol_config.current_D_gain);

    /* These are motor specific maybe we introduce a new object */
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE, motorcontrol_config.phase_resistance);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE, motorcontrol_config.phase_inductance);
    i_coe.set_object_value(DICT_MAX_CURRENT, 0, motorcontrol_config.protection_limit_over_current);//motorcontrol_config.max_current;

//    i_motorcontrol.set_config(motorcontrol_config);

    //printstr("Commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);
}

void cm_default_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    /* FIXME check the objects */
    i_coe.set_object_value(DICT_MAX_PROFILE_VELOCITY,    0, profiler.max_velocity);
    i_coe.set_object_value(DICT_PROFILE_VELOCITY,        0, profiler.velocity);
    i_coe.set_object_value(DICT_PROFILE_ACCELERATION,    0, profiler.acceleration);
    i_coe.set_object_value(DICT_PROFILE_DECELERATION,    0, profiler.deceleration);
    i_coe.set_object_value(DICT_QUICK_STOP_DECELERATION, 0, profiler.max_deceleration); /* */
    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS,   1, profiler.min_position);
    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS,   2, profiler.max_position);
    //i_coe.set_object_value(DICT_POLARITY, 0,            profiler.polarity);
    //profiler.max_acceleration =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0); /* */
}

void cm_default_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control
        )
{
    PosVelocityControlConfig position_config = i_position_control.get_position_velocity_control_config();

    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS,  1, position_config.min_pos);  /* -8000; */
    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS,  2, position_config.max_pos);  /* 8000; */
    //i_coe.set_object_value(DICT_POLARITY, 0, position_config.polarity);
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, 1, position_config.P_pos); /* POSITION_P_VALUE; */
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, 2, position_config.I_pos); /* POSITION_I_VALUE; */
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, 3, position_config.D_pos); /* POSITION_D_VALUE; */
    //position_config._cmd_limit_position     = i_coe.get_object_value(DICT_POSITION_LIMIT, 2);/* 15000; */
    //position_config._cmd_limit_position_min = i_coe.get_object_value(DICT_POSITION_LIMIT, 1);/* 15000; */

    i_coe.set_object_value(DICT_MAX_MOTOR_SPEED, 0, position_config.max_speed); /* 15000; */
    // FIXME use this in the future ESI: position_config._max_speed           = i_coe.get_object_value(CIA402_MAX_MOTOR_SPEED, 0); /* 15000; */
    i_coe.set_object_value(DICT_MAX_TORQUE, 0,    position_config.max_torque);
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, 1, position_config.P_velocity); /* 18; */
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, 2, position_config.I_velocity); /* 22; */
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, 3, position_config.D_velocity); /* 25; */

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
