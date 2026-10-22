;{- Code Header
; ==- Basic Info -================================
;     Name: _Binary.pbi
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
;- Notes

; Sizes are all unsigned 8/16/32, using Q fixes any potential issues !



; ------------------------------------------------------------------------------
;- Compiler directive

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Allocators.pbi"



; ------------------------------------------------------------------------------
;- Constants

#MsgPack_Binary_InvalidSize = -1



; ------------------------------------------------------------------------------
;- Procedures

;-> Utils

; TODO: Change this into a simplified global one for strings/maps/arrays/bin !
Procedure.q _MsgPackGetSizeAfterFormatCode(*MsgPackData.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Binary_InvalidSize
		EndIf
	CompilerEndIf

	; FIXME: Not implemented !
EndProcedure


;-> Getters

Procedure.i MsgPackCopyBinary(*MsgPackData.MsgPackData)
	
	
EndProcedure

Procedure.i MsgPackReadBinary(*MsgPackData.MsgPackData, *OutputBuffer, OutputBufferSize.q)
	
	
EndProcedure



;-> Setters

Procedure.MsgPack_ErrorCode MsgPackWriteBin8(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success

	If BufferSize < 0
        DebuggerWarning("Received negative size !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn *MsgPackData\LastError
	ElseIf BufferSize > 255
        DebuggerWarning("Binary buffer is bigger than `(2^8)-1` bytes !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn *MsgPackData\LastError
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, BufferSize + 2)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer by `" + Str(BufferSize + 2) + "` bytes for bin8...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, BufferSize + 2)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Bin8)
    PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, BufferSize)
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2

    CopyMemory(*Buffer, *MsgPackData\Buffer + *MsgPackData\BufferOffset, BufferSize)
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + BufferSize
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.MsgPack_ErrorCode MsgPackWriteBin16(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success

	If BufferSize < 0
        DebuggerWarning("Received negative size !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn *MsgPackData\LastError
	ElseIf BufferSize > 65535
        DebuggerWarning("Binary buffer is bigger than `(2^16)-1` bytes !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn *MsgPackData\LastError
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, BufferSize + 3)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer by `" + Str(BufferSize + 3) + "` bytes for bin16...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, BufferSize + 3)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Bin16)
    PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapU(BufferSize))
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3

    CopyMemory(*Buffer, *MsgPackData\Buffer + *MsgPackData\BufferOffset, BufferSize)
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + BufferSize
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.MsgPack_ErrorCode MsgPackWriteBin32(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	*MsgPackData\LastError = #MsgPack_Error_Success

	If BufferSize < 0
        DebuggerWarning("Received negative size !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn *MsgPackData\LastError
	ElseIf BufferSize > 4294967295
        DebuggerWarning("Binary buffer is bigger than `(2^32)-1` bytes !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn *MsgPackData\LastError
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, BufferSize + 5)
		Protected GrowthErrorCode.MsgPack_ErrorCode
		
		Debug("Growing buffer by `" + Str(BufferSize + 5) + "` bytes for bin16...")

		GrowthErrorCode = MsgPackGrow(*MsgPackData, BufferSize + 5)
		If GrowthErrorCode <> #MsgPack_Error_Success
			; The structure's error code field is set by the called function !
			ProcedureReturn GrowthErrorCode
		EndIf
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Bin32)
    PokeI(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI(BufferSize))
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5

    CopyMemory(*Buffer, *MsgPackData\Buffer + *MsgPackData\BufferOffset, BufferSize)
    *MsgPackData\BufferOffset = *MsgPackData\BufferOffset + BufferSize
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.MsgPack_ErrorCode MsgPackWriteBinary(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
    If BufferSize < 0
        DebuggerWarning("Received negative size !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn *MsgPackData\LastError
    ElseIf BufferSize <= 255
		ProcedureReturn MsgPackWriteBin8(*MsgPackData, *Buffer, BufferSize)
    ElseIf BufferSize <= 65535
		ProcedureReturn MsgPackWriteBin16(*MsgPackData, *Buffer, BufferSize)
    ElseIf BufferSize <= 4294967295
		ProcedureReturn MsgPackWriteBin32(*MsgPackData, *Buffer, BufferSize)
    Else
        DebuggerWarning("Binary buffer is bigger than `(2^32)-1` bytes !")
	    *MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn *MsgPackData\LastError
    EndIf
EndProcedure
