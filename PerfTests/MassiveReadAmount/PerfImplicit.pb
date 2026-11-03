EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"
XIncludeFile "_Workload.pbi"


; Writes and reads the shared workload, see `_Workload.pbi`, letting the library pick each field's format code.

Global *Encoded


Procedure WriteRecords(*Writer)
	Protected i.i

	For i = 1 To #Perf_Records
		PerfCheckWrite(MsgPackWriteInteger(*Writer, 42))
		PerfCheckWrite(MsgPackWriteInteger(*Writer, -5))
		PerfCheckWrite(MsgPackWriteInteger(*Writer, 200))
		PerfCheckWrite(MsgPackWriteInteger(*Writer, -1000))
		PerfCheckWrite(MsgPackWriteInteger(*Writer, 70000))
		PerfCheckWrite(MsgPackWriteInteger(*Writer, -1099511627776))
		; Floats don't have an implicitly typed setter.
		PerfCheckWrite(MsgPackWriteFloat64(*Writer, 3.14))
		PerfCheckWrite(MsgPackWriteString(*Writer, "Hello"))
	Next
EndProcedure

; Returns the finalized buffer, which must be freed with `FreeMemory()`.
Procedure.i Encode(InitialSize.i, GrowthIncrement.i)
	Protected *Writer = MsgPackCreate(InitialSize, GrowthIncrement)
	Protected *Buffer

	If Not *Writer
		PerfFail("Failed to create the writer !")
	EndIf

	WriteRecords(*Writer)

	*Buffer = MsgPackFinalize(*Writer)
	If Not *Buffer
		PerfFail("Failed to finalize the writer !")
	EndIf

	ProcedureReturn *Buffer
EndProcedure

Procedure.q EncodeAndFree(InitialSize.i, GrowthIncrement.i)
	Protected *Buffer = Encode(InitialSize, GrowthIncrement)
	Protected Size.q = MemorySize(*Buffer)

	FreeMemory(*Buffer)
	ProcedureReturn Size
EndProcedure


Procedure.q ScenarioWrite()
	ProcedureReturn EncodeAndFree(64, 1)
EndProcedure

Procedure.q ScenarioWriteGrow64K()
	ProcedureReturn EncodeAndFree(64, 65536)
EndProcedure

Procedure.q ScenarioWritePrealloc()
	ProcedureReturn EncodeAndFree(#Perf_EncodedSize, 1)
EndProcedure

Procedure.q ScenarioRead()
	Protected *Reader = MsgPackWrapMsgBuffer(*Encoded, MemorySize(*Encoded))
	Protected Total.q
	Protected i.i

	If Not *Reader
		PerfFail("Failed to wrap the buffer !")
	EndIf

	For i = 1 To #Perf_Records
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + Int(MsgPackReadFloat(*Reader))
		Total + Len(MsgPackReadString(*Reader))
	Next

	; Failed reads don't move the offset, so a failure breaks the next reads too.
	If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
		PerfFail("A read failed !")
	EndIf

	MsgPackFree(*Reader, #False)
	ProcedureReturn Total
EndProcedure

; Doesn't depend on the typing, so it's only measured here.
; Skips each field separately, like the Python and .NET implementations.
Procedure.q ScenarioSkip()
	Protected *Reader = MsgPackWrapMsgBuffer(*Encoded, MemorySize(*Encoded))
	Protected i.i
	
	If Not *Reader
		PerfFail("Failed to wrap the buffer !")
	EndIf
	
	For i = 1 To #Perf_Fields
		If MsgPackSkip(*Reader) <> #MsgPack_Error_Success
			PerfFail("A skip failed !")
		EndIf
	Next
	
	MsgPackFree(*Reader, #False)
	ProcedureReturn #Perf_Fields
EndProcedure


OpenConsole()

*Encoded = Encode(#Perf_EncodedSize, 1)

PerfRun("pb-implicit", "read", @ScenarioRead(), #Perf_Fields)
PerfRun("pb-implicit", "skip", @ScenarioSkip(), #Perf_Fields)
PerfRun("pb-implicit", "write-prealloc", @ScenarioWritePrealloc(), #Perf_Fields)
PerfRun("pb-implicit", "write-grow64k", @ScenarioWriteGrow64K(), #Perf_Fields)
; Last since it reallocates the buffer on every write, which can be very slow.
PerfRun("pb-implicit", "write", @ScenarioWrite(), #Perf_Fields)

FreeMemory(*Encoded)

End 0
