/**
 * @file ecat_motor_drive.xc
 * @brief EtherCAT Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_drive_service.h>
#include <refclk.h>
#include <cia402_wrapper.h>
#include <pdo_handler.h>
#include <statemachine.h>
#include <state_modes.h>
#include <profile.h>
#include <config_manager.h>
#include <position_ctrl_service.h>
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

static void sdo_wait_first_config(client interface i_coe_communication i_coe)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    select {
    case i_coe.configuration_ready():
        //printstrln("Master requests OP mode - cyclic operation is about to start.");
        break;
    }

    /* comment in the read_od_config() function to print the object values */
    //read_od_config(i_coe);
    printstrln("start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_coe.configuration_done();
}

{int, int} quick_stop_perform(int steps, int velocity)
{
    static int step = 0;

    if (step >= steps) {
        step = 0;
        return { 0, 0 };
    }

#if 1
    /* This looks like a quick and dirty hack and it is to make the quick_stop stop if we reach
     * a minimal velocity. This avoids the reacceleration of the motor to reach the real quick stop
     * position.
     *
     * FIXME maybe the profile generation is not correct
     *
     */

    if ((velocity < 200) && (velocity > -200)) {
        step = 0;
        return { 0, 0 };
    }
#endif

    int target_position = quick_stop_position_profile_generate(step, velocity);

    step++;

    return { target_position, steps-step };
}

static int quick_stop_init(int opmode,
                                int actual_velocity,
                                int sensor_resolution,
                                int actual_position,
                                ProfilerConfig &profiler_config)
{

    if (opmode == OPMODE_CST || opmode == OPMODE_CSV) {
        /* TODO implement quick stop profile */
    }

    /* FIXME avoid to accelerate to perform a quick stop */
    if ((actual_velocity < 200) && (actual_velocity > -200)) {
        return 0;
    }

    if (actual_velocity < 0) {
        actual_velocity = -actual_velocity;
    }

    int deceleration = profiler_config.max_deceleration;
    int steps = init_quick_stop_position_profile(
                (actual_velocity * sensor_resolution) / 60,
                actual_position,
                (deceleration * sensor_resolution) / 60);

    return steps;
}

static void inline update_configuration(
        client interface i_coe_communication           i_coe,
        client interface MotorcontrolInterface         i_motorcontrol,
        client interface PositionVelocityCtrlInterface i_position_control,
        client interface PositionFeedbackInterface i_pos_feedback,
        PosVelocityControlConfig  &position_config,
        PositionFeedbackConfig    &position_feedback_config,
        MotorcontrolConfig        &motorcontrol_config,
        ProfilerConfig            &profiler_config,
        int &sensor_select,
        int &limit_switch_type,
        int &polarity,
        int &sensor_resolution,
        int &nominal_speed,
        int &homing_method,
        int &opmode)
{
    /* update structures */
    //position_feedback_config;
    //position_config;

    cm_sync_config_position_feedback(i_coe, i_pos_feedback, position_feedback_config);
    cm_sync_config_profiler(i_coe, profiler_config);
    cm_sync_config_motor_control(i_coe, i_motorcontrol, motorcontrol_config);
    cm_sync_config_pos_velocity_control(i_coe, i_position_control, position_config);

    /* Update values with current configuration */
    /* FIXME this looks a little bit obnoxious, is this value really initialized previously? */
    profiler_config.ticks_per_turn = i_pos_feedback.get_ticks_per_turn();
    polarity = profiler_config.polarity;

    nominal_speed     = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
    limit_switch_type = 0; //i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0); /* not used now */
    homing_method     = 0; //i_coe.get_object_value(CIA402_HOMING_METHOD, 0); /* not used now */
    sensor_select     = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);

    sensor_resolution = position_feedback_config.resolution;

    //opmode = i_coe.get_object_value(CIA402_OP_MODES, 0);
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

#define QUICK_STOP_WAIT_COUNTER    2000

#define UPDATE_POSITION_GAIN    0x0000000f
#define UPDATE_VELOCITY_GAIN    0x000000f0
#define UPDATE_TORQUE_GAIN      0x00000f00


/* NOTE:
 * - op mode change only when we are in "Ready to Swtich on" state or below (basically op mode is set locally in this state).
 * - if the op mode signal changes in any other state it is ignored until we fall back to "Ready to switch on" state (Transition 2, 6 and 8)
 */
void ethercat_drive_service(ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface MotorcontrolInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_control,
                            client interface PositionFeedbackInterface i_position_feedback)
{
    int quick_stop_steps = 0;
    int quick_stop_steps_left = 0;
    int quick_stop_count = 0;

    //int target_torque = 0; /* used for CST */
    //int target_velocity = 0; /* used for CSV */
    int target_position = 0;
    int qs_target_position = 0;
    int actual_torque = 0;
    int actual_velocity = 0;
    int actual_position = 0;
    int update_position_velocity = 0;
    int follow_error = 0;
    //int target_position_progress = 0; /* is current target_position necessary to remember??? */

    enum eDirection direction = DIRECTION_NEUTRAL;

    int nominal_speed;
    timer t;

    int init = 0;
    int op_set_flag = 0;

    int opmode = OPMODE_NONE;
    int opmode_request = OPMODE_NONE;

    PosVelocityControlConfig position_velocity_config = i_position_control.get_position_velocity_control_config();

    pdo_handler_values_t InOut = pdo_handler_init();

    int setup_loop_flag = 0;

    int ack = 0;
    int shutdown_ack = 0;
    int sensor_select = 1;

    int communication_active = 0;
    unsigned int c_time;
    int comm_inactive_flag = 0;
    int inactive_timeout_flag = 0;

    /* tuning specific variables */
    int tuning_control = 0;
    //int tuningpdo_status = 0;
    uint32_t tuning_result = 0;
    TuningStatus tuning_status = {0};

    unsigned int time;
    enum e_States state     = S_NOT_READY_TO_SWITCH_ON;
    //enum e_States state_old = state; /* necessary for something??? */

    uint16_t statusword = update_statusword(0, state, 0, 0, 0);
    //uint16_t statusword_old = 0; /* FIXME is the previous statusword send necessary? */
    int controlword = 0;
    //int controlword_old = 0; /* FIXME is the previous controlword received necessary? */

    //int torque_offstate = 0;
    check_list checklist = init_checklist();

    int ctrl_state;
    int limit_switch_type;
    int homing_method;
    int polarity = 1;

    int sensor_resolution = 0;

    PositionFeedbackConfig position_feedback_config = i_position_feedback.get_config();

    MotorcontrolConfig motorcontrol_config = i_motorcontrol.get_config();
    UpstreamControlData   send_to_master = { 0 };
    DownstreamControlData send_to_control = { 0 };

    /*
     * copy the current default configuration into the object dictionary, this will avoid ET_ARITHMETIC in motorcontrol service.
     */

    cm_default_config_position_feedback(i_coe, i_position_feedback, position_feedback_config);
    cm_default_config_profiler(i_coe, profiler_config);
    cm_default_config_motor_control(i_coe, i_motorcontrol, motorcontrol_config);
    cm_default_config_pos_velocity_control(i_coe, i_position_control);

    /* check if the slave enters the operation mode. If this happens we assume the configuration values are
     * written into the object dictionary. So we read the object dictionary values and continue operation.
     *
     * This should be done before we configure anything.
     */
    sdo_wait_first_config(i_coe);

    /* start operation */
    int read_configuration = 1;

    t :> time;
    while (1) {
//#pragma xta endpoint "ecatloop"
        /* FIXME reduce code duplication with above init sequence */
        /* Check if we reenter the operation mode. If so, update the configuration please. */
        select {
            case i_coe.configuration_ready():
                //printstrln("Master requests OP mode - cyclic operation is about to start.");
                read_configuration = 1;
                break;
            default:
                break;
        }

        /* FIXME: When to update configuration values from OD? only do this in state "Ready to Switch on"? */
        if (read_configuration) {
            update_configuration(i_coe, i_motorcontrol, i_position_control, i_position_feedback,
                    position_velocity_config, position_feedback_config, motorcontrol_config, profiler_config,
                    sensor_select, limit_switch_type, polarity, sensor_resolution, nominal_speed, homing_method,
                    opmode
                    );

            read_configuration = 0;
            i_coe.configuration_done();
        }

        /*
         *  local state variables
         */
        controlword     = pdo_get_controlword(InOut);
        opmode_request  = pdo_get_opmode(InOut);
        target_position = pdo_get_target_position(InOut);
        send_to_control.offset_torque = InOut.user1_in; /* FIXME send this to the controll */
        update_position_velocity = InOut.user2_in; /* Update trigger which PID setting should be updated now */

        /* tuning pdos */
        tuning_control = InOut.user4_in;
        tuning_status.value = InOut.user3_in;

        /*
        printint(state);
        printstr(" ");
        printhexln(statusword);
        */

        if (opmode != OPMODE_SNCN_TUNING)
            send_to_control.position_cmd = target_position;
        if (quick_stop_steps != 0) {
            send_to_control.position_cmd = qs_target_position;
        }

        send_to_master = i_position_control.update_control_data(send_to_control);

        /* i_position_control.get_all_feedbacks; */
        actual_velocity = send_to_master.velocity; //i_position_control.get_velocity();
        actual_position = send_to_master.position; //i_position_control.get_position();
        actual_torque   = send_to_master.computed_torque; //i_position_control.get_torque(); /* FIXME expected future implementation! */
        FaultCode fault = send_to_master.error_status;

//        xscope_int(TARGET_POSITION, send_to_control.position_cmd);
//        xscope_int(ACTUAL_POSITION, actual_position);
//        xscope_int(FAMOUS_FAULT, fault * 1000);

        /*
         * Fault signaling to the master in the manufacturer specifc bit in the the statusword
         */
        if (fault != NO_FAULT) {
            update_checklist(checklist, opmode, 1);
            if (fault == OVER_CURRENT_PHASE_A || fault == OVER_CURRENT_PHASE_B || fault == OVER_CURRENT_PHASE_C) {
                SET_BIT(statusword, SW_FAULT_OVER_CURRENT);
            } else if (fault == UNDER_VOLTAGE) {
                SET_BIT(statusword, SW_FAULT_UNDER_VOLTAGE);
            } else if (fault == OVER_VOLTAGE) {
                SET_BIT(statusword, SW_FAULT_OVER_VOLTAGE);
            } else if (fault == 99/*OVER_TEMPERATURE*/) {
                SET_BIT(statusword, SW_FAULT_OVER_TEMPERATURE);
            }
        }

        follow_error = target_position - actual_position; /* FIXME only relevant in OP_ENABLED - used for what??? */

        direction = (actual_velocity < 0) ? DIRECTION_CCLK : DIRECTION_CLK;

        /*
         *  update values to send
         */
        pdo_set_statusword(statusword, InOut);
        pdo_set_opmode_display(opmode, InOut);
        pdo_set_actual_velocity(actual_velocity, InOut);
        pdo_set_actual_torque(actual_torque, InOut );
        pdo_set_actual_position(actual_position, InOut);
        InOut.user1_out = (1000 * 5 * send_to_master.sensor_torque) / 4096;  /* ticks to (edit:) milli-volt */
        InOut.user4_out = tuning_result;

        //xscope_int(USER_TORQUE, InOut.user1_out);

        /* Read/Write packets to ethercat Master application */
        communication_active = pdo_handler(i_pdo, InOut);

        if (communication_active == 0) {
            if (comm_inactive_flag == 0) {
                comm_inactive_flag = 1;
                t :> c_time;
            } else if (comm_inactive_flag == 1) {
                unsigned ts_comm_inactive;
                t :> ts_comm_inactive;
                if (ts_comm_inactive - c_time > 1*SEC_STD) {
                    state = get_next_state(state, checklist, 0, CTRL_COMMUNICATION_TIMEOUT);
                    inactive_timeout_flag = 1;
                }
            }
        } else {
            comm_inactive_flag = 0;
        }

        /* Check states of the motor drive, sensor drive and control servers */
        update_checklist(checklist, opmode, fault);

        /*
         * new, perform actions according to state
         */
        //debug_print_state(state);

        if (opmode == OPMODE_NONE) {
            /* for safety considerations, if no opmode choosen, the brake should blocking. */
            i_motorcontrol.set_brake_status(0);
            if (opmode_request != OPMODE_NONE)
                opmode = opmode_request;

        } else if (opmode == OPMODE_CSP || opmode == OPMODE_CST || opmode == OPMODE_CSV) {
            /* FIXME Put this into a separate CSP, CST, CSV function! */
            statusword      = update_statusword(statusword, state, 0, 0, 0); /* FiXME update ack, q_active and shutdown_ack */

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

            // FIXME make this function: continous_synchronous_operation(controlword, statusword, state, opmode, checklist, i_position_control);
            switch (state) {
            case S_NOT_READY_TO_SWITCH_ON:
                /* internal stuff, automatic transition (1) to next state */
                state = get_next_state(state, checklist, 0, 0);
                break;

            case S_SWITCH_ON_DISABLED:
                if (opmode_request == OPMODE_CSP) { /* FIXME check for supported opmodes if applicable */
                    opmode = opmode;
                } else {
                    opmode = opmode_request;
                }

                /* communication active, idle no motor control; read opmode from PDO and set control accordingly */
                state = get_next_state(state, checklist, controlword, 0);
                break;

            case S_READY_TO_SWITCH_ON:
                /* nothing special, transition form local (when?) or control device */
                state = get_next_state(state, checklist, controlword, 0);
                break;

            case S_SWITCH_ON:
                /* high power shall be switched on  */
                state = get_next_state(state, checklist, controlword, 0);
                if (state == S_OPERATION_ENABLE) {
                    i_position_control.enable_position_ctrl(position_velocity_config.control_mode);
                }
                break;

            case S_OPERATION_ENABLE:
                /* drive function shall be enabled and internal set-points are cleared */

                /* check if state change occured */
                state = get_next_state(state, checklist, controlword, 0);
                if (state == S_SWITCH_ON || state == S_READY_TO_SWITCH_ON || state == S_SWITCH_ON_DISABLED) {
                    i_position_control.disable();
                }

                /* if quick stop is requested start immediately */
                if (state == S_QUICK_STOP_ACTIVE) {
                    quick_stop_steps = quick_stop_init(opmode, actual_velocity, sensor_resolution, actual_position, profiler_config); // <- can be done in the calling command
                }
                break;

            case S_QUICK_STOP_ACTIVE:
                /* quick stop function shall be started and running */
            { qs_target_position, quick_stop_steps_left } = quick_stop_perform(quick_stop_steps, actual_velocity);

            if (quick_stop_steps_left == 0 ) {
                quick_stop_count += 1;
                qs_target_position = actual_position;
                i_position_control.disable();
                if (quick_stop_count >= QUICK_STOP_WAIT_COUNTER) {
                    state = get_next_state(state, checklist, 0, CTRL_QUICK_STOP_FINISHED);
                    quick_stop_steps = 0;
                    quick_stop_count = 0;
                }
            }

            break;

            case S_FAULT_REACTION_ACTIVE:
                /* a fault is detected, perform fault recovery actions like a quick_stop */
                if (quick_stop_steps == 0) {
                    quick_stop_steps = quick_stop_init(opmode, actual_velocity, sensor_resolution, actual_position, profiler_config);
                }

                { qs_target_position, quick_stop_steps_left } = quick_stop_perform(quick_stop_steps, actual_velocity);

                if (quick_stop_steps_left == 0) {
                    state = get_next_state(state, checklist, 0, CTRL_FAULT_REACTION_FINISHED);
                    quick_stop_steps = 0;
                    qs_target_position = actual_position;
                    i_position_control.disable();
                }
                break;

            case S_FAULT:
                /* wait until fault reset from the control device appears */
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
            if (opmode_request != opmode) {
                opmode = opmode_request; /* stop tuning and switch to new opmode */
                i_position_control.disable();
                state = S_FAULT;
                //reset tuning status
                tuning_status.brake_flag = 0;
                tuning_status.motorctrl_status = TUNING_MOTORCTRL_OFF;
            }

            tuning_handler_ethercat(controlword, tuning_control,
                    statusword, tuning_result,
                    tuning_status,
                    motorcontrol_config, position_velocity_config, position_feedback_config,
                    send_to_master, send_to_control,
                    i_position_control, i_position_feedback);
        } else {
            /* if a unknown or unsupported opmode is requested we simply return
             * no opmode and don't allow any operation.
             * For safety reasons, if no opmode is selected the brake is closed! */
            i_motorcontrol.set_brake_status(0);
            opmode = OPMODE_NONE;
        }

#if 1 /* Draft to get PID updates on the fly */
        t :> time; /* FIXME check the timing here! */

        if ((update_position_velocity & UPDATE_POSITION_GAIN) == UPDATE_POSITION_GAIN) {
            /* Update PID vlaues so they can be set on the fly */
            position_velocity_config.P_pos          = i_coe.get_object_value(CIA402_POSITION_GAIN, 1); /* POSITION_Kp; */
            position_velocity_config.I_pos          = i_coe.get_object_value(CIA402_POSITION_GAIN, 2); /* POSITION_Ki; */
            position_velocity_config.D_pos          = i_coe.get_object_value(CIA402_POSITION_GAIN, 3); /* POSITION_Kd; */

            i_position_control.set_position_velocity_control_config(position_velocity_config);
        }

        if ((update_position_velocity & UPDATE_VELOCITY_GAIN) == UPDATE_VELOCITY_GAIN) {
            position_velocity_config.P_velocity          = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 1); /* 18; */
            position_velocity_config.I_velocity          = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 2); /* 22; */
            position_velocity_config.D_velocity          = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 2); /* 25; */

            i_position_control.set_position_velocity_control_config(position_velocity_config);
        }


        /*
        motorcontrol_config.current_P_gain     = i_coe.get_object_value(CIA402_CURRENT_GAIN, 1);
        motorcontrol_config.current_I_gain     = i_coe.get_object_value(CIA402_CURRENT_GAIN, 2);
        motorcontrol_config.current_D_gain     = i_coe.get_object_value(CIA402_CURRENT_GAIN, 3);
         */
#endif

        /* wait 1 ms to respect timing */
        t when timerafter(time + MSEC_STD) :> time;

//#pragma xta endpoint "ecatloop_stop"
    }
}

/*
 * super simple test function for debugging without actual ethercat communication to just
 * test if the motor will move.
 */
void ethercat_drive_service_debug(ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface MotorcontrolInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_control,
                            client interface PositionFeedbackInterface i_position_feedback)
{
    PosVelocityControlConfig position_velocity_config = i_position_control.get_position_velocity_control_config();
    PositionFeedbackConfig position_feedback_config = i_position_feedback.get_config();
    MotorcontrolConfig motorcontrol_config = i_motorcontrol.get_config();

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
    printstr("pole pair: "); printintln(motorcontrol_config.pole_pair);
    printstr("commutation offset: "); printintln(motorcontrol_config.commutation_angle_offset);

    printstr("Protecction limit over current: "); printintln(motorcontrol_config.protection_limit_over_current);
    printstr("Protecction limit over voltage: "); printintln(motorcontrol_config.protection_limit_over_voltage);
    printstr("Protecction limit under voltage: "); printintln(motorcontrol_config.protection_limit_under_voltage);

    t :> time;
//    i_motorcontrol.set_offset_detection_enabled();
//    delay_milliseconds(30000);

    while (1) {

        send_to_master = i_position_control.update_control_data(send_to_control);

//        xscope_int(TARGET_POSITION, send_to_control.position_cmd);
//        xscope_int(ACTUAL_POSITION, send_to_master.position);
//        xscope_int(FAMOUS_FAULT,    send_to_master.error_status * 1000);

        if (enabled == 0) {
            //delay_milliseconds(2000);
//            i_motorcontrol.set_torque_control_enabled();
//            i_position_control.enable_torque_ctrl();
           //i_position_control.enable_velocity_ctrl();
           //printstr("enable\n");
            i_position_control.enable_position_ctrl(POS_PID_CONTROLLER);
            enabled = 1;
        }
        else {
//            i_motorcontrol.set_torque(100);
//            i_position_control.set_velocity(0);
//            i_position_control.set_position(0);
//            i_position_control.set_velocity(500);
            send_to_control.position_cmd = 100000;
//            send_to_control.offset_torque = 0;
        }

        t when timerafter(time + MSEC_STD) :> time;
    }
}
