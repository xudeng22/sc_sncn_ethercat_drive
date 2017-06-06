# vim: set ts=4 set expandtab:
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


class entry(object):
    subindex = 0  # kind of redundant
    value = 0
    max_value = 0
    min_value = 0
    default = 0
    dataType = DataType.UNKNOWN
    accessRights = Access.RW
    pdoMappable = PdoMap.NONE
    bitsize = 0
    name = ""

    def __init__(self, subindex):
        self.subindex = subindex

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
        }.get(tdesc, DataType.UNKNOWN)


class object(object):
    index = 0
    otype = ObjectType.UNKNOWN
    entry_count = 0
    entry = []
    name = ""

    def __init__(self, index, name, otype=ObjectType.UNKNOWN):
        self.name = name
        self.index = index
        self.otype = otype

    def add_entry(self, entries):
        entry.append(entries)          # list of class entries
        entry_count = entries.length

    def print_ccode(self):
        # print "struct _object object_"
        print "Object Index: {} Name: {}".format(self.index, self.name)

        for e in self.entry:
            print "Entry: {} ({}) with type {}".format(
                                                e.subindex, e.name, e.etype)

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
    print "Processing Object: {}".format(obj['Index'])

    o = object(obj['Index'], obj['Name'])

    if 'DefaultData' in obj['Info']:
        print "create single element entry"
        e = entry(0)
        e.value = obj['Info']['DefaultData']
        e.name = o.name
        e.etype = entry.getType(obj['Type'])
        o.entry.append(e)
        o.otype = ObjectType.VAR

    else:
        print "iterate through <SubItems> and create entry each"

    dictionary_objects.append(o)

for o in dictionary_objects:
    o.print_ccode()
