# vim: set ts=4 set expandtab:
import xmltodict

EsiFile = './SOMANET_CiA_402.xml'

class object(object):
    index = 0
    otype = NONE

    def __init__(self, index, name)
        self.name = name
	self.index = index

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
