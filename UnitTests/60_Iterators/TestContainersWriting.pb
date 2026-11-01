EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Only covers errors that don't call `DebuggerError()`.


Procedure.s WrittenHex(*MsgPack.MsgPackData)
	Protected Result.s = ""
	Protected i.i

	For i = 0 To *MsgPack\BufferOffset - 1
		Result = Result + RSet(Hex(PeekA(*MsgPack\Buffer + i)), 2, "0")
	Next

	ProcedureReturn Result
EndProcedure


; Writes the content given as hex with `WriteMode` and checks the whole output.
; Modes: 0 = Array, 1 = Map, 2 = FixArray, 3 = Array16, 4 = Array32, 5 = FixMap, 6 = Map16, 7 = Map32
Procedure TestWrite(WriteMode.i, ContentHex.s, ExpectedError.i, ExpectedHex.s, TestName.s)
	Protected *Content.MsgPackData = WrapHex(ContentHex + "00")
	Protected *MsgPack.MsgPackData = MsgPackCreate(1)
	Protected ContentSize.q = Len(ContentHex) / 2
	Protected ErrorCode.i

	Select WriteMode
		Case 0 : ErrorCode = MsgPackWriteArray(*MsgPack, *Content\Buffer, ContentSize)
		Case 1 : ErrorCode = MsgPackWriteMap(*MsgPack, *Content\Buffer, ContentSize)
		Case 2 : ErrorCode = MsgPackWriteFixArray(*MsgPack, *Content\Buffer, ContentSize)
		Case 3 : ErrorCode = MsgPackWriteArray16(*MsgPack, *Content\Buffer, ContentSize)
		Case 4 : ErrorCode = MsgPackWriteArray32(*MsgPack, *Content\Buffer, ContentSize)
		Case 5 : ErrorCode = MsgPackWriteFixMap(*MsgPack, *Content\Buffer, ContentSize)
		Case 6 : ErrorCode = MsgPackWriteMap16(*MsgPack, *Content\Buffer, ContentSize)
		Case 7 : ErrorCode = MsgPackWriteMap32(*MsgPack, *Content\Buffer, ContentSize)
	EndSelect

	AssertEquals(ErrorCode, ExpectedError, TestName + " (Error)")
	AssertEquals(MsgPackLastError(*MsgPack), ExpectedError, TestName + " (Last error)")
	AssertIsTrue(Bool(WrittenHex(*MsgPack) = ExpectedHex), TestName + " (Output)", WrittenHex(*MsgPack) + " <> " + ExpectedHex)

	MsgPackFree(*MsgPack, #True)
	FreeWrappedHex(*Content)
EndProcedure


Define *MsgPack.MsgPackData
Define *Inner.MsgPackData
Define *Iterator.MsgPackData
Define *Finalized
Define Content.s
Define i.i


; Smallest fit
TestWrite(0, "", #MsgPack_Error_Success, "90", "Empty array")
TestWrite(1, "", #MsgPack_Error_Success, "80", "Empty map")
TestWrite(0, "01A16192C0C3", #MsgPack_Error_Success, "9301A16192C0C3", "FixArray with a nested array")
TestWrite(1, "A16101A16292C0C3", #MsgPack_Error_Success, "82A16101A16292C0C3", "FixMap with a nested array")

Content = ""
For i = 1 To 16
	Content = Content + "C0"
Next
TestWrite(0, Content, #MsgPack_Error_Success, "DC0010" + Content, "Array16 for 16 entries")
TestWrite(1, Content, #MsgPack_Error_Success, "88" + Content, "FixMap for 8 pairs")

Content = ""
For i = 1 To 32
	Content = Content + "C0"
Next
TestWrite(1, Content, #MsgPack_Error_Success, "DE0010" + Content, "Map16 for 16 pairs")

; Forced format codes
TestWrite(2, "01", #MsgPack_Error_Success, "9101", "Forced FixArray")
TestWrite(3, "01", #MsgPack_Error_Success, "DC000101", "Forced Array16")
TestWrite(4, "01", #MsgPack_Error_Success, "DD0000000101", "Forced Array32")
TestWrite(5, "0102", #MsgPack_Error_Success, "810102", "Forced FixMap")
TestWrite(6, "0102", #MsgPack_Error_Success, "DE00010102", "Forced Map16")
TestWrite(7, "0102", #MsgPack_Error_Success, "DF000000010102", "Forced Map32")

; Errors, nothing must be written
TestWrite(1, "A16101A162", #MsgPack_Error_OddMapFieldCount, "", "Map with a key lacking its value")
TestWrite(5, "01", #MsgPack_Error_OddMapFieldCount, "", "FixMap with a single field")
TestWrite(2, Content, #MsgPack_Error_TooManyEntries, "", "FixArray with 32 entries")
TestWrite(0, "01C1", #MsgPack_Error_InvalidFormatCode, "", "Array with invalid content")
TestWrite(0, "01A361", #MsgPack_Error_BufferTooSmall, "", "Array with a truncated field")
TestWrite(0, "9201", #MsgPack_Error_BufferTooSmall, "", "Array with a truncated nested array")


; From a `MsgPackData`, and from a finalized buffer, then read back
*Inner = MsgPackCreate(4)
MsgPackWriteString(*Inner, "id")
MsgPackWriteInteger(*Inner, 1234)
MsgPackWriteString(*Inner, "tags")

*MsgPack = MsgPackCreate(1)
AssertEquals(MsgPackWriteMapFrom(*MsgPack, *Inner), #MsgPack_Error_OddMapFieldCount, "Inner map content lacks a value")
AssertEquals(*MsgPack\BufferOffset, 0, "Nothing was written for the odd map")

MsgPackWriteArray(*Inner, ?Tags, ?TagsEnd - ?Tags)
AssertEquals(MsgPackWriteMapFrom(*MsgPack, *Inner), #MsgPack_Error_Success, "Wrote the map from a MsgPackData")
AssertEquals(MsgPackWriteArrayFrom(*MsgPack, *Inner), #MsgPack_Error_Success, "Wrote an array from the same MsgPackData")

*Finalized = MsgPackFinalize(*Inner)
AssertEquals(MsgPackWriteArray(*MsgPack, *Finalized, MemorySize(*Finalized)), #MsgPack_Error_Success, "Wrote an array from a finalized buffer")
FreeMemory(*Finalized)

AssertIsTrue(Bool(WrittenHex(*MsgPack) = "82A26964CD04D2A47461677392A161A162" + "94A26964CD04D2A47461677392A161A162" + "94A26964CD04D2A47461677392A161A162"), "Written buffer", WrittenHex(*MsgPack))

*MsgPack\BufferOffset = 0
*Iterator = MsgPackExamine(*MsgPack)
AssertIsTrue(MsgPackNextEntry(*Iterator), "Read back entry #1")
AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "id"), "Read back key #1")
AssertEqualsQ(MsgPackReadInteger(*Iterator), 1234, "Read back value #1")
AssertIsTrue(MsgPackNextEntry(*Iterator), "Read back entry #2")
AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "tags"), "Read back key #2")
AssertEqualsQ(MsgPackGetEntryCount(*Iterator), 2, "Read back value #2 entry count")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Read back map has 2 entries")
MsgPackFinish(*Iterator)

AssertEqualsQ(MsgPackGetEntryCount(*MsgPack), 4, "Read back array has 4 entries")


MsgPackFree(*MsgPack, #True)



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0


DataSection
	Tags:
	Data.a $A1, $61, $A1, $62
	TagsEnd:
EndDataSection
