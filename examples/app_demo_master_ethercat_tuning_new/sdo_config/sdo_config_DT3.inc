struct _ecat_sdo_config slave_config[6][26] = {
#if 0
    {
 
        { 0x2001, 0, 3500, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 1, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 5, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 5, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 200, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 200, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 350000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 2,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 2000, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1000, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 63,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 4, 2}, /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 1200000, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 60, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 8192, 4},        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
#endif
    {   /* Forsight robot axis 1 */
        { 0x2001, 0, 190, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 40, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 40, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 30, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 40, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 0, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 0, 4},            /* Cia402_POSITION_GAIN - I */
        { 0x20fb, 3, 0, 4},             /* CIA402_POSITION_GAIN - D */
        { 0x2410, 2, 1270000, 4},        /* MOTOR_SPECIFC - phase resistance */
        { 0x2410, 3, 5,  4},           /* MOTOR_SPECIFC - pole pairs */
        { 0x2410, 4, 1200, 4},           /* MOTOR_SPECIFC - max speed */
        { 0x2410, 5, 1330, 4},           /* MOTOR_SPECIFIC - phase inductance */
        { 0x2410, 6, 300,  4},           /* MOTOR_SPECIFIC - specific torque, named MAXIMUM_TORQUE - not confuse with MAX_TORQUE */
        { 0x606a, 0, 6, 2},             /* MOTOR COMMUTATION SENSOR */
        { 0x6072, 0, 100, 4},       /* CIA402_MAX_TORQUE */
        { 0x6073, 0, 90, 2},            /* CIA402_MAX_CURRENT */
        { 0x607b, 1, 0x80000001, 4},    /* CIA402_POSITION_RANGELIMIT - minimum */
        { 0x607b, 2, 0x7fffffff, 4},    /* CIA402_POSITION_RANGELIMIT - maximum */
        { 0x607d, 1, 0x80000001, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - minimum */
        { 0x607d, 2, 0x7fffffff, 4},    /* CIA402_SOFTWARE_POSITION_RANGELIMIT - maximum */
        { 0x607e, 0, 1, 4},             /* CIA402_POLARITY */
        { 0x6085, 0, 3000, 4},          /* CIA402_QUICK_STOP_DECELERATION */
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* Forsight robot axis 2 */
        { 0x2001, 0, 2000, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 15, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 5, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 300, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 100, 4},            /* Cia402_POSITION_GAIN - I */
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
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* Forsight robot axis 3 */
        { 0x2001, 0, 300, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 38, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 35, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 170, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 35, 4},            /* Cia402_POSITION_GAIN - I */
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
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* Forsight robot axis 4 */
        { 0x2001, 0, 330, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 25, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 10, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 150, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 30, 4},            /* Cia402_POSITION_GAIN - I */
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
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* Forsight robot axis 5 */
        { 0x2001, 0, 1665, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 25, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 15, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 210, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 40, 4},            /* Cia402_POSITION_GAIN - I */
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
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    },
    {   /* Forsight robot axis 6 */
        { 0x2001, 0, 2850, 2 },         /* COMMUTATION_OFFSET_CLKWISE */
        { 0x2004, 0, 0, 2 },            /* SENSOR_POLARITY */
        { 0x20f6, 1, 1000, 4},          /* CIA402_CURRENT_GAIN - P */
        { 0x20f6, 2, 0, 4},             /* CIA402_CURRENT_GAIN - I */
        { 0x20f6, 3, 0, 4},             /* CIA402_CURRENT_GAIN - D */
        { 0x20f9, 1, 25, 4},            /* CIA402_VELOCITY_GAIN -P */
        { 0x20f9, 2, 0, 4},             /* CIA402_VELOCITY_GAIN -I */
        { 0x20f9, 3, 10, 4},            /* CIA402_VELOCITY_GAIN -D */
        { 0x20fb, 1, 250, 4},            /* Cia402_POSITION_GAIN - P */
        { 0x20fb, 2, 90, 4},            /* Cia402_POSITION_GAIN - I */
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
        { 0x308f, 0, 65536, 4}        /* fomrerly known as 0x608f CIA402_POSITION_ENC_RESOLUTION */
    }
};

