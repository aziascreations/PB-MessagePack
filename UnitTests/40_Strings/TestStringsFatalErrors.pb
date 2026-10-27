EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; /!\ Every case here calls `DebuggerError()`, which halts the program under the debugger.
;     Run it without the debugger and check the exit code.


; Setup
#UnsupportedEncoding = 999

Define *MsgPack.MsgPackData


; Null MsgPack pointers
AssertEquals(MsgPackWriteString(#Null, "a"), #MsgPack_Error_NullPointerGiven, "MsgPackWriteString is given #Null")
AssertEquals(MsgPackWriteFixStr(#Null, "a"), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFixStr is given #Null")
AssertEquals(MsgPackWriteStr8(#Null, "a"), #MsgPack_Error_NullPointerGiven, "MsgPackWriteStr8 is given #Null")
AssertEquals(MsgPackWriteStr16(#Null, "a"), #MsgPack_Error_NullPointerGiven, "MsgPackWriteStr16 is given #Null")
AssertEquals(MsgPackWriteStr32(#Null, "a"), #MsgPack_Error_NullPointerGiven, "MsgPackWriteStr32 is given #Null")
Assert(Bool(MsgPackReadString(#Null) = ""), "MsgPackReadString is given #Null")


; Unsupported encodings when writing
*MsgPack = MsgPackCreate(8)

AssertEquals(MsgPackWriteString(*MsgPack, "a", #UnsupportedEncoding), #MsgPack_Error_UnsupportedStringEncoding, "MsgPackWriteString rejects the encoding")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_UnsupportedStringEncoding, "Unsupported encoding error is set")
AssertEquals(MsgPackWriteStr8(*MsgPack, "a", #UnsupportedEncoding), #MsgPack_Error_UnsupportedStringEncoding, "MsgPackWriteStr8 rejects the encoding")
AssertEquals(MsgPackWriteString(*MsgPack, "", #UnsupportedEncoding), #MsgPack_Error_UnsupportedStringEncoding, "Empty strings are rejected too")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by rejected writes")

MsgPackFree(*MsgPack, #True)


; Unsupported encodings when reading
*MsgPack = WrapHex("A161")
Assert(Bool(MsgPackReadString(*MsgPack, #UnsupportedEncoding) = ""), "MsgPackReadString rejects the encoding")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_UnsupportedStringEncoding, "Unsupported encoding error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the rejected read")
FreeWrappedHex(*MsgPack)

; Nothing to decode, but the encoding is still checked.
*MsgPack = WrapHex("A0")
Assert(Bool(MsgPackReadString(*MsgPack, #UnsupportedEncoding) = ""), "Empty string read rejects the encoding")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_UnsupportedStringEncoding, "Empty string encoding error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the rejected empty read")
FreeWrappedHex(*MsgPack)


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
