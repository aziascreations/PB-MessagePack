EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"
XIncludeFile "_Workload.pbi"


; Writes and reads the shared workload, see `_Workload.pbi`.

; Current size, number of fields and string encoding.
Global FieldSize.i
Global FieldCount.i
Global Encoding.i

; Data written in each field.
Global Text.s
Global *Data

; Encoded fields, prepared once for the read scenarios.
Global *Encoded

; Receives each binary field when reading.
Global *Output


; Returns the finalized buffer, which must be freed with `FreeMemory()`.
; The writer is big enough for all the fields, the reallocations are measured in "MassiveReadAmount".
Procedure.i EncodeStrings()
	Protected *Writer = MsgPackCreate(FieldCount * (FieldSize * 2 + 5))
	Protected *Buffer
	Protected i.i
	
	If Not *Writer
		PerfFail("Failed to create the writer !")
	EndIf
	
	For i = 1 To FieldCount
		PerfCheckWrite(MsgPackWriteString(*Writer, Text, Encoding))
	Next
	
	*Buffer = MsgPackFinalize(*Writer)
	If Not *Buffer
		PerfFail("Failed to finalize the writer !")
	EndIf
	
	ProcedureReturn *Buffer
EndProcedure

; Returns the finalized buffer, which must be freed with `FreeMemory()`.
Procedure.i EncodeBinaries()
	Protected *Writer = MsgPackCreate(FieldCount * (FieldSize + 5))
	Protected *Buffer
	Protected i.i
	
	If Not *Writer
		PerfFail("Failed to create the writer !")
	EndIf
	
	For i = 1 To FieldCount
		PerfCheckWrite(MsgPackWriteBinary(*Writer, *Data, FieldSize))
	Next
	
	*Buffer = MsgPackFinalize(*Writer)
	If Not *Buffer
		PerfFail("Failed to finalize the writer !")
	EndIf
	
	ProcedureReturn *Buffer
EndProcedure

Procedure.q BufferSizeAndFree(*Buffer)
	Protected Size.q = MemorySize(*Buffer)
	
	FreeMemory(*Buffer)
	ProcedureReturn Size
EndProcedure


Procedure.q ScenarioStringWrite()
	ProcedureReturn BufferSizeAndFree(EncodeStrings())
EndProcedure

Procedure.q ScenarioStringRead()
	Protected *Reader = MsgPackWrapMsgBuffer(*Encoded, MemorySize(*Encoded))
	Protected Total.q
	Protected i.i
	
	If Not *Reader
		PerfFail("Failed to wrap the buffer !")
	EndIf
	
	For i = 1 To FieldCount
		Total + Len(MsgPackReadString(*Reader, Encoding))
	Next
	
	; Failed reads don't move the offset, so a failure breaks the next reads too.
	If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
		PerfFail("A read failed !")
	EndIf
	
	MsgPackFree(*Reader, #False)
	ProcedureReturn Total
EndProcedure

Procedure.q ScenarioBinaryWrite()
	ProcedureReturn BufferSizeAndFree(EncodeBinaries())
EndProcedure

Procedure.q ScenarioBinaryRead()
	Protected *Reader = MsgPackWrapMsgBuffer(*Encoded, MemorySize(*Encoded))
	Protected Total.q, BytesRead.q
	Protected i.i
	
	If Not *Reader
		PerfFail("Failed to wrap the buffer !")
	EndIf
	
	For i = 1 To FieldCount
		BytesRead = MsgPackReadBinary(*Reader, *Output, FieldSize)
		If BytesRead = #MsgPack_InvalidSize
			PerfFail("A read failed !")
		EndIf
		Total + BytesRead
	Next
	
	MsgPackFree(*Reader, #False)
	ProcedureReturn Total
EndProcedure


Procedure RunStringScenarios(Size.i, StringEncoding.i, Name.s)
	FieldSize = Size
	FieldCount = #Perf_TotalSize / Size
	Encoding = StringEncoding
	Text = LSet("", Size, "a")
	*Encoded = EncodeStrings()
	
	PerfRun("pb", Name + "-" + Str(Size) + "-write", @ScenarioStringWrite(), FieldCount)
	PerfRun("pb", Name + "-" + Str(Size) + "-read", @ScenarioStringRead(), FieldCount)
	
	FreeMemory(*Encoded)
EndProcedure

Procedure RunBinaryScenarios(Size.i)
	FieldSize = Size
	FieldCount = #Perf_TotalSize / Size
	*Data = AllocateMemory(Size)
	*Output = AllocateMemory(Size)
	If Not *Data Or Not *Output
		PerfFail("Failed to allocate the buffers !")
	EndIf
	FillMemory(*Data, Size, $AB)
	*Encoded = EncodeBinaries()
	
	PerfRun("pb", "bin-" + Str(Size) + "-write", @ScenarioBinaryWrite(), FieldCount)
	PerfRun("pb", "bin-" + Str(Size) + "-read", @ScenarioBinaryRead(), FieldCount)
	
	FreeMemory(*Encoded)
	FreeMemory(*Output)
	FreeMemory(*Data)
EndProcedure


OpenConsole()

RunStringScenarios(8, #PB_UTF8, "str")
RunStringScenarios(1024, #PB_UTF8, "str")
RunStringScenarios(65536, #PB_UTF8, "str")
RunStringScenarios(1024, #PB_Unicode, "str-utf16")

RunBinaryScenarios(1024)
RunBinaryScenarios(1048576)

End 0
