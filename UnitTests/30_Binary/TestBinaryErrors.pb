EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Only covers errors that don't call `DebuggerError()`.
;       See "TestBinaryFatalErrors.pb" for the others.


; Setup
Define *MsgPack.MsgPackData
Define *Source = AllocatePattern(16)
Define *Output = AllocateMemory(16)


; Sizes past each format code's limit, checked before anything is allocated
*MsgPack = MsgPackCreate(8)

AssertEquals(MsgPackWriteBin8(*MsgPack, *Source, 256), #MsgPack_Error_BinaryDataSizeIsTooBig, "Bin8 rejects 256 bytes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BinaryDataSizeIsTooBig, "Bin8 too big error is set")
AssertEquals(MsgPackWriteBin16(*MsgPack, *Source, 65536), #MsgPack_Error_BinaryDataSizeIsTooBig, "Bin16 rejects 65536 bytes")
AssertEquals(MsgPackWriteBin32(*MsgPack, *Source, 4294967296), #MsgPack_Error_BinaryDataSizeIsTooBig, "Bin32 rejects 2^32 bytes")
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, 4294967296), #MsgPack_Error_BinaryDataSizeIsTooBig, "Binary rejects 2^32 bytes")

AssertEquals(MsgPackWriteBin8(*MsgPack, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Bin8 rejects negative sizes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BinaryDataSizeIsNegative, "Negative size error is set")
AssertEquals(MsgPackWriteBin16(*MsgPack, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Bin16 rejects negative sizes")
AssertEquals(MsgPackWriteBin32(*MsgPack, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Bin32 rejects negative sizes")
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, -1), #MsgPack_Error_BinaryDataSizeIsNegative, "Binary rejects negative sizes")

AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by rejected writes")
AssertEquals(*MsgPack\BufferSize, 8, "Buffer wasn't grown by rejected writes")

AssertEquals(MsgPackWriteBin8(*MsgPack, *Source, 4), #MsgPack_Error_Success, "Wrote bin8 after rejected writes")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Successful write cleared the error")

MsgPackFree(*MsgPack, #True)


; Buffers that can't grow
*MsgPack = WrapHex("0000000000")

AssertEquals(MsgPackWriteBin8(*MsgPack, *Source, 4), #MsgPack_Error_CannotGrowBufferDueToConfig, "6 bytes don't fit in 5")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_CannotGrowBufferDueToConfig, "Growth error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed write")
AssertEqualsA(PeekA(*MsgPack\Buffer), $00, "Nothing was written by the failed write")

AssertEquals(MsgPackWriteBin8(*MsgPack, *Source, 3), #MsgPack_Error_Success, "5 bytes fit exactly")
AssertEquals(*MsgPack\BufferOffset, 5, "Offset is at the end")

FreeWrappedHex(*MsgPack)


; Reading at the end
*MsgPack = WrapHex("C40100")
*MsgPack\BufferOffset = 3

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Read at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Read at the end error is set")
AssertEquals(MsgPackCopyBinary(*MsgPack), #Null, "Copy at the end fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Copy at the end error is set")

FreeWrappedHex(*MsgPack)


; Wrong format codes
*MsgPack = WrapHex("A3616263")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading a str as a bin fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Str as bin read error is set")
AssertEquals(MsgPackCopyBinary(*MsgPack), #Null, "Copying a str as a bin fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Str as bin copy error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the wrong format code")

FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C1")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Reading the 0xC1 never-used code fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "0xC1 error is set")
FreeWrappedHex(*MsgPack)


; Truncated size fields
*MsgPack = WrapHex("C4")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Bin8 without its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bin8 without its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C500")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Bin16 with half its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bin16 with half its size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("C6000000")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Bin32 with 3/4 of its size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bin32 with 3/4 of its size error is set")
FreeWrappedHex(*MsgPack)


; Truncated data
*MsgPack = WrapHex("C4056162")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Bin8 missing data fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bin8 missing data error is set")
AssertEquals(MsgPackCopyBinary(*MsgPack), #Null, "Copying a bin8 missing data fails")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated data")
FreeWrappedHex(*MsgPack)

; The bin32 size is unsigned, `0xFFFFFFFF` must not be read as `-1`.
*MsgPack = WrapHex("C6FFFFFFFF00")
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), #MsgPack_InvalidSize, "Bin32 with a 0xFFFFFFFF size fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bin32 size is treated as unsigned")
FreeWrappedHex(*MsgPack)


; Output buffer too small, then retried
*MsgPack = WrapHex("C403010203")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 2), #MsgPack_InvalidSize, "3 bytes don't fit in 2")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_OutputBufferTooSmall, "Output too small error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched so the read can be retried")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 3), 3, "Retried with an exactly sized buffer")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Retry cleared the error")
AssertEqualsA(PeekA(*Output), $01, "Retried data byte 1")
AssertEqualsA(PeekA(*Output + 1), $02, "Retried data byte 2")
AssertEqualsA(PeekA(*Output + 2), $03, "Retried data byte 3")
AssertEquals(*MsgPack\BufferOffset, 5, "Offset is at the end")

FreeWrappedHex(*MsgPack)


; Ending
FreeMemory(*Source)
FreeMemory(*Output)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
