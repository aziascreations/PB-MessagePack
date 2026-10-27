EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Only covers errors that don't call `DebuggerError()`.
;       See "TestStringsFatalErrors.pb" for the others.


; Setup
Define *MsgPack.MsgPackData


; Strings too big for a forced format code
*MsgPack = MsgPackCreate(8)

AssertEquals(MsgPackWriteFixStr(*MsgPack, LSet("", 32, "a")), #MsgPack_Error_BinaryDataSizeIsTooBig, "Fixstr rejects 32 bytes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BinaryDataSizeIsTooBig, "Fixstr too big error is set")
AssertEquals(MsgPackWriteFixStr(*MsgPack, LSet("", 16, Chr($E9))), #MsgPack_Error_BinaryDataSizeIsTooBig, "Fixstr rejects 16 accents (32 bytes)")
AssertEquals(MsgPackWriteFixStr(*MsgPack, LSet("", 16, "a"), #PB_Unicode), #MsgPack_Error_BinaryDataSizeIsTooBig, "Fixstr rejects 16 UTF-16 characters (32 bytes)")
AssertEquals(MsgPackWriteStr8(*MsgPack, LSet("", 256, "a")), #MsgPack_Error_BinaryDataSizeIsTooBig, "Str8 rejects 256 bytes")
AssertEquals(MsgPackWriteStr16(*MsgPack, LSet("", 65536, "a")), #MsgPack_Error_BinaryDataSizeIsTooBig, "Str16 rejects 65536 bytes")

AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by rejected writes")
AssertEquals(*MsgPack\BufferSize, 8, "Buffer wasn't grown by rejected writes")

AssertEquals(MsgPackWriteFixStr(*MsgPack, LSet("", 31, "a")), #MsgPack_Error_Success, "Fixstr accepts 31 bytes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Successful write cleared the error")

MsgPackFree(*MsgPack, #True)


; Buffers that can't grow
*MsgPack = WrapHex("0000")

AssertEquals(MsgPackWriteString(*MsgPack, "ab"), #MsgPack_Error_CannotGrowBufferDueToConfig, "3 bytes don't fit in 2")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_CannotGrowBufferDueToConfig, "Growth error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed write")
AssertEqualsA(PeekA(*MsgPack\Buffer), $00, "Nothing was written by the failed write")

AssertEquals(MsgPackWriteString(*MsgPack, "a"), #MsgPack_Error_Success, "2 bytes fit exactly")
AssertEquals(*MsgPack\BufferOffset, 2, "Offset is at the end")

FreeWrappedHex(*MsgPack)


; Reading at the end
*MsgPack = WrapHex("A161")
*MsgPack\BufferOffset = 2

Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Read at the end returns an empty string")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Read at the end error is set")

FreeWrappedHex(*MsgPack)


; Wrong format codes
*MsgPack = WrapHex("C40161")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Reading a bin as a str fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Bin as str error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the wrong format code")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C1")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Reading the 0xC1 never-used code fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "0xC1 error is set")
FreeWrappedHex(*MsgPack)


; Truncated size fields
*MsgPack = WrapHex("D9")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Str8 without its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Str8 without its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("DA00")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Str16 with half its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Str16 with half its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("DB000000")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Str32 with 3/4 of its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Str32 with 3/4 of its size error is set")
FreeWrappedHex(*MsgPack)


; Truncated data
*MsgPack = WrapHex("A36162")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Fixstr missing data fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Fixstr missing data error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated data")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("D90561")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Str8 missing data fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Str8 missing data error is set")
FreeWrappedHex(*MsgPack)

; The str32 size is unsigned, `0xFFFFFFFF` must not be read as `-1`.
*MsgPack = WrapHex("DBFFFFFFFF61")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Str32 with a 0xFFFFFFFF size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Str32 size is treated as unsigned")
FreeWrappedHex(*MsgPack)


; UTF-16 with an odd byte count, then read as UTF-8 instead
*MsgPack = WrapHex("A3414243")

Assert(Bool(MsgPackReadString(*MsgPack, #PB_Unicode) = ""), "Odd sized UTF-16 fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidStringSize, "Odd sized UTF-16 error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched so the read can be retried")

Assert(Bool(MsgPackReadString(*MsgPack) = "ABC"), "Retried as UTF-8")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Retry cleared the error")
AssertEquals(*MsgPack\BufferOffset, 4, "Offset is at the end")

FreeWrappedHex(*MsgPack)


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
