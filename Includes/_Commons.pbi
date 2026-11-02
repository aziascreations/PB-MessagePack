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

; Skipped if "Endianness.pbi" was already included from another path, by the program or another include.
CompilerIf Not Defined(_NibblePoker_Endianness_WasIncluded, #PB_Constant) And Not Defined(EndianSwapQ, #PB_Procedure)
	XIncludeFile "./PB-Endianness/Includes/Endianness.pbi"
CompilerEndIf



; ------------------------------------------------------------------------------
;- Include Options

; Disables null checking on non-debug builds
CompilerIf Not Defined(MsgPack_DisableNullChecks, #PB_Constant)
	#MsgPack_DisableNullChecks = #False
CompilerEndIf

; Maximum nesting depth of arrays and maps, a top-level array or map being at depth 1.
; Deeper data is rejected as invalid with `#MsgPack_Error_MaxDepthExceeded`.
; Bounds the time spent on hostile data, nested views re-check their content at each level.
; Each depth level costs 8 bytes of stack per skip, hence the upper bound.
CompilerIf Not Defined(MsgPack_MaxDepth, #PB_Constant)
	#MsgPack_MaxDepth = 128
CompilerEndIf

CompilerIf #MsgPack_MaxDepth < 1 Or #MsgPack_MaxDepth > 4096
	CompilerError "#MsgPack_MaxDepth must be between 1 and 4096 !"
CompilerEndIf



; ------------------------------------------------------------------------------
;- Constants

; Used to represent any size that couldn't be calculated/derived/...
#MsgPack_InvalidSize = -1

; Biggest value a `.i` can hold, used to reject sizes that would be truncated on x86.
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
	#_MsgPack_MaxIntegerValue = $7FFFFFFF
CompilerElse
	#_MsgPack_MaxIntegerValue = $7FFFFFFFFFFFFFFF
CompilerEndIf


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
	#MsgPack_Error_InvalidValue = 3
	#MsgPack_Error_ValueOverflow = 4

	; Shouldn't re-use it.
	#MsgPack_Error_FailedToGrowBuffer = 10
	#MsgPack_Error_AtOrPastTheEndOfBuffer = 11
	#MsgPack_Error_ReadPastEndOfBuffer = 12
	#MsgPack_Error_InvalidFormatCode = 13
	#MsgPack_Error_FailedToAllocateBuffer = 14

	; 5x - Binary
	#MsgPack_Error_BinaryDataSizeIsNegative = 50
	#MsgPack_Error_BinaryDataSizeIsTooBig   = 51
	#MsgPack_Error_OutputBufferTooSmall     = 52

	; 6x - Strings
	#MsgPack_Error_UnsupportedStringEncoding = 60
	#MsgPack_Error_InvalidStringSize = 61

	; 7x - Arrays & Maps
	#MsgPack_Error_TooManyEntries    = 70
	#MsgPack_Error_OddMapFieldCount  = 71
	#MsgPack_Error_MaxDepthExceeded  = 72


	#MsgPack_Error_CannotGrowBufferDueToConfig = 100
	#MsgPack_Error_BufferIsReadOnly = 101
EndEnumeration

EnumerationBinary _MsgPack_DataFlags
	; Prevents any write in a given `MsgPackData`, set on views from `MsgPackExamine()`.
	; Writes return `#MsgPack_Error_BufferIsReadOnly`.
	#MsgPack_DataFlags_IsReadOnly     = %0000000000000001

	; Prevents a `MsgPackData` structure from auto-growing its buffer when needed.
	; It may make some functions return `#MsgPack_Error_CannotGrowBufferDueToConfig`.
	#MsgPack_DataFlags_CannotGrow     = %0000000000000010

	; Indicates the buffer is owned by the caller and must not be freed by `MsgPackFree()`.
	#MsgPack_DataFlags_NoBufferFree   = %0000000000000100

	; Indicates a given `MsgPackData` should increment its buffer offset after
	;  reading a value using the standard procedures.
	#MsgPack_DataFlags_MoveOffsetAfterRead = %0000000000001000

	; Indicates a given `MsgPackData` should increment its buffer offset after
	;  writing a value using the standard procedures.
	#MsgPack_DataFlags_MoveOffsetAfterWrite = %0000000000010000

	; Indicates a given `MsgPackData` is a view made to be iterated on with `MsgPackNextEntry()`.
	; And it implies it represents a Map or Array.
	#MsgPack_DataFlags_Iterator       = %0000000000100000
	; Set on map views, whose entries are made of a key and a value.
	#MsgPack_DataFlags_CanProvideKeys = %0000000001000000
	; Set on both map and array views.
	#MsgPack_DataFlags_CanProvideVals = %0000000010000000
EndEnumeration

; Flags set on every new `MsgPackData`, so all reads and writes move the offset.
#_MsgPack_DefaultDataFlags = #MsgPack_DataFlags_MoveOffsetAfterRead | #MsgPack_DataFlags_MoveOffsetAfterWrite

; Flags set on every view from `MsgPackExamine()`, which never own nor grow their buffer.
EnumerationBinary _MsgPack_ExaminationOptions
	; Not recommended !
	; Skips the check of the examined array or map's content, which also finds its end.
	; The view can then read past the array or map until `MsgPackNextEntry()` reaches its end,
	;  invalid content is only detected while iterating, and the examined offset isn't moved.
	#MsgPack_ExaminationOptions_Unsafe = %0000000000000001
EndEnumeration

#_MsgPack_ViewDataFlags =#_MsgPack_DefaultDataFlags | #MsgPack_DataFlags_IsReadOnly | #MsgPack_DataFlags_CannotGrow | #MsgPack_DataFlags_NoBufferFree | #MsgPack_DataFlags_Iterator | #MsgPack_DataFlags_CanProvideVals



; ------------------------------------------------------------------------------
;- Typedefs

Macro MsgPack_DataType : a : EndMacro

Macro MsgPack_FormatCode : a : EndMacro

Macro MsgPack_ErrorCode : u : EndMacro

Macro MsgPack_DataFlag : u : EndMacro

Macro MsgPack_ExaminationOption : u : EndMacro



; ------------------------------------------------------------------------------
;- Structures

Structure MsgPackData
	; Offset used when reading or writing.
	BufferOffset.i
	
	; Used in place of `MemorySize()` to reduce syscalls.
	BufferSize.i
	
	; Multiple of which any buffer size increase should match.
	; Also applies to its initial size. (FIXME)
	; If the requested size doesn't match one, we'll use the nearest next multiple.
	; If set to `1` or lower, we'll ignore this mechanism.
	BufferGrowthIncrement.i

	; Offset of the iterator's current entry, only used by views from `MsgPackExamine()`.
	; Set to `#MsgPack_InvalidSize` until the first `MsgPackNextEntry()` call.
	IteratorEntryOffset.i

	; Number of fields left to iterate on, map keys and values included, only used by views.
	IteratorFieldsLeft.q

	; Number of arrays and maps containing the data, `0` for regular structures, `1` for views over a top-level one.
	; Counted against `#MsgPack_MaxDepth`.
	IteratorDepth.i

	; LastError code
	LastError.MsgPack_ErrorCode
	
	; TODO
	DataFlags.MsgPack_DataFlag
	
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

Macro _MsgPackHasFlag(MsgPackWrapper, DataFlag)
	((MsgPackWrapper\DataFlags & DataFlag) <> $0000)
EndMacro

; Checks if the `Size` bytes at `Pointer` overlap the buffer of `MsgPackWrapper`.
; Writers refuse such data, growing the buffer would free it before it's copied.
Macro _MsgPackOverlapsBuffer(MsgPackWrapper, Pointer, Size)
	(Pointer <> #Null And (Size) > 0 And Pointer < MsgPackWrapper\Buffer + MsgPackWrapper\BufferSize And Pointer + (Size) > MsgPackWrapper\Buffer)
EndMacro

; Moves the offset past a field of `Size` bytes that was fully read, if the flags allow it.
Macro _MsgPackMoveOffsetAfterRead(MsgPackWrapper, Size)
	If _MsgPackHasFlag(MsgPackWrapper, #MsgPack_DataFlags_MoveOffsetAfterRead)
		MsgPackWrapper\BufferOffset = MsgPackWrapper\BufferOffset + (Size)
	EndIf
EndMacro

; Moves the offset back before a field of `Size` bytes that was fully written, if the flags don't allow it to move.
; Writes always move the offset as they go, since most of them are done in multiple steps.
Macro _MsgPackRewindOffsetAfterWrite(MsgPackWrapper, Size)
	If Not _MsgPackHasFlag(MsgPackWrapper, #MsgPack_DataFlags_MoveOffsetAfterWrite)
		MsgPackWrapper\BufferOffset = MsgPackWrapper\BufferOffset - (Size)
	EndIf
EndMacro



; ------------------------------------------------------------------------------
;- Procedures

Procedure.MsgPack_ErrorCode MsgPackLastError(*MsgPackData.MsgPackData)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #MsgPack_Error_NullPointerGiven
	EndIf

	ProcedureReturn *MsgPackData\LastError
EndProcedure



; ------------------------------------------------------------------------------
;- Debugging

CompilerIf #True
	Procedure _MsgPackDebug(Message.s)
		Debug Message
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			OutputDebugString_(Message)
		CompilerEndIf
	EndProcedure
CompilerElse
	Macro _MsgPackDebug(Message) :  : EndMacro
CompilerEndIf
