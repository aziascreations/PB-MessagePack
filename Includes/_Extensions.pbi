;{- Code Header
; ==- Basic Info -================================
;     Name: _Extensions.pbi
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

; The ext type is a signed byte, `-128` to `-1` being reserved by the spec. (`-1` = timestamp)
; Reserved types are not rejected, so predefined types can be written with these procedures.
; FixExt fields have no size field, their data size is implied by the format code.
; See "_Binary.pbi" for the shared "sized field" helpers.



; ------------------------------------------------------------------------------
;- Compiler directive

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Primitives.pbi"
XIncludeFile "./_Binary.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Internal helpers

; Writes a full ext field by copying `DataSize` bytes from `*Data`.
; `SizeFieldByteLength` set to `0` indicates a FixExt whose implied size must match `DataSize`.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteExtField(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, SizeFieldByteLength.a, ExtType.b, *Data, DataSize.q)
	Protected ErrorCode.MsgPack_ErrorCode
	Protected FixExtSize.q

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	If SizeFieldByteLength = 0
		Select FormatCode
			Case #MsgPack_FormatCode_FixExt1 : FixExtSize = 1
			Case #MsgPack_FormatCode_FixExt2 : FixExtSize = 2
			Case #MsgPack_FormatCode_FixExt4 : FixExtSize = 4
			Case #MsgPack_FormatCode_FixExt8 : FixExtSize = 8
			Case #MsgPack_FormatCode_FixExt16 : FixExtSize = 16
			Default
				FixExtSize = #MsgPack_InvalidSize
		EndSelect

		If DataSize <> FixExtSize
			DebuggerError("Invalid FixExt size: " + Str(DataSize))
			*MsgPackData\LastError = #MsgPack_Error_InvalidValue
			ProcedureReturn #MsgPack_Error_InvalidValue
		EndIf

		ErrorCode = _MsgPackReserveWrite(*MsgPackData, 2 + DataSize)
		If ErrorCode <> #MsgPack_Error_Success
			ProcedureReturn ErrorCode
		EndIf

		PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1
	Else
		ErrorCode = _MsgPackWriteSizedFieldHeader(*MsgPackData, FormatCode, SizeFieldByteLength, DataSize, 1)
		If ErrorCode <> #MsgPack_Error_Success
			ProcedureReturn ErrorCode
		EndIf
	EndIf

	PokeB(*MsgPackData\Buffer + *MsgPackData\BufferOffset, ExtType)
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1

	If DataSize > 0
		CopyMemory(*Data, *MsgPackData\Buffer + *MsgPackData\BufferOffset, DataSize)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + DataSize
	EndIf

	ProcedureReturn #MsgPack_Error_Success
EndProcedure



;-> Getters

; Reads the type of the ext field at the current offset, without moving it.
; Returns: The ext type.
; OnError: Returns `0` and sets the `MsgPackData\LastError` field.
Procedure.b MsgPackGetExtensionType(*MsgPackData.MsgPackData)
	Protected HeaderSize.i
	Protected DataSize.q

	If _MsgPackReadSizedFieldHeader(*MsgPackData, #MsgPack_DataTypes_Extension, @HeaderSize, @DataSize) <> #MsgPack_Error_Success
		ProcedureReturn 0
	EndIf

	ProcedureReturn PeekB(*MsgPackData\Buffer + *MsgPackData\BufferOffset + HeaderSize - 1)
EndProcedure


; Copies the data of the ext field at the current offset into `*OutputBuffer`.
; Its type can be read beforehand with `MsgPackGetExtensionType()`.
; Returns: The number of bytes copied.
; OnError: Returns `#MsgPack_InvalidSize` and sets the `MsgPackData\LastError` field.
;          The offset is left untouched, so a bigger buffer can be given afterward.
Procedure.q MsgPackReadExtension(*MsgPackData.MsgPackData, *OutputBuffer, OutputBufferSize.q)
	ProcedureReturn _MsgPackReadSizedFieldData(*MsgPackData, #MsgPack_DataTypes_Extension, *OutputBuffer, OutputBufferSize)
EndProcedure


; Copies the data of the ext field at the current offset into a new buffer.
; Its type can be read beforehand with `MsgPackGetExtensionType()`.
; Returns: A buffer from `AllocateMemory()` that the caller must free with `FreeMemory()`.
;          Its size can be obtained with `MemorySize()`.
;          Empty ext fields return `#Null` with `MsgPackData\LastError` set to `#MsgPack_Error_Success`.
; OnError: Returns `#Null` and sets the `MsgPackData\LastError` field.
Procedure.i MsgPackCopyExtension(*MsgPackData.MsgPackData)
	ProcedureReturn _MsgPackCopySizedFieldData(*MsgPackData, #MsgPack_DataTypes_Extension)
EndProcedure



;-> Setters

; Writes `BufferSize` bytes from `*Buffer` as an ext8 of type `ExtType`, even if a smaller format code fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteExt8(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_Ext8, 1, ExtType, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` as an ext16 of type `ExtType`, even if a smaller format code fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteExt16(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_Ext16, 2, ExtType, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` as an ext32 of type `ExtType`, even if a smaller format code fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteExt32(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_Ext32, 4, ExtType, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` as an ext of type `ExtType` using the smallest
;  format code that fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteExtension(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)
	Select BufferSize
		Case 1
			ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_FixExt1, 0, ExtType, *Buffer, BufferSize)
		Case 2
			ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_FixExt2, 0, ExtType, *Buffer, BufferSize)
		Case 4
			ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_FixExt4, 0, ExtType, *Buffer, BufferSize)
		Case 8
			ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_FixExt8, 0, ExtType, *Buffer, BufferSize)
		Case 16
			ProcedureReturn _MsgPackWriteExtField(*MsgPackData, #MsgPack_FormatCode_FixExt16, 0, ExtType, *Buffer, BufferSize)
	EndSelect

	If BufferSize <= 255
		ProcedureReturn MsgPackWriteExt8(*MsgPackData, ExtType, *Buffer, BufferSize)
	ElseIf BufferSize <= 65535
		ProcedureReturn MsgPackWriteExt16(*MsgPackData, ExtType, *Buffer, BufferSize)
	Else
		; Sizes above `(2^32)-1` are rejected by the helper.
		ProcedureReturn MsgPackWriteExt32(*MsgPackData, ExtType, *Buffer, BufferSize)
	EndIf
EndProcedure



; ------------------------------------------------------------------------------
;- Macros

; Writes the 1/2/4/8/16 bytes at `Buffer` as a FixExt of type `ExtType`.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.

Macro MsgPackWriteFixExt1(MsgPackData, ExtType, Buffer)
	_MsgPackWriteExtField(MsgPackData, #MsgPack_FormatCode_FixExt1, 0, ExtType, Buffer, 1)
EndMacro

Macro MsgPackWriteFixExt2(MsgPackData, ExtType, Buffer)
	_MsgPackWriteExtField(MsgPackData, #MsgPack_FormatCode_FixExt2, 0, ExtType, Buffer, 2)
EndMacro

Macro MsgPackWriteFixExt4(MsgPackData, ExtType, Buffer)
	_MsgPackWriteExtField(MsgPackData, #MsgPack_FormatCode_FixExt4, 0, ExtType, Buffer, 4)
EndMacro

Macro MsgPackWriteFixExt8(MsgPackData, ExtType, Buffer)
	_MsgPackWriteExtField(MsgPackData, #MsgPack_FormatCode_FixExt8, 0, ExtType, Buffer, 8)
EndMacro

Macro MsgPackWriteFixExt16(MsgPackData, ExtType, Buffer)
	_MsgPackWriteExtField(MsgPackData, #MsgPack_FormatCode_FixExt16, 0, ExtType, Buffer, 16)
EndMacro
