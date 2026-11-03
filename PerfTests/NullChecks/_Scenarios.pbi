; Shared by `PerfNullChecksOn.pb` and `PerfNullChecksOff.pb`, which only differ by `#MsgPack_DisableNullChecks`.
; Both must define `#Perf_Implementation` before including this file, and `#MsgPack_DisableNullChecks` for the "off" one.
;
; Writes and reads the "MassiveReadAmount" workload with implicit typing, into a buffer of the right size.
; Only the scenarios where the checks are the main overhead are measured.

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"
XIncludeFile "../MassiveReadAmount/_Workload.pbi"

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
		PerfCheckWrite(MsgPackWriteFloat64(*Writer, 3.14))
		PerfCheckWrite(MsgPackWriteString(*Writer, "Hello"))
	Next
EndProcedure

; Returns the finalized buffer, which must be freed with `FreeMemory()`.
Procedure.i Encode()
	Protected *Writer = MsgPackCreate(#Perf_EncodedSize)
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


Procedure.q ScenarioWritePrealloc()
	Protected *Buffer = Encode()
	Protected Size.q = MemorySize(*Buffer)
	
	FreeMemory(*Buffer)
	ProcedureReturn Size
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


OpenConsole()

*Encoded = Encode()

PerfRun(#Perf_Implementation, "read", @ScenarioRead(), #Perf_Fields)
PerfRun(#Perf_Implementation, "write-prealloc", @ScenarioWritePrealloc(), #Perf_Fields)

FreeMemory(*Encoded)

End 0
