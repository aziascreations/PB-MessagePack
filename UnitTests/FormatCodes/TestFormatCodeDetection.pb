
EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


Define *BufferHolder.MsgPackData = MsgPackCreate(1)

; 0x00 - 0x7F
Define iFixIntCode.a

For iFixIntCode = 0 To $7F
    PokeA(*BufferHolder\Buffer, iFixIntCode)
    AssertEqualsA(MsgPackGetFormatCode(*BufferHolder), #MsgPack_FormatCode_FixIntPositive, Str(iFixIntCode) + " resolves to #MsgPack_FormatCode_FixIntPositive")
Next

; ...


If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
