/**
 * @file config_manager.xc
 * @brief EtherCAT Motor Drive Configuration Manager
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include "config_manager.h"


void cm_sync_config_hall(
        client interface i_coe_communication i_coe,
        interface HallInterface client ?i_hall,
        HallConfig &hall_config)
{
    if (isnull(i_hall))
        return;

}


void cm_sync_config_motor_control(
        client interface i_coe_communication i_coe,
        interface MotorcontrolInterface client i_commutation,
        MotorcontrolConfig &commutation_params)

{
    if (isnull(i_hall))
        return;

}

void cm_sync_config_qei(
        client interface i_coe_communication i_coe,
        interface QEIInterface client ?i_qei,
        QEIConfig &qei_params)
{
    if (isnull(i_hall))
        return;

}

void cm_sync_config_biss(
        client interface i_coe_communication i_coe,
        interface BISSInterface client ?i_biss,
        BISSConfig &biss_config)
{
    if (isnull(i_hall))
        return;

}


void cm_sync_config_ams(
        client interface i_coe_communication i_coe,
        interface AMSInterface client ?i_ams,
        AMSConfig &ams_config)
{
    if (isnull(i_hall))
        return;

}

void cm_sync_config_torque_control(
        client interface i_coe_communication i_coe,
        interface TorqueControlInterface client ?i_torque_control,
        ControlConfig &torque_ctrl_params)
{
    if (isnull(i_hall))
        return;

}

void cm_sync_config_velocity_control(
        client interface i_coe_communication i_coe,
        interface VelocityControlInterface client i_velocity_control,
        ControlConfig &velocity_ctrl_params)
{
    if (isnull(i_hall))
        return;

}

void cm_sync_config_position_control(
        client interface i_coe_communication i_coe,
        interface PositionControlInterface client i_position_control,
        ControlConfig &position_ctrl_params)
{
    if (isnull(i_hall))
        return;

}
