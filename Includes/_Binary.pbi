;{- Code Header
; ==- Basic Info -================================
;     Name: _Binary.pbi
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

; Sizes are all unsigned 8/16/32, using Q fixes any potential issues !

; The "sized field" helpers below handle every `[FormatCode][Size][Data]` layout
;  shared by the str and bin families.
; The `SizeFieldByteLength` parameter is the number of bytes used to store the size:
;  * `0` - Size is stored in the format code's lower 5 bits. (FixStr)
;  * `1` - Str8, Bin8
;  * `2` - Str16, Bin16
;  * `4` - Str32, Bin32



; ------------------------------------------------------------------------------
;- Compiler directive

CompilerIf #PB_Compiler_IsMainFile
	EnableExplicit
CompilerEndIf

XIncludeFile "./_Commons.pbi"
XIncludeFile "./_Utils.pbi"
XIncludeFile "./_Allocators.pbi"
XIncludeFile "./_Primitives.pbi"



; ------------------------------------------------------------------------------
;- Procedures

;-> Internal helpers

; Validates `DataSize`, reserves space for the whole field, writes its format code
;  and size, and moves the offset right after them.
; The caller is expected to write `DataSize` bytes of data and move the offset afterward.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteSizedFieldHeader(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, SizeFieldByteLength.a, DataSize.q)
	Protected MaxDataSize.q
	Protected ErrorCode.MsgPack_ErrorCode

	CompilerIf Not #MsgPack_DisableNullChecks
		If Not *MsgPackData
			DebuggerError("A #Null MsgPackData pointer was passed !")
			ProcedureReturn #MsgPack_Error_NullPointerGiven
		EndIf
	CompilerEndIf

	Select SizeFieldByteLength
		Case 0 :
			MaxDataSize = 31
		Case 1 :
			MaxDataSize = 255
		Case 2 :
			MaxDataSize = 65535
		Case 4 :
			MaxDataSize = 4294967295
		Default
			DebuggerError("Invalid size field length: " + Str(SizeFieldByteLength))
			*MsgPackData\LastError = #MsgPack_Error_InvalidValue
			ProcedureReturn #MsgPack_Error_InvalidValue
	EndSelect

	If DataSize < 0
		DebuggerWarning("Received negative size !")
		*MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsNegative
		ProcedureReturn #MsgPack_Error_BinaryDataSizeIsNegative
	ElseIf DataSize > MaxDataSize
		DebuggerWarning("Data is bigger than `" + Str(MaxDataSize) + "` bytes !")
		*MsgPackData\LastError = #MsgPack_Error_BinaryDataSizeIsTooBig
		ProcedureReturn #MsgPack_Error_BinaryDataSizeIsTooBig
	EndIf

	ErrorCode = _MsgPackReserveWrite(*MsgPackData, 1 + SizeFieldByteLength + DataSize)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	Select SizeFieldByteLength
		Case 0
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode | DataSize)
		Case 1
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, DataSize)
		Case 2
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapU16(DataSize))
		Case 4
			PokeA(*MsgPackData\Buffer + *MsgPackData\BufferOffset, FormatCode)
			PokeL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1, EndianSwapI32(DataSize))
	EndSelect
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + 1 + SizeFieldByteLength

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Writes a full `[FormatCode][Size][Data]` field by copying `DataSize` bytes from `*Data`.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackWriteSizedField(*MsgPackData.MsgPackData, FormatCode.MsgPack_FormatCode, SizeFieldByteLength.a, *Data, DataSize.q)
	Protected ErrorCode.MsgPack_ErrorCode

	ErrorCode = _MsgPackWriteSizedFieldHeader(*MsgPackData, FormatCode, SizeFieldByteLength, DataSize)
	If ErrorCode <> #MsgPack_Error_Success
		ProcedureReturn ErrorCode
	EndIf

	If DataSize > 0
		CopyMemory(*Data, *MsgPackData\Buffer + *MsgPackData\BufferOffset, DataSize)
		*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + DataSize
	EndIf

	ProcedureReturn #MsgPack_Error_Success
EndProcedure


; Reads the header of a str or bin field at the current offset, without moving it.
; `ExpectedDataType` must be `#MsgPack_DataTypes_String` or `#MsgPack_DataTypes_Binary`.
; On success, `*HeaderSize` receives the format code + size field length, and `*DataSize`
;  the data's length, both guaranteed to be within the buffer.
; Sets the structure's error code and returns it.
Procedure.MsgPack_ErrorCode _MsgPackReadSizedFieldHeader(*MsgPackData.MsgPackData, ExpectedDataType.MsgPack_DataType, *HeaderSize.Integer, *DataSize.Quad)
	Protected FormatCode.MsgPack_FormatCode
	Protected SizeFieldByteLength.a
	Protected DataSize.q

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

	FormatCode = MsgPackGetFormatCode(*MsgPackData)
	If MsgPackFormatCodeToDataType(FormatCode) <> ExpectedDataType
		Debug("Unexpected format code !  (" + RSet(Hex(PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset)), 2, "0") + ")")
		*MsgPackData\LastError = #MsgPack_Error_InvalidFormatCode
		ProcedureReturn #MsgPack_Error_InvalidFormatCode
	EndIf

	Select FormatCode
		Case #MsgPack_FormatCode_FixStr:
			SizeFieldByteLength = 0
		Case #MsgPack_FormatCode_Str8,
		     #MsgPack_FormatCode_Bin8:
			 SizeFieldByteLength = 1
		Case #MsgPack_FormatCode_Str16,
		     #MsgPack_FormatCode_Bin16:
			 SizeFieldByteLength = 2
		Case #MsgPack_FormatCode_Str32,
		     #MsgPack_FormatCode_Bin32:
			 SizeFieldByteLength = 4
	EndSelect

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + SizeFieldByteLength)
		Debug("End of buffer reached, cannot read the field's size !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn #MsgPack_Error_BufferTooSmall
	EndIf

	Select SizeFieldByteLength
		Case 0:
			DataSize = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset) & %00011111
		Case 1:
			DataSize = PeekA(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)
		Case 2:
			DataSize = EndianSwapU16(PeekU(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1))
		Case 4:
			DataSize = EndianSwapI32(PeekL(*MsgPackData\Buffer + *MsgPackData\BufferOffset + 1)) & $FFFFFFFF
	EndSelect

	If Not _MsgPackHasSpaceLeft(*MsgPackData, 1 + SizeFieldByteLength + DataSize)
		Debug("End of buffer reached, cannot read the field's data !")
		*MsgPackData\LastError = #MsgPack_Error_BufferTooSmall
		ProcedureReturn #MsgPack_Error_BufferTooSmall
	EndIf

	*HeaderSize\i = 1 + SizeFieldByteLength
	*DataSize\q = DataSize

	*MsgPackData\LastError = #MsgPack_Error_Success
	ProcedureReturn #MsgPack_Error_Success
EndProcedure



;-> Getters

; Copies the bin field at the current offset into `*OutputBuffer`.
; Returns: The number of bytes copied.
; OnError: Returns `#MsgPack_InvalidSize` and sets the `MsgPackData\LastError` field.
;          The offset is left untouched, so a bigger buffer can be given afterward.
Procedure.q MsgPackReadBinary(*MsgPackData.MsgPackData, *OutputBuffer, OutputBufferSize.q)
	Protected HeaderSize.i
	Protected DataSize.q
	
	If _MsgPackReadSizedFieldHeader(*MsgPackData, #MsgPack_DataTypes_Binary, @HeaderSize, @DataSize) <> #MsgPack_Error_Success
		ProcedureReturn #MsgPack_InvalidSize
	EndIf
	
	If DataSize > OutputBufferSize
		Debug("Output buffer is too small !  (" + Str(OutputBufferSize) + " < " + Str(DataSize) + ")")
		*MsgPackData\LastError = #MsgPack_Error_OutputBufferTooSmall
		ProcedureReturn #MsgPack_InvalidSize
	EndIf
	
	If DataSize > 0
		CompilerIf Not #MsgPack_DisableNullChecks
			If Not *OutputBuffer
				DebuggerError("A #Null output buffer was passed !")
				*MsgPackData\LastError = #MsgPack_Error_NullPointerGiven
				ProcedureReturn #MsgPack_InvalidSize
			EndIf
		CompilerEndIf
		
		CopyMemory(*MsgPackData\Buffer + *MsgPackData\BufferOffset + HeaderSize, *OutputBuffer, DataSize)
	EndIf
	
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + HeaderSize + DataSize
	
	ProcedureReturn DataSize
EndProcedure


; Copies the bin field at the current offset into a new buffer.
; Returns: A buffer from `AllocateMemory()` that the caller must free with `FreeMemory()`.
;          Its size can be obtained with `MemorySize()`.
;          Empty bin fields return `#Null` with `MsgPackData\LastError` set to `#MsgPack_Error_Success`.
; OnError: Returns `#Null` and sets the `MsgPackData\LastError` field.
Procedure.i MsgPackCopyBinary(*MsgPackData.MsgPackData)
	Protected HeaderSize.i
	Protected DataSize.q
	Protected *ReturnedValue = #Null
	
	If _MsgPackReadSizedFieldHeader(*MsgPackData, #MsgPack_DataTypes_Binary, @HeaderSize, @DataSize) <> #MsgPack_Error_Success
		ProcedureReturn #Null
	EndIf
	
	If DataSize > 0
		*ReturnedValue = AllocateMemory(DataSize, #PB_Memory_NoClear)
		If Not *ReturnedValue
			Debug("Failed to allocate memory for the copied binary !")
			*MsgPackData\LastError = #MsgPack_Error_FailedToAllocateBuffer
			ProcedureReturn #Null
		EndIf
		
		CopyMemory(*MsgPackData\Buffer + *MsgPackData\BufferOffset + HeaderSize, *ReturnedValue, DataSize)
	EndIf
	
	*MsgPackData\BufferOffset = *MsgPackData\BufferOffset + HeaderSize + DataSize
	
	ProcedureReturn *ReturnedValue
EndProcedure



;-> Setters

; Writes `BufferSize` bytes from `*Buffer` as a bin8.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteBin8(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteSizedField(*MsgPackData, #MsgPack_FormatCode_Bin8, 1, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` as a bin16, even if a smaller format code fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteBin16(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteSizedField(*MsgPackData, #MsgPack_FormatCode_Bin16, 2, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` as a bin32, even if a smaller format code fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteBin32(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	ProcedureReturn _MsgPackWriteSizedField(*MsgPackData, #MsgPack_FormatCode_Bin32, 4, *Buffer, BufferSize)
EndProcedure


; Writes `BufferSize` bytes from `*Buffer` using the smallest bin format code that fits.
; Returns `#MsgPack_Error_Success` on success, something else otherwise.
Procedure.MsgPack_ErrorCode MsgPackWriteBinary(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)
	If BufferSize <= 255
		ProcedureReturn MsgPackWriteBin8(*MsgPackData, *Buffer, BufferSize)
	ElseIf BufferSize <= 65535
		ProcedureReturn MsgPackWriteBin16(*MsgPackData, *Buffer, BufferSize)
	Else
		; Sizes above `(2^32)-1` are rejected by the helper.
		ProcedureReturn MsgPackWriteBin32(*MsgPackData, *Buffer, BufferSize)
	EndIf
EndProcedure

