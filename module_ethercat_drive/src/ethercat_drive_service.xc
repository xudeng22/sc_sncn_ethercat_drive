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
                            interface TorqueControlInterface client ?i_torque_control,
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
    int op_mode = 0;

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
    int state;
    int statusword;
    int controlword;

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
     * written into the object dictionary. So we reread the object dictionary values and continue operation.
     *
     * This should be done before we configure anything.
     */
    sdo_wait_first_config(i_coe);

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

            if (setup_loop_flag == 0) {
                if (controlword == 6) {
                    tmp = i_coe.get_object_value(0x60b0, 0);
                    status = (unsigned char)(tmp&0xff);
                    if (status == 0) {
                        status = 0xaf;
                        i_coe.set_object_value(0x60b0, 0, status);
                        tmp = i_coe.get_object_value(0x60b0, 0);
                        if (tmp == status) {
                            t :> c_time;
                            t when timerafter(c_time + 500*MSEC_STD) :> c_time;
                            InOut.operation_mode_display = 105;

                        }
                    } else if (status == 0xaf) {
                        InOut.operation_mode_display = 105;
                    }
                }
                /* Read Motor Configuration sent from the EtherCAT Master Application */
                if (controlword == 5) {
                    update_commutation_param_ecat(commutation_params, i_coe);
                    sensor_select = sensor_select_sdo(i_coe);

                    //if (sensor_select == HALL_SENSOR)  /* FIXME (?)
                    //{
                    update_hall_config_ecat(hall_config, i_coe);
                    //}
                    biss_config.pole_pairs = hall_config.pole_pairs;
                    ams_config.pole_pairs = hall_config.pole_pairs;
                    if (sensor_select >= QEI_SENSOR) { /* FIXME QEI with Index defined as 2 and without Index as 3  */
                        update_qei_param_ecat(qei_params, i_coe);
                    }
                    nominal_speed = speed_sdo_update(i_coe);
                    update_pp_param_ecat(profiler_config, i_coe);
                    polarity = profiler_config.polarity;//profile_position_config.velocity_config.polarity;
                    //qei_params.poles = hall_config.pole_pairs;

                    //config_sdo_handler(i_coe);
                    {homing_method, limit_switch_type} = homing_sdo_update(i_coe);
                    if (homing_method == HOMING_NEGATIVE_SWITCH)
                        limit_switch = -1;
                    else if (homing_method == HOMING_POSITIVE_SWITCH)
                        limit_switch = 1;

                    /* Configuration of GPIO Digital ports follows here */
                    if (!isnull(i_gpio)) {
                        i_gpio.config_dio_input(0, SWITCH_INPUT_TYPE, limit_switch_type);
                        i_gpio.config_dio_input(1, SWITCH_INPUT_TYPE, limit_switch_type);
                        i_gpio.config_dio_done();//end_config_gpio(c_gpio);
                    }
                    if (!isnull(i_hall))
                        i_hall.set_hall_config(hall_config); //set_hall_conifg_ecat(c_hall, hall_config);
                    if (homing_done == 0 && !isnull(i_qei))
                        i_qei.set_qei_config(qei_params);
                    if (!isnull(i_biss))
                        i_biss.set_biss_config(biss_config);
                    if (!isnull(i_ams))
                        i_ams.set_ams_config(ams_config);
                    i_commutation.set_all_parameters(hall_config, qei_params,
                                               commutation_params);

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

            if (mode_selected == 0) {
                /* Select an operation mode requested from EtherCAT Master Application */
                switch (InOut.operation_mode) {
                    /* Cyclic synchronous position mode initialization */
                //FixMe: initialization should take place before we start PDO communication
                case CSP:
                    if (op_set_flag == 0) {
                        update_position_ctrl_param_ecat(position_ctrl_params, i_coe);
                        sensor_select = sensor_select_sdo(i_coe);

                        if (sensor_select == HALL_SENSOR && !isnull(i_hall)) {
                            i_hall.set_hall_config(hall_config);
                        } else if (sensor_select == QEI_SENSOR && !isnull(i_qei)) { /* QEI */
                            i_qei.set_qei_config(qei_params);
                        } else if (sensor_select == BISS_SENSOR && !isnull(i_biss)) { /* BiSS */
                            i_biss.set_biss_config(biss_config);
                        } else if (sensor_select == AMS_SENSOR && !isnull(i_ams)) { /* AMS */
                            i_ams.set_ams_config(ams_config);
                        }
                        i_position_control.set_position_control_config(position_ctrl_params);
                        if(motorcontrol_config.commutation_method == SINE && !isnull(i_torque_control)){
                            i_torque_control.set_torque_sensor(sensor_select);
                        }
                        i_velocity_control.set_velocity_sensor(sensor_select);
                        i_position_control.set_position_sensor(sensor_select);

                        ctrl_state = i_velocity_control.check_busy();
                        if (ctrl_state == 1)
                            i_velocity_control.disable_velocity_ctrl();
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
                switch (InOut.control_word) {
                case QUICK_STOP:
                    if (op_mode == CST) {
                        //ToDo: implement quickstop for CST
                    }
                    else if (op_mode == CSV) {
                        //ToDo: implement quickstop for CSV
                    } else if (op_mode == CSP) {
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
                    //printstrln("cyclic");
                    if (op_mode == CSV) {
                        //ToDo: implement CSV
                    } else if (op_mode == CST) {
                        //ToDo: implement CST
                    } else if (op_mode == CSP) {
                        target_position = get_target_position(InOut);
                        i_position_control.set_position(position_limit( (target_position) * profiler_config.polarity,
                                                        profiler_config.max_position, profiler_config.min_position));
                       // set_position_csp(profiler_config, target_position, 0, 0, 0, i_position_control);

                        actual_position = i_position_control.get_position() * profiler_config.polarity;//cyclic_sync_position_config.velocity_config.polarity;
                        send_actual_position(actual_position, InOut);
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
