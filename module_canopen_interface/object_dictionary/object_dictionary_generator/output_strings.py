#
# file: output_strings.py
#
# Static definition of output templates for file generation
#

# NOTE: use with ObjectListEntry.format(index=<value>, ...)

ObjectListHeader = "static COD_Object object_dictionary[] = {{"
ObjectListFooter = "}};"
ObjectListEntry = """{{ {index}, {type}, {acccess}, {entry_coutn}, {name_ptr},
{entry_ptr} }},"""

EntryListHeader = "static COD_Entry object_entries[] = {{"
EntryListFooter = "}};"
EntryListEntry = """{{
CODE_SET_ENTRY_INDEX({index},{subindex},0),
{data_type}, {bitlength}, {access}, {unit}, {name_ptr}, {value_ptr},
{default_ptr}, {min_ptr}, {max_ptr}
}},"""


# TODO some objects are read only and only have default value. In this
# situation value[k] == default[j] no need to store doubled values.
# PDOs also have no default value since they transmit the current values.

# TODO since `0` is a very common default value define `default[0] = 0` as
# generic null value. To reduce size a little bit.
# This contradicts the assumption that ValueList can be copied to
# DefaultValueList!

# how to fill the values???
#
# - Individual values are LSB first
# - Individual values are no longer than min(VALUE_DATATYPE) <= bitsize
#   (in other words, the contents are byte aligned.
# - I need either {overallsize} or enough values to fill the array, maybe both
#   is a good hint for the compiler and can help find errors
# - Need to keep track of the starting indexes (automatically add this to the
#   EntryList pointer construction.

ValueListStart = """static uint8_t values[{overallsize}] = {{"""
ValueListEntry = """{bytearray}"""  # example for 32bit value "b0, b1, b3, b4,"
ValueListEnd = """}};"""

# TODO since the ValueList is in the very beginning a copy of DefaultList
# the values can be just copied without the loss of generalization.
# i.e. except for *ListStart everything else stay the same
DefaultListStart = """static const uint8_t default[{overallsize}] = {{"""
DefaultListEntry = """{bytearray}"""  # example for 32bit value "b0, b1, b3, b4,"
DefaultListEnd = """}};"""

# Min/Max is not necessarily complete, not all object entries have min and/or
# max values
# NOTE see also ValueList and DefaultList construction
MinList = """static uint8_t minimum[{overallsize}] = { 0 };"""
MaxList = """static uint8_t maximum[{overallsize}] = { 0 };"""
