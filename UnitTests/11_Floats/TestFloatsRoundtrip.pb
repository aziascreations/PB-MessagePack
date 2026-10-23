EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Setup
Define *MsgPack.MsgPackData = MsgPackCreate(32)
Define ReadFloat.f
Define ReadDouble.d


; Writing
AssertEquals(MsgPackWriteFloat32(*MsgPack, 1.0), #MsgPack_Error_Success, "Wrote Float32")
AssertEquals(MsgPackWriteFloat64(*MsgPack, -2.5), #MsgPack_Error_Success, "Wrote Float64")
AssertEquals(*MsgPack\BufferOffset, 5 + 9, "Offset matches the written sizes")


; Checking the big-endian layout (1.0f = $3F800000, -2.5 = $C004000000000000)
AssertEqualsA(PeekA(*MsgPack\Buffer + 0), #MsgPack_FormatCode_Float32, "Float32 format code")
AssertEqualsA(PeekA(*MsgPack\Buffer + 1), $3F, "Float32 high byte first")
AssertEqualsA(PeekA(*MsgPack\Buffer + 2), $80, "Float32 second byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + 4), $00, "Float32 low byte last")
AssertEqualsA(PeekA(*MsgPack\Buffer + 5), #MsgPack_FormatCode_Float64, "Float64 format code")
AssertEqualsA(PeekA(*MsgPack\Buffer + 6), $C0, "Float64 high byte first")
AssertEqualsA(PeekA(*MsgPack\Buffer + 7), $04, "Float64 second byte")


; Reading them back
*MsgPack\BufferOffset = 0

ReadFloat = MsgPackReadFloat32(*MsgPack)
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading Float32")
AssertIsTrue(Bool(ReadFloat = 1.0), "Read Float32")

ReadDouble = MsgPackReadFloat64(*MsgPack)
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading Float64")
AssertIsTrue(Bool(ReadDouble = -2.5), "Read Float64")


; A value whose bytes look like a signaling NaN when read in the wrong order.
; Correct value: $0100807F, a normal float. Stored bytes: 01 00 80 7F.
; Read as little-endian, they give $7F800001, a signaling NaN the FPU would alter.
*MsgPack\BufferOffset = 0
PokeA(*MsgPack\Buffer + 0, #MsgPack_FormatCode_Float32)
PokeA(*MsgPack\Buffer + 1, $01)
PokeA(*MsgPack\Buffer + 2, $00)
PokeA(*MsgPack\Buffer + 3, $80)
PokeA(*MsgPack\Buffer + 4, $7F)

ReadFloat = MsgPackReadFloat32(*MsgPack)
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading the NaN-looking Float32")
AssertEquals(PeekL(@ReadFloat), $0100807F, "Float32 bits are preserved")


; Ending
MsgPackFree(*MsgPack, #True)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
