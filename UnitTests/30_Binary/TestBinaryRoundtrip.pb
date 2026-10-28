EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Setup
; Starting with 1 byte so every write has to grow the buffer.
Define *MsgPack.MsgPackData = MsgPackCreate(1)
Define *Source = AllocatePattern(65536)
Define *Output = AllocateMemory(65536)
Define *Copy

Define OffsetEmpty.i, Offset255.i, Offset256.i, Offset65535.i, Offset65536.i
Define OffsetBin16Empty.i, OffsetBin32Small.i, OffsetBin16Small.i
Define OffsetEnd.i


; Automatic format code selection, on each boundary
OffsetEmpty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBinary(*MsgPack, #Null, 0), #MsgPack_Error_Success, "Wrote 0 bytes from a #Null buffer")
Offset255 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, 255), #MsgPack_Error_Success, "Wrote 255 bytes")
Offset256 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, 256), #MsgPack_Error_Success, "Wrote 256 bytes")
Offset65535 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, 65535), #MsgPack_Error_Success, "Wrote 65535 bytes")
Offset65536 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBinary(*MsgPack, *Source, 65536), #MsgPack_Error_Success, "Wrote 65536 bytes")


; Forced format codes, even when a smaller one fits
OffsetBin16Empty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBin16(*MsgPack, #Null, 0), #MsgPack_Error_Success, "Wrote 0 bytes as bin16")
OffsetBin32Small = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBin32(*MsgPack, *Source, 5), #MsgPack_Error_Success, "Wrote 5 bytes as bin32")
OffsetBin16Small = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteBin16(*MsgPack, *Source, 1), #MsgPack_Error_Success, "Wrote 1 byte as bin16")


; Something right after, to catch offset drifts
AssertEquals(MsgPackWriteUInt8(*MsgPack, 42), #MsgPack_Error_Success, "Wrote trailing UInt8")
OffsetEnd = *MsgPack\BufferOffset


; Offsets
AssertEquals(Offset255, OffsetEmpty + 2, "Empty bin8 takes 2 bytes")
AssertEquals(Offset256, Offset255 + 2 + 255, "255 bytes bin8 takes 257 bytes")
AssertEquals(Offset65535, Offset256 + 3 + 256, "256 bytes bin16 takes 259 bytes")
AssertEquals(Offset65536, Offset65535 + 3 + 65535, "65535 bytes bin16 takes 65538 bytes")
AssertEquals(OffsetBin16Empty, Offset65536 + 5 + 65536, "65536 bytes bin32 takes 65541 bytes")
AssertEquals(OffsetBin32Small, OffsetBin16Empty + 3, "Empty bin16 takes 3 bytes")
AssertEquals(OffsetBin16Small, OffsetBin32Small + 5 + 5, "5 bytes bin32 takes 10 bytes")
AssertEquals(OffsetEnd, OffsetBin16Small + 3 + 1 + 2, "1 byte bin16 and UInt8 take 6 bytes")
AssertEquals(*MsgPack\BufferSize, OffsetEnd, "Buffer grew to exactly what was written")


; Big-endian layouts
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEmpty), #MsgPack_FormatCode_Bin8, "Empty uses bin8")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEmpty + 1), $00, "Empty bin8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255), #MsgPack_FormatCode_Bin8, "255 bytes uses bin8")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255 + 1), $FF, "255 bytes bin8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256), #MsgPack_FormatCode_Bin16, "256 bytes uses bin16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 1), $01, "256 bytes bin16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 2), $00, "256 bytes bin16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535), #MsgPack_FormatCode_Bin16, "65535 bytes uses bin16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 1), $FF, "65535 bytes bin16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 2), $FF, "65535 bytes bin16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536), #MsgPack_FormatCode_Bin32, "65536 bytes uses bin32")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 1), $00, "65536 bytes bin32 size byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 2), $01, "65536 bytes bin32 size byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 3), $00, "65536 bytes bin32 size byte 3")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 4), $00, "65536 bytes bin32 size byte 4")
Assert(CompareMemory(*MsgPack\Buffer + Offset65536 + 5, *Source, 65536), "65536 bytes bin32 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin16Empty), #MsgPack_FormatCode_Bin16, "Forced empty bin16")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin16Empty + 1), $00, "Forced empty bin16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin16Empty + 2), $00, "Forced empty bin16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin32Small), #MsgPack_FormatCode_Bin32, "Forced 5 bytes bin32")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin32Small + 1), $00, "Forced 5 bytes bin32 size byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin32Small + 2), $00, "Forced 5 bytes bin32 size byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin32Small + 3), $00, "Forced 5 bytes bin32 size byte 3")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetBin32Small + 4), $05, "Forced 5 bytes bin32 size byte 4")
Assert(CompareMemory(*MsgPack\Buffer + OffsetBin32Small + 5, *Source, 5), "Forced 5 bytes bin32 data")


; Reading them back
*MsgPack\BufferOffset = 0

AssertEqualsQ(MsgPackReadBinary(*MsgPack, #Null, 0), 0, "Read empty bin8 into a #Null buffer")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Empty read is a success")

FillMemory(*Output, 65536, $AA)
AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 255), 255, "Read 255 bytes into an exactly sized buffer")
Assert(CompareMemory(*Output, *Source, 255), "255 bytes data matches")
AssertEqualsA(PeekA(*Output + 255), $AA, "Nothing written past the data")

*Copy = MsgPackCopyBinary(*MsgPack)
Assert(Bool(*Copy <> #Null), "Copied 256 bytes")
If *Copy
	AssertEquals(MemorySize(*Copy), 256, "Copy is exactly 256 bytes")
	Assert(CompareMemory(*Copy, *Source, 256), "256 bytes data matches")
	FreeMemory(*Copy)
EndIf

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 65536), 65535, "Read 65535 bytes into a bigger buffer")
Assert(CompareMemory(*Output, *Source, 65535), "65535 bytes data matches")

*Copy = MsgPackCopyBinary(*MsgPack)
Assert(Bool(*Copy <> #Null), "Copied 65536 bytes")
If *Copy
	AssertEquals(MemorySize(*Copy), 65536, "Copy is exactly 65536 bytes")
	Assert(CompareMemory(*Copy, *Source, 65536), "65536 bytes data matches")
	FreeMemory(*Copy)
EndIf

AssertEquals(MsgPackCopyBinary(*MsgPack), #Null, "Copying an empty bin16 returns #Null")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Empty copy is a success")
AssertEquals(*MsgPack\BufferOffset, OffsetBin32Small, "Empty copy still moved the offset")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 65536), 5, "Read forced 5 bytes bin32")
Assert(CompareMemory(*Output, *Source, 5), "Forced 5 bytes bin32 data matches")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 65536), 1, "Read forced 1 byte bin16")
AssertEqualsA(PeekA(*Output), PeekA(*Source), "Forced 1 byte bin16 data matches")

AssertEqualsA(MsgPackReadUInt8(*MsgPack), 42, "Read trailing UInt8")
AssertEquals(*MsgPack\BufferOffset, OffsetEnd, "Offset is at the end")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")


; Ending
MsgPackFree(*MsgPack, #True)
FreeMemory(*Source)
FreeMemory(*Output)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
