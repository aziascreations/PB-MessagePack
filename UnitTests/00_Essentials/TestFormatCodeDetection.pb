
EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"

; Note: The checks were done on the table in the spec.
;       I didn't go with my own constants to avoid missing a discrepency.


Define *BufferHolder.MsgPackData = MsgPackCreate(1)

; 0x00 - 0x7F
Define iFixIntCode.a

; Positive FixInt
For iFixIntCode = $00 To $7F
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixIntPositive,
                  Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixIntPositive")
Next

; FixMap
For iFixIntCode = $80 To $8F
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixMap,
                  Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixMap")
Next

; FixArray
For iFixIntCode = $90 To $9F
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixArray,
                  Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixArray")
Next

; FixStr
For iFixIntCode = $A0 To $BF
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixStr,
                  Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixStr")
Next

; Others singles

Macro TestSingleCode(TestedFormatCode, ExpectedFormatCode, FormatCodeText)
    PokeA(*BufferHolder\Buffer, TestedFormatCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), ExpectedFormatCode,
                  Str(iFixIntCode) + " resolves to " + FormatCodeText)
EndMacro

TestSingleCode($C0, #MsgPack_FormatCode_Null,     "#MsgPack_FormatCode_Null")
TestSingleCode($C1, #MsgPack_FormatCode_Invalid,  "#MsgPack_FormatCode_Invalid")
TestSingleCode($C2, #MsgPack_FormatCode_False,    "#MsgPack_FormatCode_False")
TestSingleCode($C3, #MsgPack_FormatCode_True,     "#MsgPack_FormatCode_True")
TestSingleCode($C4, #MsgPack_FormatCode_Bin8,     "#MsgPack_FormatCode_Bin8")
TestSingleCode($C5, #MsgPack_FormatCode_Bin16,    "#MsgPack_FormatCode_Bin16")
TestSingleCode($C6, #MsgPack_FormatCode_Bin32,    "#MsgPack_FormatCode_Bin32")
TestSingleCode($C7, #MsgPack_FormatCode_Ext8,     "#MsgPack_FormatCode_Ext8")
TestSingleCode($C8, #MsgPack_FormatCode_Ext16,    "#MsgPack_FormatCode_Ext16")
TestSingleCode($C9, #MsgPack_FormatCode_Ext32,    "#MsgPack_FormatCode_Ext32")
TestSingleCode($CA, #MsgPack_FormatCode_Float32,  "#MsgPack_FormatCode_Float32")
TestSingleCode($CB, #MsgPack_FormatCode_Float64,  "#MsgPack_FormatCode_Float64")
TestSingleCode($CC, #MsgPack_FormatCode_UInt8,    "#MsgPack_FormatCode_UInt8")
TestSingleCode($CD, #MsgPack_FormatCode_UInt16,   "#MsgPack_FormatCode_UInt16")
TestSingleCode($CE, #MsgPack_FormatCode_UInt32,   "#MsgPack_FormatCode_UInt32")
TestSingleCode($CF, #MsgPack_FormatCode_UInt64,   "#MsgPack_FormatCode_UInt64")
TestSingleCode($D0, #MsgPack_FormatCode_Int8,     "#MsgPack_FormatCode_Int8")
TestSingleCode($D1, #MsgPack_FormatCode_Int16,    "#MsgPack_FormatCode_Int16")
TestSingleCode($D2, #MsgPack_FormatCode_Int32,    "#MsgPack_FormatCode_Int32")
TestSingleCode($D3, #MsgPack_FormatCode_Int64,    "#MsgPack_FormatCode_Int64")
TestSingleCode($D4, #MsgPack_FormatCode_FixExt1,  "#MsgPack_FormatCode_FixExt1")
TestSingleCode($D5, #MsgPack_FormatCode_FixExt2,  "#MsgPack_FormatCode_FixExt2")
TestSingleCode($D6, #MsgPack_FormatCode_FixExt4,  "#MsgPack_FormatCode_FixExt4")
TestSingleCode($D7, #MsgPack_FormatCode_FixExt8,  "#MsgPack_FormatCode_FixExt8")
TestSingleCode($D8, #MsgPack_FormatCode_FixExt16, "#MsgPack_FormatCode_FixExt16")
TestSingleCode($D9, #MsgPack_FormatCode_Str8,     "#MsgPack_FormatCode_Str8")
TestSingleCode($DA, #MsgPack_FormatCode_Str16,    "#MsgPack_FormatCode_Str16")
TestSingleCode($DB, #MsgPack_FormatCode_Str32,    "#MsgPack_FormatCode_Str32")
TestSingleCode($DC, #MsgPack_FormatCode_Array16,  "#MsgPack_FormatCode_Array16")
TestSingleCode($DD, #MsgPack_FormatCode_Array32,  "#MsgPack_FormatCode_Array32")
TestSingleCode($DE, #MsgPack_FormatCode_Map16,    "#MsgPack_FormatCode_Map16")
TestSingleCode($DF, #MsgPack_FormatCode_Map32,    "#MsgPack_FormatCode_Map32")

; Negative FixInt
For iFixIntCode = $E0 To $FF
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixIntNegative,
                  Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixIntNegative")
Next


; ...


If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
