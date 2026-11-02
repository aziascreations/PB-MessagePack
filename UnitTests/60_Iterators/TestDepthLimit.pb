EnableExplicit

; Must be defined before the include, it replaces the default of 128.
#MsgPack_MaxDepth = 3

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Setup
Define *MsgPack.MsgPackData
Define *Content.MsgPackData
Define *Output.MsgPackData
Define *View1.MsgPackData
Define *View2.MsgPackData
Define *View3.MsgPackData
Define *View4.MsgPackData


Procedure TestDepth(Hex.s, ExpectedSize.q, TestName.s)
	Protected *MsgPack.MsgPackData = WrapHex(Hex)

	AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), ExpectedSize, TestName + " (Size)")
	If ExpectedSize = #MsgPack_InvalidSize
		AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_MaxDepthExceeded, TestName + " (Error)")
		AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_MaxDepthExceeded, TestName + " (Skip)")
		AssertEquals(*MsgPack\BufferOffset, 0, TestName + " (Skip leaves the offset)")
		AssertIsTrue(Bool(MsgPackExamine(*MsgPack) = #Null), TestName + " (Examine)")
		AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_MaxDepthExceeded, TestName + " (Examine error)")
		AssertEquals(*MsgPack\BufferOffset, 0, TestName + " (Examine leaves the offset)")
	Else
		AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_Success, TestName + " (Skip)")
		AssertEquals(*MsgPack\BufferOffset, ExpectedSize, TestName + " (Skip offset)")
	EndIf

	FreeWrappedHex(*MsgPack)
EndProcedure


; Boundaries, a top-level array or map being at depth 1
TestDepth("919191C0", 4, "Arrays nested 3 levels deep")
TestDepth("91919191C0", #MsgPack_InvalidSize, "Arrays nested 4 levels deep")
TestDepth("919190", 3, "Empty array at depth 3")
TestDepth("91919190", #MsgPack_InvalidSize, "Empty array at depth 4")
TestDepth("91919180", #MsgPack_InvalidSize, "Empty map at depth 4")
TestDepth("DC0001DC0001DC0001C0", 10, "Array16 nested 3 levels deep")
TestDepth("DD00000001DD00000001DD00000001DD00000001C0", #MsgPack_InvalidSize, "Array32 nested 4 levels deep")

; Maps, as keys and as values
TestDepth("818180C0C0", 5, "Maps nested 3 levels deep as keys")
TestDepth("81818180C0C0C0", #MsgPack_InvalidSize, "Maps nested 4 levels deep as keys")
TestDepth("81C081C081C0C0", 7, "Maps nested 3 levels deep as values")
TestDepth("81C081C081C081C0C0", #MsgPack_InvalidSize, "Maps nested 4 levels deep as values")

; The depth goes back down between siblings
TestDepth("9291C091C0", 5, "Siblings at depth 2")
TestDepth("929191C09191C0", 7, "Siblings reaching depth 3")
TestDepth("82C09191C0C0C0", 7, "Map value reaching depth 3")
TestDepth("92C0919191C0", #MsgPack_InvalidSize, "Second sibling reaching depth 4")
TestDepth("939191C0C0919191C0", #MsgPack_InvalidSize, "Third sibling reaching depth 4")

; Skipping several fields, each one starting back at depth 1
*MsgPack = WrapHex("919191C0919191C0")
AssertEquals(MsgPackSkip(*MsgPack, 2), #MsgPack_Error_Success, "Skipped 2 fields 3 levels deep")
AssertEquals(*MsgPack\BufferOffset, 8, "Offset after the 2 fields")
FreeWrappedHex(*MsgPack)


; Checked views: each level is reachable, the content was checked by the top-level one
*MsgPack = WrapHex("919191C0")
*View1 = MsgPackExamine(*MsgPack)
AssertIsTrue(Bool(*View1 <> #Null), "Examined depth 1")
AssertIsTrue(MsgPackNextEntry(*View1), "Depth 1 entry")
*View2 = MsgPackExamine(*View1)
AssertIsTrue(Bool(*View2 <> #Null), "Examined depth 2")
AssertIsTrue(MsgPackNextEntry(*View2), "Depth 2 entry")
*View3 = MsgPackExamine(*View2)
AssertIsTrue(Bool(*View3 <> #Null), "Examined depth 3")
AssertIsTrue(MsgPackNextEntry(*View3), "Depth 3 entry")
AssertEquals(MsgPackReadNull(*View3), #MsgPack_Error_Success, "Read the value at depth 3")
AssertIsFalse(MsgPackNextEntry(*View3), "End of depth 3")
MsgPackFinish(*View3)
AssertIsFalse(MsgPackNextEntry(*View2), "End of depth 2")
MsgPackFinish(*View2)
AssertIsFalse(MsgPackNextEntry(*View1), "End of depth 1")
MsgPackFinish(*View1)
FreeWrappedHex(*MsgPack)


; Unsafe views aren't checked beforehand, their own nesting is limited
*MsgPack = WrapHex("91919191C0")
*View1 = MsgPackExamine(*MsgPack, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*View1 <> #Null), "Unsafe examined depth 1")
AssertIsTrue(MsgPackNextEntry(*View1), "Unsafe depth 1 entry")
*View2 = MsgPackExamine(*View1, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*View2 <> #Null), "Unsafe examined depth 2")
AssertIsTrue(MsgPackNextEntry(*View2), "Unsafe depth 2 entry")
*View3 = MsgPackExamine(*View2, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*View3 <> #Null), "Unsafe examined depth 3")
AssertIsTrue(MsgPackNextEntry(*View3), "Unsafe depth 3 entry")
*View4 = MsgPackExamine(*View3, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*View4 = #Null), "Unsafe depth 4 is rejected")
AssertEquals(MsgPackLastError(*View3), #MsgPack_Error_MaxDepthExceeded, "Unsafe depth 4 error is set")
*View4 = MsgPackExamine(*View3)
AssertIsTrue(Bool(*View4 = #Null), "Checked depth 4 is rejected too")
AssertEquals(MsgPackLastError(*View3), #MsgPack_Error_MaxDepthExceeded, "Checked depth 4 error is set")
AssertIsFalse(MsgPackNextEntry(*View3), "The depth 4 array can't be skipped")
AssertEquals(MsgPackLastError(*View3), #MsgPack_Error_MaxDepthExceeded, "Skip error is set")
MsgPackFinish(*View3)
AssertIsFalse(MsgPackNextEntry(*View2), "Depth 2 can't skip its entry either")
MsgPackFinish(*View2)
MsgPackFinish(*View1)
FreeWrappedHex(*MsgPack)


; Writers can't produce data deeper than the limit
*Output = MsgPackCreate(16)

*Content = WrapHex("9191C0")
AssertEquals(MsgPackWriteArray(*Output, *Content\Buffer, *Content\BufferSize), #MsgPack_Error_Success, "Array of content 2 levels deep")
AssertEquals(*Output\BufferOffset, 4, "Array written")
FreeWrappedHex(*Content)

*Content = WrapHex("919191C0")
AssertEquals(MsgPackWriteArray(*Output, *Content\Buffer, *Content\BufferSize), #MsgPack_Error_MaxDepthExceeded, "Array of content 3 levels deep")
AssertEquals(MsgPackLastError(*Output), #MsgPack_Error_MaxDepthExceeded, "Writer error is set")
AssertEquals(MsgPackWriteMap(*Output, *Content\Buffer, *Content\BufferSize), #MsgPack_Error_MaxDepthExceeded, "Map of content 3 levels deep")
AssertEquals(*Output\BufferOffset, 4, "Nothing was written")
FreeWrappedHex(*Content)

*Content = WrapHex("C09191C0")
AssertEquals(MsgPackWriteMap(*Output, *Content\Buffer, *Content\BufferSize), #MsgPack_Error_Success, "Map with a value 2 levels deep")
AssertEquals(*Output\BufferOffset, 9, "Map written")
FreeWrappedHex(*Content)

; The written data is at the limit, and can be read back
*Output\BufferOffset = 0
AssertEqualsQ(MsgPackGetFieldFullSize(*Output), 4, "Written array is readable")
*Output\BufferOffset = 4
AssertEqualsQ(MsgPackGetFieldFullSize(*Output), 5, "Written map is readable")

MsgPackFree(*Output, #True)



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
