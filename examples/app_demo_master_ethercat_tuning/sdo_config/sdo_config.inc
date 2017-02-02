struct _ecat_sdo_config slave_config[6][59] = {
    {   /* axis 1 */
#if 0
        /* { 0x606a, 0, 6, 2},             * MOTOR COMMUTATION SENSOR * Commutation sensor is selected in usage field of 0x210x */
#endif
        { 0x2001, 0, 0, 2 },     /* CommutationOffsetClockwise */
        { 0x2002, 0, 0x01, 2 }        /* Position control strategy */
        { 0x2003, 1,  5, 1 },       /* Pole Pairs */
        { 0x2003, 2, 600, 4 },       /* Torque Constant */
        { 0x2003, 3, 1270000, 4 },       /* Phase Resistance */
        { 0x2003, 4, 1330, 4 },       /* Phase Inductance */
        { 0x2004, 1, 0x00, 4 },       /* Duty Start Brake */
        { 0x2004, 2, 0x00, 4 },       /* Duty Maintain Brake */
        { 0x2004, 3, 0x00, 4 },       /* Period Start Brake */
        { 0x2005, 1, 0x00, 4 },       /* Max battery energy */
        { 0x2005, 2, 0x00, 4 },       /* Min battery energy */
        { 0x2005, 3, 0x00, 4 },       /* Max regeneration power */
        { 0x2005, 4, 0x00, 4 },       /* Min regeneration power */
        { 0x2005, 5, 0x00, 4 },       /* Max regeneration speed */
        { 0x2005, 6, 0x00, 4 },       /* Min regeneration speed */
        { 0x2006, 1, 0x00, 4 },       /* Max DC Voltage */
        { 0x2006, 2, 0x00, 4 },       /* Min DC Voltage */
        { 0x2007, 1, 0x00, 4 },       /* Position filter */
        { 0x2007, 2, 0x00, 4 },       /* Velocity filter */
        { 0x2010, 1,  40, 4 },       /* Torque P-Value */
        { 0x2010, 2,  40, 4 },       /* Torque I-Value */
        { 0x2010, 3,   0, 4 },       /* Torque D-Value */
        { 0x2011, 1, 0, 4 },       /* Velocity P-Valule */
        { 0x2011, 2, 0, 4 },       /* Velocity I-Valule */
        { 0x2011, 3, 0, 4 },       /* Velocity D-Valule */
        { 0x2012, 1, 0, 4 },       /* Position P-Value */
        { 0x2012, 2, 0, 4 },       /* Position I-Value */
        { 0x2012, 3, 0, 4 },       /* Position D-Value */
        { 0x2100, 1, 0x2101, 2 },     /* Feedback 1 */
        { 0x2100, 2, 0x2102, 2 },     /* Feedback 2 */
        { 0x2101, 1, 0x01, 1 },       /* Type */
        { 0x2101, 2, 0x1, 1 },       /* Usage */
        { 0x2101, 3, 65536, 4 },       /* Resolution */
        { 0x2102, 1, 6, 1 },       /* Type */
        { 0x2102, 2, 0x0, 1 },       /* Usage */
        { 0x2102, 3, 0x00, 4 },       /* Resolution */
        { 0x2201, 1, 0x00, 4 },       /* Multiturn resolution */
        { 0x2201, 2, 0x00, 4 },       /* Singleturn resolution */
        { 0x2201, 3, 0x00, 2 },       /* Clock */
        { 0x2201, 4, 0x00, 2 },       /* Clock divisor */
        { 0x2201, 5, 0x00, 4 },       /* Timeout */
        { 0x2202, 1, 0x00, 4 },       /* Index type */
        { 0x2202, 2, 0x00, 4 },       /* Sensor signal type */
        { 0x2A00, 0, 0x64, 2 },       /* Tuning torque percent */
        { 0x6072, 0, 100, 4 }, /* MaxTorque */
        { 0x6073, 0, 90, 2 },     /* Max Current */
        { 0x6075, 0, 0x00000000, 4 }, /* Motor Rated Current */
        { 0x6076, 0, 0x00000000, 4 }, /* Motor Rated Torque */
        { 0x607D, 1, 0x80000001, 4 }, /* Min position limit */
        { 0x607D, 2, 0x7fffffff, 4 }, /* Max position limit */
        { 0x607B, 1, 0x80000001, 4 }, /* Min position range limit */
        { 0x607B, 2, 0x7fffffff, 4 }, /* Max position range limit */
        { 0x6085, 0, 3000, 4 },       /* Quick stop deceleration */
        { 0x6080, 0, 1200, 4 },       /* Max motor speed */
        { 0x607E, 0, 0x00, 1 },       /* Polarity - formerly -1/1 no like specification */
        { 0x6083, 0, 0x00, 4 },       /* Profile acceleration */
        { 0x6084, 0, 0x00, 4 },       /* Profile deceleration */
        { 0x607F, 0, 0x00, 4 },       /* Max profile velocity */
        { 0x607C, 0, 0x00, 4 },       /* Home offset */
    },
    {   /* axis 2 */
        { 0x2001, 0, 0, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 0, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 0, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 170,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* formerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* axis 3 */
        { 0x2001, 0, 0, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 0, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 0, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 170,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* formerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* axis 4 */
        { 0x2001, 0, 0, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 0, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 0, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 170,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* formerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* axis 5 */
        { 0x2001, 0, 0, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 0, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 0, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 170,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* formerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* axis 6 */
        { 0x2001, 0, 0, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 0, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 0, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 170,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* formerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    }
};

