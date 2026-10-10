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

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf



; ------------------------------------------------------------------------------
;- Include Options

; Disables null checking on non-debug builds
CompilerIf Not Defined(MsgPack_DisableNullChecks, #PB_Constant)
	#MsgPack_DisableNullChecks = #False
CompilerEndIf



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

Enumeration _MsgPack_ErrorCodes
	#MsgPack_Error_Success = 0

	; Common errors
	#MsgPack_Error_NullPointerGiven = 1
	#MsgPack_Error_BufferTooSmall = 2

	; Shouldn't re-use it.
	#MsgPack_Error_FailedToGrowBuffer = 3
	#MsgPack_Error_AtOrPastTheEndOfBuffer = 4
	#MsgPack_Error_ReadPastEndOfBuffer = 5
	#MsgPack_Error_InvalidFormatCode = 6


	#MsgPack_Error_CannotGrowBufferDueToConfig = 100
EndEnumeration



; ------------------------------------------------------------------------------
;- Typedefs

Macro MsgPack_DataType : a : EndMacro

Macro MsgPack_FormatCode : a : EndMacro

Macro MsgPack_ErrorCode : u : EndMacro



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
	LastError.MsgPack_ErrorCode
	
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

; Should be moved to allocators.
; But it would fuck up the splitting of responsibility.
; TODO: Add callback in the structure, maybe ?
Procedure.MsgPack_ErrorCode MsgPackGrow(*MsgPackData.MsgPackData, MinimalGrowthSize.i = -1)
	Protected GrowthSize.i
	Protected *NewBuffer
	
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	; Often set by the callers, but programmers are likely to use it too,
	;  so I'm leaving it here.
	MsgPackData\LastError = #MsgPack_Error_Success
	
	If *MsgPackData\BufferGrowthIncrements <= 0
		DebuggerError("Cannot grow a buffer with no growth increments !")

		MsgPackData\LastError = #MsgPack_Error_CannotGrowBufferDueToConfig
		ProcedureReturn #MsgPack_Error_CannotGrowBufferDueToConfig
	EndIf
	
	; TODO: Improve logic later, i can't be bothered now
	GrowthSize = *MsgPackData\BufferGrowthIncrements
	If MinimalGrowthSize > GrowthSize
		GrowthSize = ((MinimalGrowthSize + GrowthSize - 1) / GrowthSize) * GrowthSize
	EndIf
	
	*NewBuffer = ReAllocateMemory(*MsgPackData\Buffer, *MsgPackData\BufferSize + GrowthSize)
	If Not *NewBuffer
		DebuggerError("Failed to reallocate memory for buffer !")

		MsgPackData\LastError = #MsgPack_Error_FailedToGrowBuffer
		ProcedureReturn #MsgPack_Error_FailedToGrowBuffer
	EndIf
	
	*MsgPackData\Buffer = *NewBuffer
	*MsgPackData\BufferSize + GrowthSize
	
	ProcedureReturn #MsgPack_Error_Success
EndProcedure



; ------------------------------------------------------------------------------
;- Debugging

; TODO: Something for OutputDebugStringW on win32
