# PureBasic - MsgPack - Performance investigations
Open questions raised by the [results](readme.md#results), with leads to check. \
Nothing below is confirmed yet, update or remove each entry once it is looked into.

Measured on 2026-11-03, see the results' CSVs in `Results/`.


## Strings are slow compared to binary data
x64 with the C backend, PureBasic 6.41, ns per field:

| Payload | Binary write | String write | Binary read | String read |
|:--|--:|--:|--:|--:|
| 1 KB, UTF-8 | 190.6 | 720.9 (3.8x) | 50.2 | 570.0 (11.4x) |
| 1 KB, UTF-16 (2 KB) | - | 526.0 | - | 282.7 |
| 64 KB vs 1 MB | ~5.0 GB/s | ~1.4 GB/s | ~19 GB/s | ~2.1 GB/s |

* UTF-16 is faster than UTF-8 while being twice as big, so the encoding itself costs a lot.
* MessagePack-CSharp reads 1 KB strings in 150 ns, and writes 8 B strings in 13 ns against 60 ns here.
* PureBasic 6.21 is another 2.5 to 4 times slower, see [PureBasic 6.21 vs 6.41](readme.md#purebasic-621-vs-641).

### Leads in `Includes/_Strings.pbi`
* `String.s` is passed by value through `MsgPackWriteString`, `_MsgPackGetEncodedStringSize` and `_MsgPackWriteStringField`,
  which may copy it at each call, and would explain why 6.40's string handling helps that much. \
  Passing `@String` and its length to the private helpers would avoid it.
* Each write goes over the string at least twice, with `StringByteLength()` then `PokeS()`. \
  For `#PB_Unicode` and `#PB_Ascii`, the size could come from `Len()` instead, if it doesn't scan the string.
* `PokeS()` is given `-1` as its length, so it may also look for the null terminator on its own.
* `MsgPackReadString` builds the string with `PeekS()`, then returns it, which may copy it again.

### Leads in the benchmark
* `EncodeStrings()` preallocates `FieldSize * 2 + 5` bytes per field, 64 MB in total, against 32 MB for binaries. \
  The allocation is timed, see the next section, and `MsgPackFinalize` then shrinks it by half.
* `ScenarioStringRead()` calls `Len()` on each string, which may scan it on 6.21 and not on 6.41. \
  Python's `len()` and .NET's `Length` don't scan.

### Experiments to run
1. Time raw `PokeS()`/`PeekS()` loops with the same sizes, without MsgPack, to split PureBasic's own cost from the include's.
2. Size the strings writer like the binaries one, and compare.
3. Try the `@String` + length helpers, and `Len()` for the fixed-width encodings.
4. Run 6.40 too, to check that the gain comes from 6.40 and not 6.41.


## Buffers are zero-filled
`MsgPackCreate` uses `AllocateMemory()` and `MsgPackGrow` uses `ReAllocateMemory()`, both without `#PB_Memory_NoClear`,
so every buffer is zeroed before being written over.
* That cost is in every write scenario with a preallocated buffer, more so for the big ones.
* With a `GrowthIncrement` of `1`, small writes take ~440 ns against ~12 ns preallocated,
  the reallocation and copy probably cost more than the zeroing, but it adds up.

To try: `#PB_Memory_NoClear` on both, as only the written bytes are ever read, then re-run every folder.


## Smaller oddities
* **Maps:** writing them is 8.6 times slower than MessagePack-CSharp and 1.9 times slower than msgpack. \
  Each map is written in its own structure, then checked, counted and copied by `MsgPackWriteMapFrom`, see the main readme.
  Its 16 keys are strings too, see above.
* **ASM backend:** skipping small fields is 3.2 times slower than with the C backend (57.9 vs 18.3 ns), against 1 to 2 times for the rest.
* **6.21 faster than 6.41:** skip (14.7 vs 18.3 ns) and 1 KB binaries (0.8 to 0.9x). \
  Those runs only last 1 to 2 ms, so it may be noise, re-run them with more iterations before looking further.
