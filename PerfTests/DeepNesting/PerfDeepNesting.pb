EnableExplicit

XIncludeFile "../../Includes/MessagePack.pbi"
XIncludeFile "../_PerfTesting.pbi"


; Builds and reads arrays nested `NestedDepth` levels deep, each one holding 3 integers before the next one.
; Each run handles `NestedRepeats` of them, and `NsPerOp` is the time per nested structure.
; The depth goes up to the default `#MsgPack_MaxDepth`.

#NestedMaxDepth = 128

; Number of levels handled by each run, split between the repeats.
#NestedLevelsPerRun = 100000

Global NestedDepth.i
Global NestedRepeats.i
Global *NestedBuffer


Procedure WriteLevelIntegers(*Writer)
	PerfCheckWrite(MsgPackWriteInteger(*Writer, 1))
	PerfCheckWrite(MsgPackWriteInteger(*Writer, 2))
	PerfCheckWrite(MsgPackWriteInteger(*Writer, 3))
EndProcedure

; Returns the finalized buffer, which must be freed with `FreeMemory()`.
; Each level's content is written in its own writer, then copied into its parent.
Procedure.i BuildNestedBuffer()
	Protected *Content, *Parent, *Buffer
	Protected Level.i

	*Content = MsgPackCreate(64)
	If Not *Content
		PerfFail("Failed to create a writer !")
	EndIf
	WriteLevelIntegers(*Content)

	For Level = 2 To NestedDepth
		*Parent = MsgPackCreate(64)
		If Not *Parent
			PerfFail("Failed to create a writer !")
		EndIf
		WriteLevelIntegers(*Parent)
		PerfCheckWrite(MsgPackWriteArrayFrom(*Parent, *Content))
		MsgPackFree(*Content, #True)
		*Content = *Parent
	Next

	; The top-level array.
	*Parent = MsgPackCreate(64)
	If Not *Parent
		PerfFail("Failed to create a writer !")
	EndIf
	PerfCheckWrite(MsgPackWriteArrayFrom(*Parent, *Content))
	MsgPackFree(*Content, #True)

	*Buffer = MsgPackFinalize(*Parent)
	If Not *Buffer
		PerfFail("Failed to finalize the writer !")
	EndIf

	ProcedureReturn *Buffer
EndProcedure

; Examines every level, reading its integers, and returns their sum for one structure.
Procedure.q ExamineNested(ExaminationOptions.MsgPack_ExaminationOption)
	Protected Dim Views.i(NestedDepth)
	Protected Total.q
	Protected Iteration.i, Level.i, Entry.i

	For Iteration = 1 To NestedRepeats
		Total = 0

		Views(0) = MsgPackWrapMsgBuffer(*NestedBuffer, MemorySize(*NestedBuffer))
		If Not Views(0)
			PerfFail("Failed to wrap the buffer !")
		EndIf

		For Level = 1 To NestedDepth
			Views(Level) = MsgPackExamine(Views(Level - 1), ExaminationOptions)
			If Not Views(Level)
				PerfFail("Failed to examine level " + Str(Level) + " !")
			EndIf

			For Entry = 1 To 3
				If Not MsgPackNextEntry(Views(Level))
					PerfFail("Missing integer at level " + Str(Level) + " !")
				EndIf
				Total + MsgPackReadInteger(Views(Level))
			Next

			; Moving to the nested array, the innermost level doesn't have one.
			If Level < NestedDepth
				If Not MsgPackNextEntry(Views(Level))
					PerfFail("Missing array at level " + Str(Level) + " !")
				EndIf
			EndIf
		Next

		For Level = NestedDepth To 1 Step -1
			MsgPackFinish(Views(Level))
		Next
		MsgPackFree(Views(0), #False)
	Next

	ProcedureReturn Total
EndProcedure


Procedure.q ScenarioBuild()
	Protected *Buffer
	Protected Size.q
	Protected Iteration.i

	For Iteration = 1 To NestedRepeats
		*Buffer = BuildNestedBuffer()
		Size = MemorySize(*Buffer)
		FreeMemory(*Buffer)
	Next

	ProcedureReturn Size
EndProcedure

Procedure.q ScenarioExamine()
	ProcedureReturn ExamineNested(0)
EndProcedure

Procedure.q ScenarioExamineUnsafe()
	ProcedureReturn ExamineNested(#MsgPack_ExaminationOptions_Unsafe)
EndProcedure

Procedure.q ScenarioFullSize()
	Protected *Reader
	Protected Size.q
	Protected Iteration.i

	For Iteration = 1 To NestedRepeats
		*Reader = MsgPackWrapMsgBuffer(*NestedBuffer, MemorySize(*NestedBuffer))
		If Not *Reader
			PerfFail("Failed to wrap the buffer !")
		EndIf

		Size = MsgPackGetFieldFullSize(*Reader)
		If Size = #MsgPack_InvalidSize
			PerfFail("Failed to get the full size !")
		EndIf

		MsgPackFree(*Reader, #False)
	Next

	ProcedureReturn Size
EndProcedure


OpenConsole()

NestedDepth = 1
While NestedDepth <= #NestedMaxDepth
	NestedRepeats = #NestedLevelsPerRun / NestedDepth
	*NestedBuffer = BuildNestedBuffer()

	PerfRun("pb", "nested-" + Str(NestedDepth) + "-build", @ScenarioBuild(), NestedRepeats)
	PerfRun("pb", "nested-" + Str(NestedDepth) + "-examine", @ScenarioExamine(), NestedRepeats)
	PerfRun("pb", "nested-" + Str(NestedDepth) + "-examine-unsafe", @ScenarioExamineUnsafe(), NestedRepeats)
	PerfRun("pb", "nested-" + Str(NestedDepth) + "-fullsize", @ScenarioFullSize(), NestedRepeats)

	FreeMemory(*NestedBuffer)
	NestedDepth * 2
Wend

End 0
