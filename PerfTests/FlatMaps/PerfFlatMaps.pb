EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"
XIncludeFile "_Workload.pbi"


; Writes and reads the shared workload, see `_Workload.pbi`.
; Each map's fields are written in their own writer, then copied in with `MsgPackWriteMapFrom`.

Global Dim Keys.s(#Perf_Entries - 1)
Global *Encoded


Procedure WriteMap(*Writer)
	Protected *Fields = MsgPackCreate(128)
	Protected i.i
	
	If Not *Fields
		PerfFail("Failed to create the fields writer !")
	EndIf
	
	For i = 0 To #Perf_Entries - 1
		PerfCheckWrite(MsgPackWriteString(*Fields, Keys(i)))
		PerfCheckWrite(MsgPackWriteInteger(*Fields, i))
	Next
	
	PerfCheckWrite(MsgPackWriteMapFrom(*Writer, *Fields))
	MsgPackFree(*Fields, #True)
EndProcedure

; Returns the finalized buffer, which must be freed with `FreeMemory()`.
Procedure.i EncodeMaps()
	Protected *Writer = MsgPackCreate(#Perf_EncodedSize)
	Protected *Buffer
	Protected i.i
	
	If Not *Writer
		PerfFail("Failed to create the writer !")
	EndIf
	
	For i = 1 To #Perf_Maps
		WriteMap(*Writer)
	Next
	
	*Buffer = MsgPackFinalize(*Writer)
	If Not *Buffer
		PerfFail("Failed to finalize the writer !")
	EndIf
	
	ProcedureReturn *Buffer
EndProcedure


Procedure.q ScenarioWrite()
	Protected *Buffer = EncodeMaps()
	Protected Size.q = MemorySize(*Buffer)
	
	FreeMemory(*Buffer)
	ProcedureReturn Size
EndProcedure

Procedure.q ScenarioRead()
	Protected *Reader = MsgPackWrapMsgBuffer(*Encoded, MemorySize(*Encoded))
	Protected *Iterator
	Protected Total.q
	Protected i.i
	
	If Not *Reader
		PerfFail("Failed to wrap the buffer !")
	EndIf
	
	For i = 1 To #Perf_Maps
		*Iterator = MsgPackExamine(*Reader)
		If Not *Iterator
			PerfFail("Failed to examine a map !")
		EndIf
		
		While MsgPackNextEntry(*Iterator)
			Total + Len(MsgPackReadString(*Iterator))
			Total + MsgPackReadInteger(*Iterator)
		Wend
		
		; `MsgPackNextEntry` also returns `#False` on errors, and failed reads break the next ones.
		If MsgPackLastError(*Iterator) <> #MsgPack_Error_Success
			PerfFail("A read failed !")
		EndIf
		
		MsgPackFinish(*Iterator)
	Next
	
	MsgPackFree(*Reader, #False)
	ProcedureReturn Total
EndProcedure


OpenConsole()

Define i.i
For i = 0 To #Perf_Entries - 1
	Keys(i) = "Key" + RSet(Str(i), 2, "0")
Next

*Encoded = EncodeMaps()

PerfRun("pb", "write", @ScenarioWrite(), #Perf_Maps)
PerfRun("pb", "read", @ScenarioRead(), #Perf_Maps)

FreeMemory(*Encoded)

End 0
