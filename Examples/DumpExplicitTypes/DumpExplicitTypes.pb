; ------------------------------------------------------------------------------
;- Notes

; This example shows you how to iterate over a MessagePack buffer and dump
;  every field to the console with its exact format code.
; Each field is read with the procedure matching its format code.
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


Procedure.s GetFormatCodeName(FormatCode.MsgPack_FormatCode)
    Select FormatCode
        Case #MsgPack_FormatCode_Null : ProcedureReturn "Null"
        Case #MsgPack_FormatCode_False : ProcedureReturn "False"
        Case #MsgPack_FormatCode_True : ProcedureReturn "True"
        Case #MsgPack_FormatCode_FixIntPositive : ProcedureReturn "FixIntPositive"
        Case #MsgPack_FormatCode_FixIntNegative : ProcedureReturn "FixIntNegative"
        Case #MsgPack_FormatCode_UInt8 : ProcedureReturn "UInt8"
        Case #MsgPack_FormatCode_UInt16 : ProcedureReturn "UInt16"
        Case #MsgPack_FormatCode_UInt32 : ProcedureReturn "UInt32"
        Case #MsgPack_FormatCode_UInt64 : ProcedureReturn "UInt64"
        Case #MsgPack_FormatCode_Int8 : ProcedureReturn "Int8"
        Case #MsgPack_FormatCode_Int16 : ProcedureReturn "Int16"
        Case #MsgPack_FormatCode_Int32 : ProcedureReturn "Int32"
        Case #MsgPack_FormatCode_Int64 : ProcedureReturn "Int64"
        Case #MsgPack_FormatCode_Float32 : ProcedureReturn "Float32"
        Case #MsgPack_FormatCode_Float64 : ProcedureReturn "Float64"
        Case #MsgPack_FormatCode_FixStr : ProcedureReturn "FixStr"
        Case #MsgPack_FormatCode_Str8 : ProcedureReturn "Str8"
        Case #MsgPack_FormatCode_Str16 : ProcedureReturn "Str16"
        Case #MsgPack_FormatCode_Str32 : ProcedureReturn "Str32"
        Case #MsgPack_FormatCode_Bin8 : ProcedureReturn "Bin8"
        Case #MsgPack_FormatCode_Bin16 : ProcedureReturn "Bin16"
        Case #MsgPack_FormatCode_Bin32 : ProcedureReturn "Bin32"
        Case #MsgPack_FormatCode_FixArray : ProcedureReturn "FixArray"
        Case #MsgPack_FormatCode_Array16 : ProcedureReturn "Array16"
        Case #MsgPack_FormatCode_Array32 : ProcedureReturn "Array32"
        Case #MsgPack_FormatCode_FixMap : ProcedureReturn "FixMap"
        Case #MsgPack_FormatCode_Map16 : ProcedureReturn "Map16"
        Case #MsgPack_FormatCode_Map32 : ProcedureReturn "Map32"
        Case #MsgPack_FormatCode_FixExt1 : ProcedureReturn "FixExt1"
        Case #MsgPack_FormatCode_FixExt2 : ProcedureReturn "FixExt2"
        Case #MsgPack_FormatCode_FixExt4 : ProcedureReturn "FixExt4"
        Case #MsgPack_FormatCode_FixExt8 : ProcedureReturn "FixExt8"
        Case #MsgPack_FormatCode_FixExt16 : ProcedureReturn "FixExt16"
        Case #MsgPack_FormatCode_Ext8 : ProcedureReturn "Ext8"
        Case #MsgPack_FormatCode_Ext16 : ProcedureReturn "Ext16"
        Case #MsgPack_FormatCode_Ext32 : ProcedureReturn "Ext32"
    EndSelect

    ProcedureReturn "Invalid"
EndProcedure


; Prints the field at the current offset and moves past it.
; `Label` is printed before it, to tell array indexes and map keys/values apart.
Procedure.b DumpField(*MsgPackData, Indent.s, Label.s)
    Protected FormatCode.MsgPack_FormatCode = MsgPackGetFormatCode(*MsgPackData)
    Protected Text.s = GetFormatCodeName(FormatCode)
    Protected *Iterator, *Data
    Protected IsMap.b, Success.b
    Protected EntryCount.q, Index.q

    Select FormatCode
        Case #MsgPack_FormatCode_Null
            MsgPackReadNull(*MsgPackData)

        Case #MsgPack_FormatCode_False, #MsgPack_FormatCode_True
            ; The value is already given by the format code.
            MsgPackReadBoolean(*MsgPackData)

        Case #MsgPack_FormatCode_FixIntPositive, #MsgPack_FormatCode_FixIntNegative
            ; Fixints don't have their own getter, the generic one reads them.
            Text = Text + ": " + Str(MsgPackReadInteger(*MsgPackData))

        Case #MsgPack_FormatCode_UInt8
            Text = Text + ": " + Str(MsgPackReadUInt8(*MsgPackData))
        Case #MsgPack_FormatCode_UInt16
            Text = Text + ": " + Str(MsgPackReadUInt16(*MsgPackData))
        Case #MsgPack_FormatCode_UInt32
            ; Read as a `.l`, values above the signed max come back negative.
            Text = Text + ": " + Str(MsgPackReadUInt32(*MsgPackData) & $FFFFFFFF)
        Case #MsgPack_FormatCode_UInt64
            ; Read as a `.q`, values above the signed max come back negative.
            Text = Text + ": " + StrU(MsgPackReadUInt64(*MsgPackData), #PB_Quad)

        Case #MsgPack_FormatCode_Int8
            Text = Text + ": " + Str(MsgPackReadInt8(*MsgPackData))
        Case #MsgPack_FormatCode_Int16
            Text = Text + ": " + Str(MsgPackReadInt16(*MsgPackData))
        Case #MsgPack_FormatCode_Int32
            Text = Text + ": " + Str(MsgPackReadInt32(*MsgPackData))
        Case #MsgPack_FormatCode_Int64
            Text = Text + ": " + Str(MsgPackReadInt64(*MsgPackData))

        Case #MsgPack_FormatCode_Float32
            Text = Text + ": " + StrF(MsgPackReadFloat32(*MsgPackData))
        Case #MsgPack_FormatCode_Float64
            Text = Text + ": " + StrD(MsgPackReadFloat64(*MsgPackData))

        Case #MsgPack_FormatCode_FixStr, #MsgPack_FormatCode_Str8,
             #MsgPack_FormatCode_Str16, #MsgPack_FormatCode_Str32
            Text = Text + ": " + Chr(34) + MsgPackReadString(*MsgPackData) + Chr(34)

        Case #MsgPack_FormatCode_Bin8, #MsgPack_FormatCode_Bin16, #MsgPack_FormatCode_Bin32
            *Data = MsgPackCopyBinary(*MsgPackData)
            Text = Text + ": " + HexDump(*Data)

        Case #MsgPack_FormatCode_FixExt1, #MsgPack_FormatCode_FixExt2, #MsgPack_FormatCode_FixExt4,
             #MsgPack_FormatCode_FixExt8, #MsgPack_FormatCode_FixExt16,
             #MsgPack_FormatCode_Ext8, #MsgPack_FormatCode_Ext16, #MsgPack_FormatCode_Ext32
            ; The type doesn't move the offset, the data is read right after.
            Text = Text + " (Type " + Str(MsgPackGetExtensionType(*MsgPackData)) + ")"
            If MsgPackLastError(*MsgPackData) <> #MsgPack_Error_Success
                ProcedureReturn #False
            EndIf
            *Data = MsgPackCopyExtension(*MsgPackData)
            Text = Text + ": " + HexDump(*Data)

        Case #MsgPack_FormatCode_FixArray, #MsgPack_FormatCode_Array16, #MsgPack_FormatCode_Array32,
             #MsgPack_FormatCode_FixMap, #MsgPack_FormatCode_Map16, #MsgPack_FormatCode_Map32
            IsMap = Bool(MsgPackFormatCodeToDataType(FormatCode) = #MsgPack_DataTypes_Map)

            EntryCount = MsgPackGetEntryCount(*MsgPackData)
            *Iterator = MsgPackExamine(*MsgPackData)
            If Not *Iterator
                ProcedureReturn #False
            EndIf

            PrintN(Indent + Label + Text + " (" + Str(EntryCount) + " entries)")

            Success = #True
            Index = 0
            While MsgPackNextEntry(*Iterator)
                If IsMap
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
            PrintN(Indent + Label + "Invalid format code !")
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

; MsgPack-encoded buffers that will get exported in this example.
Define *Buffer, *EntriesBuffer, *FieldsBuffer

; Raw data for the bin and ext fields.
Define Bytes.l = $44332211

Define FieldSize.q, BytesLeft.q

OpenConsole()


; Writing a bit of everything, forcing each format code.
*Writer = MsgPackCreate(64)
CheckPointer(*Writer, "the writer")

CheckWrite(MsgPackWriteNull(*Writer), "a nil")
CheckWrite(MsgPackWriteTrue(*Writer), "a true")
CheckWrite(MsgPackWriteFalse(*Writer), "a false")
CheckWrite(MsgPackWriteFixInt(*Writer, 42), "a positive fixint")
CheckWrite(MsgPackWriteFixInt(*Writer, -5), "a negative fixint")
CheckWrite(MsgPackWriteUInt8(*Writer, 200), "a UInt8")
CheckWrite(MsgPackWriteUInt32(*Writer, 70000), "a UInt32")
CheckWrite(MsgPackWriteInt16(*Writer, -1000), "an Int16")
CheckWrite(MsgPackWriteInt64(*Writer, 1), "an Int64")
CheckWrite(MsgPackWriteFloat32(*Writer, 1.5), "a Float32")
CheckWrite(MsgPackWriteFloat64(*Writer, 3.14159), "a Float64")
CheckWrite(MsgPackWriteFixStr(*Writer, "Hello"), "a FixStr")
CheckWrite(MsgPackWriteStr16(*Writer, "World"), "a Str16")
CheckWrite(MsgPackWriteBin8(*Writer, @Bytes, 4), "a Bin8")
CheckWrite(MsgPackWriteFixExt4(*Writer, 1, @Bytes), "a FixExt4")
CheckWrite(MsgPackWriteExt8(*Writer, 2, @Bytes, 3), "an Ext8")


; Forcing the format code of arrays and maps requires their content in a buffer.
; Writing the entries of an array in their own writer, then exporting them.
*Entries = MsgPackCreate(16)
CheckPointer(*Entries, "the entries writer")

CheckWrite(MsgPackWriteUInt8(*Entries, 10), "an entry")
CheckWrite(MsgPackWriteUInt8(*Entries, 20), "an entry")
CheckWrite(MsgPackWriteUInt8(*Entries, 30), "an entry")

*EntriesBuffer = MsgPackFinalize(*Entries)
CheckPointer(*EntriesBuffer, "the entries buffer")


; Writing the keys and values of a map, with the array as a value.
*Fields = MsgPackCreate(32)
CheckPointer(*Fields, "the fields writer")

CheckWrite(MsgPackWriteFixStr(*Fields, "Name"), "a key")
CheckWrite(MsgPackWriteStr8(*Fields, "Herwin"), "a value")
CheckWrite(MsgPackWriteFixStr(*Fields, "Scores"), "a key")
CheckWrite(MsgPackWriteArray16(*Fields, *EntriesBuffer, MemorySize(*EntriesBuffer)), "an Array16")
FreeMemory(*EntriesBuffer)

*FieldsBuffer = MsgPackFinalize(*Fields)
CheckPointer(*FieldsBuffer, "the fields buffer")

CheckWrite(MsgPackWriteMap16(*Writer, *FieldsBuffer, MemorySize(*FieldsBuffer)), "a Map16")
FreeMemory(*FieldsBuffer)


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
