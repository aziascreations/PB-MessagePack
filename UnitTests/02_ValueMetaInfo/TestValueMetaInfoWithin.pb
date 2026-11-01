EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Note: The checks were done on the table in the spec.
;       I didn't go with my own constants to avoid missing a discrepency.


Procedure TestValueMetaInfoWithin(CodeForBuffer.a, ExpectedVariableSize.q, ExpectedDataOffset.b, TestName.s)
    Protected *BufferHolder.MsgPackData = MsgPackCreate(1)

    PokeA(*BufferHolder\Buffer, CodeForBuffer)

    Protected ExaminedFormatCode.MsgPack_FormatCode = MsgPackGetFormatCode(*BufferHolder)

    Protected ReturnedVariableSize.q
    Protected ReturnedDataOffset.b

    _MsgPackGetFieldSpacingInfo(*BufferHolder, ExaminedFormatCode, @ReturnedVariableSize, @ReturnedDataOffset)

    AssertEqualsQ(ReturnedVariableSize, ExpectedVariableSize, TestName + " (Value)")

    AssertEqualsB(ReturnedDataOffset, ExpectedDataOffset, TestName + " (Offset)")

    MsgPackFree(*BufferHolder, #True)
EndProcedure


; Positive FixInt, unsupported since `MsgPackReadInteger()` handles them
TestValueMetaInfoWithin($00, #MsgPack_InvalidSize, #MsgPack_InvalidSize, "FixInt with positive 0")
TestValueMetaInfoWithin($7F, #MsgPack_InvalidSize, #MsgPack_InvalidSize, "FixInt with positive 127")

; FixMap
TestValueMetaInfoWithin($80, 0,  1, "FixMap with 0 elements")  ; Value: 0  (0x0) | Offset: 1
TestValueMetaInfoWithin($8F, 15, 1, "FixMap with 15 elements") ; Value: 15 (0xF) | Offset: 1

; FixArray
TestValueMetaInfoWithin($90, 0,  1, "FixArray with 0 elements")  ; Value: 0  (0x0) | Offset: 1
TestValueMetaInfoWithin($9F, 15, 1, "FixArray with 15 elements") ; Value: 15 (0xF) | Offset: 1

; FixStr
TestValueMetaInfoWithin($A0, 0,  1, "FixStr with 0 elements")  ; Value: 0  (0x00) | Offset: 1
TestValueMetaInfoWithin($AF, 15, 1, "FixStr with 15 elements") ; Value: 15 (0x0F) | Offset: 1
TestValueMetaInfoWithin($B0, 16, 1, "FixStr with 16 elements") ; Value: 16 (0x10) | Offset: 1
TestValueMetaInfoWithin($BF, 31, 1, "FixStr with 31 elements") ; Value: 31 (0x1F) | Offset: 1

; Negative FixInt, unsupported since `MsgPackReadInteger()` handles them
TestValueMetaInfoWithin($E0, #MsgPack_InvalidSize, #MsgPack_InvalidSize, "FixInt with negative 32")
TestValueMetaInfoWithin($FF, #MsgPack_InvalidSize, #MsgPack_InvalidSize, "FixInt with negative 1")



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
