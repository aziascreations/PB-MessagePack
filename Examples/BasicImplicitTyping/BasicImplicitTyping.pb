; ------------------------------------------------------------------------------
;- Notes

; This example show you how to write, export and read a MessagePack buffer
;  with implicitely typed variables whose format code is automatically
;  resolved based on the given data.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

Structure MyDataPacket
    Id.q
    UserName.s
EndStructure

Procedure.b EncodeMyDataPacket(*MsgPackData, *Input.MyDataPacket)
    If MsgPackWriteInteger(*MsgPackData, *Input\Id) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
    If MsgPackWriteString(*MsgPackData, *Input\UserName) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
    ProcedureReturn #True
EndProcedure

Procedure.b DecodeMyDataPacket(*MsgPackData, *Output.MyDataPacket)
    *Output\Id = MsgPackReadInteger(*MsgPackData)
    If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf
    
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
; Leaving out the `GrowthIncrement` parameter causes reallocations of the required size on every write.
; Setting it to any value higher than 1 would force the library to allocate memory in blocks of X bytes.
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
; It also resizes the final buffer to the appropriate size.
*Buffer = MsgPackFinalize(*Writer)
If Not *Buffer
    Debug "Failed to finalize the writer !"
    End 3
EndIf

Debug "Encoded size: " + Str(MemorySize(*Buffer))


; It also gives ownership of the buffer to the obscure structure.
; And it is marked internally as read-only.
*Reader = MsgPackWrapMsgBuffer(*Buffer, MemorySize(*Buffer), #True)
If Not *Reader
    Debug "Failed to wrap the buffer !"
    End 4
EndIf


; Getting data out of the MsgPack buffer.
OutputStruct.MyDataPacket
If Not DecodeMyDataPacket(*Reader, @OutputStruct)
    Debug "Failed to decode the packet !"
    End 5
EndIf

Debug "Id: " + Str(OutputStruct\Id)
Debug "UserName: " + OutputStruct\UserName


; Freeing the obscure structure.
; Since it owns the buffer, it will also free it.
MsgPackFree(*Reader, #True)

End 0
