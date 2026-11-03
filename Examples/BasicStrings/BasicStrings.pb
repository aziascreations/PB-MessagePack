; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write and read strings in the supported
;  encodings, UTF-8 being the default one and the one used by the spec.
; The string must be read with the encoding it was written with.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

; Obscure structures that hold info about the MsgPack data
Define *Writer, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; "Cafe" with an accented "e", 4 characters but 5 bytes in UTF-8.
Define Text.s = "Caf" + Chr($E9)



; Writing the strings into the buffer.
*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 1
EndIf

; UTF-8 by default.
If MsgPackWriteString(*Writer, Text) <> #MsgPack_Error_Success
    Debug "Failed to write the UTF-8 string !"
    End 2
EndIf

; UTF-16 LE, 2 bytes per character here.
If MsgPackWriteString(*Writer, Text, #PB_Unicode) <> #MsgPack_Error_Success
    Debug "Failed to write the UTF-16 string !"
    End 3
EndIf

; Empty strings are valid too.
If MsgPackWriteString(*Writer, "") <> #MsgPack_Error_Success
    Debug "Failed to write the empty string !"
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


; Reading the strings back, in the same order and encodings.
Debug "UTF-8: " + MsgPackReadString(*Reader)
If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
    Debug "Failed to read the UTF-8 string !"
    End 7
EndIf

Debug "UTF-16: " + MsgPackReadString(*Reader, #PB_Unicode)
If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
    Debug "Failed to read the UTF-16 string !"
    End 8
EndIf

Debug "Empty: '" + MsgPackReadString(*Reader) + "'"
If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
    Debug "Failed to read the empty string !"
    End 9
EndIf


; Freeing the obscure structure and the buffer it owns.
MsgPackFree(*Reader, #True)

End 0
