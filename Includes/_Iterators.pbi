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
;- Procedures

;-> Utils

;-> Dynamic size getters

;-> > Private

; /!\ Do not use outside of this file /!\ 
; /!\ All macro/procedure here assume the caller has checked for null and that the format code is valid for this /!\

Macro _MsgPackGetValueDynamicSize_Within(MsgPackData, Mask) : ((MsgPackData\*Buffer + *MsgPackData\BufferOffset) & Mask) : EndMacro

Procedure.q _MsgPackGetValueDynamicSize_1After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, *MsgPackData\BufferSize + 1)
        DebuggerWarning("We have less than 1 byte to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
EndProcedure

Procedure.q _MsgPackGetValueDynamicSize_2After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, *MsgPackData\BufferSize + 2)
        DebuggerWarning("We have less than 2 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapU(PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
EndProcedure

; Do not use outside of this file !!!
Procedure.q _MsgPackGetValueDynamicSize_4After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, *MsgPackData\BufferSize + 4)
        DebuggerWarning("We have less than 4 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapL(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
EndProcedure


;-> > Public

Procedure.q MsgPackGetValueDynamicSize(*MsgPackData.MsgPackData, ExaminedDataType.MsgPack_FormatCode)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

    Select ExaminedDataType
        Case #MsgPack_FormatCode_FixIntPositive:
            ProcedureReturn _MsgPackGetValueDynamicSize_Within(*MsgPackData, %01111111)
            
        Case #MsgPack_FormatCode_FixStr:
        Case #MsgPack_FormatCode_FixIntNegative:
            ProcedureReturn _MsgPackGetValueDynamicSize_Within(*MsgPackData, %00011111)
            
        Case #MsgPack_FormatCode_FixArray:
        Case #MsgPack_FormatCode_FixMap:
            ProcedureReturn _MsgPackGetValueDynamicSize_Within(*MsgPackData, %00001111)
            
        Case #MsgPack_FormatCode_Str8:
        Case #MsgPack_FormatCode_Bin8:
        Case #MsgPack_FormatCode_Ext8:
            ProcedureReturn _MsgPackGetValueDynamicSize_1After(*MsgPackData)
            
        Case #MsgPack_FormatCode_Str16:
        Case #MsgPack_FormatCode_Bin16:
        Case #MsgPack_FormatCode_Array16:
        Case #MsgPack_FormatCode_Map16:
        Case #MsgPack_FormatCode_Ext16:
            ProcedureReturn _MsgPackGetValueDynamicSize_2After(*MsgPackData)
            
        Case #MsgPack_FormatCode_Str32:
        Case #MsgPack_FormatCode_Bin32:
        Case #MsgPack_FormatCode_Array32:
        Case #MsgPack_FormatCode_Map32:
        Case #MsgPack_FormatCode_Ext32:
            ProcedureReturn _MsgPackGetValueDynamicSize_4After(*MsgPackData)

        Default:
            ProcedureReturn #MsgPack_InvalidSize
    EndSelect

EndProcedure


;-> Size getters

Procedure.q MsgPackGetFieldFullSize(*MsgPackData.MsgPackData)
    Protected HasVariableSize = #False
    Protected FullFieldSize.q = 0

    Protected ExaminedFormatCode.MsgPack_FormatCode
	
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
; MsgPackNext(MaximalDepth)


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
