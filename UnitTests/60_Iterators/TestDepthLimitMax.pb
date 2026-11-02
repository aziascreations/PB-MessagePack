EnableExplicit

; Biggest supported value, deep nesting must still be handled iteratively.
#MsgPack_MaxDepth = 4096

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_TestBuffers.pbi"


; Setup
Define *MsgPack.MsgPackData
Define *Buffer
Define i.i
Define Depth.i
Define *View.MsgPackData
Dim Views.i(4096)


Procedure.i WrapNested(Depth.i, Size.i)
	Protected *Buffer = AllocateMemory(Size)
	FillMemory(*Buffer, Depth, $91)
	FillMemory(*Buffer + Depth, Size - Depth, $C0)
	ProcedureReturn MsgPackWrapMsgBuffer(*Buffer, Size)
EndProcedure


; At the limit
*MsgPack = WrapNested(4096, 4097)
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), 4097, "Arrays nested 4096 levels deep")
AssertEquals(MsgPackSkip(*MsgPack), #MsgPack_Error_Success, "Skipped arrays nested 4096 levels deep")

; Every level examined, with checked views
*MsgPack\BufferOffset = 0
Views(0) = *MsgPack
For i = 1 To 4096
	Views(i) = MsgPackExamine(Views(i - 1))
	If Not Views(i)
		Break
	EndIf
	If Not MsgPackNextEntry(Views(i))
		MsgPackFinish(Views(i))
		Break
	EndIf
Next
Depth = i - 1
AssertEquals(Depth, 4096, "Examined every level")
If Depth = 4096
	AssertEquals(MsgPackReadNull(Views(4096)), #MsgPack_Error_Success, "Read the value at depth 4096")
EndIf
For i = Depth To 1 Step -1
	*View = Views(i)
	MsgPackFinish(*View)
Next
FreeWrappedHex(*MsgPack)

; Past the limit
*MsgPack = WrapNested(4097, 4098)
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Arrays nested 4097 levels deep")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_MaxDepthExceeded, "Max depth error is set")
FreeWrappedHex(*MsgPack)

; Far past it, rejected without walking the rest
*MsgPack = WrapNested(1000000, 1000001)
AssertEqualsQ(MsgPackGetFieldFullSize(*MsgPack), #MsgPack_InvalidSize, "Arrays nested 1M levels deep")
AssertEquals(MsgPackLastError(*MsgPack), #MsgPack_Error_MaxDepthExceeded, "Max depth error is set for 1M levels")
FreeWrappedHex(*MsgPack)



If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
