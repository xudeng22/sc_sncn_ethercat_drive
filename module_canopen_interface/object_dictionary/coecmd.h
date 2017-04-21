
/**
 * @file coecmd.h
 * @brief Defines and definitions for applications commands to handle object
 * 			dictionary entries.
 */

/**
 * @brief This header defines the channel commands for COE requests.
 *
 * This communication is primary to access and manipulate the objects within
 * the CAN Object Dictionary (OD).
 */

#ifndef COECMD_H
#define COECMD_H

#warning FIXME deprecated - remove!

/** Command to request object from OD */
#define CAN_GET_OBJECT    0x1
/** Command to set  object from OD */
#define CAN_SET_OBJECT    0x2
/** Command to request type of specified object */
#define CAN_OBJECT_TYPE   0x3
/** Command to request max number of subindexes of object */
#define CAN_MAX_SUBINDEX  0x4

/* command structure:
 * app -> ecat/coe:
 * CAN_GET_OBJECT index.subindex
 * ecat -> app
 * value
 *
 * CAN_SET_OBJECT index.subindex value
 * ecat->app: value | errorcode
 *
 * CAN_MAX_SUBINDEX index.00=subindex
 * ecat->app: max_subindex
 */

/**
 * This define constructs a well formed address to access
 * the object dictionary. It is recommended to use this define
 * with the channel commands.
 *
 * @param i   the main index
 * @param s   the sub index
 */
#define CAN_OBJ_ADR(i,s)   (((unsigned)i<<8) | s)

/* Error symbols */
/** CAN error code */
#define CAN_ERROR           0xff01
/** CAN error for serious failure in CAN module */
#define CAN_ERROR_UNKNOWN   0xff02

#endif /* COECMD_H */
