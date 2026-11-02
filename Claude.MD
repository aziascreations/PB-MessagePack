# MessagePack.pbi
PureBasic include for creating/reading MessagePack data.

**When integrating, do not read any `.pbi` files to save on tokens, use the API below.**


## APIs

### Behaviour
* ???
* The internal offset is auto-incremented on all complete reads and writes.
  * Does not apply to `MsgPackGetFormatCode`.
  * Can be disabled with the internal `#MsgPack_DataFlags_MoveOffsetAfterRead/Write` flags, honored by every read and write.
* The internal buffer is automatically resized as needed.
* Invalid or truncated data never raises a `DebuggerError`, only programming errors do. (e.g.: `#Null` pointers)
* Views from `MsgPackExamine` are read-only, writes return `#MsgPack_Error_BufferIsReadOnly`.


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
  * `#MsgPack_Error_TooManyEntries`
  * `#MsgPack_Error_OddMapFieldCount`
  * `#MsgPack_Error_CannotGrowBufferDueToConfig`
  * `#MsgPack_Error_BufferIsReadOnly`

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

* `MsgPackFree.b(*MsgPackData.MsgPackData, FreeDataBuffer.b)` \
  Frees a given internal structure `*MsgPackData` and its associated buffer if `FreeDataBuffer` is `#True`. \
  `FreeDataBuffer` is mandatory, use `#False` for buffers wrapped with `MsgPackWrapMsgBuffer` that the caller still owns. \
  Returns `#True` if freed properly, `#False` otherwise.

* `MsgPackFinalize.i(*MsgPackData.MsgPackData)` \
  Frees a given internal structure `*MsgPackData` and returns its buffer, shrunk to the number of bytes written. \
  The caller takes ownership of the buffer, gets its size with `MemorySize()` and frees it with `FreeMemory()`. \
  Fails if the buffer is owned by the caller or nothing was written. \
  Returns `#Null` on errors and leaves `*MsgPackData` untouched. \
  See: `MsgPackLastError`


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

* `MsgPackWriteBoolean.MsgPack_ErrorCode(*MsgPackData.MsgPackData, Boolean.b)`
  Writes `#True` or `#False` depending on `Boolean`. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackReadNull.MsgPack_ErrorCode(*MsgPackData.MsgPackData)`
  Attempts to read a nil at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise, in which case the offset isn't moved.


### Integers & Floats
* `MsgPackWriteInteger.MsgPack_ErrorCode(*MsgPackData.MsgPackData, Value.q)` \
  Writes `Value` using the smallest int format code that fits, fixints included. \
  Positive values always use the unsigned format codes. \
  UInt64 values above `(2^63)-1` must be written with `MsgPackWriteUInt64`.

* `MsgPackWriteFixInt.MsgPack_ErrorCode(*MsgPackData.MsgPackData, Value.q)` \
  Writes `Value` as a fixint, from `-32` to `127`. \
  Returns `#MsgPack_Error_ValueOverflow` if it doesn't fit.

* `MsgPackWrite/Read[U]Int8/16/32/64`, `MsgPackWrite/ReadFloat32/64` \
  Force the given format code. Aliases: `MsgPackWrite/ReadU8`, `I8`, ..., `F64`. \
  `UInt32` and `UInt64` use `.l` and `.q`, so their values above the signed max come back negative.

* `MsgPackReadInteger.q(*MsgPackData.MsgPackData)` \
  Reads any int field at the current internal offset, fixints included. \
  Returns `0` on errors and sets the internal error code. \
  UInt64 values above `(2^63)-1` fail with `#MsgPack_Error_ValueOverflow` without moving the offset, so they can be read with `MsgPackReadUInt64`. \
  See: `MsgPackLastError`

* `MsgPackReadFloat.d(*MsgPackData.MsgPackData)` \
  Reads any float field at the current internal offset. \
  Returns `0` on errors and sets the internal error code. \
  See: `MsgPackLastError`


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


### Extensions
`ExtType.b` is the signed ext type, `-128` to `-1` being reserved by the spec but not rejected. \
Size errors reuse the `#MsgPack_Error_BinaryDataSize*` codes.

* `MsgPackWriteExtension.MsgPack_ErrorCode(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)` \
  Writes `BufferSize` bytes from `*Buffer` using fixext for 1/2/4/8/16 bytes, or the smallest ext format code otherwise. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteExt8/16/32.MsgPack_ErrorCode(*MsgPackData.MsgPackData, ExtType.b, *Buffer, BufferSize.q)` \
  Same as `MsgPackWriteExtension`, but forces the given format code, even if a smaller one fits.

* `MsgPackWriteFixExt1/2/4/8/16.MsgPack_ErrorCode(*MsgPackData.MsgPackData, ExtType.b, *Buffer)` \
  Writes the 1/2/4/8/16 bytes at `*Buffer` as the given fixext.

* `MsgPackGetExtensionType.b(*MsgPackData.MsgPackData)` \
  Returns the type of the ext field at the current internal offset, without moving it. \
  Returns `0` on errors and sets the internal error code. \
  See: `MsgPackLastError`

* `MsgPackReadExtension.q(*MsgPackData.MsgPackData, *OutputBuffer, OutputBufferSize.q)` \
  Same as `MsgPackReadBinary`, for the data of ext fields.

* `MsgPackCopyExtension.i(*MsgPackData.MsgPackData)` \
  Same as `MsgPackCopyBinary`, for the data of ext fields.


### Navigation
Arrays and maps are handled iteratively, so deep nesting can't overflow the stack.

* `MsgPackGetFieldFullSize.q(*MsgPackData.MsgPackData)` \
  Returns the full size in bytes of the field at the current internal offset, without moving it. \
  Arrays and maps include all of their contained fields, recursively. \
  Returns `#MsgPack_InvalidSize` on errors and sets the internal error code. \
  See: `MsgPackLastError`

* `MsgPackGetEntryCount.q(*MsgPackData.MsgPackData)` \
  Returns the number of entries in the array or map at the current internal offset, without moving it. \
  A map entry is a key and a value, and counts as one. \
  Returns `#MsgPack_InvalidSize` on errors and sets the internal error code.

* `MsgPackSkip.MsgPack_ErrorCode(*MsgPackData.MsgPackData, FieldCount.q = 1)` \
  Moves the internal offset past the next `FieldCount` fields, the ones contained in arrays and maps included. \
  Map keys and values count as separate fields. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise, in which case the offset isn't moved.


### Arrays & Maps
* `MsgPackExamine.i(*MsgPackData.MsgPackData, ExaminationOptions.MsgPack_ExaminationOption = 0)` \
  Returns a view over the array or map at the current internal offset, to iterate on with `MsgPackNextEntry`. \
  The view is a regular `MsgPackData` limited to the array/map's content, so all the regular read functions work on it, and can't read past it. \
  It reads straight from `*MsgPackData`'s buffer, which must not be grown or freed while the view is used. \
  The whole array/map is checked beforehand, and the offset of `*MsgPackData` is moved past it. \
  Returns `#Null` on errors and sets the internal error code. \
  See: `MsgPackLastError`
  * `#MsgPack_ExaminationOptions_Unsafe` - **Not recommended !** \
    Skips the content check, which is also what finds the array/map's end. \
    The view can read past the array/map until `MsgPackNextEntry` reaches its end, invalid content is only
    detected while iterating, and the offset of `*MsgPackData` isn't moved, use `MsgPackSkip` afterward.

* `MsgPackNextEntry.b(*Iterator.MsgPackData)` \
  Moves the view's offset to its next entry, the first one on the first call. \
  Whatever wasn't read from the current entry is skipped, nested arrays/maps included. \
  Map entries are read key first, then value. \
  Returns `#True` if an entry is available, `#False` at the end or on errors, with the internal error code set accordingly.

* `MsgPackFinish(*Iterator.MsgPackData)` \
  Frees a view from `MsgPackExamine`, without touching the underlying buffer.

```purebasic
Define *Iterator.MsgPackData = MsgPackExamine(*MsgPack)
If *Iterator
	While MsgPackNextEntry(*Iterator)
		Key.s = MsgPackReadString(*Iterator)
		If MsgPackFormatCodeToDataType(MsgPackGetFormatCode(*Iterator)) = #MsgPack_DataTypes_Map
			*Nested = MsgPackExamine(*Iterator) ; Or leave it, it'll be skipped
			; ...
			MsgPackFinish(*Nested)
		EndIf
	Wend
	MsgPackFinish(*Iterator)
EndIf
```

* `MsgPackWriteArray.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)` \
  Writes an array whose entries are the fields in the `BufferSize` bytes of MessagePack data at `*Buffer`, using the smallest array format code that fits. \
  The data is fully checked and its fields are counted, nested arrays/maps counting as one. \
  `*Buffer` can come from `MsgPackFinalize`, with `MemorySize()` as its size, but not from `*MsgPackData`'s own buffer. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise, with nothing written.

* `MsgPackWriteMap.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)` \
  Same as `MsgPackWriteArray`, for maps. \
  The data must hold an even number of fields, alternating keys and values, or `#MsgPack_Error_OddMapFieldCount` is returned.

* `MsgPackWriteArrayFrom/MapFrom.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Source.MsgPackData)` \
  Same as `MsgPackWriteArray/Map`, with the data written so far in `*Source`, which is left untouched.

* `MsgPackWriteFixArray/Array16/Array32/FixMap/Map16/Map32.MsgPack_ErrorCode(*MsgPackData.MsgPackData, *Buffer, BufferSize.q)` \
  Same as `MsgPackWriteArray/Map`, but forces the given format code. \
  Returns `#MsgPack_Error_TooManyEntries` if the entries don't fit in it.


## Remarks
* Never touch the `MsgPackData` structure unless you **absolutely** have to.


## Support
- Both the ASM and C backends
- x86, x64, arm64
