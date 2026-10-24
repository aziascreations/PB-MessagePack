EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Default growth increment is 1, no rounding
Define *BufferHolder.MsgPackData = MsgPackCreate(16)

AssertEquals(*BufferHolder\BufferGrowthIncrement, 1, "Default growth increment is 1.")
AssertEquals(MsgPackGrow(*BufferHolder, 3), #MsgPack_Error_Success, "Growing 16 by 3 with the default increment.")
AssertEquals(*BufferHolder\BufferSize, 19, "Size is exactly 19.")

MsgPackFree(*BufferHolder, #True)


; Rounding up to the next multiple of the growth increment
*BufferHolder = MsgPackCreate(16, 16)

AssertEquals(MsgPackGrow(*BufferHolder, 2), #MsgPack_Error_Success, "Growing 16 by 2 with an increment of 16.")
AssertEquals(*BufferHolder\BufferSize, 32, "Size was rounded up to 32. (1)")
AssertEquals(MemorySize(*BufferHolder\Buffer), 32, "Size was rounded up to 32. (2)")

AssertEquals(MsgPackGrow(*BufferHolder, 17), #MsgPack_Error_Success, "Growing 32 by 17 with an increment of 16.")
AssertEquals(*BufferHolder\BufferSize, 64, "Size was rounded up to 64.")

AssertEquals(MsgPackGrow(*BufferHolder, 16), #MsgPack_Error_Success, "Growing 64 by an exact multiple.")
AssertEquals(*BufferHolder\BufferSize, 80, "Size is exactly 80.")

*BufferHolder\BufferGrowthIncrement = 1
AssertEquals(MsgPackGrow(*BufferHolder, 3), #MsgPack_Error_Success, "Growing 80 by 3 without increment.")
AssertEquals(*BufferHolder\BufferSize, 83, "Size is exactly 83.")

MsgPackFree(*BufferHolder, #True)


; Writers only grow by the missing amount
*BufferHolder = MsgPackCreate(4)
*BufferHolder\BufferOffset = 3

AssertEquals(MsgPackWriteUInt16(*BufferHolder, $1234), #MsgPack_Error_Success, "Writing 3 bytes at offset 3 of a 4 bytes buffer.")
AssertEquals(*BufferHolder\BufferSize, 6, "Buffer grew by the 2 missing bytes only.")
AssertEquals(*BufferHolder\BufferOffset, 6, "Offset is now at the end.")

MsgPackFree(*BufferHolder, #True)


; Wrapped buffer that stays owned by the caller
Define *RawBuffer = AllocateMemory(2)
*BufferHolder = MsgPackWrapMsgBuffer(*RawBuffer, 2)

AssertIsTrue(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_CannotGrow)), "Non-owned wrap cannot grow.")
AssertIsTrue(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_NoBufferFree)), "Non-owned wrap cannot be freed.")
AssertEquals(MsgPackWriteUInt16(*BufferHolder, $1234), #MsgPack_Error_CannotGrowBufferDueToConfig, "Writing past a non-owned wrap is refused.")
AssertEquals(*BufferHolder\Buffer, *RawBuffer, "Buffer pointer is untouched.")
AssertEquals(*BufferHolder\BufferSize, 2, "Buffer size is untouched.")

AssertIsTrue(MsgPackFree(*BufferHolder, #False), "Non-owned wrap is freed without its buffer.")
FreeMemory(*RawBuffer)


; Wrapped buffer whose ownership is given
*RawBuffer = AllocateMemory(2)
*BufferHolder = MsgPackWrapMsgBuffer(*RawBuffer, 2, #True)

AssertIsFalse(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_CannotGrow)), "Owned wrap can grow.")
AssertIsFalse(Bool(_MsgPackHasFlag(*BufferHolder, #MsgPack_DataFlags_NoBufferFree)), "Owned wrap can be freed.")
AssertEquals(MsgPackWriteUInt16(*BufferHolder, $1234), #MsgPack_Error_Success, "Writing past an owned wrap grows it.")
AssertEquals(*BufferHolder\BufferSize, 3, "Buffer grew by the missing byte.")

AssertIsTrue(MsgPackFree(*BufferHolder, #True), "Owned wrap is freed with its buffer.")


If FailedUnitTests
	End 1
EndIf

Debug "Done !"

End 0
