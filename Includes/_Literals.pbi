;{- Code Header
; ==- Basic Info -================================
;     Name: _Literals.pbi
;  Version: 0.0.1
;   Author: Herwin Bozet (NibblePoker)
;
; ==- Compatibility -=============================
;  Tested compiler version:
;    * PureBasic 5.73 LTS (x86/x64)
;    * PureBasic 6.21 (x86/x64)
;    * PureBasic 6.21 C Backend (x86/x64/arm64)
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

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Primitives.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Getters

; Reads a nil from the given data.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackReadNull(*MsgPackData.MsgPackData)
	Protected ErrorCode.MsgPack_ErrorCode

	ErrorCode = _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Null, 1)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	_MsgPackMoveOffsetAfterRead(*MsgPackData, 1)

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Reads a boolean from the given data.
; Returns: The boolean value `#True` or `#False` as a `.b`
; OnError: Returns `#False` and sets the `MsgPackData\LastError` field.
Procedure.b MsgPackReadBoolean(*MsgPackData.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #False
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		Debug("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn #False
	EndIf
	
	; We don't check if we're 1 byte off the end since the previous check implies it.

	If FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) = #MsgPack_FormatCode_False
		If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterRead)
	    	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
		EndIf
		
		ProcedureReturn #False
    ElseIf FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) = #MsgPack_FormatCode_True
		If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterRead)
	    	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
	    EndIf
	    
		ProcedureReturn #True
	Else
		Debug("The format code isn't the one for a boolean !  (" +
		      RSet(Hex(FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		      " vs "+ RSet(Hex(#MsgPack_FormatCode_False), 2, "0") +
		      "/"+ RSet(Hex(#MsgPack_FormatCode_True), 2, "0") + ")")

		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn #False
	EndIf
EndProcedure


;-> Setters

;-> > Common

Procedure.MsgPack_ErrorCode _MsgPackWriteLiteral(*MsgPackData.MsgPackData, LiteralFormatCode.MsgPack_FormatCode)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_IsReadOnly)
		Debug("Cannot write in a read-only buffer !")
		*MsgPackData\LastError = #MsgPack_Error_BufferIsReadOnly
		ProcedureReturn #MsgPack_Error_BufferIsReadOnly
	EndIf

	*MsgPackData\LastError = #MsgPack_Error_Success

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 1)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer for literal with code 0x" + Hex(LiteralFormatCode) + "...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, 1)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf
	
	FastPokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, LiteralFormatCode)

	If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterWrite)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
	EndIf
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


;-> Macro aliases

; @Function MsgPackWriteNull(*Ptr.MsgPackData).MsgPack_ErrorCode
; Writes a null field in the given MessagePack at its current offset. \
; The offset may be grown if required, and if ´MsgPackData\Flags´ has ´???´ unset.
; The offset may be incremented if the ´MsgPackData\Flags´ has ´???´ set.
; @Returns
;  * `#MsgPack_Error_Success` on success.
;  * `#MsgPack_Error_NullPointerGiven` if `MsgPackData` is `#Null`
; @SideEffects
;  * ´MsgPackData\LastError´ will contains the returned code, except for the ´#MsgPack_Error_NullPointerGiven´ case.
; @SupportedOS Windows, Linux, MacOS
; @SupportedCPU x86, x64, arm64
Macro MsgPackWriteNull(MsgPackData) : _MsgPackWriteLiteral(MsgPackData, #MsgPack_FormatCode_Null) : EndMacro

Macro MsgPackWriteTrue(MsgPackData) : _MsgPackWriteLiteral(MsgPackData, #MsgPack_FormatCode_True) : EndMacro

Macro MsgPackWriteFalse(MsgPackData) : _MsgPackWriteLiteral(MsgPackData, #MsgPack_FormatCode_False) : EndMacro


;-> > Utility

; Writes `#True` or `#False` depending on `Boolean`.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteBoolean(*MsgPackData.MsgPackData, Boolean.b)
	If Boolean
		ProcedureReturn MsgPackWriteTrue(*MsgPackData)
	EndIf

	ProcedureReturn MsgPackWriteFalse(*MsgPackData)
EndProcedure
