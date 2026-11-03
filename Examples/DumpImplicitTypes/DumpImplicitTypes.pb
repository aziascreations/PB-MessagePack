; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to iterate over a MessagePack buffer and dump
;  every field to the console with its general data type.
; Each field is read with the implicitly typed procedure of its data type,
;  which accepts all of the type's format codes.
; Arrays and maps are dumped recursively, map entries key first.


; ------------------------------------------------------------------------------
;- Example

EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"


; Ends the program if a write failed.
Procedure CheckWrite(ErrorCode.MsgPack_ErrorCode, What.s)
    If ErrorCode <> #MsgPack_Error_Success
        PrintN("Failed to write " + What + " ! (Error " + Str(ErrorCode) + ")")
        End 1
    EndIf
EndProcedure

; Ends the program if a structure or buffer couldn't be prepared.
Procedure CheckPointer(*Pointer, What.s)
    If Not *Pointer
        PrintN("Failed to prepare " + What + " !")
        End 1
    EndIf
EndProcedure


; Returns the bytes of a buffer from `MsgPackCopyBinary/Extension` as hex.
; Empty bin and ext fields give a `#Null` buffer.
Procedure.s HexDump(*Data)
    Protected Text.s = ""
    Protected i.i

    If Not *Data
        ProcedureReturn ""
    EndIf

    For i = 0 To MemorySize(*Data) - 1
        Text = Text + RSet(Hex(PeekA(*Data + i)), 2, "0") + " "
    Next

    ProcedureReturn RTrim(Text)
EndProcedure


; Prints the field at the current offset and moves past it.
; `Label` is printed before it, to tell array indexes and map keys/values apart.
Procedure.b DumpField(*MsgPackData, Indent.s, Label.s)
    Protected DataType.MsgPack_DataType = MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*MsgPackData))
    Protected Text.s
    Protected *Iterator, *Data
    Protected Success.b
    Protected EntryCount.q, Index.q

    Select DataType
        Case #MsgPack_DataTypes_Null
            MsgPackReadNull(*MsgPackData)
            Text = "Null"

        Case #MsgPack_DataTypes_Boolean
            If MsgPackReadBoolean(*MsgPackData)
                Text = "Boolean: True"
            Else
                Text = "Boolean: False"
            EndIf

        Case #MsgPack_DataTypes_Integer
            ; UInt64 values above `(2^63)-1` fail here, see `MsgPackReadUInt64`.
            Text = "Integer: " + Str(MsgPackReadInteger(*MsgPackData))

        Case #MsgPack_DataTypes_Float
            ; Float32 values are returned as a `.d`.
            Text = "Float: " + StrD(MsgPackReadFloat(*MsgPackData))

        Case #MsgPack_DataTypes_String
            Text = "String: " + Chr(34) + MsgPackReadString(*MsgPackData) + Chr(34)

        Case #MsgPack_DataTypes_Binary
            *Data = MsgPackCopyBinary(*MsgPackData)
            Text = "Binary: " + HexDump(*Data)

        Case #MsgPack_DataTypes_Extension
            ; The type doesn't move the offset, the data is read right after.
            Text = "Extension (Type " + Str(MsgPackGetExtensionType(*MsgPackData)) + ")"
            If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
                ProcedureReturn #False
            EndIf
            *Data = MsgPackCopyExtension(*MsgPackData)
            Text = Text + ": " + HexDump(*Data)

        Case #MsgPack_DataTypes_Array, #MsgPack_DataTypes_Map
            EntryCount = MsgPackGetEntryCount(*MsgPackData)
            *Iterator = MsgPackExamine(*MsgPackData)
            If Not *Iterator
                ProcedureReturn #False
            EndIf

            If DataType = #MsgPack_DataTypes_Map
                PrintN(Indent + Label + "Map (" + Str(EntryCount) + " entries)")
            Else
                PrintN(Indent + Label + "Array (" + Str(EntryCount) + " entries)")
            EndIf

            Success = #True
            Index = 0
            While MsgPackNextEntry(*Iterator)
                If DataType = #MsgPack_DataTypes_Map
                    Success = DumpField(*Iterator, Indent + "  ", "Key: ")
                    If Success
                        Success = DumpField(*Iterator, Indent + "  ", "Value: ")
                    EndIf
                Else
                    Success = DumpField(*Iterator, Indent + "  ", "[" + Str(Index) + "] ")
                EndIf

                If Not Success
                    Break
                EndIf
                Index = Index + 1
            Wend

            ; `MsgPackNextEntry` also returns `#False` on errors.
            If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
                Success = #False
            EndIf

            MsgPackFinish(*Iterator)
            ProcedureReturn Success

        Default
            PrintN(Indent + Label + "Unknown data type !")
            ProcedureReturn #False
    EndSelect

    If *Data
        FreeMemory(*Data)
    EndIf

    If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
        ProcedureReturn #False
    EndIf

    PrintN(Indent + Label + Text)
    ProcedureReturn #True
EndProcedure



; Obscure structures that hold info about the MsgPack data
Define *Writer, *Entries, *Fields, *Reader

; MsgPack-encoded buffer that will get exported midway in this example.
Define *Buffer

; Raw data for the bin and ext fields.
Define Bytes.l = $44332211

Define FieldSize.q, BytesLeft.q

OpenConsole()


; Writing a bit of everything, the smallest format code that fits is used.
*Writer = MsgPackCreate(64)
CheckPointer(*Writer, "the writer")

CheckWrite(MsgPackWriteNull(*Writer), "a nil")
CheckWrite(MsgPackWriteBoolean(*Writer, #True), "a boolean")
CheckWrite(MsgPackWriteBoolean(*Writer, #False), "a boolean")
CheckWrite(MsgPackWriteInteger(*Writer, 42), "an integer")
CheckWrite(MsgPackWriteInteger(*Writer, -5), "an integer")
CheckWrite(MsgPackWriteInteger(*Writer, 200), "an integer")
CheckWrite(MsgPackWriteInteger(*Writer, 70000), "an integer")
CheckWrite(MsgPackWriteInteger(*Writer, -1000), "an integer")
; Floats don't have an implicitly typed setter.
CheckWrite(MsgPackWriteFloat64(*Writer, 3.14159), "a float")
CheckWrite(MsgPackWriteString(*Writer, "Hello"), "a string")
CheckWrite(MsgPackWriteBinary(*Writer, @Bytes, 4), "a binary")
CheckWrite(MsgPackWriteExtension(*Writer, 1, @Bytes, 4), "an extension")
CheckWrite(MsgPackWriteExtension(*Writer, 2, @Bytes, 3), "an extension")


; Writing the entries of an array in their own writer.
*Entries = MsgPackCreate(16)
CheckPointer(*Entries, "the entries writer")

CheckWrite(MsgPackWriteInteger(*Entries, 10), "an entry")
CheckWrite(MsgPackWriteInteger(*Entries, 20), "an entry")
CheckWrite(MsgPackWriteInteger(*Entries, 30), "an entry")


; Writing the keys and values of a map, with the array as a value.
*Fields = MsgPackCreate(32)
CheckPointer(*Fields, "the fields writer")

CheckWrite(MsgPackWriteString(*Fields, "Name"), "a key")
CheckWrite(MsgPackWriteString(*Fields, "Herwin"), "a value")
CheckWrite(MsgPackWriteString(*Fields, "Scores"), "a key")
CheckWrite(MsgPackWriteArrayFrom(*Fields, *Entries), "an array")

CheckWrite(MsgPackWriteMapFrom(*Writer, *Fields), "a map")

; The entries and fields writers are left untouched, so they must be freed.
MsgPackFree(*Entries, #True)
MsgPackFree(*Fields, #True)


; Exporting the data and giving it to a reader.
*Buffer = MsgPackFinalize(*Writer)
CheckPointer(*Buffer, "the final buffer")

PrintN("Encoded size: " + Str(MemorySize(*Buffer)))
PrintN("")

*Reader = MsgPackWrapMsgBuffer(*Buffer, MemorySize(*Buffer), #True)
CheckPointer(*Reader, "the reader")


; Dumping every top-level field until the whole buffer is read.
; Each field's full size is checked first, which also validates it.
BytesLeft = MemorySize(*Buffer)
While BytesLeft > 0
    FieldSize = MsgPackGetFieldFullSize(*Reader)
    If FieldSize = #MsgPack_InvalidSize
        PrintN("Invalid field ! (Error " + Str(MsgPackLastError(*Reader)) + ")")
        End 2
    EndIf

    If Not DumpField(*Reader, "", "")
        PrintN("Failed to dump a field !")
        End 3
    EndIf

    BytesLeft = BytesLeft - FieldSize
Wend


; Freeing the obscure structure and the buffer it owns.
MsgPackFree(*Reader, #True)

PrintN("")
PrintN("Press enter to exit.")
Input()

End 0
