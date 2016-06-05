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

{int, int} static inline get_position_absolute(int sensor_select, interface HallInterface client ?i_hall,
                                                interface QEIInterface client ?i_qei, interface BISSInterface client ?i_biss, interface AMSInterface client ?i_ams)
{
    int actual_position;
    int direction;

    if (sensor_select == HALL_SENSOR) {
        actual_position = i_hall.get_hall_position_absolute();//get_hall_position_absolute(c_hall);
        direction = i_hall.get_hall_direction();
    } else if (sensor_select == QEI_SENSOR) { /* QEI */
        actual_position = i_qei.get_qei_position_absolute();//get_qei_position_absolute(c_qei);
        direction = i_qei.get_qei_direction();
    } else if (sensor_select == BISS_SENSOR) { /* BISS */
        { actual_position, void, void } = i_biss.get_biss_position();
        if (i_biss.get_biss_velocity() >= 0)
            direction = 1;
        else
            direction = -1;
    } else if (sensor_select == AMS_SENSOR) { /* AMS */
        { actual_position, void} = i_ams.get_ams_position();
        if (i_ams.get_ams_velocity() >= 0)
            direction = 1;
        else
            direction = -1;
    }

    return {actual_position, direction};
}

static int get_actual_velocity(int sensor_select,
                            interface HallInterface client ?i_hall,
                            interface QEIInterface client ?i_qei,
                            interface BISSInterface client ?i_biss,
                            interface AMSInterface client ?i_ams)
{
    int velocity = 0;

    if (sensor_select == HALL_SENSOR) {
        velocity = i_hall.get_hall_velocity();
    } else if (sensor_select == QEI_SENSOR){    /* QEI */
        velocity = i_qei.get_qei_velocity();
    } else if (sensor_select == BISS_SENSOR){    /* BiSS */
        velocity = i_biss.get_biss_velocity();
    } else if (sensor_select == AMS_SENSOR){    /* AMS */
        velocity = i_ams.get_ams_velocity();
    }

    return velocity;
}

static int get_sensor_resolution(int sensor_select,
        HallConfig hall_config, QEIConfig qei_params,
        BISSConfig biss_config, AMSConfig ams_config)
{
    int sensor_resolution = 0;

    if (sensor_select == HALL_SENSOR) {
        sensor_resolution = hall_config.pole_pairs * HALL_TICKS_PER_ELECTRICAL_ROTATION; /* max_ticks_per_turn; */
    } else if (sensor_select == QEI_SENSOR){    /* QEI */
        sensor_resolution = qei_params.ticks_resolution * QEI_CHANGES_PER_TICK;
    } else if (sensor_select == BISS_SENSOR){    /* BiSS */
        sensor_resolution = (1 << biss_config.singleturn_resolution);
    } else if (sensor_select == AMS_SENSOR){    /* AMS */
        sensor_resolution = (1 << ams_config.resolution_bits);
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
                printstrln("Master requests OP mode - cyclic operation is about to start.");
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

enum eDirection {
    DIRECTION_NEUTRAL = 0
    ,DIRECTION_CLK    = 1
    ,DIRECTION_CCLK   = -1
};

static int quick_stop_perform(int steps, enum eDirection direction,
                                ProfilerConfig &profiler_config,
                                interface PositionControlInterface client i_position_control)
{
    static int step = 0;

    if (step >= steps)
        return 1;

    int target_position = quick_stop_position_profile_generate(step, direction);
    i_position_control.set_position(position_limit(target_position,
            profiler_config.max_position,
            profiler_config.min_position));

    step++;

    return 0;
}

static int quick_stop_init(int op_mode,
                                int actual_velocity,
                                int sensor_resolution,
                                int actual_position,
                                ProfilerConfig &profiler_config)
{

    if (op_mode == OPMODE_CST || op_mode == OPMODE_CSV) {
        /* TODO implement quick stop profile */
    }

    /* FIXME maybe get the velocity here directly? */
    if (actual_velocity < 0) {
        actual_velocity = -actual_velocity;
    }

    int steps = 0;
    int deceleration = profiler_config.max_deceleration;
    /* WTF? WTF? WTF? */
    //if (actual_velocity >= 500)
    {
        steps = init_quick_stop_position_profile(
                (actual_velocity * sensor_resolution) / 60,
                actual_position,
                (deceleration * sensor_resolution) / 60);
    }

    return steps;
}

static void inline update_configuration(
        client interface i_coe_communication      i_coe,
        interface MotorcontrolInterface client    i_commutation,
        interface HallInterface client            ?i_hall,
        interface QEIInterface client             ?i_qei,
        interface BISSInterface client            ?i_biss,
        interface AMSInterface client             ?i_ams,
        interface GPIOInterface client            ?i_gpio,
        interface TorqueControlInterface client   ?i_torque_control,
        interface VelocityControlInterface client i_velocity_control,
        interface PositionControlInterface client i_position_control,
        HallConfig            &hall_config,
        QEIConfig             &qei_params,
        AMSConfig             &ams_config,
        BISSConfig            &biss_config,
        ControlConfig         &torque_ctrl_params,
        ControlConfig         &velocity_ctrl_params,
        ControlConfig         &position_ctrl_params,
        MotorcontrolConfig    &commutation_params,
        MotorcontrolConfig    &motorcontrol_config,
        ProfilerConfig        &profiler_config,
        int &sensor_select,
        int &limit_switch_type,
        int &polarity,
        int &sensor_resolution,
        int &nominal_speed,
        int &homing_method)
{
            /* update structures */
            cm_sync_config_hall(i_coe, i_hall, hall_config);
            cm_sync_config_qei(i_coe, i_qei, qei_params);
            cm_sync_config_ams(i_coe, i_ams, ams_config);
            cm_sync_config_biss(i_coe, i_biss, biss_config);

            cm_sync_config_torque_control(i_coe, i_torque_control, torque_ctrl_params);
            cm_sync_config_velocity_control(i_coe, i_velocity_control, velocity_ctrl_params);
            cm_sync_config_position_control(i_coe, i_position_control, position_ctrl_params);

            cm_sync_config_profiler(i_coe, profiler_config);

            /* FIXME commutation_params and motorcontrol_config are similar but not the same */
            cm_sync_config_motor_control(i_coe, i_commutation, commutation_params);
            cm_sync_config_motor_commutation(i_coe, motorcontrol_config);

            /* Update values with current configuration */
            polarity = profiler_config.polarity;
            /* FIXME use cm_sync_config_{biss,ams}() */
            biss_config.pole_pairs = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);
            ams_config.pole_pairs  = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);

            nominal_speed = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 4);
            limit_switch_type = i_coe.get_object_value(LIMIT_SWITCH_TYPE, 0);
            homing_method = i_coe.get_object_value(CIA402_HOMING_METHOD, 0);

            /* FIXME this is weired, 3 === 2? is this python? */
            sensor_select = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
            if(sensor_select == 2 || sensor_select == 3)
                sensor_select = 2; //qei

            sensor_resolution = get_sensor_resolution(sensor_select, hall_config, qei_params, biss_config, ams_config);

            i_velocity_control.set_velocity_sensor(sensor_select);
            i_position_control.set_position_sensor(sensor_select);

            /* Configuration of GPIO Digital ports for limit switches */
            if (!isnull(i_gpio)) {
                i_gpio.config_dio_input(0, SWITCH_INPUT_TYPE, limit_switch_type);
                i_gpio.config_dio_input(1, SWITCH_INPUT_TYPE, limit_switch_type);
                i_gpio.config_dio_done();//end_config_gpio(c_gpio);
            }
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
                            interface MotorcontrolInterface client i_commutation,
                            interface HallInterface client ?i_hall,
                            interface QEIInterface client ?i_qei,
                            interface BISSInterface client ?i_biss,
                            interface AMSInterface client ?i_ams,
                            interface GPIOInterface client ?i_gpio,
                            interface TorqueControlInterface client ?i_torque_control,
                            interface VelocityControlInterface client i_velocity_control,
                            interface PositionControlInterface client i_position_control)
{
    int mode = 3; /* only used for update_checklist to verify if position_control is initialized (use 1 for torque and 2 for velocity) */
    int quick_stop_steps = 0;

    //int target_torque = 0; /* used for CST */
    int actual_torque = 0;
    //int target_velocity = 0; /* used for CSV */
    int actual_velocity = 0;
    int target_position = 0;
    int actual_position = 0;

    enum eDirection direction = DIRECTION_NEUTRAL;

#if 0 /* collection of currently unused variables */
    int position_ramp = 0;
    int prev_position = 0;

    int velocity_ramp = 0;
    int prev_velocity = 0;

    int torque_ramp = 0;
    int prev_torque = 0;

    int status=0;
    int tmp=0;

    int home_velocity = 0;
    int home_acceleration = 0;

    int limit_switch = -1;      // positive negative limit switches
    int reset_counter = 0;

    int home_state = 0;
    int safety_state = 0;
    int capture_position = 0;
    int current_position = 0;
    int home_offset = 0;
    int homing_done = 0;
    int end_state = 0;
#endif

    int nominal_speed;
    timer t;

    int init = 0;
    int op_set_flag = 0;
    int op_mode = 0, op_mode_old = 0, op_mode_commanded_old = 0;

    int opmode = 0;
    int opmode_request = 0;

    ControlConfig position_ctrl_params;
    ControlConfig torque_ctrl_params;
    ControlConfig velocity_ctrl_params;

    QEIConfig qei_params;
    HallConfig hall_config;
    BISSConfig biss_config;
    AMSConfig ams_config;

    MotorcontrolConfig commutation_params;
    ctrl_proto_values_t InOut;

    int setup_loop_flag = 0;

    int ack = 0;
    int quick_active = 0;
    int mode_quick_flag = 0;
    int shutdown_ack = 0;
    int sensor_select = -1;

    int communication_active = 0;
    unsigned int c_time;
    int comm_inactive_flag = 0;
    int inactive_timeout_flag = 0;

    unsigned int time;
    enum e_States state     = S_NOT_READY_TO_SWITCH_ON;
    enum e_States state_old = state;

    uint16_t statusword = update_statusword(0, state, 0, 0, 0);
    uint16_t statusword_old = 0;
    int controlword = 0, controlword_old = 0;

    //int torque_offstate = 0;
    int mode_selected = 0; /* valid values: { 0, 1, 3, 100 } - WTF? */
    check_list checklist;

    int ctrl_state;
    int limit_switch_type;
    int homing_method;
    int polarity = 1;

    checklist   = init_checklist();
    InOut       = init_ctrl_proto();
    int sensor_resolution = 0;

    if (!isnull(i_hall))
        hall_config = i_hall.get_hall_config();
    if (!isnull(i_qei))
        qei_params = i_qei.get_qei_config();
    if (!isnull(i_biss))
        biss_config = i_biss.get_biss_config();
    if (!isnull(i_ams))
            ams_config = i_ams.get_ams_config();
    velocity_ctrl_params = i_velocity_control.get_velocity_control_config();
    MotorcontrolConfig motorcontrol_config = i_commutation.get_config();

 //ToDo parameters to be updated over ethercat:
 // hall_config
 // qei_params
 // biss_config
 // ams_config
 // velocity_ctrl_params
 // position_ctrl_params
 // torque_ctrl_params
 // motorcontrol_config
 // profiler_config
 // commutation_params
 //
 // sensor_select
 // nominal_speed
 // homing_method, limit_switch_type
 // polarity

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
                printstrln("Master requests OP mode - cyclic operation is about to start.");
                read_configuration = 1;
                break;
            default:
                break;
        }

        /* FIXME: When to update configuration values from OD? only do this in state "Ready to Switch on"? */
        if (read_configuration) {
            update_configuration(i_coe, i_commutation,
                    i_hall, i_qei, i_biss, i_ams, i_gpio,
                    i_torque_control, i_velocity_control, i_position_control,
                    hall_config, qei_params, ams_config, biss_config,
                    torque_ctrl_params, velocity_ctrl_params, position_ctrl_params,
                     commutation_params, motorcontrol_config, profiler_config,
                    sensor_select, limit_switch_type, polarity, sensor_resolution, nominal_speed, homing_method
                    );

            read_configuration = 0;
            i_coe.configuration_done();
        }

        /*
         *  local state variables
         */
        statusword     = update_statusword(statusword, state, 0, 0, 0); /* FiXME update ack, q_active and shutdown_ack */
        controlword    = get_controlword(InOut);
        opmode_request = get_opmode(InOut);

        actual_velocity = get_actual_velocity(sensor_select, i_hall, i_qei, i_biss, i_ams);

        { actual_position, direction } = get_position_absolute(sensor_select, i_hall, i_qei, i_biss, i_ams);

#if 0
        actual_torque = i_position_control.get_torque(); /* FIXME expected future implementation! */
#else
        if (isnull(i_torque_control))
            actual_torque = i_commutation.get_torque_actual();
        else
            actual_torque = i_torque_control.get_torque();
#endif


        /*
         *  update values to send
         */
        send_statusword(statusword, InOut);
        send_opmode_display(opmode, InOut);
        send_actual_velocity(actual_velocity, InOut);
        send_actual_torque(actual_torque, InOut );
        send_actual_position(actual_position * polarity, InOut);


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
                    t :> c_time;
                    t when timerafter(c_time + 2*SEC_STD) :> c_time;
                    inactive_timeout_flag = 1;
                }
            }
        }

        update_checklist(checklist, mode, i_commutation, i_hall, i_qei, i_biss, i_ams, null,
                i_torque_control, i_velocity_control, i_position_control);

        /*
         * new, perform actions according to state
         */

        switch (state) {
        case S_NOT_READY_TO_SWITCH_ON:
            printstrln("S_NOT_READY_TO_SWITCH_ON");
            /* internal stuff, automatic transition (1) to next state */
            state = get_next_state(state, checklist, 0, 0);
            break;

        case S_SWITCH_ON_DISABLED:
            printstrln("S_SWITCH_ON_DISABLED");
            if (opmode_request != OPMODE_CSP) { /* FIXME check for supported opmodes if applicable */
                opmode = OPMODE_NONE;
            } else {
                opmode = opmode_request;
            }

            /* communication active, idle no motor control; read opmode from PDO and set control accordingly */
            state = get_next_state(state, checklist, controlword, 0);
            break;

        case S_READY_TO_SWITCH_ON:
            printstrln("S_READY_TO_SWITCH_ON");
            /* nothing special, transition form local (when?) or control device */
            state = get_next_state(state, checklist, controlword, 0);
            break;

        case S_SWITCH_ON:
            printstrln("S_SWITCH_ON");
            /* high power shall be switched on  */
            state = get_next_state(state, checklist, controlword, 0);
            break;

        case S_OPERATION_ENABLE:
            printstrln("S_OPERATION_ENABLE");
            /* drive function shall be enabled and internal set-points are cleared */
            /* FIXME add motor control call(s) */

            state = get_next_state(state, checklist, controlword, 0);
            /* update motor/control parameters and let the motor turn */
            if (state == S_QUICK_STOP_ACTIVE) {
                 quick_stop_steps =quick_stop_init(op_mode, actual_velocity, sensor_resolution, actual_position, profiler_config); // <- can be done in the calling command
            }
            break;

        case S_QUICK_STOP_ACTIVE:
            printstrln("S_QUICK_STOP_ACTIVE");
            /* quick stop function shall be started and running */
            int ret = quick_stop_perform(quick_stop_steps, direction, profiler_config, i_position_control);
            if (ret != 0) {
                state = get_next_state(state, checklist, 0, CTRL_QUICK_STOP_FINISHED);
                quick_stop_steps = 0;
            }
            break;

        case S_FAULT_REACTION_ACTIVE:
            printstrln("S_FAULT_REACTION_ACTIVE");
            /* a fault is detected, perform fault recovery actions like a quick_stop */
            if (quick_stop_steps == 0) {
                quick_stop_steps = quick_stop_init(op_mode, actual_velocity, sensor_resolution, actual_position, profiler_config);
            }

            if (quick_stop_perform(quick_stop_steps, direction, profiler_config, i_position_control) == 1) {
                state = get_next_state(state, checklist, 0, CTRL_FAULT_REACTION_FINISHED);
            }
            break;

        case S_FAULT:
            printstrln("S_FAULT");
            /* wait until fault reset from the control device appears */
            state = get_next_state(state, checklist, InOut.control_word, 0);
            break;

        default: /* should never happen! */
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
