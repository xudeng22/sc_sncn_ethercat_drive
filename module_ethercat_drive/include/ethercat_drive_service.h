/**
 * @file ethercat_drive_service.h
 * @brief EtherCAT Motor Drive Server
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <motor_control_interfaces.h>
#include <ethercat_service.h>

#include <motion_control_service.h>
#include <position_feedback_service.h>
#include <spiffs_service.h>

#include <profile_control.h>


/**
 * \brief Exchange object for object and entry description
 */
struct _sdoinfo_entry_description {
    uint16_t index; ///< 16 bit int should be sufficient
    uint8_t subindex; ///< 16 bit int should be sufficient
    uint8_t objectDataType;
    uint8_t dataType;
    uint8_t objectCode;
    uint8_t bitLength;
    uint16_t objectAccess;
    uint32_t value; ///< real data type is defined by .dataType
    uint8_t name[50];
};


/**
 * \brief Name of config file to store / read device configuration
 */
#define CONFIG_FILE_NAME "config.csv"


#define MAX_TIME_TO_WAIT_SDO      100000

/**
 * \brief OD definitions
 */
#ifndef CANOD_TYPE_VAR
#define CANOD_TYPE_VAR        0x7
#endif

#define MAX_CONFIG_SDO_ENTRIES   250

typedef interface SDO_Config SDO_Config;


interface SDO_Config {

    [[guarded]] int write_od_config(void);

    [[guarded]] int read_od_config(void);

};


/**
 * @brief This Service enables motor drive functions via EtherCAT.
 *
 * @param profiler_config Configuration for profile mode control.
 * @param i_pdo Channel to send and receive information to EtherCAT Service.
 * @param i_coe Channel to receive motor configuration information from EtherCAT Service.
 * @param i_torque_control Interface to Motor Control Service
 * @param i_motion_control Interface to Motion Control Service.
 * @param i_position_feedback_1 Interface to the fisrt sensor service
 * @param i_position_feedback_2 Interface to the second sensor service
 */
void ethercat_drive_service(server SDO_Config sdo_config,
                            ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback_1,
                            client interface PositionFeedbackInterface ?i_position_feedback_2,
                            client SPIFFSInterface i_spiffs);

void ethercat_drive_service_debug(server SDO_Config sdo_config,
                            ProfilerConfig &profiler_config,
                            client interface i_pdo_communication i_pdo,
                            client interface i_coe_communication i_coe,
                            client interface TorqueControlInterface i_torque_control,
                            client interface MotionControlInterface i_motion_control,
                            client interface PositionFeedbackInterface i_position_feedback,
                            client SPIFFSInterface i_spiffs);
