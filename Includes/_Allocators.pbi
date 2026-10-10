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
		*ReturnedValue\BufferGrowthIncrements = InitialSize
		
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
	*ReturnedValue\BufferGrowthIncrements = 0
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
