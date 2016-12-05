
/**
 * @file can_od.h
 * @brief Functions to handle CAN object dictionary
 */

#include "canod.h"

#ifndef CAN_OD_H
#define CAN_OD_H

#if 0
struct _sdoinfo_service {
	unsigned opcode;                   ///< OD operation code
	unsigned incomplete;               ///< 0 - last fragment, 1 - more fragments follow
	unsigned fragments;                ///< number of fragments which follow
	unsigned char data[COE_MAX_DATA_SIZE];  ///< SDO data field
};
#endif

/* FIXME: add objects which describe the mapped PDO data.
 * the best matching OD area would be at index 0x200-0x5fff (manufacturer specific profile area
 */

/** entry description structure */
struct _sdoinfo_entry_description {
	unsigned index; ///< 16 bit int should be sufficient
	unsigned subindex; ///< 16 bit int should be sufficient
	unsigned objectDataType;
	unsigned dataType;
	unsigned char objectCode;
	unsigned bitLength;
	unsigned objectAccess;
	unsigned value; ///< real data type is defined by .dataType
	unsigned char name[50];
};

/* ad valueInfo (BYTE):
 * Bit 0 - 2: reserved
 * Bit 3: unit type
 * Bit 4: default value
 * Bit 5: minimum value
 * Bit 6: maximum value
 *
 * ad objectAccess (WORD):
 * Bit 0: read access in Pre-Operational state
 * Bit 1: read access in Safe-Operational state
 * Bit 2: read access in Operational state
 * Bit 3: write access in Pre-Operational state
 * Bit 4: write access in Safe-Operational state
 * Bit 5: write access in Operational state
 * Bit 6: object is mappable in a RxPDO
 * Bit 7: object is mappable in a TxPDO
 * Bit 8: object can be used for backup
 * Bit 9: object can be used for settings
 * Bit 10 - 15: reserved
 *
 * ad PDO Mapping value (at index 0x200[01]):
 * bit 0-7: length of the mapped objects in bits
 * bit 8-15: subindex of the mapped object
 * bit 16-32: index of the mapped object
 */


/**
 * Return the length of all five cathegories
 */
int canod_get_all_list_length(unsigned length[]);

/**
 * return the length of list of type listtype
 */
int canod_get_list_length(unsigned listtype);

/**
 * Get list of objects in the specified cathegory
 */
int canod_get_list(unsigned list[], unsigned size, unsigned listtype);

/**
 * Get description of object at index and subindex.
 */
int canod_get_object_description(struct _sdoinfo_entry_description &obj, unsigned index);

/**
 * Get description of specified entry
 */
int canod_get_entry_description(unsigned index, unsigned subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc);

/**
 * Get OD entry values
 *
 * @param index
 * @param subindex
 * @param &value     read the values from this array from the object dictionary.
 * @param &type      the type of &value
 * @return 0 on success
 */
int canod_get_entry(unsigned index, unsigned subindex, unsigned &value, unsigned &type);

/**
 * Set OD entry values
 *
 * @note This function is currently unused.
 *
 * @param index
 * @param subindex
 * @param value     write the values from this array to the object dictionary.
 * @param type      the type of &value
 * @return 0 on success
 */
int canod_set_entry(unsigned index, unsigned subindex, unsigned value, unsigned type);

#endif /* CANOD_H */
