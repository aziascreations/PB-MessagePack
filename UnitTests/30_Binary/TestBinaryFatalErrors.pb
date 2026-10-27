EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; /!\ Every case here calls `DebuggerError()`, which halts the program under the debugger.
;     Run it without the debugger and check the exit code.


; Setup
Define *MsgPack.MsgPackData
Define *Source = AllocatePattern(16)
Define *Output = AllocateMemory(16)


; Null MsgPack pointers
AssertEquals(MsgPackWriteBin8(#Null, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteBin8 is given #Null")
AssertEquals(MsgPackWriteBin16(#Null, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteBin16 is given #Null")
AssertEquals(MsgPackWriteBin32(#Null, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteBin32 is given #Null")
AssertEquals(MsgPackWriteBinary(#Null, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteBinary is given #Null")
AssertEqualsQ(MsgPackReadBinary(#Null, *Output, 16), #MsgPack_InvalidSize, "MsgPackReadBinary is given #Null")
AssertEquals(MsgPackCopyBinary(#Null), #Null, "MsgPackCopyBinary is given #Null")


; Null output buffer with data to copy
*MsgPack = WrapHex("C4020102")

AssertEqualsQ(MsgPackReadBinary(*MsgPack, #Null, 2), #MsgPack_InvalidSize, "Reading into a #Null buffer fails")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_NullPointerGiven, "Null output buffer error is set")
AssertEquals(*MsgPack\BufferOffset, 0, "Offset is untouched by the failed read")

FreeWrappedHex(*MsgPack)


; Ending
FreeMemory(*Source)
FreeMemory(*Output)

If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
