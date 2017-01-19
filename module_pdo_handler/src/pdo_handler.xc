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

	InOut.control_word    = 0x00;    		// shutdown
	InOut.operation_mode  = 0x00;  			// undefined

	InOut.target_torque   = 0x0;
	InOut.target_velocity = 0x0;
	InOut.target_position = 0x0;

	InOut.user1_in        = 0x0;
	InOut.user2_in        = 0x0;
	InOut.user3_in        = 0x0;
	InOut.user4_in        = 0x0;

	InOut.status_word     = 0x0000;  		// not set
	InOut.operation_mode_display = 0x00; 	/* no operation mode selected */

	InOut.torque_actual   = 0x0;
	InOut.velocity_actual = 0x0;
	InOut.position_actual = 0x0;

	InOut.user1_out       = 0x0;
	InOut.user2_out       = 0x0;
	InOut.user3_out       = 0x0;
	InOut.user4_out       = 0x0;

	return InOut;
}

int pdo_handler(client interface i_pdo_communication i_pdo, pdo_handler_values_t &InOut)
{

	unsigned char buffer[MAX_PDO_SIZE];
	unsigned int count = 0;

	count = i_pdo.get_pdos_value(buffer);

	//Test for matching number of words
	if(count > 0)
	{
		InOut.control_word    = (((uint16_t)buffer[1] << 8) | (buffer[0])) & 0xffff;
		InOut.operation_mode  = (int8_t)(buffer[2] & 0xff);
		InOut.target_torque   = (((int16_t)buffer[4] << 8)  | (buffer[3])) & 0xffff;
		InOut.target_position = ((int32_t)buffer[8]  << 24) | ((int32_t)buffer[7]  << 16) | ((int32_t)buffer[6]  << 8) | buffer[5];
		InOut.target_velocity = ((int32_t)buffer[12] << 24) | ((int32_t)buffer[11] << 16) | ((int32_t)buffer[10] << 8) | buffer[9];
		InOut.user1_in        = ((int32_t)buffer[16] << 24) | ((int32_t)buffer[15] << 16) | ((int32_t)buffer[14] << 8) | buffer[13];
		InOut.user2_in        = ((int32_t)buffer[20] << 24) | ((int32_t)buffer[19] << 16) | ((int32_t)buffer[18] << 8) | buffer[17];
		InOut.user3_in        = ((int32_t)buffer[24] << 24) | ((int32_t)buffer[23] << 16) | ((int32_t)buffer[22] << 8) | buffer[21];
		InOut.user4_in        = ((int32_t)buffer[28] << 24) | ((int32_t)buffer[27] << 16) | ((int32_t)buffer[26] << 8) | buffer[25];
#if 0
        printhexln(InOut.control_word);
        printhexln(InOut.operation_mode);
        printhexln(InOut.target_torque);
        printhexln(InOut.target_position);
        printhexln(InOut.target_velocity);
#endif
	}

	size_t pdo_count = 0;
	if(count > 0)
	{
		buffer[pdo_count++]  = InOut.status_word        & 0xff;
		buffer[pdo_count++]  = (InOut.status_word >> 8) & 0xff;

		buffer[pdo_count++]  = (InOut.operation_mode_display & 0xff);

		buffer[pdo_count++]  = InOut.position_actual         & 0xff;
		buffer[pdo_count++]  = (InOut.position_actual >> 8)  & 0xff;
		buffer[pdo_count++]  = (InOut.position_actual >> 16) & 0xff;
		buffer[pdo_count++]  = (InOut.position_actual >> 24) & 0xff;

		buffer[pdo_count++]  = InOut.velocity_actual         & 0xff;
		buffer[pdo_count++]  = (InOut.velocity_actual >> 8)  & 0xff;
		buffer[pdo_count++]  = (InOut.velocity_actual >> 16) & 0xff;
		buffer[pdo_count++] = (InOut.velocity_actual >> 24) & 0xff;

		buffer[pdo_count++] = InOut.torque_actual        & 0xff;
		buffer[pdo_count++] = (InOut.torque_actual >> 8) & 0xff;

		buffer[pdo_count++] = InOut.user1_out         & 0xff;
		buffer[pdo_count++] = (InOut.user1_out >> 8)  & 0xff;
		buffer[pdo_count++] = (InOut.user1_out >> 16) & 0xff;
		buffer[pdo_count++] = (InOut.user1_out >> 24) & 0xff;

		buffer[pdo_count++] = InOut.user2_out         & 0xff;
		buffer[pdo_count++] = (InOut.user2_out >> 8)  & 0xff;
		buffer[pdo_count++] = (InOut.user2_out >> 16) & 0xff;
		buffer[pdo_count++] = (InOut.user2_out >> 24) & 0xff;

		buffer[pdo_count++] = InOut.user3_out         & 0xff;
		buffer[pdo_count++] = (InOut.user3_out >> 8)  & 0xff;
		buffer[pdo_count++] = (InOut.user3_out >> 16) & 0xff;
		buffer[pdo_count++] = (InOut.user3_out >> 24) & 0xff;

		buffer[pdo_count++] = InOut.user4_out         & 0xff;
		buffer[pdo_count++] = (InOut.user4_out >> 8)  & 0xff;
		buffer[pdo_count++] = (InOut.user4_out >> 16) & 0xff;
		buffer[pdo_count++] = (InOut.user4_out >> 24) & 0xff;

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
    return InOut.control_word;
}

int pdo_get_opmode(pdo_handler_values_t InOut)
{
    return InOut.operation_mode;
}

void pdo_set_actual_torque(int actual_torque, pdo_handler_values_t &InOut)
{
    InOut.torque_actual = actual_torque;
}

void pdo_set_actual_velocity(int actual_velocity, pdo_handler_values_t &InOut)
{
    InOut.velocity_actual = actual_velocity;
}

void pdo_set_actual_position(int actual_position, pdo_handler_values_t &InOut)
{
    InOut.position_actual = actual_position;
}

void pdo_set_statusword(int statusword, pdo_handler_values_t &InOut)
{
    InOut.status_word = statusword & 0xffff;
}

void pdo_set_opmode_display(int opmode, pdo_handler_values_t &InOut)
{
    InOut.operation_mode_display = opmode & 0xff;
}
