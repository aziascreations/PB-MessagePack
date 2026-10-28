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

Define OffsetEmpty.i, OffsetFix1.i, OffsetFix2.i, OffsetFix4.i, OffsetFix8.i, OffsetFix16.i
Define Offset3.i, Offset255.i, Offset256.i, Offset65535.i, Offset65536.i
Define OffsetExt8Fix.i, OffsetExt16Small.i, OffsetExt32Empty.i, OffsetFixExt4.i, OffsetFixExt16.i
Define OffsetEnd.i


; Automatic format code selection, on each boundary
OffsetEmpty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 5, #Null, 0), #MsgPack_Error_Success, "Wrote 0 bytes from a #Null buffer")
OffsetFix1 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 1, *Source, 1), #MsgPack_Error_Success, "Wrote 1 byte")
OffsetFix2 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, -1, *Source, 2), #MsgPack_Error_Success, "Wrote 2 bytes")
OffsetFix4 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 127, *Source, 4), #MsgPack_Error_Success, "Wrote 4 bytes")
OffsetFix8 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, -128, *Source, 8), #MsgPack_Error_Success, "Wrote 8 bytes")
OffsetFix16 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 42, *Source, 16), #MsgPack_Error_Success, "Wrote 16 bytes")
Offset3 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 3, *Source, 3), #MsgPack_Error_Success, "Wrote 3 bytes")
Offset255 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 6, *Source, 255), #MsgPack_Error_Success, "Wrote 255 bytes")
Offset256 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 7, *Source, 256), #MsgPack_Error_Success, "Wrote 256 bytes")
Offset65535 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 8, *Source, 65535), #MsgPack_Error_Success, "Wrote 65535 bytes")
Offset65536 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExtension(*MsgPack, 9, *Source, 65536), #MsgPack_Error_Success, "Wrote 65536 bytes")


; Forced format codes, even when a smaller one fits
OffsetExt8Fix = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExt8(*MsgPack, 10, *Source, 4), #MsgPack_Error_Success, "Wrote 4 bytes as ext8")
OffsetExt16Small = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExt16(*MsgPack, 11, *Source, 1), #MsgPack_Error_Success, "Wrote 1 byte as ext16")
OffsetExt32Empty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteExt32(*MsgPack, 12, #Null, 0), #MsgPack_Error_Success, "Wrote 0 bytes as ext32")
OffsetFixExt4 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteFixExt4(*MsgPack, 13, *Source), #MsgPack_Error_Success, "Wrote fixext4")
OffsetFixExt16 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteFixExt16(*MsgPack, 14, *Source), #MsgPack_Error_Success, "Wrote fixext16")


; Something right after, to catch offset drifts
AssertEquals(MsgPackWriteUInt8(*MsgPack, 42), #MsgPack_Error_Success, "Wrote trailing UInt8")
OffsetEnd = *MsgPack\BufferOffset


; Offsets
AssertEquals(OffsetFix1, OffsetEmpty + 3, "Empty ext8 takes 3 bytes")
AssertEquals(OffsetFix2, OffsetFix1 + 2 + 1, "fixext1 takes 3 bytes")
AssertEquals(OffsetFix4, OffsetFix2 + 2 + 2, "fixext2 takes 4 bytes")
AssertEquals(OffsetFix8, OffsetFix4 + 2 + 4, "fixext4 takes 6 bytes")
AssertEquals(OffsetFix16, OffsetFix8 + 2 + 8, "fixext8 takes 10 bytes")
AssertEquals(Offset3, OffsetFix16 + 2 + 16, "fixext16 takes 18 bytes")
AssertEquals(Offset255, Offset3 + 3 + 3, "3 bytes ext8 takes 6 bytes")
AssertEquals(Offset256, Offset255 + 3 + 255, "255 bytes ext8 takes 258 bytes")
AssertEquals(Offset65535, Offset256 + 4 + 256, "256 bytes ext16 takes 260 bytes")
AssertEquals(Offset65536, Offset65535 + 4 + 65535, "65535 bytes ext16 takes 65539 bytes")
AssertEquals(OffsetExt8Fix, Offset65536 + 6 + 65536, "65536 bytes ext32 takes 65542 bytes")
AssertEquals(OffsetExt16Small, OffsetExt8Fix + 3 + 4, "4 bytes ext8 takes 7 bytes")
AssertEquals(OffsetExt32Empty, OffsetExt16Small + 4 + 1, "1 byte ext16 takes 5 bytes")
AssertEquals(OffsetFixExt4, OffsetExt32Empty + 6, "Empty ext32 takes 6 bytes")
AssertEquals(OffsetFixExt16, OffsetFixExt4 + 2 + 4, "Forced fixext4 takes 6 bytes")
AssertEquals(OffsetEnd, OffsetFixExt16 + 2 + 16 + 2, "Forced fixext16 and UInt8 take 20 bytes")
AssertEquals(*MsgPack\BufferSize, OffsetEnd, "Buffer grew to exactly what was written")


; Big-endian layouts
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEmpty), #MsgPack_FormatCode_Ext8, "Empty uses ext8")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEmpty + 1), $00, "Empty ext8 size")
AssertEqualsB(PeekB(*MsgPack\Buffer + OffsetEmpty + 2), 5, "Empty ext8 type")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix1), #MsgPack_FormatCode_FixExt1, "1 byte uses fixext1")
AssertEqualsB(PeekB(*MsgPack\Buffer + OffsetFix1 + 1), 1, "fixext1 type")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix1 + 2), PeekA(*Source), "fixext1 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix2), #MsgPack_FormatCode_FixExt2, "2 bytes uses fixext2")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix2 + 1), $FF, "fixext2 negative type")
Assert(CompareMemory(*MsgPack\Buffer + OffsetFix2 + 2, *Source, 2), "fixext2 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix4), #MsgPack_FormatCode_FixExt4, "4 bytes uses fixext4")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix4 + 1), $7F, "fixext4 type")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix8), #MsgPack_FormatCode_FixExt8, "8 bytes uses fixext8")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix8 + 1), $80, "fixext8 type")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFix16), #MsgPack_FormatCode_FixExt16, "16 bytes uses fixext16")
Assert(CompareMemory(*MsgPack\Buffer + OffsetFix16 + 2, *Source, 16), "fixext16 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset3), #MsgPack_FormatCode_Ext8, "3 bytes uses ext8")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset3 + 1), $03, "3 bytes ext8 size")
AssertEqualsB(PeekB(*MsgPack\Buffer + Offset3 + 2), 3, "3 bytes ext8 type")
Assert(CompareMemory(*MsgPack\Buffer + Offset3 + 3, *Source, 3), "3 bytes ext8 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255), #MsgPack_FormatCode_Ext8, "255 bytes uses ext8")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255 + 1), $FF, "255 bytes ext8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256), #MsgPack_FormatCode_Ext16, "256 bytes uses ext16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 1), $01, "256 bytes ext16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 2), $00, "256 bytes ext16 size low byte")
AssertEqualsB(PeekB(*MsgPack\Buffer + Offset256 + 3), 7, "256 bytes ext16 type")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535), #MsgPack_FormatCode_Ext16, "65535 bytes uses ext16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 1), $FF, "65535 bytes ext16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 2), $FF, "65535 bytes ext16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536), #MsgPack_FormatCode_Ext32, "65536 bytes uses ext32")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 1), $00, "65536 bytes ext32 size byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 2), $01, "65536 bytes ext32 size byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 3), $00, "65536 bytes ext32 size byte 3")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 4), $00, "65536 bytes ext32 size byte 4")
AssertEqualsB(PeekB(*MsgPack\Buffer + Offset65536 + 5), 9, "65536 bytes ext32 type")
Assert(CompareMemory(*MsgPack\Buffer + Offset65536 + 6, *Source, 65536), "65536 bytes ext32 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetExt8Fix), #MsgPack_FormatCode_Ext8, "Forced 4 bytes ext8")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetExt8Fix + 1), $04, "Forced 4 bytes ext8 size")
AssertEqualsB(PeekB(*MsgPack\Buffer + OffsetExt8Fix + 2), 10, "Forced 4 bytes ext8 type")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetExt32Empty), #MsgPack_FormatCode_Ext32, "Forced empty ext32")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetExt32Empty + 4), $00, "Forced empty ext32 size byte 4")
AssertEqualsB(PeekB(*MsgPack\Buffer + OffsetExt32Empty + 5), 12, "Forced empty ext32 type")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFixExt4), #MsgPack_FormatCode_FixExt4, "Forced fixext4")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFixExt16), #MsgPack_FormatCode_FixExt16, "Forced fixext16")
AssertEqualsB(PeekB(*MsgPack\Buffer + OffsetFixExt16 + 1), 14, "Forced fixext16 type")


; Reading them back
*MsgPack\BufferOffset = 0

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 5, "Empty ext8 type is read")
AssertEquals(*MsgPack\BufferOffset, 0, "Reading the type didn't move the offset")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, #Null, 0), 0, "Read empty ext8 into a #Null buffer")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Empty read is a success")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 1, "fixext1 type is read")
FillMemory(*Output, 65536, $AA)
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 1), 1, "Read fixext1 into an exactly sized buffer")
AssertEqualsA(PeekA(*Output), PeekA(*Source), "fixext1 data matches")
AssertEqualsA(PeekA(*Output + 1), $AA, "Nothing written past the data")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), -1, "fixext2 negative type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 2, "Read fixext2")
Assert(CompareMemory(*Output, *Source, 2), "fixext2 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 127, "fixext4 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 4, "Read fixext4")
Assert(CompareMemory(*Output, *Source, 4), "fixext4 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), -128, "fixext8 type is read")
*Copy = MsgPackCopyExtension(*MsgPack)
Assert(Bool(*Copy <> #Null), "Copied fixext8")
If *Copy
	AssertEquals(MemorySize(*Copy), 8, "Copy is exactly 8 bytes")
	Assert(CompareMemory(*Copy, *Source, 8), "fixext8 data matches")
	FreeMemory(*Copy)
EndIf

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 42, "fixext16 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), 16, "Read fixext16")
Assert(CompareMemory(*Output, *Source, 16), "fixext16 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 3, "3 bytes ext8 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 3, "Read 3 bytes ext8")
Assert(CompareMemory(*Output, *Source, 3), "3 bytes ext8 data matches")

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 255), 255, "Read 255 bytes ext8")
Assert(CompareMemory(*Output, *Source, 255), "255 bytes data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 7, "256 bytes ext16 type is read")
*Copy = MsgPackCopyExtension(*MsgPack)
Assert(Bool(*Copy <> #Null), "Copied 256 bytes")
If *Copy
	AssertEquals(MemorySize(*Copy), 256, "Copy is exactly 256 bytes")
	Assert(CompareMemory(*Copy, *Source, 256), "256 bytes data matches")
	FreeMemory(*Copy)
EndIf

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 65535, "Read 65535 bytes ext16")
Assert(CompareMemory(*Output, *Source, 65535), "65535 bytes data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 9, "65536 bytes ext32 type is read")
*Copy = MsgPackCopyExtension(*MsgPack)
Assert(Bool(*Copy <> #Null), "Copied 65536 bytes")
If *Copy
	AssertEquals(MemorySize(*Copy), 65536, "Copy is exactly 65536 bytes")
	Assert(CompareMemory(*Copy, *Source, 65536), "65536 bytes data matches")
	FreeMemory(*Copy)
EndIf

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 10, "Forced ext8 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 4, "Read forced 4 bytes ext8")
Assert(CompareMemory(*Output, *Source, 4), "Forced 4 bytes ext8 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 11, "Forced ext16 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 1, "Read forced 1 byte ext16")
AssertEqualsA(PeekA(*Output), PeekA(*Source), "Forced 1 byte ext16 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 12, "Forced ext32 type is read")
AssertEquals(MsgPackCopyExtension(*MsgPack), #Null, "Copying an empty ext32 returns #Null")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Empty copy is a success")
AssertEquals(*MsgPack\BufferOffset, OffsetFixExt4, "Empty copy still moved the offset")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 13, "Forced fixext4 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 4, "Read forced fixext4")
Assert(CompareMemory(*Output, *Source, 4), "Forced fixext4 data matches")

AssertEqualsB(MsgPackGetExtensionType(*MsgPack), 14, "Forced fixext16 type is read")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 65536), 16, "Read forced fixext16")
Assert(CompareMemory(*Output, *Source, 16), "Forced fixext16 data matches")

AssertEqualsA(MsgPackReadUInt8(*MsgPack), 42, "Read trailing UInt8")
AssertEquals(*MsgPack\BufferOffset, OffsetEnd, "Offset is at the end")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")

MsgPackFree(*MsgPack, #True)


; Known vector: timestamp 32 for 1970-01-01T00:00:01Z
*MsgPack = WrapHex("D6FF00000001")

AssertEquals(MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*MsgPack)), #MsgPack_DataTypes_Extension, "Timestamp is detected as an extension")
AssertEqualsB(MsgPackGetExtensionType(*MsgPack), -1, "Timestamp type is -1")
AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 4), 4, "Read the timestamp's 4 bytes")
AssertEquals(EndianSwapI32(PeekL(*Output)), 1, "Timestamp seconds are big-endian")
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
