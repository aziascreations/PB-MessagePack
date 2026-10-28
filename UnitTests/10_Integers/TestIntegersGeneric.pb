EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Writes `Value` with `MsgPackWriteInteger()` into a 1 byte buffer that has to grow,
;  checks its first byte and size, and reads it back with `MsgPackReadInteger()`.
; For fixints, `ExpectedFirstByte` is the value itself.
Procedure CheckInteger(Value.q, ExpectedFirstByte.a, ExpectedSize.i)
	Protected *MsgPack.MsgPackData = MsgPackCreate(1)
	Protected Name.s = Str(Value)

	AssertEquals(MsgPackWriteInteger(*MsgPack, Value), #MsgPack_Error_Success, "Wrote " + Name)
	AssertEquals(*MsgPack\BufferOffset, ExpectedSize, Name + " takes " + Str(ExpectedSize) + " bytes")
	AssertEquals(*MsgPack\BufferSize, ExpectedSize, Name + " grew the buffer exactly")
	AssertEqualsA(PeekA(*MsgPack\Buffer), ExpectedFirstByte, Name + " first byte")

	*MsgPack\BufferOffset = 0
	AssertEqualsQ(MsgPackReadInteger(*MsgPack), Value, "Read back " + Name)
	AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Read back " + Name + " without errors")
	AssertEquals(*MsgPack\BufferOffset, ExpectedSize, "Read back " + Name + " moved the offset")

	MsgPackFree(*MsgPack, #True)
EndProcedure


; Setup
Define *MsgPack.MsgPackData
Define QuadMin.q = -9223372036854775807 - 1


; Automatic format code selection, on each boundary
CheckInteger(0, $00, 1)
CheckInteger(1, $01, 1)
CheckInteger(127, $7F, 1)
CheckInteger(128, #MsgPack_FormatCode_UInt8, 2)
CheckInteger(255, #MsgPack_FormatCode_UInt8, 2)
CheckInteger(256, #MsgPack_FormatCode_UInt16, 3)
CheckInteger(65535, #MsgPack_FormatCode_UInt16, 3)
CheckInteger(65536, #MsgPack_FormatCode_UInt32, 5)
CheckInteger(4294967295, #MsgPack_FormatCode_UInt32, 5)
CheckInteger(4294967296, #MsgPack_FormatCode_UInt64, 9)
CheckInteger(9223372036854775807, #MsgPack_FormatCode_UInt64, 9)

CheckInteger(-1, $FF, 1)
CheckInteger(-32, $E0, 1)
CheckInteger(-33, #MsgPack_FormatCode_Int8, 2)
CheckInteger(-128, #MsgPack_FormatCode_Int8, 2)
CheckInteger(-129, #MsgPack_FormatCode_Int16, 3)
CheckInteger(-32768, #MsgPack_FormatCode_Int16, 3)
CheckInteger(-32769, #MsgPack_FormatCode_Int32, 5)
CheckInteger(-2147483648, #MsgPack_FormatCode_Int32, 5)
CheckInteger(-2147483649, #MsgPack_FormatCode_Int64, 9)
CheckInteger(QuadMin, #MsgPack_FormatCode_Int64, 9)


; Big-endian layouts
*MsgPack = MsgPackCreate(16)
MsgPackWriteInteger(*MsgPack, 4294967295)
MsgPackWriteInteger(*MsgPack, -129)
AssertEqualsA(PeekA(*MsgPack\Buffer + 1), $FF, "UInt32 byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + 4), $FF, "UInt32 byte 4")
AssertEqualsA(PeekA(*MsgPack\Buffer + 5), #MsgPack_FormatCode_Int16, "Int16 format code")
AssertEqualsA(PeekA(*MsgPack\Buffer + 6), $FF, "Int16 high byte first")
AssertEqualsA(PeekA(*MsgPack\Buffer + 7), $7F, "Int16 low byte last")
MsgPackFree(*MsgPack, #True)


; Reading values written with forced format codes
*MsgPack = MsgPackCreate(1)

AssertEquals(MsgPackWriteUInt32(*MsgPack, $89ABCDEF), #MsgPack_Error_Success, "Wrote UInt32 with its high bit set")
AssertEquals(MsgPackWriteInt8(*MsgPack, -1), #MsgPack_Error_Success, "Wrote Int8")
AssertEquals(MsgPackWriteUInt8(*MsgPack, 200), #MsgPack_Error_Success, "Wrote UInt8")
AssertEquals(MsgPackWriteInt16(*MsgPack, 5), #MsgPack_Error_Success, "Wrote small Int16")
AssertEquals(MsgPackWriteUInt16(*MsgPack, $ABCD), #MsgPack_Error_Success, "Wrote UInt16")
AssertEquals(MsgPackWriteInt32(*MsgPack, -123456), #MsgPack_Error_Success, "Wrote Int32")
AssertEquals(MsgPackWriteInt64(*MsgPack, -2), #MsgPack_Error_Success, "Wrote small Int64")
AssertEquals(MsgPackWriteFixInt(*MsgPack, -5), #MsgPack_Error_Success, "Wrote negative fixint")
AssertEquals(MsgPackWriteFixInt(*MsgPack, 100), #MsgPack_Error_Success, "Wrote positive fixint")
AssertEquals(MsgPackWriteUInt8(*MsgPack, 42), #MsgPack_Error_Success, "Wrote trailing UInt8")

AssertEqualsA(PeekA(*MsgPack\Buffer + 5 + 2 + 2 + 3 + 3 + 5 + 9), $FB, "Negative fixint byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + 5 + 2 + 2 + 3 + 3 + 5 + 9 + 1), $64, "Positive fixint byte")

*MsgPack\BufferOffset = 0
AssertEqualsQ(MsgPackReadInteger(*MsgPack), $89ABCDEF, "UInt32 is read as unsigned")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -1, "Int8 is read as signed")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 200, "UInt8 is read as unsigned")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 5, "Small Int16 is read")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), $ABCD, "UInt16 is read as unsigned")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -123456, "Int32 is read as signed")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -2, "Small Int64 is read")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -5, "Negative fixint is read")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 100, "Positive fixint is read")
AssertEqualsA(MsgPackReadUInt8(*MsgPack), 42, "Read trailing UInt8")
AssertEquals(*MsgPack\BufferOffset, *MsgPack\BufferSize, "Offset is at the end")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")

MsgPackFree(*MsgPack, #True)


; Known fixint vectors
*MsgPack = WrapHex("007F80E0FF")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "0x00 is 0")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 127, "0x7F is 127")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "0x80 is a fixmap, not an int")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Fixmap error is set")
AssertEquals(*MsgPack\BufferOffset, 2, "Offset is untouched by the fixmap")
*MsgPack\BufferOffset = 3
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -32, "0xE0 is -32")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), -1, "0xFF is -1")
FreeWrappedHex(*MsgPack)


; Fixints out of range
*MsgPack = MsgPackCreate(8)
AssertEquals(MsgPackWriteFixInt(*MsgPack, 128), #MsgPack_Error_ValueOverflow, "128 isn't a fixint")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_ValueOverflow, "Fixint overflow error is set")
AssertEquals(MsgPackWriteFixInt(*MsgPack, -33), #MsgPack_Error_ValueOverflow, "-33 isn't a fixint")
AssertEquals(MsgPackWriteFixInt(*MsgPack, 256 + 5), #MsgPack_Error_ValueOverflow, "261 isn't truncated into a fixint")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by rejected writes")
AssertEquals(MsgPackWriteFixInt(*MsgPack, 0), #MsgPack_Error_Success, "0 is a fixint")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Successful write cleared the error")
MsgPackFree(*MsgPack, #True)


; Buffers that can't grow
*MsgPack = WrapHex("0000")
AssertEquals(MsgPackWriteInteger(*MsgPack, 256), #MsgPack_Error_CannotGrowBufferDueToConfig, "UInt16's 3 bytes don't fit in 2")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed write")
AssertEquals(MsgPackWriteInteger(*MsgPack, -100), #MsgPack_Error_Success, "Int8's 2 bytes fit exactly")
FreeWrappedHex(*MsgPack)


; Reading errors
*MsgPack = WrapHex("01")
*MsgPack\BufferOffset = 1
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "Read at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Read at the end error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CA3F800000")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "Reading a float as an int fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Float as int error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the wrong format code")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("A161")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "Reading a str as an int fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Str as int error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CD00")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "UInt16 with half its value fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated UInt16 error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated value")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("D1")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "Int16 without its value fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated Int16 error is set")
FreeWrappedHex(*MsgPack)


; UInt64 values that don't fit in a signed quad
*MsgPack = WrapHex("CF7FFFFFFFFFFFFFFF")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 9223372036854775807, "UInt64 (2^63)-1 fits")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CF8000000000000000")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "UInt64 2^63 doesn't fit")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_ValueOverflow, "UInt64 overflow error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the overflow")
AssertEqualsQ(MsgPackReadUInt64(*MsgPack), QuadMin, "It can still be read as raw bits with MsgPackReadUInt64")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Raw read is a success")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CF80")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 0, "Truncated UInt64 with its high bit set fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncation is reported over the overflow")
FreeWrappedHex(*MsgPack)


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
