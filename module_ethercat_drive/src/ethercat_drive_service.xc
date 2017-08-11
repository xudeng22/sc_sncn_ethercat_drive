/**
 * @file ecat_motor_drive.xc
 * @brief EtherCAT Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <cia402_error_codes.h>
#include <ethercat_drive_service.h>
#include <refclk.h>
#include <cia402_wrapper.h>
#include <pdo_handler.h>
#include <statemachine.h>
#include <state_modes.h>
#include <profile.h>
#include <config_manager.h>
#include <motion_control_service.h>
#include <position_feedback_service.h>
#include <spiffs_service.h>
#include <config_parser.h>
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



static unsigned int set_configuration_to_dictionary(
        client interface i_coe_communication i_canopen,
        ConfigParameter_t* Config)
{
    unsigned int i;

    for (i = 0; i < Config->param_count; i++) {
        i_canopen.set_object_value(Config->parameter[i][0].index, Config->parameter[i][0].subindex, Config->parameter[i][0].value);
    }
    return i;
}


static int exclude_object(uint16_t index)
{
    const uint16_t blacklist[] = {
            0x2000, 0x603f, /* special objects */
            0x6040, 0x6060, 0x6071, 0x607a, 0x60ff, 0x2300, 0x2a01, 0x2601, 0x2602, 0x2603, 0x2604, 0x2ffe, /* receive pdos */
            0x6041, 0x6061, 0x6064, 0x606c, 0x6077, 0x230a, 0x230b, 0x2401, 0x2402, 0x2403, 0x2404, 0x2a03, 0x2501, 0x2502, 0x2503, 0x2504, 0x2fff, 0x2ffd /* send pdos */
    };

    for (int i = 0; i < sizeof(blacklist)/sizeof(blacklist[0]); i++) {
        if (index == blacklist[i])
            return 1;
    }

    return 0;
}


static unsigned get_configuration_from_dictionary(
        client interface i_coe_communication i_canopen,
        ConfigParameter_t* Config)
{
    uint16_t list_lengths[5];
    //i_canopen.od_get_all_list_length(list_lengths);

   /* if (list_lengths[0] > MAX_CONFIG_SDO_ENTRIES) {
        printstrln("Warning OD to large, only get what fits.");
    }*/

    uint16_t all_od_objects[MAX_CONFIG_SDO_ENTRIES] = { 0 };
    //i_canopen.od_get_list(all_od_objects, list_lengths[0], OD_LIST_ALL);

    struct _sdoinfo_entry_description od_entry;

    int count = 0;
    uint32_t value = 0;
    //uint8_t error = 0;
    for (unsigned i = 0; i < list_lengths[0]; i++) {
        /* Skip objects below index 0x2000 */
        if (all_od_objects[i] < 0x2000) {
            continue;
        }

        /* filter out unnecessary objects (like PDOs and command objects or read only stuff) */
        if (exclude_object(all_od_objects[i])) {
            continue;
        }

       // error = i_canopen.od_get_object_description(od_entry, all_od_objects[i], 0);

        /* object is no simple variable and subindex 0 holds the highest subindex then read all sub elements */
        if (od_entry.objectCode != CANOD_TYPE_VAR && od_entry.value > 0) {
            for (unsigned k = 1; k <= od_entry.value; k++) {
                value = i_canopen.get_object_value(all_od_objects[i], k);
                Config->parameter[count][0].index    = all_od_objects[i];
                Config->parameter[count][0].subindex = k;
                Config->parameter[count][0].value    = value;
                count++;
            }
        } else { /* simple variable object */
            value = i_canopen.get_object_value(all_od_objects[i], 0);
            Config->parameter[count][0].index    = od_entry.index;
            Config->parameter[count][0].subindex = 0;
            Config->parameter[count][0].value    = value;
            count++;
        }
    }

    Config->param_count = count;
    Config->node_count = 1;

    return count;
}


static int flash_write_od_config(
        client SPIFFSInterface i_spiffs,
        client interface i_coe_communication i_canopen)
{
    int result = 0;
    ConfigParameter_t Config;

    get_configuration_from_dictionary(i_canopen, &Config);

    if ((result = write_config(CONFIG_FILE_NAME, &Config, i_spiffs)) >= 0)

    if (result == 0) {
        // put the flash configuration into the dictionary
        set_configuration_to_dictionary(i_canopen, &Config);
    }

    return result;
}



static int flash_read_od_config(
        client SPIFFSInterface i_spiffs,
        client interface i_coe_communication i_canopen)
{
    int result = 0;
    ConfigParameter_t Config;

    if ((result = read_config(CONFIG_FILE_NAME, &Config, i_spiffs)) >= 0)

    if (result == 0) {
        // put the flash configuration into the dictionary
        set_configuration_to_dictionary(i_canopen, &Config);
    }
    return result;
}





static int get_cia402_error_code(FaultCode motorcontrol_fault, SensorError motion_sensor_error,
                                 SensorError commutation_sensor_error, MotionControlError motion_control_error,
                                 int inactive_timeout_flag)
{
    int error_code = 0;

    switch (motorcontrol_fault) {
    case DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1:
        error_code = ERROR_CODE_PHASE_FAILURE_L1;
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
    case NO_FAULT:
        /* if there is no motorcontrol fault check sensor fault
         * it means that motorcontrol faults take precedence over sensor faults
         * */
        if (commutation_sensor_error != SENSOR_NO_ERROR || motion_sensor_error != SENSOR_NO_ERROR) {
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
    }

    return error_code;
}

static void sdo_wait_first_config(client interface i_coe_communication i_coe)
{
    select {
    case i_coe.operational_state_change():
        //printstrln("Master requests OP mode - cyclic operation is about to start.");
        break;
    }

    /* comment in the read_od_config() function to print the object values */
    //read_od_config(i_coe);
    printstrln("start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_coe.configuration_done();
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
        client interface i_coe_communication           i_coe,
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
    int number_of_feedbacks_ports = i_coe.get_object_value(DICT_FEEDBACK_SENSOR_PORTS, 0);
    int feedback_port_index = 1;
    restart += cm_sync_config_position_feedback(i_coe, i_pos_feedback_1, position_feedback_config_1, 1,
            sensor_commutation, sensor_motion_control,
            number_of_feedbacks_ports, feedback_port_index);
    if (!isnull(i_pos_feedback_2)) {
        restart += cm_sync_config_position_feedback(i_coe, i_pos_feedback_2, position_feedback_config_2, 2,
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

    cm_sync_config_profiler(i_coe, profiler_config, PROFILE_TYPE_POSITION); /* FIXME currently only one profile type is used! */
    int max_torque = cm_sync_config_motor_control(i_coe, i_torque_control, motorcontrol_config, sensor_commutation, sensor_commutation_type);
    cm_sync_config_pos_velocity_control(i_coe, i_motion_control, position_config, sensor_resolution, max_torque);

    //FIXME: as the hall_states params are still in the motorcontrol config they are set in cm_sync_config_motor_control
//    cm_sync_config_hall_states(i_coe, i_pos_feedback_1, i_torque_control, position_feedback_config_1, motorcontrol_config, 1);

    /* Update values with current configuration */
    profiler_config.ticks_per_turn = sensor_resolution;
    nominal_speed     = i_coe.get_object_value(DICT_MAX_MOTOR_SPEED, 0);
    limit_switch_type = 0; //i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0); /* not used now */
    homing_method     = 0; //i_coe.get_object_value(CIA402_HOMING_METHOD, 0); /* not used now */
    polarity          = i_coe.get_object_value(DICT_POLARITY, 0);
    quick_stop_deceleration = i_coe.get_object_value(DICT_QUICK_STOP_DECELERATION, 0);
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

//#pragma xta command "analyze loop ecatloop"
//#pragma xta command "set required - 1.0 ms"

#define UPDATE_POSITION_GAIN    0x0000000f
#define UPDATE_VELOCITY_GAIN    0x000000f0
#define UPDATE_TORQUE_GAIN      0x00000f00


/* NOTE:
 * - op mode change only when we are in "Ready to Swtich on" state or below (basically op mode is set locally in this state).
 * - if the op mode signal changes in any other state it is ignored until we fall back to "Ready to switch on" state (Transition 2, 6 and 8)
 */
void ethercat_drive_service(server SDO_Config sdo_config,
                            ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2,
                            client SPIFFSInterface i_spiffs)
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

    pdo_handler_values_t InOut = { 0 };

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

    if (flash_read_od_config(i_spiffs, i_coe) != 0) {
          printstrln("Warning: Could not read object dictionary from file system.");

        /*
         * copy the current default configuration into the object dictionary, this will avoid ET_ARITHMETIC in motorcontrol service.
         */
        cm_default_config_position_feedback(i_coe, i_position_feedback_1, position_feedback_config_1, 1);
        if (!isnull(i_position_feedback_2)) {
            cm_default_config_position_feedback(i_coe, i_position_feedback_2, position_feedback_config_2, 2);
        }
        cm_default_config_profiler(i_coe, profiler_config);
        cm_default_config_motor_control(i_coe, i_torque_control, motorcontrol_config);
        cm_default_config_pos_velocity_control(i_coe, i_motion_control);
        i_coe.set_object_value(DICT_QUICK_STOP_DECELERATION, 0, profiler_config.max_deceleration); //we use profiler.max_deceleration as the default value for quick stop deceleration
    }
    /* check if the slave enters the operation mode. If this happens we assume the configuration values are
     * written into the object dictionary. So we read the object dictionary values and continue operation.
     *
     * This should be done before we configure anything.
     */
    sdo_wait_first_config(i_coe);

    /* if we reach this point the EtherCAT service is considered in OPMODE */
    int drive_in_opstate = 1;

    /* start operation */
    int read_configuration = 1;

    t :> time;
    while (1) {
//#pragma xta endpoint "ecatloop"
        /* FIXME reduce code duplication with above init sequence */
        /* Check if we reenter the operation mode. If so, update the configuration please. */
        select {
            case i_coe.operational_state_change():
                //printstrln("Master requests OP mode - cyclic operation is about to start.");
                drive_in_opstate = i_coe.in_op_state();
                if (drive_in_opstate) {
                    read_configuration = 1;
                }
                break;
            default:
                break;
        }

        select {
            case !isnull(i_spiffs) => sdo_config.write_od_config() -> int res:

                    res = flash_write_od_config(i_spiffs, i_coe);
                    break;

           case !isnull(i_spiffs) => sdo_config.read_od_config() -> int res:

                   res = flash_read_od_config(i_spiffs, i_coe);
                   break;
        }

        /* FIXME: When to update configuration values from OD? only do this in state "Ready to Switch on"? */
        if (read_configuration) {
            update_configuration(i_coe, i_torque_control, i_motion_control, i_position_feedback_1, i_position_feedback_2,
                    motion_control_config, position_feedback_config_1, position_feedback_config_2, motorcontrol_config, profiler_config,
                    sensor_commutation, sensor_motion_control, limit_switch_type, sensor_resolution, polarity, nominal_speed, homing_method,
                    quick_stop_deceleration
                    );
            tuning_mode_state.flags = tuning_set_flags(tuning_mode_state, motorcontrol_config, motion_control_config,
                    position_feedback_config_1, position_feedback_config_2, sensor_commutation);
            read_configuration = 0;
            i_coe.configuration_done();
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

//        xscope_int(TARGET_POSITION, send_to_control.position_cmd);
//        xscope_int(ACTUAL_POSITION, actual_position);
//        xscope_int(FAMOUS_FAULT, motorcontrol_fault * 1000);

        /*
         * Check states of the motor drive, sensor drive and control servers
         * Fault signaling to the master in the manufacturer specifc bit in the the statusword
         */
        if (motorcontrol_fault != NO_FAULT ||
                motion_sensor_error != SENSOR_NO_ERROR || commutation_sensor_error != SENSOR_NO_ERROR ||
                motion_control_error != MOTION_CONTROL_NO_ERROR ||
                inactive_timeout_flag)
        {
            update_checklist(checklist, opmode, 1);
            if (motorcontrol_fault == DEVICE_INTERNAL_CONTINOUS_OVER_CURRENT_NO_1) {
                SET_BIT(statusword, SW_FAULT_OVER_CURRENT);
            } else if (motorcontrol_fault == UNDER_VOLTAGE_NO_1) {
                SET_BIT(statusword, SW_FAULT_UNDER_VOLTAGE);
            } else if (motorcontrol_fault == OVER_VOLTAGE_NO_1) {
                SET_BIT(statusword, SW_FAULT_OVER_VOLTAGE);
            } else if (motorcontrol_fault == 99/*OVER_TEMPERATURE*/) {
                SET_BIT(statusword, SW_FAULT_OVER_TEMPERATURE);
            }

            /* Write error code to object dictionary */
            error_code = get_cia402_error_code(motorcontrol_fault, motion_sensor_error, commutation_sensor_error,
                                               motion_control_error, inactive_timeout_flag);
            i_coe.set_object_value(DICT_ERROR_CODE, 0, error_code);
        } else {
            update_checklist(checklist, opmode, 0); //no error
            error_code = 0;
            i_coe.set_object_value(DICT_ERROR_CODE, 0, 0);
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

//        xscope_int(ACTUAL_VELOCITY, actual_velocity);
//        xscope_int(ACTUAL_POSITION, actual_position);

        /* Read/Write packets to ethercat Master application */
        communication_active = pdo_handler(i_pdo, InOut);

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
//        debug_print_state(state);

        if (opmode == OPMODE_NONE) {
            statusword      = update_statusword(statusword, state, 0, quick_stop_steps, 0); /* FiXME update ack and shutdown_ack */
            /* for safety considerations, if no opmode choosen, the brake should blocking. */
            i_torque_control.set_brake_status(0);

            //check and update opmode
            opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity);

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
                opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity);

                /* communication active, idle no motor control; read opmode from PDO and set control accordingly */
                state = get_next_state(state, checklist, controlword, 0);

                /* update config on the S_SWITCH_ON_DISABLED -> S_READY_TO_SWITCH_ON transition */
                if (state == S_READY_TO_SWITCH_ON) {
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
                /* Wait until fault reset from the control device appears.
                 * When we receive the fault reset, start a timer
                 * and send the fault reset commands.
                 * The fault can only be reset after the end of the timer.
                 * This is because the motorcontrol needs time before restarting.
                 */
                if (read_controlword_fault_reset(controlword) && checklist.fault_reset_wait == false) {
                    //reset fault in motorcontrol
                    if (motorcontrol_fault != NO_FAULT) {
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
                    //reset fault in position feedback
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
                        if (motorcontrol_fault != NO_FAULT || motion_sensor_error != SENSOR_NO_ERROR || commutation_sensor_error != SENSOR_NO_ERROR) {
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
                    i_motion_control, i_position_feedback_1, i_position_feedback_2);

            //check and update opmode
            opmode = update_opmode(opmode, opmode_request, i_motion_control, motion_control_config, polarity);

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
void ethercat_drive_service_debug(server SDO_Config sdo_config,
                            ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback,
                            client SPIFFSInterface i_spiffs)
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
