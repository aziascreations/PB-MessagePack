;{- Code Header
; ==- Basic Info -================================
;     Name: _Literals.pbi
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

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Allocators.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Getters

;Procedure.i MsgPackReadNull(*MsgPackData.MsgPackData)
;	CompilerIf Not #MsgPack_DisableNullChecks
;		If Not *MsgPackData
;			DebuggerError("A #Null MsgPackData pointer was passed !")
;			ProcedureReturn #Null
;		EndIf
;	CompilerEndIf
;EndProcedure


; Reads a boolean from the given data.
; Returns: The boolean value `#True` or `#False` as a `.b`
; OnError: Returns `#False` and sets the `MsgPackData\LastError` field.
;          Will also raise a `DebuggerError`.
Procedure.b MsgPackReadBoolean(*MsgPackData.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #False
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")

		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn #False
	EndIf
	
	; We don't check if we're 1 byte off the end since the previous check implies it.

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) = #MsgPack_FormatCode_False
		If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterRead)
	    	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
		EndIf
		
		ProcedureReturn #False
    ElseIf PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) = #MsgPack_FormatCode_True
		If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterRead)
	    	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
	    EndIf
	    
		ProcedureReturn #True
	Else
		DebuggerError("The format code isn't the one for a boolean !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
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
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, LiteralFormatCode)

	If _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterWrite)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
	EndIf
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


;-> > Utility

; Procedure.b MsgPackWriteBoolean(*MsgPackData.MsgPackData, Boolean)
;     If Boolean
;         ProcedureReturn MsgPackWriteTrue(*MsgPackData)
;     Else
;         ProcedureReturn MsgPackWriteFalse(*MsgPackData)
;     EndIf
; EndProcedure


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
