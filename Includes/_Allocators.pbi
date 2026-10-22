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

Procedure.i MsgPackCreate(InitialSize.i)
	Protected *ReturnedValue.MsgPackData = #Null
	
	If InitialSize <= 0
		DebuggerWarning("Returning #Null, requested size was zero or negative")
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	
	If *ReturnedValue <> #Null
		*ReturnedValue\BufferOffset = 0
		*ReturnedValue\BufferSize = InitialSize
		*ReturnedValue\BufferGrowthIncrement = InitialSize
		*ReturnedValue\DataFlags = 0
		
		*ReturnedValue\Buffer = AllocateMemory(InitialSize)
		If Not *ReturnedValue\Buffer
			DebuggerError("Failed to allocate memory for buffer !")
			FreeStructure(*ReturnedValue)
			*ReturnedValue = #Null
		EndIf
	EndIf
	
	ProcedureReturn *ReturnedValue
EndProcedure

; Wraps an existing, caller-owned buffer so it can be read with ReadA/ReadI8.
; Does not copy or take ownership of *Buffer: free it yourself, and pass
; FreeDataBuffer = #False to MsgPackFreeMsgBuffer for the wrapper it returns.
Procedure.i MsgPackWrapMsgBuffer(*Buffer, BufferSize.i)
	Protected *ReturnedValue.MsgPackData = #Null
	
	If *Buffer = #Null Or BufferSize <= 0
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	If *ReturnedValue = #Null
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue\BufferOffset = 0
	*ReturnedValue\BufferSize = BufferSize
	*ReturnedValue\BufferGrowthIncrement = 0
	*ReturnedValue\DataFlags = 0
	*ReturnedValue\Buffer = *Buffer
	
	ProcedureReturn *ReturnedValue
EndProcedure

Procedure.b MsgPackFree(*MsgPackData.MsgPackData, FreeDataBuffer.b = #False)
	If Not *MsgPackData
		ProcedureReturn #False
	EndIf
	
	If *MsgPackData <> #Null
		If *MsgPackData\Buffer <> #Null And FreeDataBuffer
			FreeMemory(*MsgPackData\Buffer)
		EndIf
		FreeStructure(*MsgPackData)
	EndIf
	
	ProcedureReturn #True
EndProcedure


; TODO: Add callback in the structure, maybe ?
; FIXME: Use a .q for the size !!!!
Procedure.MsgPack_ErrorCode MsgPackGrow(*MsgPackData.MsgPackData, DesiredSizeIncrease.i)
	Protected GrowthSize.q
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
	
	If *MsgPackData\BufferGrowthIncrement <= 1
		GrowthSize = DesiredSizeIncrease
		NewSize = *MsgPackData\BufferSize + GrowthSize
	Else
		GrowthSize = (DesiredSizeIncrease % *MsgPackData\BufferGrowthIncrement) + DesiredSizeIncrease
		NewSize = ((*MsgPackData\BufferSize + GrowthSize) % *MsgPackData\BufferGrowthIncrement) + (*MsgPackData\BufferSize + GrowthSize)
	EndIf

	If (GrowthSize < 0) Or (*MsgPackData\BufferSize + GrowthSize < 0) Or (NewSize < 0) Or (NewSize < *MsgPackData\BufferSize)
		DebuggerError("We had an overflow in one of the growth values, the calculation is messed up !")
		*MsgPackData\LastError = #MsgPack_Error_ValueOverflow
		ProcedureReturn #MsgPack_Error_ValueOverflow
	EndIf
	
	*NewBuffer = ReAllocateMemory(*MsgPackData\Buffer, NewSize)
	If Not *NewBuffer
		DebuggerError("Failed to reallocate memory for buffer !")

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
