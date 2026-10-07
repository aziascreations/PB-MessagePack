;{- Code Header
; ==- Basic Info -================================
;     Name: _Commons.pbi
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

Enumeration _MsgPack_DataTypes
	#MsgPack_DataTypes_Unknown
	#MsgPack_DataTypes_Null
	#MsgPack_DataTypes_Boolean
	#MsgPack_DataTypes_Integer
	#MsgPack_DataTypes_Float
	#MsgPack_DataTypes_String
	#MsgPack_DataTypes_Binary
	#MsgPack_DataTypes_Array
	#MsgPack_DataTypes_Map
	#MsgPack_DataTypes_Ext
	#MsgPack_DataTypes_Extension
EndEnumeration

Enumeration _MsgPack_FormatCodes
	; nil
	#MsgPack_FormatCode_Null = $C0
	
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

Macro MsgPack_DataType : b : EndMacro

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
