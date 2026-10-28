EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; /!\ Every case here calls `DebuggerError()`, which halts the program under the debugger.
;     Run it without the debugger and check the exit code.


; Null MsgPack pointers
AssertEquals(MsgPackWriteInteger(#Null, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteInteger is given #Null for a fixint")
AssertEquals(MsgPackWriteInteger(#Null, 100000), #MsgPack_Error_NullPointerGiven, "MsgPackWriteInteger is given #Null for a UInt32")
AssertEquals(MsgPackWriteInteger(#Null, -100), #MsgPack_Error_NullPointerGiven, "MsgPackWriteInteger is given #Null for an Int8")
AssertEquals(MsgPackWriteFixInt(#Null, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFixInt is given #Null")
AssertEquals(MsgPackWriteFixInt(#Null, 1000), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFixInt is given #Null before the range check")
AssertEquals(MsgPackWriteUInt8(#Null, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteUInt8 is given #Null")
AssertEquals(MsgPackWriteInt64(#Null, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteInt64 is given #Null")
AssertEqualsQ(MsgPackReadInteger(#Null), 0, "MsgPackReadInteger is given #Null")
AssertEqualsA(MsgPackReadUInt8(#Null), 0, "MsgPackReadUInt8 is given #Null")
AssertEqualsQ(MsgPackReadInt64(#Null), 0, "MsgPackReadInt64 is given #Null")

; The generic float reader shares the integer one's checks.
Assert(Bool(MsgPackReadFloat(#Null) = 0), "MsgPackReadFloat is given #Null")


; Ending
If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
