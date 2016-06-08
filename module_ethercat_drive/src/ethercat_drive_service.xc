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

static int get_sensor_resolution(int sensor_select, PositionFeedbackConfig position_feedback_config)
{
    int sensor_resolution = 0;

    if (sensor_select == HALL_SENSOR) {
        sensor_resolution = 0; /* FIXME the resolution has to be provided in PositionFeedbackConfig structure */
    } else if (sensor_select == QEI_SENSOR) {
        sensor_resolution = 0; /* FIXME the resolution has to be provided in PositionFeedbackConfig structure */
    } else if (sensor_select == BISS_SENSOR) {
        sensor_resolution = position_feedback_config.biss_config.singleturn_resolution;
    } else if (sensor_select == AMS_SENSOR) {
        sensor_resolution = 0; /* FIXME the resolution has to be provided in PositionFeedbackConfig structure */
    } else if (sensor_select == CONTELEC_SENSOR) {
        sensor_resolution = position_feedback_config.contelec_config.resolution_bits;
    }

    return sensor_resolution;
}

#define MAX_TIME_TO_WAIT_SDO      100000

static void sdo_wait_first_config(client interface i_coe_communication i_coe)
{
    timer t;
    unsigned int delay = MAX_TIME_TO_WAIT_SDO;
    unsigned int time;

    int sdo_configured = 0;

    while (sdo_configured == 0) {
        select {
            case i_coe.configuration_ready():
                //printstrln("Master requests OP mode - cyclic operation is about to start.");
                sdo_configured = 1;
                break;
        }

        t when timerafter(time+delay) :> time;
    }

    /* comment in the read_od_config() function to print the object values */
    //read_od_config(i_coe);
    printstrln("Configuration finished, ECAT in OP mode - start cyclic operation");

    /* clear the notification before proceeding the operation */
    i_coe.configuration_done();
}

{int, int} quick_stop_perform(int steps, int velocity)
{
    static int step = 0;

    if (step >= steps)
        return { 0, 0 };

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
        client interface MotorcontrolInterface         i_commutation,
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
    cm_sync_config_motor_control(i_coe, i_commutation, motorcontrol_config);
    cm_sync_config_pos_velocity_control(i_coe, i_position_control, position_config);

    /* Update values with current configuration */
    /* FIXME this looks a little bit obnoxious, is this value really initialized previously? */
    profiler_config.ticks_per_turn = i_pos_feedback.get_ticks_per_turn();
    polarity = profiler_config.polarity;

    nominal_speed     = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
    limit_switch_type = i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0);
    homing_method     = i_coe.get_object_value(CIA402_HOMING_METHOD, 0);
    sensor_select     = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);

    sensor_resolution = get_sensor_resolution(sensor_select, position_feedback_config);

    opmode = i_coe.get_object_value(CIA402_OP_MODES, 0);
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

/* NOTE:
 * - op mode change only when we are in "Ready to Swtich on" state or below (basically op mode is set locally in this state).
 * - if the op mode signal changes in any other state it is ignored until we fall back to "Ready to switch on" state (Transition 2, 6 and 8)
 */
void ethercat_drive_service(ProfilerConfig &profiler_config,
                            chanend pdo_out, chanend pdo_in,
                            client interface i_coe_communication i_coe,
                            client interface MotorcontrolInterface i_motorcontrol,
                            client interface PositionVelocityCtrlInterface i_position_control,
                            client interface PositionFeedbackInterface i_position_feedback)
{
    int quick_stop_steps = 0;
    int quick_stop_steps_left = 0;

    //int target_torque = 0; /* used for CST */
    //int target_velocity = 0; /* used for CSV */
    int target_position = 0;
    int qs_target_position = 0;
    int actual_torque = 0;
    int actual_velocity = 0;
    int actual_position = 0;

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

    ctrl_proto_values_t InOut = init_ctrl_proto();

    int setup_loop_flag = 0;

    int ack = 0;
    int shutdown_ack = 0;
    int sensor_select = -1;

    int communication_active = 0;
    unsigned int c_time;
    int comm_inactive_flag = 0;
    int inactive_timeout_flag = 0;

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

    UpstreamControlData   txdata;
    DownstreamControlData rxdata;

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
        statusword      = update_statusword(statusword, state, 0, 0, 0); /* FiXME update ack, q_active and shutdown_ack */
        controlword     = pdo_get_controlword(InOut);
        opmode_request  = pdo_get_opmode(InOut);
        target_position = pdo_get_target_position(InOut);

        rxdata.position_cmd = target_position;
        if (quick_stop_steps != 0) {
            rxdata.position_cmd = qs_target_position;
        }

        txdata = i_position_control.update_control_data(rxdata);

        /* i_position_control.get_all_feedbacks; */
        actual_velocity = txdata.velocity; //i_position_control.get_velocity();
        actual_position = txdata.position; //i_position_control.get_position();
        actual_torque   = txdata.computed_torque; //i_position_control.get_torque(); /* FIXME expected future implementation! */

        follow_error = target_position - actual_position; /* FIXME only relevant in OP_ENABLED - used for what??? */

        direction = (actual_velocity < 0) ? DIRECTION_CCLK : DIRECTION_CLK;

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

        /*
         *  update values to send
         */
        pdo_set_statusword(statusword, InOut);
        pdo_set_opmode_display(opmode, InOut);
        pdo_set_actual_velocity(actual_velocity, InOut);
        pdo_set_actual_torque(actual_torque, InOut );
        pdo_set_actual_position(actual_position * polarity, InOut);


        /* Read/Write packets to ethercat Master application */
        communication_active = ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);

        if (communication_active == 0) {
            if (comm_inactive_flag == 0) {
                comm_inactive_flag = 1;
                t :> c_time;
            } else if (comm_inactive_flag == 1) {
                unsigned ts_comm_inactive;
                t :> ts_comm_inactive;
                if (ts_comm_inactive - c_time > 1*SEC_STD) {
                    //printstrln("comm inactive timeout");
                    state = get_next_state(state, checklist, 0, CTRL_COMMUNICATION_TIMEOUT);
                    printstrln("Timeout Hit got to fault mode");
                    t :> c_time;
                    t when timerafter(c_time + 2*SEC_STD) :> c_time;
                    inactive_timeout_flag = 1;
                }
            }
        } else {
            comm_inactive_flag = 0;
        }

        /* Check states of the motor drive, sensor drive and control servers */
        update_checklist(checklist, opmode, 0);

        /*
         * new, perform actions according to state
         */
        //debug_print_state(state);

        switch (state) {
        case S_NOT_READY_TO_SWITCH_ON:
            /* internal stuff, automatic transition (1) to next state */
            state = get_next_state(state, checklist, 0, 0);
            break;

        case S_SWITCH_ON_DISABLED:
            if (opmode_request != OPMODE_CSP) { /* FIXME check for supported opmodes if applicable */
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
                i_position_control.enable_position_ctrl();
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
                state = get_next_state(state, checklist, 0, CTRL_QUICK_STOP_FINISHED);
                quick_stop_steps = 0;
                qs_target_position = actual_position;
                i_position_control.disable();
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
            break;

        default: /* should never happen! */
            //printstrln("Should never happen happend.");
            state = get_next_state(state, checklist, 0, FAULT_RESET_CONTROL);
            break;
        }

        /*
         * current way of doing things
         */
#if 0
        /*********************************************************************************
         * If communication is inactive, trigger quick stop mode if motor is in motion
         *********************************************************************************/
        if (inactive_timeout_flag == 1) {
            //printstrln("Triggering quick stop mode");

            if(controlword != controlword_old
                    || state != state_old
                    || statusword != statusword_old
                    || InOut.operation_mode != op_mode_commanded_old
                    || op_mode != op_mode_old) {
                printf("Inactive_COMM!!!, Control_word: %d  |  State: %s  |   Statusword: %d  |   Op_mode_commanded %d, Op_mode_assigned %d\n",
                        controlword, state_names[state], statusword, InOut.operation_mode, op_mode);
            }

            controlword_old = controlword;
            state_old = state;
            statusword_old = statusword;
            op_mode_commanded_old = InOut.operation_mode;
            op_mode_old = op_mode;

            quick_stop_steps = quick_stop_init(op_mode, actual_velocity, sensor_resolution, actual_position, profiler_config);
            state = get_next_state(state, checklist, controlword, CTRL_QUICK_STOP_INIT);

            quick_active = 1;

            /* FIXME safe to get rid of? */
            mode_selected = 0;
            setup_loop_flag = 0;
            op_set_flag = 0;
            op_mode = 256;      /* FIXME: why 256? */
        }

        /* state:                   action to perform:
         * NO_READY_TO_SWITCH_ON -> self test, self initialisation (if appropreate)
         * SWITCH_ON_DISABLED    -> Communication shall be activated (basically as soon as we enter the loop)
         * READY_TO_SWITCH_ON    -> none (command from control device)
         * SWITCHED_ON           -> local (which?) signal or control device, high-level power shall be switched on if possible
         * OPERATION_ENABLED     -> local (which?) signal or control device, enable drive function
         */

        /*********************************************************************************
         * EtherCAT communication is Active
         *********************************************************************************/
        if (comm_inactive_flag == 0) { /* communication active, i.e. PDOs arrive */
            //printstrln("EtherCAT comm active");
            /* Read controlword from the received from EtherCAT Master application */
            controlword = InOut.control_word;

            /* Check states of the motor drive, sensor drive and control servers */
            update_checklist(checklist, mode, i_commutation, i_hall, i_qei, i_biss, i_ams, null,
                             i_torque_control, i_velocity_control, i_position_control);

            /* Update state machine */
            state = get_next_state(state, checklist, controlword, 0);

            /* Update statusword sent to the EtherCAT Master Application */
            statusword = update_statusword(statusword, state, ack, quick_active, shutdown_ack);
            InOut.status_word = statusword;

            if(controlword != controlword_old
                    || state != state_old
                    || statusword != statusword_old
                    || InOut.operation_mode != op_mode_commanded_old
                    || op_mode != op_mode_old) {
                printf("Active_COMM, Control_word: %d  |  State: %s  |   Statusword: %d  |   Op_mode_commanded %d, Op_mode_assigned %d\n",
                        controlword, state_names[state], statusword, InOut.operation_mode, op_mode);
            }

            controlword_old       = controlword;
            state_old             = state;
            statusword_old        = statusword;
            op_mode_commanded_old = InOut.operation_mode;
            op_mode_old           = op_mode;



            /* FIXME - deprecated since the configuration is checked in the beginning of the loop
             * WRONG! There is no controlword '5' in std. controls, only
             * possibility "Disable Voltage" but Bit 0 and 2 are don't care!
             * Besides, op mode 105 is in the reserved are of valid values! */
            if (setup_loop_flag == 0) {
                if (controlword == 6) {
                    InOut.operation_mode_display = 105;
                }
                /* Read Motor Configuration sent from the EtherCAT Master Application */
                if (controlword == 5) {
                    setup_loop_flag = 1;
                    op_set_flag = 0;
                }
            }

            /* ################################
             * Error Handling
             * ################################ */

            if (!checklist.fault)
            {
#if 0 /* the i_adc got lost somehow, somewhere... */
                /* Temperature */
                if (i_adc.get_temperature() > TEMP_THRESHOLD) {
                    checklist.fault = true;

                }
#endif

                /* Speed - FIXME add check if actual speed is > than speed limits */
                if (ABSOLUTE_VALUE(actual_velocity) > profiler_config.max_velocity) {
                    checklist.fault = true;
                    /* FIXME start new transition to -> FAULT state and initiate appropreate operations */
                }

                /* Over current - FIXME add check if we have over-current - from where? */

                /* Over voltage - FIXME add check for over-voltage - from where? */
            }


            if (mode_selected == 0) {
                /* Select an operation mode requested from EtherCAT Master Application */
                switch (InOut.operation_mode) {
                    /* Cyclic synchronous position mode initialization */
                //FixMe: initialization should take place before we start PDO communication
                case CSP:
                    if (op_set_flag == 0) {
                        ctrl_state = i_velocity_control.check_busy();
                        if (ctrl_state == 1) {
                            i_velocity_control.disable_velocity_ctrl();
                        }
                        init_position_control(i_position_control);
                    }
                    if (i_position_control.check_busy() == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        mode_quick_flag = 10;
                        op_mode = CSP;
                        ack = 0;
                        shutdown_ack = 0;

                        update_csp_param_ecat(profiler_config, i_coe);
                        InOut.operation_mode_display = CSP;
                    }
                    break;

                    /* Cyclic synchronous velocity mode initialization */
                case CSV:   //csv mode index
                    break;

                    /* Cyclic synchronous torque mode initialization */
                case CST:
                    break;
                }
            }

            /* After operation mode is selected the loop enters a continuous operation
             * until the operation is shutdown */
            if (mode_selected == 1) {
                switch (controlword) {
                case QUICK_STOP:
                    quick_stop_steps = quick_stop_init(op_mode, actual_velocity, sensor_resolution, actual_position, profiler_config);
                    state = get_next_state(state, checklist, controlword, CTRL_QUICK_STOP_INIT);
                    /* FIXME check for update state */
                    statusword = update_statusword(state, state, ack, quick_active, shutdown_ack);
                    break;

                    /* continuous controlword */
                case SWITCH_ON: //switch on cyclic
                    if (op_mode == CSV) {
                        //ToDo: implement CSV
                    } else if (op_mode == CST) {
                        //ToDo: implement CST
                    } else if (op_mode == CSP) {
                    //printstrln("SWITCH ON: cyclic position mode");
                        target_position = get_target_position(InOut);
                        i_position_control.set_position(position_limit( (target_position) * profiler_config.polarity,
                                                        profiler_config.max_position, profiler_config.min_position));
                       // set_position_csp(profiler_config, target_position, 0, 0, 0, i_position_control);

                        //printintln(actual_position);
                        //safety_state = read_gpio_digital_input(c_gpio, 1);        // read port 1
                        //value = (port_3_value<<3 | port_2_value<<2 | port_1_value <<1| safety_state );  pack values if more than one port inputs
                    }
                    break;

                case SHUTDOWN:
                    if (op_mode == CST) {
                        //ToDo implement shutdown for CST
                    } else if (op_mode == CSV) {
                        //ToDo implement shutdown for CSV
                    } else if (op_mode == CSP) {
                        //FixMe: verify if we are doing it right
                        i_position_control.disable_position_ctrl();
                        //printstrln("CSP disabled.");
                        shutdown_ack = 1;
                        op_set_flag = 0;
                        init = 0;
                        mode_selected = 0;  // to reenable the op selection and reset the controller
                        setup_loop_flag = 0;
                    }
                    break;
                }
            }

            /* If we are in state S_QUICK_STOP_ACTIVE then we perform the quick stop steps! */
            if (state == S_QUICK_STOP_ACTIVE) {
                int ret = quick_stop_perform(quick_stop_steps, direction, profiler_config, i_position_control);
                if (ret != 0) {
                    state = get_next_state(state, checklist, 0, CTRL_QUICK_STOP_FINISHED);
                }
            }

            /* quick stop controlword routine */
            else if (mode_selected == 3) { // non interrupt
                //perform_quick_stop();

            } else if (mode_selected == 100) {
                if (mode_quick_flag == 0)
                    quick_active = 1;

                //FixMe: what is logic here? - Nothing! 100 is a reserved op mode
                switch (InOut.operation_mode) {
                case 100:
                    mode_selected = 0;
                    quick_active = 0;
                    mode_quick_flag = 1;
                    InOut.operation_mode_display = 100;
                    break;
                }
            }

            /* FIXME this timer is only called if the communication is active, BUT shouldn't this function
             * run in a specified timely manner, independentally if the communication is active or not?
             */
            t when timerafter(time + MSEC_STD) :> time;
        }
#endif
        /* wait 1 ms to respect timing */
        t when timerafter(time + MSEC_STD) :> time;

//#pragma xta endpoint "ecatloop_stop"
    }
}
