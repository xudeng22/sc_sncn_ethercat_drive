# vim: set ts=4 set expandtab:
import output_strings

import xmltodict
from enum import Enum

EsiFile = './SOMANET_CiA_402.xml'


# object type enumeration

# currently no destinction in which state we are
class Access(Enum):
    RO = 0
    RW = 1
    WO = 2


class PdoMap(Enum):
    NONE = 0
    RXPDO = 1
    TXPDO = 2
    RXTXPDO = 3


class ObjectType(Enum):
    UNKNOWN = 0
    VAR = 1
    ARRAY = 2
    RECORD = 3


class DataType(Enum):
    UNKNOWN = 0
    SINT = 1
    USINT = 2
    INT = 3
    UINT = 3
    DINT = 4
    UDINT = 5
    REAL = 6


class entry(object):

    def __init__(self, subindex):
        self.subindex = subindex  # subindex is kind of redundant
        self.value = 0
        self.max_value = 0
        self.min_value = 0
        self.default = 0
        self.accessRights = Access.RW
        self.pdoMappable = PdoMap.NONE
        self.bitsize = 0
        self.name = ""
        self.etype = DataType.UNKNOWN

    @staticmethod
    def getType(tdesc):
        # dictionary access, second argument is the default if first is not
        # found
        return {
            'SINT': DataType.SINT,
            'USINT': DataType.USINT,
            'INT': DataType.INT,
            'UINT': DataType.UINT,
            'DINT': DataType.DINT,
            'UDINT': DataType.UDINT,
            'REAL': DataType.REAL,
        }.get(tdesc, DataType.UNKNOWN)

    @staticmethod
    def getTypeString(t):
        return {
            DataType.SINT: "SINT",
            DataType.USINT: "USINT",
            DataType.INT: "INT",
            DataType.UINT: "UINT",
            DataType.DINT: "DINT",
            DataType.UDINT: "UDINT",
            DataType.REAL: "REAL",
        }.get(t, "Unknown")


class object(object):

    def __init__(self, index, name, otype=ObjectType.UNKNOWN):
        self.index = index
        self.name = name
        self.otype = otype
        self.entry_count = 0
        self.entry = []

    def add_entry(self, entries):
        self.entry.append(entries)          # list of class entries
        self.entry_count = self.entry_count + 1

    def print_ccode(self):
        # print "struct _object object_"
        print "Object Index: {} Name: {}".format(self.index, self.name)

        i = 0
        for e in self.entry:
            print "| Entry: {} ({}) with type {}".format(
                                                e.subindex, i,
                                                entry.getTypeString(e.etype))
            i = i + 1


# check for data type if it's of array type
def data_type_is_array(data_type_description, max_subindex):
    list_items = len(data_type_description['SubItem'])

    if 'SubIdx' in data_type_description['SubItem'][1]:
        return False

    if list_items <= max_subindex:
        return True

    else:
        return False


def data_type_subitem(data_type, idx):
    if 'SubItem' in data_type:
        for item in data_type['SubItem']:
            print item['Name']
            if item['SubIdx'] == idx:
                return item


# Find a specific entry in the data_type area
# The DataType for RECORD and ARRAY is determined by DTxxxx
def find_data_type_entry(objtype, data_type):
    for t in data_type:
        if objtype == t['Name']:
            return t

    return None


# FIXME add access rights for the entry!
def get_entry_data_type(data_type, objtype, entry):
    dt_entry = find_data_type_entry(objtype, data_type)
    if dt_entry is None:
        raise Exception("dt_entry {} not found".format(dt_entry))

    if len(dt_entry['SubItem']) > entry.subindex:
        dt = dt_entry['SubItem'][entry.subindex]
    else:
        dt = dt_entry['SubItem'][1]

    basetype = entry.getType(dt['Type'])
    if basetype == DataType.UNKNOWN:
        dte = find_data_type_entry(dt['Type'], data_type)
        entry.etype = entry.getType(dte['BaseType'])
    else:
        entry.etype = entry.getType(dt['Type'])
        # e.accessRights = dt['

def write_dictionary(objects)
    dictionary_source = "co_dictionary.c"
    dictionary_header = "co_dictionary.h"
    # may add defines for dictionary symbols? dictionary_symbols = "dictionary_symbols.h"

    open(dictionary_source) as dsrc_fd
    open(dictionary_header) as dhead_fd

#
# parse the ESI
#

with open(EsiFile) as fd:
    esi = xmltodict.parse(fd.read())

# set objdict to the objects section of the dictionary.
# The object-objects appear as list of items, since repeating tags are
# considered to be lists,
# I assign this list to the object variable.
objdict = (esi['EtherCATInfo']['Descriptions']['Devices']['Device']['Profile']
           ['Dictionary']['Objects']['Object'])

# The data types are important for complex data types where much object
# information and some entry information are stored.
dataTypes = (esi['EtherCATInfo']['Descriptions']['Devices']['Device']
             ['Profile']['Dictionary']['DataTypes']['DataType'])

# print objdict['Object'][0]['Index']

# list all the objects in the dictionary
dictionary_objects = []

for obj in objdict:
    o = object(obj['Index'], obj['Name'])

    max_subindex = 0

    # VAR is a simple object
    if 'DefaultData' in obj['Info']:
        e = entry(0)
        e.value = obj['Info']['DefaultData']
        e.name = o.name
        e.etype = entry.getType(obj['Type'])
        o.add_entry(e)
        o.otype = ObjectType.VAR

    # Complex objects ARRAY and RECORD
    else:
        t = find_data_type_entry(obj['Type'], dataTypes)

        if t is None:
            raise Exception("No matching data type found {}".format(
                                    obj['Type']))

        if type(obj['Info']['SubItem']) is list:
            max_subindex = obj['Info']['SubItem'][0]['Info']['DefaultData']
        else:
            max_subindex = obj['Info']['SubItem']['Info']['DefaultData']

        print "Object {}".format(o.index)
        if data_type_is_array(t, max_subindex):
            # print "Object {} is ARRAY".format(o.index)
            o.otype = ObjectType.ARRAY

        else:
            # print "Object {} is RECORD".format(o.index)
            o.otype = ObjectType.RECORD

        if type(obj['Info']['SubItem']) is list:
            i = 0
            for sub in obj['Info']['SubItem']:
                e = entry(i)
                e.name = sub['Name']
                e.value = sub['Info']['DefaultData']

                # update this entry with type informations
                get_entry_data_type(dataTypes, obj['Type'], e)

                o.add_entry(e)
                i = i + 1

        else:   # Empty Array
            print "*** Empty SubItem List - i.e. only one element"
            sub = obj['Info']['SubItem']
            e = entry(0)
            e.value = sub['Info']['DefaultData']

            # update this entry with type informations
            get_entry_data_type(dataTypes, obj['Type'], e)

            o.add_entry(e)

    dictionary_objects.append(o)

# Debug output of the parsed dictionary
for o in dictionary_objects:
    o.print_ccode()
