# PureBasic - MsgPack - Performances
Performance benchmarks for the [PB-MessagePack](../readme.md) include.

Please refer to the [Performances](../readme.md#performances) section for the warnings and conclusions. \
Open questions raised by these results are tracked in [Investigations.md](Investigations.md).


## Workloads
Each folder has a `RunPerfTests.ps1` script that runs its benchmarks:
* `MassiveReadAmount/` - 1M small fields written, read and skipped, with explicit and implicit typing.
* `StringsAndBinary/` - Strings of 8 B to 64 KB, and binaries of 1 KB and 1 MB, written and read.
* `FlatMaps/` - 100K maps of 16 entries written and read.
* `DeepNesting/` - Arrays nested 1 to 128 levels deep, built, examined and measured. (PureBasic only)
* `NullChecks/` - Small fields written and read with and without `#MsgPack_DisableNullChecks`. (PureBasic only)

The first three are compared to [msgpack](https://pypi.org/project/msgpack/) (Python)
and [MessagePack-CSharp](https://github.com/MessagePack-CSharp/MessagePack-CSharp) (.NET).

The scripts prompt for the PureBasic version, architecture and backend. \
The results are saved in `Results/`, as one CSV per folder, PureBasic version, architecture and backend.


## Results
Hardware:
* Proxmox VM running Windows 10
* 10 Intel Core i5-13500 cores **(No E/P core pinning)**
* PureBasic 6.41
* Python 3.14 with [msgpack](https://pypi.org/project/msgpack/) 1.2.3
* .NET 10 with [MessagePack-CSharp](https://github.com/MessagePack-CSharp/MessagePack-CSharp) 3.1.12

Times are in nanoseconds per field, per map or per nested structure, lower is better. \
Every implementation produced the same bytes and read back the same values. \
PureBasic 6.41 is used everywhere, except in the [last table](#purebasic-621-vs-641).

### Compared to other implementations
x64 with the C backend, the fastest of each row in bold.

| Workload | Op | PureBasic | Python | .NET |
|:--|:--|--:|--:|--:|
| 1M small fields <sup>1</sup> | Write | 11.9 | 50.9 | **5.4** |
|  | Read | 12.7 | 52.4 | **10.6** |
|  | Skip | **18.3** | 40.2 | 29.4 |
| Strings, 8 B | Write | 59.6 | 62.0 | **13.2** |
|  | Read | 46.6 | 73.4 | **16.2** |
| Strings, 1 KB | Write | 720.9 | **556.0** | 804.8 |
|  | Read | 570.0 | 341.3 | **150.0** |
| Strings, 64 KB | Write | 45,917 | **33,932** | 39,848 |
|  | Read | 31,473 | **16,390** | 23,045 |
| Binary, 1 KB | Write | **190.6** | 556.6 | 576.1 |
|  | Read | **50.2** | 311.3 | 204.0 |
| Binary, 1 MB | Write | **207,744** | 574,825 | 438,025 |
|  | Read | **54,812** | 465,075 | 59,459 |
| Maps of 16 entries | Write | 1,793 | 927.2 | **209.2** |
|  | Read | 1,858 | 1,962 | **292.1** |

<sup>1</sup> 1M fields of mixed integers, floats and short strings, with implicit typing. PureBasic writes into a preallocated buffer.

### Architectures & backends
PureBasic only.

| Scenario | x64 C | x64 ASM | x86 C |
|:--|--:|--:|--:|
| Small fields, explicit write | 11.0 | 18.0 | 13.9 |
| Small fields, explicit read | 9.8 | 15.9 | 8.8 |
| Small fields, implicit write | 11.9 | 25.4 | 14.2 |
| Small fields, implicit read | 12.7 | 25.3 | 11.5 |
| Small fields, skip | 18.3 | 57.9 | 23.2 |
| Small fields, write, 64 KB growth <sup>2</sup> | 37.9 | 51.5 | 44.7 |
| Small fields, write, exact growth <sup>2</sup> | 441.0 | 461.6 | 503.3 |
| Small fields, read, null checks off <sup>3</sup> | 11.4 | 19.5 | 11.4 |
| Small fields, read, null checks on <sup>3</sup> | 12.2 | 20.2 | 11.4 |
| Strings, 1 KB UTF-16, write | 526.0 | 539.1 | 599.0 |
| Strings, 1 KB UTF-16, read | 282.7 | 298.8 | 289.1 |
| Maps of 16 entries, write | 1,793 | 3,472 | 2,189 |
| Maps of 16 entries, read | 1,858 | 3,232 | 1,782 |

<sup>2</sup> The buffer starts at 64 bytes and grows in multiples of 64 KB, or by the exact size of each write. (`GrowthIncrement` of `1`) \
<sup>3</sup> With and without `#MsgPack_DisableNullChecks`.

### Deep nesting
x64 with the C backend, arrays of 3 integers nested `N` levels deep.

| Depth | Build | Examine | Examine, unsafe | `MsgPackGetFieldFullSize` |
|--:|--:|--:|--:|--:|
| 1 | 283.3 | 177.8 | 134.9 | 80.4 |
| 2 | 453.4 | 363.2 | 261.4 | 115.8 |
| 4 | 1,002 | 825.2 | 464.1 | 177.3 |
| 8 | 2,226 | 2,154 | 906.9 | 308.9 |
| 16 | 6,414 | 6,155 | 1,807 | 546.5 |
| 32 | 21,888 | 21,134 | 4,367 | 985.9 |
| 64 | 76,370 | 72,715 | 7,774 | 1,997 |
| 128 | 278,388 | 269,656 | 15,803 | 3,812 |

### PureBasic 6.21 vs 6.41
x64 with the C backend, the new string handling of 6.40 being the main difference.

| Scenario | 6.21 | 6.41 | Speedup |
|:--|--:|--:|--:|
| Small fields, implicit write <sup>4</sup> | 23.0 | 11.9 | 1.9x |
| Small fields, implicit read <sup>4</sup> | 26.4 | 12.7 | 2.1x |
| Small fields, skip | 14.7 | 18.3 | 0.8x |
| Strings, 8 B, write | 162.8 | 59.6 | 2.7x |
| Strings, 8 B, read | 164.5 | 46.6 | 3.5x |
| Strings, 1 KB, write | 1,971 | 720.9 | 2.7x |
| Strings, 1 KB, read | 1,412 | 570.0 | 2.5x |
| Strings, 64 KB, write | 113,872 | 45,917 | 2.5x |
| Strings, 64 KB, read | 77,056 | 31,473 | 2.4x |
| Strings, 1 KB UTF-16, write | 2,026 | 526.0 | 3.9x |
| Strings, 1 KB UTF-16, read | 1,065 | 282.7 | 3.8x |
| Binary, 1 KB, write | 173.4 | 190.6 | 0.9x |
| Binary, 1 KB, read | 41.2 | 50.2 | 0.8x |
| Maps of 16 entries, write <sup>4</sup> | 3,221 | 1,793 | 1.8x |
| Maps of 16 entries, read <sup>4</sup> | 3,478 | 1,858 | 1.9x |
| Nested 128 levels, examine | 263,158 | 269,656 | 1.0x |

<sup>4</sup> Includes strings, one per record of 8 fields, and one per map key. \
The x64 ASM and x86 C results show the same 2 to 3 times speedup on strings.
