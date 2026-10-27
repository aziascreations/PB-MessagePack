EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Only covers errors that don't call `DebuggerError()`.
;       See "TestExtensionsFatalErrors.pb" for the others.


; Setup
Define *MsgPack.MsgPackData
Define *Source = AllocatePattern(16)
Define *Output = AllocateMemory(16)


; Sizes past each format code's limit, checked before anything is allocated
*MsgPack = MsgPackCreate(8)

AssertEquals(MsgPackWriteExt8(*MsgPack, 1, *Source, 256), #MsgPack_Error_BinaryDataSizeIsTooBig, "Ext8 rejects 256 bytes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BinaryDataSizeIsTooBig, "Ext8 too big error is set")
AssertEquals(MsgPackWriteExt16(*MsgPack, 1, *Source, 65536), #MsgPack_Error_BinaryDataSizeIsTooBig, "Ext16 rejects 65536 bytes")
AssertEquals(MsgPackWriteExt32(*MsgPack, 1, *Source, 4294967296), #MsgPack_Error_BinaryDataSizeIsTooBig, "Ext32 rejects 2^32 bytes")
AssertEquals(MsgPackWriteExtension(*MsgPack, 1, *Source, 4294967296), #MsgPack_Error_BinaryDataSizeIsTooBig, "Extension rejects 2^32 bytes")

AssertEquals(MsgPackWriteExt8(*MsgPack, 1, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Ext8 rejects negative sizes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BinaryDataSizeIsNegative, "Negative size error is set")
AssertEquals(MsgPackWriteExt16(*MsgPack, 1, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Ext16 rejects negative sizes")
AssertEquals(MsgPackWriteExt32(*MsgPack, 1, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Ext32 rejects negative sizes")
AssertEquals(MsgPackWriteExtension(*MsgPack, 1, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Extension rejects negative sizes")

AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by rejected writes")
AssertEquals(*MsgPack\BufferSize, 8, "Buffer wasn't grown by rejected writes")

AssertEquals(MsgPackWriteExt8(*MsgPack, 1, *Source, 3), #MsgPack_Error_Success, "Wrote ext8 after rejected writes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Successful write cleared the error")

MsgPackFree(*MsgPack, #True)


; Buffers that can't grow
*MsgPack = WrapHex("0000000000")

AssertEquals(MsgPackWriteFixExt4(*MsgPack, 1, *Source), #MsgPack_Error_CannotGrowBufferDueToConfig, "fixext4's 6 bytes don't fit in 5")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_CannotGrowBufferDueToConfig, "Growth error is set")
AssertEquals(MsgPackWriteExt8(*MsgPack, 1, *Source, 3), #MsgPack_Error_CannotGrowBufferDueToConfig, "ext8's 6 bytes don't fit in 5")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed writes")
AssertEqualsA(PeekA(*MsgPack\Buffer), $00, "Nothing was written by the failed writes")

AssertEquals(MsgPackWriteExt8(*MsgPack, 1, *Source, 2), #MsgPack_Error_Success, "ext8's 5 bytes fit exactly")
AssertEquals(*MsgPack\BufferOffset, 5, "Offset is at the end")

FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("00000000")
AssertEquals(MsgPackWriteFixExt2(*MsgPack, 1, *Source), #MsgPack_Error_Success, "fixext2's 4 bytes fit exactly")
AssertEquals(*MsgPack\BufferOffset, 4, "Offset is at the end")
FreeWrappedHex(*MsgPack)


; Reading at the end
*MsgPack = WrapHex("D40100")
*MsgPack\BufferOffset = 3

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Read at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Read at the end error is set")
AssertEquals(MsgPackCopyExtension(*MsgPack), #Null, "Copy at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Copy at the end error is set")
AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 0, "Type at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Type at the end error is set")

FreeWrappedHex(*MsgPack)


; Wrong format codes, in both directions
*MsgPack = WrapHex("C4020102")

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading a bin as an ext fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Bin as ext read error is set")
AssertEquals(MsgPackCopyExtension(*MsgPack), #Null, "Copying a bin as an ext fails")
AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 0, "Getting the type of a bin fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Bin type error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the wrong format code")

FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C702050102")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading an ext8 as a bin fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Ext8 as bin error is set")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Reading an ext8 as a str fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Ext8 as str error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("D40501")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading a fixext1 as a bin fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Fixext1 as bin error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("A3616263")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading a str as an ext fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Str as ext error is set")
FreeWrappedHex(*MsgPack)


; Truncated size and type fields
*MsgPack = WrapHex("C7")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Ext8 without its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Ext8 without its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C700")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Empty ext8 without its type fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Empty ext8 without its type error is set")
AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 0, "Getting a missing type fails")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C80000")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Empty ext16 without its type fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Empty ext16 without its type error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C9000000")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Ext32 with 3/4 of its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Ext32 with 3/4 of its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("D4")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Fixext1 without its type fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Fixext1 without its type error is set")
FreeWrappedHex(*MsgPack)


; Truncated data
*MsgPack = WrapHex("D6FF0000")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Fixext4 missing data fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Fixext4 missing data error is set")
AssertEquals(MsgPackCopyExtension(*MsgPack), #Null, "Copying a fixext4 missing data fails")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated data")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C705016162")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Ext8 missing data fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Ext8 missing data error is set")
FreeWrappedHex(*MsgPack)

; The type byte must not be counted as data.
*MsgPack = WrapHex("C70201AA")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Ext8 with its type as the last data byte fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Type isn't counted as data")
FreeWrappedHex(*MsgPack)

; The ext32 size is unsigned, `0xFFFFFFFF` must not be read as `-1`.
*MsgPack = WrapHex("C9FFFFFFFF0100")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Ext32 with a 0xFFFFFFFF size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Ext32 size is treated as unsigned")
FreeWrappedHex(*MsgPack)


; Output buffer too small, then retried
*MsgPack = WrapHex("C70307010203")

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 2), #MsgPack_InvalidSize, "3 bytes don't fit in 2")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_OutputBufferTooSmall, "Output too small error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched so the read can be retried")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 7, "Type is still readable")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 3), 3, "Retried with an exactly sized buffer")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Retry cleared the error")
AssertEqualsA(PeekA(*Output), $01, "Retried data byte 1")
AssertEqualsA(PeekA(*Output + 1), $02, "Retried data byte 2")
AssertEqualsA(PeekA(*Output + 2), $03, "Retried data byte 3")
AssertEquals(*MsgPack\BufferOffset, 6, "Offset is at the end")

FreeWrappedHex(*MsgPack)


; Ending
FreeMemory(*Source)
FreeMemory(*Output)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
