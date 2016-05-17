/**
 * @file config_manager.xc
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <stdint.h>
#include <canod.h>
#include "config_manager.h"

struct _config_object {
    uint16_t index;
    uint8_t subindex;
    uint8_t type;
};

void cm_sync_config_hall(
        client interface i_coe_communication i_coe,
        interface HallInterface client ?i_hall,
        HallConfig &hall_config)
{
    if (isnull(i_hall))
        return;

    hall_config = i_hall.get_hall_config();

    hall_config.pole_pairs = i_coe.get_object_value(CIA402_MOTOR_SPECIFIC, 3);

    i_hall.set_hall_config(hall_config);
}

void cm_sync_config_qei(
        client interface i_coe_communication i_coe,
        interface QEIInterface client ?i_qei,
        QEIConfig &qei_config)
{
    if (isnull(i_qei))
        return;

    qei_config = i_qei.get_qei_config();

    qei_config.ticks_resolution = i_coe.get_object_value(CIA402_POSITION_ENC_RESOLUTION, 0);
    qei_config.index_type = i_coe.get_object_value(CIA402_SENSOR_SELECTION_CODE, 0);
    qei_config.sensor_polarity = i_coe.get_object_value(SENSOR_POLARITY, 0);

    /* FIXME add min and max? */
    //min = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
    //max = i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);

    i_qei.set_qei_config(qei_config);
}

void cm_sync_config_biss(
        client interface i_coe_communication i_coe,
        interface BISSInterface client ?i_biss,
        BISSConfig &biss_config)
{
    if (isnull(i_biss))
        return;

    biss_config = i_biss.get_biss_config();

    /* FIXME: add reading of biss related objects */

    i_biss.set_biss_config(biss_config);
}


void cm_sync_config_ams(
        client interface i_coe_communication i_coe,
        interface AMSInterface client ?i_ams,
        AMSConfig &ams_config)
{
    if (isnull(i_ams))
        return;

    ams_config = i_ams.get_ams_config();

    /* FIXME: add reading of ams related objects */

    i_ams.set_ams_config(ams_config);
}

void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client ?i_commutation,
        MotorcontrolConfig &commutation_params)

{
    if (isnull(i_commutation))
        return;

    commutation_params = i_commutation.get_config();

    commutation_params.bldc_winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0); /* FIXME check if the object contains values that respect BLDCWindingType */
    commutation_params.hall_offset[0] = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);;
    commutation_params.hall_offset[1] = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);;

    i_commutation.set_config(commutation_params);
}

/* FIXME basically the same as in cm_sync_config_motor_control() */
void cm_sync_config_motor_commutation(
        client interface i_coe_communication i_coe,
        MotorcontrolConfig &mc_config)
{
    mc_config.hall_offset[0]    = i_coe.get_object_value(COMMUTATION_OFFSET_CLKWISE, 0);
    mc_config.hall_offset[1]    = i_coe.get_object_value(COMMUTATION_OFFSET_CCLKWISE, 0);
    mc_config.bldc_winding_type = i_coe.get_object_value(MOTOR_WINDING_TYPE, 0);
}

void cm_sync_config_torque_control(
        client interface i_coe_communication i_coe,
        interface TorqueControlInterface client ?i_torque_control,
        ControlConfig &torque_ctrl_params)
{
    if (isnull(i_torque_control))
        return;
#if 0 /* unavailable */
    torque_ctrl_params = i_torque_control.get_config();

    torque_ctrl_params.Kp_n = i_coe.get_object_value(CIA402_CURRENT_GAIN, 1);
    torque_ctrl_params.Ki_n = i_coe.get_object_value(CIA402_CURRENT_GAIN, 2);
    torque_ctrl_params.Kd_n = i_coe.get_object_value(CIA402_CURRENT_GAIN, 3);

    /* FIXME what does this fixed value here? */
    torque_ctrl_params.control_loop_period = 1000; //1ms

    i_torque_control.set_config(torque_ctrl_params);
#endif
}

void cm_sync_config_velocity_control(
        client interface i_coe_communication i_coe,
        interface VelocityControlInterface client ?i_velocity_control,
        ControlConfig &velocity_ctrl_params)
{
    if (isnull(i_velocity_control))
        return;

    velocity_ctrl_params = i_velocity_control.get_velocity_control_config();

    velocity_ctrl_params.Kp_n = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 1);
    velocity_ctrl_params.Ki_n = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 2);
    velocity_ctrl_params.Kd_n = i_coe.get_object_value(CIA402_VELOCITY_GAIN, 3);

    /* FIXME what does this fixed value here? */
    velocity_ctrl_params.control_loop_period = 1000; //1ms

    i_velocity_control.set_velocity_control_config(velocity_ctrl_params);
}

void cm_sync_config_position_control(
        client interface i_coe_communication i_coe,
        interface PositionControlInterface client ?i_position_control,
        ControlConfig &position_ctrl_params)
{
    if (isnull(i_position_control))
        return;

    position_ctrl_params = i_position_control.get_position_control_config();

    position_ctrl_params.Kp_n = i_coe.get_object_value(CIA402_POSITION_GAIN, 1);
    position_ctrl_params.Ki_n = i_coe.get_object_value(CIA402_POSITION_GAIN, 2);
    position_ctrl_params.Kd_n = i_coe.get_object_value(CIA402_POSITION_GAIN, 3);

    /* FIXME what does this fixed value here? */
    position_ctrl_params.control_loop_period = 1000; //1ms

    i_position_control.set_position_control_config(position_ctrl_params);
}

void cm_sync_config_profiler(
        client interface i_coe_communication i_coe,
        ProfilerConfig &profiler)
{
    profiler.max_velocity     =  i_coe.get_object_value(CIA402_MAX_PROFILE_VELOCITY, 0);
    profiler.velocity         =  i_coe.get_object_value(CIA402_PROFILE_VELOCITY, 0);
    profiler.acceleration     =  i_coe.get_object_value(CIA402_PROFILE_ACCELERATION, 0);
    profiler.deceleration     =  i_coe.get_object_value(CIA402_PROFILE_DECELERATION, 0);
    profiler.max_deceleration =  i_coe.get_object_value(CIA402_QUICK_STOP_DECELERATION, 0);
    profiler.min_position     =  i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 1);
    profiler.max_position     =  i_coe.get_object_value(CIA402_SOFTWARE_POSITION_LIMIT, 2);
    profiler.polarity         =  i_coe.get_object_value(CIA402_POLARITY, 0);
    profiler.max_acceleration =  i_coe.get_object_value(CIA402_MAX_ACCELERATION, 0);
}

