; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write and read extensions, which are binary
;  data tagged with an application-defined type, here a 2D vector.
; Types from 0 to 127 are free to use, -128 to -1 are reserved by the spec.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

#ExtType_Vector2 = 1

Structure Vector2
    X.f
    Y.f
EndStructure

; Obscure structures that hold info about the MsgPack data
Define *Writer, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; Structure that will hold the data to encode and the decoded one.
Define InputVector.Vector2, OutputVector.Vector2
Define ExtType.b



; Preparing the input structure.
With InputVector
    \X = 1.5
    \Y = -2.25
EndWith


; Writing the vector into the buffer.
; It is 8 bytes long, so it is written as a FixExt8.
*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 1
EndIf

If MsgPackWriteExtension(*Writer, #ExtType_Vector2, @InputVector, SizeOf(Vector2)) <> #MsgPack_Error_Success
    Debug "Failed to write the extension !"
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


; Checking the type first, it doesn't move the offset.
ExtType = MsgPackGetExtensionType(*Reader)
If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
    Debug "Failed to get the extension type !"
    End 5
EndIf

If ExtType <> #ExtType_Vector2
    Debug "Unexpected extension type: " + Str(ExtType)
    End 6
EndIf


; Copying its data into the output structure.
If MsgPackReadExtension(*Reader, @OutputVector, SizeOf(Vector2)) <> SizeOf(Vector2)
    Debug "Failed to read the extension !"
    End 7
EndIf

Debug "X: " + StrF(OutputVector\X)
Debug "Y: " + StrF(OutputVector\Y)


; Freeing the obscure structure and the buffer it owns.
MsgPackFree(*Reader, #True)

End 0
