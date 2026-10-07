

EnableExplicit
XIncludeFile "./Includes/MessagePack.pbi"


Define *Buffer = MsgPackCreateMsgBuffer(16)
MsgPackWriteI8(*Buffer, 42)
MsgPackWriteI8(*Buffer, 7)
MsgPackFreeMsgBuffer(*Buffer, #True)

; Wrapping an existing buffer for reading
Define *RawData = AllocateMemory(4)
PokeA(*RawData + 0, #MsgPack_FormatCode_UInt8)
PokeA(*RawData + 1, 42)
PokeA(*RawData + 2, #MsgPack_FormatCode_Int8)
PokeB(*RawData + 3, -3)

Define *ReadBuffer = MsgPackWrapMsgBuffer(*RawData, 4)
Debug MsgPackReadU8(*ReadBuffer)
Debug MsgPackReadI8(*ReadBuffer)

MsgPackFreeMsgBuffer(*ReadBuffer, #False) ; #False: *RawData is owned by us
FreeMemory(*RawData)
	