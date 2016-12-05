/**
 * @file co.xc
 * @brief Implementation of the CO handling of the EtherCAT module.
 */

#include <xs1.h>
#include <print.h>

#include "coe.h"
#include "can_od.h"
#include "canod_datatypes.h"

#define OBJECT_DICTIONARY_MAXSIZE    100
#define CO_SDO_HEADER_LENGTH        4
#define CO_SDO_DATA_LENGTH          (CO_MAX_MSG_SIZE - CO_MAX_HEADER_SIZE - CO_SDO_HEADER_LENGTH)

#define SDO_INFO_HEADER_LENGTH       CO_SDO_HEADER_LENGTH
#define SDO_INFO_DATA_LENGTH         CO_SDO_DATA_LENGTH

#define CO_MAX_SEGMENTS             1    /* number of segments provided */

#define REPLY_RESET_PACKET()         (0)
#define REPLY_NEXT_PACKET(a)         ((a + 1 >= CO_MAX_SEGMENTS) ? 0 : a + 1)
#define REPLY_GET_INDEX(a)           (a * CO_MAX_MSG_SIZE)

static unsigned char reply[CO_MAX_SEGMENTS * CO_MAX_MSG_SIZE];
static int replyPending;
static int replyDataSize[CO_MAX_SEGMENTS];
static unsigned int replyReadPacket;             /* next packet to read  [0 .. CO_MAX_SEGMENTS-1] */
static unsigned int replyWritePacket;            /* next packet to write [0 .. CO_MAX_SEGMENTS-1] */

static int g_last_modified_object = 0;

struct _sdo_info_header {
	unsigned char opcode;
	unsigned char incomplete;
	unsigned fragmentsleft; /* number of fragments which will follow - Q: in this or the next packet? */
};

struct _sdo_request_header {
	unsigned char command;
	unsigned char complete;
	unsigned index;
	unsigned subindex;
};

struct _sdo_response_header {
	unsigned char command;
	unsigned char complete;
	unsigned char dataSetSize;
	unsigned char transfereType; /* normal (0x00) or expedited (0x01) */
	unsigned char sizeIndicator; /* 0x01 */
};

static int build_sdoinfo_reply(struct _sdo_info_header sdo_header, unsigned char data[], unsigned datasize)
{
    unsigned offset= REPLY_GET_INDEX(replyWritePacket);
    int datacount = 0;

    reply[offset+datacount++] = 0x00;
    reply[offset+datacount++] = 0x80;

    reply[offset+datacount++] = (sdo_header.opcode&0x7f) | ((sdo_header.incomplete<<7)&0x80);
    reply[offset+datacount++] = 0;
    reply[offset+datacount++] = sdo_header.fragmentsleft&0xff;
    reply[offset+datacount++] = (sdo_header.fragmentsleft>>8)&0xff;

	if (datasize > CO_SDO_DATA_LENGTH) {
	    printstr("Warning: requested packet length is to large! Falling back to CO_SDO_DATA_LENGTH - datasize = ");
	    printintln(datasize);
	    datasize = CO_SDO_DATA_LENGTH;
    }

	for (int i = 0; i < datasize; i++) {
	    reply[offset+datacount++] = data[i];
	}

	replyPending = 1;
	replyDataSize[replyWritePacket] = datacount;
	replyWritePacket = REPLY_NEXT_PACKET(replyWritePacket);

	return replyPending;
}

static int build_sdo_reply(struct _sdo_response_header header, unsigned char data[], unsigned datasize, unsigned char sdoservice)
{
    unsigned offset    = REPLY_GET_INDEX(replyWritePacket);
	unsigned datacount = 0;

	reply[offset + datacount] = 0;
	datacount++;
	reply[offset + datacount] = (sdoservice<<4) & 0xf0;
	datacount++;

	reply[offset + datacount] = (header.sizeIndicator&0x1) |
		   ((header.transfereType&0x1)<<1) |
		   ((header.dataSetSize&0x3)<<2) |
		   ((header.complete&0x1)<<4) |
		   ((header.command&0x7)<<5);
	datacount++;

	for (int i=0; i<datasize; i++) {
		reply[offset + datacount] = data[i];
		datacount++;
	}

	for (int i = datacount; i<CO_MAX_DATA_SIZE-1; i++)
		reply[i] = 0;

	replyPending = 1;
	replyDataSize[replyWritePacket] = datacount ;
	replyWritePacket = REPLY_NEXT_PACKET(replyWritePacket);

	return replyPending;
}

#if 0
static void parse_packet(unsigned char buffer[], ...)
{
}
#endif

static inline void parse_co_header(unsigned char buffer[], struct _co_header &head)
{
	unsigned tmp = buffer[1];
	tmp = (tmp<<8) | buffer[0];

	head.sdonumber = tmp&0x1ff;
	head.sdoservice = (tmp>>12)&0x0f;
}


/* sdo information request handler */
static int getODListRequest(unsigned listtype)
{
	unsigned lists[5];
	unsigned olists[OBJECT_DICTIONARY_MAXSIZE];
	unsigned size;
	unsigned char data[CO_MAX_DATA_SIZE];
	struct _sdo_info_header sdo_header;
	int reply_pending = 0;

	if (replyPending) {
		return -1; /* previous reply is pending */
	}

	sdo_header.opcode = CO_SDOI_GET_ODLIST_RSP;

	if (listtype == 0) { /* list of length is replied */
		canod_get_all_list_length(lists);

		/* FIXME build reply */
		sdo_header.incomplete = 0;
		sdo_header.fragmentsleft = 0;

		int k = 0;
		data[k++] = listtype&0xff;
		data[k++] = (listtype>>8)&0xff;

		for (int i = 0; i<5; i++) {
			data[k++] = lists[i]&0xff;
			data[k++] = (lists[i]>>8)&0xff;
		}

        reply_pending = build_sdoinfo_reply(sdo_header, data, k);
	} else {
		size = canod_get_list(olists, OBJECT_DICTIONARY_MAXSIZE, listtype);

	    int max_payload_size = (CO_SDO_DATA_LENGTH - SDO_INFO_HEADER_LENGTH);
	    int fragment_count = ((size * 2) - 1) / max_payload_size;

//		if (fragment_count > 0) { /* DEBUG if thing */
//			printstr("more segments should follow\n");
//		}

		if (fragment_count > CO_MAX_SEGMENTS) {
		    printstrln("ERROR want to send more segments than it is possible to send");
		    fragment_count = CO_MAX_SEGMENTS;
		}

		for (int i = 0; i <= fragment_count; i++) {
		    /* process each packet */
		    sdo_header.fragmentsleft = fragment_count - i;
		    sdo_header.incomplete = (sdo_header.fragmentsleft == 0) ? 0 : 1;

//		    printstr("Fragments left: "); printintln(sdo_header.fragmentsleft);

		    int datacount = 0;
		    data[datacount++] = listtype&0xff;
		    data[datacount++] = (listtype>>8)&0xff;

#define MINIMUM(a,b)     (a < b ? a : b)
		    int objects_to_transfer = MINIMUM(size - (i * (max_payload_size / 2)), max_payload_size/2);
		    int start_object = i * (max_payload_size / 2);
		    for (int j = start_object; j < (start_object + objects_to_transfer); j++) {
		        data[datacount++] = olists[j]&0xff;
		        data[datacount++] = (olists[j]>>8)&0xff;
		    }

		    reply_pending = build_sdoinfo_reply(sdo_header, data, datacount);
		}
	}

	return reply_pending;
}

#define CO_SDO_TRANSFER_NORMAL     0x00
#define CO_SDO_TRANSFER_EXPEDITED  0x01

static int sdo_request(unsigned char buffer[], unsigned size)
{
	unsigned index;
	unsigned subindex;
	unsigned type;
	unsigned value;
	struct _sdo_response_header header;
	unsigned char tmp[CO_MAX_DATA_SIZE];
	unsigned opcode = (buffer[2]>>5)&0x03;
	unsigned completeAccess = (buffer[2]>>4)&0x01; /* completeAccess only in SDO Upload Req/Rsp */
	unsigned maxSubindex = 0;
	unsigned dataSize = 0;
    unsigned completeSize = 0;
    const unsigned Completesizepos = 3; /* first position of complete size */
    int new_reply = 0;

	switch (opcode) {
	case CO_CMD_UPLOAD_REQ:
		index = (buffer[3]&0xff) | (((unsigned)buffer[4]<<8)&0xff00);
		subindex = buffer[5];

		if (completeAccess == 1) {
			if (buffer[5] != 0 && buffer[5] != 1) {
				/* error complete access requested, but subindex is not zero or one*/
				printstr("[ERROR] Complete Access with wrong subindex field\n");
				return -1;
			}
		}

		header.command = CO_CMD_UPLOAD_RSP;
		header.complete = completeAccess;
		//header.dataSetSize = 0x00; /* fixed to 0 => 4 bytes */
		//header.transfereType = 0x01; /* 0x00 normal transfer; 0x01 expedited */
		header.sizeIndicator = 0x01; /* always set in upload requests */

		tmp[0/*dataSize++*/] = index&0xff;
		tmp[1/*dataSize++*/] = (index>>8)&0xff;
		tmp[2/*dataSize++*/] = subindex&0xff;
		dataSize = 3;

		/* if the bitlength of the value is less than 4 octects use expedited transfere */
		struct _sdoinfo_entry_description desc;
		canod_get_entry_description(index, subindex, 0, desc);
		if (desc.bitLength <= 32) {
		    header.dataSetSize = 4 - desc.bitLength/8;
		    header.transfereType = CO_SDO_TRANSFER_EXPEDITED;
		} else {
		    header.dataSetSize = 0x00;
		    header.transfereType = CO_SDO_TRANSFER_NORMAL;

		    /* reserve positions in the buffer for number of octets to be transferred
		     * Parameter: Complete Size */
		    tmp[dataSize++] = 0x00;
		    tmp[dataSize++] = 0x00;
		    tmp[dataSize++] = 0x00;
		    tmp[dataSize++] = 0x00;
        }

		if (completeAccess==1) {
			canod_get_entry(index, 0, value, type);
			maxSubindex = value;
			if (subindex==0x00) {
				tmp[dataSize++] = value&0xff; /* subindex 0 is alway UNSIGNED8 */
			}

			for (int i=1; i<maxSubindex; i++) {
				canod_get_entry(index, i, value, type);

//				printstr("[DEBUG complete object values: "); printintln(i); printstr(": ");
				for (int k=0; k<(type/8); k++) {
					tmp[dataSize++] = (value>>(k*8))&0xff;
//					printhexln(tmp[dataSize-1]);
				}
			}

			completeSize = dataSize - 3;

		} else {
		    unsigned bitlength = 0;
			if (canod_get_entry(index, subindex, value, bitlength)) {
				printstr("[sdorequest CO_CMD_UPLOAD_REQ] error, entry not found 0x"); printhex(index); printstr(" 0x"); printhexln(subindex);
				return 1;
			}

			//printstr("[DEBUG] single value: 0x"); printhexln(value);
			for (int k=0; k<(bitlength/8); k++) {
				tmp[dataSize++] = (value>>(k*8))&0xff;
				//printhexln(tmp[dataSize-1]);
			}

			/* padding in expedited transfere for fill byte[4] array */
			if (header.transfereType == CO_SDO_TRANSFER_EXPEDITED) {
                unsigned rest = 4 - (bitlength/8);
                for (int k=0; k<rest; k++) {
                    tmp[dataSize++] = 0x00;
                }
			}

		}

		if (header.transfereType == CO_SDO_TRANSFER_NORMAL) {
		    /* now the type is known and set in the output buffer */
		    tmp[Completesizepos] = completeSize&0xff;
		    tmp[Completesizepos+1] = (completeSize>>8)&0xff;
		    tmp[Completesizepos+2] = (completeSize>>16)&0xff;
		    tmp[Completesizepos+3] = (completeSize>>24)&0xff;
		}


		/* FIXME on error CO_SERVICE_SDO_REQ with header.command == CO_CMD_ABORT_REQ should be send */
		new_reply = build_sdo_reply(header, tmp, dataSize, CO_SERVICE_SDO_RSP);
		break;

#if 0
	case CO_CMD_UPLOAD_RSP:
		break;
#endif

	case CO_CMD_UPLOAD_SEG_REQ:
		return -1; /* currently unsupported */

#if 0
	case CO_CMD_UPLOAD_SEG_RSP:
		return -1; /* currently unsupported */
#endif

	case CO_CMD_DOWNLOAD_SEG_REQ:
		return -1; /* currently unsupported */

	case CO_CMD_DOWNLOAD_REQ:
		index = (buffer[3]&0xff) | (((unsigned)buffer[4]<<8)&0xff00);
		subindex = buffer[5];

		if (completeAccess == 1) {
			if (buffer[5] != 0 && buffer[5] != 1) {
				/* error complete access requested, but subindex is not zero or one*/
				printstr("[ERROR] Complete Access with wrong subindex field\n");
				return -1;
			}
		}

		value = 0;
		for (int i=0; (i+5) < size; i++) {
			value |= buffer[6+i]<<(i*8);
		}

		unsigned char co_service = CO_SERVICE_SDO_RSP;

		if (canod_set_entry(index, subindex, value, type) == 0) {
            header.command = CO_CMD_DOWNLOAD_RSP;
            header.complete = completeAccess;
            header.dataSetSize = 0x00; /* temporary 0 */
            header.transfereType = 0x00; /* normal transfer */
            header.sizeIndicator = 0x00;

            dataSize = 0;
            tmp[dataSize++] = index&0xff;
            tmp[dataSize++] = (index>>8)&0xff;
            tmp[dataSize++] = subindex&0xff;
            tmp[dataSize++] = 0x00;
            tmp[dataSize++] = 0x00;
            tmp[dataSize++] = 0x00;
            tmp[dataSize++] = 0x00;
		} else {
		    // Error handling send abort command
		    co_service = CO_SERVICE_SDO_REQ;

            header.command = CO_CMD_ABORT_REQ;
            header.complete = 0;
            header.dataSetSize = 0x00;
            header.transfereType = 0x00; /* normal transfer */
            header.sizeIndicator = 0x00;

            dataSize = 0;
            tmp[dataSize++] = index&0xff;
            tmp[dataSize++] = (index>>8)&0xff;
            tmp[dataSize++] = subindex&0xff;

            // get abort code and set value.
            uint32_t abort_code = CO_ABORT_WRITE_RO;
            tmp[dataSize++] = abort_code         & 0xff;
            tmp[dataSize++] = (abort_code >> 8)  & 0xff;
            tmp[dataSize++] = (abort_code >> 16) & 0xff;
            tmp[dataSize++] = (abort_code >> 24) & 0xff;
		}

		g_last_modified_object = (index<<16) | subindex;
		new_reply = build_sdo_reply(header, tmp, dataSize, co_service); /* on error abort REQ */
		break;

	case CO_CMD_ABORT_REQ:
		/* FIXME handle abort request appropriately */
		break;

	default:
		return -1; /* unknown command specifier */
	}

	return new_reply;
}

static int sdoinfo_request(unsigned char buffer[], unsigned size)
{
	struct _sdo_info_header infoheader;
	struct _sdo_info_header response;
	unsigned char data[CO_MAX_DATA_SIZE-6]; /* quark */
	unsigned datasize = CO_MAX_DATA_SIZE-6;
	unsigned abortcode = 0;
	unsigned servicedata = 0;
	int new_reply = 0;

	int i = 0;
	unsigned index, subindex, valueinfo;
	struct _sdoinfo_entry_description desc;

	infoheader.opcode = buffer[2]&0x07;
	infoheader.incomplete = (buffer[2]>>7)&0x01;
	infoheader.fragmentsleft = buffer[4] | ((unsigned)buffer[5]>>8);

	if (size>(CO_MAX_DATA_SIZE-6)) {
		printstrln("[sdoinfo_request()] error size is much larger than expected\n");
		return 0;
	}

	switch (infoheader.opcode) {
	case CO_SDOI_GET_ODLIST_REQ: /* answer with CO_SDOI_GET_ODLIST_RSP */
		servicedata = (((unsigned)buffer[6])&0xff) | ((((unsigned)buffer[7])>>8)&0xff);
		/* DEBUG output: */
		//printstr("[DEBUG SDO INFO] get OD list: 0x"); printhexln(servicedata);
		new_reply = getODListRequest(servicedata);
		break;

	case CO_SDOI_OBJDICT_REQ: /* answer with CO_SDOI_OBJDICT_RSP */
		servicedata = ((unsigned)buffer[6]&0xff) | (((unsigned)buffer[7]<<8)&0xff00);
		/* here servicedata holds the index of the requested object description */
		canod_get_object_description(desc, servicedata);

		data[0] = desc.index&0xff;
		data[1] = (desc.index>>8)&0xff;
		data[2] = desc.dataType&0xff;
		data[3]	= (desc.dataType>>8)&0xff;
		    data[4] = desc.value;
		data[5]	= desc.objectCode;
		for (i=0; desc.name[i] != '\0'; i++) {
			data[i+6]	= desc.name[i];
		}

		response.fragmentsleft = 0;
		response.incomplete = 0;
		response.opcode = CO_SDOI_OBJDICT_RSP;

		new_reply = build_sdoinfo_reply(response, data, 6+i);
		break;

	case CO_SDOI_ENTRY_DESCRIPTION_REQ: /* answer with CO_SDOI_ENTRY_DESCRIPTION_RSP */
		index = ((unsigned)buffer[6]&0xff) | ((((unsigned)buffer[7])<<8)&0xff00);
		subindex = buffer[8];
		valueinfo = buffer[9]; /* bitmask which elements should be in the response - bit 1,2 and 3 = 0 (reserved) */

		canod_get_entry_description(index, subindex, valueinfo, desc);
		response.fragmentsleft = 0;
		response.incomplete = 0;
		response.opcode = CO_SDOI_ENTRY_DESCRIPTION_RSP;

		datasize = 0;

		data[datasize++] = desc.index&0xff;
		data[datasize++] = ((desc.index)>>8)&0xff;
		data[datasize++] = desc.subindex&0xff;
		data[datasize++] = 0; /*valueinfo&0x78;*/ /* restrict to specified bits */

		data[datasize++] = desc.dataType&0xff;
		data[datasize++] = (desc.dataType>>8)&0xff;

		data[datasize++] = desc.bitLength&0xff;
		data[datasize++] = (desc.bitLength>>8)&0xff;

		data[datasize++] = desc.objectAccess&0xff;
		data[datasize++] = (desc.objectAccess>>8)&0xff;

#if 0
		/* repeat data type (know as unit type) [DWORD] */
		data[datasize++] = desc.dataType&0xff;
		data[datasize++] = (desc.dataType>>8)&0xff;
		//data[datasize++] = 0x00;
		//data[datasize++] = 0x00;

		/* FIXME refactor for more generality */
		switch (desc.bitLength/8) {
		case 1:
			data[datasize++] = desc.value&0xff;
#if 0
			/* min value */
			data[datasize++] = 0x00;
			/* max value */
			data[datasize++] = 0xff;
#endif
			break;

		case 2:
			data[datasize++] = desc.value&0xff;
			data[datasize++] = (desc.value>>8)&0xff;
			//data[datasize] = 0x00;
			//data[datasize] = 0x00;
#if 0
			/* min value */
			data[datasize++] = 0x00;
			data[datasize++] = 0x00;
			/* max value */
			data[datasize++] = 0xff;
			data[datasize++] = 0xff;
#endif
			break;

		case 4:
			data[datasize++] = desc.value&0xff;
			data[datasize++] = (desc.value>>8)&0xff;
			data[datasize++] = (desc.value>>16)&0xff;
			data[datasize++] = (desc.value>>24)&0xff;
#if 0
			/* min value */
			data[datasize++] = 0x00;
			data[datasize++] = 0x00;
			data[datasize++] = 0x00;
			data[datasize++] = 0x00;
			/* max value */
			data[datasize++] = 0xff;
			data[datasize++] = 0xff;
			data[datasize++] = 0xff;
			data[datasize++] = 0xff;
#endif
			break;
		}
#endif

		/* this should only be included if enough space is available in the report */
		if ((datasize+6)<CO_MAX_DATA_SIZE) {
			for (int i=0; desc.name[i] != '\0'; i++) {
				data[datasize++] = desc.name[i];
			}
		}

		new_reply = build_sdoinfo_reply(response, data, datasize);

		break;

	case CO_SDOI_INFO_ERR_REQ: /* FIXME check abort code and take action */
		abortcode = ((unsigned)buffer[6]&0xff) |
			(((unsigned)buffer[7]<<8)&0xff) |
			(((unsigned)buffer[8]<<16)&0xff) |
			(((unsigned)buffer[9]<<24)&0xff);
		printstr("[SDO INFO] Error request receiveied 0x");
		printhexln(abortcode);
		/* FIXME do something appropriate  */
		break;

	default:
		printstr("[SDO INFO] Error unknown opcode 0x");
		printhexln(infoheader.opcode);
		return -1;
	}

	return new_reply;
}
