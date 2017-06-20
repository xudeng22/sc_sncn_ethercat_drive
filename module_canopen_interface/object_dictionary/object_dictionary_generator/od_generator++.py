#
# **DEPRECATED** This generates the object dictionary for SOMANET SDK 3.0 and prior
#

import re
import sys


d_datatypes = {
    0x0001:         "DEFTYPE_BOOLEAN",
    0x0002:        "DEFTYPE_INTEGER8",
    0x0003:       "DEFTYPE_INTEGER16",
    0x0004:       "DEFTYPE_INTEGER32",
    0x0005:       "DEFTYPE_UNSIGNED8",
    0x0006:      "DEFTYPE_UNSIGNED16",
    0x0007:      "DEFTYPE_UNSIGNED32",
    0x0008:          "DEFTYPE_REAL32",
    0x0009:  "DEFTYPE_VISIBLE_STRING",
    0x000A:    "DEFTYPE_OCTET_STRING",
    0x000B:  "DEFTYPE_UNICODE_STRING",
    0x000C:     "DEFTYPE_TIME_OF_DAY",
    0x000D: "DEFTYPE_TIME_DIFFERENCE",
}

d_objecttype = {
    0x0:    "CANOD_TYPE_DOMAIN",
    0x5:   "CANOD_TYPE_DEFTYPE",
    0x6: "CANOD_TYPE_DEFSTRUCT",
    0x7:       "CANOD_TYPE_VAR",
    0x8:     "CANOD_TYPE_ARRAY",
    0x9:    "CANOD_TYPE_RECORD",
}


print '\n'
print '#'*42
print '# Welcome to Object Dictionary Generator #'
print '#'*42
print '\n'
NODE_ID = 1#raw_input(' Enter Node ID of CANOpen Device : ')
print '\n'

#FILE_NAME = raw_input(' Enter EDS file name of CANOpen Device with extension as .eds : ')
print '\n'

try:  
  fp=open(sys.argv[1])
except:
  print 'Error!, Name of file should be "CO_EDS_401.eds"\n'
  sys.exit(1)

od_list = []
subindex_counter = 0
pdocnt = ''

len_max_string = 0

for line in fp:
  od_entry = []
  if (line.find('NrOfTXPDO') == 0):
    line = line.replace('NrOfTXPDO=','').replace('\n', '')
    pdocnt = line

  if(line.find('[') == 0):
    index = line.replace('[','').replace(']\n','')
    if(index.find('sub') == 4):
      index,si = index.split('sub')
      subindex_counter += 1
    else:
      si = '0'  
  if(line.find('DataType') == 0):
    line = line.replace('DataType=','').replace('\n','')
    dtype = line
  
  if(line.find('AccessType') == 0):
    line = line.replace('AccessType=','').replace('\n','')
    if line.upper() == 'CONST':
      line = 'RO'
    elif line.upper() == 'RWW':
      line = 'RW'
    atype = line

  if(line.find('ObjectType') == 0):
    line = line.replace('ObjectType=','').replace('\n','')
    otype = line

  if (line.find('ParameterName') == 0):
    line = line.replace('ParameterName=', '').replace('\n', '')
    if len(line) > len_max_string:
      len_max_string = len(line)
    name = line
    
  if(line.find('DefaultValue') == 0):
    line = line.replace('DefaultValue=','').replace('\n','')

    line = line.replace('$NODEID+','').replace('\n','')
    #if line.find('$NODEID') >= 0:
     # value = re.sub(r'\+?\$NODEID\+?', '', line)
      #line = str(hex(int(value, 16) + NODE_ID))

    od_entry.append(index)
    od_entry.append(si)
    od_entry.append(dtype)
    od_entry.append(otype)

    od_entry.append(atype)
    od_entry.append(line)
    od_entry.append(name)
    if int(dtype, 16) != 0x9:
      od_list.append(od_entry)

file_ptr = open('dictionary.h','w')

file_ptr.write(
"""#ifndef DICTIONARY_H_
#define DICTIONARY_H_

#include "common.h"

#define NUMBER_OF_SUBINDEX """
+ str(len(od_list)) +
"""
#define PDO_COUNT """ + pdocnt +
#+ str(subindex_counter) +

"""

struct _sdoinfo_entry_description SDO_Info_Entries[] = {
""")

for entry in od_list:
  datatype = int(entry[2], 16)
  if datatype != 0x9:
    file_ptr.write('{ ')
    file_ptr.write('0x'+ entry[0]) # Index
    file_ptr.write(', ')
    file_ptr.write('0x'+ entry[1]) # Subindex
    file_ptr.write(', ')
    file_ptr.write('0')
    file_ptr.write(', ')
    file_ptr.write(d_datatypes[datatype]) # Data type
    file_ptr.write(', ')
    file_ptr.write(d_objecttype[int(entry[3], 16)]) # Object type
    file_ptr.write(', ')
    if (datatype == 0x1 or datatype == 0x2 or datatype == 0x5):
      file_ptr.write('8')
    elif (datatype == 0x3 or datatype == 0x6):
      file_ptr.write('16')
    elif (datatype == 0x4 or datatype == 0x7 or datatype == 0x8):
      file_ptr.write('32')
    else:
      file_ptr.write('0')
    file_ptr.write(', ')
    file_ptr.write(entry[4].upper()) # Access type
    file_ptr.write(', ')
    if datatype == 0x9:
      file_ptr.write('"'+entry[5]+'"') # Value  
    else:
      file_ptr.write(entry[5]) # Value  
    file_ptr.write(', ')
    file_ptr.write('"'+entry[6]+'"') # Name
    file_ptr.write(' },\n')

file_ptr.write('{ 0, 0, 0, 0, 0, 0, 0, 0, "\\0" }\n};\n#endif\n')  

file_ptr.close()

print "Max string length: ", len_max_string