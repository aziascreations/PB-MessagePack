EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Note: The checks were done on the table in the spec.
;       I didn't go with my own constants to avoid missing a discrepency.


Define *MyBuffer
Define *MsgPack.MsgPackData


; Null MsgPack pointers

; FIXME: It returns #False, should this be normalized ?
;AssertEquals(MsgPackReadBoolean(#Null), #MsgPack_Error_NullPointerGiven, "MsgPackReadBoolean is given #Null")ssertEquals(MsgPackReadBoolean(#Null), #MsgPack_Error_NullPointerGiven, "MsgPackReadBoolean is given #Null")

AssertEquals(MsgPackWriteNull(#Null), #MsgPack_Error_NullPointerGiven, "MsgPackWriteNull is given #Null")
AssertEquals(MsgPackWriteFalse(#Null), #MsgPack_Error_NullPointerGiven, "MsgPackWriteFalse is given #Null")
AssertEquals(MsgPackWriteTrue(#Null), #MsgPack_Error_NullPointerGiven, "MsgPackWriteTrue is given #Null")


; Buffer at end
*MyBuffer = AllocateMemory(8)
FillMemory(*MyBuffer, MemorySize(*MyBuffer), #MsgPack_FormatCode_True, #PB_Ascii) ; Filling with `#True`
*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))
*MsgPack\BufferOffset = MemorySize(*MsgPack\Buffer)

AssertIsFalse(MsgPackReadBoolean(*MsgPack), "Reading at the end returns #False")

; FIXME: Implement the non-growth flag.
;AssertEquals(MsgPackWriteNull(*MsgPack), #MsgPack_Error_NullPointerGiven, "MsgPackWriteNull is given #Null")
;AssertEquals(MsgPackWriteFalse(*MsgPack), #MsgPack_Error_NullPointerGiven, "MsgPackWriteNull is given #Null")
;AssertEquals(MsgPackWriteTrue(*MsgPack), #MsgPack_Error_NullPointerGiven, "MsgPackWriteNull is given #Null")

MsgPackFree(*MsgPack, #False)
FreeMemory(*MyBuffer)


; Offset out-of-bounds


;; Setup
;*MyBuffer = AllocateMemory(8)
;FillMemory(*MyBuffer, MemorySize(*MyBuffer), $C1, #PB_Ascii)
;*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))
;
;
;; Writing in place
;*MsgPack\DataFlags = *MsgPack\DataFlags & (~#MsgPack_DataFlags_MoveOffsetAfterWrite)
;AssertIsFalse(Bool(_MsgPackHasFlag(*MsgPack, #MsgPack_DataFlags_MoveOffsetAfterWrite)), "Move after flag is unset")
;
;AssertEquals(MsgPackWriteNull(*MsgPack), #MsgPack_Error_Success, "Wrote null using helper")
;AssertEqualsA(PeekA(*MsgPack\Buffer), #MsgPack_FormatCode_Null, "Format code is changed and correct")
;AssertEqualsA(*MsgPack\BufferOffset, 0, "Offset was left at 0")
;
;
;; Ending
;MsgPackFree(*MsgPack, #False)
;FreeMemory(*MyBuffer)
