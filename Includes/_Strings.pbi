;{- Code Header
; ==- Basic Info -================================
;     Name: _Strings.pbi
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

; The spec defines str as UTF-8, which is the default everywhere.
; `#PB_Ascii` and `#PB_Unicode` (UTF-16 LE) are supported for peers that don't follow it.
; Sizes are always in bytes of the encoded string, without any null terminator.
; Strings containing a null character will be truncated on read, as with `PeekS()`.



; ------------------------------------------------------------------------------
;- Compiler directive

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Binary.pbi"



; ------------------------------------------------------------------------------
;- Private macros

Macro _MsgPackIsSupportedStringEncoding(Encoding)
	(Encoding = #PB_UTF8 Or Encoding = #PB_Ascii Or Encoding = #PB_Unicode)
EndMacro



; ------------------------------------------------------------------------------
;- Procedures

;-> Internal helpers

; Returns the byte length of `String` once encoded in `Encoding`, without a null terminator.
; Sets the structure's error code and returns `#MsgPack_InvalidSize` on unsupported encodings.
Procedure.q _MsgPackGetEncodedStringSize(*MsgPackData.MsgPackData, String.s, Encoding.i)
	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_InvalidSize
		EndIf
	CompilerEndIf

	If Not _MsgPackIsSupportedStringEncoding(Encoding)
		DebuggerError("Unsupported string encoding: " + Str(Encoding))
		*MsgPackData\LastError = #MsgPack_Error_UnsupportedStringEncoding
		ProcedureReturn #MsgPack_InvalidSize
	EndIf

	ProcedureReturn StringByteLength(String, Encoding)
EndProcedure


; Writes a full str field whose encoded size is already known.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteStringField(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, SizeFieldByteLength.a, String.s, StringSize.q, Encoding.i)
	Protected ErrorCode.MsgPack_ErrorCode

	ErrorCode = _MsgPackWriteSizedFieldHeader(*MsgPackData, FormatCode, SizeFieldByteLength, StringSize)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	If StringSize > 0
		PokeS(*MsgPackData\Buffer + *MsgPackData\BufferOffset, String, -1, Encoding | #PB_String_NoZero)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + StringSize
	EndIf

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Writes a str field with an explicit format code.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteStringAs(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, SizeFieldByteLength.a, String.s, Encoding.i)
	Protected StringSize.q

	StringSize = _MsgPackGetEncodedStringSize(*MsgPackData, String, Encoding)
	If StringSize = #MsgPack_InvalidSize
		ProcedureReturn MsgPackLastError(*MsgPackData)
	EndIf

	ProcedureReturn _MsgPackWriteStringField(*MsgPackData, FormatCode, SizeFieldByteLength, String, StringSize, Encoding)
EndProcedure



;-> Getters

; Reads the str field at the current offset and decodes it from `Encoding`.
; Returns: The decoded string.
; OnError: Returns `""` and sets the `MsgPackData\LastError` field.
Procedure.s MsgPackReadString(*MsgPackData.MsgPackData, Encoding.i = #PB_UTF8)
	Protected HeaderSize.i
	Protected StringSize.q
	Protected *StringStart
	Protected ReturnedValue.s = ""

	If _MsgPackReadSizedFieldHeader(*MsgPackData, #MsgPack_DataTypes_String, @HeaderSize, @StringSize) <> #MsgPack_Error_Success
		ProcedureReturn ""
	EndIf

	If Not _MsgPackIsSupportedStringEncoding(Encoding)
		DebuggerError("Unsupported string encoding: " + Str(Encoding))
		*MsgPackData\LastError = #MsgPack_Error_UnsupportedStringEncoding
		ProcedureReturn ""
	EndIf

	If Encoding = #PB_Unicode And StringSize % 2 <> 0
		DebuggerWarning("UTF-16 string has an odd byte size !")
		*MsgPackData\LastError = #MsgPack_Error_InvalidStringSize
		ProcedureReturn ""
	EndIf

	*StringStart = *MsgPackData\Buffer + *MsgPackData\BufferOffset + HeaderSize

	If StringSize > 0
		Select Encoding
			Case #PB_UTF8
				ReturnedValue = PeekS(*StringStart, StringSize, #PB_UTF8 | #PB_ByteLength)
			Case #PB_Ascii
				ReturnedValue = PeekS(*StringStart, StringSize, #PB_Ascii)
			Case #PB_Unicode
				ReturnedValue = PeekS(*StringStart, StringSize / 2, #PB_Unicode)
		EndSelect
	EndIf

	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + HeaderSize + StringSize

	ProcedureReturn ReturnedValue
EndProcedure



;-> Setters

; Writes `String` encoded as `Encoding` using the smallest str format code that fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteString(*MsgPackData.MsgPackData, String.s, Encoding.i = #PB_UTF8)
	Protected StringSize.q

	StringSize = _MsgPackGetEncodedStringSize(*MsgPackData, String, Encoding)
	If StringSize = #MsgPack_InvalidSize
		ProcedureReturn MsgPackLastError(*MsgPackData)
	EndIf

	If StringSize <= 31
		ProcedureReturn _MsgPackWriteStringField(*MsgPackData, #MsgPack_FormatCode_FixStr, 0, String, StringSize, Encoding)
	ElseIf StringSize <= 255
		ProcedureReturn _MsgPackWriteStringField(*MsgPackData, #MsgPack_FormatCode_Str8, 1, String, StringSize, Encoding)
	ElseIf StringSize <= 65535
		ProcedureReturn _MsgPackWriteStringField(*MsgPackData, #MsgPack_FormatCode_Str16, 2, String, StringSize, Encoding)
	Else
		; Sizes above `(2^32)-1` are rejected by the helper.
		ProcedureReturn _MsgPackWriteStringField(*MsgPackData, #MsgPack_FormatCode_Str32, 4, String, StringSize, Encoding)
	EndIf
EndProcedure



; ------------------------------------------------------------------------------
;- Macros

Macro MsgPackWriteFixStr(MsgPackData, String, Encoding = #PB_UTF8)
	_MsgPackWriteStringAs(MsgPackData, #MsgPack_FormatCode_FixStr, 0, String, Encoding)
EndMacro

Macro MsgPackWriteStr8(MsgPackData, String, Encoding = #PB_UTF8)
	_MsgPackWriteStringAs(MsgPackData, #MsgPack_FormatCode_Str8, 1, String, Encoding)
EndMacro

Macro MsgPackWriteStr16(MsgPackData, String, Encoding = #PB_UTF8)
	_MsgPackWriteStringAs(MsgPackData, #MsgPack_FormatCode_Str16, 2, String, Encoding)
EndMacro

Macro MsgPackWriteStr32(MsgPackData, String, Encoding = #PB_UTF8)
	_MsgPackWriteStringAs(MsgPackData, #MsgPack_FormatCode_Str32, 4, String, Encoding)
EndMacro
