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
		inout.tuning_command = buffer[20] << 24 | buffer[19] << 16 | buffer[18] << 8 | buffer[17];
		inout.digital_output1 = buffer[21];
		inout.digital_output2 = buffer[22];
		inout.digital_output3 = buffer[23];
		inout.digital_output4 = buffer[24];
		inout.user_mosi = buffer[28] << 24 | buffer[27] << 16 | buffer[26] << 8 | buffer[25];
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
		buffer[13] = inout.secondary_position_value;
		buffer[14] = inout.secondary_position_value >> 8;
		buffer[15] = inout.secondary_position_value >> 16;
		buffer[16] = inout.secondary_position_value >> 24;
		buffer[17] = inout.secondary_velocity_value;
		buffer[18] = inout.secondary_velocity_value >> 8;
		buffer[19] = inout.secondary_velocity_value >> 16;
		buffer[20] = inout.secondary_velocity_value >> 24;
		buffer[21] = inout.analog_input1;
		buffer[22] = inout.analog_input1 >> 8;
		buffer[23] = inout.analog_input2;
		buffer[24] = inout.analog_input2 >> 8;
		buffer[25] = inout.analog_input3;
		buffer[26] = inout.analog_input3 >> 8;
		buffer[27] = inout.analog_input4;
		buffer[28] = inout.analog_input4 >> 8;
		buffer[29] = inout.tuning_status;
		buffer[30] = inout.tuning_status >> 8;
		buffer[31] = inout.tuning_status >> 16;
		buffer[32] = inout.tuning_status >> 24;
		buffer[33] = inout.digital_input1;
		buffer[35] = inout.digital_input2;
		buffer[37] = inout.digital_input3;
		buffer[39] = inout.digital_input4;
		buffer[41] = inout.user_miso;
		buffer[42] = inout.user_miso >> 8;
		buffer[43] = inout.user_miso >> 16;
		buffer[44] = inout.user_miso >> 24;

		pdo_count = 45;
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

int pdo_get_tuning_command(pdo_handler_values_t &InOut)
{
    return InOut.tuning_command;
}

int pdo_get_dgitial_output1(pdo_handler_values_t &InOut)
{
    return InOut.digital_output1;
}

int pdo_get_dgitial_output2(pdo_handler_values_t &InOut)
{
    return InOut.digital_output2;
}

int pdo_get_dgitial_output3(pdo_handler_values_t &InOut)
{
    return InOut.digital_output3;
}

int pdo_get_dgitial_output4(pdo_handler_values_t &InOut)
{
    return InOut.digital_output4;
}

int pdo_get_user_mosi(pdo_handler_values_t &InOut)
{
    return InOut.user_mosi;
}

void pdo_set_secondary_position_value(int value, pdo_handler_values_t &InOut)
{
    InOut.secondary_position_value = value;
}

void pdo_set_secondary_velocity_value(int value, pdo_handler_values_t &InOut)
{
    InOut.secondary_velocity_value = value;
}

void pdo_set_analog_input1(int value, pdo_handler_values_t &InOut)
{
    InOut.analog_input1 = value;
}

void pdo_set_analog_input2(int value, pdo_handler_values_t &InOut)
{
    InOut.analog_input2 = value;
}

void pdo_set_analog_input3(int value, pdo_handler_values_t &InOut)
{
    InOut.analog_input3 = value;
}

void pdo_set_analog_input4(int value, pdo_handler_values_t &InOut)
{
    InOut.analog_input4 = value;
}

void pdo_set_tuning_status(int value, pdo_handler_values_t &InOut)
{
    InOut.tuning_status = value;
}

void pdo_set_digital_input1(int value, pdo_handler_values_t &InOut)
{
    InOut.digital_input1 = value;
}

void pdo_set_digital_input2(int value, pdo_handler_values_t &InOut)
{
    InOut.digital_input2 = value;
}

void pdo_set_digital_input3(int value, pdo_handler_values_t &InOut)
{
    InOut.digital_input3 = value;
}

void pdo_set_digital_input4(int value, pdo_handler_values_t &InOut)
{
    InOut.digital_input4 = value;
}

void pdo_set_user_miso(int value, pdo_handler_values_t &InOut)
{
    InOut.user_miso = value;
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
