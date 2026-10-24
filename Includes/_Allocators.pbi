;{- Code Header
; ==- Basic Info -================================
;     Name: _Allocators.pbi
;  Version: 0.0.0
;   Author: Herwin Bozet (NibblePoker)
;
; ==- Compatibility -=============================
;  Tested compiler version:
;    * //PureBasic 5.73 LTS (x86/x64)
;    * //PureBasic 6.21 (x86/x64)
;    * //PureBasic 6.21 C Backend (arm64)
; 
; ==- Links & License -===========================
;  License: CC0 1.0 Universal (Public Domain)
;  GitHub: https://github.com/aziascreations/PB-MessagePack
;}


; ------------------------------------------------------------------------------
;- Compiler directive

XIncludeFile "./_Commons.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Thingies

Procedure.i MsgPackCreate(InitialSize.i, GrowthIncrement.i = 1)
	Protected *ReturnedValue.MsgPackData = #Null

	If InitialSize <= 0
		DebuggerWarning("Returning #Null, requested size was zero or negative")
		ProcedureReturn #Null
	EndIf

	If GrowthIncrement <= 0
		DebuggerWarning("Returning #Null, growth increment was zero or negative")
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	
	If *ReturnedValue <> #Null
		*ReturnedValue\BufferOffset = 0
		*ReturnedValue\BufferSize = InitialSize
		*ReturnedValue\BufferGrowthIncrement = GrowthIncrement
		*ReturnedValue\DataFlags = 0
		
		*ReturnedValue\Buffer = AllocateMemory(InitialSize)
		If Not *ReturnedValue\Buffer
			Debug("Failed to allocate memory for buffer !")
			FreeStructure(*ReturnedValue)
			*ReturnedValue = #Null
		EndIf
	EndIf
	
	ProcedureReturn *ReturnedValue
EndProcedure

; Wraps an existing buffer into an internal structure without copying it.
; If `GiveOwnership` is `#False`, the buffer stays owned by the caller: it will never
;  be grown or freed by this include, and the caller must free it themselves.
; If `GiveOwnership` is `#True`, `*Buffer` MUST come from `AllocateMemory()`, since it
;  may be reallocated when growing, and it can be freed through `MsgPackFree()`.
Procedure.i MsgPackWrapMsgBuffer(*Buffer, BufferSize.i, GiveOwnership.b = #False, GrowthIncrement.i = 1)
	Protected *ReturnedValue.MsgPackData = #Null

	If *Buffer = #Null Or BufferSize <= 0
		ProcedureReturn #Null
	EndIf

	If GrowthIncrement <= 0
		DebuggerWarning("Returning #Null, growth increment was zero or negative")
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	If *ReturnedValue = #Null
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue\BufferOffset = 0
	*ReturnedValue\BufferSize = BufferSize
	*ReturnedValue\BufferGrowthIncrement = GrowthIncrement
	*ReturnedValue\DataFlags = 0
	*ReturnedValue\Buffer = *Buffer

	If Not GiveOwnership
		*ReturnedValue\DataFlags = #MsgPack_DataFlags_CannotGrow | #MsgPack_DataFlags_NoBufferFree
	EndIf
	
	ProcedureReturn *ReturnedValue
EndProcedure

Procedure.b MsgPackFree(*MsgPackData.MsgPackData, FreeDataBuffer.b = #False)
	If Not *MsgPackData
		ProcedureReturn #False
	EndIf
	
	If FreeDataBuffer And _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_NoBufferFree)
		DebuggerError("Cannot free a buffer that is still owned by the caller !")
		ProcedureReturn #False
	EndIf

	If *MsgPackData\Buffer <> #Null And FreeDataBuffer
		FreeMemory(*MsgPackData\Buffer)
	EndIf
	FreeStructure(*MsgPackData)
	
	ProcedureReturn #True
EndProcedure


; TODO: Add callback in the structure, maybe ?
; FIXME: Use a .q for the size !!!!
Procedure.MsgPack_ErrorCode MsgPackGrow(*MsgPackData.MsgPackData, DesiredSizeIncrease.i)
	Protected NewSize.q
	Protected *NewBuffer
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_CannotGrow)
		*MsgPackData\LastError = #MsgPack_Error_CannotGrowBufferDueToConfig
		ProcedureReturn #MsgPack_Error_CannotGrowBufferDueToConfig
	EndIf

	If DesiredSizeIncrease <= 0
		DebuggerError("Negative growth value was passed !")
		*MsgPackData\LastError = #MsgPack_Error_InvalidValue
		ProcedureReturn #MsgPack_Error_InvalidValue
	EndIf
	
	NewSize = *MsgPackData\BufferSize + DesiredSizeIncrease

	; Rounding up to the next multiple of `BufferGrowthIncrement`.
	If *MsgPackData\BufferGrowthIncrement > 1
		NewSize = ((NewSize + *MsgPackData\BufferGrowthIncrement - 1) / *MsgPackData\BufferGrowthIncrement) * *MsgPackData\BufferGrowthIncrement
	EndIf

	; `DesiredSizeIncrease` is positive, so a new size that isn't bigger can only come from an overflow.
	If NewSize <= *MsgPackData\BufferSize
		DebuggerError("We had an overflow in one of the growth values, the calculation is messed up !")
		*MsgPackData\LastError = #MsgPack_Error_ValueOverflow
		ProcedureReturn #MsgPack_Error_ValueOverflow
	EndIf
	
	*NewBuffer = ReAllocateMemory(*MsgPackData\Buffer, NewSize)
	If Not *NewBuffer
		Debug("Failed to reallocate memory for buffer !")

		*MsgPackData\LastError = #MsgPack_Error_FailedToGrowBuffer
		ProcedureReturn #MsgPack_Error_FailedToGrowBuffer
	EndIf
	
	*MsgPackData\Buffer = *NewBuffer
	*MsgPackData\BufferSize = NewSize
	
	; Often set by the callers, but programmers are likely to use this
	;  function directly, so I'm leaving it here.
	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure
