/**
 * @file config_manager.xc
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include <dictionary_symbols.h>
#include <position_feedback_service.h>
#include "config_manager.h"
#include <xs1.h>

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

int cm_sync_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index)
{
    config = i_pos_feedback.get_config();
    int restart = 0;

    uint16_t feedback_sensor_object = 0;
    feedback_sensor_object = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_index);

    if (feedback_sensor_object != 0) {

        /* Get common settings for sensors */
        int old_sensor_type = config.sensor_type; //too check if we need to restart the service

        //FIXME: do we set sensor type using (feedback_sensor_object subindex 1) or
        // using the value of feedback_sensor_object ??
//        config.sensor_type = i_coe.get_object_value(feedback_sensor_object, 1);
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
        //restart the service if the sensor type is changed
        if (old_sensor_type != config.sensor_type) {
            restart = 1;
        }

        config.sensor_function         = i_coe.get_object_value(feedback_sensor_object, 2);
        config.resolution              = i_coe.get_object_value(feedback_sensor_object, 3);
        config.velocity_compute_period = i_coe.get_object_value(feedback_sensor_object, 4);
        config.polarity                = sext(i_coe.get_object_value(feedback_sensor_object, 5), 8);
        config.pole_pairs              = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS);

        // sensor specific parameters
        switch (config.sensor_type) {
        case QEI_SENSOR:
            config.qei_config.index_type  = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS);
            config.qei_config.signal_type = i_coe.get_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE);
            //FIXME: missing port number
            break;

        case BISS_SENSOR:
            config.biss_config.multiturn_resolution = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_MULTITURN_RESOLUTION);
            config.biss_config.clock_frequency      = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_FREQUENCY);
            config.biss_config.timeout              = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_TIMEOUT);
            config.biss_config.crc_poly             = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CRC_POLYNOM);
            config.biss_config.clock_port_config    = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_PORT_CONFIG); /* FIXME add check for valid enum data of clock_port_config */
            config.biss_config.data_port_number     = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_DATA_PORT_CONFIG);
            config.biss_config.filling_bits         = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS);
            config.biss_config.busy                 = i_coe.get_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY);
            break;

        case HALL_SENSOR:
            /* FIXME see cm_sync_config_hall_states() */
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_0);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_1);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_2);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_3);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_4);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_5);
            //FIXME: missing port number
            break;

        case REM_14_SENSOR:
            config.rem_14_config.hysteresis      = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_HYSTERESIS);
            config.rem_14_config.noise_setting   = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_NOISE_SETTINGS);
            config.rem_14_config.dyn_angle_comp  = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_DYNAMIC_ANGLE_ERROR_COMPENSATION);
            config.rem_14_config.abi_resolution  = i_coe.get_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_RESOLUTION_SETTINGS);
            break;

        case REM_16MT_SENSOR:
            config.rem_16mt_config.filter = i_coe.get_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_FILTER);
            break;

        case 0: /* FIXME need error handling here, or in position feedback service */
            break;

        default:
            break;
        }

        i_pos_feedback.set_config(config);
    }

    return restart;
}

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config,
        int sensor_commutation,
        int sensor_commutation_type)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    motorcontrol_config.v_dc                     = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_DC_BUS_VOLTAGE);
    motorcontrol_config.phases_inverted          = sext(i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_MOTOR_PHASES_INVERTED), 8);
    motorcontrol_config.torque_P_gain            = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KP);
    motorcontrol_config.torque_I_gain            = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KI);
    motorcontrol_config.torque_D_gain            = i_coe.get_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KD);
    motorcontrol_config.pole_pairs               = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS);
    motorcontrol_config.commutation_sensor       = sensor_commutation_type;
    motorcontrol_config.commutation_angle_offset = i_coe.get_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0);
    motorcontrol_config.max_torque               = i_coe.get_object_value(DICT_MAX_TORQUE, 0);
    motorcontrol_config.phase_resistance         = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE);
    motorcontrol_config.phase_inductance         = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE);
    motorcontrol_config.torque_constant          = i_coe.get_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_TORQUE_CONSTANT);
    motorcontrol_config.rated_current            = i_coe.get_object_value(DICT_MOTOR_RATED_CURRENT, 0);
    motorcontrol_config.rated_torque             = i_coe.get_object_value(DICT_MOTOR_RATED_TORQUE, 0);
    motorcontrol_config.percent_offset_torque    = i_coe.get_object_value(DICT_APPLIED_TUNING_TORQUE_PERCENT, 0);
    /* Read protection limits */
    motorcontrol_config.protection_limit_over_current  = i_coe.get_object_value(DICT_PROTECTION, SUB_PROTECTION_MAX_CURRENT);
    motorcontrol_config.protection_limit_under_voltage = i_coe.get_object_value(DICT_PROTECTION, SUB_PROTECTION_MIN_DC_VOLTAGE);
    motorcontrol_config.protection_limit_over_voltage  = i_coe.get_object_value(DICT_PROTECTION, SUB_PROTECTION_MAX_DC_VOLTAGE);

    uint16_t feedback_sensor_object = 0;
    feedback_sensor_object = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_commutation); //select which hall config to read
    if (feedback_sensor_object == DICT_HALL_SENSOR_1 || feedback_sensor_object == DICT_HALL_SENSOR_2) {
        motorcontrol_config.hall_state_angle[0] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_0);
        motorcontrol_config.hall_state_angle[1] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_1);
        motorcontrol_config.hall_state_angle[2] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_2);
        motorcontrol_config.hall_state_angle[3] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_3);
        motorcontrol_config.hall_state_angle[4] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_4);
        motorcontrol_config.hall_state_angle[5] = i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_5);
    }


    //not in main.xc
    /* Read recuperation config */
    //FIXME: do we set recuperation settings
//    motorcontrol_config.recuperation    = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_RECUPERATION_ENABLED);
//    motorcontrol_config.battery_e_max   = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MIN_BATTERY_ENERGY);
//    motorcontrol_config.battery_e_min   = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAX_BATTERY_ENERGY);
//    motorcontrol_config.regen_p_max     = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MIN_RECUPERATION_POWER);
//    motorcontrol_config.regen_p_min     = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAX_RECUPERATION_POWER);
//    motorcontrol_config.regen_speed_min = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MINIMUM_RECUPERATION_SPEED);
//    motorcontrol_config.regen_speed_max = i_coe.get_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAXIMUM_RECUPERATION_SPEED);

    //motorcontrol_config.max_current              = i_coe.get_object_value(DICT_MAX_CURRENT, 0);

    i_motorcontrol.set_config(motorcontrol_config);
}

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler,
        enum eProfileType type)
{
    profiler.min_position     =  i_coe.get_object_value(DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT, 1);
    profiler.max_position     =  i_coe.get_object_value(DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT, 2);
    profiler.acceleration     =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    profiler.deceleration     =  i_coe.get_object_value(DICT_PROFILE_DECELERATION, 0);
    profiler.max_velocity     =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);
    /* FIXME this profiler is only used for Quick Stop so the max_deceleration is read from the quick stop deceleration */
    profiler.max_deceleration =  i_coe.get_object_value(DICT_QUICK_STOP_DECELERATION, 0);
    profiler.max_acceleration =  i_coe.get_object_value(DICT_PROFILE_ACCELERATION, 0);
    profiler.velocity         =  i_coe.get_object_value(DICT_MAX_PROFILE_VELOCITY, 0);

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
        PosVelocityControlConfig &position_config,
        int sensor_resolution)
{
    i_position_control.get_position_velocity_control_config();

    //limits
    position_config.min_pos_range_limit = i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MIN_POSITION_RANGE_LIMIT);
    position_config.max_pos_range_limit = i_coe.get_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MAX_POSITION_RANGE_LIMIT);
    position_config.max_speed           = i_coe.get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    position_config.max_torque          = i_coe.get_object_value(DICT_MAX_TORQUE, 0);

    /* Copy the raw value from the object to the parameter */
    position_config.polarity        = i_coe.get_object_value(DICT_POLARITY, 0);

    position_config.enable_profiler = i_coe.get_object_value(DICT_MOTION_PROFILE_TYPE, 0); //FIXME: profiler setting missing
    position_config.resolution      = sensor_resolution;

    position_config.position_control_strategy = i_coe.get_object_value(DICT_POSITION_CONTROL_STRATEGY, 0);

    position_config.P_pos                   = i_coe.get_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KP);
    position_config.I_pos                   = i_coe.get_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KI);
    position_config.D_pos                   = i_coe.get_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KD);
    position_config.integral_limit_pos      = i_coe.get_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT);
    position_config.j               = i_coe.get_object_value(DICT_MOMENT_OF_INERTIA, 0);

    position_config.P_velocity              = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KP);
    position_config.I_velocity              = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KI);
    position_config.D_velocity              = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KD);
    position_config.integral_limit_velocity = i_coe.get_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT);

    /* Brake control settings */
    /* FIXME PosVelocityControlConfig does not contain parameter for dc_bus_voltage */
    position_config.special_brake_release = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_BRAKE_RELEASE_STRATEGY);
    position_config.brake_shutdown_delay  = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_BRAKE_RELEASE_DELAY);
    position_config.nominal_v_dc          = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_DC_BUS_VOLTAGE);
    position_config.voltage_pull_brake    = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_PULL_BRAKE_VOLTAGE);
    position_config.time_pull_brake       = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_PULL_BRAKE_TIME);
    position_config.voltage_hold_brake    = i_coe.get_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_HOLD_BRAKE_VOLTAGE);

    //not in main.xc
//    position_config.position_fc     = i_coe.get_object_value(DICT_FILTER_COEFFICIENTS, SUB_FILTER_COEFFICIENTS_POSITION_FILTER_COEFFICIENT);
//    position_config.velocity_fc     = i_coe.get_object_value(DICT_FILTER_COEFFICIENTS, SUB_FILTER_COEFFICIENTS_VELOCITY_FILTER_COEFFICIENT);

    i_position_control.set_position_velocity_control_config(position_config);
}

/*
 *  Set default parameters from current configuration
 */

void cm_default_config_position_feedback(
        client interface i_coe_communication i_coe,
        client interface PositionFeedbackInterface i_pos_feedback,
        PositionFeedbackConfig &config,
        int sensor_index)
{
    config = i_pos_feedback.get_config();

    // select where to store the parameters
    uint16_t feedback_sensor_object = 0;
    switch(config.sensor_type) {
    case QEI_SENSOR:
        if (sensor_index == 1)
            feedback_sensor_object = DICT_INCREMENTAL_ENCODER_1;
        else
            feedback_sensor_object = DICT_INCREMENTAL_ENCODER_2;
        break;
    case BISS_SENSOR:
        if (sensor_index == 1)
            feedback_sensor_object = DICT_BISS_ENCODER_1;
        else
            feedback_sensor_object = DICT_BISS_ENCODER_2;
        break;
    case HALL_SENSOR:
        if (sensor_index == 1)
            feedback_sensor_object = DICT_HALL_SENSOR_1;
        else
            feedback_sensor_object = DICT_HALL_SENSOR_2;
        break;
    case REM_14_SENSOR:
        feedback_sensor_object = DICT_REM_14_ENCODER;
        break;
    case REM_16MT_SENSOR:
        feedback_sensor_object = DICT_REM_16MT_ENCODER;
        break;
    }

    if (feedback_sensor_object != 0) {
        i_coe.set_object_value(DICT_FEEDBACK_SENSOR_PORTS, sensor_index, feedback_sensor_object);


        // generic sensor parameters
        i_coe.set_object_value(feedback_sensor_object, 1, config.sensor_type);
        i_coe.set_object_value(feedback_sensor_object, 2, config.sensor_function);
        i_coe.set_object_value(feedback_sensor_object, 3, config.resolution);
        i_coe.set_object_value(feedback_sensor_object, 4, config.velocity_compute_period);
        i_coe.set_object_value(feedback_sensor_object, 5, config.polarity);

        //FIXME: missing gpio settings

        // sensor specific parameters
        switch (config.sensor_type) {
        case QEI_SENSOR:
            i_coe.set_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_NUMBER_OF_CHANNELS, config.qei_config.index_type);
            i_coe.set_object_value(feedback_sensor_object, SUB_INCREMENTAL_ENCODER_ACCESS_SIGNAL_TYPE,config.qei_config.signal_type);
            //FIXME: missing qei_config.port_number
            break;

        case BISS_SENSOR:
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_MULTITURN_RESOLUTION, config.biss_config.multiturn_resolution);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_FREQUENCY, config.biss_config.clock_frequency);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_TIMEOUT, config.biss_config.timeout);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CRC_POLYNOM, config.biss_config.crc_poly);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_CLOCK_PORT_CONFIG, config.biss_config.clock_port_config); /* FIXME add check for valid enum data of clock_port_config */
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_DATA_PORT_CONFIG,config.biss_config.data_port_number);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_FILLING_BITS,config.biss_config.filling_bits);
            i_coe.set_object_value(feedback_sensor_object, SUB_BISS_ENCODER_NUMBER_OF_BITS_TO_READ_WHILE_BUSY,config.biss_config.busy);
            break;

        case HALL_SENSOR:
            //FIXME: missing hall_config.port_number
            /* FIXME see cm_sync_config_hall_states() */
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_0);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_1);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_2);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_3);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_4);
            //i_coe.get_object_value(feedback_sensor_object, SUB_HALL_SENSOR_STATE_ANGLE_5);
            break;

        case REM_14_SENSOR:
            i_coe.set_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_HYSTERESIS, config.rem_14_config.hysteresis);
            i_coe.set_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_NOISE_SETTINGS, config.rem_14_config.noise_setting);
            i_coe.set_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_DYNAMIC_ANGLE_ERROR_COMPENSATION, config.rem_14_config.dyn_angle_comp);
            i_coe.set_object_value(feedback_sensor_object, SUB_REM_14_ENCODER_RESOLUTION_SETTINGS, config.rem_14_config.abi_resolution);
            break;

        case REM_16MT_SENSOR:
            i_coe.set_object_value(feedback_sensor_object, SUB_REM_16MT_ENCODER_FILTER, config.rem_16mt_config.filter);
            break;

        case 0: /* FIXME need error handling here, or in position feedback service */
            break;

        default:
            break;
        }
    }
}

void cm_default_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_motorcontrol,
        MotorcontrolConfig &motorcontrol_config)

{
    if (isnull(i_motorcontrol))
        return;

    motorcontrol_config = i_motorcontrol.get_config();

    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_DC_BUS_VOLTAGE, motorcontrol_config.v_dc);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_MOTOR_PHASES_INVERTED, motorcontrol_config.phases_inverted);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KP, motorcontrol_config.torque_P_gain);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KI, motorcontrol_config.torque_I_gain);
    i_coe.set_object_value(DICT_TORQUE_CONTROLLER, SUB_TORQUE_CONTROLLER_CONTROLLER_KD, motorcontrol_config.torque_D_gain);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_POLE_PAIRS, motorcontrol_config.pole_pairs);
    i_coe.set_object_value(DICT_COMMUTATION_ANGLE_OFFSET, 0, motorcontrol_config.commutation_angle_offset);
    i_coe.set_object_value(DICT_MAX_TORQUE, 0, motorcontrol_config.max_torque);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_RESISTANCE, motorcontrol_config.phase_resistance);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_PHASE_INDUCTANCE, motorcontrol_config.phase_inductance);
    i_coe.set_object_value(DICT_MOTOR_SPECIFIC_SETTINGS, SUB_MOTOR_SPECIFIC_SETTINGS_TORQUE_CONSTANT, motorcontrol_config.torque_constant);
    i_coe.set_object_value(DICT_MOTOR_RATED_CURRENT, 0, motorcontrol_config.rated_current);
    i_coe.set_object_value(DICT_MOTOR_RATED_TORQUE, 0, motorcontrol_config.rated_torque);
    i_coe.set_object_value(DICT_APPLIED_TUNING_TORQUE_PERCENT, 0, motorcontrol_config.percent_offset_torque);
    /* Write protection limits */
    i_coe.set_object_value(DICT_PROTECTION, SUB_PROTECTION_MAX_CURRENT, motorcontrol_config.protection_limit_over_current);
    i_coe.set_object_value(DICT_PROTECTION, SUB_PROTECTION_MIN_DC_VOLTAGE, motorcontrol_config.protection_limit_under_voltage);
    i_coe.set_object_value(DICT_PROTECTION, SUB_PROTECTION_MAX_DC_VOLTAGE, motorcontrol_config.protection_limit_over_voltage);


    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_0, motorcontrol_config.hall_state_angle[0]);
    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_1, motorcontrol_config.hall_state_angle[1]);
    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_2, motorcontrol_config.hall_state_angle[2]);
    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_3, motorcontrol_config.hall_state_angle[3]);
    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_4, motorcontrol_config.hall_state_angle[4]);
    i_coe.set_object_value(DICT_HALL_SENSOR_1, SUB_HALL_SENSOR_STATE_ANGLE_5, motorcontrol_config.hall_state_angle[5]);

    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_0, motorcontrol_config.hall_state_angle[0]);
    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_1, motorcontrol_config.hall_state_angle[1]);
    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_2, motorcontrol_config.hall_state_angle[2]);
    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_3, motorcontrol_config.hall_state_angle[3]);
    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_4, motorcontrol_config.hall_state_angle[4]);
    i_coe.set_object_value(DICT_HALL_SENSOR_2, SUB_HALL_SENSOR_STATE_ANGLE_5, motorcontrol_config.hall_state_angle[5]);

    // The following are not set in the main.xc
    /* Write recuperation config */
    //FIXME: do we set recuperation settings
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_RECUPERATION_ENABLED, motorcontrol_config.recuperation);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MIN_BATTERY_ENERGY, motorcontrol_config.battery_e_max);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAX_BATTERY_ENERGY, motorcontrol_config.battery_e_min);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MIN_RECUPERATION_POWER, motorcontrol_config.regen_p_max);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAX_RECUPERATION_POWER, motorcontrol_config.regen_p_min);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MINIMUM_RECUPERATION_SPEED, motorcontrol_config.regen_speed_min);
//    i_coe.set_object_value(DICT_RECUPERATION, SUB_RECUPERATION_MAXIMUM_RECUPERATION_SPEED, motorcontrol_config.regen_speed_max);

//    i_coe.set_object_value(DICT_MAX_CURRENT, 0, motorcontrol_config.max_current);

    // also missing:
    // current_ratio
    // voltage_ratio

}

void cm_default_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    i_coe.set_object_value(DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT, 1, profiler.min_position);
    i_coe.set_object_value(DICT_MAX_SOFTWARE_POSITION_RANGE_LIMIT, 2, profiler.max_position);
    i_coe.set_object_value(DICT_PROFILE_ACCELERATION, 0, profiler.acceleration);
    i_coe.set_object_value(DICT_PROFILE_DECELERATION, 0, profiler.deceleration);
    i_coe.set_object_value(DICT_MAX_PROFILE_VELOCITY, 0, profiler.max_velocity);
    /* FIXME this profiler is only used for Quick Stop so the max_deceleration is read from the quick stop deceleration */
    i_coe.set_object_value(DICT_QUICK_STOP_DECELERATION, 0, profiler.max_deceleration);
    i_coe.set_object_value(DICT_PROFILE_ACCELERATION, 0, profiler.max_acceleration);
    i_coe.set_object_value(DICT_MAX_PROFILE_VELOCITY, 0, profiler.velocity);
}

void cm_default_config_pos_velocity_control(
        client interface i_coe_communication i_coe,
        client interface PositionVelocityCtrlInterface i_position_control
        )
{
    PosVelocityControlConfig position_config = i_position_control.get_position_velocity_control_config();

    //limits
    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MIN_POSITION_RANGE_LIMIT, position_config.min_pos_range_limit);
    i_coe.set_object_value(DICT_POSITION_RANGE_LIMITS, SUB_POSITION_RANGE_LIMITS_MAX_POSITION_RANGE_LIMIT, position_config.max_pos_range_limit);
    i_coe.set_object_value(DICT_MAX_MOTOR_SPEED, 0, position_config.max_speed);

    i_coe.set_object_value(DICT_POLARITY, 0, position_config.polarity);

    i_coe.set_object_value(DICT_MOTION_PROFILE_TYPE, 0, position_config.enable_profiler);

    i_coe.set_object_value(DICT_POSITION_CONTROL_STRATEGY, 0, position_config.position_control_strategy);

    //position PID
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KP, position_config.P_pos);
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KI, position_config.I_pos);
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_CONTROLLER_KD, position_config.D_pos);
    i_coe.set_object_value(DICT_POSITION_CONTROLLER, SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT, position_config.integral_limit_pos);
    i_coe.set_object_value(DICT_MOMENT_OF_INERTIA, 0, position_config.j);

    //velocity PID
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KP, position_config.P_velocity);
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KI, position_config.I_velocity);
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_KD, position_config.D_velocity);
    i_coe.set_object_value(DICT_VELOCITY_CONTROLLER, SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT, position_config.integral_limit_velocity);

    /* Brake control settings */
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_BRAKE_RELEASE_STRATEGY, position_config.special_brake_release);
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_BRAKE_RELEASE_DELAY, position_config.brake_shutdown_delay);
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_DC_BUS_VOLTAGE, position_config.nominal_v_dc);
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_PULL_BRAKE_VOLTAGE, position_config.voltage_pull_brake);
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_PULL_BRAKE_TIME, position_config.time_pull_brake);
    i_coe.set_object_value(DICT_BREAK_RELEASE, SUB_BREAK_RELEASE_HOLD_BRAKE_VOLTAGE, position_config.voltage_hold_brake);

    //not in main.xc
//    i_coe.set_object_value(DICT_FILTER_COEFFICIENTS, SUB_FILTER_COEFFICIENTS_POSITION_FILTER_COEFFICIENT, position_config.position_fc);
//    i_coe.set_object_value(DICT_FILTER_COEFFICIENTS, SUB_FILTER_COEFFICIENTS_VELOCITY_FILTER_COEFFICIENT, position_config.velocity_fc);

    i_position_control.set_position_velocity_control_config(position_config);
}
