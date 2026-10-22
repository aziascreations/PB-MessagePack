
EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Setup
Define *BufferHolder.MsgPackData = MsgPackCreate(1)
Define LastMeasuredSize.q = MemorySize(*BufferHolder\Buffer)


; Checking defaults, should be able to grow
AssertIsFalse(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_CannotGrow)), "The `#MsgPack_DataFlags_CannotGrow` flag isn't set by default.")


; Testing null
AssertEquals(MsgPackGrow(#Null, 64), #MsgPack_Error_NullPointerGiven, "Passing #Null is rejected properly")


; Testing negative growth
AssertEquals(MsgPackGrow(*BufferHolder, -1), #MsgPack_Error_InvalidValue, "Negative growth is blocked.")
AssertEquals(*BufferHolder\LastError, #MsgPack_Error_InvalidValue, "Negative growth's error is set in structure.")


; Testing blocked growth
*BufferHolder\DataFlags = *BufferHolder\DataFlags | #MsgPack_DataFlags_CannotGrow
AssertIsTrue(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_CannotGrow)), "The `#MsgPack_DataFlags_CannotGrow` flag is now set.")

AssertEquals(MsgPackGrow(*BufferHolder, 64), #MsgPack_Error_CannotGrowBufferDueToConfig, "Testing disabled growth.")
AssertEquals(*BufferHolder\LastError, #MsgPack_Error_CannotGrowBufferDueToConfig, "Blocked growth's error is set in structure.")

AssertEquals(*BufferHolder\BufferSize, LastMeasuredSize, "Buffer's length is untouched. (1)")
AssertEquals(MemorySize(*BufferHolder\Buffer), LastMeasuredSize, "Buffer's length is untouched. (2)")


If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
