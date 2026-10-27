# MessagePack.pbi
PureBasic include for creating/reading MessagePack data.

**When integrating, do not read any `.pbi` files to save on tokens, use the API below.**


## APIs

### Behaviour
* ???
* The internal offset is auto-incremented on all complete reads and writes.
  * Does not apply to `MsgPackGetFormatCode`.
* The internal buffer is automatically resized as needed.


### Type aliases/macros

* `.MsgPack_FormatCode` \
  Represents the low-level format code from the specification. \
  When [interacting] with fix* types, the value in it will be set to 0. 
  * `#MsgPack_FormatCode_Null`
  * `#MsgPack_FormatCode_False`
  * `#MsgPack_FormatCode_True`
  * `#MsgPack_FormatCode_FixIntPositive`
  * `#MsgPack_FormatCode_FixIntNegative`
  * `#MsgPack_FormatCode_UInt8`
  * `#MsgPack_FormatCode_UInt16`
  * `#MsgPack_FormatCode_UInt32`
  * `#MsgPack_FormatCode_UInt64`
  * `#MsgPack_FormatCode_Int8`
  * `#MsgPack_FormatCode_Int16`
  * `#MsgPack_FormatCode_Int32`
  * `#MsgPack_FormatCode_Int64`
  * `#MsgPack_FormatCode_Float32`
  * `#MsgPack_FormatCode_Float64`
  * `#MsgPack_FormatCode_FixStr`
  * `#MsgPack_FormatCode_Str8`
  * `#MsgPack_FormatCode_Str16`
  * `#MsgPack_FormatCode_Str32`
  * `#MsgPack_FormatCode_Bin8`
  * `#MsgPack_FormatCode_Bin16`
  * `#MsgPack_FormatCode_Bin32`
  * `#MsgPack_FormatCode_FixArray`
  * `#MsgPack_FormatCode_Array16`
  * `#MsgPack_FormatCode_Array32`
  * `#MsgPack_FormatCode_FixMap`
  * `#MsgPack_FormatCode_Map16`
  * `#MsgPack_FormatCode_Map32`
  * `#MsgPack_FormatCode_FixExt1`
  * `#MsgPack_FormatCode_FixExt2`
  * `#MsgPack_FormatCode_FixExt4`
  * `#MsgPack_FormatCode_FixExt8`
  * `#MsgPack_FormatCode_FixExt16`
  * `#MsgPack_FormatCode_Ext8`
  * `#MsgPack_FormatCode_Ext16`
  * `#MsgPack_FormatCode_Ext32`
  * `#MsgPack_FormatCode_Invalid`


* `.MsgPack_DataType` \
  High-level representation of a format code. \
  Should be used when iterating on complex objects to detect the members' general type. 
  * `#MsgPack_DataTypes_Unknown` - The `0x??` format code.
  * `#MsgPack_DataTypes_Null`
  * `#MsgPack_DataTypes_Boolean`
  * `#MsgPack_DataTypes_Integer`
  * `#MsgPack_DataTypes_Float`
  * `#MsgPack_DataTypes_String`
  * `#MsgPack_DataTypes_Binary`
  * `#MsgPack_DataTypes_Array`
  * `#MsgPack_DataTypes_Map`
  * `#MsgPack_DataTypes_Ext`
  * `#MsgPack_DataTypes_Extension`

* `.MsgPack_ErrorCode` \
  * `#MsgPack_Error_Success = 0`
  * `#MsgPack_Error_NullPointerGiven`
  * `#MsgPack_Error_BufferTooSmall`
  * `#MsgPack_Error_FailedToGrowBuffer`
  * `#MsgPack_Error_AtOrPastTheEndOfBuffer`
  * `#MsgPack_Error_ReadPastEndOfBuffer`
  * `#MsgPack_Error_InvalidFormatCode`
  * `#MsgPack_Error_FailedToAllocateBuffer`
  * `#MsgPack_Error_BinaryDataSizeIsNegative`
  * `#MsgPack_Error_BinaryDataSizeIsTooBig`
  * `#MsgPack_Error_OutputBufferTooSmall`
  * `#MsgPack_Error_UnsupportedStringEncoding`
  * `#MsgPack_Error_InvalidStringSize`
  * `#MsgPack_Error_CannotGrowBufferDueToConfig`

* `.MsgPack_DataFlag` \
  Internal flags, do not touch.


### Commons
* `MsgPackLastError.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
  ...


### Thingies
* `MsgPackCreate.i(InitialSize.i)` \
  Prepares an internal structure for a buffer of a given size `InitialSize.i`. \
  Returns `#Null` on errors.

* `MsgPackWrapMsgBuffer.i(*Buffer, BufferSize.i)` \
  Wraps a given buffer `*Buffer` of a given size `InitialSize.i` into an internal structure. \
  Returns `#Null` on errors.

* Procedure.b MsgPackFree(*MsgPackData.MsgPackData, FreeDataBuffer.b = #False) \
  Frees a given internal structure `*MsgPackData` and its associated buffer if `FreeDataBuffer` is `#True`.
  Returns `#True` if freed properly, `#False` otherwise.


### Literals
* `MsgPackReadBoolean.b(*MsgPackData.MsgPackData)`
  Attempts to read the boolean at the current internal offset. \
  Returns `#True` or `#False`. \
  May set the internal error code if any happens. \
  See: `MsgPackLastError`

* `MsgPackWriteNull.MsgPack_ErrorCode(*MsgPackData.MsgPackData)`
  Attempts to write `#Null` at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteTrue.MsgPack_ErrorCode(*MsgPackData.MsgPackData)`
  Attempts to write `#True` at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteFalse.MsgPack_ErrorCode(*MsgPackData.MsgPackData)`
  Attempts to write `#False` at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.


### Binary
* `MsgPackWriteBinary.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)` \
  Writes `BufferSize` bytes from `*Buffer` using the smallest bin format code that fits. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteBin8/16/32.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)` \
  Same as `MsgPackWriteBinary`, but forces the given format code, even if a smaller one fits.

* `MsgPackReadBinary.q(*MsgPackData.MsgPackData, *OutputBuffer, OutputBufferSize.q)` \
  Copies the bin field at the current internal offset into `*OutputBuffer`. \
  Returns the number of bytes copied, or `#MsgPack_InvalidSize` on errors. \
  The offset isn't moved on errors, so it can be retried with a bigger buffer. \
  See: `MsgPackLastError`

* `MsgPackCopyBinary.i(*MsgPackData.MsgPackData)` \
  Copies the bin field at the current internal offset into a new buffer that must be freed with `FreeMemory()`. \
  Returns `#Null` on errors, or for empty bin fields with `#MsgPack_Error_Success` as the last error. \
  See: `MsgPackLastError`


### Strings
Supported encodings: `#PB_UTF8` (default, per spec), `#PB_Ascii`, `#PB_Unicode` (UTF-16 LE).

* `MsgPackWriteString.MsgPack_ErrorCode(*MsgPackData.MsgPackData, String.s, Encoding.i = #PB_UTF8)` \
  Writes `String` using the smallest str format code that fits its encoded byte size. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteFixStr/Str8/Str16/Str32.MsgPack_ErrorCode(*MsgPackData.MsgPackData, String.s, Encoding.i = #PB_UTF8)` \
  Same as `MsgPackWriteString`, but forces the given format code.

* `MsgPackReadString.s(*MsgPackData.MsgPackData, Encoding.i = #PB_UTF8)` \
  Reads any str field at the current internal offset. \
  Returns `""` on errors and sets the internal error code. \
  See: `MsgPackLastError`


## Remarks
* Never touch the `MsgPackData` structure unless you **absolutely** have to.


## Support
- Both the ASM and C backends
- x86, x64, arm64
