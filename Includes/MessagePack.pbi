;{- Code Header
; ==- Basic Info -================================
;     Name: MessagePack.pbi
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

; Specification:
; * https://github.com/msgpack/msgpack/blob/master/spec.md



; ------------------------------------------------------------------------------
;- Compiler directive

;EnableExplicit



; ------------------------------------------------------------------------------
;- Constants

; ???



; ------------------------------------------------------------------------------
;- Enumerations

Enumeration MsgPack_Types
	#MsgPack_Types_Null
	#MsgPack_Types_Nil = #MsgPack_Types_Null
	
	#MsgPack_Types_False
	#MsgPack_Types_True
	
	#MsgPack_Types_FixIntPositive
	#MsgPack_Types_FixIntNegative
	
	#MsgPack_Types_UInt8
	#MsgPack_Types_UInt16
	#MsgPack_Types_UInt32
	#MsgPack_Types_UInt64
	
	#MsgPack_Types_Int8
	#MsgPack_Types_Int16
	#MsgPack_Types_Int32
	#MsgPack_Types_Int64

	#MsgPack_Types_Float32
	#MsgPack_Types_Float64

	#MsgPack_Types_Custom
EndEnumeration

Enumeration MsgPack_FormatCodes
	
	; 1 type byte, nothing else
	#MsgPack_FormatCode_Null = $C0
	#MsgPack_FormatCode_Nil = #MsgPack_Types_Null
	
	; 1 type byte, nothing else
	#MsgPack_FormatCode_False = $C2
	
	; 1 type byte, nothing else
	#MsgPack_FormatCode_True = $C3

	; 1 type byte + 4 data bytes (big-endian IEEE 754 single precision)
	#MsgPack_FormatCode_Float32 = $CA

	; 1 type byte + 8 data bytes (big-endian IEEE 754 double precision)
	#MsgPack_FormatCode_Float64 = $CB

	; Special
	#MsgPack_FormatCode_FixIntPositive = $CC
	#MsgPack_FormatCode_FixIntNegative = $CC
	
	#MsgPack_FormatCode_UInt8 = $CC
	#MsgPack_FormatCode_UInt16 = $CD
	#MsgPack_FormatCode_UInt32 = $CE
	#MsgPack_FormatCode_UInt64 = $CF
	
	#MsgPack_FormatCode_Int8 = $D0
	#MsgPack_FormatCode_Int16 = $D1
	#MsgPack_FormatCode_Int32 = $D2
	#MsgPack_FormatCode_Int64 = $D3
	
EndEnumeration





; Private structure representing read/write buffers
Structure MsgPackThingy
	; Offset used when reading or writing.
	BufferOffset.i
	
	; Used in place of `MemorySize()` to reduce syscalls.
	BufferSize.i
	
	; Temp mechanism for buffer growth.
	BufferGrowthIncrements.i
	
	; Pointer to a data buffer.
	; Can be freed by the caller or this module.
	*Buffer
EndStructure






; Tmp
Procedure MsgPackAAAAA(DataFormatCode.a)
	
	; FixInts
	If DataFormatCode & %10000000 = 0
		ProcedureReturn #MsgPack_Types_FixIntPositive
	EndIf
	
	
	If DataFormatCode & %11100000 = %11100000
		ProcedureReturn #MsgPack_Types_FixIntNegative
	EndIf
	
EndProcedure






; ------------------------------------------------------------------------------
;- Macros

Macro _HasSpaceLeft(MsgPackWrapper, DesiredSize)
	((MsgPackWrapper\BufferSize >= MsgPackWrapper\BufferOffset) And (MsgPackWrapper\BufferSize - MsgPackWrapper\BufferOffset >= DesiredSize))
EndMacro

Macro _IsAtTheEnd(MsgPackWrapper)
	(MsgPackWrapper\BufferOffset >= MsgPackWrapper\BufferSize)
EndMacro



; ------------------------------------------------------------------------------
;- Procedures

;--> Thingies

Procedure.i MsgPackCreateMsgBuffer(InitialSize.i)
	Debug "########################################"
	Debug "MsgPackCreateMsgBuffer()"
	Debug "  InitialSize: " + Str(InitialSize)
	
	Protected *ReturnedValue.MsgPackThingy = #Null
	
	If InitialSize <= 0
		DebuggerWarning("Returning #Null, requested size was zero or negative")
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackThingy)
	
	If *ReturnedValue <> #Null
		*ReturnedValue\BufferOffset = 0
		*ReturnedValue\BufferSize = InitialSize
		*ReturnedValue\BufferGrowthIncrements = InitialSize
		
		*ReturnedValue\Buffer = AllocateMemory(InitialSize)
		If Not *ReturnedValue\Buffer
			DebuggerError("Failed to allocate memory for buffer !")
			FreeStructure(*ReturnedValue)
			*ReturnedValue = #Null
		EndIf
	EndIf
	
	ProcedureReturn *ReturnedValue
EndProcedure

; Wraps an existing, caller-owned buffer so it can be read with ReadA/ReadI8.
; Does not copy or take ownership of *Buffer: free it yourself, and pass
; FreeDataBuffer = #False to MsgPackFreeMsgBuffer for the wrapper it returns.
Procedure.i MsgPackWrapMsgBuffer(*Buffer, BufferSize.i)
	Debug "########################################"
	Debug "MsgPackWrapMsgBuffer()"
	Debug "     *Buffer: 0x" + RSet(Hex(*Buffer), SizeOf(Integer) * 2, "0")
	Debug "  BufferSize: " + Str(BufferSize)
	;If *Buffer
	;	Debug "  MemorySize: " + Str(MemorySize(*Buffer))
	;EndIf
	
	Protected *ReturnedValue.MsgPackThingy = #Null
	
	If *Buffer = #Null Or BufferSize <= 0
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackThingy)
	If *ReturnedValue = #Null
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue\BufferOffset = 0
	*ReturnedValue\BufferSize = BufferSize
	*ReturnedValue\BufferGrowthIncrements = 0 ; wrapped buffer isn't grown
	*ReturnedValue\Buffer = *Buffer
	
	ProcedureReturn *ReturnedValue
EndProcedure

Procedure.b MsgPackFreeMsgBuffer(*MsgPackData.MsgPackThingy, FreeDataBuffer.b = #False)
	If Not *MsgPackData
		ProcedureReturn #False
	EndIf
	
	If *MsgPackData <> #Null
		If *MsgPackData\Buffer <> #Null And FreeDataBuffer
			FreeMemory(*MsgPackData\Buffer)
		EndIf
		FreeStructure(*MsgPackData)
	EndIf
	
	ProcedureReturn #True
EndProcedure



;--> Read/Write

;---> UInt8

Procedure.b MsgPackWriteUInt8(*MsgPackData.MsgPackThingy, Value.a)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf
	
	If Not _HasSpaceLeft(*MsgPackData, 2)
		Debug("Growing buffer for UInt8...")
		ProcedureReturn #False
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt8)
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn #True
EndProcedure


Procedure.a MsgPackReadUInt8(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.a = $00
	
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf
	
	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt8
		DebuggerError("The format code isn't the one for a UInt8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt8), 2, "0") + ")")
		ProcedureReturn 0
	EndIf
	
	If Not _HasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn ReturnedValue
EndProcedure




;---> Int8

Procedure.b MsgPackWriteInt8(*MsgPackData.MsgPackThingy, Value.b)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf
	
	If Not _HasSpaceLeft(*MsgPackData, 2)
		Debug("Growing buffer for Int8...")
		ProcedureReturn #False
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int8)
	PokeB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn #True
EndProcedure


Procedure.b MsgPackReadInt8(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.b = $00
	
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf
	
	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int8
		DebuggerError("The format code isn't the one for a Int8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int8), 2, "0") + ")")
		ProcedureReturn 0
	EndIf
	
	If Not _HasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 2

	ProcedureReturn ReturnedValue
EndProcedure




;---> UInt16

Procedure.b MsgPackWriteUInt16(*MsgPackData.MsgPackThingy, Value.u)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 3)
		Debug("Growing buffer for UInt16...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt16)
	PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 3

	ProcedureReturn #True
EndProcedure


Procedure.u MsgPackReadUInt16(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.u = $0000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt16
		DebuggerError("The format code isn't the one for a UInt16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt16), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure




;---> Int16

Procedure.b MsgPackWriteInt16(*MsgPackData.MsgPackThingy, Value.w)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 3)
		Debug("Growing buffer for Int16...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int16)
	PokeW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 3

	ProcedureReturn #True
EndProcedure


Procedure.w MsgPackReadInt16(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.w = $0000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int16
		DebuggerError("The format code isn't the one for a Int16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int16), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure




;---> UInt32

; No unsigned Long in PureBasic: value is peeked/poked as-is via .l and returned unchanged.
Procedure.b MsgPackWriteUInt32(*MsgPackData.MsgPackThingy, Value.l)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for UInt32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.l MsgPackReadUInt32(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.l = $00000000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt32
		DebuggerError("The format code isn't the one for a UInt32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure




;---> Int32

Procedure.b MsgPackWriteInt32(*MsgPackData.MsgPackThingy, Value.l)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for Int32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.l MsgPackReadInt32(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.l = $00000000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int32
		DebuggerError("The format code isn't the one for a Int32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure




;---> UInt64

; No unsigned Quad in PureBasic: value is peeked/poked as-is via .q and returned unchanged.
Procedure.b MsgPackWriteUInt64(*MsgPackData.MsgPackThingy, Value.q)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for UInt64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.q MsgPackReadUInt64(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.q = 0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt64
		DebuggerError("The format code isn't the one for a UInt64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure




;---> Int64

Procedure.b MsgPackWriteInt64(*MsgPackData.MsgPackThingy, Value.q)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for Int64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.q MsgPackReadInt64(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.q = 0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int64
		DebuggerError("The format code isn't the one for a Int64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure




;---> Float32

Procedure.b MsgPackWriteFloat32(*MsgPackData.MsgPackThingy, Value.f)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for Float32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float32)
	PokeF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.f MsgPackReadFloat32(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.f = 0.0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float32
		DebuggerError("The format code isn't the one for a Float32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure




;---> Float64

Procedure.b MsgPackWriteFloat64(*MsgPackData.MsgPackThingy, Value.d)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for Float64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float64)
	PokeD(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.d MsgPackReadFloat64(*MsgPackData.MsgPackThingy)
	Protected ReturnedValue.d = 0.0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackThingy pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _IsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float64
		DebuggerError("The format code isn't the one for a Float64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _HasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekD(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 9

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
