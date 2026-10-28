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
AssertEquals(MsgPackWriteExt8(#Null, 1, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteExt8 is given #Null")
AssertEquals(MsgPackWriteExt16(#Null, 1, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteExt16 is given #Null")
AssertEquals(MsgPackWriteExt32(#Null, 1, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteExt32 is given #Null")
AssertEquals(MsgPackWriteExtension(#Null, 1, *Source, 1), #MsgPack_Error_NullPointerGiven, "MsgPackWriteExtension is given #Null for a fixext")
AssertEquals(MsgPackWriteExtension(#Null, 1, *Source, 3), #MsgPack_Error_NullPointerGiven, "MsgPackWriteExtension is given #Null for an ext8")
AssertEquals(MsgPackWriteFixExt1(#Null, 1, *Source), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFixExt1 is given #Null")
AssertEquals(MsgPackWriteFixExt16(#Null, 1, *Source), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFixExt16 is given #Null")
AssertEqualsQ(MsgPackReadExtension(#Null, *Output, 16), #MsgPack_InvalidSize, "MsgPackReadExtension is given #Null")
AssertEquals(MsgPackCopyExtension(#Null), #Null, "MsgPackCopyExtension is given #Null")
AssertEqualsB(MsgPackGetExtensionType(#Null), 0, "MsgPackGetExtensionType is given #Null")


; Null output buffer with data to copy
*MsgPack = WrapHex("D5010102")

AssertEqualsQ(MsgPackReadExtension(*MsgPack, #Null, 2), #MsgPack_InvalidSize, "Reading into a #Null buffer fails")
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
