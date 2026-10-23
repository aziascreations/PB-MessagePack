EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Setup
Define *MsgPack.MsgPackData = MsgPackCreate(64)

; No unsigned Long in PureBasic, so the UInt32 goes through a quad.
Define UInt32Value.q = $89ABCDEF
Define ReadUInt32Value.q


; Writing one of each
AssertEquals(MsgPackWriteUInt8(*MsgPack, 200), #MsgPack_Error_Success, "Wrote UInt8")
AssertEquals(MsgPackWriteInt8(*MsgPack, -5), #MsgPack_Error_Success, "Wrote Int8")
AssertEquals(MsgPackWriteUInt16(*MsgPack, $ABCD), #MsgPack_Error_Success, "Wrote UInt16")
AssertEquals(MsgPackWriteInt16(*MsgPack, -1234), #MsgPack_Error_Success, "Wrote Int16")
AssertEquals(MsgPackWriteUInt32(*MsgPack, UInt32Value), #MsgPack_Error_Success, "Wrote UInt32")
AssertEquals(MsgPackWriteInt32(*MsgPack, -123456), #MsgPack_Error_Success, "Wrote Int32")
AssertEquals(MsgPackWriteUInt64(*MsgPack, $0123456789ABCDEF), #MsgPack_Error_Success, "Wrote UInt64")
AssertEquals(MsgPackWriteInt64(*MsgPack, -1), #MsgPack_Error_Success, "Wrote Int64")
AssertEquals(*MsgPack\BufferOffset, 2+2+3+3+5+5+9+9, "Offset matches the written sizes")


; Checking the big-endian layout once
AssertEqualsA(PeekA(*MsgPack\Buffer + 4), #MsgPack_FormatCode_UInt16, "UInt16 format code")
AssertEqualsA(PeekA(*MsgPack\Buffer + 5), $AB, "UInt16 high byte first")
AssertEqualsA(PeekA(*MsgPack\Buffer + 6), $CD, "UInt16 low byte last")


; Reading them back
*MsgPack\BufferOffset = 0

AssertEqualsA(MsgPackReadUInt8(*MsgPack), 200, "Read UInt8")
AssertEqualsB(MsgPackReadInt8(*MsgPack), -5, "Read Int8")
AssertEquals(MsgPackReadUInt16(*MsgPack), $ABCD, "Read UInt16")
AssertEquals(MsgPackReadInt16(*MsgPack), -1234, "Read Int16")
ReadUInt32Value = MsgPackReadUInt32(*MsgPack)
ReadUInt32Value = ReadUInt32Value & $FFFFFFFF
AssertEqualsQ(ReadUInt32Value, UInt32Value, "Read UInt32")
AssertEquals(MsgPackReadInt32(*MsgPack), -123456, "Read Int32")
AssertEqualsQ(MsgPackReadUInt64(*MsgPack), $0123456789ABCDEF, "Read UInt64")
AssertEqualsQ(MsgPackReadInt64(*MsgPack), -1, "Read Int64")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")


; Bad input doesn't halt the debugger, and a successful write clears the error
AssertEqualsA(MsgPackReadUInt8(*MsgPack), 0, "Reading the zeroed tail as a UInt8 fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Invalid format code is reported")
AssertEquals(*MsgPack\BufferOffset, 2+2+3+3+5+5+9+9, "Offset is untouched by the failed read")

AssertEquals(MsgPackWriteUInt8(*MsgPack, 1), #MsgPack_Error_Success, "Wrote UInt8 after the failed read")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Successful write cleared the error")


; Ending
MsgPackFree(*MsgPack, #True)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
