EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Setup
Define *MsgPack.MsgPackData = MsgPackCreate(1)


; Reading both float sizes
AssertEquals(MsgPackWriteFloat32(*MsgPack, 1.5), #MsgPack_Error_Success, "Wrote Float32")
AssertEquals(MsgPackWriteFloat64(*MsgPack, -2.25), #MsgPack_Error_Success, "Wrote Float64")
AssertEquals(MsgPackWriteFloat32(*MsgPack, 0.1), #MsgPack_Error_Success, "Wrote inexact Float32")
AssertEquals(MsgPackWriteUInt8(*MsgPack, 42), #MsgPack_Error_Success, "Wrote trailing UInt8")

*MsgPack\BufferOffset = 0
Assert(Bool(MsgPackReadFloat(*MsgPack) = 1.5), "Float32 is read")
AssertEquals(*MsgPack\BufferOffset, 5, "Float32 moved the offset by 5")
Assert(Bool(MsgPackReadFloat(*MsgPack) = -2.25), "Float64 is read")
AssertEquals(*MsgPack\BufferOffset, 5 + 9, "Float64 moved the offset by 9")
; 0.1 isn't exact as a float32, so it must match the float32 value, not the double one.
Assert(Bool(MsgPackReadFloat(*MsgPack) = ValF("0.1")), "Inexact Float32 is widened as-is")
AssertEqualsA(MsgPackReadUInt8(*MsgPack), 42, "Read trailing UInt8")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")

MsgPackFree(*MsgPack, #True)


; Reading errors
*MsgPack = WrapHex("CA")
*MsgPack\BufferOffset = 1
Assert(Bool(MsgPackReadFloat(*MsgPack) = 0), "Read at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Read at the end error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("01")
Assert(Bool(MsgPackReadFloat(*MsgPack) = 0), "Reading an int as a float fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Int as float error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the wrong format code")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CB3FF0000000")
Assert(Bool(MsgPackReadFloat(*MsgPack) = 0), "Truncated Float64 fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated Float64 error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated value")
FreeWrappedHex(*MsgPack)


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
