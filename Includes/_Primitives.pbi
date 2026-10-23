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



; ------------------------------------------------------------------------------
;- Procedures

;-> Internal helpers

; Ensures `Size` bytes can be written at the current offset, growing the buffer by
;  exactly the missing amount if needed.
; Sets the structure's error code and returns it.
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



;-> Getters & Setters

;-> > UInt8
Procedure.MsgPack_ErrorCode MsgPackWriteUInt8(*MsgPackData.MsgPackData, Value.a)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 2)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt8)
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.a MsgPackReadUInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.a
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_UInt8, 2) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > Int8
Procedure.MsgPack_ErrorCode MsgPackWriteInt8(*MsgPackData.MsgPackData, Value.b)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 2)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int8)
	PokeB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.b MsgPackReadInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.b
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Int8, 2) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 2
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > UInt16
Procedure.MsgPack_ErrorCode MsgPackWriteUInt16(*MsgPackData.MsgPackData, Value.u)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 3)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt16)
	PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapU16(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.u MsgPackReadUInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.u
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_UInt16, 3) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapU16(PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int16
Procedure.MsgPack_ErrorCode MsgPackWriteInt16(*MsgPackData.MsgPackData, Value.w)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 3)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int16)
	PokeW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI16(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.w MsgPackReadInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.w
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Int16, 3) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapI16(PeekW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 3
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt32
; No unsigned Long in PureBasic: value is peeked/poked as-is via .l and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt32(*MsgPackData.MsgPackData, Value.l)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 5)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI32(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.l MsgPackReadUInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_UInt32, 5) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapI32(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int32
Procedure.MsgPack_ErrorCode MsgPackWriteInt32(*MsgPackData.MsgPackData, Value.l)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 5)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI32(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.l MsgPackReadInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Int32, 5) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapI32(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt64
; No unsigned Quad in PureBasic: value is peeked/poked as-is via .q and returned unchanged.
Procedure.MsgPack_ErrorCode MsgPackWriteUInt64(*MsgPackData.MsgPackData, Value.q)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 9)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI64(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.q MsgPackReadUInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_UInt64, 9) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapI64(PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int64
Procedure.MsgPack_ErrorCode MsgPackWriteInt64(*MsgPackData.MsgPackData, Value.q)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 9)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI64(Value))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.q MsgPackReadInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Int64, 9) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = EndianSwapI64(PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float32

; The value's bits are moved and swapped as an integer, since loading a byte-swapped
;  float into the FPU can alter its bits. (e.g.: NaN quieting on x87)
Procedure.MsgPack_ErrorCode MsgPackWriteFloat32(*MsgPackData.MsgPackData, Value.f)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 5)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI32(PeekL(@Value)))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.f MsgPackReadFloat32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.f
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Float32, 5) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	PokeL(@ReturnedValue, EndianSwapI32(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 5
	
	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float64

; The value's bits are moved and swapped as an integer, since loading a byte-swapped
;  float into the FPU can alter its bits. (e.g.: NaN quieting on x87)
Procedure.MsgPack_ErrorCode MsgPackWriteFloat64(*MsgPackData.MsgPackData, Value.d)
	Protected ErrorCode.MsgPack_ErrorCode
	
	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 9)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI64(PeekQ(@Value)))
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 9
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure


Procedure.d MsgPackReadFloat64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.d
	
	If _MsgPackExpectRead(*MsgPackData, #MsgPack_FormatCode_Float64, 9) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf
	
	PokeQ(@ReturnedValue, EndianSwapI64(PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)))
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
