; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write and read raw binary data.
; It can either be copied into a buffer you own, or into a new one.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

; Obscure structures that hold info about the MsgPack data
Define *Writer, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; Raw data to encode, and buffers that will receive the decoded one.
Define *Input = AllocateMemory(4)
Define *Output = AllocateMemory(16)
Define *Copy
Define BytesRead.q

If Not *Input Or Not *Output
    Debug "Failed to allocate the buffers !"
    End 1
EndIf

PokeL(*Input, $DEADBEEF)



; Writing the same data twice into the buffer.
*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 2
EndIf

If MsgPackWriteBinary(*Writer, *Input, MemorySize(*Input)) <> #MsgPack_Error_Success
    Debug "Failed to write the first binary field !"
    End 3
EndIf

If MsgPackWriteBinary(*Writer, *Input, MemorySize(*Input)) <> #MsgPack_Error_Success
    Debug "Failed to write the second binary field !"
    End 4
EndIf


; Exporting the data and giving it to a reader.
*Buffer = MsgPackFinalize(*Writer)
If Not *Buffer
    Debug "Failed to finalize the writer !"
    End 5
EndIf

Debug "Encoded size: " + Str(MemorySize(*Buffer))

*Reader = MsgPackWrapMsgBuffer(*Buffer, MemorySize(*Buffer), #True)
If Not *Reader
    Debug "Failed to wrap the buffer !"
    End 6
EndIf


; Copying the first field into a buffer we own.
; It fails if the buffer is too small, without moving the offset.
BytesRead = MsgPackReadBinary(*Reader, *Output, MemorySize(*Output))
If BytesRead = #MsgPack_InvalidSize
    Debug "Failed to read the first binary field !"
    End 7
EndIf

Debug "Read " + Str(BytesRead) + " bytes: $" + Hex(PeekL(*Output), #PB_Long)


; Copying the second field into a new buffer of the right size.
*Copy = MsgPackCopyBinary(*Reader)
If Not *Copy
    Debug "Failed to copy the second binary field !"
    End 8
EndIf

Debug "Copied " + Str(MemorySize(*Copy)) + " bytes: $" + Hex(PeekL(*Copy), #PB_Long)


; Freeing everything.
FreeMemory(*Copy)
FreeMemory(*Output)
FreeMemory(*Input)
MsgPackFree(*Reader, #True)

End 0
