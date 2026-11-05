;{- Code Header
; ==- Basic Info -================================
;     Name: _Iterators.pbi
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
XIncludeFile "./_Utils.pbi"
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Binary.pbi"



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
Macro _MsgPackGetFieldDynamicSize_Within(MsgPackData, Mask) : (FastPeekA(MsgPackData\Buffer + MsgPackData\BufferOffset) & Mask) : EndMacro

; Returns the field's dynamic size based on the byte right after the format code.
; Applies to: Str8, Bin8, Ext8
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_1After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 1)
        Debug("We have less than 1 byte to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
EndProcedure

; Returns the field's dynamic size based on the 2 bytes right after the format code.
; Applies to: Str16, Bin16, Ext16, Array16, Map16
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_2After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 2)
        Debug("We have less than 2 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapU(FastPeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
EndProcedure

; Returns the field's dynamic size based on the 4 bytes right after the format code.
; Applies to: Str32, Bin32, Ext32, Array32, Map32
;     Remark: Doesn't apply to Int/UInt variants since those have their own function for extracting the value.
Procedure.q _MsgPackGetFieldDynamicSize_4After(*MsgPackData.MsgPackData)
    If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + 4)
        Debug("We have less than 4 bytes to read the field's dynamic size !")
        ProcedureReturn #MsgPack_InvalidSize
    EndIf

    ProcedureReturn EndianSwapL(FastPeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)) & $FFFFFFFF
EndProcedure

; Returns a given format code's spacing info based on itself and the data in the given MsgPack buffer.
; `*VariableSizeQ` receives the size of str/bin/ext data, or the number of entries in arrays/maps.
; `*ValueStartOffsetB` receives the offset of the value from the format code, ext type excluded.
; Both receive `#MsgPack_InvalidSize` and `#False` is returned for unsupported format codes.
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
        Debug("End of buffer reached, cannot read the field's dynamic size !")
        ExaminedDataType = #MsgPack_FormatCode_Invalid
    EndIf
    
    Select ExaminedDataType
        Case #MsgPack_FormatCode_FixStr:
            If *VariableSizeQ <> #Null
                FastPokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_Within(*MsgPackData, %00011111))
            EndIf
            If *ValueStartOffsetB <> #Null
                FastPokeB(*ValueStartOffsetB, 1)
            EndIf
            ProcedureReturn #True
            
        Case #MsgPack_FormatCode_FixArray,
             #MsgPack_FormatCode_FixMap:
            If *VariableSizeQ <> #Null
                FastPokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_Within(*MsgPackData, %00001111))
            EndIf
            If *ValueStartOffsetB <> #Null
                FastPokeB(*ValueStartOffsetB, 1)
            EndIf
            ProcedureReturn #True
            
            ; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext8,
             #MsgPack_FormatCode_Str8,
             #MsgPack_FormatCode_Bin8:
        	If *VariableSizeQ <> #Null
        		FastPokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_1After(*MsgPackData))
        	EndIf
        	If *ValueStartOffsetB <> #Null
        		FastPokeB(*ValueStartOffsetB, 2)
        	EndIf
        	ProcedureReturn #True
        	
        	; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext16,
             #MsgPack_FormatCode_Str16,
             #MsgPack_FormatCode_Bin16,
             #MsgPack_FormatCode_Array16,
             #MsgPack_FormatCode_Map16:
        	If *VariableSizeQ <> #Null
        		FastPokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_2After(*MsgPackData))    
        	EndIf
        	If *ValueStartOffsetB <> #Null
        		FastPokeB(*ValueStartOffsetB, 3)
        	EndIf
        	ProcedureReturn #True
        	
        	; TODO: Check if it should it add +1 to *ValueStartOffsetB for extensions ?
        Case #MsgPack_FormatCode_Ext32,
             #MsgPack_FormatCode_Str32,
             #MsgPack_FormatCode_Bin32,
             #MsgPack_FormatCode_Array32,
             #MsgPack_FormatCode_Map32:
        	If *VariableSizeQ <> #Null
                FastPokeQ(*VariableSizeQ, _MsgPackGetFieldDynamicSize_4After(*MsgPackData))    
            EndIf
            If *ValueStartOffsetB <> #Null
                FastPokeB(*ValueStartOffsetB, 5)
            EndIf
            ProcedureReturn #True
            
        Default:
            If *VariableSizeQ <> #Null
                FastPokeQ(*VariableSizeQ, #MsgPack_InvalidSize)    
            EndIf
            If *ValueStartOffsetB <> #Null
                FastPokeB(*ValueStartOffsetB, #MsgPack_InvalidSize)
            EndIf
            ProcedureReturn #False
    EndSelect
EndProcedure


;-> Field layout

;-> > Private

; Reads the layout of the field at the current offset, without moving it.
; On success:
;  * `*HeaderSize` receives the length of its format code, size field and ext type.
;  * `*DataSize` receives the length of the data or value following its header.
;  * `*ChildCount` receives the number of fields contained in an array or map, keys included.
; The header and data are guaranteed to be within the buffer, but contained fields aren't checked.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackGetFieldLayout(*MsgPackData.MsgPackData, *HeaderSize.Integer, *DataSize.Quad, *ChildCount.Quad)
	Protected FormatCode.MsgPack_FormatCode
	Protected DataType.MsgPack_DataType
	Protected ChildCount.q
	Protected ValueStartOffset.b

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		Debug("End of buffer reached, cannot check data format code !")
		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn #MsgPack_Error_AtOrPastTheEndOfBuffer
	EndIf

	FormatCode = MsgPackGetFormatCode(*MsgPackData)
	DataType = MsgPackFormatCodeToDataType(FormatCode)

	*HeaderSize\i = 1
	*DataSize\q = 0
	*ChildCount\q = 0

	Select DataType
		Case #MsgPack_DataTypes_Null,
		     #MsgPack_DataTypes_Boolean,
		     #MsgPack_DataTypes_Integer,
		     #MsgPack_DataTypes_Float:
			; Fixints, nil and bools only have their format code.
			Select FormatCode
				Case #MsgPack_FormatCode_UInt8,
				     #MsgPack_FormatCode_Int8:
					*DataSize\q = 1
				Case #MsgPack_FormatCode_UInt16,
				     #MsgPack_FormatCode_Int16:
					*DataSize\q = 2
				Case #MsgPack_FormatCode_UInt32,
				     #MsgPack_FormatCode_Int32,
				     #MsgPack_FormatCode_Float32:
					*DataSize\q = 4
				Case #MsgPack_FormatCode_UInt64,
				     #MsgPack_FormatCode_Int64,
				     #MsgPack_FormatCode_Float64:
					*DataSize\q = 8
			EndSelect

		Case #MsgPack_DataTypes_String,
		     #MsgPack_DataTypes_Binary,
		     #MsgPack_DataTypes_Extension:
			; Also checks that the whole field is within the buffer.
			ProcedureReturn _MsgPackReadSizedFieldHeader(*MsgPackData, DataType, *HeaderSize, *DataSize)

		Case #MsgPack_DataTypes_Array,
		     #MsgPack_DataTypes_Map:
			_MsgPackGetFieldSpacingInfo(*MsgPackData, FormatCode, @ChildCount, @ValueStartOffset)
			If ChildCount = #MsgPack_InvalidSize
				Debug("End of buffer reached, cannot read the field's size !")
				*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
				ProcedureReturn #MsgPack_Error_BufferTooSmall
			EndIf

			If DataType = #MsgPack_DataTypes_Map
				ChildCount = ChildCount * 2
			EndIf

			; Each contained field takes at least 1 byte, bogus counts are rejected right away.
			If ChildCount > *MsgPackData\BufferSize - *MsgPackData\BufferOffset - ValueStartOffset
				Debug("The array or map has more entries than the buffer can hold !")
				*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
				ProcedureReturn #MsgPack_Error_BufferTooSmall
			EndIf

			*HeaderSize\i = ValueStartOffset
			*ChildCount\q = ChildCount

		Default:
			Debug("Invalid format code !  (" + RSet(Hex(FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") + ")")
			*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
			ProcedureReturn #MsgPack_Error_InvalidFormatCode
	EndSelect

	If Not _MsgPackHasSpaceLeft(*MsgPackData, *HeaderSize\i + *DataSize\q)
		Debug("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn #MsgPack_Error_BufferTooSmall
	EndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Checks if a format code byte is the one of an array or map, empty ones included.
Macro _MsgPackIsContainerFormatByte(Byte)
	((Byte & $E0) = $80 Or (Byte >= $DC And Byte <= $DF))
EndMacro

; Fields left to skip at each nesting level, the skipped array or map's own level being `0`.
Structure _MsgPackSkipLevels
	FieldsLeft.q[#MsgPack_MaxDepth + 1]
EndStructure

; Moves the offset past the array or map at the current offset, and all of its contained fields.
; Done iteratively so deeply nested arrays and maps can't overflow the stack.
; Arrays and maps nested deeper than `#MsgPack_MaxDepth`, counting the ones containing the structure, are rejected.
; `FieldsAfter` is the number of fields the caller still has to skip after this one,
;  so the "more fields left than bytes left" check below sees the caller's fields too.
; Only called by `_MsgPackSkipFields()`, which restores the offset on errors.
;     Remark: `Levels` is zero-filled by PureBasic on every call, 1 KB by default,
;             so simple fields are skipped by `_MsgPackSkipFields()` without calling this.
; Sets the structure's error code on errors and returns it.
Procedure.MsgPack_ErrorCode _MsgPackSkipContainer(*MsgPackData.MsgPackData, FieldsAfter.q)
	Protected HeaderSize.i
	Protected DataSize.q
	Protected ChildCount.q
	Protected Level.i = 0
	Protected Levels._MsgPackSkipLevels
	Protected FormatByte.a
	Protected FieldCount.q = 1
	Protected ErrorCode.MsgPack_ErrorCode = #MsgPack_Error_Success

	; `FieldCount` is the total left to skip in the array or map, itself and all levels included.
	Levels\FieldsLeft[0] = FieldCount

	While FieldCount > 0
		; Leaving the arrays and maps whose content was fully skipped.
		While Levels\FieldsLeft[Level] = 0
			Level = Level - 1
		Wend

		ErrorCode = _MsgPackGetFieldLayout(*MsgPackData, @HeaderSize, @DataSize, @ChildCount)
		If ErrorCode <> #MsgPack_Error_Success
			ProcedureReturn ErrorCode
		EndIf

		; Arrays and maps are at depth `Level + 1` from the structure's content.
		FormatByte = FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)
		If _MsgPackIsContainerFormatByte(FormatByte) And *MsgPackData\IteratorDepth + Level + 1 > #MsgPack_MaxDepth
			Debug("Arrays and maps are nested deeper than " + Str(#MsgPack_MaxDepth) + " levels !")
			*MsgPackData\LastError = #MsgPack_Error_MaxDepthExceeded
			ProcedureReturn #MsgPack_Error_MaxDepthExceeded
		EndIf

		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + HeaderSize + DataSize
		FieldCount = FieldCount - 1 + ChildCount
		Levels\FieldsLeft[Level] = Levels\FieldsLeft[Level] - 1
		If ChildCount > 0
			Level = Level + 1
			Levels\FieldsLeft[Level] = ChildCount
		EndIf

		; Each field takes at least 1 byte, which rejects bogus array and map sizes early.
		If FieldCount + FieldsAfter > *MsgPackData\BufferSize - *MsgPackData\BufferOffset
			Debug("End of buffer reached, " + Str(FieldCount + FieldsAfter) + " fields are left to skip !")
			*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
			ProcedureReturn #MsgPack_Error_BufferTooSmall
		EndIf
	Wend

	ProcedureReturn #MsgPack_Error_Success
EndProcedure

; Moves the offset past the next `FieldCount` fields, the ones contained in arrays and maps included.
; Simple fields are skipped here, each array or map is handed to `_MsgPackSkipContainer()`.
; The offset is left untouched on errors.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackSkipFields(*MsgPackData.MsgPackData, FieldCount.q)
	Protected StartOffset.i
	Protected HeaderSize.i
	Protected DataSize.q
	Protected ChildCount.q
	Protected FormatByte.a
	Protected IsContainer.b
	Protected ErrorCode.MsgPack_ErrorCode = #MsgPack_Error_Success

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	StartOffset = *MsgPackData\BufferOffset

	; Each field takes at least 1 byte, which also keeps `FieldCount` far from overflowing below.
	If FieldCount > *MsgPackData\BufferSize - *MsgPackData\BufferOffset And Not _MsgPackIsAtTheEnd(*MsgPackData)
		Debug("End of buffer reached, " + Str(FieldCount) + " fields can't fit !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn #MsgPack_Error_BufferTooSmall
	EndIf

	While FieldCount > 0
		; At the end of the buffer, `_MsgPackGetFieldLayout()` below reports it.
		IsContainer = #False
		If Not _MsgPackIsAtTheEnd(*MsgPackData)
			FormatByte = FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)
			IsContainer = Bool(_MsgPackIsContainerFormatByte(FormatByte))
		EndIf

		If IsContainer
			ErrorCode = _MsgPackSkipContainer(*MsgPackData, FieldCount - 1)
		Else
			ErrorCode = _MsgPackGetFieldLayout(*MsgPackData, @HeaderSize, @DataSize, @ChildCount)
			If ErrorCode = #MsgPack_Error_Success
				*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + HeaderSize + DataSize
			EndIf
		EndIf
		If ErrorCode <> #MsgPack_Error_Success
			Break
		EndIf

		FieldCount = FieldCount - 1

		; Each field takes at least 1 byte.
		If FieldCount > *MsgPackData\BufferSize - *MsgPackData\BufferOffset
			Debug("End of buffer reached, " + Str(FieldCount) + " fields are left to skip !")
			*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
			ErrorCode = #MsgPack_Error_BufferTooSmall
			Break
		EndIf
	Wend

	If ErrorCode <> #MsgPack_Error_Success
		*MsgPackData\BufferOffset = StartOffset
		ProcedureReturn ErrorCode
	EndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


;-> Size getters

; Returns the full size in bytes of the field at the current offset, without moving it.
; Arrays and maps include all of their contained fields, recursively.
; OnError: Returns `#MsgPack_InvalidSize` and sets the `MsgPackData\LastError` field.
Procedure.q MsgPackGetFieldFullSize(*MsgPackData.MsgPackData)
	Protected StartOffset.i
	Protected FullSize.q

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_InvalidSize
		EndIf
	CompilerEndIf

	StartOffset = *MsgPackData\BufferOffset

	If _MsgPackSkipFields(*MsgPackData, 1) <> #MsgPack_Error_Success
		ProcedureReturn #MsgPack_InvalidSize
	EndIf

	FullSize = *MsgPackData\BufferOffset - StartOffset
	*MsgPackData\BufferOffset = StartOffset

	ProcedureReturn FullSize
EndProcedure


; Returns the number of entries in the array or map at the current offset, without moving it.
; Map entries are made of a key and a value, and count as one.
; OnError: Returns `#MsgPack_InvalidSize` and sets the `MsgPackData\LastError` field.
Procedure.q MsgPackGetEntryCount(*MsgPackData.MsgPackData)
	Protected HeaderSize.i
	Protected DataSize.q
	Protected ChildCount.q

	If _MsgPackGetFieldLayout(*MsgPackData, @HeaderSize, @DataSize, @ChildCount) <> #MsgPack_Error_Success
		ProcedureReturn #MsgPack_InvalidSize
	EndIf

	Select MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*MsgPackData))
		Case #MsgPack_DataTypes_Array:
			ProcedureReturn ChildCount
		Case #MsgPack_DataTypes_Map:
			ProcedureReturn ChildCount / 2
	EndSelect

	Debug("Unexpected format code !  (" + RSet(Hex(FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") + ")")
	*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
	ProcedureReturn #MsgPack_InvalidSize
EndProcedure


;-> Navigation

; Moves the offset past the next `FieldCount` fields, the ones contained in arrays and maps included.
; Map keys and values count as separate fields.
; Returns `#MsgPack_Error_Success` on success, something else otherwise, in which case the offset isn't moved.
Procedure.MsgPack_ErrorCode MsgPackSkip(*MsgPackData.MsgPackData, FieldCount.q = 1)
	Protected ErrorCode.MsgPack_ErrorCode

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If FieldCount < 0
		DebuggerWarning("Cannot skip a negative amount of fields !")
		*MsgPackData\LastError = #MsgPack_Error_InvalidValue
		ProcedureReturn #MsgPack_Error_InvalidValue
	EndIf

	ErrorCode = _MsgPackSkipFields(*MsgPackData, FieldCount)
	If ErrorCode = #MsgPack_Error_Success
		*MsgPackData\IteratorFieldsRead = *MsgPackData\IteratorFieldsRead + FieldCount
	EndIf

	ProcedureReturn ErrorCode
EndProcedure


;-> Iterators

; Prepares a view over the array or map at the current offset, to iterate on it with `MsgPackNextEntry()`.
; The view reads straight from the given structure's buffer, which must not be grown or freed while it is used.
; Its size is limited to the array or map's content, so reads can't go past it.
; The whole array or map is checked beforehand, and the offset is moved past it.
; `#MsgPack_ExaminationOptions_Unsafe` skips that check, which isn't recommended, see its definition.
; Returns: A view that must be freed with `MsgPackFinish()`.
; OnError: Returns `#Null` and sets the `MsgPackData\LastError` field.
Procedure.i MsgPackExamine(*MsgPackData.MsgPackData, ExaminationOptions.MsgPack_ExaminationOption = 0)
	Protected DataType.MsgPack_DataType
	Protected HeaderSize.i
	Protected DataSize.q
	Protected ChildCount.q
	Protected StartOffset.i
	Protected EndOffset.i
	Protected IsUnsafe.b
	Protected *View.MsgPackData

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #Null
		EndIf
	CompilerEndIf

	If _MsgPackGetFieldLayout(*MsgPackData, @HeaderSize, @DataSize, @ChildCount) <> #MsgPack_Error_Success
		ProcedureReturn #Null
	EndIf

	DataType = MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*MsgPackData))
	If DataType <> #MsgPack_DataTypes_Array And DataType <> #MsgPack_DataTypes_Map
		Debug("Attempted to examine format code 0x" +
		      RSet(Hex(FastPeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		      " as if it was an array or map !")
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn #Null
	EndIf

	; Unsafe views aren't checked beforehand, nesting them is limited here.
	If *MsgPackData\IteratorDepth >= #MsgPack_MaxDepth
		Debug("Arrays and maps are nested deeper than " + Str(#MsgPack_MaxDepth) + " levels !")
		*MsgPackData\LastError = #MsgPack_Error_MaxDepthExceeded
		ProcedureReturn #Null
	EndIf

	StartOffset = *MsgPackData\BufferOffset
	IsUnsafe = Bool(ExaminationOptions & #MsgPack_ExaminationOptions_Unsafe)

	If IsUnsafe
		; The end is unknown, the view is only limited by `IteratorFieldsLeft` until it is reached.
		EndOffset = *MsgPackData\BufferSize
	Else
		; Seeking the end of the array or map, which also checks all of its content.
		If _MsgPackSkipFields(*MsgPackData, 1) <> #MsgPack_Error_Success
			ProcedureReturn #Null
		EndIf
		EndOffset = *MsgPackData\BufferOffset
	EndIf

	*View = AllocateStructure(MsgPackData)
	If Not *View
		Debug("Failed to allocate memory for the view !")
		*MsgPackData\BufferOffset = StartOffset
		*MsgPackData\LastError = #MsgPack_Error_FailedToAllocateBuffer
		ProcedureReturn #Null
	EndIf

	*View\Buffer = *MsgPackData\Buffer + StartOffset + HeaderSize
	*View\BufferSize = EndOffset - StartOffset - HeaderSize
	*View\BufferOffset = 0
	*View\BufferGrowthIncrement = 1
	*View\DataFlags = #_MsgPack_ViewDataFlags
	*View\IteratorEntryOffset = #MsgPack_InvalidSize
	*View\IteratorFieldsLeft = ChildCount
	*View\IteratorDepth = *MsgPackData\IteratorDepth + 1

	If DataType = #MsgPack_DataTypes_Map
		*View\DataFlags = *View\DataFlags | #MsgPack_DataFlags_CanProvideKeys
	EndIf

	If IsUnsafe Or Not _MsgPackHasFlag(*MsgPackData, #MsgPack_DataFlags_MoveOffsetAfterRead)
		*MsgPackData\BufferOffset = StartOffset
	Else
		*MsgPackData\IteratorFieldsRead = *MsgPackData\IteratorFieldsRead + 1
	EndIf

	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn *View
EndProcedure


; Moves a view's offset to its next entry, skipping whatever wasn't read from the current one.
; The entry can then be read with the regular procedures, key first for maps.
; Nested arrays and maps can be examined or left as-is, they'll be skipped.
; Returns: `#True` if an entry is available, `#False` once the end of the view is reached.
; OnError: Returns `#False` and sets the `MsgPackData\LastError` field.
Procedure.b MsgPackNextEntry(*Iterator.MsgPackData)
	Protected FieldsPerEntry.q = 1
	Protected FieldsToSkip.q

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *Iterator
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #False
		EndIf
	CompilerEndIf

	If Not _MsgPackHasFlag(*Iterator, #MsgPack_DataFlags_Iterator)
		DebuggerError("The given MsgPackData isn't a view from `MsgPackExamine()` !")
		*Iterator\LastError = #MsgPack_Error_InvalidValue
		ProcedureReturn #False
	EndIf

	If *Iterator\IteratorEntryOffset = #MsgPack_InvalidSize
		; First call, the first entry is at the very start of the view.
		*Iterator\IteratorEntryOffset = 0
	ElseIf *Iterator\IteratorFieldsLeft > 0
		If _MsgPackHasFlag(*Iterator, #MsgPack_DataFlags_CanProvideKeys)
			FieldsPerEntry = 2
		EndIf

		; Only the fields that weren't read are skipped, from where the reads left the offset.
		; Reading past the entry falls back to skipping all of it from its start.
		If *Iterator\IteratorFieldsRead > FieldsPerEntry
			*Iterator\BufferOffset = *Iterator\IteratorEntryOffset
			FieldsToSkip = FieldsPerEntry
		Else
			FieldsToSkip = FieldsPerEntry - *Iterator\IteratorFieldsRead
		EndIf

		If FieldsToSkip > 0
			If _MsgPackSkipFields(*Iterator, FieldsToSkip) <> #MsgPack_Error_Success
				; Failing again from the entry's start, so the error doesn't depend on what was read,
				;  the "more fields left than bytes left" check may catch it earlier from there.
				*Iterator\BufferOffset = *Iterator\IteratorEntryOffset
				_MsgPackSkipFields(*Iterator, FieldsPerEntry)
				ProcedureReturn #False
			EndIf
		EndIf
		*Iterator\IteratorEntryOffset = *Iterator\BufferOffset
		*Iterator\IteratorFieldsLeft = *Iterator\IteratorFieldsLeft - FieldsPerEntry
	EndIf

	*Iterator\BufferOffset = *Iterator\IteratorEntryOffset
	*Iterator\IteratorFieldsRead = 0
	*Iterator\LastError = #MsgPack_Error_Success

	If *Iterator\IteratorFieldsLeft <= 0
		; Unsafe views only find their end here, so reads can't go past it afterward.
		*Iterator\BufferSize = *Iterator\IteratorEntryOffset
		ProcedureReturn #False
	EndIf

	; Unsafe views can announce more entries than their buffer holds.
	If *Iterator\IteratorEntryOffset >= *Iterator\BufferSize
		Debug("End of buffer reached, the remaining entries are missing !")
		*Iterator\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn #False
	EndIf

	ProcedureReturn #True
EndProcedure


Macro MsgPackFinish(Iterator) : MsgPackFree(Iterator, #False) : EndMacro


;-> Setters

;-> > Private

; Used in place of a size field's length to pick the smallest one that fits.
#_MsgPack_SmallestSizeField = $FF

; Counts the fields in the `BufferSize` bytes at `*Buffer`, the ones contained in arrays and maps excluded.
; The whole data is checked, and must end on a field's boundary.
; Returns: The number of fields.
; OnError: Returns `#MsgPack_InvalidSize` and sets the `MsgPackData\LastError` field.
Procedure.q _MsgPackCountFields(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	Protected Source.MsgPackData
	Protected FieldCount.q = 0

	If BufferSize < 0
		DebuggerWarning("Received negative size !")
		*MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn #MsgPack_InvalidSize
	ElseIf BufferSize > #_MsgPack_MaxIntegerValue
		DebuggerWarning("Requested size can't be addressed: " + Str(BufferSize))
		*MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn #MsgPack_InvalidSize
	EndIf

	CompilerIf Not #MsgPack_DisableNullChecks
		If BufferSize > 0 And Not *Buffer
			DebuggerError("A #Null data buffer was passed !")
			*MsgPackData\LastError = #MsgPack_Error_NullPointerGiven
			ProcedureReturn #MsgPack_InvalidSize
		EndIf
	CompilerEndIf

	; Temporary wrapper, so the regular procedures can walk the data.
	Source\Buffer = *Buffer
	Source\BufferSize = BufferSize
	; The fields will be in the written array or map, so the result stays within `#MsgPack_MaxDepth`.
	Source\IteratorDepth = 1

	While Not _MsgPackIsAtTheEnd(Source)
		If _MsgPackSkipFields(@Source, 1) <> #MsgPack_Error_Success
			*MsgPackData\LastError = Source\LastError
			ProcedureReturn #MsgPack_InvalidSize
		EndIf
		FieldCount = FieldCount + 1
	Wend

	ProcedureReturn FieldCount
EndProcedure


; Writes an array or map whose content is a copy of the `BufferSize` bytes of MessagePack data at `*Buffer`.
; Map content must hold an even number of fields, alternating keys and values.
; `SizeFieldByteLength` follows the "sized field" helpers' convention, `0` being FixArray and FixMap,
;  or is `#_MsgPack_SmallestSizeField` to use the smallest format code that fits.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteContainer(*MsgPackData.MsgPackData, IsMap.b, SizeFieldByteLength.a, *Buffer, BufferSize.q)
	Protected EntryCount.q
	Protected MaxEntryCount.q
	Protected FormatCode.MsgPack_FormatCode
	Protected ErrorCode.MsgPack_ErrorCode

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	; The content's address would be invalidated when growing.
	If _MsgPackOverlapsBuffer(*MsgPackData, *Buffer, BufferSize)
		DebuggerError("Cannot write content located in the destination's own buffer !")
		*MsgPackData\LastError = #MsgPack_Error_InvalidValue
		ProcedureReturn #MsgPack_Error_InvalidValue
	EndIf

	EntryCount = _MsgPackCountFields(*MsgPackData, *Buffer, BufferSize)
	If EntryCount = #MsgPack_InvalidSize
		ProcedureReturn *MsgPackData\LastError
	EndIf

	If IsMap
		If EntryCount % 2 <> 0
			Debug("Map content has an odd number of fields (" + Str(EntryCount) + "), keys and values must be paired !")
			*MsgPackData\LastError = #MsgPack_Error_OddMapFieldCount
			ProcedureReturn #MsgPack_Error_OddMapFieldCount
		EndIf
		EntryCount = EntryCount / 2
	EndIf

	If SizeFieldByteLength = #_MsgPack_SmallestSizeField
		If EntryCount <= 15
			SizeFieldByteLength = 0
		ElseIf EntryCount <= 65535
			SizeFieldByteLength = 2
		Else
			SizeFieldByteLength = 4
		EndIf
	EndIf

	Select SizeFieldByteLength
		Case 0 :
			MaxEntryCount = 15
			FormatCode = #MsgPack_FormatCode_FixArray
			If IsMap : FormatCode = #MsgPack_FormatCode_FixMap : EndIf
		Case 2 :
			MaxEntryCount = 65535
			FormatCode = #MsgPack_FormatCode_Array16
			If IsMap : FormatCode = #MsgPack_FormatCode_Map16 : EndIf
		Case 4 :
			MaxEntryCount = 4294967295
			FormatCode = #MsgPack_FormatCode_Array32
			If IsMap : FormatCode = #MsgPack_FormatCode_Map32 : EndIf
		Default
			DebuggerError("Invalid size field length: " + Str(SizeFieldByteLength))
			*MsgPackData\LastError = #MsgPack_Error_InvalidValue
			ProcedureReturn #MsgPack_Error_InvalidValue
	EndSelect

	If EntryCount > MaxEntryCount
		DebuggerWarning("Content has more than " + Str(MaxEntryCount) + " entries !")
		*MsgPackData\LastError = #MsgPack_Error_TooManyEntries
		ProcedureReturn #MsgPack_Error_TooManyEntries
	EndIf

	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 1 + SizeFieldByteLength + BufferSize)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	; Each field takes at least 1 byte, so the header won't reserve more than what was reserved above.
	ErrorCode = _MsgPackWriteSizedFieldHeader(*MsgPackData, FormatCode, SizeFieldByteLength, EntryCount)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	If BufferSize > 0
		CopyMemory(*Buffer, *MsgPackData\Buffer + *MsgPackData\BufferOffset, BufferSize)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + BufferSize
	EndIf
	_MsgPackRewindOffsetAfterWrite(*MsgPackData, 1 + SizeFieldByteLength + BufferSize)

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


;-> > Public

; Writes an array whose entries are the fields in the `BufferSize` bytes of MessagePack data at `*Buffer`,
;  using the smallest array format code that fits.
; `*Buffer` can come from `MsgPackFinalize()`, with `MemorySize()` as its size.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteArray(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteContainer(*MsgPackData, #False, #_MsgPack_SmallestSizeField, *Buffer, BufferSize)
EndProcedure


; Same as `MsgPackWriteArray()`, for maps.
; The data must hold an even number of fields, alternating keys and values.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteMap(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteContainer(*MsgPackData, #True, #_MsgPack_SmallestSizeField, *Buffer, BufferSize)
EndProcedure


; Same as `MsgPackWriteArray()`, with the data written so far in `*Source`.
; `*Source` is left untouched and must be freed by the caller.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteArrayFrom(*MsgPackData.MsgPackData, *Source.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData Or Not *Source
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	ProcedureReturn MsgPackWriteArray(*MsgPackData, *Source\Buffer, *Source\BufferOffset)
EndProcedure


; Same as `MsgPackWriteMap()`, with the data written so far in `*Source`.
; `*Source` is left untouched and must be freed by the caller.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteMapFrom(*MsgPackData.MsgPackData, *Source.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData Or Not *Source
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	ProcedureReturn MsgPackWriteMap(*MsgPackData, *Source\Buffer, *Source\BufferOffset)
EndProcedure


;-> Macros

; Same as `MsgPackWriteArray()` and `MsgPackWriteMap()`, but force the given format code.

Macro MsgPackWriteFixArray(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #False, 0, Buffer, BufferSize)
EndMacro

Macro MsgPackWriteArray16(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #False, 2, Buffer, BufferSize)
EndMacro

Macro MsgPackWriteArray32(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #False, 4, Buffer, BufferSize)
EndMacro

Macro MsgPackWriteFixMap(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #True, 0, Buffer, BufferSize)
EndMacro

Macro MsgPackWriteMap16(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #True, 2, Buffer, BufferSize)
EndMacro

Macro MsgPackWriteMap32(MsgPackData, Buffer, BufferSize)
	_MsgPackWriteContainer(MsgPackData, #True, 4, Buffer, BufferSize)
EndMacro
