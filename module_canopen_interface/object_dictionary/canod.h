
/**
 * @file canod.h
 * @brief Functions to handle CAN object dictionary
 */

#include "canod_constants.h"
#include "co_interface.h"

#ifndef CANOD_H
#define CANOD_H

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
 * @brief Get OD struct index of OD entry.
 * @param[in]   Index   OD Index
 * @param[in]   Subindex   OD Subindex
 * @return OD struct index, Error
 */
{unsigned, unsigned} canod_find_index(uint16_t index, uint8_t subindex);

/**
 * @brief Get OD value length in Byte.
 * @param[in]   Index   OD Index
 * @param[in]   Subindex   OD Subindex
 * @return Datalength, Error
 */
{int, unsigned} canod_find_data_length(uint16_t index, uint8_t subindex);

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
int canod_get_object_description(struct _sdoinfo_entry_description &obj, uint16_t index, uint8_t subindex);

/**
 * Get description of specified entry
 */
int canod_get_entry_description(uint16_t index, uint8_t subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc);

/**
 * @brief Get OD entry values
 *
 * @param[in] index
 * @param[in] subindex
 * @param[out] &value     read the values from this array from the object dictionary.
 * @param[out] &bitlength      bitlength of value
 * @return 0 on success
 */
int canod_get_entry(uint16_t index, uint8_t subindex, unsigned &value, unsigned &bitlength);

/**
 * @brief Get OD entry values fast without searching
 *
 * @param[in] index     Direct index for OD array (For PDOs)
 * @param[out] &value     read the values from this array from the object dictionary.
 * @param[out] &bitlength      bitlength of value
 * @return 0 on success
 */
int canod_get_entry_fast(uint16_t od_index, unsigned &value, unsigned &bitlength);

/**
 * @brief Set OD entry values
 *
 * @param[in] index
 * @param[in] subindex
 * @param[in] value     write the values from this array to the object dictionary.
 * @param[in] intern    Access flag for intern or extern access
 * @return 0 on success
 */
int canod_set_entry(uint16_t index, uint8_t subindex, unsigned value, unsigned intern);

/**
 * @brief Set OD entry values fast without searching
 *
 * @param[in] index     Direct index for OD array (For PDOs)
 * @param[in] value     read the values from this array from the object dictionary.
 * @param[in] intern    Access flag for intern or extern access
 * @return 0 on success
 */
int canod_set_entry_fast(uint16_t od_index, unsigned value, unsigned intern);

/**
 * @brief Get Access type for entry.
 *
 * @param[in] index     Direct index for OD array (For PDOs)
 * @param[in] subindex
 * @return Access type, Error
 */
{unsigned char, unsigned} canod_get_access(uint16_t index, uint8_t subindex);

#endif /* CANOD_H */
