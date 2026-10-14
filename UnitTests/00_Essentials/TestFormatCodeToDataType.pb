EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


Macro TestFormatToType(TestedFormatCode, ExpectedDataType, TestMessage)
    AssertEqualsA(MsgPackFormatCodeToDataType(TestedFormatCode), ExpectedDataType, TestMessage)
EndMacro

TestFormatToType(#MsgPack_FormatCode_Null,           #MsgPack_DataTypes_Null,      "Null -> Null")
TestFormatToType(#MsgPack_FormatCode_False,          #MsgPack_DataTypes_Boolean,   "False -> Boolean")
TestFormatToType(#MsgPack_FormatCode_True,           #MsgPack_DataTypes_Boolean,   "True -> Boolean")
TestFormatToType(#MsgPack_FormatCode_FixIntPositive, #MsgPack_DataTypes_Integer,   "FixIntPositive -> Integer")
TestFormatToType(#MsgPack_FormatCode_FixIntNegative, #MsgPack_DataTypes_Integer,   "FixIntNegative -> Integer")
TestFormatToType(#MsgPack_FormatCode_UInt8,          #MsgPack_DataTypes_Integer,   "UInt8 -> Integer")
TestFormatToType(#MsgPack_FormatCode_UInt16,         #MsgPack_DataTypes_Integer,   "UInt16 -> Integer")
TestFormatToType(#MsgPack_FormatCode_UInt32,         #MsgPack_DataTypes_Integer,   "UInt32 -> Integer")
TestFormatToType(#MsgPack_FormatCode_UInt64,         #MsgPack_DataTypes_Integer,   "UInt64 -> Integer")
TestFormatToType(#MsgPack_FormatCode_Int8,           #MsgPack_DataTypes_Integer,   "Int8 -> Integer")
TestFormatToType(#MsgPack_FormatCode_Int16,          #MsgPack_DataTypes_Integer,   "Int16 -> Integer")
TestFormatToType(#MsgPack_FormatCode_Int32,          #MsgPack_DataTypes_Integer,   "Int32 -> Integer")
TestFormatToType(#MsgPack_FormatCode_Int64,          #MsgPack_DataTypes_Integer,   "Int64 -> Integer")
TestFormatToType(#MsgPack_FormatCode_Float32,        #MsgPack_DataTypes_Float,     "Float32 -> Float")
TestFormatToType(#MsgPack_FormatCode_Float64,        #MsgPack_DataTypes_Float,     "Float64 -> Float")
TestFormatToType(#MsgPack_FormatCode_FixStr,         #MsgPack_DataTypes_String,    "FixStr -> String")
TestFormatToType(#MsgPack_FormatCode_Str8,           #MsgPack_DataTypes_String,    "Str8 -> String")
TestFormatToType(#MsgPack_FormatCode_Str16,          #MsgPack_DataTypes_String,    "Str16 -> String")
TestFormatToType(#MsgPack_FormatCode_Str32,          #MsgPack_DataTypes_String,    "Str32 -> String")
TestFormatToType(#MsgPack_FormatCode_Bin8,           #MsgPack_DataTypes_Binary,    "Bin8 -> Binary")
TestFormatToType(#MsgPack_FormatCode_Bin16,          #MsgPack_DataTypes_Binary,    "Bin16 -> Binary")
TestFormatToType(#MsgPack_FormatCode_Bin32,          #MsgPack_DataTypes_Binary,    "Bin32 -> Binary")
TestFormatToType(#MsgPack_FormatCode_FixArray,       #MsgPack_DataTypes_Array,     "FixArray -> Array")
TestFormatToType(#MsgPack_FormatCode_Array16,        #MsgPack_DataTypes_Array,     "Array16 -> Array")
TestFormatToType(#MsgPack_FormatCode_Array32,        #MsgPack_DataTypes_Array,     "Array32 -> Array")
TestFormatToType(#MsgPack_FormatCode_FixMap,         #MsgPack_DataTypes_Map,       "FixMap -> Map")
TestFormatToType(#MsgPack_FormatCode_Map16,          #MsgPack_DataTypes_Map,       "Map16 -> Map")
TestFormatToType(#MsgPack_FormatCode_Map32,          #MsgPack_DataTypes_Map,       "Map32 -> Map")
TestFormatToType(#MsgPack_FormatCode_FixExt1,        #MsgPack_DataTypes_Extension, "FixExt1 -> Extension")
TestFormatToType(#MsgPack_FormatCode_FixExt2,        #MsgPack_DataTypes_Extension, "FixExt2 -> Extension")
TestFormatToType(#MsgPack_FormatCode_FixExt4,        #MsgPack_DataTypes_Extension, "FixExt4 -> Extension")
TestFormatToType(#MsgPack_FormatCode_FixExt8,        #MsgPack_DataTypes_Extension, "FixExt8 -> Extension")
TestFormatToType(#MsgPack_FormatCode_FixExt16,       #MsgPack_DataTypes_Extension, "FixExt16 -> Extension")
TestFormatToType(#MsgPack_FormatCode_Ext8,           #MsgPack_DataTypes_Extension, "Ext8 -> Extension")
TestFormatToType(#MsgPack_FormatCode_Ext16,          #MsgPack_DataTypes_Extension, "Ext16 -> Extension")
TestFormatToType(#MsgPack_FormatCode_Ext32,          #MsgPack_DataTypes_Extension, "Ext32 -> Extension")
TestFormatToType(#MsgPack_FormatCode_Invalid,        #MsgPack_DataTypes_Unknown,   "Invalid -> Unknown")


If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
