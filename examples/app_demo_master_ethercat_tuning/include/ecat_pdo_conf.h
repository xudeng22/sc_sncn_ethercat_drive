/**
 * ecat_pdo_conf.h
 *
 * PDO configuration types
 *
 * 2016-05-24 Frank Jeschke <fjeschke@synapticon.com>
 */

#ifndef ECAT_PDO_CONF_H
#define ECAT_PDO_CONF_H

struct _pdo_offset {
    /* outputs */
    unsigned int controlword;
    unsigned int opmode;
    unsigned int target_torque;
    unsigned int target_position;
    unsigned int target_velocity;
    unsigned int user1_out;
    unsigned int user2_out;
    unsigned int user3_out;
    unsigned int user4_out;
    /* inputs */
    unsigned int statusword;
    unsigned int opmode_display;
    unsigned int position_value;
    unsigned int velocity_value;
    unsigned int torque_value;
    unsigned int user1_in;
    unsigned int user2_in;
    unsigned int user3_in;
    unsigned int user4_in;
};

#endif /* ECAT_PDO_CONF_H */
