EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Checks that `#MsgPack_DataFlags_MoveOffsetAfterRead/Write` are honored by every family,
;  and that `#MsgPack_DataFlags_IsReadOnly` blocks every write.


Define *MsgPack.MsgPackData
Define *Iterator.MsgPackData
Define *Output = AllocateMemory(16)
Define Bytes.l = $44332211


; Writes without moving the offset, each one overwriting the previous one
*MsgPack = MsgPackCreate(32)
*MsgPack\DataFlags = *MsgPack\DataFlags & (~#MsgPack_DataFlags_MoveOffsetAfterWrite)

AssertEquals(MsgPackWriteInteger(*MsgPack, 1000), #MsgPack_Error_Success, "Wrote an int without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "Int write didn't move the offset")
AssertEquals(MsgPackWriteString(*MsgPack, "abc"), #MsgPack_Error_Success, "Wrote a string without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "String write didn't move the offset")
AssertEquals(MsgPackWriteBinary(*MsgPack, @Bytes, 4), #MsgPack_Error_Success, "Wrote a bin without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "Bin write didn't move the offset")
AssertEquals(MsgPackWriteExtension(*MsgPack, 1, @Bytes, 4), #MsgPack_Error_Success, "Wrote a fixext without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "Fixext write didn't move the offset")
AssertEquals(MsgPackWriteExt8(*MsgPack, 1, @Bytes, 3), #MsgPack_Error_Success, "Wrote an ext8 without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "Ext8 write didn't move the offset")
AssertEquals(MsgPackWriteArray(*MsgPack, @Bytes, 2), #MsgPack_Error_Success, "Wrote an array without moving")
AssertEquals(*MsgPack\BufferOffset, 0, "Array write didn't move the offset")
AssertEqualsA(PeekA(*MsgPack\Buffer), $92, "Array was written at the start")

MsgPackFree(*MsgPack, #True)


; Reads without moving the offset, so the same field can be read twice
*MsgPack = WrapHex("CD03E8A3616263C4021122D401AAC0")
*MsgPack\DataFlags = *MsgPack\DataFlags & (~#MsgPack_DataFlags_MoveOffsetAfterRead)

AssertEqualsQ(MsgPackReadInteger(*MsgPack), 1000, "Peeked an int")
AssertEqualsQ(MsgPackReadUInt16(*MsgPack), 1000, "Read the same int again")
AssertEquals(*MsgPack\BufferOffset, 0, "Int reads didn't move the offset")
MsgPackSkip(*MsgPack)

AssertIsTrue(Bool(MsgPackReadString(*MsgPack) = "abc"), "Peeked a string")
AssertEquals(*MsgPack\BufferOffset, 3, "String read didn't move the offset")
MsgPackSkip(*MsgPack)

AssertEqualsQ(MsgPackReadBinary(*MsgPack, *Output, 16), 2, "Peeked a bin")
AssertEquals(*MsgPack\BufferOffset, 7, "Bin read didn't move the offset")
MsgPackSkip(*MsgPack)

AssertEqualsQ(MsgPackReadExtension(*MsgPack, *Output, 16), 1, "Peeked an ext")
AssertEquals(*MsgPack\BufferOffset, 11, "Ext read didn't move the offset")
MsgPackSkip(*MsgPack)

AssertEquals(MsgPackReadNull(*MsgPack), #MsgPack_Error_Success, "Peeked a nil")
AssertEquals(*MsgPack\BufferOffset, 14, "Nil read didn't move the offset")

FreeWrappedHex(*MsgPack)


; Views are read-only: [1, 2]
*MsgPack = WrapHex("920102")
*Iterator = MsgPackExamine(*MsgPack)
MsgPackNextEntry(*Iterator)

AssertEquals(MsgPackWriteNull(*Iterator), #MsgPack_Error_BufferIsReadOnly, "Cannot write a literal in a view")
AssertEquals(MsgPackWriteBoolean(*Iterator, #True), #MsgPack_Error_BufferIsReadOnly, "Cannot write a boolean in a view")
AssertEquals(MsgPackWriteInteger(*Iterator, 5), #MsgPack_Error_BufferIsReadOnly, "Cannot write an int in a view")
AssertEquals(MsgPackWriteString(*Iterator, "a"), #MsgPack_Error_BufferIsReadOnly, "Cannot write a string in a view")
AssertEquals(MsgPackWriteBinary(*Iterator, @Bytes, 1), #MsgPack_Error_BufferIsReadOnly, "Cannot write a bin in a view")
AssertEquals(MsgPackWriteExtension(*Iterator, 1, @Bytes, 1), #MsgPack_Error_BufferIsReadOnly, "Cannot write an ext in a view")
AssertEquals(MsgPackWriteArray(*Iterator, @Bytes, 1), #MsgPack_Error_BufferIsReadOnly, "Cannot write an array in a view")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_BufferIsReadOnly, "Read-only error is set")
AssertEquals(*Iterator\BufferOffset, 0, "Offset is untouched by the rejected writes")
AssertIsTrue(Bool(PeekA(*MsgPack\Buffer + 1) = $01 And PeekA(*MsgPack\Buffer + 2) = $02), "Parent data is untouched")

AssertEqualsQ(MsgPackReadInteger(*Iterator), 1, "View can still be read")
MsgPackFinish(*Iterator)
FreeWrappedHex(*MsgPack)


; Nil and booleans
*MsgPack = MsgPackCreate(1)
AssertEquals(MsgPackWriteBoolean(*MsgPack, #True), #MsgPack_Error_Success, "Wrote a true boolean")
AssertEquals(MsgPackWriteBoolean(*MsgPack, #False), #MsgPack_Error_Success, "Wrote a false boolean")
AssertEquals(MsgPackWriteNull(*MsgPack), #MsgPack_Error_Success, "Wrote a nil")
*MsgPack\BufferOffset = 0

AssertEquals(MsgPackReadNull(*MsgPack), #MsgPack_Error_InvalidFormatCode, "True isn't a nil")
AssertEquals(*MsgPack\BufferOffset, 0, "Failed nil read didn't move the offset")
AssertIsTrue(MsgPackReadBoolean(*MsgPack), "Read the true boolean")
AssertIsFalse(MsgPackReadBoolean(*MsgPack), "Read the false boolean")
AssertIsFalse(MsgPackReadBoolean(*MsgPack), "Nil isn't a boolean")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Boolean error is set")
AssertEquals(MsgPackReadNull(*MsgPack), #MsgPack_Error_Success, "Read the nil")
AssertEquals(MsgPackReadNull(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Cannot read a nil at the end")
AssertEquals(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_Invalid, "No format code at the end")
AssertEquals(MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*MsgPack)), #MsgPack_DataTypes_Unknown, "No data type at the end")
MsgPackFree(*MsgPack, #True)


FreeMemory(*Output)



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
