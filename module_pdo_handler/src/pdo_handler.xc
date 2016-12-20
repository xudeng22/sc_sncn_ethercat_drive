/**
 * @file pdo_handler.xc
 * @brief Control Protocol PDO Parser
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <pdo_handler.h>
#include <stdint.h>
//#include <foefs.h>

#define MAX_PDO_SIZE    15

pdo_values_t pdo_init(void)
{
	pdo_values_t InOut;

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

	InOut.actual_torque   = 0x0;
	InOut.actual_velocity = 0x0;
	InOut.actual_position = 0x0;

	InOut.user1_out       = 0x0;
	InOut.user2_out       = 0x0;
	InOut.user3_out       = 0x0;
	InOut.user4_out       = 0x0;

	return InOut;
}


int pdo_protocol_handler(chanend pdo_out, chanend pdo_in, pdo_values_t &InOut)
{

    int buffer[64];
    unsigned int count = 0;
    int i = 0;


    pdo_in <: DATA_REQUEST;
    pdo_in :> count;
//  printstr("count  "); printintln(count);
    if (count == 0)
        return 0;

    for (i = 0; i < count; i++) {
        pdo_in :> buffer[i];
        //printhexln(buffer[i]);
    }

    //Test for matching number of words
    if(count > 0)
    {
        InOut.control_word    = (buffer[0]) & 0xffff;
        InOut.operation_mode  = buffer[1] & 0xff;
        InOut.target_torque   = ((buffer[2]<<8 & 0xff00) | (buffer[1]>>8 & 0xff)) & 0x0000ffff;
        InOut.target_position = ((buffer[4]&0x00ff)<<24 | buffer[3]<<8 | (buffer[2] & 0xff00)>>8 )&0xffffffff;
        InOut.target_velocity = (buffer[6]<<24 | buffer[5]<<8 |  (buffer[4]&0xff00) >> 8)&0xffffffff;
        InOut.user1_in        = ((buffer[8]&0xff)<<24)  | ((buffer[7]&0xffff)<<8)  | ((buffer[6]>>8)&0xff);
        InOut.user2_in        = ((buffer[10]&0xff)<<24) | ((buffer[9]&0xffff)<<8)  | ((buffer[8]>>8)&0xff);
        InOut.user3_in        = ((buffer[12]&0xff)<<24) | ((buffer[11]&0xffff)<<8) | ((buffer[10]>>8)&0xff);
        InOut.user4_in        = ((buffer[14]&0xff)<<24) | ((buffer[13]&0xffff)<<8) | ((buffer[12]>>8)&0xff);
//      printhexln(InOut.control_word);
//      printhexln(InOut.operation_mode);
//      printhexln(InOut.target_torque);
//      printhexln(InOut.target_position);
//      printhexln(InOut.target_velocity);
    }

    if(count > 0)
    {
        pdo_out <: MAX_PDO_SIZE;
        buffer[0]  = InOut.status_word ;
        buffer[1]  = ((InOut.operation_mode_display&0xff) | (InOut.actual_position&0xff)<<8) ;
        buffer[2]  = (InOut.actual_position>> 8)& 0xffff;
        buffer[3]  = ((InOut.actual_position>>24) & 0xff) | ((InOut.actual_velocity&0xff)<<8);
        buffer[4]  = (InOut.actual_velocity>> 8)& 0xffff;
        buffer[5]  = ((InOut.actual_velocity>>24) & 0xff) | ((InOut.actual_torque&0xff)<<8) ;
        buffer[6]  = ((InOut.user1_out<<8)&0xff00) | ((InOut.actual_torque >> 8)&0xff);
        buffer[7]  = ((InOut.user1_out>>8)&0xffff);
        buffer[8]  = ((InOut.user2_out<<8)&0xff00) | ((InOut.user1_out>>24)&0xff);
        buffer[9]  = ((InOut.user2_out>>8)&0xffff);
        buffer[10] = ((InOut.user3_out<<8)&0xff00) | ((InOut.user2_out>>24)&0xff);
        buffer[11] = ((InOut.user3_out>>8)&0xffff);
        buffer[12] = ((InOut.user4_out<<8)&0xff00) | ((InOut.user3_out>>24)&0xff);
        buffer[13] = ((InOut.user4_out>>8)&0xffff);
        buffer[14] = ((InOut.user4_out>>24)&0xff);
        for (i = 0; i < MAX_PDO_SIZE; i++)
        {
            pdo_out <: (unsigned) buffer[i];
        }
    }
    return count;
}

int pdo_get_target_torque(pdo_values_t InOut)
{
    return InOut.target_torque;
}

int pdo_get_target_velocity(pdo_values_t InOut)
{
    return InOut.target_velocity;
}

int pdo_get_target_position(pdo_values_t InOut)
{
    return InOut.target_position;
}

int pdo_get_controlword(pdo_values_t InOut)
{
    return InOut.control_word;
}

int pdo_get_opmode(pdo_values_t InOut)
{
    return InOut.operation_mode;
}

void pdo_set_actual_torque(int actual_torque, pdo_values_t &InOut)
{
    InOut.actual_torque = actual_torque;
}

void pdo_set_actual_velocity(int actual_velocity, pdo_values_t &InOut)
{
    InOut.actual_velocity = actual_velocity;
}

void pdo_set_actual_position(int actual_position, pdo_values_t &InOut)
{
    InOut.actual_position = actual_position;
}

void pdo_set_statusword(int statusword, pdo_values_t &InOut)
{
    InOut.status_word = statusword & 0xffff;
}

void pdo_set_opmode_display(int opmode, pdo_values_t &InOut)
{
    InOut.operation_mode_display = opmode & 0xff;
}
