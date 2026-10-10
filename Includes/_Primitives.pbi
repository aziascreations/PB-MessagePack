;{- Code Header
; ==- Basic Info -================================
;     Name: _Primitives.pbi
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

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

; Includes the required "Endianness.pbi"
XIncludeFile "./_Commons.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Getters & Setters

;-> > UInt8

Procedure.MsgPack_ErrorCode MsgPackWriteUInt8(*MsgPackData.MsgPackData, Value.a)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for UInt8...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 2)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt8)
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.a MsgPackReadUInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.a = $00
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt8
		DebuggerError("The format code isn't the one for a UInt8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt8), 2, "0") + ")")

		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn ReturnedValue
EndProcedure



;-> > Int8

Procedure.MsgPack_ErrorCode MsgPackWriteInt8(*MsgPackData.MsgPackData, Value.b)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Int8...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 2)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int8)
	PokeB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.b MsgPackReadInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.b = $00
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int8
		DebuggerError("The format code isn't the one for a Int8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int8), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2

	ProcedureReturn ReturnedValue
EndProcedure


;-> > UInt16

Procedure.MsgPack_ErrorCode MsgPackWriteUInt16(*MsgPackData.MsgPackData, Value.u)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for UInt16...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 3)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt16)
	PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.u MsgPackReadUInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.u = $0000

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt16
		DebuggerError("The format code isn't the one for a UInt16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt16), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int16

Procedure.MsgPack_ErrorCode MsgPackWriteInt16(*MsgPackData.MsgPackData, Value.w)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Int16...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 3)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int16)
	PokeW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.w MsgPackReadInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.w = $0000

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int16
		DebuggerError("The format code isn't the one for a Int16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int16), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt32

; No unsigned Long in PureBasic: value is peeked/poked as-is via .l and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt32(*MsgPackData.MsgPackData, Value.l)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for UInt32...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 5)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.l MsgPackReadUInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l = $00000000

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt32
		DebuggerError("The format code isn't the one for a UInt32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt32), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int32

Procedure.MsgPack_ErrorCode MsgPackWriteInt32(*MsgPackData.MsgPackData, Value.l)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Int32...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 5)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.l MsgPackReadInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l = $00000000

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int32
		DebuggerError("The format code isn't the one for a Int32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int32), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt64

; No unsigned Quad in PureBasic: value is peeked/poked as-is via .q and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt64(*MsgPackData.MsgPackData, Value.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for UInt64...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 9)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.q MsgPackReadUInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q = 0

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt64
		DebuggerError("The format code isn't the one for a UInt64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt64), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int64

Procedure.MsgPack_ErrorCode MsgPackWriteInt64(*MsgPackData.MsgPackData, Value.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Int64...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 9)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.q MsgPackReadInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q = 0

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int64
		DebuggerError("The format code isn't the one for a Int64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int64), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float32

Procedure.MsgPack_ErrorCode MsgPackWriteFloat32(*MsgPackData.MsgPackData, Value.f)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Float32...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 5)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float32)
	PokeF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.f MsgPackReadFloat32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.f = 0.0

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
			ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float32
		DebuggerError("The format code isn't the one for a Float32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float32), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float64

Procedure.MsgPack_ErrorCode MsgPackWriteFloat64(*MsgPackData.MsgPackData, Value.d)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for Float64...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 9)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float64)
	PokeD(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.d MsgPackReadFloat64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.d = 0.0

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float64
		DebuggerError("The format code isn't the one for a Float64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float64), 2, "0") + ")")
					  
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekD(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure



; ------------------------------------------------------------------------------
;- Aliases

;-> UInt8
Macro MsgPackWriteU8 : MsgPackWriteUInt8 : EndMacro
Macro MsgPackReadU8 : MsgPackReadUInt8 : EndMacro

;-> Int8
Macro MsgPackWriteI8 : MsgPackWriteInt8 : EndMacro
Macro MsgPackReadI8 : MsgPackReadInt8 : EndMacro

;-> UInt16
Macro MsgPackWriteU16 : MsgPackWriteUInt16 : EndMacro
Macro MsgPackReadU16 : MsgPackReadUInt16 : EndMacro

;-> Int16
Macro MsgPackWriteI16 : MsgPackWriteInt16 : EndMacro
Macro MsgPackReadI16 : MsgPackReadInt16 : EndMacro

;-> UInt32
Macro MsgPackWriteU32 : MsgPackWriteUInt32 : EndMacro
Macro MsgPackReadU32 : MsgPackReadUInt32 : EndMacro

;-> Int32
Macro MsgPackWriteI32 : MsgPackWriteInt32 : EndMacro
Macro MsgPackReadI32 : MsgPackReadInt32 : EndMacro

;-> UInt64
Macro MsgPackWriteU64 : MsgPackWriteUInt64 : EndMacro
Macro MsgPackReadU64 : MsgPackReadUInt64 : EndMacro

;-> Int64
Macro MsgPackWriteI64 : MsgPackWriteInt64 : EndMacro
Macro MsgPackReadI64 : MsgPackReadInt64 : EndMacro

;-> Float32
Macro MsgPackWriteF32 : MsgPackWriteFloat32 : EndMacro
Macro MsgPackReadF32 : MsgPackReadFloat32 : EndMacro

;-> Float64
Macro MsgPackWriteF64 : MsgPackWriteFloat64 : EndMacro
Macro MsgPackReadF64 : MsgPackReadFloat64 : EndMacro
