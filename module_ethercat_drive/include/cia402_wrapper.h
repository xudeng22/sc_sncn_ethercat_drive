/**
 * @file ctrlproto.h
 * @brief Control Protocol Handler
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <print.h>
#include <stdlib.h>
#include <stdint.h>
#include <coecmd.h>
#include <canod.h>

#include <hall_service.h>
#include <qei_service.h>
#include <motorcontrol_service.h>
#include <control_loops_common.h>
#include <profile_control.h>

/* internal qei single variable selection code */
#define QEI_SENSOR_TYPE                         QEI_WITH_INDEX//QEI_WITH_NO_INDEX

#define GET_SDO_DATA(index, sub_index, value) \
    coe_out <: CAN_GET_OBJECT;                \
    coe_out <: CAN_OBJ_ADR(index, sub_index); \
    coe_out :> value;

/**
 * @brief
 *  Struct for Tx, Rx PDOs
 */
typedef struct
{
    uint8_t operation_mode;    //      Modes of Operation
    uint16_t control_word;     //      Control Word

    int16_t target_torque;
    int32_t target_velocity;
    int32_t target_position;


    uint8_t operation_mode_display; //      Modes of Operation Display
    uint16_t status_word;                   //  Status Word

    int16_t torque_actual;
    int32_t velocity_actual;
    int32_t position_actual;

} ctrl_proto_values_t;



/**
 * @brief
 *  This function receives channel communication from the ctrlproto_pdo_handler_thread
 *  It updates the referenced values according to the command and has to be placed
 *  inside the control loop.
 *
 *  This function is not considered as stand alone thread! It's for being executed in
 *  the motor control thread
 *
 * @param pdo_out       the channel for outgoing process data objects
 * @param pdo_in        the channel for incoming process data objects
 * @param InOut         the struct for exchanging data with the motor control functions
 *
 * @return      1 if communication is active else 0
 */
int ctrlproto_protocol_handler_function(chanend pdo_out, chanend pdo_in, ctrl_proto_values_t &InOut);

/**
 *  @brief
 *       This function initializes a struct from the type of ctrl_proto_values_t
 *
 *      \return ctrl_proto_values_t with values initialised
 */
ctrl_proto_values_t init_ctrl_proto(void);

/*
 * FIXME: documentation missing
 */
void config_sdo_handler(chanend coe_out);

/**
 * @brief read sensor select from Ethercat
 *
 * @return sensor_select HALL/QEI
 *
 */
int sensor_select_sdo(chanend coe_out);

/**
 * @brief read qei params from Ethercat
 *
 * @return real counts
 * @return max position
 * @return min position
 * @return qei type
 * @return sensor polarity
 *
 */
{int, int, int, int, int} qei_sdo_update(chanend coe_out);

/**
 * @brief read hall params from Ethercat
 *
 * @return pole pairs
 * @return max position
 * @return min position
 *
 */
{int, int, int} hall_sdo_update(chanend coe_out);

/**
 * @brief read commutation parameters from Ethercat
 *
 * @return hall_offset_clk
 * @return hall_offset_cclk
 * @return winding_type
 *
 */
{int, int, int} commutation_sdo_update(chanend coe_out);

/**
 * @brief read homing parameters from Ethercat
 *
 * @return homing_method
 * @return limit_switch_type
 *
 */
{int, int} homing_sdo_update(chanend coe_out);

/**
 * @brief read profile torque params from Ethercat
 *
 * @return torque_slope
 * @return polarity
 *
 */
{int, int} pt_sdo_update(chanend coe_out);

/**
 * @brief read profile velocity params from Ethercat
 *
 * @return max_profile_velocity
 * @return profile_acceleration
 * @return profile_deceleration
 * @return quick_stop_deceleration
 * @return polarity
 *
 */
{int, int, int, int, int} pv_sdo_update(chanend coe_out);

/**
 * @brief read profile position params from Ethercat
 *
 * @return max_profile_velocity
 * @return profile_velocity
 * @return profile_acceleration
 * @return profile_deceleration
 * @return quick_stop_deceleration
 * @return min
 * @return max
 * @return polarity
 * @return max_acceleration
 *
 */
{int, int, int, int, int, int, int, int, int} pp_sdo_update(chanend coe_out);

/**
 * @brief read cyclic synchronous torque params from Ethercat
 *
 * @return nominal_current
 * @return max_motor_speed
 * @return polarity
 * @return max_torque
 * @return motor_torque_constant
 *
 */
{int, int, int, int, int} cst_sdo_update(chanend coe_out);

/**
 * @brief read cyclic synchronous velocity params from Ethercat
 *
 * @return max_motor_speed
 * @return nominal_current
 * @return polarity
 * @return motor_torque_constant
 * @return max_acceleration
 *
 */
{int, int, int, int, int} csv_sdo_update(chanend coe_out);

/**
 * @brief read cyclic synchronous position params from Ethercat
 *
 * @return max_motor_speed
 * @return polarity
 * @return nominal_current
 * @return min position
 * @return max position
 * @return max_acceleration
 *
 */
{int, int, int, int, int, int} csp_sdo_update(chanend coe_out);

/**
 * @brief read torque control params from Ethercat
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} torque_sdo_update(chanend coe_out);

/**
 * @brief read velocity control params from Ethercat
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} velocity_sdo_update(chanend coe_out);

/**
 * @brief read position control params from Ethercat
 *
 * @return Kp
 * @return Ki
 * @return Kd
 *
 */
{int, int, int} position_sdo_update(chanend coe_out);

/**
 * @brief read nominal speed from Ethercat
 *
 * @return nominal_speed
 *
 */
int speed_sdo_update(chanend coe_out);


/**
 * @brief Get target torque from Ethercat
 *
 * @return target torque from Ethercat in range [0 - mNm * Current Resolution]
 */
int get_target_torque(ctrl_proto_values_t InOut);

/**
 * @brief Get target velocity from Ethercat
 *
 * @return target velocity from Ethercat in rpm
 */
int get_target_velocity(ctrl_proto_values_t InOut);

/**
 * @brief Get target position from Ethercat
 *
 * @return target position from Ethercat in ticks
 */
int get_target_position(ctrl_proto_values_t InOut);

/**
 * @brief Send actual torque to Ethercat
 *
 * @param[in] actual_torque sent to Ethercat in range [0 - mNm * Current Resolution]
 */
void send_actual_torque(int actual_torque, ctrl_proto_values_t &InOut);

/**
 * @brief Send actual velocity to Ethercat
 *
 * @param[in] actual_velocity sent to Ethercat in rpm
 * @param[in] ctrl_proto_values_t
 */
void send_actual_velocity(int actual_velocity, ctrl_proto_values_t &InOut);

/**
 * @brief Send actual position to Ethercat
 *
 * @param[in] actual_position sent to Ethercat in ticks
 * @param[in] ctrl_proto_values_t
 */
void send_actual_position(int actual_position, ctrl_proto_values_t &InOut);

/**
 * @brief Update Hall sensor parameters from Ethercat
 *
 * @param hall_config struct defines the pole-pairs and gear ratio
 * @param coe_out
 */
void update_hall_config_ecat(HallConfig &hall_config, chanend coe_out);

/**
 * @brief Update QEI sensor parameters from Ethercat
*
 * @param qei_params struct defines the quadrature encoder (QEI) resolution, sensor type and
*    gear-ratio used for the motor
*/
void update_qei_param_ecat(QEIConfig &qei_params, chanend coe_out);

void update_commutation_param_ecat(MotorcontrolConfig &commutation_params, chanend coe_out);

/**
 * @brief Update cyclic synchronous torque parameters from Ethercat
*
 * @param cst_params struct defines the cyclic synchronous torque params
 * @param coe_out
*/
void update_cst_param_ecat(CyclicSyncTorqueConfig &cst_params, chanend coe_out);

/**
 * @brief Update cyclic synchronous velocity parameters from Ethercat
*
 * @param csv_params struct defines the cyclic synchronous velocity params
 * @param coe_out
*
*/
void update_csv_param_ecat(CyclicSyncVelocityConfig &csv_params, chanend coe_out);

/**
 * @brief Update cyclic synchronous position parameters from Ethercat
*
 * @param csp_params struct defines the cyclic synchronous position params
 * @param coe_out
*/
void update_csp_param_ecat(CyclicSyncPositionConfig &csp_params, chanend coe_out);

/**
 * @brief Update profile torque parameters from Ethercat
*
 * @param pt_params struct defines the profile torque params
 * @param coe_out
*/
void update_pt_param_ecat(ProfileTorqueConfig &pt_params, chanend coe_out);

/**
 * @brief Update profile velocity parameters from Ethercat
*
 * @param pv_params struct defines the profile velocity params
 * @param coe_out
*/
void update_pv_param_ecat(ProfileVelocityConfig &pv_params, chanend coe_out);

/**
 * @brief Update profile position parameters from Ethercat
*
 * @param pp_params struct defines the profile position params
 * @param coe_out
*/
void update_pp_param_ecat(ProfilePositionConfig &pp_params, chanend coe_out);

/**
 * @brief Update torque control PID parameters from Ethercat
 *
 * @param torque_ctrl_params struct defines torque control PID params
 */
void update_torque_ctrl_param_ecat(ControlConfig &torque_ctrl_params, chanend coe_out);

/**
 * @brief Update velocity control PID parameters from Ethercat
 *
 * @param velocity_ctrl_params struct defines velocity control PID params
 */
void update_velocity_ctrl_param_ecat(ControlConfig &velocity_ctrl_params, chanend coe_out);

/**
 * @brief Update position control PID params from Ethercat
 *
 * @param position_ctrl_params struct defines position control PID params
 */
void update_position_ctrl_param_ecat(ControlConfig &position_ctrl_params, chanend coe_out);

