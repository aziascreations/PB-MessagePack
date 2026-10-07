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
;- Compiler directive

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Primitives.pbi"
XIncludeFile "./_Strings.pbi"



; ------------------------------------------------------------------------------
;- Procedures



;-> Iterators?

Procedure.MsgPack_FormatCode MsgPackGetFormatCode(*MsgPackData.MsgPackData)
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #MsgPack_FormatCode_Invalid
	EndIf
	
	If Not _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn #MsgPack_FormatCode_Invalid
	EndIf

	If DataFormatCode < $80
		; 0x00 - 0x7F
		ProcedureReturn #MsgPack_FormatCode_FixIntPositive
	ElseIf DataFormatCode < $90
		; 0x80 - 0x8F
		ProcedureReturn #MsgPack_FormatCode_FixMap
	ElseIf DataFormatCode < $A0
		; 0x90 - 0x9F
		ProcedureReturn #MsgPack_FormatCode_FixArray
	ElseIf DataFormatCode < $C0
		; 0xA0 - 0xBF
		ProcedureReturn #MsgPack_FormatCode_FixStr
	ElseIf DataFormatCode < $E0
		; 0xC0 - 0xDF -> Various
		ProcedureReturn DataFormatCode
	Else
		; 0xE0 - 0xFF -> ???
		ProcedureReturn MsgPack_FormatCode_Invalid
	EndIf
EndProcedure


Procedure.MsgPack_DataType MsgPackGetDataType(*MsgPackData.MsgPackData)
    Protected FormatCode = MsgPackGetFormatCode(*MsgPackData)
    
    ProcedureReturn 0
EndProcedure



; ; int family
; #MsgPack_FormatCode_FixIntPositive = %00000000  ; 0x00-0x7F
; #MsgPack_FormatCode_FixMap = %10000000  ; 0x80-0x8F
; #MsgPack_FormatCode_FixArray = %10010000  ; 0x90-0x9F
; #MsgPack_FormatCode_FixStr = %10100000  ; 0xA0-0xBF

; #MsgPack_FormatCode_Null = $C0
; #MsgPack_FormatCode_Invalid = $C1
; #MsgPack_FormatCode_False = $C2
; #MsgPack_FormatCode_True  = $C3
; #MsgPack_FormatCode_Bin8  = $C4
; #MsgPack_FormatCode_Bin16 = $C5
; #MsgPack_FormatCode_Bin32 = $C6
; #MsgPack_FormatCode_Ext8  = $C7
; #MsgPack_FormatCode_Ext16 = $C8
; #MsgPack_FormatCode_Ext32 = $C9
; #MsgPack_FormatCode_Float32 = $CA
; #MsgPack_FormatCode_Float64 = $CB
; #MsgPack_FormatCode_UInt8  = $CC
; #MsgPack_FormatCode_UInt16 = $CD
; #MsgPack_FormatCode_UInt32 = $CE
; #MsgPack_FormatCode_UInt64 = $CF

; #MsgPack_FormatCode_Int8  = $D0
; #MsgPack_FormatCode_Int16 = $D1
; #MsgPack_FormatCode_Int32 = $D2
; #MsgPack_FormatCode_Int64 = $D3
; #MsgPack_FormatCode_FixExt1  = $D4
; #MsgPack_FormatCode_FixExt2  = $D5
; #MsgPack_FormatCode_FixExt4  = $D6
; #MsgPack_FormatCode_FixExt8  = $D7
; #MsgPack_FormatCode_FixExt16 = $D8
; #MsgPack_FormatCode_Str8  = $D9
; #MsgPack_FormatCode_Str16 = $DA
; #MsgPack_FormatCode_Str32 = $DB
; #MsgPack_FormatCode_Array16 = $DC
; #MsgPack_FormatCode_Array32 = $DD
; #MsgPack_FormatCode_Map16 = $DE
; #MsgPack_FormatCode_Map32 = $DF; 
; #MsgPack_FormatCode_FixIntNegative = %11100000  ; 0xE0-0xFF





; ------------------------------------------------------------------------------
;- DataSection

; ???
