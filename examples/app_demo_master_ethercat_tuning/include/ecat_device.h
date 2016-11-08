#ifndef ECAT_DEVICE_H
#define ECAT_DEVICE_H

/* Master 0, Slave 0, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

#ifdef __cplusplus
extern "C" {
#endif

ec_pdo_entry_info_t slave_0_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_0_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_0_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};

/* Master 0, Slave 1, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

ec_pdo_entry_info_t slave_1_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_1_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_1_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};


/* Master 0, Slave 2, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

ec_pdo_entry_info_t slave_2_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_2_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_2_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};

/* Master 0, Slave 3, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

ec_pdo_entry_info_t slave_3_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_3_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_3_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};

/* Master 0, Slave 4, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

ec_pdo_entry_info_t slave_4_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_4_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_4_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};

/* Master 0, Slave 5, "CiA402 Motor Control Device"
 * Vendor ID:       0x000022d2
 * Product code:    0x00000201
 * Revision number: 0x0a000002
 */

ec_pdo_entry_info_t slave_5_pdo_entries[] = {
    {0x6040, 0x00, 16}, /* Controlword */
    {0x6060, 0x00, 8}, /* Op Mode */
    {0x6071, 0x00, 16}, /* Target Torque */
    {0x607a, 0x00, 32}, /* Target Position */
    {0x60ff, 0x00, 32}, /* Target Velocity */
    {0x4010, 0x00, 32}, /* User Value 1 */
    {0x4020, 0x00, 32}, /* User Value 2 */
    {0x4030, 0x00, 32}, /* User Value 3 */
    {0x4040, 0x00, 32}, /* User Value 4 */
    {0x6041, 0x00, 16}, /* Statusword */
    {0x6061, 0x00, 8}, /* Operating mode */
    {0x6064, 0x00, 32}, /* Position Value */
    {0x606c, 0x00, 32}, /* Velocity Value */
    {0x6077, 0x00, 16}, /* Torque Value */
    {0x4011, 0x00, 32}, /* User Value 1 */
    {0x4021, 0x00, 32}, /* User Value 2 */
    {0x4031, 0x00, 32}, /* User Value 3 */
    {0x4041, 0x00, 32}, /* User Value 4 */
};

ec_pdo_info_t slave_5_pdos[] = {
    {0x1600, 9, slave_0_pdo_entries + 0}, /* Rx PDO Mapping */
    {0x1a00, 9, slave_0_pdo_entries + 9}, /* Tx PDO Mapping */
};

ec_sync_info_t slave_5_syncs[] = {
    {0, EC_DIR_OUTPUT, 0, NULL, EC_WD_DISABLE},
    {1, EC_DIR_INPUT, 0, NULL, EC_WD_DISABLE},
    {2, EC_DIR_OUTPUT, 1, slave_0_pdos + 0, EC_WD_DISABLE},
    {3, EC_DIR_INPUT, 1, slave_0_pdos + 1, EC_WD_DISABLE},
    {0xff}
};

#ifdef __cplusplus
}
#endif


#endif /* ECAT_DEVICE_H */
