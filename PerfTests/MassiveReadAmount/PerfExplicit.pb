EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"
XIncludeFile "_Workload.pbi"


; Writes and reads the shared workload, see `_Workload.pbi`, forcing each field's format code.

Global *Encoded


Procedure WriteRecords(*Writer)
	Protected i.i

	For i = 1 To #Perf_Records
		PerfCheckWrite(MsgPackWriteFixInt(*Writer, 42))
		PerfCheckWrite(MsgPackWriteFixInt(*Writer, -5))
		PerfCheckWrite(MsgPackWriteUInt8(*Writer, 200))
		PerfCheckWrite(MsgPackWriteInt16(*Writer, -1000))
		PerfCheckWrite(MsgPackWriteUInt32(*Writer, 70000))
		PerfCheckWrite(MsgPackWriteInt64(*Writer, -1099511627776))
		PerfCheckWrite(MsgPackWriteFloat64(*Writer, 3.14))
		PerfCheckWrite(MsgPackWriteFixStr(*Writer, "Hello"))
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
		; Fixints don't have an explicitly typed getter.
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadInteger(*Reader)
		Total + MsgPackReadUInt8(*Reader)
		Total + MsgPackReadInt16(*Reader)
		Total + (MsgPackReadUInt32(*Reader) & $FFFFFFFF)
		Total + MsgPackReadInt64(*Reader)
		Total + Int(MsgPackReadFloat64(*Reader))
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

*Encoded = Encode(#Perf_EncodedSize, 1)

PerfRun("pb-explicit", "read", @ScenarioRead(), #Perf_Fields)
PerfRun("pb-explicit", "write-prealloc", @ScenarioWritePrealloc(), #Perf_Fields)
PerfRun("pb-explicit", "write-grow64k", @ScenarioWriteGrow64K(), #Perf_Fields)
; Last since it reallocates the buffer on every write, which can be very slow.
PerfRun("pb-explicit", "write", @ScenarioWrite(), #Perf_Fields)

FreeMemory(*Encoded)

End 0
