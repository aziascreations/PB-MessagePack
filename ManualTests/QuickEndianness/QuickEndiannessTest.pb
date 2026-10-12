
EnableExplicit
XIncludeFile "../../Includes/MessagePack.pbi"

Define *MPack.MsgPackData = MsgPackCreate(1)

; Forcing overgrowth
*MPack\BufferGrowthIncrements = 128

MsgPackWriteUInt16(*MPack, $4267)
MsgPackWriteUInt16(*MPack, EndianSwapU($4267))

DeleteFile("./test.mpack")

CreateFile(0, "./test.mpack")

Define *Buffer = MsgPackFinalize(*MPack)
WriteData(0, *Buffer, 6)

CloseFile(0)
