/**
 * @file drive_config.h
 * @brief Motor Drive defines and configurations
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <stdint.h>
//#include <stdbool_xc.h>

#include <adc_service.h>

#include <position_ctrl_service.h>
#include <velocity_ctrl_service.h>
#include <torque_ctrl_service.h>

typedef int bool;
#define true 1
#define false 0

typedef struct S_Check_list {
    bool ready;
    bool switch_on;
    bool operation_enable;
    bool mode_op;
    bool fault;

    bool _commutation_init;
    bool _hall_init;
    bool _qei_init;
    bool _biss_init;
    bool _adc_init;
    bool _torque_init;
    bool _velocity_init;
    bool _position_init;
} check_list;


bool __check_bdc_init(chanend c_signal);

int init_state(void);

/**
 * @brief Initialize checklist params
 *
 * @Output
 * @return check_list initialised checklist parameters
 */
check_list init_checklist(void);

/**
 * @brief Update Checklist
 *
 * @Input channel
 * @param c_commutation for communicating with the commutation server
 * @param c_hall for communicating with the hall server
 * @param c_qei for communicating with the qei server
 * @param c_adc for communicating with the adc server
 * @param c_torque_ctrl for communicating with the torque control server
 * @param c_velocity_ctrl for communicating with the velocity control server
 * @param c_position_ctrl for communicating with the position control server
 *
 * @Input
 * @param mode sets mode of operation
 *
 * @Output
 * @return check_list_param updated checklist parameters
 */
void update_checklist(check_list &check_list_param, int mode,
                        interface MotorcontrolInterface client i_commutation,
                        interface HallInterface client ?i_hall,
                        interface QEIInterface client ?i_qei,
                        interface BISSInterface client ?i_biss,
                        interface ADCInterface client ?i_adc,
                        interface TorqueControlInterface client i_torque_control,
                        interface VelocityControlInterface client i_velocity_control,
                        interface PositionControlInterface client i_position_control);

int16_t update_statusword(int current_status, int state_reached, int ack, int q_active, int shutdown_ack);

int get_next_state(int in_state, check_list &checklist, int controlword);

int read_controlword_switch_on(int control_word);

int read_controlword_quick_stop(int control_word);

int read_controlword_enable_op(int control_word);

int read_controlword_fault_reset(int control_word);

