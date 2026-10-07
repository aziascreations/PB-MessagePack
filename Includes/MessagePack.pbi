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
;- Configurations

; Scrapped idea
;CompilerIf Not Defined(MsgPack_LookupTable_FormatCode, #PB_Constant)
;	#MsgPack_LookupTable_FormatCode = #False
;CompilerEndIf



; ------------------------------------------------------------------------------
;- Compiler directive

;EnableExplicit



; ------------------------------------------------------------------------------
;- Constants

; ???



; ------------------------------------------------------------------------------
;- Enumerations

Enumeration _MsgPack_DataTypes
	; ???
	#MsgPack_DataTypes_Unknown

	; nil
	#MsgPack_DataTypes_Null
	#MsgPack_DataTypes_Nil = #MsgPack_Types_Null
	
	; bool family
	#MsgPack_DataTypes_Boolean
	
	; int family
	#MsgPack_DataTypes_FixIntPositive
	#MsgPack_DataTypes_FixIntNegative
	
	#MsgPack_DataTypes_UInt8
	#MsgPack_DataTypes_UInt16
	#MsgPack_DataTypes_UInt32
	#MsgPack_DataTypes_UInt64
	
	#MsgPack_DataTypes_Int8
	#MsgPack_DataTypes_Int16
	#MsgPack_DataTypes_Int32
	#MsgPack_DataTypes_Int64

	; float family
	#MsgPack_DataTypes_Float
	#MsgPack_DataTypes_Double

	; str family
	#MsgPack_DataTypes_String

	; bin family
	#MsgPack_DataTypes_Binary

	; array family
	#MsgPack_DataTypes_Array

	; map family
	#MsgPack_DataTypes_Map

	; map family
	#MsgPack_DataTypes_Ext

	; Extensions
	#MsgPack_DataTypes_Extension
EndEnumeration

Enumeration _MsgPack_FormatCodes
	; nil
	#MsgPack_FormatCode_Null = $C0
	#MsgPack_FormatCode_Nil  = #MsgPack_Types_Null
	
	; bool family
	#MsgPack_FormatCode_False = $C2
	#MsgPack_FormatCode_True  = $C3

	; int family
	#MsgPack_FormatCode_FixIntPositive = %00000000  ; 0x00-0x7F
	#MsgPack_FormatCode_FixIntNegative = %11100000  ; 0xE0-0xFF

	#MsgPack_FormatCode_UInt8  = $CC
	#MsgPack_FormatCode_UInt16 = $CD
	#MsgPack_FormatCode_UInt32 = $CE
	#MsgPack_FormatCode_UInt64 = $CF
	
	#MsgPack_FormatCode_Int8  = $D0
	#MsgPack_FormatCode_Int16 = $D1
	#MsgPack_FormatCode_Int32 = $D2
	#MsgPack_FormatCode_Int64 = $D3

	; float family
	#MsgPack_FormatCode_Float32 = $CA
	#MsgPack_FormatCode_Float64 = $CB

	; str family
	#MsgPack_FormatCode_FixStr = %10100000  ; 0xA0-0xBF
	#MsgPack_FormatCode_Str8  = $D9
	#MsgPack_FormatCode_Str16 = $DA
	#MsgPack_FormatCode_Str32 = $DB

	; bin family
	#MsgPack_FormatCode_Bin8  = $C4
	#MsgPack_FormatCode_Bin16 = $C5
	#MsgPack_FormatCode_Bin32 = $C6

	; array family
	#MsgPack_FormatCode_FixArray = %10010000  ; 0x90-0x9F
	#MsgPack_FormatCode_Array16 = $DC
	#MsgPack_FormatCode_Array32 = $DD

	; map family
	#MsgPack_FormatCode_FixMap = %10000000  ; 0x80-0x8F
	#MsgPack_FormatCode_Map16 = $DE
	#MsgPack_FormatCode_Map32 = $DF

	; fixext family
	#MsgPack_FormatCode_FixExt1  = $D4
	#MsgPack_FormatCode_FixExt2  = $D5
	#MsgPack_FormatCode_FixExt4  = $D6
	#MsgPack_FormatCode_FixExt8  = $D7
	#MsgPack_FormatCode_FixExt16 = $D8

	; ext family
	#MsgPack_FormatCode_Ext8  = $C7
	#MsgPack_FormatCode_Ext16 = $C8
	#MsgPack_FormatCode_Ext32 = $C9

	; Tmp
	#MsgPack_FormatCode_Invalid = $C1
EndEnumeration



; ------------------------------------------------------------------------------
;- Typedefs

CompilerIf Defined(MsgPack_DataType, #PB_Macro)
	CompilerError("The typedef macro `MsgPack_DataType` is already defined !")
CompilerEndIf
Macro MsgPack_DataType : b : EndMacro

CompilerIf Defined(MsgPack_FormatCode, #PB_Macro)
	CompilerError("The typedef macro `MsgPack_FormatCode` is already defined !")
CompilerEndIf
Macro MsgPack_FormatCode : b : EndMacro



; ------------------------------------------------------------------------------
;- Structures

Structure MsgPackData
	; Offset used when reading or writing.
	BufferOffset.i
	
	; Used in place of `MemorySize()` to reduce syscalls.
	BufferSize.i
	
	; Temp mechanism for buffer growth.
	BufferGrowthIncrements.i
	
	; LastError code (Unused)
	LastError.i
	
	; Pointer to a data buffer.
	; Can be freed by the caller or this module.
	*Buffer
EndStructure



; ------------------------------------------------------------------------------
;- Macros

Macro _MsgPackHasSpaceLeft(MsgPackWrapper, DesiredSize)
	((MsgPackWrapper\BufferSize >= MsgPackWrapper\BufferOffset) And (MsgPackWrapper\BufferSize - MsgPackWrapper\BufferOffset >= DesiredSize))
EndMacro

Macro _MsgPackIsAtTheEnd(MsgPackWrapper)
	(MsgPackWrapper\BufferOffset >= MsgPackWrapper\BufferSize)
EndMacro



; ------------------------------------------------------------------------------
;- Procedures

;-> Thingies

Procedure.i MsgPackCreate(InitialSize.i)
	Protected *ReturnedValue.MsgPackData = #Null
	
	If InitialSize <= 0
		DebuggerWarning("Returning #Null, requested size was zero or negative")
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	
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
	Protected *ReturnedValue.MsgPackData = #Null
	
	If *Buffer = #Null Or BufferSize <= 0
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue = AllocateStructure(MsgPackData)
	If *ReturnedValue = #Null
		ProcedureReturn #Null
	EndIf
	
	*ReturnedValue\BufferOffset = 0
	*ReturnedValue\BufferSize = BufferSize
	*ReturnedValue\BufferGrowthIncrements = 0
	*ReturnedValue\Buffer = *Buffer
	
	ProcedureReturn *ReturnedValue
EndProcedure

Procedure.b MsgPackFree(*MsgPackData.MsgPackData, FreeDataBuffer.b = #False)
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


;-> Iterators

; Tmp
; CompilerIf Defined(MsgPack_LookupTable_FormatCode)

Procedure.MsgPack_DataType MsgPackNextDataType(DataFormatCode.a)
	
	; Processing Fix* formats before to speed them up

	If DataFormatCode < $0x80
		; 0x00 - 0x7F
		ProcedureReturn #MsgPack_FormatCode_FixIntPositive

	ElseIf DataFormatCode < $0x90
		; 0x80 - 0x8F
		ProcedureReturn #MsgPack_FormatCode_FixMap

	ElseIf DataFormatCode < $0xA0
		; 0x90 - 0x9F
		ProcedureReturn #MsgPack_FormatCode_FixArray

	ElseIf DataFormatCode < $0xC0
		; 0xA0 - 0xBF
		ProcedureReturn #MsgPack_FormatCode_FixStr

	ElseIf DataFormatCode < $0xE0
		; 0xC0 - 0xDF -> Various
		ProcedureReturn DataFormatCode

	Else
		; 0xE0 - 0xFF -> ???
		ProcedureReturn MsgPack_FormatCode_Invalid
	EndIf
		
EndProcedure





;-> Getters & Setters

;-> > UInt8

Procedure.b MsgPackWriteUInt8(*MsgPackData.MsgPackData, Value.a)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		Debug("Growing buffer for UInt8...")
		ProcedureReturn #False
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt8)
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn #True
EndProcedure


Procedure.a MsgPackReadUInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.a = $00
	
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt8
		DebuggerError("The format code isn't the one for a UInt8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt8), 2, "0") + ")")
		ProcedureReturn 0
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn ReturnedValue
EndProcedure



;-> > Int8

Procedure.b MsgPackWriteInt8(*MsgPackData.MsgPackData, Value.b)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		Debug("Growing buffer for Int8...")
		ProcedureReturn #False
	EndIf
	
	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int8)
	PokeB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)
	
	*MsgPackData\BufferOffset + 2
	
	ProcedureReturn #True
EndProcedure


Procedure.b MsgPackReadInt8(*MsgPackData.MsgPackData)
	Protected ReturnedValue.b = $00
	
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf
	
	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int8
		DebuggerError("The format code isn't the one for a Int8 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int8), 2, "0") + ")")
		ProcedureReturn 0
	EndIf
	
	If Not _MsgPackHasSpaceLeft(*MsgPackData, 2)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf
	
	ReturnedValue = PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 2

	ProcedureReturn ReturnedValue
EndProcedure


;-> > UInt16

Procedure.b MsgPackWriteUInt16(*MsgPackData.MsgPackData, Value.u)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		Debug("Growing buffer for UInt16...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt16)
	PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 3

	ProcedureReturn #True
EndProcedure


Procedure.u MsgPackReadUInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.u = $0000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt16
		DebuggerError("The format code isn't the one for a UInt16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt16), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int16

Procedure.b MsgPackWriteInt16(*MsgPackData.MsgPackData, Value.w)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		Debug("Growing buffer for Int16...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int16)
	PokeW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 3

	ProcedureReturn #True
EndProcedure


Procedure.w MsgPackReadInt16(*MsgPackData.MsgPackData)
	Protected ReturnedValue.w = $0000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int16
		DebuggerError("The format code isn't the one for a Int16 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int16), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 3)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekW(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 3

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt32

; No unsigned Long in PureBasic: value is peeked/poked as-is via .l and returned unchanged.
Procedure.b MsgPackWriteUInt32(*MsgPackData.MsgPackData, Value.l)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for UInt32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.l MsgPackReadUInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l = $00000000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt32
		DebuggerError("The format code isn't the one for a UInt32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int32

Procedure.b MsgPackWriteInt32(*MsgPackData.MsgPackData, Value.l)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for Int32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int32)
	PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.l MsgPackReadInt32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.l = $00000000

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int32
		DebuggerError("The format code isn't the one for a Int32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > UInt64

; No unsigned Quad in PureBasic: value is peeked/poked as-is via .q and returned unchanged.
Procedure.b MsgPackWriteUInt64(*MsgPackData.MsgPackData, Value.q)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for UInt64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_UInt64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.q MsgPackReadUInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q = 0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_UInt64
		DebuggerError("The format code isn't the one for a UInt64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_UInt64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Int64

Procedure.b MsgPackWriteInt64(*MsgPackData.MsgPackData, Value.q)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for Int64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Int64)
	PokeQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.q MsgPackReadInt64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.q = 0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Int64
		DebuggerError("The format code isn't the one for a Int64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Int64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekQ(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 9

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float32

Procedure.b MsgPackWriteFloat32(*MsgPackData.MsgPackData, Value.f)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		Debug("Growing buffer for Float32...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float32)
	PokeF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 5

	ProcedureReturn #True
EndProcedure


Procedure.f MsgPackReadFloat32(*MsgPackData.MsgPackData)
	Protected ReturnedValue.f = 0.0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float32
		DebuggerError("The format code isn't the one for a Float32 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float32), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 5)
		DebuggerError("End of buffer reached, cannot read out of bounds !")
		ProcedureReturn 0
	EndIf

	ReturnedValue = PeekF(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
	*MsgPackData\BufferOffset + 5

	ProcedureReturn ReturnedValue
EndProcedure


;-> > > Float64

Procedure.b MsgPackWriteFloat64(*MsgPackData.MsgPackData, Value.d)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #False
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
		Debug("Growing buffer for Float64...")
		ProcedureReturn #False
	EndIf

	PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, #MsgPack_FormatCode_Float64)
	PokeD(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, Value)

	*MsgPackData\BufferOffset + 9

	ProcedureReturn #True
EndProcedure


Procedure.d MsgPackReadFloat64(*MsgPackData.MsgPackData)
	Protected ReturnedValue.d = 0.0

	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn 0
	EndIf

	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn 0
	EndIf

	If PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) <> #MsgPack_FormatCode_Float64
		DebuggerError("The format code isn't the one for a Float64 !  (" +
		              RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") +
		              " vs "+ RSet(Hex(#MsgPack_FormatCode_Float64), 2, "0") + ")")
		ProcedureReturn 0
	EndIf

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 9)
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


; ------------------------------------------------------------------------------
;- DataSection

; ???
