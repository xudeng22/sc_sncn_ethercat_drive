/**
 * @file canod.xc
 * @brief managing object dictionary
 */

#include "canod.h"
#include "canod_datatypes.h"
#include "dictionary.h"
#include "print.h"

#include <xs1.h>

/* local */

static int get_minvalue(unsigned datatype)
{
	switch (datatype) {
	case DEFTYPE_BOOLEAN:
		return 0;
	case DEFTYPE_INTEGER8:
		return 0xff;
	case DEFTYPE_INTEGER16:
		return 0xffff;
	case DEFTYPE_INTEGER32:
		return 0xffffffff;
	case DEFTYPE_UNSIGNED8:
		return 0;
	case DEFTYPE_UNSIGNED16:
		return 0;
	case DEFTYPE_UNSIGNED32:
		return 0;
	default:
		return 0;
	}

	return 0;
}

static int get_maxvalue(unsigned datatype)
{
	switch (datatype) {
	case DEFTYPE_BOOLEAN:
		return 1;
	case DEFTYPE_INTEGER8:
		return 0x7f;
	case DEFTYPE_INTEGER16:
		return 0x7fff;
	case DEFTYPE_INTEGER32:
		return 0x7fffffff;
	case DEFTYPE_UNSIGNED8:
		return 0xff;
	case DEFTYPE_UNSIGNED16:
		return 0xffff;
	case DEFTYPE_UNSIGNED32:
		return 0xffffffff;
	default:
		return 0;
	}

	return 0;
}

{unsigned, unsigned} canod_find_index(uint16_t index, uint8_t subindex)
{
    static unsigned old_index, old_subindex, old_od_index;
    unsigned od_index,
    j = -1,
    k = -1;

    // Return previously searched OD index, if entry is the same.
    if ( (index == old_index) && (subindex == old_subindex) )
        return {old_od_index, 0};

    old_index = index;
    old_subindex = subindex;

    // search for index
    for(od_index = 0; SDO_Info_Entries[od_index].index != 0x0; od_index++)
    {
        if(SDO_Info_Entries[od_index].index == index)
        {
            j = od_index;
            break;
        }
    }

    // Index not found
    if(j == -1) {
        return {0, 2};
    }

    // search for subindex
    for(od_index = j; SDO_Info_Entries[od_index].index != 0x0; od_index++)
    {
        if((SDO_Info_Entries[od_index].index == index) && (SDO_Info_Entries[od_index].subindex == subindex))
        {
            k = od_index;
            break;
        }
    }

    // subindex not found
    if(k == -1) {
        return {0, 3};
    }

    old_od_index = k;
    return {k, 0};
}

/*---------------------------------------------------------------------------
 Find data length od the object based on index and subindex
 ---------------------------------------------------------------------------*/
{int, unsigned} canod_find_data_length(uint16_t index, uint8_t subindex)
{
    unsigned od_index, error = 0;
    {od_index, error} = canod_find_index(index, subindex);
    return {SDO_Info_Entries[od_index].bitLength / 8, error};
}


/* get number of objects without subobjects */
static unsigned get_object_count(void)
{
	unsigned count = 0;

	for (unsigned i=0; SDO_Info_Entries[i].index != 0; i++) {
		if (SDO_Info_Entries[i].subindex == 0) {
			count++;
		}
	}

	return count;
}

/* API implementation */

{unsigned char, unsigned} canod_get_access(uint16_t index, uint8_t subindex)
{
    unsigned od_index, error;
    {od_index, error} = canod_find_index(index, subindex);

    return {SDO_Info_Entries[od_index].objectAccess, error};
}

int canod_get_all_list_length(unsigned length[])
{
	/* FIXME correct length of all subsections */
	length[0] = get_object_count();
	length[1] = 0;
	length[2] = 0;
	length[3] = 0;
	length[4] = 0;

	return 0;
}

/* FIXME except for all the list length returns length 0 */
int canod_get_list_length(unsigned listtype)
{
	int length = 0;

	switch (listtype) {
	case CANOD_LIST_ALL:
		length = get_object_count();
		break;

	case CANOD_LIST_RXPDO_MAP:
		break;

	case CANOD_LIST_TXPDO_MAP:
		break;

	case CANOD_LIST_REPLACE:
		break;

	case CANOD_LIST_STARTUP:
		break;

	default:
		return 0;
	};

	return length;
}

/* FIXME implement and check other list lengths. */
int canod_get_list(unsigned list[], unsigned size, unsigned listtype)
{
	int count, i;

	switch (listtype) {
	case CANOD_LIST_ALL:
		for (i=0, count=0; SDO_Info_Entries[i].index != 0; i++) {
			if (SDO_Info_Entries[i].subindex == 0) {
				list[count++] = SDO_Info_Entries[i].index;
			}
		}

		break;

	case CANOD_LIST_RXPDO_MAP:
		break;

	case CANOD_LIST_TXPDO_MAP:
		break;

	case CANOD_LIST_REPLACE:
		break;

	case CANOD_LIST_STARTUP:
		break;

	default:
		return 0;
	};

	return count;
}

int canod_get_object_description(struct _sdoinfo_entry_description &obj, uint16_t index, uint8_t subindex)
{
	int k;
    unsigned od_index, error = 0;
    {od_index, error} = canod_find_index(index, subindex);

    obj.index = SDO_Info_Entries[od_index].index;
    obj.subindex = SDO_Info_Entries[od_index].subindex;
    obj.objectDataType = SDO_Info_Entries[od_index].objectDataType;
    obj.dataType = SDO_Info_Entries[od_index].dataType;
    obj.objectCode = SDO_Info_Entries[od_index].objectCode;
    if (obj.subindex == 0 && obj.objectCode != CANOD_TYPE_VAR)
        obj.value = SDO_Info_Entries[od_index].value;
    else
        obj.value = 0;
    for (k=0; k<50; k++) { /* FIXME set a define for max string length */
        obj.name[k] = SDO_Info_Entries[od_index].name[k];
    }

	return error;
}

static int canod_get_entry_description_lowerindex(uint16_t index, uint8_t subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc)
{
    desc.index = index;
    desc.subindex = subindex;

    desc.dataType = DEFTYPE_UNSIGNED16;
    desc.bitLength = 16;
    desc.objectAccess = 0x0003; /* readable */
    //desc.value =

    return 0;
}

int canod_get_entry_description(uint16_t index, uint8_t subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc)
{
	struct _sdoinfo_entry_description entry;
	int i,k;
    unsigned od_index, error = 0;
    {od_index, error} = canod_find_index(index, subindex);


	if (index < 0x1000) {
	    return canod_get_entry_description_lowerindex(SDO_Info_Entries[od_index].index, SDO_Info_Entries[od_index].subindex, valueinfo, desc);
	}

	if (SDO_Info_Entries[od_index].index == 0x0)
		return -1; /* Entry object not found */

	/* FIXME implement entry_description */
	desc.index = SDO_Info_Entries[od_index].index;
	desc.subindex = SDO_Info_Entries[od_index].subindex;

	desc.dataType = SDO_Info_Entries[od_index].dataType;
	desc.bitLength = SDO_Info_Entries[od_index].bitLength;
	desc.objectAccess = SDO_Info_Entries[od_index].objectAccess;

#if 1
	desc.value = SDO_Info_Entries[od_index].value;
#else /* wrong assumption of packet content? */
	switch (valueinfo) {
	case CANOD_VALUEINFO_UNIT:
		desc.value = 0; /* unit type currently unsupported */
		break;

	case CANOD_VALUEINFO_DEFAULT:
		desc.value = SDO_Info_Entries[i].value;
		break;
	case CANOD_VALUEINFO_MIN:
		desc.value = get_minvalue(desc.dataType);
		break;

	case CANOD_VALUEINFO_MAX:
		desc.value = get_maxvalue(desc.dataType);
		break;
	default:
		/* empty response */
		desc.value = 0;
		break;
	}
#endif

	/* copy name */
	for (k=0; k<50 && SDO_Info_Entries[od_index].name[k] != '\0'; k++) {
		desc.name[k] = SDO_Info_Entries[od_index].name[k];
	}
	desc.name[k] = '\0';

    return error;
}

int canod_get_lowerentry(uint16_t index, uint8_t subindex, unsigned &value, unsigned &bitlength)
{
    unsigned indexes[] = {
        0, /* unused */
        DEFTYPE_BOOLEAN,
        DEFTYPE_INTEGER8,
        DEFTYPE_INTEGER16,
        DEFTYPE_INTEGER32,
        DEFTYPE_UNSIGNED8,
        DEFTYPE_UNSIGNED16,
        DEFTYPE_UNSIGNED32,
        DEFTYPE_REAL32,
        DEFTYPE_VISIBLE_STRING,
        DEFTYPE_OCTET_STRING,
        DEFTYPE_UNICODE_STRING,
        DEFTYPE_TIME_OF_DAY,
        DEFTYPE_TIME_DIFFERENCE,
        DEFTYPE_DOMAIN
    };

    if (index < sizeof(indexes)/sizeof(indexes[0])) {
        value = indexes[index];
        bitlength = 16;
    } else {
        return 1; /* not found */
    }

   return 0;
}

int canod_get_entry(uint16_t index, uint8_t subindex, unsigned &value, unsigned &bitlength)
{
	unsigned mask = 0xffffffff;
    unsigned od_index, error = 0;
    {od_index, error} = canod_find_index(index, subindex);

	/* FIXME handle special subindex 0xff to request object type -> see also CiA 301 */

	/* special file handling for object requests of index < 0x1000 */
    if (SDO_Info_Entries[od_index].index < 0x1000) {
        return canod_get_lowerentry(SDO_Info_Entries[od_index].index,
                SDO_Info_Entries[od_index].subindex, value, bitlength);
    }

    value = SDO_Info_Entries[od_index].value & (mask >> (32 - SDO_Info_Entries[od_index].bitLength) );
    bitlength = SDO_Info_Entries[od_index].bitLength; /* alternative bitLength */

    return error;
}

int canod_set_entry(uint16_t index, uint8_t subindex, unsigned value, unsigned intern)
{
	unsigned mask = 0xffffffff;
    unsigned od_index, error = 0;
    {od_index, error} = canod_find_index(index, subindex);

	// TODO Find solution for access from application side
    if ((SDO_Info_Entries[od_index].objectAccess & 0x38) == 0 && !intern) /* object not writeable, FIXME should be distinguished according to the current state */
        return 1;

    SDO_Info_Entries[od_index].value = value & (mask >> (32 - SDO_Info_Entries[od_index].bitLength) );

    return error;
}
