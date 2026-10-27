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
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Utils.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Internal helpers

; Ensures `Size` bytes can be written at the current offset, growing the buffer by
;  exactly the missing amount if needed.
; Sets the structure's error code and returns it.
; FIXME: Move elsewhere since it's used in multiple places !
Procedure.MsgPack_ErrorCode _MsgPackReserveWrite(*MsgPackData.MsgPackData, Size.i)
	Protected MissingSize.i
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf
	
	MissingSize = (*MsgPackData\BufferOffset + Size) - *MsgPackData\BufferSize
	If MissingSize > 0
		; The structure's error code field is set by the called function !
		ProcedureReturn MsgPackGrow(*MsgPackData, MissingSize)
	EndIf
	
	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Checks that a value with the given `FormatCode` and total `Size` (format code included)
;  can be read at the current offset.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackExpectRead(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, Size.i)
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
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> FormatCode
		Debug("Unexpected format code !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(FormatCode), 2, "0") + ")")
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn #MsgPack_Error_InvalidFormatCode
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, Size)
		Debug("End of buffer reached, cannot read out of bounds !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn #MsgPack_Error_BufferTooSmall
	EndIf
	
	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure



; The "fixed field" helpers below handle every `[FormatCode][Value]` layout
;  shared by the int and float families.
; The `ValueByteLength` parameter is the number of bytes used to store the value:
;  * `0` - Value is stored in the format code's lower bits. (FixIntPositive, FixIntNegative)
;  * `1` - UInt8, Int8
;  * `2` - UInt16, Int16
;  * `4` - UInt32, Int32, Float32
;  * `8` - UInt64, Int64, Float64
; Values are passed around as raw bits in a quad, floats included.

; Reserves space for the whole field, writes its format code and big-endian value,
;  and moves the offset right after them.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteFixedField(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, ValueByteLength.a, Value.q)
	Protected ErrorCode.MsgPack_ErrorCode

	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 1 + ValueByteLength)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	Select ValueByteLength
		Case 0
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode | (Value & $FF))
		Case 1
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
		Case 2
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapU16(Value))
		Case 4
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI32(Value))
		Case 8
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI64(Value))
	EndSelect
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1 + ValueByteLength

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Reads the value of the field at the current offset if its format code is `FormatCode`.
; Doesn't support fixints, since their format code varies with the value.
; Returns: The value's raw bits, zero-extended. (e.g.: `$FF` for an Int8 `-1`)
; OnError: Returns `0` and sets the `MsgPackData\LastError` field.
Procedure.q _MsgPackReadFixedField(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, ValueByteLength.a)
	Protected ReturnedValue.q

	If _MsgPackExpectRead(*MsgPackData, FormatCode, 1 + ValueByteLength) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf

	Select ValueByteLength
		Case 1
			ReturnedValue = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
		Case 2
			ReturnedValue = EndianSwapU16(PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
		Case 4
			ReturnedValue = EndianSwapI32(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)) & $FFFFFFFF
		Case 8
			ReturnedValue = EndianSwapI64(PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	EndSelect
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1 + ValueByteLength

	ProcedureReturn ReturnedValue
EndProcedure



;-> Getters & Setters

;-> > UInt8
Procedure.MsgPack_ErrorCode MsgPackWriteUInt8(*MsgPackData.MsgPackData, Value.a)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt8, 1, Value)
EndProcedure


Procedure.a MsgPackReadUInt8(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt8, 1)
EndProcedure


;-> > Int8
Procedure.MsgPack_ErrorCode MsgPackWriteInt8(*MsgPackData.MsgPackData, Value.b)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int8, 1, Value)
EndProcedure


Procedure.b MsgPackReadInt8(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Int8, 1)
EndProcedure


;-> > UInt16
Procedure.MsgPack_ErrorCode MsgPackWriteUInt16(*MsgPackData.MsgPackData, Value.u)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt16, 2, Value)
EndProcedure


Procedure.u MsgPackReadUInt16(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt16, 2)
EndProcedure


;-> > > Int16
Procedure.MsgPack_ErrorCode MsgPackWriteInt16(*MsgPackData.MsgPackData, Value.w)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int16, 2, Value)
EndProcedure


Procedure.w MsgPackReadInt16(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Int16, 2)
EndProcedure


;-> > > UInt32
; No unsigned Long in PureBasic: value is peeked/poked as-is via .l and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt32(*MsgPackData.MsgPackData, Value.l)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt32, 4, Value)
EndProcedure


Procedure.l MsgPackReadUInt32(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt32, 4)
EndProcedure


;-> > > Int32
Procedure.MsgPack_ErrorCode MsgPackWriteInt32(*MsgPackData.MsgPackData, Value.l)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int32, 4, Value)
EndProcedure


Procedure.l MsgPackReadInt32(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Int32, 4)
EndProcedure


;-> > > UInt64
; No unsigned Quad in PureBasic: value is peeked/poked as-is via .q and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt64(*MsgPackData.MsgPackData, Value.q)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt64, 8, Value)
EndProcedure


Procedure.q MsgPackReadUInt64(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt64, 8)
EndProcedure


;-> > > Int64
Procedure.MsgPack_ErrorCode MsgPackWriteInt64(*MsgPackData.MsgPackData, Value.q)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int64, 8, Value)
EndProcedure


Procedure.q MsgPackReadInt64(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Int64, 8)
EndProcedure


;-> > > FixInt

; Writes `Value` as a positive (`0` to `127`) or negative (`-32` to `-1`) fixint.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteFixInt(*MsgPackData.MsgPackData, Value.q)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If Value >= 0 And Value <= 127
		ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_FixIntPositive, 0, Value)
	ElseIf Value >= -32 And Value < 0
		ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_FixIntNegative, 0, Value)
	EndIf

	DebuggerWarning("Value doesn't fit in a fixint: " + Str(Value))
	*MsgPackData\LastError = #MsgPack_Error_ValueOverflow
	ProcedureReturn #MsgPack_Error_ValueOverflow
EndProcedure


;-> > > Any integer

; Writes `Value` using the smallest int format code that fits.
; Positive values always use the unsigned format codes, as recommended by the spec.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
; Remark: UInt64 values above `(2^63)-1` must be written with `MsgPackWriteUInt64()`.
Procedure.MsgPack_ErrorCode MsgPackWriteInteger(*MsgPackData.MsgPackData, Value.q)
	If Value >= 0
		If Value <= 127
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_FixIntPositive, 0, Value)
		ElseIf Value <= 255
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt8, 1, Value)
		ElseIf Value <= 65535
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt16, 2, Value)
		ElseIf Value <= 4294967295
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt32, 4, Value)
		Else
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_UInt64, 8, Value)
		EndIf
	Else
		If Value >= -32
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_FixIntNegative, 0, Value)
		ElseIf Value >= -128
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int8, 1, Value)
		ElseIf Value >= -32768
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int16, 2, Value)
		ElseIf Value >= -2147483648
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int32, 4, Value)
		Else
			ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Int64, 8, Value)
		EndIf
	EndIf
EndProcedure


; Reads any int field at the current offset, fixints included.
; Returns: The value as a signed quad.
; OnError: Returns `0` and sets the `MsgPackData\LastError` field.
;          UInt64 values above `(2^63)-1` fail with `#MsgPack_Error_ValueOverflow` and
;           leave the offset untouched, so they can be read with `MsgPackReadUInt64()`.
Procedure.q MsgPackReadInteger(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		Debug("End of buffer reached, cannot check data format code !")
		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn 0
	EndIf

	Select MsgPackGetFormatCode(*MsgPackData)
		Case #MsgPack_FormatCode_FixIntPositive,
		     #MsgPack_FormatCode_FixIntNegative:
			; The whole byte is the value, both ranges are valid signed bytes.
			ReturnedValue = PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset)
			*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
			*MsgPackData\LastError = #MsgPack_Error_Success
			ProcedureReturn ReturnedValue
		Case #MsgPack_FormatCode_UInt8:
			ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt8, 1)
		Case #MsgPack_FormatCode_UInt16:
			ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt16, 2)
		Case #MsgPack_FormatCode_UInt32:
			ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt32, 4)
		Case #MsgPack_FormatCode_UInt64:
			If _MsgPackHasSpaceLeft(*MsgPackData, 9) And (PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1) & $80)
				Debug("UInt64 value doesn't fit in a signed quad !")
				*MsgPackData\LastError = #MsgPack_Error_ValueOverflow
				ProcedureReturn 0
			EndIf
			ProcedureReturn _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_UInt64, 8)
		Case #MsgPack_FormatCode_Int8:
			ProcedureReturn MsgPackReadInt8(*MsgPackData)
		Case #MsgPack_FormatCode_Int16:
			ProcedureReturn MsgPackReadInt16(*MsgPackData)
		Case #MsgPack_FormatCode_Int32:
			ProcedureReturn MsgPackReadInt32(*MsgPackData)
		Case #MsgPack_FormatCode_Int64:
			ProcedureReturn MsgPackReadInt64(*MsgPackData)
	EndSelect

	Debug("Unexpected format code !  (" + RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") + ")")
	*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
	ProcedureReturn 0
EndProcedure


;-> > > Float32

; The value's bits are moved and swapped as an integer, since loading a byte-swapped
;  float into the FPU can alter its bits. (e.g.: NaN quieting on x87)
Procedure.MsgPack_ErrorCode MsgPackWriteFloat32(*MsgPackData.MsgPackData, Value.f)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Float32, 4, PeekL(@Value))
EndProcedure


Procedure.f MsgPackReadFloat32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.f

	PokeL(@ReturnedValue, _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Float32, 4))

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float64

; The value's bits are moved and swapped as an integer, since loading a byte-swapped
;  float into the FPU can alter its bits. (e.g.: NaN quieting on x87)
Procedure.MsgPack_ErrorCode MsgPackWriteFloat64(*MsgPackData.MsgPackData, Value.d)
	ProcedureReturn _MsgPackWriteFixedField(*MsgPackData, #MsgPack_FormatCode_Float64, 8, PeekQ(@Value))
EndProcedure


Procedure.d MsgPackReadFloat64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.d

	PokeQ(@ReturnedValue, _MsgPackReadFixedField(*MsgPackData, #MsgPack_FormatCode_Float64, 8))

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Any float

; Reads any float field at the current offset.
; Returns: The value as a double, float32 values being widened losslessly.
; OnError: Returns `0` and sets the `MsgPackData\LastError` field.
Procedure.d MsgPackReadFloat(*MsgPackData.MsgPackData)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn 0
		EndIf
	CompilerEndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		Debug("End of buffer reached, cannot check data format code !")
		*MsgPackData\LastError = #MsgPack_Error_AtOrPastTheEndOfBuffer
		ProcedureReturn 0
	EndIf

	Select MsgPackGetFormatCode(*MsgPackData)
		Case #MsgPack_FormatCode_Float32:
			ProcedureReturn MsgPackReadFloat32(*MsgPackData)
		Case #MsgPack_FormatCode_Float64:
			ProcedureReturn MsgPackReadFloat64(*MsgPackData)
	EndSelect

	Debug("Unexpected format code !  (" + RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") + ")")
	*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
	ProcedureReturn 0
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
