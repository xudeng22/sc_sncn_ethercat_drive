/**
 * @file network_drive_service.xc
 * @brief CANopen Motor Drive Service
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <cia402_error_codes.h>
#include <network_drive_service.h>

#include <refclk.h>
#include <cia402_wrapper.h>
#include <pdo_handler.h>
#include <statemachine.h>
#include <state_modes.h>
#include <profile.h>
#include <string.h>
#include <config_manager.h>
#include <motion_control_service.h>
#include <position_feedback_service.h>
#include <profile_control.h>
#include <xscope.h>
#include <tuning.h>

/* FIXME move to some stdlib */
#define ABSOLUTE_VALUE(x)   (x < 0 ? -x : x)

const char * state_names[] = {"u shouldn't see me",
"S_NOT_READY_TO_SWITCH_ON",
"S_SWITCH_ON_DISABLED",
"S_READY_TO_SWITCH_ON",
"S_SWITCH_ON",
"S_OPERATION_ENABLE",
"S_QUICK_STOP_ACTIVE",
"S_FAULT"
};

enum eDirection {
    DIRECTION_NEUTRAL = 0
    ,DIRECTION_CLK    = 1
    ,DIRECTION_CCLK   = -1
};

#define MAX_TIME_TO_WAIT_SDO      100000

static int get_cia402_error_code(FaultCode motorcontrol_fault, WatchdogError watchdog_error,
                                 SensorError motion_sensor_error, SensorError commutation_sensor_error,
                                 MotionControlError motion_control_error,
                                 int inactive_timeout_flag)
{
    int error_code = 0;

    switch(watchdog_error) {
    /* if there is no watchdog fault check motorcontrol fault
     * it means that motorcontrol faults take precedence over sensor faults
     * */
    case WATCHDOG_TICKS_ERROR:
        error_code = ERROR_CODE_SOFTWARE_RESET_WATCHDOG;
        break;
    case WATCHDOG_DEAD_TIME_PHASE_A_ERROR:
        error_code = ERROR_CODE_PHASE_FAILURE_L1;
        break;
    case WATCHDOG_DEAD_TIME_PHASE_B_ERROR:
        error_code = ERROR_CODE_PHASE_FAILURE_L1;
        break;
    case WATCHDOG_DEAD_TIME_PHASE_C_ERROR:
        error_code = ERROR_CODE_PHASE_FAILURE_L1;
        break;
    case WATCHDOG_DEAD_TIME_PHASE_D_ERROR:
        error_code = ERROR_CODE_PHASE_FAILURE;
        break;
    case WATCHDOG_OVER_CURRENT_ERROR:
        error_code = ERROR_CODE_CONTINUOUS_OVER_CURRENT_DEVICE_INTERNAL;
        break;
    case WATCHDOG_OVER_UNDER_VOLTAGE_OVER_TEMP_ERROR:
        error_code = ERROR_CODE_DC_LINK_UNDER_VOLTAGE;
        break;
    case WATCHDOG_UNKNOWN_ERROR:
        error_code = ERROR_CODE_CONTROL;
        break;
    case WATCHDOG_NO_ERROR://if there is no watchdog fault check motorcontrol fault
        switch (motorcontrol_fault) {
        case DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1:
            error_code = ERROR_CODE_CONTINUOUS_OVER_CURRENT_DEVICE_INTERNAL;
            break;
        case UNDER_VOLTAGE_NO_1:
            error_code = ERROR_CODE_DC_LINK_UNDER_VOLTAGE;
            break;
        case OVER_VOLTAGE_NO_1:
            error_code = ERROR_CODE_DC_LINK_OVER_VOLTAGE;
            break;
        case EXCESS_TEMPERATURE_DRIVE:
            error_code = ERROR_CODE_EXCESS_TEMPERATURE_DEVICE;
            break;
        case PHASE_FAILURE_L1:
            error_code = ERROR_CODE_PHASE_FAILURE_L1;
            break;
        case PHASE_FAILURE_L2:
            error_code = ERROR_CODE_PHASE_FAILURE_L2;
            break;
        case PHASE_FAILURE_L3:
            error_code = ERROR_CODE_PHASE_FAILURE_L3;
            break;
        case NO_FAULT:
            /* if there is no motorcontrol fault check sensor fault
             * it means that motorcontrol faults take precedence over sensor faults
             * */
            if (commutation_sensor_error != SENSOR_NO_ERROR || motion_sensor_error != SENSOR_NO_ERROR) {
                if (commutation_sensor_error == SENSOR_QEI_INDEX_LOSING_TICKS || motion_sensor_error == SENSOR_QEI_INDEX_LOSING_TICKS)
                    error_code = ERROR_CODE_INCREMENTAL_SENSOR_1_FAULT;
                else if (commutation_sensor_error == SENSOR_INCREMENTAL_FAULT || motion_sensor_error == SENSOR_INCREMENTAL_FAULT)
                    error_code = ERROR_CODE_INCREMENTAL_SENSOR_1_FAULT;
                else if (commutation_sensor_error == SENSOR_SPEED_FAULT  || motion_sensor_error == SENSOR_SPEED_FAULT)
                    error_code = ERROR_CODE_SPEED;
                else if (commutation_sensor_error == SENSOR_POSITION_FAULT  || motion_sensor_error == SENSOR_POSITION_FAULT)
                    error_code = ERROR_CODE_POSITION;
                else
                    error_code = ERROR_CODE_SENSOR;
            } else {
                /* if there is no sensor fault check motion control fault */
                switch(motion_control_error) {
                case MOTION_CONTROL_BRAKE_NOT_RELEASED:
                    error_code = ERROR_CODE_MOTOR_BLOCKED;
                    break;
                case MOTION_CONTROL_NO_ERROR: //if there is no motioncontrol fault check communication fault
                    if (inactive_timeout_flag) {
                        error_code = ERROR_CODE_COMMUNICATION;
                    }
                    break;
                default:
                    error_code = ERROR_CODE_CONTROL;
                    break;
                }
            }
            break;
        default: /* a fault occured but could not be specified further */
            error_code = ERROR_CODE_CONTROL;
            break;
        } // end switch motorcontrol_fault
        break;
    default: /* a fault occured but could not be specified further */
        error_code = ERROR_CODE_CONTROL;
        break;
    } //end switch watchdog error

    return error_code;
}

static void sdo_wait_first_config(client interface i_co_communication i_co)
{
    while (!i_co.configuration_get());
        //printstrln("Master requests OP mode - cyclic operation is about to start.");

    /* comment in the read_od_config() function to print the object values */
    //read_od_config(i_co);
    printstrln("start cyclic operation");

    //print_object_dictionary(i_co);
    /* clear the notification before proceeding the operation */
    i_co.configuration_done();
}

static int initial_object_dictionary_read(client interface i_co_communication i_co)
{
    timer t;
    unsigned time;

    i_co.od_set_object_value(DICT_COMMAND_OBJECT, 0, OD_COMMAND_READ_CONFIG);
    enum eSdoState command_state = OD_COMMAND_STATE_IDLE;

    while (command_state <= OD_COMMAND_STATE_PROCESSING) {
        t :> time;
        t when timerafter(time + 1000 * USEC_STD) :> void;

        {command_state, void, void} = i_co.od_get_object_value(DICT_COMMAND_OBJECT, 0);
    }

    return ((command_state == OD_COMMAND_STATE_SUCCESS) ? 0 : 1);
}

/*
 * For tuning of the PID values it is necessary to modify these values during
 * the motion of the drive. This function checks if any of the relevant entries
 * changed since the last check.
 *
 * This functions only gets the next changed entry element at a time.
 *
 * Return 0 if nothing changed
 *        1 if a value is updated
 */
static int check_for_pid_updatate(
        client interface i_co_communication i_co,
        client interface MotionControlInterface i_motion_control,
        MotionControlConfig &position_config)
{
    uint16_t changed_index = 0;
    uint8_t  changed_subindex = 0;

    {changed_index, changed_subindex} = i_co.od_get_next_changed_element();
    if (changed_index == 0) {
        return 0;
    }

    union sdo_value value;
    uint8_t od_err = 0;

    int changed = 0;
    position_config = i_motion_control.get_motion_control_config();
    if (changed_index    == DICT_FILTER_COEFFICIENTS &&
        changed_subindex == SUB_FILTER_COEFFICIENTS_POSITION_FILTER_COEFFICIENT) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.filter = value.i;
        changed = 1;
    } else if (changed_index    == DICT_POSITION_CONTROLLER &&
               changed_subindex == SUB_POSITION_CONTROLLER_CONTROLLER_KP) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.position_kp = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_POSITION_CONTROLLER &&
               changed_subindex == SUB_POSITION_CONTROLLER_CONTROLLER_KI) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.position_ki = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_POSITION_CONTROLLER &&
               changed_subindex == SUB_POSITION_CONTROLLER_CONTROLLER_KD) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.position_kd = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_POSITION_CONTROLLER &&
               changed_subindex == SUB_POSITION_CONTROLLER_POSITION_INTEGRAL_LIMIT) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.position_integral_limit = value.i;
        changed = 1;
    } else if (changed_index    == DICT_VELOCITY_CONTROLLER &&
               changed_subindex == SUB_VELOCITY_CONTROLLER_CONTROLLER_KP) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.velocity_kp = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_VELOCITY_CONTROLLER &&
               changed_subindex == SUB_VELOCITY_CONTROLLER_CONTROLLER_KI) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.velocity_ki = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_VELOCITY_CONTROLLER &&
               changed_subindex == SUB_VELOCITY_CONTROLLER_CONTROLLER_KD) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.velocity_kd = (int)value.f;
        changed = 1;
    } else if (changed_index    == DICT_VELOCITY_CONTROLLER &&
               changed_subindex == SUB_VELOCITY_CONTROLLER_CONTROLLER_INTEGRAL_LIMIT) {
        {value.i, void, od_err} = i_co.od_get_object_value(changed_index, changed_subindex);
        if (od_err != 0) {
            return 0;
        }
        position_config.velocity_integral_limit = value.i;
        changed = 1;
    }

    i_motion_control.set_motion_control_config(position_config);

    return changed;
}

static int quick_stop_perform(int opmode, int &step)
{
    int target = 0;

    switch (opmode) {
    case OPMODE_CSP:
        target = quick_stop_position_profile_generate(step);
        break;

    case OPMODE_CSV:
        target = quick_stop_velocity_profile_generate(step);
        break;

    case OPMODE_CST:
        /* We can use the same linear profile for torque because it's actually independant on units */
        target = quick_stop_velocity_profile_generate(step);
        break;
    }

    step++;

    return target;
}

static int quick_stop_init(int opmode,
        int actual_position,
        int actual_velocity,
        int actual_torque,
        int sensor_resolution,
        int quick_stop_deceleration)
{
    int steps = 0;

    switch(opmode) {
    case OPMODE_CSP:
        steps = init_quick_stop_position_profile(
                (actual_velocity * sensor_resolution) / 60,
                actual_position,
                (quick_stop_deceleration * sensor_resolution) / 60);
        break;
    case OPMODE_CSV:
        steps = init_quick_stop_velocity_profile(actual_velocity, quick_stop_deceleration);
        break;
    case OPMODE_CST:
        // we get the time needed to stop using the velocity quick stop
        steps = init_quick_stop_velocity_profile(actual_velocity, quick_stop_deceleration);
        // we set the torque deceleration to decrease to 0 with the same duration
        if (steps != 0) {
            if (actual_torque < 0) {
                quick_stop_deceleration = (1000*(-actual_torque))/steps;
            } else {
                quick_stop_deceleration = (1000*actual_torque)/steps;
            }
            // we use the same linear profile for torque because it's actually independant on units
            steps = init_quick_stop_velocity_profile(actual_torque, quick_stop_deceleration);
        }
        break;
    default:
        steps = 0;
        break;
    }

    //limit steps
    if (actual_velocity < 0) {
        actual_velocity = -actual_velocity;
    }
    if (quick_stop_deceleration == 0) {
        quick_stop_deceleration = 1;
    }
    int steps_limit = (1000*actual_velocity)/quick_stop_deceleration + 1;
    if (steps > steps_limit) {
        steps = steps_limit;
    }

    return steps;
}

static void inline update_configuration(
        client interface i_co_communication           i_co,
        client interface TorqueControlInterface         i_torque_control,
        client interface MotionControlInterface i_motion_control,
        client interface PositionFeedbackInterface i_pos_feedback_1,
        client interface PositionFeedbackInterface ?i_pos_feedback_2,
        MotionControlConfig  &position_config,
        PositionFeedbackConfig    &position_feedback_config_1,
        PositionFeedbackConfig    &position_feedback_config_2,
        MotorcontrolConfig        &motorcontrol_config,
        ProfilerConfig            &profiler_config,
        int &sensor_commutation, int &sensor_motion_control,
        int &limit_switch_type,
        int &sensor_resolution,
        uint8_t &polarity,
        int &nominal_speed,
        int &homing_method,
        int &quick_stop_deceleration)
{

    // set position feedback services parameters
    int restart = 0; //we need to restart position feedback service(s) when sensor type is changed
    int number_of_feedbacks_ports;
    {number_of_feedbacks_ports, void, void}= i_co.od_get_object_value(DICT_FEEDBACK_SENSOR_PORTS, 0);
    int feedback_port_index = 1;
    restart += cm_sync_config_position_feedback(i_co, i_pos_feedback_1, position_feedback_config_1, 1,
            sensor_commutation, sensor_motion_control,
            number_of_feedbacks_ports, feedback_port_index);
    if (!isnull(i_pos_feedback_2)) {
        restart += cm_sync_config_position_feedback(i_co, i_pos_feedback_2, position_feedback_config_2, 2,
                sensor_commutation, sensor_motion_control,
                number_of_feedbacks_ports, feedback_port_index);
        if (restart)
            i_pos_feedback_2.exit();
    }
    if (restart) {
        i_pos_feedback_1.exit();
    }

    // set sensor resolution from the resolution of the sensor used for motion control (used by profiler)
    if (sensor_motion_control == 2) {
        sensor_resolution = position_feedback_config_2.resolution;
    } else {
        sensor_resolution = position_feedback_config_1.resolution;
    }

    // set commutation sensor type (used by motorcontrol service to detect if hall is used)
    int sensor_commutation_type = 0;
    if (sensor_commutation == 2) {
        sensor_commutation_type = position_feedback_config_2.sensor_type;
    } else {
        sensor_commutation_type = position_feedback_config_1.sensor_type;
    }

    cm_sync_config_profiler(i_co, profiler_config, PROFILE_TYPE_POSITION); /* FIXME currently only one profile type is used! */
    int max_torque = cm_sync_config_motor_control(i_co, i_torque_control, motorcontrol_config, sensor_commutation_type);
    cm_sync_config_pos_velocity_control(i_co, i_motion_control, position_config, sensor_resolution, max_torque);

    /* Update values with current configuration */
    profiler_config.ticks_per_turn = sensor_resolution;

    {nominal_speed, void, void}     = i_co.od_get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    limit_switch_type = 0; //i_co.od_get_object_value(LIMIT_SWITCH_TYPE, 0); /* not used now */
    homing_method     = 0; //i_co.od_get_object_value(CIA402_HOMING_METHOD, 0); /* not used now */
    {polarity, void, void}          = i_co.od_get_object_value(DICT_POLARITY, 0);
    {quick_stop_deceleration, void, void} = i_co.od_get_object_value(DICT_QUICK_STOP_DECELERATION, 0);
}

static void motioncontrol_enable(int opmode, int position_control_strategy,
                                 client interface MotionControlInterface i_motion_control)
{
    switch (opmode) {
    case OPMODE_CSP:
        i_motion_control.enable_position_ctrl(position_control_strategy);
        break;

    case OPMODE_CSV:
        i_motion_control.enable_velocity_ctrl();
        break;

    case OPMODE_CST:
        i_motion_control.enable_torque_ctrl();
        break;

    default:
        break;
    }

}

#ifdef NETWORK_DRIVE_DEBUG_PRINT_STATE
static void debug_print_state(DriveState_t state)
{
    static DriveState_t oldstate = 0;

    if (state == oldstate)
        return;

    switch (state) {
    case S_NOT_READY_TO_SWITCH_ON:
        printstrln("S_NOT_READY_TO_SWITCH_ON");
        break;
    case S_SWITCH_ON_DISABLED:
        printstrln("S_SWITCH_ON_DISABLED");
        break;
    case S_READY_TO_SWITCH_ON:
        printstrln("S_READY_TO_SWITCH_ON");
        break;
    case S_SWITCH_ON:
        printstrln("S_SWITCH_ON");
        break;
    case S_OPERATION_ENABLE:
        printstrln("S_OPERATION_ENABLE");
        break;
    case S_QUICK_STOP_ACTIVE:
        printstrln("S_QUICK_STOP_ACTIVE");
        break;
    case S_FAULT_REACTION_ACTIVE:
        printstrln("S_FAULT_REACTION_ACTIVE");
        break;
    case S_FAULT:
        printstrln("S_FAULT");
        break;
    default:
        printstrln("Never happen State.");
        break;
    }

    oldstate = state;
}
#endif

//#pragma xta command "analyze loop ecatloop"
//#pragma xta command "set required - 1.0 ms"

#define UPDATE_POSITION_GAIN    0x0000000f
#define UPDATE_VELOCITY_GAIN    0x000000f0
#define UPDATE_TORQUE_GAIN      0x00000f00


/* NOTE:
 * - op mode change only when we are in "Ready to Swtich on" state or below (basically op mode is set locally in this state).
 * - if the op mode signal changes in any other state it is ignored until we fall back to "Ready to switch on" state (Transition 2, 6 and 8)
 */
void network_drive_service(ProfilerConfig &profiler_config,
                            client interface i_pdo_handler_exchange i_pdo,
                            client interface i_co_communication i_co,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2,
                                    client interface FileServiceInterface i_file_service)
{


    //int target_torque = 0; /* used for CST */
    //int target_velocity = 0; /* used for CSV */
    int target_position = 0;
    int target_velocity = 0;
    int target_torque   = 0;
    int quick_stop_deceleration = 0;
    int qs_target = 0;
    int qs_start_velocity = 0;
    int quick_stop_steps = 0;
    int quick_stop_step = 0;
    int actual_torque = 0;
    int actual_velocity = 0;
    int actual_position = 0;
    int follow_error = 0;
    //int target_position_progress = 0; /* is current target_position necessary to remember??? */

    enum eDirection direction = DIRECTION_NEUTRAL;

    int nominal_speed;
    timer t;

    int opmode = OPMODE_NONE;
    int opmode_request = OPMODE_NONE;

    MotionControlConfig motion_control_config = i_motion_control.get_motion_control_config();

    pdo_values_t InOut = i_pdo.pdo_init();

    int sensor_commutation = 1;     //sensor service used for commutation (1 or 2)
    int sensor_motion_control = 1;  //sensor service used for motion control (1 or 2)

    int communication_active = 0;
    unsigned int c_time;
    int comm_inactive_flag = 0;
    int inactive_timeout_flag = 0;

    /* tuning specific variables */
    uint32_t tuning_command = 0;
    uint32_t tuning_status = 0;
    uint32_t user_miso = 0;
    TuningModeState tuning_mode_state = {0};

    unsigned int time;
    enum e_States state     = S_NOT_READY_TO_SWITCH_ON;

    uint16_t statusword = update_statusword(0, state, 0, 0, 0);
    int controlword = 0;
    uint16_t error_code = 0;

    //int torque_offstate = 0;
    check_list checklist = init_checklist();
    unsigned int fault_reset_wait_time;

    int limit_switch_type;
    int homing_method;

    int sensor_resolution = 0;
    uint8_t polarity = 0;

    PositionFeedbackConfig position_feedback_config_1 = i_position_feedback_1.get_config();
    PositionFeedbackConfig position_feedback_config_2;

    MotorcontrolConfig motorcontrol_config = i_torque_control.get_config();
    UpstreamControlData   send_to_master = { 0 };
    DownstreamControlData send_to_control = { 0 };

    /* read tile frequency
     * this needs to be after the first call to i_torque_control
     * so when we read it the frequency has already been changed by the torque controller
     */
    unsigned int tile_usec = USEC_STD;
    unsigned ctrlReadData;
    read_sswitch_reg(get_local_tile_id(), 8, ctrlReadData);
    if(ctrlReadData == 1) {
        tile_usec = USEC_FAST;
    }

#if STARTUP_READ_FLASH_OBJECTS == 1
    /* Before anything else, read the object data values from flash - if existing. */
    if (initial_object_dictionary_read(i_co) != 0) {
        printstrln("Warning: Could not read object dictionary from file system.");
#endif /* STARTUP_READ_FLASH_OBJECTS */

    /*
     * copy the current default configuration into the object dictionary, this will avoid ET_ARITHMETIC in motorcontrol service.
     */
    /* FIXME add support for more than one feedback sensor */
    cm_default_config_position_feedback(i_co, i_position_feedback_1, position_feedback_config_1, 1);
    if (!isnull(i_position_feedback_2)) {
        cm_default_config_position_feedback(i_co, i_position_feedback_2, position_feedback_config_2, 2);
    }

    cm_default_config_profiler(i_co, profiler_config);
    cm_default_config_motor_control(i_co, i_torque_control, motorcontrol_config);
    cm_default_config_pos_velocity_control(i_co, i_motion_control);

#if STARTUP_READ_FLASH_OBJECTS == 1
    }
#endif /* STARTUP_READ_FLASH_OBJECTS */

    i_co.od_set_object_value(DICT_QUICK_STOP_DECELERATION, 0, profiler_config.max_deceleration); //we use profiler.max_deceleration as the default value for quick stop deceleration

    /* check if the slave enters the operation mode. If this happens we assume the configuration values are
     * written into the object dictionary. So we read the object dictionary values and continue operation.
     *
     * This should be done before we configure anything.
     */
    sdo_wait_first_config(i_co);


    /* if we reach this point the EtherCAT service is considered in OPMODE */
    int drive_in_opstate = 1;

    /* start operation */
    int read_configuration = 1;

    t :> time;
    while (1) {
//#pragma xta endpoint "ecatloop"

        /* Read the configuration in SWITCH_ON_DISABLE */
        if (read_configuration) {
            update_configuration(i_co, i_torque_control, i_motion_control, i_position_feedback_1, i_position_feedback_2,
                    motion_control_config, position_feedback_config_1, position_feedback_config_2, motorcontrol_config, profiler_config,
                    sensor_commutation, sensor_motion_control, limit_switch_type, sensor_resolution, polarity, nominal_speed, homing_method,
                    quick_stop_deceleration
                    );
            //Load cogging torque data
            char filename [] = "cogging_torque.bin";
            int status = i_file_service.read_torque_array(motorcontrol_config.torque_offset);
            if (status != SPIFFS_ERR_NOT_FOUND)
                i_motion_control.enable_cogging_compensation(1);


            tuning_mode_state.flags = tuning_set_flags(tuning_mode_state, motorcontrol_config, motion_control_config,
                    position_feedback_config_1, position_feedback_config_2, sensor_commutation);
            read_configuration = 0;
            i_co.configuration_done();
            // check if there is there is any object that changed but was not read and if so read them to clear the flag
            uint16_t changed_index = 0;
            uint8_t changed_subindex = 0;
            { changed_index, changed_subindex } = i_co.od_get_next_changed_element();
            int timeout = 1000;
            while (changed_index && timeout>0) {
                i_co.od_get_object_value(changed_index, changed_subindex);
                { changed_index, changed_subindex } = i_co.od_get_next_changed_element();
                timeout--;
            }
        } else {
            /* if there is no "read the whole configuration", just check if single values changed.
             * More precisely, the PID configuration values, one at time. */
            check_for_pid_updatate(i_co, i_motion_control, motion_control_config);
        }

        /*
         *  local state variables
         */
        controlword     = pdo_get_controlword(InOut);
        opmode_request  = pdo_get_op_mode(InOut);
        target_position = pdo_get_target_position(InOut);
        target_velocity = pdo_get_target_velocity(InOut);
        target_torque   = (pdo_get_target_torque(InOut)*motorcontrol_config.rated_torque) / 1000; //target torque received in 1/1000 of rated torque
        send_to_control.offset_torque = (pdo_get_offset_torque(InOut)*motorcontrol_config.rated_torque) / 1000; //offset torque received in 1/1000 of rated torque
        send_to_control.gpio_output = ((pdo_get_digital_output4(InOut)&1) << 3) | ((pdo_get_digital_output3(InOut)&1) << 2)
                                    | ((pdo_get_digital_output2(InOut)&1) << 1)| (pdo_get_digital_output1(InOut) & 1);

        /* tuning pdos */
        tuning_command = pdo_get_tuning_command(InOut); // mode 3, 2 and 1 in tuning command
        tuning_mode_state.value = pdo_get_user_mosi(InOut); // value of tuning command

        /*
        printint(state);
        printstr(" ");
        printhexln(statusword);
        */


        if (quick_stop_steps == 0) {
            send_to_control.position_cmd = target_position;
            send_to_control.velocity_cmd = target_velocity;
            send_to_control.torque_cmd   = target_torque;
        } else {
            switch (opmode) {
            case OPMODE_CSP:
                // we update the position command only if the qs target is in the right direction
                if ((qs_start_velocity > 0 && qs_target > send_to_control.position_cmd) || (qs_start_velocity < 0 && qs_target < send_to_control.position_cmd)) {
                    send_to_control.position_cmd = qs_target;
                }
                break;

            case OPMODE_CSV:
                // we update the velocity command only if decreasing
                if ((send_to_control.velocity_cmd > 0 && qs_target < send_to_control.velocity_cmd) || (send_to_control.velocity_cmd < 0 && qs_target > send_to_control.velocity_cmd)) {
                    send_to_control.velocity_cmd = qs_target;
                }
                break;

            case OPMODE_CST:
                // we update the torque command only if decreasing
                if ((send_to_control.torque_cmd > 0 && qs_target < send_to_control.torque_cmd) || (send_to_control.torque_cmd < 0 && qs_target > send_to_control.torque_cmd)) {
                    send_to_control.torque_cmd = qs_target;
                }
                break;

            /* FIXME what to do for the default? */
            }
        }

        send_to_master = i_motion_control.update_control_data(send_to_control);

        /* i_motion_control.get_all_feedbacks; */
        actual_velocity = send_to_master.velocity; //i_motion_control.get_velocity();
        actual_position = send_to_master.position; //i_motion_control.get_position();
        actual_torque   = (send_to_master.computed_torque*1000) / motorcontrol_config.rated_torque; //torque sent to master in 1/1000 of rated torque
        FaultCode motorcontrol_fault = send_to_master.error_status;
        SensorError motion_sensor_error = send_to_master.last_sensor_error;
        SensorError commutation_sensor_error = send_to_master.angle_last_sensor_error;
        MotionControlError motion_control_error = send_to_master.motion_control_error;
        WatchdogError watchdog_error = send_to_master.watchdog_error;

//        xscope_int(TARGET_POSITION, send_to_control.position_cmd);
//        xscope_int(ACTUAL_POSITION, actual_position);
//        xscope_int(FAMOUS_FAULT, motorcontrol_fault * 1000);

        /*
         * Check states of the motor drive, sensor drive and control servers
         * Fault signaling to the master in the manufacturer specifc bit in the the statusword
         */
        if ( motorcontrol_fault != NO_FAULT ||
             motion_sensor_error != SENSOR_NO_ERROR ||
             commutation_sensor_error != SENSOR_NO_ERROR ||
             motion_control_error != MOTION_CONTROL_NO_ERROR ||
             watchdog_error != WATCHDOG_NO_ERROR ||
             inactive_timeout_flag)
        {
            update_checklist(checklist, opmode, 1);
            if (motorcontrol_fault == DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1 || watchdog_error == WATCHDOG_OVER_CURRENT_ERROR) {
                SET_BIT(statusword, SW_FAULT_OVER_CURRENT);
            } else if (motorcontrol_fault == UNDER_VOLTAGE_NO_1 || watchdog_error == WATCHDOG_OVER_UNDER_VOLTAGE_OVER_TEMP_ERROR) {
                SET_BIT(statusword, SW_FAULT_UNDER_VOLTAGE);
            } else if (motorcontrol_fault == OVER_VOLTAGE_NO_1) {
                SET_BIT(statusword, SW_FAULT_OVER_VOLTAGE);
            } else if (motorcontrol_fault == 99/*OVER_TEMPERATURE*/) {
                SET_BIT(statusword, SW_FAULT_OVER_TEMPERATURE);
            }

            /* Write error code to object dictionary */
            error_code = get_cia402_error_code(motorcontrol_fault, watchdog_error,
                                               motion_sensor_error, commutation_sensor_error,
                                               motion_control_error, inactive_timeout_flag);
            i_co.od_set_object_value(DICT_ERROR_CODE, 0, error_code);
        } else {
            update_checklist(checklist, opmode, 0); //no error
            error_code = 0;
            i_co.od_set_object_value(DICT_ERROR_CODE, 0, 0);
        }

        //put error_code in user_miso pdo when not in tuning mode
        if (opmode != OPMODE_SNCN_TUNING) {
            user_miso = error_code;
        }

        follow_error = target_position - actual_position; /* FIXME only relevant in OP_ENABLED - used for what??? */

        direction = (actual_velocity < 0) ? DIRECTION_CCLK : DIRECTION_CLK;

        /*
         *  update values to send
         */
        pdo_set_statusword(statusword, InOut);
        pdo_set_op_mode_display(opmode, InOut);
        pdo_set_velocity_value(actual_velocity, InOut);
        pdo_set_torque_value(actual_torque, InOut );
        pdo_set_position_value(actual_position, InOut);
        pdo_set_secondary_position_value(send_to_master.secondary_position, InOut);
        pdo_set_secondary_velocity_value(send_to_master.secondary_velocity, InOut);
        // FIXME this is one of the analog inputs?
        pdo_set_analog_input1((1000 * 5 * send_to_master.analogue_input_a_1) / 4096, InOut); /* ticks to (edit:) milli-volt */
        pdo_set_tuning_status(tuning_status, InOut);
        pdo_set_user_miso(user_miso, InOut);
        pdo_set_timestamp(send_to_master.sensor_timestamp, InOut);
        // send gpio input to master
        pdo_set_digital_input1(send_to_master.gpio[0], InOut);
        pdo_set_digital_input2(send_to_master.gpio[1], InOut);
        pdo_set_digital_input3(send_to_master.gpio[2], InOut);
        pdo_set_digital_input4(send_to_master.gpio[3], InOut);

//        xscope_int(ACTUAL_VELOCITY, actual_velocity);
//        xscope_int(ACTUAL_POSITION, actual_position);


        /* Read/Write packets to ethercat Master application */
        {InOut, communication_active} = i_pdo.pdo_exchange_app(InOut);


        if (communication_active == 0) {
            if (comm_inactive_flag == 0) {
                comm_inactive_flag = 1;
                t :> c_time;
            } else if (comm_inactive_flag == 1) {
                unsigned ts_comm_inactive;
                t :> ts_comm_inactive;
                if (ts_comm_inactive - c_time > 1000000*tile_usec) {
                    state = get_next_state(state, checklist, 0, CTRL_COMMUNICATION_TIMEOUT);
                    inactive_timeout_flag = 1;
                }
            }
        } else if (communication_active != 0 && drive_in_opstate != 1) {
            state = get_next_state(state, checklist, 0, CTRL_COMMUNICATION_TIMEOUT);
            inactive_timeout_flag = 1;
        } else {
            comm_inactive_flag = 0;
        }


        /*
         * new, perform actions according to state
         */
#ifdef NETWORK_DRIVE_DEBUG_PRINT_STATE
        debug_print_state(state);
#endif

        if (opmode == OPMODE_NONE) {
            statusword      = update_statusword(statusword, state, 0, quick_stop_steps, 0); /* FiXME update ack and shutdown_ack */
            /* for safety considerations, if no opmode choosen, the brake should blocking. */
            i_torque_control.set_brake_status(0);

            //check and update opmode
            opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity, read_configuration);

        } else if (opmode == OPMODE_CSP || opmode == OPMODE_CST || opmode == OPMODE_CSV) {
            /* FIXME Put this into a separate CSP, CST, CSV function! */
            statusword      = update_statusword(statusword, state, 0, quick_stop_steps, 0); /* FiXME update ack and shutdown_ack */

            /*
             * Additionally used bits in statusword for...
             *
             * ...CSP:
             * Bit 10: Reserved -> 0
             * Bit 12: "Target Position Ignored"
             *         -> 0 Target position ignored
             *         -> 1 Target position shall be used as input to position control loop
             * Bit 13: "Following Error"
             *         -> 0 no error
             *         -> 1 if target_position_value || position_offset is outside of following_error_window
             *              around position_demand_value for longer than following_error_time_out
             */
            statusword = SET_BIT(statusword, SW_CSP_TARGET_POSITION_IGNORED);
            statusword = CLEAR_BIT(statusword, SW_CSP_FOLLOWING_ERROR);

            // FIXME make this function: continous_synchronous_operation(controlword, statusword, state, opmode, checklist, i_motion_control);
            switch (state) {
            case S_NOT_READY_TO_SWITCH_ON:
                /* internal stuff, automatic transition (1) to next state */
                state = get_next_state(state, checklist, 0, 0);
                break;

            case S_SWITCH_ON_DISABLED:
                /* we allow opmode change in this state */
                //check and update opmode

                opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity, read_configuration);

                /* communication active, idle no motor control; read opmode from PDO and set control accordingly */
                state = get_next_state(state, checklist, controlword, 0);

                /* update config on the S_SWITCH_ON_DISABLED -> S_READY_TO_SWITCH_ON transition */
                if (state == S_READY_TO_SWITCH_ON && i_co.od_changed_values_count()) {
                    read_configuration = 1;
                }
                break;

            case S_READY_TO_SWITCH_ON:
                /* nothing special, transition form local (when?) or control device */
                state = get_next_state(state, checklist, controlword, 0);
                break;

            case S_SWITCH_ON:
                /* high power shall be switched on  */
                state = get_next_state(state, checklist, controlword, 0);
                if (state == S_OPERATION_ENABLE) {
                    motioncontrol_enable(opmode, motion_control_config.position_control_strategy, i_motion_control);
                }

                break;

            case S_OPERATION_ENABLE:
                /* drive function shall be enabled and internal set-points are cleared */

                /* check if state change occured */
                state = get_next_state(state, checklist, controlword, 0);
                if (state == S_SWITCH_ON || state == S_READY_TO_SWITCH_ON || state == S_SWITCH_ON_DISABLED) {
                    i_motion_control.disable();
                }

                /* if quick stop is requested start immediately */
                if (state == S_QUICK_STOP_ACTIVE) {
                    qs_start_velocity = actual_velocity;
                    quick_stop_steps = quick_stop_init(opmode, actual_position, actual_velocity, actual_torque, sensor_resolution, quick_stop_deceleration); // <- can be done in the calling command
                    quick_stop_step = 0;
                    qs_target = quick_stop_perform(opmode, quick_stop_step); // compute the fisrt step now
                }
                break;

            case S_QUICK_STOP_ACTIVE:
                /* quick stop function shall be started and running */
                qs_target = quick_stop_perform(opmode, quick_stop_step);

                if (quick_stop_step > quick_stop_steps) {
                    i_motion_control.disable();
                    state = get_next_state(state, checklist, 0, CTRL_QUICK_STOP_FINISHED);
                    quick_stop_steps = 0;
                }
                break;

            case S_FAULT_REACTION_ACTIVE:
                /* a fault is detected, perform fault recovery actions like a quick_stop */
                if (quick_stop_steps == 0) {
                    quick_stop_steps = quick_stop_init(opmode, actual_position, actual_velocity, actual_torque, sensor_resolution, quick_stop_deceleration);
                    quick_stop_step = 0;
                }

                qs_target= quick_stop_perform(opmode, quick_stop_step);

                if (quick_stop_step > quick_stop_steps) {
                    state = get_next_state(state, checklist, 0, CTRL_FAULT_REACTION_FINISHED);
                    quick_stop_steps = 0;
                    i_motion_control.disable();
                }
                break;

            case S_FAULT:
                // check if the object dictionary has changed
                if (i_co.od_changed_values_count()) {
                    read_configuration = 1; //reload config
                }

                /* Wait until fault reset from the control device appears.
                 * When we receive the fault reset, start a timer
                 * and send the fault reset commands.
                 * The fault can only be reset after the end of the timer.
                 * This is because the motorcontrol needs time before restarting.
                 */
                if (read_controlword_fault_reset(controlword) && checklist.fault_reset_wait == false) {
                    //reset fault in motorcontrol
                    if (motorcontrol_fault != NO_FAULT || watchdog_error != WATCHDOG_NO_ERROR) {
                        i_torque_control.reset_faults();
                        checklist.fault_reset_wait = true;
                    }
                    //reset fault in position feedback
                    if (motion_sensor_error != SENSOR_NO_ERROR || commutation_sensor_error != SENSOR_NO_ERROR) {
                        if (!isnull(i_position_feedback_2)) {
                            i_position_feedback_2.set_config(position_feedback_config_2);
                        }
                        i_position_feedback_1.set_config(position_feedback_config_1);
                        checklist.fault_reset_wait = true;
                    }
                    //reset fault in motion control
                    if (motion_control_error != MOTION_CONTROL_NO_ERROR) {
                        i_motion_control.set_motion_control_config(motion_control_config);
                    }
                    //reset communication fault
                    inactive_timeout_flag = 0;
                    //start timer
                    fault_reset_wait_time = time + 1000000*tile_usec; //wait 1s before restarting the motorcontrol
                } else if (checklist.fault_reset_wait == true) {
                    //check if timer ended
                    if (timeafter(time, fault_reset_wait_time)) {
                        checklist.fault_reset_wait = false;
                        /* recheck fault to see if it's realy removed */
                        if ( motorcontrol_fault != NO_FAULT ||
                             motion_sensor_error != SENSOR_NO_ERROR ||
                             commutation_sensor_error != SENSOR_NO_ERROR ||
                             watchdog_error != WATCHDOG_NO_ERROR )
                        {
                            update_checklist(checklist, opmode, 1);
                        }
                    }
                }

                state = get_next_state(state, checklist, controlword, 0);

                if (state == S_SWITCH_ON_DISABLED) {
                    CLEAR_BIT(statusword, SW_FAULT_OVER_CURRENT);
                    CLEAR_BIT(statusword, SW_FAULT_UNDER_VOLTAGE);
                    CLEAR_BIT(statusword, SW_FAULT_OVER_VOLTAGE);
                    CLEAR_BIT(statusword, SW_FAULT_OVER_TEMPERATURE);
                }
                break;

            default: /* should never happen! */
                //printstrln("Should never happen happend.");
                state = get_next_state(state, checklist, 0, FAULT_RESET_CONTROL);
                break;
            }

        } else if (opmode == OPMODE_SNCN_TUNING) {
            /* run offset tuning -> this will be called as long as OPMODE_SNCN_TUNING is set */
            tuning_handler_ethercat(tuning_command,
                    user_miso, tuning_status,
                    tuning_mode_state,
                    motorcontrol_config, motion_control_config, position_feedback_config_1, position_feedback_config_2,
                    sensor_commutation, sensor_motion_control,
                    send_to_master,
                    i_motion_control, i_position_feedback_1, i_position_feedback_2, i_file_service);

            //check and update opmode
            opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity, read_configuration);

            //exit tuning mode
            if (opmode != OPMODE_SNCN_TUNING) {
                opmode = opmode_request; /* stop tuning and switch to new opmode */
                i_motion_control.disable();
                state = S_SWITCH_ON_DISABLED;
                statusword      = update_statusword(0, state, 0, quick_stop_steps, 0); /* FiXME update ack and shutdown_ack */
                //reset tuning status
                tuning_mode_state.brake_flag = 0;
                tuning_mode_state.flags = tuning_set_flags(tuning_mode_state, motorcontrol_config, motion_control_config,
                        position_feedback_config_1, position_feedback_config_2, sensor_commutation);
                tuning_mode_state.motorctrl_status = TUNING_MOTORCTRL_OFF;
                user_miso = 0;
            }
        } else {
            /* if a unknown or unsupported opmode is requested we simply return
             * no opmode and don't allow any operation.
             * For safety reasons, if no opmode is selected the brake is closed! */
            i_torque_control.set_brake_status(0);
            opmode = OPMODE_NONE;
            statusword      = update_statusword(statusword, state, 0, quick_stop_steps, 0); /* FiXME update ack and shutdown_ack */
        }

        /* wait 1 ms to respect timing */
        t when timerafter(time + tile_usec*1000) :> time;

//#pragma xta endpoint "ecatloop_stop"
    }
}

/*
 * super simple test function for debugging without actual ethercat communication to just
 * test if the motor will move.
 */
void network_drive_service_debug(ProfilerConfig &profiler_config,
                            client interface i_pdo_handler_exchange i_pdo,
                            client interface i_co_communication i_co,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback)
{
    MotionControlConfig motion_control_config = i_motion_control.get_motion_control_config();
    PositionFeedbackConfig position_feedback_config = i_position_feedback.get_config();
    MotorcontrolConfig motorcontrol_config = i_torque_control.get_config();

    UpstreamControlData   send_to_master;
    DownstreamControlData send_to_control;
    send_to_control.position_cmd = 0;
    send_to_control.velocity_cmd = 0;
    send_to_control.torque_cmd = 0;
    send_to_control.offset_torque = 0;

    int enabled = 0;

    timer t;
    unsigned time;

    printstr("Motorconfig\n");
    printstr("pole pair: "); printintln(motorcontrol_config.pole_pairs);
    printstr("commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);

    printstr("Protecction limit over current: "); printintln(motorcontrol_config.protection_limit_over_current);
    printstr("Protecction limit over voltage: "); printintln(motorcontrol_config.protection_limit_over_voltage);
    printstr("Protecction limit under voltage: "); printintln(motorcontrol_config.protection_limit_under_voltage);

    t :> time;
//    i_torque_control.set_offset_detection_enabled();
//    delay_milliseconds(30000);

    while (1) {

        send_to_master = i_motion_control.update_control_data(send_to_control);

//        xscope_int(TARGET_POSITION, send_to_control.position_cmd);
//        xscope_int(ACTUAL_POSITION, send_to_master.position);
//        xscope_int(FAMOUS_FAULT,    send_to_master.error_status * 1000);

        if (enabled == 0) {
            //delay_milliseconds(2000);
//            i_torque_control.set_torque_control_enabled();
//            i_motion_control.enable_torque_ctrl();
           //i_motion_control.enable_velocity_ctrl();
           //printstr("enable\n");
            i_motion_control.enable_position_ctrl(POS_PID_CONTROLLER);
            enabled = 1;
        }
        else {
//            i_torque_control.set_torque(100);
//            i_motion_control.set_velocity(0);
//            i_motion_control.set_position(0);
//            i_motion_control.set_velocity(500);
            send_to_control.position_cmd = 100000;
//            send_to_control.offset_torque = 0;
        }

        t when timerafter(time + MSEC_STD) :> time;
    }
}
