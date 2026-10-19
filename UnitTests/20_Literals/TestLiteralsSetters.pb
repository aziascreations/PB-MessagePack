EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Note: The checks were done on the table in the spec.
;       I didn't go with my own constants to avoid missing a discrepency.


Define *MyBuffer
Define *MsgPack.MsgPackData


; Setup
*MyBuffer = AllocateMemory(8)
FillMemory(*MyBuffer, MemorySize(*MyBuffer), $C1, #PB_Ascii)
*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))


; Writing in place
*MsgPack\DataFlags = *MsgPack\DataFlags & (~#MsgPack_DataFlags_MoveOffsetAfterWrite)
AssertIsFalse(Bool(_MsgPackHasFlag(*MsgPack, #MsgPack_DataFlags_MoveOffsetAfterWrite)), "Move after flag is unset")

AssertEquals(MsgPackWriteNull(*MsgPack), #MsgPack_Error_Success, "Wrote null using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer), #MsgPack_FormatCode_Null, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 0, "Offset was left at 0")

AssertEquals(MsgPackWriteFalse(*MsgPack), #MsgPack_Error_Success, "Wrote false using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer), #MsgPack_FormatCode_False, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 0, "Offset was left at 0")

AssertEquals(MsgPackWriteTrue(*MsgPack), #MsgPack_Error_Success, "Wrote true using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer), #MsgPack_FormatCode_True, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 0, "Offset was left at 0")


; Writing sequentially
*MsgPack\DataFlags = *MsgPack\DataFlags | #MsgPack_DataFlags_MoveOffsetAfterWrite
AssertIsTrue(Bool(_MsgPackHasFlag(*MsgPack, #MsgPack_DataFlags_MoveOffsetAfterWrite)), "Move after flag is set")

AssertEquals(MsgPackWriteNull(*MsgPack), #MsgPack_Error_Success, "Wrote null using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer + 0), #MsgPack_FormatCode_Null, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 1, "Offset is now 1")

AssertEquals(MsgPackWriteFalse(*MsgPack), #MsgPack_Error_Success, "Wrote false using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer + 1), #MsgPack_FormatCode_False, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 2, "Offset is now 2")

AssertEquals(MsgPackWriteTrue(*MsgPack), #MsgPack_Error_Success, "Wrote true using helper")
AssertEqualsA(PeekA(*MsgPack\Buffer + 2), #MsgPack_FormatCode_True, "Format code is changed and correct")
AssertEqualsA(*MsgPack\BufferOffset, 3, "Offset is now 3")


; Ending
MsgPackFree(*MsgPack, #False)
FreeMemory(*MyBuffer)
