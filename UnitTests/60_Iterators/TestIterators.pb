EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Note: Only covers errors that don't call `DebuggerError()`.


; Setup
Define *MsgPack.MsgPackData
Define *Iterator.MsgPackData
Define *Nested.MsgPackData
Define EntryCount.i
Define i.i
Define Hex.s


Procedure TestFullSize(Hex.s, ExpectedSize.q, TestName.s)
	Protected *MsgPack.MsgPackData = WrapHex(Hex)

	AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), ExpectedSize, TestName + " (Size)")
	AssertEquals(*MsgPack\BufferOffset, 0, TestName + " (Offset untouched)")

	FreeWrappedHex(*MsgPack)
EndProcedure


; Full sizes of single fields, with an extra trailing byte that must not be counted
TestFullSize("C0FF", 1, "Nil")
TestFullSize("C3FF", 1, "True")
TestFullSize("7FFF", 1, "Positive fixint")
TestFullSize("E0FF", 1, "Negative fixint")
TestFullSize("CCFFFF", 2, "UInt8")
TestFullSize("D10001FF", 3, "Int16")
TestFullSize("CE00000001FF", 5, "UInt32")
TestFullSize("CA3FC00000FF", 5, "Float32")
TestFullSize("D30000000000000001FF", 9, "Int64")
TestFullSize("CB4000000000000000FF", 9, "Float64")
TestFullSize("A26162FF", 3, "FixStr")
TestFullSize("D9026162FF", 4, "Str8")
TestFullSize("C50002AAAAFF", 5, "Bin16")
TestFullSize("D401AAFF", 3, "FixExt1")
TestFullSize("D801AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFF", 18, "FixExt16")
TestFullSize("C70205AAAAFF", 5, "Ext8")
TestFullSize("90FF", 1, "Empty array")
TestFullSize("80FF", 1, "Empty map")
TestFullSize("920102FF", 3, "FixArray")
TestFullSize("DC00020102FF", 5, "Array16")
TestFullSize("DD000000020102FF", 7, "Array32")
TestFullSize("82A16101A16202FF", 7, "FixMap")
TestFullSize("DE0001A16101FF", 6, "Map16")
TestFullSize("9291C091C0FF", 5, "Nested arrays")

; Invalid and truncated fields
*MsgPack = WrapHex("C1")
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Invalid format code has no size")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Invalid format code error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("930102")
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Truncated array has no size")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated array error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the truncated array")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("DDFFFFFFFF01")
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Bogus array size is rejected")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Bogus array size error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("CD00")
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Truncated UInt16 has no size")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated UInt16 error is set")
FreeWrappedHex(*MsgPack)

; Deep nesting doesn't overflow the stack
Hex = ""
For i = 1 To 10000
	Hex = Hex + "91"
Next
*MsgPack = WrapHex(Hex + "01")
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), 10001, "Deeply nested arrays")
FreeWrappedHex(*MsgPack)


; Entry counts
*MsgPack = WrapHex("DC0003010203")
AssertEqualsQ(MsgPackGetEntryCount(*MsgPack), 3, "Array16 entry count")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("82A16101A16202")
AssertEqualsQ(MsgPackGetEntryCount(*MsgPack), 2, "Map entry count")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("01")
AssertEqualsQ(MsgPackGetEntryCount(*MsgPack), #MsgPack_InvalidSize, "Fixint has no entry count")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Entry count error is set")
FreeWrappedHex(*MsgPack)


; Skipping
*MsgPack = WrapHex("01A161C0")
AssertEquals(MsgPackSkip(*MsgPack, 2), #MsgPack_Error_Success, "Skipped 2 fields")
AssertEquals(*MsgPack\BufferOffset, 3, "Offset after skipping 2 fields")
AssertEquals(MsgPackSkip(*MsgPack, 2), #MsgPack_Error_BufferTooSmall, "Cannot skip past the end")
AssertEquals(*MsgPack\BufferOffset, 3, "Offset is untouched by the failed skip")
AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_Success, "Skipped the last field")
AssertIsTrue(Bool(_MsgPackIsAtTheEnd(*MsgPack)), "Reached the end by skipping")
AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Cannot skip at the end")
FreeWrappedHex(*MsgPack)


; Iterating on an array: [1, "ab", [true, nil], {"k": [1, 2]}, 3] followed by `false`
*MsgPack = WrapHex("9501A26162" + "92C3C0" + "81A16B920102" + "03" + "C2")

*Iterator = MsgPackExamine(*MsgPack)
AssertIsTrue(Bool(*Iterator <> #Null), "Examined the array")
AssertEquals(*MsgPack\BufferOffset, 15, "Offset was moved past the array")
AssertEquals(*Iterator\BufferSize, 14, "View is limited to the array's content")

EntryCount = 0
While MsgPackNextEntry(*Iterator)
	EntryCount = EntryCount + 1
	Select EntryCount
		Case 1
			AssertEqualsQ(MsgPackReadInteger(*Iterator), 1, "Entry #1")
		Case 2
			AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "ab"), "Entry #2")
		Case 3
			; Left unread, must be skipped as a whole
			AssertEquals(MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*Iterator)), #MsgPack_DataTypes_Array, "Entry #3 is an array")
		Case 4
			*Nested = MsgPackExamine(*Iterator)
			AssertIsTrue(Bool(*Nested <> #Null), "Examined the nested map")
			AssertIsTrue(MsgPackNextEntry(*Nested), "Nested map has an entry")
			AssertIsTrue(Bool(MsgPackReadString(*Nested) = "k"), "Nested map key")
			AssertEqualsQ(MsgPackGetEntryCount(*Nested), 2, "Nested map value is a 2 entries array")
			AssertIsFalse(MsgPackNextEntry(*Nested), "Nested map has a single entry")
			AssertEquals(MsgPackLastError(*Nested), #MsgPack_Error_Success, "Nested map ended without errors")
			MsgPackFinish(*Nested)
		Case 5
			AssertEqualsQ(MsgPackReadInteger(*Iterator), 3, "Entry #5")
	EndSelect
Wend

AssertEquals(EntryCount, 5, "Iterated on 5 entries")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_Success, "Array ended without errors")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Iteration stays over")
MsgPackFinish(*Iterator)

AssertIsFalse(MsgPackReadBoolean(*MsgPack), "Read the field following the array")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_Success, "Field following the array was read properly")
FreeWrappedHex(*MsgPack)


; Iterating on a map while only reading the keys: {"a": 1, "b": [2, 3]}
*MsgPack = WrapHex("82A16101A16292020305")

*Iterator = MsgPackExamine(*MsgPack)
AssertIsTrue(MsgPackNextEntry(*Iterator), "Map entry #1")
AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "a"), "Map key #1")
AssertIsTrue(MsgPackNextEntry(*Iterator), "Map entry #2")
AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "b"), "Map key #2")
AssertEquals(MsgPackSkip(*Iterator), #MsgPack_Error_Success, "Skipped map value #2")
AssertEqualsQ(MsgPackReadInteger(*Iterator), 0, "Cannot read past the map's end")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Map's end error is set")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Map has 2 entries")
MsgPackFinish(*Iterator)

AssertEqualsQ(MsgPackReadInteger(*MsgPack), 5, "Read the field following the map")
FreeWrappedHex(*MsgPack)


; Empty arrays and maps
*MsgPack = WrapHex("9080")

*Iterator = MsgPackExamine(*MsgPack)
AssertIsTrue(Bool(*Iterator <> #Null), "Examined the empty array")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Empty array has no entries")
MsgPackFinish(*Iterator)

*Iterator = MsgPackExamine(*MsgPack)
AssertIsTrue(Bool(*Iterator <> #Null), "Examined the empty map")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Empty map has no entries")
MsgPackFinish(*Iterator)

FreeWrappedHex(*MsgPack)


; Examination errors
*MsgPack = WrapHex("01")
AssertIsTrue(Bool(MsgPackExamine(*MsgPack) = #Null), "Cannot examine a fixint")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_InvalidFormatCode, "Examination error is set")
FreeWrappedHex(*MsgPack)

*MsgPack = WrapHex("920191")
AssertIsTrue(Bool(MsgPackExamine(*MsgPack) = #Null), "Cannot examine a truncated array")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_BufferTooSmall, "Truncated array error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed examination")
FreeWrappedHex(*MsgPack)


; Unsafe examination: {"a": [1], "b": 2} followed by `5`
*MsgPack = WrapHex("82A1619101A1620205")

*Iterator = MsgPackExamine(*MsgPack, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*Iterator <> #Null), "Examined the map unsafely")
AssertEquals(*MsgPack\BufferOffset, 0, "Unsafe examination doesn't move the offset")
AssertEquals(*Iterator\BufferSize, 8, "Unsafe view goes up to the end of the buffer")

EntryCount = 0
While MsgPackNextEntry(*Iterator)
	EntryCount = EntryCount + 1
	If EntryCount = 2
		AssertIsTrue(Bool(MsgPackReadString(*Iterator) = "b"), "Unsafe map key #2")
		AssertEqualsQ(MsgPackReadInteger(*Iterator), 2, "Unsafe map value #2")
	EndIf
Wend

AssertEquals(EntryCount, 2, "Unsafe map has 2 entries")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_Success, "Unsafe map ended without errors")
AssertEquals(*Iterator\BufferSize, 7, "Unsafe view is limited once its end is reached")
AssertEqualsQ(MsgPackReadInteger(*Iterator), 0, "Cannot read past the unsafe map's end")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_AtOrPastTheEndOfBuffer, "Unsafe map's end error is set")
MsgPackFinish(*Iterator)

AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_Success, "Skipped the unsafely examined map")
AssertEqualsQ(MsgPackReadInteger(*MsgPack), 5, "Read the field following the unsafe map")
FreeWrappedHex(*MsgPack)

; Invalid content is only detected while iterating
*MsgPack = WrapHex("9201C1")

*Iterator = MsgPackExamine(*MsgPack, #MsgPack_ExaminationOptions_Unsafe)
AssertIsTrue(Bool(*Iterator <> #Null), "Examined the invalid array unsafely")
AssertIsTrue(MsgPackNextEntry(*Iterator), "Invalid array entry #1")
AssertIsTrue(MsgPackNextEntry(*Iterator), "Invalid array entry #2 is reached")
AssertIsFalse(MsgPackNextEntry(*Iterator), "Cannot skip the invalid entry #2")
AssertEquals(MsgPackLastError(*Iterator), #MsgPack_Error_InvalidFormatCode, "Invalid entry error is set")
MsgPackFinish(*Iterator)
FreeWrappedHex(*MsgPack)



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
