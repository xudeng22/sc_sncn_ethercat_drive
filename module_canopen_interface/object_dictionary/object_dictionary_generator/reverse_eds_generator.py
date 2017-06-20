#
# **DEPRECATED** This generates the object dictionary for SOMANET SDK 3.0 and prior
#

import re
import sys

d_datatypes = {
    "DEFTYPE_BOOLEAN":         "0x0001",
    "DEFTYPE_INTEGER8":        "0x0002",
    "DEFTYPE_INTEGER16":       "0x0003",
    "DEFTYPE_INTEGER32":       "0x0004",
    "DEFTYPE_UNSIGNED8":       "0x0005",
    "DEFTYPE_UNSIGNED16":      "0x0006",
    "DEFTYPE_UNSIGNED32":      "0x0007",
    "DEFTYPE_REAL32":          "0x0008",
    "DEFTYPE_VISIBLE_STRING":  "0x0009",
    "DEFTYPE_OCTET_STRING":    "0x000A",
    "DEFTYPE_UNICODE_STRING":  "0x000B",
    "DEFTYPE_TIME_OF_DAY":     "0x000C",
    "DEFTYPE_TIME_DIFFERENCE": "0x000D",
}

d_objecttype = {
    "CANOD_TYPE_DOMAIN":    "0x0",
    "CANOD_TYPE_DEFTYPE":   "0x5",
    "CANOD_TYPE_DEFSTRUCT": "0x6",
    "CANOD_TYPE_VAR":       "0x7",
    "CANOD_TYPE_ARRAY":     "0x8",
    "CANOD_TYPE_RECORD":    "0x9",
}

re_od_line = re.compile(r'{(?P<index>.+), *(?P<sub>.+), *(?P<value_info>.+), *(?P<datatype>.+), *(?P<objecttype>.+), *(?P<bitlength>.+), *(?P<access>.+), *(?P<value>.+), *(?P<name>.+) *},')

fp=open(sys.argv[1], 'r')

output = ''
indexes = []

pdo_mapping = []

optional_obj = []
manufacurer_obj = []

num_of_elem = 0

array = 0

for l in fp:
    string = """
    [<index>sub<sub>]
    ParameterName=<name>
    ObjectType=<objecttype>
    DataType=<datatype>
    AccessType=<access>
    DefaultValue=<value>
    PDOMapping=<pdomapping>

    """

    record_description = """
    [<index>]
    ParameterName=<name>
    ObjectType=<objecttype>
    SubNumber=<subnumber>

    """

    number_of_elements = """
    [<index>sub0]
    ParameterName=Number of Elements
    ObjectType=0x7
    DataType=0x0005
    AccessType=ro
    DefaultValue=<number_of_elements>
    PDOMapping=0

    """

    res = re_od_line.search(l)


    if res:
        index = res.group('index').replace('0x','').replace(' ', '')
        sub_index = res.group('sub')
        name = res.group('name').replace('"', '')
        objecttype = res.group('objecttype')
        datatype = res.group('datatype')
        access = res.group('access')
        value = res.group('value')

        if not index in indexes:
            indexes.append(index)

        num_index = int(index, 16)
        if  ( (0x1000 <= num_index <= 0x1fff) or (0x6000 <= num_index <= 0xffff) ) and not num_index in optional_obj:
            optional_obj.append(num_index)

        if  0x2000 <= num_index <= 0x5fff and not num_index in manufacurer_obj:
            manufacurer_obj.append(num_index)

        if (objecttype == "CANOD_TYPE_ARRAY" \
        or objecttype == "CANOD_TYPE_RECORD") and int(sub_index) == 0 and array == 0:
            record_description = record_description.replace('<index>', index)
            record_description = record_description.replace('<name>', name)
            record_description = record_description.replace('<objecttype>', d_objecttype[objecttype] )
            record_description = record_description.replace('<subnumber>', str(int(value, 16)+1) )

            #number_of_elements = number_of_elements.replace('<index>', index)
            num_of_elem = int(value, 16)
            #number_of_elements = number_of_elements.replace('<number_of_elements>', str(num_of_elem) )
            #print "array found: %s with %d elements" % (index, num_of_elem)
            array = 1

        if ( (objecttype == "CANOD_TYPE_DOMAIN") or (objecttype == "CANOD_TYPE_DEFTYPE") 
            or (objecttype == "CANOD_TYPE_VAR") ) and int(sub_index) == 0:
            print "single entry"
            string = string.replace('sub<sub>', '')



        string = string.replace('<index>', index)
        string = string.replace('<sub>', sub_index)
        string = string.replace('<name>', name)
        string = string.replace('<objecttype>', d_objecttype[objecttype] )
        string = string.replace('<datatype>', d_datatypes[datatype] )
        string = string.replace('<access>', access)
        string = string.replace('<value>', value)

        if ( (int(index, 16) >= 0x1600 and int(index, 16) <= 0x17ff) or \
        (int(index, 16) >= 0x1a00 and int(index, 16) <= 0x1bff) ) and len(value) == 10:
            pdo_mapping.append(value[2:-4])            
            string = string.replace('<pdomapping>', '0')
        elif index in pdo_mapping:
            string = string.replace('<pdomapping>', '1')
        else:
            string = string.replace('<pdomapping>', '0')

        #print string

        if array == 1:
            output += record_description
            array = 2 

        if num_of_elem == int(sub_index) and array == 2:
            #print "array end"
            array = 0

        output += string


fp.close()

fp=open('generated_EDS_file', 'w')
fp.write(output)

fp.write('\n[OptionalObjects]\n')
fp.write('SupportedObjects=%d\n' % (len(optional_obj)) )
num = 1
for i in optional_obj:
    fp.write(str(num) + '=')
    fp.write('0x%x\n' % (i) )
    num += 1

fp.write('\n[ManufacturerObjects]\n')
fp.write('SupportedObjects=%d\n' % (len(manufacurer_obj)) )
num = 1
for i in manufacurer_obj:
    fp.write(str(num) + '=')
    fp.write('0x%x\n' % (i) )
    num += 1
fp.close()