/**
 * @file pdo_handler.xc
 * @brief Control Protocol PDO Parser
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <ethercat_service.h>
#include <pdo_handler.h>

#define MAX_PDO_SIZE    64

pdo_handler_values_t pdo_handler_init(void)
{
	pdo_handler_values_t InOut;

	InOut.controlword                     = 0x00;
	InOut.op_mode                         = 0x00;

	InOut.target_torque                   = 0x0;
	InOut.target_velocity                 = 0x0;
	InOut.target_position                 = 0x0;

	InOut.offset_torque                   = 0x0;
	InOut.tuning_status                   = 0x0;
	InOut.tuning_control                  = 0x0;
	InOut.command_pid_update              = 0x0;

	InOut.statusword                      = 0x0000;
	InOut.op_mode_display                 = 0x00;

	InOut.torque_value                    = 0x0;
	InOut.velocity_value                  = 0x0;
	InOut.position_value                  = 0x0;

	InOut.additional_feedbacksensor_value = 0x0;
	InOut.tuning_result                   = 0x0;

	return InOut;
}

int pdo_handler(client interface i_pdo_communication i_pdo, pdo_handler_values_t &inout)
{

	unsigned char buffer[MAX_PDO_SIZE];
	unsigned int count = 0;

	count = i_pdo.get_pdos_value(buffer);

	//Test for matching number of words
	if(count > 0)
	{
		inout.controlword = buffer[1] << 8 | buffer[0];
		inout.op_mode = buffer[2];
		inout.target_torque = buffer[4] << 8 | buffer[3];
		inout.target_position = buffer[8] << 24 | buffer[7] << 16 | buffer[6] << 8 | buffer[5];
		inout.target_velocity = buffer[12] << 24 | buffer[11] << 16 | buffer[10] << 8 | buffer[9];
		inout.offset_torque = buffer[16] << 24 | buffer[15] << 16 | buffer[14] << 8 | buffer[13];
		inout.tuning_status = buffer[20] << 24 | buffer[19] << 16 | buffer[18] << 8 | buffer[17];
		inout.tuning_control = buffer[24] << 24 | buffer[23] << 16 | buffer[22] << 8 | buffer[21];
		inout.command_pid_update = buffer[28] << 24 | buffer[27] << 16 | buffer[26] << 8 | buffer[25];
	}

	size_t pdo_count = 0;
	if(count > 0)
	{
		buffer[0] = inout.statusword;
		buffer[1] = inout.statusword >> 8;
		buffer[2] = inout.op_mode_display;
		buffer[3] = inout.position_value;
		buffer[4] = inout.position_value >> 8;
		buffer[5] = inout.position_value >> 16;
		buffer[6] = inout.position_value >> 24;
		buffer[7] = inout.velocity_value;
		buffer[8] = inout.velocity_value >> 8;
		buffer[9] = inout.velocity_value >> 16;
		buffer[10] = inout.velocity_value >> 24;
		buffer[11] = inout.torque_value;
		buffer[12] = inout.torque_value >> 8;
		buffer[13] = inout.additional_feedbacksensor_value;
		buffer[14] = inout.additional_feedbacksensor_value >> 8;
		buffer[15] = inout.additional_feedbacksensor_value >> 16;
		buffer[16] = inout.additional_feedbacksensor_value >> 24;
		buffer[17] = inout.tuning_result;
		buffer[18] = inout.tuning_result >> 8;
		buffer[19] = inout.tuning_result >> 16;
		buffer[20] = inout.tuning_result >> 24;

                pdo_count = 21;
		i_pdo.set_pdos_value(buffer, pdo_count);
	}
	return count;
}

int pdo_get_target_torque(pdo_handler_values_t InOut)
{
    return InOut.target_torque;
}

int pdo_get_target_velocity(pdo_handler_values_t InOut)
{
    return InOut.target_velocity;
}

int pdo_get_target_position(pdo_handler_values_t InOut)
{
    return InOut.target_position;
}

int pdo_get_controlword(pdo_handler_values_t InOut)
{
    return InOut.controlword;
}

int pdo_get_opmode(pdo_handler_values_t InOut)
{
    return InOut.op_mode;
}

void pdo_set_torque_value(int actual_torque, pdo_handler_values_t &InOut)
{
    InOut.torque_value = actual_torque;
}

void pdo_set_velocity_value(int actual_velocity, pdo_handler_values_t &InOut)
{
    InOut.velocity_value = actual_velocity;
}

void pdo_set_position_value(int actual_position, pdo_handler_values_t &InOut)
{
    InOut.position_value = actual_position;
}

void pdo_set_statusword(int statusword, pdo_handler_values_t &InOut)
{
    InOut.statusword = statusword & 0xffff;
}

void pdo_set_opmode_display(int opmode, pdo_handler_values_t &InOut)
{
    InOut.op_mode_display = opmode & 0xff;
}

int pdo_get_offset_torque(pdo_handler_values_t &InOut)
{
    return InOut.offset_torque;
}

int pdo_get_tuning_status(pdo_handler_values_t &InOut)
{
    return InOut.tuning_status;
}

int pdo_get_tuning_control(pdo_handler_values_t &InOut)
{
    return InOut.tuning_control;
}

int pdo_get_command_pid_update(pdo_handler_values_t &InOut)
{
    return InOut.command_pid_update;
}

void pdo_set_tuning_result(int value, pdo_handler_values_t &InOut)
{
    InOut.tuning_result = value;
}

void pdo_set_additional_feedbacksensor_value(int value, pdo_handler_values_t &InOut)
{
    InOut.additional_feedbacksensor_value = value;
}

#if 0 /* DON'T COMMIT */
/* template for getter and setter functions to access PDOs */
int pdo_get_NAME(pdo_handler_values_t &InOut)
{
    return InOut.NAME;
}

void pdo_set_NAME(int value, pdo_handler_values &InOut)
{
    InOut.NAME = value;
}
#endif
