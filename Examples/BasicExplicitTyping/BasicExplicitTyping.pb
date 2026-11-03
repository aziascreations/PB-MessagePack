; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write, export and read a MessagePack buffer
;  with explicitly typed variables whose format code is forced by the
;  procedure used to write them, even if a smaller one would fit.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

Structure MyDataPacket
    Id.q
    UserName.s
EndStructure

Procedure.b EncodeMyDataPacket(*MsgPackData, *Input.MyDataPacket)
    ; Always written as an Int64, 9 bytes in total.
    If MsgPackWriteInt64(*MsgPackData, *Input\Id) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf

    ; Always written as a Str8, which only fits up to 255 bytes.
    If MsgPackWriteStr8(*MsgPackData, *Input\UserName) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf

    ProcedureReturn #True
EndProcedure

Procedure.b DecodeMyDataPacket(*MsgPackData, *Output.MyDataPacket)
    ; Fails if the field isn't an Int64.
    *Output\Id = MsgPackReadInt64(*MsgPackData)
    If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf

    ; Strings don't have explicit getters, any str format code is accepted.
    *Output\UserName = MsgPackReadString(*MsgPackData)
    If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf

    ProcedureReturn #True
EndProcedure



; Obscure structures that hold info about the MsgPack data
Define *Writer, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; Structure that will hold the data to encode and the decoded one.
; You could replace this with whatever you want in your use cases.
Define InputStruct.MyDataPacket, OutputStruct.MyDataPacket



; Preparing the input structure.
With InputStruct
    \Id = 67
    \UserName = "Herwin"
EndWith


; Writing the data into the buffer.
*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 1
EndIf

If Not EncodeMyDataPacket(*Writer, @InputStruct)
    Debug "Failed to encode the packet !"
    End 2
EndIf


; Exporting the data.
; Doing this frees the obscure structure in `*Writer`.
*Buffer = MsgPackFinalize(*Writer)
If Not *Buffer
    Debug "Failed to finalize the writer !"
    End 3
EndIf

; 9 bytes for the Int64, 2+6 bytes for the Str8.
Debug "Encoded size: " + Str(MemorySize(*Buffer))


; Giving ownership of the buffer to the obscure structure.
*Reader = MsgPackWrapMsgBuffer(*Buffer, MemorySize(*Buffer), #True)
If Not *Reader
    Debug "Failed to wrap the buffer !"
    End 4
EndIf


; Getting data out of the MsgPack buffer.
If Not DecodeMyDataPacket(*Reader, @OutputStruct)
    Debug "Failed to decode the packet !"
    End 5
EndIf

Debug "Id: " + Str(OutputStruct\Id)
Debug "UserName: " + OutputStruct\UserName

; Freeing the obscure structure and the buffer it owns.
MsgPackFree(*Reader, #True)


; Forcing a format code that is too small for the data fails.
; Str8 only fits up to 255 bytes, so a 256 bytes name can't be written.
InputStruct\UserName = LSet("", 256, "A")

*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 6
EndIf

If EncodeMyDataPacket(*Writer, @InputStruct)
    Debug "Encoded a 256 bytes name as Str8, this shouldn't happen !"
    End 7
EndIf

Debug "Failed to encode a 256 bytes name as Str8, as expected."

; Nothing was exported, so the writer still owns its buffer.
MsgPackFree(*Writer, #True)

End 0
