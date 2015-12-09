/**
 * @file ecat_motor_drive.xc
 * @brief Ethercat Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_drive_service.h>
#include <refclk.h>
#include <comm.h>
#include <statemachine.h>
#include <state_modes.h>
#include <profile.h>



{int, int} static inline get_position_absolute(int sensor_select, interface HallInterface client i_hall,
                                                interface QEIInterface client i_qei)
{
    int actual_position;
    int direction;

    if (sensor_select == HALL) {
        {actual_position, direction} = i_hall.get_hall_position_absolute();//get_hall_position_absolute(c_hall);
    } else { /* QEI */
        {actual_position, direction} = i_qei.get_qei_position_absolute();//get_qei_position_absolute(c_qei);
    }

    return {actual_position, direction};
}

//#pragma xta command "analyze loop ecatloop"
//#pragma xta command "set required - 1.0 ms"

void ethercat_drive_service(CyclicSyncPositionConfig &cyclic_sync_position_config,
                            CyclicSyncVelocityConfig &cyclic_sync_velocity_config,
                            CyclicSyncTorqueConfig &cyclic_sync_torque_config,
                            ProfilePositionConfig &profile_position_config,
                            ProfileVelocityConfig &profile_velocity_config,
                            ProfileTorqueConfig &profile_torque_config,
                            chanend pdo_out, chanend pdo_in, chanend coe_out,
                            interface MotorcontrolInterface client i_commutation,
                            interface HallInterface client i_hall,
                            interface QEIInterface client i_qei,
                            interface GPIOInterface client i_gpio,
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
    int op_mode = 0;

    ControlConfig position_ctrl_params;
    ControlConfig torque_ctrl_params;
    ControlConfig velocity_ctrl_params;

    QEIConfig qei_params;
    HallConfig hall_config;

    MotorcontrolConfig commutation_params;
    ctrl_proto_values_t InOut;

    int setup_loop_flag = 0;
    int sense;

    int ack = 0;
    int quick_active = 0;
    int mode_quick_flag = 0;
    int shutdown_ack = 0;
    int sensor_select = 4;

    int direction;

    int communication_active = 0;
    unsigned int c_time;
    int comm_inactive_flag = 0;
    int inactive_timeout_flag = 0;

    unsigned int time;
    int state;
    int statusword;
    int controlword;

    int status=0;
    int tmp=0;

    int torque_offstate = 0;
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

    //init_cst_param(cyclic_sync_torque_config);
    //init_csv_param(cyclic_sync_velocity_config);
    //init_csp_param(cyclic_sync_position_config);
    hall_config = i_hall.getHallConfig();
    //init_pp_params(profile_position_config);
    //init_pv_params(profile_velocity_config);
    //init_pt_params(profile_torque_config);
    qei_params = i_qei.getQEIConfig();
    velocity_ctrl_params = i_velocity_control.get_velocity_control_config();

    t :> time;
    while (1) {
//#pragma xta endpoint "ecatloop"
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

            /* quick stop for torque mode */
            if (op_mode == CST || op_mode == TQ)
            {
                actual_torque = i_torque_control.get_torque();
                steps = init_linear_profile(0, actual_torque, profile_torque_config.profile_slope,
                                            profile_torque_config.profile_slope);
                t :> c_time;
                for (int i=0; i<steps; i++) {
                    target_torque = linear_profile_generate(i);
                    i_torque_control.set_torque(target_torque);
                    actual_torque = i_torque_control.get_torque();
                    send_actual_torque(actual_torque * cyclic_sync_torque_config.polarity, InOut);

                    t when timerafter(c_time + MSEC_STD) :> c_time;
                }
            }

            /* quick stop for velocity mode */
            if (op_mode == CSV || op_mode == PV) {
                actual_velocity = i_velocity_control.get_velocity();

                int deceleration;
                int max_velocity;
                int polarity;
                if (op_mode == CSV) {
                    deceleration = cyclic_sync_velocity_config.max_acceleration;
                    max_velocity = cyclic_sync_velocity_config.max_motor_speed;
                    polarity = cyclic_sync_velocity_config.polarity;
                } else {        /* op_mode == PV */
                    deceleration = profile_velocity_config.quick_stop_deceleration;
                    max_velocity = profile_velocity_config.max_profile_velocity;
                    polarity = profile_velocity_config.polarity;
                }
                steps = init_quick_stop_velocity_profile(actual_velocity, deceleration);

                t :> c_time;
                for (int i=0; i<steps; i++) {
                    target_velocity = quick_stop_velocity_profile_generate(i);

                    i_velocity_control.set_velocity(max_speed_limit(target_velocity, max_velocity));

                    actual_velocity = i_velocity_control.get_velocity();
                    send_actual_velocity(actual_velocity * polarity, InOut);

                    t when timerafter(c_time + MSEC_STD) :> c_time;
                }
            }

            /* quick stop for position mode */
            else if (op_mode == CSP || op_mode == PP) {
                actual_velocity = i_hall.get_hall_velocity();
                actual_position = i_position_control.get_position();

                int deceleration;
                int max_position_limit;
                int min_position_limit;
                //int polarity;
                if (op_mode == CSP) {
                    deceleration = cyclic_sync_position_config.velocity_config.max_acceleration;
                    max_position_limit = cyclic_sync_position_config.max_position_limit;
                    min_position_limit = cyclic_sync_position_config.min_position_limit;
                    //polarity = cyclic_sync_position_config.velocity_config.polarity;
                } else {    /* op_mode == PP */
                    deceleration = profile_position_config.velocity_config.quick_stop_deceleration;
                    max_position_limit = profile_position_config.software_position_limit_max;
                    min_position_limit = profile_position_config.software_position_limit_min;
                    //polarity = profile_position_config.velocity_config.polarity;
                }

                if (actual_velocity>=500 || actual_velocity<=-500) {
                    if (actual_velocity < 0) {
                        actual_velocity = -actual_velocity;
                    }

                    int sensor_ticks;
                    if (sensor_select == HALL) {
                        sensor_ticks = hall_config.max_ticks_per_turn;
                    } else {    /* QEI */
                        sensor_ticks = qei_params.real_counts;
                    }

                    steps = init_quick_stop_position_profile(
                        (actual_velocity * sensor_ticks) / 60,
                        actual_position,
                        (deceleration * sensor_ticks) / 60);

                    mode_selected = 3; // non interruptible mode
                    mode_quick_flag = 0;
                }

                {actual_position, sense} = get_position_absolute(sensor_select, i_hall, i_qei);

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
         * Ethercat communication is Active
         *********************************************************************************/
        if (comm_inactive_flag == 0) {
            /* Read controlword from the received from Ethercat Master application */
            controlword = InOut.control_word;

            /* Check states of the motor drive, sensor drive and control servers */
            update_checklist(checklist, mode, i_commutation, i_hall, i_qei, null,
                             i_torque_control, i_velocity_control, i_position_control);

            /* Update state machine */
            state = get_next_state(state, checklist, controlword);

            /* Update statusword sent to the Ethercat Master Application */
            statusword = update_statusword(statusword, state, ack, quick_active, shutdown_ack);
            InOut.status_word = statusword;

            if (setup_loop_flag == 0) {
                if (controlword == 6) {
                    coe_out <: CAN_GET_OBJECT;
                    coe_out <: CAN_OBJ_ADR(0x60b0, 0);
                    coe_out :> tmp;
                    status = (unsigned char)(tmp&0xff);
                    if (status == 0) {
                        coe_out <: CAN_SET_OBJECT;
                        coe_out <: CAN_OBJ_ADR(0x60b0, 0);
                        status = 0xaf;
                        coe_out <: (unsigned)status;
                        coe_out :> tmp;
                        if (tmp == status) {
                            t :> c_time;
                            t when timerafter(c_time + 500*MSEC_STD) :> c_time;
                            InOut.operation_mode_display = 105;

                        }
                    } else if (status == 0xaf) {
                        InOut.operation_mode_display = 105;
                    }
                }
                /* Read Motor Configuration sent from the Ethercat Master Application */
                if (controlword == 5) {
                    update_commutation_param_ecat(commutation_params, coe_out);
                    sensor_select = sensor_select_sdo(coe_out);

                    //if (sensor_select == HALL)  /* FIXME (?)
                    //{
                    update_hall_config_ecat(hall_config, coe_out);
                    //}
                    if (sensor_select >= QEI) { /* FIXME QEI with Index defined as 2 and without Index as 3  */
                        update_qei_param_ecat(qei_params, coe_out);
                    }
                    nominal_speed = speed_sdo_update(coe_out);
                    update_pp_param_ecat(profile_position_config, coe_out);
                    polarity = profile_position_config.velocity_config.polarity;
                    qei_params.poles = hall_config.pole_pairs;

                    //config_sdo_handler(coe_out);
                    {homing_method, limit_switch_type} = homing_sdo_update(coe_out);
                    if (homing_method == HOMING_NEGATIVE_SWITCH)
                        limit_switch = -1;
                    else if (homing_method == HOMING_POSITIVE_SWITCH)
                        limit_switch = 1;

                    /* Configuration of GPIO Digital ports follows here */
                    i_gpio.config_dio_input(0, SWITCH_INPUT_TYPE, limit_switch_type);
                    i_gpio.config_dio_input(1, SWITCH_INPUT_TYPE, limit_switch_type);
                    i_gpio.config_dio_done();//end_config_gpio(c_gpio);
                    i_hall.setHallConfig(hall_config); //set_hall_conifg_ecat(c_hall, hall_config);
                    if (homing_done == 0)
                        i_qei.setQEIConfig(qei_params);
                    i_commutation.setAllParameters(hall_config, qei_params,
                                               commutation_params, nominal_speed);

                    setup_loop_flag = 1;
                    op_set_flag = 0;
                }
            }
            /* Read Position Sensor */
            if (sensor_select == HALL) {
                actual_velocity = i_hall.get_hall_velocity();
            } else if (sensor_select == QEI) {
                actual_velocity = i_qei.get_qei_velocity();
            }
            send_actual_velocity(actual_velocity * polarity, InOut);

            if (mode_selected == 0) {
                /* Select an operation mode requested from Ethercat Master Application */
                switch (InOut.operation_mode) {
                    /* Homing Mode initialization */
                case HM:
                    if (op_set_flag == 0) {
                        ctrl_state = i_torque_control.check_busy();
                        if (ctrl_state == 1)
                            i_torque_control.shutdown_torque_ctrl();
                        init = init_velocity_control(i_velocity_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        op_mode = HM;
                        steps = 0;
                        mode_quick_flag = 10;
                        ack = 0;
                        shutdown_ack = 0;

                        i_velocity_control.set_velocity_sensor(QEI); //QEI
                        InOut.operation_mode_display = HM;
                    }
                    break;

                    /* Profile Position Mode initialization */
                case PP:
                    if (op_set_flag == 0) {
                        update_position_ctrl_param_ecat(position_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_position_control.set_position_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_position_control.set_position_ctrl_qei_param(qei_params);
                        }
                        i_position_control.set_position_ctrl_param(position_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_velocity_control.check_velocity_ctrl_state();
                        if (ctrl_state == 1)
                            i_velocity_control.shutdown_velocity_ctrl();
                        init = init_position_control(i_position_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        op_mode = PP;
                        steps = 0;
                        mode_quick_flag = 10;
                        ack = 0;
                        shutdown_ack = 0;

                        update_pp_param_ecat(profile_position_config, coe_out);
                        init_position_profile_limits(profile_position_config.max_acceleration,
                                                     profile_position_config.velocity_config.max_profile_velocity,
                                                     qei_params, hall_config, sensor_select,
                                                     profile_position_config.software_position_limit_max,
                                                     profile_position_config.software_position_limit_min);
                        InOut.operation_mode_display = PP;
                    }
                    break;

                    /* Profile Torque Mode initialization */
                case TQ:
                    if (op_set_flag == 0) {
                        update_torque_ctrl_param_ecat(torque_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_torque_control.set_torque_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_torque_control.set_torque_ctrl_qei_param(qei_params);
                        }

                        i_torque_control.set_torque_ctrl_param(torque_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_position_control.check_busy();
                        if (ctrl_state == 1)
                            i_position_control.shutdown_position_ctrl();
                        init = init_torque_control(i_torque_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        op_mode = TQ;
                        steps = 0;
                        mode_quick_flag = 10;
                        ack = 0;
                        shutdown_ack = 0;

                        update_cst_param_ecat(cyclic_sync_torque_config, coe_out);
                        update_pt_param_ecat(profile_torque_config, coe_out);
                        torque_offstate = (cyclic_sync_torque_config.max_torque * 15) /
                            (cyclic_sync_torque_config.nominal_current * 100 * cyclic_sync_torque_config.motor_torque_constant);

                        init_linear_profile_limits(cyclic_sync_torque_config.max_torque,cyclic_sync_torque_config.polarity);

                        InOut.operation_mode_display = TQ;
                    }
                    break;

                    /* Profile Velocity Mode initialization */
                case PV:
                    if (op_set_flag == 0) {
                        update_velocity_ctrl_param_ecat(velocity_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_velocity_control.set_velocity_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_velocity_control.set_velocity_ctrl_qei_param(qei_params);
                        }

                        i_velocity_control.set_velocity_ctrl_param(velocity_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_position_control.check_position_ctrl_state();
                        if (ctrl_state == 1)
                            i_position_control.shutdown_position_ctrl();
                        init = init_velocity_control(i_velocity_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        op_mode = PV;
                        steps = 0;
                        mode_quick_flag = 10;
                        ack = 0;
                        shutdown_ack = 0;

                        update_pv_param_ecat(profile_velocity_config, coe_out);
                        init_velocity_profile_limits(profile_velocity_config.max_profile_velocity,profile_velocity_config.quick_stop_deceleration,
                                                        profile_velocity_config.quick_stop_deceleration);
                        InOut.operation_mode_display = PV;
                    }
                    break;

                    /* Cyclic synchronous position mode initialization */
                case CSP:
                    if (op_set_flag == 0) {
                        update_position_ctrl_param_ecat(position_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_position_control.set_position_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_position_control.set_position_ctrl_qei_param(qei_params);
                        }
                        i_position_control.set_position_ctrl_param(position_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_velocity_control.check_velocity_ctrl_state();
                        if (ctrl_state == 1)
                            i_velocity_control.shutdown_velocity_ctrl();
                        init = init_position_control(i_position_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        mode_quick_flag = 10;
                        op_mode = CSP;
                        ack = 0;
                        shutdown_ack = 0;

                        update_csp_param_ecat(cyclic_sync_position_config, coe_out);
                        InOut.operation_mode_display = CSP;
                    }
                    break;

                    /* Cyclic synchronous velocity mode initialization */
                case CSV:   //csv mode index
                    if (op_set_flag == 0) {
                        update_velocity_ctrl_param_ecat(velocity_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_velocity_control.set_velocity_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_velocity_control.set_velocity_ctrl_qei_param(qei_params);
                        }

                        i_velocity_control.set_velocity_ctrl_param(velocity_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);
                        ctrl_state = i_position_control.check_position_ctrl_state();
                        if (ctrl_state == 1)
                            i_position_control.shutdown_position_ctrl();
                        init = init_velocity_control(i_velocity_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        mode_quick_flag = 10;
                        op_mode = CSV;
                        ack = 0;
                        shutdown_ack = 0;

                        update_csv_param_ecat(cyclic_sync_velocity_config, coe_out);
                        InOut.operation_mode_display = CSV;
                    }
                    break;

                    /* Cyclic synchronous torque mode initialization */
                case CST:
                    //printstrln("op mode enabled on slave");
                    if (op_set_flag == 0) {
                        update_torque_ctrl_param_ecat(torque_ctrl_params, coe_out);
                        sensor_select = sensor_select_sdo(coe_out);

                        if (sensor_select == HALL) {
                            i_torque_control.set_torque_ctrl_hall_param(hall_config);
                        } else { /* QEI */
                            i_torque_control.set_torque_ctrl_qei_param(qei_params);
                        }

                        i_torque_control.set_torque_ctrl_param(torque_ctrl_params);
                        i_torque_control.set_torque_sensor(sensor_select);
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_velocity_control.check_velocity_ctrl_state();
                        if (ctrl_state == 1)
                            i_velocity_control.shutdown_velocity_ctrl();
                        ctrl_state = i_position_control.check_position_ctrl_state(); /* FIXME: why twice? */
                        if (ctrl_state == 1)
                            i_position_control.shutdown_position_ctrl();
                        init = init_torque_control(i_torque_control);
                    }
                    if (init == INIT) {
                        op_set_flag = 1;
                        mode_selected = 1;
                        mode_quick_flag = 10;
                        op_mode = CST;
                        ack = 0;
                        shutdown_ack = 0;

                        update_cst_param_ecat(cyclic_sync_torque_config, coe_out);
                        update_pt_param_ecat(profile_torque_config, coe_out);
                        torque_offstate = (cyclic_sync_torque_config.max_torque * 15) / (cyclic_sync_torque_config.nominal_current * 100 * cyclic_sync_torque_config.motor_torque_constant);
                        InOut.operation_mode_display = CST;
                    }
                    break;
                }
            }

            /* After operation mode is selected the loop enters a continuous operation
             * until the operation is shutdown */
            if (mode_selected == 1) {
                switch (InOut.control_word) {
                case QUICK_STOP:
                    if (op_mode == CST || op_mode == TQ) {
                        actual_torque = i_torque_control.get_torque();
                        steps = init_linear_profile(0, actual_torque, profile_torque_config.profile_slope,
                                                    profile_torque_config.profile_slope);
                        i = 0;
                        mode_selected = 3; // non interruptible mode
                        mode_quick_flag = 0;
                    }
                    else if (op_mode == CSV || op_mode == PV) {
                        actual_velocity = i_velocity_control.get_velocity();

                        int deceleration;
                        if (op_mode == CSV) {
                            deceleration = cyclic_sync_velocity_config.max_acceleration;
                        } else { /* op_mode == PV */
                            deceleration = profile_velocity_config.quick_stop_deceleration;
                        }
                        steps = init_quick_stop_velocity_profile(actual_velocity,
                                                                 deceleration);
                        i = 0;
                        mode_selected = 3; // non interruptible mode
                        mode_quick_flag = 0;
                    } else if (op_mode == CSP || op_mode == PP) {
                        actual_velocity = i_hall.get_hall_velocity();
                        actual_position = i_position_control.get_position();

                        if (actual_velocity>=500 || actual_velocity<=-500) {
                            if (actual_velocity < 0) {
                                actual_velocity = -actual_velocity;
                            }

                            int deceleration;
                            if (op_mode == CSP) {
                                deceleration = cyclic_sync_position_config.velocity_config.max_acceleration;
                            } else { /* op_ode == PP */
                                deceleration = profile_position_config.velocity_config.quick_stop_deceleration;
                            }

                            int sensor_ticks;
                            if (sensor_select == HALL) {
                                sensor_ticks = hall_config.max_ticks_per_turn;
                            } else { /* QEI */
                                sensor_ticks = qei_params.real_counts;
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
                    //printstrln("cyclic");
                    if (op_mode == HM) {
                        if (ack == 0) {
                            home_velocity = get_target_velocity(InOut);
                            home_acceleration = get_target_torque(InOut);
                            //h_active = 1;

                            if (home_acceleration == 0) {
                                home_acceleration = get_target_torque(InOut);
                            }

                            if (home_velocity == 0) {
                                home_velocity = get_target_velocity(InOut);
                            } else {
                                if (home_acceleration != 0) {
                                    //mode_selected = 4;
                                    // set_home_switch_type(c_home, limit_switch_type);
                                    i = 1;
                                    actual_velocity = i_velocity_control.get_velocity();
                                    steps = init_velocity_profile(home_velocity * limit_switch,
                                                                  actual_velocity, home_acceleration,
                                                                  home_acceleration);
                                    //printintln(home_velocity);
                                    //printintln(home_acceleration);
                                    ack = 1;
                                    reset_counter = 0;
                                    end_state = 0;
                                }
                            }
                        } else if (ack == 1) {
                            if (reset_counter == 0) {
                                ack = 1;
                                if (i < steps) {
                                    velocity_ramp = velocity_profile_generate(i);
                                    i_velocity_control.set_velocity(velocity_ramp);
                                    i++;
                                }
                                home_state = i_gpio.read_gpio(0);//read_gpio_digital_input(c_gpio, 0);
                                safety_state = i_gpio.read_gpio(1);//read_gpio_digital_input(c_gpio, 1);
                                {capture_position, direction} = i_qei.get_qei_position_absolute();

                                if ((home_state == 1 || safety_state == 1) && end_state == 0) {
                                    actual_velocity = i_velocity_control.get_velocity();
                                    steps = init_velocity_profile(0, actual_velocity,
                                                                  home_acceleration,
                                                                  home_acceleration);
                                    i = 1;
                                    end_state = 1;
                                }
                                if (end_state == 1 && i >= steps) {
                                    i_velocity_control.shutdown_velocity_ctrl();
                                    if (home_state == 1) {
                                        {current_position, direction} = i_qei.get_qei_position_absolute();//get_qei_position_absolute(c_qei);

                                        //printintln(current_position);
                                        home_offset = current_position - capture_position;
                                        //printintln(home_offset);
                                        i_qei.reset_qei_count(home_offset);
                                        reset_counter = 1;
                                    }
                                }

                            }
                            if (reset_counter == 1) {
                                ack = 0;//h_active = 1;

                                //mode_selected = 100;
                                homing_done = 1;
                                //printstrln("homing_success"); //done
                                InOut.operation_mode_display = 250;
                            }
                        }
                    }

                    if (op_mode == CSV) {
                        target_velocity = get_target_velocity(InOut);
                        set_velocity_csv(cyclic_sync_velocity_config, target_velocity, 0, 0, i_velocity_control);

                        actual_velocity = i_velocity_control.get_velocity() * cyclic_sync_velocity_config.polarity;
                        send_actual_velocity(actual_velocity, InOut);
                    } else if (op_mode == CST) {
                        target_torque = get_target_torque(InOut);
                        set_torque_cst(cyclic_sync_torque_config, target_torque, 0, i_torque_control);

                        actual_torque = i_torque_control.get_torque();
                        send_actual_torque(actual_torque, InOut);
                    } else if (op_mode == CSP) {
                        target_position = get_target_position(InOut);
                        set_position_csp(cyclic_sync_position_config, target_position, 0, 0, 0, i_position_control);

                        actual_position = i_position_control.get_position() * cyclic_sync_position_config.velocity_config.polarity;
                        send_actual_position(actual_position, InOut);
                        //safety_state = read_gpio_digital_input(c_gpio, 1);        // read port 1
                        //value = (port_3_value<<3 | port_2_value<<2 | port_1_value <<1| safety_state );  pack values if more than one port inputs
                    } else if (op_mode == PP) {
                        if (ack == 1) {
                            target_position = get_target_position(InOut);
                            actual_position = i_position_control.get_position() * profile_position_config.velocity_config.polarity;
                            send_actual_position(actual_position, InOut);

                            if (prev_position != target_position) {
                                ack = 0;
                                steps = init_position_profile(target_position, actual_position,
                                                              profile_position_config.profile_velocity,
                                                              profile_position_config.velocity_config.profile_acceleration,
                                                              profile_position_config.velocity_config.profile_deceleration);

                                i = 1;
                                prev_position = target_position;
                            }
                        } else if (ack == 0) {
                            if (i < steps) {
                                position_ramp = position_profile_generate(i);
                                i_position_control.set_position(position_limit(position_ramp * profile_position_config.velocity_config.polarity,
                                        profile_position_config.software_position_limit_max,
                                        profile_position_config.software_position_limit_min));
                                i++;
                            } else if (i == steps) {
                                t :> c_time;
                                t when timerafter(c_time + 15*MSEC_STD) :> c_time;
                                ack = 1;
                            } else if (i > steps) {
                                ack = 1;
                            }
                            //actual_position = get_position(c_position_ctrl) * profile_position_config.velocity_config.polarity;
                            //send_actual_position(actual_position, InOut);
                        }
                    } else if (op_mode == TQ) {
                        if (ack == 1) {
                            target_torque = get_target_torque(InOut);
                            actual_torque = i_torque_control.get_torque();
                            send_actual_torque(actual_torque, InOut);

                            if (prev_torque != target_torque) {
                                ack = 0;
                                steps = init_linear_profile(target_torque, actual_torque,
                                                            profile_torque_config.profile_slope,
                                                            profile_torque_config.profile_slope);
                                i = 1;
                                prev_torque = target_torque;
                            }
                        } else if (ack == 0) {
                            if (i < steps) {
                                torque_ramp = linear_profile_generate(i);
                                set_torque_cst(cyclic_sync_torque_config, torque_ramp, 0, i_torque_control);
                                i++;
                            } else if (i == steps) {
                                t :> c_time;
                                t when timerafter(c_time + 10*MSEC_STD) :> c_time;
                                ack = 1;
                            } else if (i > steps) {
                                ack = 1;
                            }
                            actual_torque = i_torque_control.get_torque();
                            send_actual_torque(actual_torque, InOut);
                        }
                    } else if (op_mode == PV) {
                        if (ack == 1) {
                            target_velocity = get_target_velocity(InOut);
                            actual_velocity = i_velocity_control.get_velocity() * profile_velocity_config.polarity;
                            send_actual_velocity(actual_velocity, InOut);

                            if (prev_velocity != target_velocity) {
                                ack = 0;
                                steps = init_velocity_profile(target_velocity, actual_velocity,
                                                              profile_velocity_config.profile_acceleration,
                                                              profile_velocity_config.profile_deceleration);
                                i = 1;
                                prev_velocity = target_velocity;
                            }
                        } else if (ack == 0) {
                            if (i < steps) {
                                velocity_ramp = velocity_profile_generate(i);
                                i_velocity_control.set_velocity(max_speed_limit( (velocity_ramp) * profile_velocity_config.polarity,
                                        profile_velocity_config.max_profile_velocity));
                                i++;
                            } else if (i == steps) {
                                t :> c_time;
                                t when timerafter(c_time + 10*MSEC_STD) :> c_time;
                                ack = 1;
                            } else if (i > steps) {
                                ack = 1;
                            }
                            actual_velocity = i_velocity_control.get_velocity() * profile_velocity_config.polarity;
                            send_actual_velocity(actual_velocity, InOut);
                        }
                    }
                    break;

                case SHUTDOWN:
                    if (op_mode == CST || op_mode == TQ) {
                        i_torque_control.shutdown_torque_ctrl();
                        shutdown_ack = 1;
                        op_set_flag = 0;
                        init = 0;
                        mode_selected = 0;  // to reenable the op selection and reset the controller
                        setup_loop_flag = 0;
                    } else if (op_mode == CSV || op_mode == PV) {
                        i_velocity_control.shutdown_velocity_ctrl();
                        shutdown_ack = 1;
                        op_set_flag = 0;
                        init = 0;
                        mode_selected = 0;  // to reenable the op selection and reset the controller
                        setup_loop_flag = 0;
                    } else if (op_mode == CSP || op_mode == PP) {
                        i_position_control.shutdown_position_ctrl();
                        shutdown_ack = 1;
                        op_set_flag = 0;
                        init = 0;
                        mode_selected = 0;  // to reenable the op selection and reset the controller
                        setup_loop_flag = 0;
                    } else if (op_mode == HM) {
                        //shutdown_position_ctrl(c_position_ctrl);
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
                if (op_mode == CST || op_mode == TQ) {
                    t :> c_time;
                    while (i < steps) {
                        target_torque = linear_profile_generate(i);
                        i_torque_control.set_torque(target_torque);
                        actual_torque = i_torque_control.get_torque() * cyclic_sync_torque_config.polarity;
                        send_actual_torque(actual_torque, InOut);
                        t when timerafter(c_time + MSEC_STD) :> c_time;
                        i++;
                    }
                    if (i == steps) {
                        t when timerafter(c_time + 100*MSEC_STD) :> c_time;
                        actual_torque = i_torque_control.get_torque();
                        send_actual_torque(actual_torque, InOut);
                    }
                    if (i >= steps) {
                        actual_torque = i_torque_control.get_torque();
                        send_actual_torque(actual_torque, InOut);
                        if (actual_torque < torque_offstate || actual_torque > -torque_offstate) {
                            ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);
                            mode_selected = 100;
                            op_set_flag = 0;
                            init = 0;
                        }
                    }
                    if (steps == 0) {
                        mode_selected = 100;
                        op_set_flag = 0;
                        init = 0;
                    }
                } else if (op_mode == CSV || op_mode == PV) {
                    t :> c_time;
                    while (i < steps) {
                        target_velocity = quick_stop_velocity_profile_generate(i);
                        if (op_mode == CSV) {
                            i_velocity_control.set_velocity(max_speed_limit(target_velocity, cyclic_sync_velocity_config.max_motor_speed));
                            actual_velocity = i_velocity_control.get_velocity();
                            send_actual_velocity(actual_velocity * cyclic_sync_velocity_config.polarity, InOut);
                        } else if (op_mode == PV) {
                            i_velocity_control.set_velocity(max_speed_limit(target_velocity, profile_velocity_config.max_profile_velocity));
                            actual_velocity = i_velocity_control.get_velocity();
                            send_actual_velocity(actual_velocity * profile_velocity_config.polarity, InOut);
                        }
                        t when timerafter(c_time + MSEC_STD) :> c_time;
                        i++;
                    }
                    if (i == steps) {
                        t when timerafter(c_time + 100*MSEC_STD) :> c_time;
                    }
                    if (i >= steps) {
                        if (op_mode == CSV)
                            send_actual_velocity(actual_velocity * cyclic_sync_velocity_config.polarity, InOut);
                        else if (op_mode == PV)
                            send_actual_velocity(actual_velocity * profile_velocity_config.polarity, InOut);
                        if (actual_velocity < 50 || actual_velocity > -50) {
                            ctrlproto_protocol_handler_function(pdo_out, pdo_in, InOut);
                            mode_selected = 100;
                            op_set_flag = 0;
                            init = 0;
                        }
                    }
                    if (steps == 0) {
                        mode_selected = 100;
                        op_set_flag = 0;
                        init = 0;

                    }
                } else if (op_mode == CSP || op_mode == PP) {
                    {actual_position, sense} = get_position_absolute(sensor_select, i_hall, i_qei);

                    t :> c_time;
                    while (i < steps) {
                        target_position = quick_stop_position_profile_generate(i, sense);
                        if (op_mode == CSP) {
                            i_position_control.set_position(position_limit(target_position,
                                                                   cyclic_sync_position_config.max_position_limit,
                                                                   cyclic_sync_position_config.min_position_limit));
                        } else if (op_mode == PP) {
                            i_position_control.set_position(position_limit(target_position,
                                                            profile_position_config.software_position_limit_max,
                                                            profile_position_config.software_position_limit_min));
                        }
                        t when timerafter(c_time + MSEC_STD) :> c_time;
                        i++;
                    }

                    if (i == steps) {
                        t when timerafter(c_time + 100*MSEC_STD) :> c_time;
                    }
                    if (i >= steps) {
                        actual_velocity = i_hall.get_hall_velocity();
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
                    actual_torque = i_torque_control.get_torque();
                    send_actual_torque(actual_torque, InOut);
                } else if (op_mode == TQ) {
                    actual_torque = i_torque_control.get_torque();
                    send_actual_torque(actual_torque, InOut);
                } else if (op_mode == CSV) {
                    actual_velocity = i_velocity_control.get_velocity();
                    send_actual_velocity(actual_velocity * cyclic_sync_velocity_config.polarity, InOut);
                } else if (op_mode == PV) {
                    actual_velocity = i_velocity_control.get_velocity();
                    send_actual_velocity(actual_velocity * profile_velocity_config.polarity, InOut);
                    send_actual_velocity(actual_velocity, InOut);
                }
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
            {actual_position, direction} = get_position_absolute(sensor_select, i_hall, i_qei);
            send_actual_torque( i_torque_control.get_torque(), InOut );
            //send_actual_torque( get_torque(c_torque_ctrl) * polarity, InOut );
            send_actual_position(actual_position * polarity, InOut);
            t when timerafter(time + MSEC_STD) :> time;
        }
//#pragma xta endpoint "ecatloop_stop"
    }
}
