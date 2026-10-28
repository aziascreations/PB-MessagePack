EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Non-ASCII characters are built with `Chr()` to not depend on the source file's encoding.


; Setup
; Starting with 1 byte so every write has to grow the buffer.
Define *MsgPack.MsgPackData = MsgPackCreate(1)

Define String31.s = LSet("", 31, "a")
Define String32.s = LSet("", 32, "b")
Define String255.s = LSet("", 255, "c")
Define String256.s = LSet("", 256, "d")
Define String65535.s = LSet("", 65535, "e")
Define String65536.s = LSet("", 65536, "f")

; U+00E9 is 2 bytes in UTF-8, so the format code depends on bytes, not characters.
Define Accents15.s = LSet("", 15, Chr($E9)) ; 30 bytes
Define Accents16.s = LSet("", 16, Chr($E9)) ; 32 bytes

; U+20AC is 3 bytes in UTF-8.
Define Euro.s = "Price: 5" + Chr($20AC)   ; 11 bytes

Define OffsetEmpty.i, Offset31.i, Offset32.i, Offset255.i, Offset256.i, Offset65535.i, Offset65536.i
Define OffsetAccents15.i, OffsetAccents16.i, OffsetEuro.i
Define OffsetStr32.i, OffsetStr8Empty.i, OffsetFixStr.i, OffsetStr16.i
Define OffsetAscii.i, OffsetUnicode.i, OffsetEnd.i


; Automatic format code selection, on each boundary
OffsetEmpty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, ""), #MsgPack_Error_Success, "Wrote empty string")
Offset31 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String31), #MsgPack_Error_Success, "Wrote 31 bytes")
Offset32 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String32), #MsgPack_Error_Success, "Wrote 32 bytes")
Offset255 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String255), #MsgPack_Error_Success, "Wrote 255 bytes")
Offset256 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String256), #MsgPack_Error_Success, "Wrote 256 bytes")
Offset65535 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String65535), #MsgPack_Error_Success, "Wrote 65535 bytes")
Offset65536 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, String65536), #MsgPack_Error_Success, "Wrote 65536 bytes")


; Multi-byte UTF-8 characters
OffsetAccents15 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, Accents15), #MsgPack_Error_Success, "Wrote 15 accents")
OffsetAccents16 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, Accents16), #MsgPack_Error_Success, "Wrote 16 accents")
OffsetEuro = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, Euro), #MsgPack_Error_Success, "Wrote euro string")


; Forced format codes, even when a smaller one fits
OffsetStr32 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteStr32(*MsgPack, "abc"), #MsgPack_Error_Success, "Wrote 3 bytes as str32")
OffsetStr8Empty = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteStr8(*MsgPack, ""), #MsgPack_Error_Success, "Wrote empty string as str8")
OffsetFixStr = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteFixStr(*MsgPack, "xyz"), #MsgPack_Error_Success, "Wrote 3 bytes as fixstr")
OffsetStr16 = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteStr16(*MsgPack, "q"), #MsgPack_Error_Success, "Wrote 1 byte as str16")


; Other encodings
OffsetAscii = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, "Hello", #PB_Ascii), #MsgPack_Error_Success, "Wrote ASCII string")
OffsetUnicode = *MsgPack\BufferOffset
AssertEquals(MsgPackWriteString(*MsgPack, "Hi" + Chr($20AC), #PB_Unicode), #MsgPack_Error_Success, "Wrote UTF-16 string")


; Something right after, to catch offset drifts
AssertEquals(MsgPackWriteUInt8(*MsgPack, 42), #MsgPack_Error_Success, "Wrote trailing UInt8")
OffsetEnd = *MsgPack\BufferOffset


; Offsets
AssertEquals(Offset31, OffsetEmpty + 1, "Empty fixstr takes 1 byte")
AssertEquals(Offset32, Offset31 + 1 + 31, "31 bytes fixstr takes 32 bytes")
AssertEquals(Offset255, Offset32 + 2 + 32, "32 bytes str8 takes 34 bytes")
AssertEquals(Offset256, Offset255 + 2 + 255, "255 bytes str8 takes 257 bytes")
AssertEquals(Offset65535, Offset256 + 3 + 256, "256 bytes str16 takes 259 bytes")
AssertEquals(Offset65536, Offset65535 + 3 + 65535, "65535 bytes str16 takes 65538 bytes")
AssertEquals(OffsetAccents15, Offset65536 + 5 + 65536, "65536 bytes str32 takes 65541 bytes")
AssertEquals(OffsetAccents16, OffsetAccents15 + 1 + 30, "15 accents fixstr takes 31 bytes")
AssertEquals(OffsetEuro, OffsetAccents16 + 2 + 32, "16 accents str8 takes 34 bytes")
AssertEquals(OffsetStr32, OffsetEuro + 1 + 11, "Euro fixstr takes 12 bytes")
AssertEquals(OffsetStr8Empty, OffsetStr32 + 5 + 3, "3 bytes str32 takes 8 bytes")
AssertEquals(OffsetFixStr, OffsetStr8Empty + 2, "Empty str8 takes 2 bytes")
AssertEquals(OffsetStr16, OffsetFixStr + 1 + 3, "3 bytes fixstr takes 4 bytes")
AssertEquals(OffsetAscii, OffsetStr16 + 3 + 1, "1 byte str16 takes 4 bytes")
AssertEquals(OffsetUnicode, OffsetAscii + 1 + 5, "5 bytes ASCII fixstr takes 6 bytes")
AssertEquals(OffsetEnd, OffsetUnicode + 1 + 6 + 2, "6 bytes UTF-16 fixstr and UInt8 take 9 bytes")
AssertEquals(*MsgPack\BufferSize, OffsetEnd, "Buffer grew to exactly what was written")


; Layouts
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEmpty), $A0, "Empty uses fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset31), $BF, "31 bytes uses fixstr")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset32), #MsgPack_FormatCode_Str8, "32 bytes uses str8")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset32 + 1), 32, "32 bytes str8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255), #MsgPack_FormatCode_Str8, "255 bytes uses str8")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset255 + 1), $FF, "255 bytes str8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256), #MsgPack_FormatCode_Str16, "256 bytes uses str16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 1), $01, "256 bytes str16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset256 + 2), $00, "256 bytes str16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535), #MsgPack_FormatCode_Str16, "65535 bytes uses str16")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 1), $FF, "65535 bytes str16 size high byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65535 + 2), $FF, "65535 bytes str16 size low byte")

AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536), #MsgPack_FormatCode_Str32, "65536 bytes uses str32")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 1), $00, "65536 bytes str32 size byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 2), $01, "65536 bytes str32 size byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 3), $00, "65536 bytes str32 size byte 3")
AssertEqualsA(PeekA(*MsgPack\Buffer + Offset65536 + 4), $00, "65536 bytes str32 size byte 4")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAccents15), $BE, "15 accents use a 30 bytes fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAccents15 + 1), $C3, "Accent UTF-8 byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAccents15 + 2), $A9, "Accent UTF-8 byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAccents16), #MsgPack_FormatCode_Str8, "16 accents use str8, not fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAccents16 + 1), 32, "16 accents str8 size is in bytes")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEuro), $AB, "Euro uses a 11 bytes fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEuro + 9), $E2, "Euro UTF-8 byte 1")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEuro + 10), $82, "Euro UTF-8 byte 2")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetEuro + 11), $AC, "Euro UTF-8 byte 3")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr32), #MsgPack_FormatCode_Str32, "Forced str32")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr32 + 4), $03, "Forced str32 size low byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr32 + 5), 'a', "Forced str32 data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr8Empty), #MsgPack_FormatCode_Str8, "Forced empty str8")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr8Empty + 1), $00, "Forced empty str8 size")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetFixStr), $A3, "Forced fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetStr16), #MsgPack_FormatCode_Str16, "Forced str16")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAscii), $A5, "ASCII uses a 5 bytes fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetAscii + 1), 'H', "ASCII data")

AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetUnicode), $A6, "UTF-16 uses a 6 bytes fixstr")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetUnicode + 1), 'H', "UTF-16 is little-endian (1)")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetUnicode + 2), $00, "UTF-16 is little-endian (2)")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetUnicode + 5), $AC, "UTF-16 euro low byte")
AssertEqualsA(PeekA(*MsgPack\Buffer + OffsetUnicode + 6), $20, "UTF-16 euro high byte")


; Reading them back
*MsgPack\BufferOffset = 0

Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Read empty string")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Empty read is a success")
Assert(Bool(MsgPackReadString(*MsgPack) = String31), "Read 31 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = String32), "Read 32 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = String255), "Read 255 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = String256), "Read 256 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = String65535), "Read 65535 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = String65536), "Read 65536 bytes")
Assert(Bool(MsgPackReadString(*MsgPack) = Accents15), "Read 15 accents")
Assert(Bool(MsgPackReadString(*MsgPack) = Accents16), "Read 16 accents")
Assert(Bool(MsgPackReadString(*MsgPack) = Euro), "Read euro string")
Assert(Bool(MsgPackReadString(*MsgPack) = "abc"), "Read forced str32")
Assert(Bool(MsgPackReadString(*MsgPack) = ""), "Read forced empty str8")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Forced empty str8 read is a success")
Assert(Bool(MsgPackReadString(*MsgPack) = "xyz"), "Read forced fixstr")
Assert(Bool(MsgPackReadString(*MsgPack) = "q"), "Read forced str16")
Assert(Bool(MsgPackReadString(*MsgPack, #PB_Ascii) = "Hello"), "Read ASCII string")
Assert(Bool(MsgPackReadString(*MsgPack, #PB_Unicode) = "Hi" + Chr($20AC)), "Read UTF-16 string")

AssertEqualsA(MsgPackReadUInt8(*MsgPack), 42, "Read trailing UInt8")
AssertEquals(*MsgPack\BufferOffset, OffsetEnd, "Offset is at the end")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "No error after reading")

MsgPackFree(*MsgPack, #True)


; Raw strings from other writers

; A null character cuts the string, but the whole field is still skipped.
*MsgPack = WrapHex("A46100626301")
Assert(Bool(MsgPackReadString(*MsgPack) = "a"), "Null character cuts the string")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Null character isn't an error")
AssertEquals(*MsgPack\BufferOffset, 5, "Whole field was skipped")
FreeWrappedHex(*MsgPack)

; A string ending exactly at the end of the buffer.
*MsgPack = WrapHex("D903616263")
Assert(Bool(MsgPackReadString(*MsgPack) = "abc"), "Read a str8 ending with the buffer")
AssertEquals(*MsgPack\BufferOffset, 5, "Offset is at the end")
FreeWrappedHex(*MsgPack)


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
