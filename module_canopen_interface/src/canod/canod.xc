/**
 * @file canod.xc
 * @brief managing object dictionary
 */

#include "can_od.h"
#include "canod_datatypes.h"
#include "dictionary.h"

//#include "ethercat_config.h"
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

/* get number of objects without subobjects */
static unsigned get_object_count(void)
{
	unsigned count = 0;

	for (unsigned i=0; SDO_Info_Entries[i].index != 0; i++) {
		if (SDO_Info_Entries[i].subindex == 0)
			count++;
	}

	return count;
}

/* API implementation */

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

int canod_get_object_description(struct _sdoinfo_entry_description &obj, unsigned index)
{
	int i = 0, k;

	for (i=0; i<sizeof(SDO_Info_Entries)/sizeof(SDO_Info_Entries[0]); i++) {
		if (SDO_Info_Entries[i].index == index) {
			obj.index = SDO_Info_Entries[i].index;
			obj.subindex = SDO_Info_Entries[i].subindex;
			obj.objectDataType = SDO_Info_Entries[i].objectDataType;
			obj.dataType = SDO_Info_Entries[i].dataType;
			obj.objectCode = SDO_Info_Entries[i].objectCode;
			if (obj.subindex == 0 && obj.objectCode != CANOD_TYPE_VAR)
			    obj.value = SDO_Info_Entries[i].value;
			else
			    obj.value = 0;
			for (k=0; k<50; k++) { /* FIXME set a define for max string length */
				obj.name[k] = SDO_Info_Entries[i].name[k];
			}

			break;
		}

		if (SDO_Info_Entries[i].index == 0x0) {
			return 1; /* object not found */
		}
	}

	return 0;
}

static int canod_get_entry_description_lowerindex(unsigned index, unsigned subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc)
{
    desc.index = index;
    desc.subindex = subindex;

    desc.dataType = DEFTYPE_UNSIGNED16;
    desc.bitLength = 16;
    desc.objectAccess = 0x0003; /* readable */
    //desc.value =

    return 0;
}

int canod_get_entry_description(unsigned index, unsigned subindex, unsigned valueinfo, struct _sdoinfo_entry_description &desc)
{
	struct _sdoinfo_entry_description entry;
	int i,k;

	if (index < 0x1000) {
	    return canod_get_entry_description_lowerindex(index, subindex, valueinfo, desc);
	}

	for (i=0; i<SDO_Info_Entries[i].index != 0x0; i++) {
		if ((SDO_Info_Entries[i].index == index) && (SDO_Info_Entries[i].subindex == subindex))
			break;
	}

	if (SDO_Info_Entries[i].index == 0x0)
		return -1; /* Entry object not found */

	/* FIXME implement entry_description */
	desc.index = index;
	desc.subindex = subindex;

	desc.dataType = SDO_Info_Entries[i].dataType;
	desc.bitLength = SDO_Info_Entries[i].bitLength;
	desc.objectAccess = SDO_Info_Entries[i].objectAccess;

#if 1
	desc.value = SDO_Info_Entries[i].value;
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
	for (k=0; k<50 && SDO_Info_Entries[i].name[k] != '\0'; k++) {
		desc.name[k] = SDO_Info_Entries[i].name[k];
	}
	desc.name[k] = '\0';

    return 0;
}

int canod_get_lowerentry(unsigned index, unsigned subindex, unsigned &value, unsigned &bitlength)
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

int canod_get_entry(unsigned index, unsigned subindex, unsigned &value, unsigned &bitlength)
{
	int i;
	unsigned mask = 0xffffffff;

	/* FIXME handle special subindex 0xff to request object type -> see also CiA 301 */

	/* special file handling for object requests of index < 0x1000 */
    if (index < 0x1000) {
        return canod_get_lowerentry(index, subindex, value, bitlength);
    }

	/* regular request */
	for (i=0; SDO_Info_Entries[i].index != 0x0; i++) {
		if (SDO_Info_Entries[i].index == index
		    && SDO_Info_Entries[i].subindex == subindex) {
			switch (SDO_Info_Entries[i].bitLength) {
			case 8:
				mask = 0xff;
				break;
			case 16:
				mask = 0xffff;
				break;
			case 32:
				mask = 0xffffffff;
				break;
			default:
				break;
			}
			value = SDO_Info_Entries[i].value & mask;
			bitlength = SDO_Info_Entries[i].bitLength; /* alternative bitLength */

			return 0;
		}
	}

	return 1; /* not found */
}

int canod_set_entry(unsigned index, unsigned subindex, unsigned value, unsigned type)
{
	unsigned mask = 0xffffffff;

	for (int i=0; SDO_Info_Entries[i].index != 0x0; i++) {
		if (SDO_Info_Entries[i].index == index
				&& SDO_Info_Entries[i].subindex == subindex) {

		    if ((SDO_Info_Entries[i].objectAccess & 0x38) == 0) /* object not writeable, FIXME should be destinguished according to the current state */
		        return 1;

			switch (SDO_Info_Entries[i].bitLength) {
			case 8:
				mask = 0xff;
				break;
			case 16:
				mask = 0xffff;
				break;
			case 32:
				mask = 0xffffffff;
				break;
			default:
				break;
			}
			SDO_Info_Entries[i].value = value & mask;
			return 0;
		}
	}

	return 1; /* cannot set value */
}
