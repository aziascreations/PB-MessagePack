;{- Code Header
; ==- Basic Info -================================
;     Name: _Iterators.pbi
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
XIncludeFile "./_Utils.pbi"
XIncludeFile "./_Allocators.pbi"



; ------------------------------------------------------------------------------
;- Constants

#MsgPack_InvalidSize = -1



; ------------------------------------------------------------------------------
;- Procedures

;-> Utils

Procedure MsgPackGetFieldSize(*MsgPackData.MsgPackData)
    
EndProcedure

Procedure.q MsgPackGetFieldFullSize(*MsgPackData.MsgPackData)
    Protected HasVariableSize = #False
    Protected FullFieldSize.q = 0

    Protected ExaminedDataType.MsgPack_FormatCode
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

    *MsgPackData\LastError = #MsgPack_Error_Success

    ExaminedFormatCode = MsgPackGetFormatCode(*MsgPackData)

    ; Step 1
    ;Select ExaminedFormatCode
    ; FIXME: Not Implemented !!!

    ; Step 2
    If HasVariableSize
        Protected VariableFieldSize = MsgPackGetFieldSize()
        If VariableFieldSize = #MsgPack_InvalidSize
            ProcedureReturn #MsgPack_InvalidSize
        EndIf
        FullFieldSize = FullFieldSize + VariableFieldSize
    EndIf

    ; Step 3
    ProcedureReturn FullFieldSize
EndProcedure


;-> General

; TODO: Use the internal flag to detect if we should check the remaining count.
; MsgPackNext


;-> Dictionary

; MsgPackExamineDictionary

Macro MsgPackFinishDictionary(MsgPackData) : MsgPackFree(MsgPackData, #False) : EndMacro


;-> Arrays

Procedure.i MsgPackExamineArray(*MsgPackData.MsgPackData, ExaminationOptions.MsgPack_ExaminationOption = 0)
    Protected ExaminedFormatCode.MsgPack_FormatCode
    Protected ExaminedDataType.MsgPack_FormatCode
    Protected ExaminedArraySize.q

    Protected *ExaminedData.MsgPackData = #Null
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

    *MsgPackData\LastError = #MsgPack_Error_Success

    ExaminedFormatCode = MsgPackGetFormatCode(*MsgPackData)
    ExaminedDataType = MsgPackGetFormatCode(ExaminedFormatCode)

    If ExaminedDataType <> #MsgPack_DataTypes_Array
        DebuggerWarning("Attempted to iterate on format code 0x" +
                        RSet(Hex(ExaminedFormatCode, #PB_Ascii), 2, 0) +
                        " as if it was an array !")
        *MsgPackData\LastError = -1
        ProcedureReturn #Null
    EndIf

    Select ExaminedFormatCode
        Case #MsgPack_FormatCode_FixArray:
            ExaminedArraySize = ExaminedFormatCode & $000000000000000F

        Case #MsgPack_FormatCode_Array16:
            If Not _MsgPackHasSpaceLeft(*MsgPackData, BufferSize + 3)
                DebuggerWarning("We have less than 3 bytes to read the Array16's size !")
                ; FIXME: Use the proper one
                *MsgPackData\LastError = -1
                ProcedureReturn #Null
            EndIf

            ExaminedArraySize = PeekU(*MsgPackData\*Buffer + 1)

        Case #MsgPack_FormatCode_Array32:
            If Not _MsgPackHasSpaceLeft(*MsgPackData, BufferSize + 5)
                DebuggerWarning("We have less than 5 bytes to read the Array32's size !")
                ; FIXME: Use the proper one
                *MsgPackData\LastError = -1
                ProcedureReturn #Null
            EndIf

            ; FIXME: WILL CAUSE ISSUES WITH UNSIGNED SHIT !!!
            ExaminedArraySize = PeekI(*MsgPackData\*Buffer + 1)

        Default:
            ; ???
    EndSelect

    ; ???

    
    ; Not implemented yet !
    ProcedureReturn #Null
EndProcedure


Macro MsgPackFinishArray(MsgPackData) : MsgPackFree(MsgPackData, #False) : EndMacro
