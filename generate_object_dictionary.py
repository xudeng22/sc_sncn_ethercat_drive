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


class object(object):
    index = 0
    otype = ObjectType.UNKNOWN
    entry_count = 0
    entry = []
    name = ""

    def __init__(self, index, name, otype):
        self.name = name
        self.index = index
        self.otype = otype

    def add_entry(entries):
        entry.append(entries)          # list of entries of class entries
        entry_count = entries.length

    def print_ccode():
        print "struct _object object_"

# parse the ESI

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

for obj in objdict:
    print obj['Index']
