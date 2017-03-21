#ifndef DICTIONARY_H_
#define DICTIONARY_H_

#ifdef COM_CAN

#define NUMBER_OF_SUBINDEX 189
#define PDO_COUNT 4

struct _sdoinfo_entry_description SDO_Info_Entries[] = {
{ 0x1000, 0x0, 0, 0x7, 0x7, 32, RO, 0x20192, "Device Type" },
{ 0x1001, 0x0, 0, 0x5, 0x7,  8, RO, 0x00, "Error Register" },
{ 0x1018, 0x0, 0, 0x5, 0x7,  8, RO, 4, "Number of entries" },
{ 0x1018, 0x1, 0, 0x7, 0x7, 32, RO, 0x22d2, "Vendor Id" },
{ 0x1018, 0x2, 0, 0x7, 0x7, 32, RO, 0x0301, "Product Code" },
{ 0x1018, 0x3, 0, 0x7, 0x7, 32, RO, 0xAABB, "Revision number" },
{ 0x1018, 0x4, 0, 0x7, 0x7, 32, RO, 0x1111, "Serial number" },
{ 0x1003, 0x0, 0, 0x5, 0x7,  8, RW, 1, "Number of Errors" },
{ 0x1003, 0x1, 0, 0x7, 0x7, 32, RO, 0xDEADDEAD, "Standard Error Field" },
{ 0x1005, 0x0, 0, 0x7, 0x7, 32, RW, 0x00000080, "COB-ID SYNC Message" },
{ 0x1006, 0x0, 0, 0x7, 0x7, 32, RW, 0x30, "Communication Cycle Period" },
{ 0x1007, 0x0, 0, 0x7, 0x7, 32, RW, 100, "Synchronous Window Length" },
{ 0x100C, 0x0, 0, 0x6, 0x7, 16, RW, 0, "Guard Time" },
{ 0x100D, 0x0, 0, 0x5, 0x7,  8, RW, 0x00, "Life Time Factor" },
{ 0x1017, 0x0, 0, 0x6, 0x7, 16, RW, 1000, "Producer Heartbeat Time" },
{ 0x1019, 0x0, 0, 0x5, 0x7,  8, RW, 0, "Synchronous counter overflow value" },
{ 0x1200, 0x0, 0, 0x5, 0x7,  8, RO, 2, "Number of entries" },
{ 0x1200, 0x1, 0, 0x7, 0x7, 32, RO, 0x600, "COB ID Client to Server" },
{ 0x1200, 0x2, 0, 0x7, 0x7, 32, RO, 0x580, "COB ID Server to Client" },
{ 0x1400, 0x0, 0, 0x5, 0x7,  8, RO, 5, "Number of entries" },
{ 0x1400, 0x1, 0, 0x7, 0x7, 32, RW, 0x200, "COB ID" },
{ 0x1400, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1400, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1400, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1400, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1401, 0x0, 0, 0x5, 0x7,  8, RO, 5, "Number of entries" },
{ 0x1401, 0x1, 0, 0x7, 0x7, 32, RW, 0x300, "COB ID" },
{ 0x1401, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1401, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1401, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1401, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1402, 0x0, 0, 0x5, 0x7,  8, RO, 5, "Number of entries" },
{ 0x1402, 0x1, 0, 0x7, 0x7, 32, RW, 0x400, "COB ID" },
{ 0x1402, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1402, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1402, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1402, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1403, 0x0, 0, 0x5, 0x7,  8, RO, 5, "Number of entries" },
{ 0x1403, 0x1, 0, 0x7, 0x7, 32, RW, 0x500, "COB ID" },
{ 0x1403, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1403, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1403, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1403, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1600, 0x0, 0, 0x5, 0x7,  8, RW, 3, "Number of entries" },
{ 0x1600, 0x1, 0, 0x7, 0x7, 32, RW, 0x60400110, "PDO Mapping Entry" },
{ 0x1600, 0x2, 0, 0x7, 0x7, 32, RW, 0x60600108, "PDO Mapping Entry" },
{ 0x1600, 0x3, 0, 0x7, 0x7, 32, RW, 0x60710110, "PDO Mapping Entry" },
{ 0x1601, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1601, 0x1, 0, 0x7, 0x7, 32, RW, 0x607A0120, "PDO Mapping Entry" },
{ 0x1601, 0x2, 0, 0x7, 0x7, 32, RW, 0x60FF0120, "PDO Mapping Entry" },
{ 0x1602, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1602, 0x1, 0, 0x7, 0x7, 32, RW, 0x40100120, "PDO Mapping Entry" },
{ 0x1602, 0x2, 0, 0x7, 0x7, 32, RW, 0x40200120, "PDO Mapping Entry" },
{ 0x1603, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1603, 0x1, 0, 0x7, 0x7, 32, RW, 0x40300120, "PDO Mapping Entry" },
{ 0x1603, 0x2, 0, 0x7, 0x7, 32, RW, 0x40400120, "PDO Mapping Entry" },
{ 0x1800, 0x0, 0, 0x5, 0x7,  8, RO, 6, "Number of entries" },
{ 0x1800, 0x1, 0, 0x7, 0x7, 32, RO, 0x40000180, "COB ID" },
{ 0x1800, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1800, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1800, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1800, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1800, 0x6, 0, 0x5, 0x7,  8, RW, 0, "SYNC start value" },
{ 0x1801, 0x0, 0, 0x5, 0x7,  8, RO, 6, "Number of entries" },
{ 0x1801, 0x1, 0, 0x7, 0x7, 32, RO, 0x40000280, "COB ID" },
{ 0x1801, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1801, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1801, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1801, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1801, 0x6, 0, 0x5, 0x7,  8, RW, 0, "SYNC start value" },
{ 0x1802, 0x0, 0, 0x5, 0x7,  8, RO, 6, "Number of entries" },
{ 0x1802, 0x1, 0, 0x7, 0x7, 32, RO, 0x40000380, "COB ID" },
{ 0x1802, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1802, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1802, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1802, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1802, 0x6, 0, 0x5, 0x7,  8, RW, 0, "SYNC start value" },
{ 0x1803, 0x0, 0, 0x5, 0x7,  8, RO, 6, "Number of entries" },
{ 0x1803, 0x1, 0, 0x7, 0x7, 32, RO, 0x40000480, "COB ID" },
{ 0x1803, 0x2, 0, 0x5, 0x7,  8, RW, 255, "Transmission Type" },
{ 0x1803, 0x3, 0, 0x6, 0x7, 16, RW, 0x0000, "Inhibit Time" },
{ 0x1803, 0x4, 0, 0x5, 0x7,  8, RW, 0, "Compatibility Entry" },
{ 0x1803, 0x5, 0, 0x6, 0x7, 16, RW, 5, "Event Timer" },
{ 0x1803, 0x6, 0, 0x5, 0x7,  8, RW, 0, "SYNC start value" },
{ 0x1A00, 0x0, 0, 0x5, 0x7,  8, RW, 3, "Number of entries" },
{ 0x1A00, 0x1, 0, 0x7, 0x7, 32, RW, 0x60410110, "PDO Mapping Entry" },
{ 0x1A00, 0x2, 0, 0x7, 0x7, 32, RW, 0x60610108, "PDO Mapping Entry" },
{ 0x1A00, 0x3, 0, 0x7, 0x7, 32, RW, 0x60770110, "PDO Mapping Entry" },
{ 0x1A01, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1A01, 0x1, 0, 0x7, 0x7, 32, RW, 0x60640120, "PDO Mapping Entry" },
{ 0x1A01, 0x2, 0, 0x7, 0x7, 32, RW, 0x606C0120, "PDO Mapping Entry" },
{ 0x1A02, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1A02, 0x1, 0, 0x7, 0x7, 32, RW, 0x40110120, "PDO Mapping Entry" },
{ 0x1A02, 0x2, 0, 0x7, 0x7, 32, RW, 0x40210120, "PDO Mapping Entry" },
{ 0x1A03, 0x0, 0, 0x5, 0x7,  8, RW, 2, "Number of entries" },
{ 0x1A03, 0x1, 0, 0x7, 0x7, 32, RW, 0x40310120, "PDO Mapping Entry" },
{ 0x1A03, 0x2, 0, 0x7, 0x7, 32, RW, 0x40410120, "PDO Mapping Entry" },
{ 0x6040, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6040, 0x1, 0, 0x6, 0x7, 16, RO, 0xCAFE, "Control word" },
{ 0x6041, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6041, 0x1, 0, 0x6, 0x7, 16, RO, 0xABBA, "Status word" },
{ 0x6060, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6060, 0x1, 0, 0x2, 0x7,  8, RO, 0xCD, "Operation Mode" },
{ 0x6061, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6061, 0x1, 0, 0x2, 0x7,  8, RO, 0xCD, "Operation Mode Display" },
{ 0x6064, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6064, 0x1, 0, 0x4, 0x7, 32, RO, 0xDEADBEEF, "Position actual" },
{ 0x6065, 0x0, 0, 0x7, 0x7, 32, RW, 0x00000000, "Following Error Window" },
{ 0x6066, 0x0, 0, 0x6, 0x7, 16, RW, 0x0000, "Following Error Timeout" },
{ 0x606A, 0x0, 0, 0x3, 0x7, 16, RW, 0x0000, "SensorSelectionMode" },
{ 0x606C, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x606C, 0x1, 0, 0x4, 0x7, 32, RO, 0xDEADBEEF, "Velocity actual" },
{ 0x6071, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6071, 0x1, 0, 0x3, 0x7, 16, RW, 0xDEADBEEF, "Torque target" },
{ 0x6072, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "MaxTorque" },
{ 0x6073, 0x0, 0, 0x3, 0x7, 16, RW, 0x0000, "MaxCurrent" },
{ 0x6075, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "Motor Rated Current" },
{ 0x6076, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "Motor Rated Torque" },
{ 0x6077, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x6077, 0x1, 0, 0x3, 0x7, 16, RO, 0xDEADBEEF, "Torque actual" },
{ 0x607A, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x607A, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "Position target" },
{ 0x607B, 0x0, 0, 0x8, 0x8, 32, RW, 0x02, "Number of Entries" },
{ 0x607B, 0x1, 0, 0x4, 0x8, 32, RW, 0x00000000, "Neg Position Range Limits" },
{ 0x607B, 0x2, 0, 0x4, 0x8, 32, RW, 0x00000000, "Pos Position Range Limits" },
{ 0x607D, 0x0, 0, 0x8, 0x8, 32, RW, 0x02, "Number of Entries" },
{ 0x607D, 0x1, 0, 0x4, 0x8, 32, RW, 0x00000000, "Neg Max Software Position Range Limit" },
{ 0x607D, 0x2, 0, 0x4, 0x8, 32, RW, 0x00000000, "Pos Max Software Position Range Limit" },
{ 0x607E, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "Polarity" },
{ 0x607F, 0x0, 0, 0x4, 0x7, 32, RW, 0, "Max Profile Velocity" },
{ 0x6080, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "Max Motor Speed" },
{ 0x6081, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "ProfileVelocity" },
{ 0x6083, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "ProfileAcceleration" },
{ 0x6084, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "ProfileDeceleration" },
{ 0x6085, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "QuickStopDeceleration" },
{ 0x6087, 0x0, 0, 0x7, 0x7, 32, RW, 0x00000000, "TorqueSlope" },
{ 0x608F, 0x0, 0, 0x6, 0x7, 16, RW, 0x2000, "PositionEncoderResolution" },
{ 0x6091, 0x0, 0, 0x3, 0x7, 16, RW, 0x0000, "GearRatio" },
{ 0x6098, 0x0, 0, 0x2, 0x7,  8, RW, 0x00, "HomingMethod" },
{ 0x6099, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "HomingSpeed" },
{ 0x609A, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "HomingAcceleration" },
{ 0x60B0, 0x0, 0, 0x7, 0x7, 32, RW, 0x00000000, "PostionOffset" },
{ 0x60B1, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "VelocityOffset" },
{ 0x60B2, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "TorqueOffset" },
{ 0x60C5, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "MaxAcceleration" },
{ 0x60F4, 0x0, 0, 0x4, 0x7, 32, RW, 0x00000000, "FollowingError" },
{ 0x60FF, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x60FF, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "Velocity target" },
{ 0x6402, 0x0, 0, 0x6, 0x7, 16, RW, 0x0000, "MotorType" },
{ 0x6502, 0x0, 0, 0x7, 0x7, 32, RO, 0x00000700, "Supported Drive Modes" },
{ 0x2001, 0x0, 0, 0x3, 0x7, 16, RW, 960, "Commutation Offset Clockwise" },
{ 0x2002, 0x0, 0, 0x3, 0x7, 16, RW, 0, "Commutation Offset Counter Clockwise" },
{ 0x2003, 0x0, 0, 0x2, 0x7,  8, RW, 0, "Motor Winding Type" },
{ 0x2004, 0x0, 0, 0x3, 0x7, 16, RW, 1, "Position Sensor Polarity" },
{ 0x20F6, 0x0, 0, 0x8, 0x8, 32, RO, 3, "Number of Entries" },
{ 0x20F6, 0x1, 0, 0x4, 0x8, 32, RW, 0, "Current P-Gain" },
{ 0x20F6, 0x2, 0, 0x4, 0x8, 32, RW, 0, "Current I-Gain" },
{ 0x20F6, 0x3, 0, 0x4, 0x8, 32, RW, 0, "Current D-Gain" },
{ 0x20F9, 0x0, 0, 0x8, 0x8, 32, RO, 3, "Number of Entries" },
{ 0x20F9, 0x1, 0, 0x4, 0x8, 32, RW, 0, "Velocity P-Gain" },
{ 0x20F9, 0x2, 0, 0x4, 0x8, 32, RW, 0, "Velocity I-Gain" },
{ 0x20F9, 0x3, 0, 0x4, 0x8, 32, RW, 0, "Velocity D-Gain" },
{ 0x20FB, 0x0, 0, 0x8, 0x8, 32, RO, 3, "Number of Entries" },
{ 0x20FB, 0x1, 0, 0x4, 0x8, 32, RW, 11000, "Position P-Gain" },
{ 0x20FB, 0x2, 0, 0x4, 0x8, 32, RW, 4000, "Position I-Gain" },
{ 0x20FB, 0x3, 0, 0x4, 0x8, 32, RW, 40000, "Position D-Gain" },
{ 0x2410, 0x0, 0, 0x8, 0x8, 32, RO, 6, "Number of Entries" },
{ 0x2410, 0x1, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific Nominal Current" },
{ 0x2410, 0x2, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific Phase Resistance" },
{ 0x2410, 0x3, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific pole pair number" },
{ 0x2410, 0x4, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific Max Speed" },
{ 0x2410, 0x5, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific Phase Inductance" },
{ 0x2410, 0x6, 0, 0x4, 0x8, 32, RW, 0, "Motor Specific Torque Constant" },
{ 0x4010, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4010, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO In 1" },
{ 0x4011, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4011, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO Out 1" },
{ 0x4020, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4020, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO In 2" },
{ 0x4021, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4021, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO Out 2" },
{ 0x4030, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4030, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO In 3" },
{ 0x4031, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4031, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO Out 3" },
{ 0x4040, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4040, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO In 4" },
{ 0x4041, 0x0, 0, 0x5, 0x7,  8, RO, 1, "Number of Elements" },
{ 0x4041, 0x1, 0, 0x4, 0x7, 32, RW, 0xDEADBEEF, "User PDO Out 4" },
{ 0, 0, 0, 0, 0, 0, 0, 0, "\0" }
};

#elif COM_ETHERCAT

#define CIA402
#define USER_DEFINED_PDOS     1
#define PDO_COUNT             5

#if USER_DEFINED_PDOS == 1
#undef PDO_COUNT
#define PDO_COUNT             9
#endif

struct _sdoinfo_entry_description SDO_Info_Entries[] = {
    /* device type value: Mode bits (8bits) | type (8bits) | device profile number (16bits)
     *                    *                 | 0x02 (Servo) | 0x0192
     *
     * Mode Bits: csp, csv, cst
     */
#if 0
    { 0x1000, 0, DEFTYPE_UNSIGNED32, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x0007, 0x00000000, "Device Type" }, /* FIXME why is this entry not readable in opmode */
    { 0x1000, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x0007, 0x70020192, "Device Type" }, /* FIXME why is this entry not readable in opmode */
#endif
    { 0x1000, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x0007, 0x00020192, "Device Type" }, /* FIXME why is this entry not readable in opmode */
    { 0x1001, 0, 0, DEFTYPE_UNSIGNED8, CANOD_TYPE_VAR, 8, 0x0007, 0x00,  "Error Register" },
    /* identity object */
    { 0x1018, 0, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED8,  CANOD_TYPE_RECORD,  8, 0x0007, 4, "Identity" },
    { 0x1018, 1, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x000022d2, "Vendor ID" }, /* Vendor ID (by ETG) */
    { 0x1018, 2, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x00000201, "Product code" }, /* Product Code */
    { 0x1018, 3, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x0a000002, "Revision" }, /* Revision Number */
    { 0x1018, 4, DEFSTRUCT_IDENTITY, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD, 32, 0x0007, 0x00000000, "Serialnumber" }, /* Serial Number */
#ifndef ETHERCAT_BOOTMANAGER
#if 1
    /* RxPDO Mapping */
    { 0x1600, 0, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD,  8, 0x0007, PDO_COUNT, "SubIndex 000" }, /* input */
    { 0x1600, 1, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_CONTROLWORD,0,16), "Controlword" },
    { 0x1600, 2, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_OP_MODES,0,8), "Op Mode" },
    { 0x1600, 3, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_TORQUE,0,16), "Target Torque" },
    { 0x1600, 4, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_POSITION,0,32), "Target Position" },
    { 0x1600, 5, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TARGET_VELOCITY,0,32), "Target Velocity" },
#if USER_DEFINED_PDOS == 1
    { 0x1600, 6, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_1,0,32), "User RX 1" },
    { 0x1600, 7, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_2,0,32), "User RX 2" },
    { 0x1600, 8, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_3,0,32), "User RX 3" },
    { 0x1600, 9, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_IN_4,0,32), "User RX 4" },
#endif
    /* TxPDO Mapping */
    { 0x1A00, 0, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD,  8, 0x0007, PDO_COUNT, "SubIndex 000" }, /* output */
    { 0x1A00, 1, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_STATUSWORD,0,16), "Statusword" },
    { 0x1A00, 2, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_OP_MODES_DISP,0,8), "Op Mode Display" },
    { 0x1A00, 3, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_POSITION_VALUE,0,32), "Position Value" },
    { 0x1A00, 4, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_VELOCITY_VALUE,0,32), "Velocity Value" },
    { 0x1A00, 5, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(CIA402_TORQUE_VALUE,0,16), "Torque Value" },
#if USER_DEFINED_PDOS == 1
    { 0x1A00, 6, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_1,0,32), "User TX 1" },
    { 0x1A00, 7, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_2,0,32), "User TX 2" },
    { 0x1A00, 8, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_3,0,32), "User TX 3" },
    { 0x1A00, 9, DEFSTRUCT_PDO_MAPPING, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,  32, 0x0007, PDOMAPING(USER_PDO_OUT_4,0,32), "User TX 4" },
#endif
    /* SyncManager Communication Type */
    { 0x1C00, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 4, "SubIndex 000" },
    { 0x1C00, 1, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x01, "SyncMan 0" }, /* mailbox receive */
    { 0x1C00, 2, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x02, "SyncMan 1" }, /* mailbox send */
    { 0x1C00, 3, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x03, "SyncMan 2" }, /* PDO in (bufferd mode) */
    { 0x1C00, 4, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0x04, "SyncMan 3" }, /* PDO output (bufferd mode) */
    /* Tx PDO and Rx PDO assignments */
    { 0x1C10, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0, "SyncMan 0 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C11, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 0, "SyncMan 1 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C12, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 1, "SyncMan 2 Assignment"}, /* assignment of SyncMan 2 */
    { 0x1C12, 1, DEFTYPE_UNSIGNED16, DEFTYPE_UNSIGNED16, CANOD_TYPE_ARRAY, 16, 0x0007, 0x1600, "SyncMan 2 Assignment" },
    { 0x1C13, 0, DEFTYPE_UNSIGNED8, DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY, 8, 0x0007, 1, "SyncMan 3 assignment"}, /* assignment of SyncMan 3 */
    { 0x1C13, 1, DEFTYPE_UNSIGNED16, DEFTYPE_UNSIGNED16, CANOD_TYPE_ARRAY, 16, 0x0007, 0x1A00, "SyncMan 3 Assignment" },
    /* CiA objects */
    /* index, sub, value info, datatype, bitlength, object access, value, name */
    { CIA402_CONTROLWORD, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Controlword" }, /* map to PDO */
    { CIA402_STATUSWORD, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Statusword" },  /* map to PDO */
//  { CIA402_SUPPORTED_DRIVE_MODES, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x003f, 0x0280 /* csv, csp, cst */, "Supported drive modes" },
    { CIA402_OP_MODES, 0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR, 8, 0x003f, CIA402_OP_MODE_CSP, "Op Mode" },
    { CIA402_OP_MODES_DISP, 0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR, 8, 0x003f, CIA402_OP_MODE_CSP, "Operating mode" },
    { CIA402_POSITION_VALUE, 0, 0,  DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Position Value" }, /* csv, csp */
    { CIA402_FOLLOWING_ERROR_WINDOW, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Following Error Window"}, /* csp */
    { CIA402_FOLLOWING_ERROR_TIMEOUT, 0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Following Error Timeout"}, /* csp */
    { CIA402_VELOCITY_VALUE, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Velocity Value"}, /* csv */
    { CIA402_TARGET_TORQUE, 0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Target Torque"}, /* cst */
    { CIA402_TORQUE_VALUE, 0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR, 16, 0x003f, 0, "Torque Value"}, /* csv, cst */
    { CIA402_TARGET_POSITION, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Target Position" }, /* csp */
    { CIA402_POSITION_RANGELIMIT, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x0007, 2, "Postition Range Limits"}, /* csp */
    { CIA402_POSITION_RANGELIMIT, 1, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Min Postition Range Limit"},
    { CIA402_POSITION_RANGELIMIT, 2, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Max Postition Range Limit"},
    { CIA402_SOFTWARE_POSITION_LIMIT, 0, 0,  DEFTYPE_UNSIGNED8, CANOD_TYPE_ARRAY,  8, 0x0007, 2, "Software Postition Range Limits"}, /* csp */
    { CIA402_SOFTWARE_POSITION_LIMIT, 1, 0,  DEFTYPE_INTEGER32, CANOD_TYPE_ARRAY, 32, 0x003f, 0, "Min Software Postition Range Limit"},
    { CIA402_SOFTWARE_POSITION_LIMIT, 2, 0,  DEFTYPE_INTEGER32, CANOD_TYPE_ARRAY, 32, 0x003f, 0, "Max Software Postition Range Limit"},
    { CIA402_VELOCITY_OFFSET, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Velocity Offset" }, /* csp */
    { CIA402_TORQUE_OFFSET, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Torque Offset" }, /* csv, csp */
//  { CIA402_INTERPOL_TIME_PERIOD, 0, 0, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD, 8, 0x0007, 2, "Interpolation Time Period"}, /* csv, csp, cst */
//  { CIA402_INTERPOL_TIME_PERIOD, 1, 0, DEFTYPE_UNSIGNED8, CANOD_TYPE_RECORD, 8, 0x003f, 1, "Interpolation Time Unit"}, /* value range: 1..255msec */
//  { CIA402_INTERPOL_TIME_PERIOD, 2, 0, DEFTYPE_INTEGER8,  CANOD_TYPE_RECORD, 8, 0x003f, -3, "Interpolation Time Index"}, /* value range: -3, -4 (check!)*/
    { CIA402_FOLLOWING_ERROR,         0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Following Error" },
    { CIA402_TARGET_VELOCITY, 0, 0,  DEFTYPE_INTEGER32, CANOD_TYPE_VAR, 32, 0x003f, 0, "Target Velocity" }, /* csv */
    /* FIXME new objects, change description accordingly */
    { CIA402_SENSOR_SELECTION_CODE,   0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Sensor Selection Mode" },
    { CIA402_MAX_TORQUE,              0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Torque" },
    { CIA402_MAX_CURRENT,             0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Max Current" },
    { CIA402_MOTOR_RATED_CURRENT,     0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Motor Rated Current" },
    { CIA402_MOTOR_RATED_TORQUE,      0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Motor Rated Torque" },
    { CIA402_HOME_OFFSET,             0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Home Offset" },
    { CIA402_POLARITY,                0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 1,   "Polarity" },
    { CIA402_MAX_PROFILE_VELOCITY,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Profile Velocity" },
    { CIA402_MAX_MOTOR_SPEED,         0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Max Motor Speed" },
    { CIA402_PROFILE_VELOCITY,        0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Velocity" },
//  { CIA402_END_VELOCITY,            0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "End Velocity" },
    { CIA402_PROFILE_ACCELERATION,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Acceleration" },
    { CIA402_PROFILE_DECELERATION,    0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Profile Deceleration" },
    { CIA402_QUICK_STOP_DECELERATION, 0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Quick Stop Deceleration" },
//  { CIA402_MOTION_PROFILE_TYPE,     0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Motion Profile Type" },
    { CIA402_TORQUE_SLOPE,            0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Torque Slope" },
//  { CIA402_TORQUE_PROFILE_TYPE,     0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Torque Profile Type" },
    { CIA402_POSITION_ENC_RESOLUTION, 0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,  32, 0x003f, 0,   "Position Encoder Resolution" },
    { CIA402_GEAR_RATIO,              0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Gear Ratio" },
    { CIA402_MAX_ACCELERATION,        0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Max Acceleration" },
    { CIA402_HOMING_METHOD,           0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Homing Method"},
    { CIA402_HOMING_SPEED,            0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Homing Speed"},
    { CIA402_HOMING_ACCELERATION,     0, 0, DEFTYPE_INTEGER32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Homing Acceleration"},
    { COMMUTATION_OFFSET_CLKWISE,     0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Commutation Offset Clockwise"},
    { COMMUTATION_OFFSET_CCLKWISE,    0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Commutation Offset Counter Clockwise"},
    { MOTOR_WINDING_TYPE,             0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Motor Winding Type"},
    { SNCN_SENSOR_POLARITY,           0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 1,   "Position Sensor Polarity"},
    { LIMIT_SWITCH_TYPE,              0, 0, DEFTYPE_INTEGER8, CANOD_TYPE_VAR,     8, 0x003f, 0,   "Limit Switch Type"},
//  { CIA402_POSITIVE_TORQUE_LIMIT,   0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Positive Torque Limit" },
//  { CIA402_NEGATIVE_TORQUE_LIMIT,   0, 0, DEFTYPE_INTEGER16, CANOD_TYPE_VAR,   16, 0x003f, 0,   "Negative Torque Limit" },
    { CIA402_MOTOR_TYPE,              0, 0, DEFTYPE_UNSIGNED16, CANOD_TYPE_VAR,  16, 0x003f, 0,   "Motor Type" },
    /* the following objects are vendor specific and defined by CiA402_Objects.xlsx */
    { CIA402_MOTOR_SPECIFIC,          0, 0, DEFTYPE_UNSIGNED8,  CANOD_TYPE_ARRAY,    8, 0x0007, 6,   "Motor Specific Settings" },
    { CIA402_MOTOR_SPECIFIC,          1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Nominal Current" },
    { CIA402_MOTOR_SPECIFIC,          2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Phase Resistance" },
    { CIA402_MOTOR_SPECIFIC,          3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific pole pair number" },
    { CIA402_MOTOR_SPECIFIC,          4, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Max Speed" },
    { CIA402_MOTOR_SPECIFIC,          5, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Phase Inductance" },
    { CIA402_MOTOR_SPECIFIC,          6, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Motor Specific Torque Constant" },
    { CIA402_CURRENT_GAIN,            0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Current Gain" },
    { CIA402_CURRENT_GAIN,            1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current P-Gain" },
    { CIA402_CURRENT_GAIN,            2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current I-Gain" },
    { CIA402_CURRENT_GAIN,            3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Current D-Gain" },
    { CIA402_VELOCITY_GAIN,           0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Velocity Gain" },
    { CIA402_VELOCITY_GAIN,           1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity P-Gain" },
    { CIA402_VELOCITY_GAIN,           2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity I-Gain" },
    { CIA402_VELOCITY_GAIN,           3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Velocity D-Gain" },
    { CIA402_POSITION_GAIN,           0, 0, DEFTYPE_UNSIGNED8,   CANOD_TYPE_ARRAY,    8, 0x0007, 3,   "Position Gain" },
    { CIA402_POSITION_GAIN,           1, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position P-Gain" },
    { CIA402_POSITION_GAIN,           2, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position I-Gain" },
    { CIA402_POSITION_GAIN,           3, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_ARRAY,   32, 0x003f, 0,   "Position D-Gain" },
    { CIA402_POSITION_OFFSET,         0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,   32, 0x003f, 0,   "Postion Offset" },
    { CIA402_SUPPORTED_DRIVE_MODES,   0, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_VAR,     32, 0x0007, 0x00000700, "Supported Drive Modes" },
    { ODSNCN_ADDITIONAL_ENCODER,      0, 0, DEFTYPE_UNSIGNED8,  CANOD_TYPE_RECORD,    8, 0x0007, 3,   "Additional Encoder" },
    { ODSNCN_ADDITIONAL_ENCODER,      1, 0, DEFTYPE_UNSIGNED8,  CANOD_TYPE_RECORD,    8, 0x003f, 0,   "Additional Encoder Type" },
    { ODSNCN_ADDITIONAL_ENCODER,      2, 0, DEFTYPE_UNSIGNED8,  CANOD_TYPE_RECORD,    8, 0x003f, 0,   "Additional Encoder Polarity" },
    { ODSNCN_ADDITIONAL_ENCODER,      3, 0, DEFTYPE_UNSIGNED32, CANOD_TYPE_RECORD,   32, 0x003f, 0,   "Additional Encoder Resolution" },
#endif
#if USER_DEFINED_PDOS == 1
    { USER_PDO_OUT_1,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 1" },
    { USER_PDO_OUT_2,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 2" },
    { USER_PDO_OUT_3,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 3" },
    { USER_PDO_OUT_4,                 0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User TX 4" },
    { USER_PDO_IN_1,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 1" },
    { USER_PDO_IN_2,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 2" },
    { USER_PDO_IN_3,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 3" },
    { USER_PDO_IN_4,                  0, 0, DEFTYPE_INTEGER32,  CANOD_TYPE_VAR,     32, 0x003f, 0, "User RX 4" },
#endif /* USER_DEFINED_PDOS */
#endif /* ETHERCAT_BOOTMANAGER */
    { 0, 0, 0, 0, 0, 0, 0, 0, "\0" }
};

#endif

#endif
