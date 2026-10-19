EnableExplicit

XIncludeFile "../_UnitTesting.pbi"
XIncludeFile "../../Includes/MessagePack.pbi"


; Note: The checks were done on the table in the spec.
;       I didn't go with my own constants to avoid missing a discrepency.


Define *MyBuffer
Define *MsgPack.MsgPackData


; Null
*MyBuffer = AllocateMemory(2)

PokeA(*MyBuffer + 0, $C0) ; Null
PokeA(*MyBuffer + 1, $C1) ; Invalid

*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))

AssertEqualsA(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_Null, "[Null] First format code is null")

; FIXME: Implement a way to move forward for those !!!
;AssertEqualsA(MsgPackGetFormatCode(*MsgPack), , "Second is invalid, we moved to the 2nd byte")

MsgPackFree(*MsgPack, #False)
FreeMemory(*MyBuffer)



; False
*MyBuffer = AllocateMemory(2)

PokeA(*MyBuffer + 0, $C2) ; False
PokeA(*MyBuffer + 1, $C1) ; Invalid

*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))

AssertEqualsA(*MsgPack\BufferOffset, 0, "[False] Offset is 0")
AssertEqualsA(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_False, "[False] First format code is false")
AssertEqualsA(MsgPackReadBoolean(*MsgPack), #False, "[False] Boolean literal getter returns #False")
AssertEqualsA(*MsgPack\BufferOffset, 0, "[False] Offset is still 0, we'll change the flag")

*MsgPack\DataFlags = *MsgPack\DataFlags | #MsgPack_DataFlags_MoveOffsetAfterRead
AssertEqualsA(MsgPackReadBoolean(*MsgPack), #False, "[False] Boolean literal getter returns #False")
AssertEqualsA(*MsgPack\BufferOffset, 1, "[False] Offset is 1 after setting flag and reading")

AssertEqualsA(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_Invalid, "[False] Second format code is invalid as expected")

MsgPackFree(*MsgPack, #False)
FreeMemory(*MyBuffer)



; True
*MyBuffer = AllocateMemory(2)

PokeA(*MyBuffer + 0, $C3) ; True
PokeA(*MyBuffer + 1, $C1) ; Invalid

*MsgPack = MsgPackWrapMsgBuffer(*MyBuffer, MemorySize(*MyBuffer))

AssertEqualsA(*MsgPack\BufferOffset, 0, "[True] Offset is 0")
AssertEqualsA(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_True, "[True] First format code is false")
AssertEqualsA(MsgPackReadBoolean(*MsgPack), #True, "[True] Boolean literal getter returns #True")
AssertEqualsA(*MsgPack\BufferOffset, 0, "[True] Offset is still 0, we'll change the flag")

*MsgPack\DataFlags = *MsgPack\DataFlags | #MsgPack_DataFlags_MoveOffsetAfterRead
AssertEqualsA(MsgPackReadBoolean(*MsgPack), #True, "[True] Boolean literal getter returns #True")
AssertEqualsA(*MsgPack\BufferOffset, 1, "[True] Offset is 1 after setting flag and reading")

AssertEqualsA(MsgPackGetFormatCode(*MsgPack), #MsgPack_FormatCode_Invalid, "[True] Second format code is invalid as expected")

MsgPackFree(*MsgPack, #False)
FreeMemory(*MyBuffer)

