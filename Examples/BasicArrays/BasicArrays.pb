; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to write an array from entries written in a
;  separate writer, and how to iterate on it.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"

; Obscure structures that hold info about the MsgPack data
Define *Writer, *Entries, *Reader, *Iterator

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

Define i.i, Value.q



; Writing the entries in their own writer.
*Entries = MsgPackCreate(64)
If Not *Entries
    Debug "Failed to create the entries writer !"
    End 1
EndIf

For i = 1 To 5
    If MsgPackWriteInteger(*Entries, i * 10) <> #MsgPack_Error_Success
        Debug "Failed to write entry #" + Str(i) + " !"
        End 2
    EndIf
Next


; Writing the array, the entries are counted and copied into it.
*Writer = MsgPackCreate(64)
If Not *Writer
    Debug "Failed to create the writer !"
    End 3
EndIf

If MsgPackWriteArrayFrom(*Writer, *Entries) <> #MsgPack_Error_Success
    Debug "Failed to write the array !"
    End 4
EndIf

; The entries writer is left untouched, so it must be freed.
MsgPackFree(*Entries, #True)


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


; Iterating on the array.
Debug "Entry count: " + Str(MsgPackGetEntryCount(*Reader))

*Iterator = MsgPackExamine(*Reader)
If Not *Iterator
    Debug "Failed to examine the array !"
    End 7
EndIf

While MsgPackNextEntry(*Iterator)
    Value = MsgPackReadInteger(*Iterator)
    If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
        Debug "Failed to read an entry !"
        End 8
    EndIf

    Debug "Entry: " + Str(Value)
Wend

; `MsgPackNextEntry` also returns `#False` on errors.
If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
    Debug "Failed to iterate on the array !"
    End 9
EndIf


; Freeing the view first, it reads from the reader's buffer.
MsgPackFinish(*Iterator)
MsgPackFree(*Reader, #True)

End 0
