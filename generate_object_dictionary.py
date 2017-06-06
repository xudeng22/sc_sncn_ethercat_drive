# vim: set ts=4 set expandtab:
import xmltodict

from enum import Enum

EsiFile = './SOMANET_CiA_402.xml'


# object type enumeration
class ObjectType(Enum):
    UNKNOWN = 0
    VAR = 1
    ARRAY = 2
    RECORD = 3


class object(object):
    index = 0
    otype = ObjectType.UNKNOWN

    def __init__(self, index, name, otype):
        self.name = name
        self.index = index
        self.otype = otype

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
