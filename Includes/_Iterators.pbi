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

; Returns the field's size that is included in the field's format code like `[XXXYYYY]` where
;  `XXX` is the format code bits and `YYYYY` the value's dynamic size.
; Applies to: FixStr, FixArray, FixMap
;     Remark: Doesn't apply to FixInt variants since those have their own function for extracting the value.
Macro _MsgPackGetFieldDynamicSize_Within(MsgPackData, Mask) : (PeekA(MsgPackData\Buffer + MsgPackData\BufferOffset) & Mask) : EndMacro

; Returns the field's dynamic size based on the byte right after the format code.
; Applies to: Str8, Bin8, Ext8
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_1After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 1)
        DebuggerWarning("We have less than 1 byte to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
EndProcedure

; Returns the field's dynamic size based on the 2 bytes right after the format code.
; Applies to: Str16, Bin16, Ext16, Array16, Map16
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_2After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 2)
        DebuggerWarning("We have less than 2 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapU(PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
EndProcedure

; Returns the field's dynamic size based on the 4 bytes right after the format code.
; Applies to: Str32, Bin32, Ext32, Array32, Map32
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_4After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 4)
        DebuggerWarning("We have less than 4 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapL(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)) & $FFFFFFFF
EndProcedure

; Returns a given format code's spacing info based on itself and the data in the given MsgPack buffer.
; ???
;     Remark: Doesn't apply to FixInt/Int/UInt variants since those have their own function for extracting the value.
Procedure _MsgPackGetFieldSpacingInfo(*MsgPackData.MsgPackData, ExaminedDataType.MsgPack_FormatCode, *VariableSizeQ = #Null, *ValueStartOffsetB = #Null)
    CompilerIf Not #MsgPack_DisableNullChecks
        If Not *MsgPackData
            DebuggerError("A #Null MsgPackData pointer was passed !")
            ProcedureReturn #False
        EndIf
    CompilerEndIf
    
    If *MsgPackData = #Null Or (*VariableSizeQ = #Null And *ValueStartOffsetB = #Null)
        ProcedureReturn #False
    EndIf
    
    ; The "within" sizes are read from the format code, which must be in the buffer.
    If _MsgPackIsAtTheEnd(*MsgPackData)
        DebuggerWarning("End of buffer reached, cannot read the field's dynamic size !")
        ExaminedDataType = #MsgPack_FormatCode_Invalid
    EndIf
    
    Select ExaminedDataType
        Case #MsgPack_FormatCode_FixIntPositive:
            If *VariableSizeQ <> #Null
                PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_Within(*MsgPackData, %01111111))
            EndIf
            If *ValueStartOffsetB <> #Null
            	; FIXME: Is this right ?!?
                PokeB(*ValueStartOffsetB, 1)
            EndIf
            ProcedureReturn #True
            
        Case #MsgPack_FormatCode_FixStr,
             #MsgPack_FormatCode_FixIntNegative:
            If *VariableSizeQ <> #Null
                PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_Within(*MsgPackData, %00011111))
            EndIf
            If *ValueStartOffsetB <> #Null
                PokeB(*ValueStartOffsetB, 1)
            EndIf
            ProcedureReturn #True
            
        Case #MsgPack_FormatCode_FixArray,
             #MsgPack_FormatCode_FixMap:
            If *VariableSizeQ <> #Null
                PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_Within(*MsgPackData, %00001111))
            EndIf
            If *ValueStartOffsetB <> #Null
                PokeB(*ValueStartOffsetB, 1)
            EndIf
            ProcedureReturn #True
            
            ; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext8,
             #MsgPack_FormatCode_Str8,
             #MsgPack_FormatCode_Bin8:
        	If *VariableSizeQ <> #Null
        		PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_1After(*MsgPackData))
        	EndIf
        	If *ValueStartOffsetB <> #Null
        		PokeB(*ValueStartOffsetB, 2)
        	EndIf
        	ProcedureReturn #True
        	
        	; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext16,
             #MsgPack_FormatCode_Str16,
             #MsgPack_FormatCode_Bin16,
             #MsgPack_FormatCode_Array16,
             #MsgPack_FormatCode_Map16:
        	If *VariableSizeQ <> #Null
        		PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_2After(*MsgPackData))    
        	EndIf
        	If *ValueStartOffsetB <> #Null
        		PokeB(*ValueStartOffsetB, 3)
        	EndIf
        	ProcedureReturn #True
        	
        	; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext32,
             #MsgPack_FormatCode_Str32,
             #MsgPack_FormatCode_Bin32,
             #MsgPack_FormatCode_Array32,
             #MsgPack_FormatCode_Map32:
        	If *VariableSizeQ <> #Null
                PokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_4After(*MsgPackData))    
            EndIf
            If *ValueStartOffsetB <> #Null
                PokeB(*ValueStartOffsetB, 5)
            EndIf
            ProcedureReturn #True
            
        Default:
            If *VariableSizeQ <> #Null
                PokeQ(*VariableSizeQ, #MsgPack_InvalidSize)    
            EndIf
            If *ValueStartOffsetB <> #Null
                PokeB(*ValueStartOffsetB, #MsgPack_InvalidSize)
            EndIf
            ProcedureReturn #False
    EndSelect
EndProcedure


;-> > Public

; NOTE: Not sure if making this public is useful :/
Procedure.q MsgPackGetFieldDynamicSize(*MsgPackData.MsgPackData, ExaminedDataType.MsgPack_FormatCode)
    Protected ReturnedValue.q = 0
    _MsgPackGetFieldSpacingInfo(*MsgPackData, ExaminedDataType, @ReturnedValue, #Null)
    ProcedureReturn ReturnedValue
EndProcedure


;-> Size getters

Procedure.q MsgPackGetFieldFullSize(*MsgPackData.MsgPackData)
    Protected IsIterable = #False
    Protected HasVariableSize = #False
    
    Protected FieldVariableSize.q = #MsgPack_InvalidSize
    Protected FieldValueOffset.b = #MsgPack_InvalidSize
    Protected FullFieldSize.q = 0

    Protected ExaminedFormatCode.MsgPack_FormatCode
    
    ; Safety checks
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	; Preparing stuff
    *MsgPackData\LastError = #MsgPack_Error_Success
    ExaminedFormatCode = MsgPackGetFormatCode(*MsgPackData)
    
    ; Determining iterability for later
    If (ExaminedFormatCode >= #MsgPack_FormatCode_Array16 And ExaminedFormatCode <= #MsgPack_FormatCode_Map32) Or
       (ExaminedFormatCode = #MsgPack_FormatCode_FixArray Or ExaminedFormatCode = #MsgPack_FormatCode_FixMap)
        IsIterable = #True
    EndIf
    
    ; We ignore the returned boolean since we maw not care about this result later down the line.
    _MsgPackGetFieldSpacingInfo(*MsgPackData, ExaminedFormatCode, @FieldVariableSize, @FieldValueOffset)
    
    If IsIterable
        ; Iterables, we'll have to go recursive
        ; They're also all using variable sizes.
        DebuggerError("Getting an iterable field's full size isn't implemented yet !")
        
    ElseIf FieldVariableSize = -1
        ; Simple fixed-size field, we'll have to determine the size 
        
    Else
        ; Variable size field
        
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
                        RSet(Hex(ExaminedFormatCode, #PB_Ascii), 2, "0") +
                        " as if it was an array !")
        *MsgPackData\LastError = -1
        ProcedureReturn #Null
    EndIf

    Select ExaminedFormatCode
        Case #MsgPack_FormatCode_FixArray:
            ExaminedArraySize = ExaminedFormatCode & $000000000000000F

        Case #MsgPack_FormatCode_Array16:
            If Not _MsgPackHasSpaceLeft(*MsgPackData, *MsgPackData\BufferSize + 3)
                DebuggerWarning("We have less than 3 bytes to read the Array16's size !")
                ; FIXME: Use the proper one
                *MsgPackData\LastError = -1
                ProcedureReturn #Null
            EndIf

            ExaminedArraySize = PeekU(*MsgPackData\Buffer + 1)

        Case #MsgPack_FormatCode_Array32:
            If Not _MsgPackHasSpaceLeft(*MsgPackData, *MsgPackData\BufferSize + 5)
                DebuggerWarning("We have less than 5 bytes to read the Array32's size !")
                ; FIXME: Use the proper one
                *MsgPackData\LastError = -1
                ProcedureReturn #Null
            EndIf

            ; FIXME: WILL CAUSE ISSUES WITH UNSIGNED SHIT !!!
            ExaminedArraySize = PeekI(*MsgPackData\Buffer + 1)

        Default:
            ; ???
    EndSelect

    ; ???

    
    ; Not implemented yet !
    ProcedureReturn #Null
EndProcedure


Macro MsgPackFinishArray(MsgPackData) : MsgPackFree(MsgPackData, #False) : EndMacro
