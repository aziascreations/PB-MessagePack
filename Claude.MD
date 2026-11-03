# MessagePack.pbi
PureBasic include for creating/reading MessagePack data.

**When integrating, do not read any `.pbi` files to save on tokens, use the API below.** \
When working on the include itself, see [Working on this repository](#working-on-this-repository).


## APIs

### Behaviour
* All the procedures take a `*MsgPackData` from `MsgPackCreate`, `MsgPackWrapMsgBuffer` or `MsgPackExamine`.
* Errors are reported through the internal error code, see `MsgPackLastError`.
  * Writes and other procedures returning a `.MsgPack_ErrorCode` also return it directly.
  * Reads returning a value give `0`, `""`, `#False`, `#Null` or `#MsgPack_InvalidSize` on errors,
    which can also be valid values, so check `MsgPackLastError` after them.
  * A successful read or write resets it to `#MsgPack_Error_Success`.
* Failed reads and writes don't move the internal offset, and write nothing.
* The internal offset is auto-incremented on all complete reads and writes.
  * Does not apply to `MsgPackGetFormatCode`, `MsgPackGetExtensionType`, `MsgPackGetEntryCount` and `MsgPackGetFieldFullSize`.
  * Can be disabled with the internal `#MsgPack_DataFlags_MoveOffsetAfterRead/Write` flags, honored by every read and write.
* The internal buffer is automatically grown as needed, unless it is owned by the caller.
* Invalid or truncated data never raises a `DebuggerError`, only programming errors do. (e.g.: `#Null` pointers)
* Views from `MsgPackExamine` are read-only, writes return `#MsgPack_Error_BufferIsReadOnly`.


### Type aliases/macros

* `.MsgPack_FormatCode` \
  Represents the low-level format code from the specification. \
  Fix* types are returned without the value/size bits they embed, e.g. `$A0` for any FixStr and `0` for positive fixints. 
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
  * `#MsgPack_DataTypes_Unknown` - For `#MsgPack_FormatCode_Invalid`.
  * `#MsgPack_DataTypes_Null`
  * `#MsgPack_DataTypes_Boolean`
  * `#MsgPack_DataTypes_Integer`
  * `#MsgPack_DataTypes_Float`
  * `#MsgPack_DataTypes_String`
  * `#MsgPack_DataTypes_Binary`
  * `#MsgPack_DataTypes_Array`
  * `#MsgPack_DataTypes_Map`
  * `#MsgPack_DataTypes_Extension`

* `.MsgPack_ErrorCode` \
  * `#MsgPack_Error_Success = 0`
  * `#MsgPack_Error_NullPointerGiven`
  * `#MsgPack_Error_BufferTooSmall`
  * `#MsgPack_Error_InvalidValue`
  * `#MsgPack_Error_ValueOverflow`
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
  * `#MsgPack_Error_MaxDepthExceeded`
  * `#MsgPack_Error_CannotGrowBufferDueToConfig`
  * `#MsgPack_Error_BufferIsReadOnly`

* `.MsgPack_DataFlag` \
  Internal flags, do not touch.

* `.MsgPack_ExaminationOption` \
  Options for `MsgPackExamine`.
  * `#MsgPack_ExaminationOptions_Unsafe`


### Constants & compiler options
* `#MsgPack_InvalidSize = -1` \
  Returned by procedures that return a size, on errors.

* `#MsgPack_MaxDepth` \
  Maximum nesting depth of arrays and maps, a top-level array or map being at depth 1. \
  Defaults to `128`, can be defined before the inclusion, from `1` to `4096`. \
  Deeper data is rejected with `#MsgPack_Error_MaxDepthExceeded`.

* `#MsgPack_DisableNullChecks` \
  Disables the `#Null` pointer checks when defined as `#True` before the inclusion. \
  Defaults to `#False`.


### Errors & format codes
* `MsgPackLastError.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
  Returns the error code set by the last read, write or navigation on `*MsgPackData`, `#MsgPack_Error_Success` if it succeeded. \
  Returns `#MsgPack_Error_NullPointerGiven` if `*MsgPackData` is `#Null`.

* `MsgPackGetFormatCode.MsgPack_FormatCode(*MsgPackData.MsgPackData)` \
  Returns the format code of the field at the current internal offset, without moving it or setting the internal error code. \
  Returns `#MsgPack_FormatCode_Invalid` at the end of the buffer, or for the `0xC1` byte.

* `MsgPackFormatCodeToDataType.MsgPack_DataType(FormatCode.MsgPack_FormatCode)` \
  Returns the data type of a format code from `MsgPackGetFormatCode`. \
  Returns `#MsgPack_DataTypes_Unknown` for `#MsgPack_FormatCode_Invalid`.


### Allocation & ownership
* `MsgPackCreate.i(InitialSize.i, GrowthIncrement.i = 1)` \
  Prepares an internal structure for a buffer of a given size `InitialSize.i`. \
  The buffer grows in multiples of `GrowthIncrement` bytes, `1` growing it by the exact size needed by each write. \
  Returns `#Null` on errors.

* `MsgPackWrapMsgBuffer.i(*Buffer, BufferSize.i, GiveOwnership.b = #False, GrowthIncrement.i = 1)` \
  Wraps a given buffer `*Buffer` of a given size `BufferSize.i` into an internal structure, without copying it. \
  If `GiveOwnership` is `#False`, the buffer stays owned by the caller, and is never grown or freed. \
  If `GiveOwnership` is `#True`, `*Buffer` must come from `AllocateMemory()`, it can be grown, and freed with `MsgPackFree`. \
  Returns `#Null` on errors.

* `MsgPackGrow.MsgPack_ErrorCode(*MsgPackData.MsgPackData, DesiredSizeIncrease.q)` \
  Grows the buffer by `DesiredSizeIncrease` bytes, rounded up to a multiple of its `GrowthIncrement`. \
  Called by the writes as needed, there's no need to call it beforehand. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise. (e.g.: `#MsgPack_Error_CannotGrowBufferDueToConfig` for buffers owned by the caller)

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
* `MsgPackReadBoolean.b(*MsgPackData.MsgPackData)` \
  Attempts to read the boolean at the current internal offset. \
  Returns `#True` or `#False`, `#False` on errors too. \
  See: `MsgPackLastError`

* `MsgPackWriteNull.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
  Attempts to write a nil at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteTrue.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
  Attempts to write `#True` at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteFalse.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
  Attempts to write `#False` at the current internal offset. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackWriteBoolean.MsgPack_ErrorCode(*MsgPackData.MsgPackData, Boolean.b)` \
  Writes `#True` or `#False` depending on `Boolean`. \
  Returns `#MsgPack_Error_Success` on success, something else otherwise.

* `MsgPackReadNull.MsgPack_ErrorCode(*MsgPackData.MsgPackData)` \
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


## Usage patterns

### Writing, exporting and reading
```purebasic
Define *Writer = MsgPackCreate(64)
If MsgPackWriteInteger(*Writer, 42) <> #MsgPack_Error_Success
	; ...
EndIf

; Frees `*Writer`, the caller now owns `*Buffer`.
Define *Buffer = MsgPackFinalize(*Writer)

; Gives `*Buffer` back to a structure, freed along with it.
Define *Reader = MsgPackWrapMsgBuffer(*Buffer, MemorySize(*Buffer), #True)
Define Value.q = MsgPackReadInteger(*Reader)
If MsgPackLastError(*Reader) <> #MsgPack_Error_Success
	; ...
EndIf

MsgPackFree(*Reader, #True)
```

### Building arrays & maps
Their content is written in a separate structure, then copied in with its fields counted.
```purebasic
Define *Fields = MsgPackCreate(32)
MsgPackWriteString(*Fields, "Key")
MsgPackWriteInteger(*Fields, 1)
MsgPackWriteMapFrom(*Writer, *Fields)
MsgPackFree(*Fields, #True)
```
Forcing their format code requires the content as a buffer, e.g. from `MsgPackFinalize`, for `MsgPackWriteFixArray/Array16/...`.

### Iterating over a buffer
The end of a buffer can't be queried, so either wrap the data in a top-level array/map,
or subtract each top-level field's `MsgPackGetFieldFullSize` from the buffer's size until it reaches `0`.

### Missing or asymmetric procedures
* Floats have no implicitly typed setter, use `MsgPackWriteFloat32/64`.
* Strings have no explicitly typed getters, `MsgPackReadString` reads all str format codes.
* Fixints have no explicitly typed getter, `MsgPackReadInteger` reads them.


## Remarks
* Never touch the `MsgPackData` structure unless you **absolutely** have to.


## Support
- Both the ASM and C backends
- x86, x64, arm64


## Working on this repository

### Layout
* `Includes/MessagePack.pbi` - Main file, only includes the others.
* `Includes/_*.pbi` - One file per family. (Allocators, Literals, Primitives, Strings, ...)
* `Includes/PB-Endianness/` - Git submodule, don't edit it from here.
* `UnitTests/` - One folder per family, numbered like the includes' order.
* `Examples/` - One folder per example, with a `.pb` of the same name.
* `PerfTests/` - Benchmarks, one folder per workload, each with a `RunPerfTests.ps1`.
* `SecurityTests/` - Private, git-ignored, leave it alone unless asked.

### Conventions
* `.pb`/`.pbi` files use CRLF line endings and ASCII only, `Chr()` for anything else.
* Includes use tabs, examples use 4 spaces.
* Private procedures and macros are prefixed with `_MsgPack`, public ones with `MsgPack`.
* Every public procedure is documented above its definition, and in this file.
* `#Null` pointers raise a `DebuggerError` behind `CompilerIf Not #MsgPack_DisableNullChecks`, invalid data only uses `Debug`.

### Unit tests
* Run with `RunTests.ps1`, which builds each test without the debugger, so `Debug` & co are compiled out.
* Each test includes `../_UnitTesting.pbi`, uses its `Assert*` procedures, and ends with `End 1` if `FailedUnitTests` isn't `0`.
* `*FatalErrors.pb` tests call `DebuggerError` on purpose, and only pass without the debugger.
* No PureBasic compiler is available in the cloud sandbox, ask the user to run the tests.

### Performance tests
* Run with the `RunPerfTests.ps1` of each folder, Windows only.
  * They dot-source `PerfTests/_PerfTesting.ps1`, which builds the folder's `.pb` files without the debugger, with `/OPTIMIZER` on the C backend,
    runs `PerfPython.py` and `DotNet/` if present, and saves the results in `PerfTests/Results/<Folder>_<Version>_<Architecture>-<Backend>.csv`.
  * PureBasic 6.41 and 6.21 are configured in `$Compilers`, 6.21 being kept to compare the string handling changes of 6.40.
* Each implementation times its scenarios with the shared `_PerfTesting.pbi`/`.py`/`.cs`: one warm-up run, then the median of 5.
* Each program prints `Implementation,Scenario,MedianMs,NsPerOp,Check` lines on stdout, errors go to stderr.
* `Check` must be identical for a scenario across implementations, the scripts report mismatches.
* Each folder's workload is described in its `_Workload.pbi`, keep its `PerfPython.py` and `DotNet/Program.cs` in sync with it.
* Python packages are pinned in `PerfTests/requirements.txt`, MessagePack-CSharp in each `DotNetPerf.csproj`.
* The results tables are in `PerfTests/readme.md`, the conclusions in the main readme's "Performances" section, keep both in sync with new results.
* Open performance questions and their leads are in `PerfTests/Investigations.md`, update it when one is looked into.

### Examples
* Start with a `;- Notes` section, then `;- Example`.
* Check every result, and use a different `End` code for each failure.
* Link new examples in the readme's "Examples" section.
