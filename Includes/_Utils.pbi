;{- Code Header
; ==- Basic Info -================================
;     Name: _Utils.pbi
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



; ------------------------------------------------------------------------------
;- Procedures


;-> Format Codes

Procedure.MsgPack_FormatCode MsgPackGetFormatCode(*MsgPackData.MsgPackData)
	Protected DataFormatCode.MsgPack_FormatCode
	
	If Not *MsgPackData
		DebuggerError("A #Null MsgPackData pointer was passed !")
		ProcedureReturn #MsgPack_FormatCode_Invalid
	EndIf
	
	If _MsgPackIsAtTheEnd(*MsgPackData)
		DebuggerError("End of buffer reached, cannot check data format code !")
		ProcedureReturn #MsgPack_FormatCode_Invalid
	EndIf
	
	DataFormatCode = PeekA(*MsgPackData\Buffer)
	
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
		
		; All fields types are mapped to codes present in the enumeration.
		ProcedureReturn DataFormatCode
	Else
		; 0xE0 - 0xFF
		ProcedureReturn #MsgPack_FormatCode_FixIntNegative
	EndIf
EndProcedure


;-> Format Types

Procedure.MsgPack_DataType MsgPackFormatCodeToDataType(FormatCode.MsgPack_FormatCode)
	Select FormatCode
		Case #MsgPack_FormatCode_FixIntPositive,
		     #MsgPack_FormatCode_UInt8,
		     #MsgPack_FormatCode_UInt16,
		     #MsgPack_FormatCode_UInt32,
		     #MsgPack_FormatCode_UInt64,
		     #MsgPack_FormatCode_Int8,
		     #MsgPack_FormatCode_Int16,
		     #MsgPack_FormatCode_Int32,
		     #MsgPack_FormatCode_Int64,
		     #MsgPack_FormatCode_FixIntNegative:
			ProcedureReturn #MsgPack_DataTypes_Integer
			
		Case #MsgPack_FormatCode_Float32,
		     #MsgPack_FormatCode_Float64:
			ProcedureReturn #MsgPack_DataTypes_Float
			
		Case #MsgPack_FormatCode_FixStr,
		     #MsgPack_FormatCode_Str8,
		     #MsgPack_FormatCode_Str16,
		     #MsgPack_FormatCode_Str32:
			ProcedureReturn #MsgPack_DataTypes_String
			
		Case #MsgPack_FormatCode_Null:
			ProcedureReturn #MsgPack_DataTypes_Null
			
		Case #MsgPack_FormatCode_False,
		     #MsgPack_FormatCode_True:
			ProcedureReturn #MsgPack_DataTypes_Boolean
			
		Case #MsgPack_FormatCode_Bin8,
		     #MsgPack_FormatCode_Bin16,
		     #MsgPack_FormatCode_Bin32:
			ProcedureReturn #MsgPack_DataTypes_Binary
			
		Case #MsgPack_FormatCode_FixArray,
		     #MsgPack_FormatCode_Array16,
		     #MsgPack_FormatCode_Array32:
			ProcedureReturn #MsgPack_DataTypes_Array
			
		Case #MsgPack_FormatCode_FixMap,
		     #MsgPack_FormatCode_Map16,
		     #MsgPack_FormatCode_Map32:
			ProcedureReturn #MsgPack_DataTypes_Map
			
		Case #MsgPack_FormatCode_Ext8,
		     #MsgPack_FormatCode_Ext16,
		     #MsgPack_FormatCode_Ext32,
		     #MsgPack_FormatCode_FixExt1,
		     #MsgPack_FormatCode_FixExt2,
		     #MsgPack_FormatCode_FixExt4,
		     #MsgPack_FormatCode_FixExt8,
		     #MsgPack_FormatCode_FixExt16:
			ProcedureReturn #MsgPack_DataTypes_Extension
			
		Case #MsgPack_FormatCode_Invalid:
		Default:
			; FIXME: ADD MESSAGE HERE !!!
			DebuggerWarning("")
			ProcedureReturn #MsgPack_DataTypes_Unknown
	EndSelect
EndProcedure
