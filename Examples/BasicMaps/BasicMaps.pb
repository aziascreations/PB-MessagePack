; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write a structure as a map whose keys are
;  its fields' names, and how to read it back by iterating on it.
; Unknown keys are skipped, and the keys' order doesn't matter.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

Structure MyDataPacket
    Id.q
    UserName.s
    IsAdmin.b
EndStructure

; Writes the keys and values one after the other, alternating them.
Procedure.b EncodeMyDataPacketFields(*MsgPackData, *Input.MyDataPacket)
    If MsgPackWriteString(*MsgPackData, "Id") <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    If MsgPackWriteInteger(*MsgPackData, *Input\Id) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
    If MsgPackWriteString(*MsgPackData, "UserName") <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    If MsgPackWriteString(*MsgPackData, *Input\UserName) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
    If MsgPackWriteString(*MsgPackData, "IsAdmin") <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    If MsgPackWriteBoolean(*MsgPackData, *Input\IsAdmin) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
EndProcedure

Procedure.b EncodeMyDataPacket(*MsgPackData, *Input.MyDataPacket)
    Protected *Fields
    Protected Success.b = #False
    
    ; Writing the keys and values in their own writer.
    *Fields = MsgPackCreate(64)
    If Not *Fields
        ProcedureReturn #False
    EndIf
    
    ; Writing the map, the fields are counted and copied into it.
    If EncodeMyDataPacketFields(*Fields, *Input)
        Success = Bool(MsgPackWriteMapFrom(*MsgPackData, *Fields) = #MsgPack_Error_Success)
    EndIf
    
    ; The fields writer is left untouched, so it must be freed.
    MsgPackFree(*Fields, #True)
    
    ProcedureReturn Success
EndProcedure

Procedure.b DecodeMyDataPacket(*MsgPackData, *Output.MyDataPacket)
    Protected *Iterator
    Protected Key.s

    *Iterator = MsgPackExamine(*MsgPackData)
    If Not *Iterator
        ProcedureReturn #False
    EndIf

    ; Each entry is read key first, then value.
    While MsgPackNextEntry(*Iterator)
        Key = MsgPackReadString(*Iterator)

        Select Key
            Case "Id"
                *Output\Id = MsgPackReadInteger(*Iterator)
            Case "UserName"
                *Output\UserName = MsgPackReadString(*Iterator)
            Case "IsAdmin"
                *Output\IsAdmin = MsgPackReadBoolean(*Iterator)
        EndSelect

        If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
            Break
        EndIf
    Wend

    ; `MsgPackNextEntry` also returns `#False` on errors.
    If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
        MsgPackFinish(*Iterator)
        ProcedureReturn #False
    EndIf

    MsgPackFinish(*Iterator)
    ProcedureReturn #True
EndProcedure



; Obscure structures that hold info about the MsgPack data
Define *Writer, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; Structure that will hold the data to encode and the decoded one.
Define InputStruct.MyDataPacket, OutputStruct.MyDataPacket



; Preparing the input structure.
With InputStruct
    \Id = 67
    \UserName = "Herwin"
    \IsAdmin = #True
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


; Exporting the data and giving it to a reader.
*Buffer = MsgPackFinalize(*Writer)
If Not *Buffer
    Debug "Failed to finalize the writer !"
    End 3
EndIf

Debug "Encoded size: " + Str(MemorySize(*Buffer))

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
Debug "IsAdmin: " + Str(OutputStruct\IsAdmin)


; Freeing the obscure structure and the buffer it owns.
MsgPackFree(*Reader, #True)

End 0
