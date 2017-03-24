/**
 * @file cia402_error_codes.h
 * @brief Error codes defined by IEC65800-7-201
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <stdint.h>

#define ERROR_CODE_DC_LINK_OVER_VOLTAGE             0x3210
#define ERROR_CODE_DC_LINK_UNDER_VOLTAGE            0x3210

#define ERROR_CODE_PHASE_FAILURE_L1                 0x3131
#define ERROR_CODE_PHASE_FAILURE_L2                 0x3132
#define ERROR_CODE_PHASE_FAILURE_L3                 0x3133

#define ERROR_CODE_EXCESS_TEMPEATUR_DEVICE          0x4210

/* for all error in this control which could not further specified */
#define ERROR_CODE_CONTROL                          0x8A00
