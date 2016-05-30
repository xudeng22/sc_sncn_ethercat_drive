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

//#pragma xta command "analyze loop ecatloop"
//#pragma xta command "set required - 1.0 ms"

void ethercat_drive_service(ProfilerConfig &profiler_config,
                            chanend pdo_out, chanend pdo_in,
                            client interface i_coe_communication i_coe,
                            interface MotorcontrolInterface client i_commutation,
                            interface HallInterface client ?i_hall,
                            interface QEIInterface client ?i_qei,
                            interface BISSInterface client ?i_biss,
                            interface AMSInterface client ?i_ams,
                            interface GPIOInterface client ?i_gpio,
                            interface ADCInterface client i_adc,
                            interface TorqueControlInterface client ?i_torque_control,
                            interface TorqueControlInterface client i_torque_control,
                            interface VelocityControlInterface client i_velocity_control,
                            interface PositionControlInterface client i_position_control)
{
    int i = 0;
    int mode = 40;
    int steps = 0;

    int target_torque = 0;
    int actual_torque = 0;
    int target_velocity = 0;
    int actual_velocity = 0;
    int target_position = 0;
    int actual_position = 0;

    int direction = 0;

    int position_ramp = 0;
    int prev_position = 0;

    int velocity_ramp = 0;
    int prev_velocity = 0;

    int torque_ramp = 0;
    int prev_torque = 0;

    int nominal_speed;
    timer t;

    int init = 0;
    int op_set_flag = 0;
    int op_mode = 0, op_mode_old = 0, op_mode_commanded_old = 0;

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
    int sense;

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
    int state, state_old;
    int statusword = 0, statusword_old = 0;
    int controlword = 0, controlword_old = 0;

    int status=0;
    int tmp=0;

    //int torque_offstate = 0;
    int mode_selected = 0;
    check_list checklist;

    int home_velocity = 0;
    int home_acceleration = 0;

    int limit_switch = -1;      // positive negative limit switches
    int reset_counter = 0;

    int home_state = 0;
    int safety_state = 0;
    int capture_position = 0;
    int current_position = 0;
    int home_offset = 0;
    int end_state = 0;
    int ctrl_state;
    int limit_switch_type;
    int homing_method;
    int polarity = 1;
    int homing_done = 0;
    state       = init_state(); // init state
    checklist   = init_checklist();
    InOut       = init_ctrl_proto();

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

        if (read_configuration) {
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

            i_velocity_control.set_velocity_sensor(sensor_select);
            i_position_control.set_position_sensor(sensor_select);

            /* Configuration of GPIO Digital ports for limit switches */
            if (!isnull(i_gpio)) {
                i_gpio.config_dio_input(0, SWITCH_INPUT_TYPE, limit_switch_type);
                i_gpio.config_dio_input(1, SWITCH_INPUT_TYPE, limit_switch_type);
                i_gpio.config_dio_done();//end_config_gpio(c_gpio);
            }

            read_configuration = 0;
            i_coe.configuration_done();
        }

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
                    t :> c_time;
                    t when timerafter(c_time + 2*SEC_STD) :> c_time;
                    inactive_timeout_flag = 1;
                }
            }
        } else if (communication_active >= 1) {
            comm_inactive_flag = 0;
            inactive_timeout_flag = 0;
        }

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


            /* quick stop for torque mode */
            if (op_mode == CST)
            {
                //ToDo: implement quick stop for CST
            }

            /* quick stop for velocity mode */
            if (op_mode == CSV) {
                //ToDo: implement quick stop for CSV
            }

            /* quick stop for position mode */
            else if (op_mode == CSP) {
                //printstrln("We are in OP mode CSP");
                if (sensor_select == HALL_SENSOR && !isnull(i_hall))
                    actual_velocity = i_hall.get_hall_velocity();
                else if (sensor_select == BISS_SENSOR && !isnull(i_biss))
                    actual_velocity = i_biss.get_biss_velocity();
                else if (sensor_select == QEI_SENSOR && !isnull(i_qei))
                    actual_velocity = i_qei.get_qei_velocity();
                else if (sensor_select == AMS_SENSOR && !isnull(i_ams))
                    actual_velocity = i_ams.get_ams_velocity();
                actual_position = i_position_control.get_position();

                int deceleration;
                int max_position_limit;
                int min_position_limit;
                //int polarity;
                deceleration = profiler_config.max_acceleration;
                max_position_limit = profiler_config.max_position;
                min_position_limit = profiler_config.min_position;
                //polarity = cyclic_sync_position_config.velocity_config.polarity;

                if (actual_velocity>=500 || actual_velocity<=-500) {
                    if (actual_velocity < 0) {
                        actual_velocity = -actual_velocity;
                    }

                    int sensor_ticks;
                    if (sensor_select == HALL_SENSOR) {
                        sensor_ticks = hall_config.pole_pairs * HALL_TICKS_PER_ELECTRICAL_ROTATION;//max_ticks_per_turn;
                    } else if (sensor_select == QEI_SENSOR){    /* QEI */
                        sensor_ticks = qei_params.ticks_resolution * QEI_CHANGES_PER_TICK;
                    } else if (sensor_select == BISS_SENSOR){    /* BISS */
                        sensor_ticks = (1 << biss_config.singleturn_resolution);
                    } else if (sensor_select == AMS_SENSOR){    /* AMS */
                        sensor_ticks = (1 << ams_config.resolution_bits);
                    }

                    steps = init_quick_stop_position_profile(
                        (actual_velocity * sensor_ticks) / 60,
                        actual_position,
                        (deceleration * sensor_ticks) / 60);

                    mode_selected = 3; // non interruptible mode
                    mode_quick_flag = 0;
                }

                {actual_position, sense} = get_position_absolute(sensor_select, i_hall, i_qei, i_biss, i_ams);

                t :> c_time;
                for (int i=0; i<steps; i++) {
                    target_position = quick_stop_position_profile_generate(i, sense);
                    i_position_control.set_position(position_limit( target_position, max_position_limit,
                                                                    min_position_limit));

                    //send_actual_position(actual_position * polarity, InOut);
                    t when timerafter(c_time + MSEC_STD) :> c_time;
                }
            }
            mode_selected = 0;
            setup_loop_flag = 0;
            op_set_flag = 0;
            op_mode = 256;      /* FIXME: why 256? */
        }


        /*********************************************************************************
         * EtherCAT communication is Active
         *********************************************************************************/
        if (comm_inactive_flag == 0) {
            //printstrln("EtherCAT comm active");
            /* Read controlword from the received from EtherCAT Master application */
            controlword = InOut.control_word;

            /* Check states of the motor drive, sensor drive and control servers */
            update_checklist(checklist, mode, i_commutation, i_hall, i_qei, i_biss, i_ams, null,
                             i_torque_control, i_velocity_control, i_position_control);

            /* Update state machine */
            state = get_next_state(state, checklist, controlword);

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
            /* Read Position Sensor */
            if (sensor_select == HALL_SENSOR && !isnull(i_hall)) {
                actual_velocity = i_hall.get_hall_velocity();
            } else if (sensor_select == QEI_SENSOR && !isnull(i_qei)) {
                actual_velocity = i_qei.get_qei_velocity();
               //printintln(actual_velocity);
            } else if (sensor_select == BISS_SENSOR && !isnull(i_biss)) {
                actual_velocity = i_biss.get_biss_velocity();
            } else if (sensor_select == AMS_SENSOR && !isnull(i_ams)) {
                actual_velocity = i_ams.get_ams_velocity();
            }
            send_actual_velocity(actual_velocity * polarity, InOut);

            /* ################################
             * Error Handling
             * ################################ */

            if (!checklist.fault)
            {
                /* Temperature */
                if (i_adc.get_temperature() > TEMP_THRESHOLD) {
                    checklist.fault = true;

                }

                /* Speed */

                /* Over current */

                /* Over voltage */
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
                    if (op_mode == CST) {
                        //ToDo: implement quickstop for CST
                    }
                    else if (op_mode == CSV) {
                        //ToDo: implement quickstop for CSV
                    } else if (op_mode == CSP) {
                        /* FIXME WTF? why again reading the config? -> remove */
                        if (sensor_select == HALL_SENSOR && !isnull(i_hall))
                            actual_velocity = i_hall.get_hall_velocity();
                        else if (sensor_select == BISS_SENSOR && !isnull(i_biss))
                            actual_velocity = i_biss.get_biss_velocity();
                        else if (sensor_select == AMS_SENSOR && !isnull(i_ams))
                            actual_velocity = i_ams.get_ams_velocity();
                        else if (sensor_select == QEI_SENSOR && !isnull(i_qei))
                            actual_velocity = i_qei.get_qei_velocity();

                        actual_position = i_position_control.get_position();

                        if (actual_velocity>=500 || actual_velocity<=-500) {
                            if (actual_velocity < 0) {
                                actual_velocity = -actual_velocity;
                            }

                            int deceleration;
                            if (op_mode == CSP) {
                                deceleration = profiler_config.max_acceleration;
                            } else { /* op_ode == PP */
                                deceleration = profiler_config.max_deceleration;
                            }

                            int sensor_ticks;
                            if (sensor_select == HALL_SENSOR) {
                                sensor_ticks = hall_config.pole_pairs * HALL_TICKS_PER_ELECTRICAL_ROTATION;//max_ticks_per_turn;
                            } else if (sensor_select == QEI_SENSOR){    /* QEI */
                                sensor_ticks = qei_params.ticks_resolution * QEI_CHANGES_PER_TICK;
                            } else if (sensor_select == BISS_SENSOR){    /* BiSS */
                                sensor_ticks = (1 << biss_config.singleturn_resolution);
                            } else if (sensor_select == AMS_SENSOR){    /* AMS */
                                sensor_ticks = (1 << ams_config.resolution_bits);
                            }

                            steps = init_quick_stop_position_profile(
                                (actual_velocity * sensor_ticks) / 60,
                                actual_position,
                                (deceleration * sensor_ticks) / 60);

                            i = 0;
                            mode_selected = 3; // non interruptible mode
                            mode_quick_flag = 0;
                        } else {
                            mode_selected = 100;
                            op_set_flag = 0;
                            init = 0;
                            mode_quick_flag = 0;
                        }
                    }
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

                        actual_position = i_position_control.get_position() * profiler_config.polarity;//cyclic_sync_position_config.velocity_config.polarity;
                        send_actual_position(actual_position, InOut);
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

            /* quick stop controlword routine */
            else if (mode_selected == 3) { // non interrupt
                if (op_mode == CST) {
                    //ToDO: implement CST quick stop execution routine here
                } else if (op_mode == CSV) {
                    //ToDO: implement CSV quick stop execution routine here
                } else if (op_mode == CSP) {
                    {actual_position, sense} = get_position_absolute(sensor_select, i_hall, i_qei, i_biss, i_ams);

                    t :> c_time;
                    while (i < steps) {
                        target_position = quick_stop_position_profile_generate(i, sense);
                        if (op_mode == CSP) {
                            i_position_control.set_position(position_limit(target_position,
                                                                    profiler_config.max_position,
                                                                    profiler_config.min_position));
                                                                 //  cyclic_sync_position_config.max_position_limit,
                                                                 //  cyclic_sync_position_config.min_position_limit));
                        } else if (op_mode == PP) {
                            i_position_control.set_position(position_limit(target_position,
                                                            profiler_config.max_position,
                                                            profiler_config.min_position));
                        }
                        t when timerafter(c_time + MSEC_STD) :> c_time;
                        i++;
                    }

                    if (i == steps) {
                        t when timerafter(c_time + 100*MSEC_STD) :> c_time;
                    }
                    if (i >= steps) {
                        if (sensor_select == HALL_SENSOR && !isnull(i_hall))
                            actual_velocity = i_hall.get_hall_velocity();
                        else if (sensor_select == BISS_SENSOR && !isnull(i_biss))
                            actual_velocity = i_biss.get_biss_velocity();
                        else if (sensor_select == QEI_SENSOR && !isnull(i_qei))
                            actual_velocity = i_qei.get_qei_velocity();
                        else if (sensor_select == AMS_SENSOR && !isnull(i_ams))
                            actual_velocity = i_ams.get_ams_velocity();
                        if (actual_velocity < 50 || actual_velocity > -50) {
                            mode_selected = 100;
                            op_set_flag = 0;
                            init = 0;
                        }
                    }
                }
            } else if (mode_selected == 100) {
                if (mode_quick_flag == 0)
                    quick_active = 1;

                if (op_mode == CST) {
                    //Here was just sending toque feedback, but why not always?
                } else if (op_mode == CSV) {
                    //Here was just sending velocity feedback, but why not always?
                }
                //FixMe: what is logic here?
                switch (InOut.operation_mode) {
                case 100:
                    mode_selected = 0;
                    quick_active = 0;
                    mode_quick_flag = 1;
                    InOut.operation_mode_display = 100;
                    break;
                }
            }

            /* Read Torque and Position */
            {actual_position, direction} = get_position_absolute(sensor_select, i_hall, i_qei, i_biss, i_ams);

            if(motorcontrol_config.commutation_method == FOC){
                send_actual_torque( i_commutation.get_torque_actual(), InOut );
            } else {
                if(!isnull(i_torque_control))
                    send_actual_torque( i_torque_control.get_torque() * polarity, InOut );
            }
            //send_actual_torque( get_torque(c_torque_ctrl) * polarity, InOut );
            send_actual_position(actual_position * polarity, InOut);
            t when timerafter(time + MSEC_STD) :> time;
        }

//#pragma xta endpoint "ecatloop_stop"
    }
}
