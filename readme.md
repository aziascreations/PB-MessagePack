# PureBasic - MsgPack
PureBasic Include for serializing and deserializing MessagePack data.

Based on the [msgpack/msgpack](https://github.com/msgpack/msgpack) specification.


> **🤖 AI Disclaimer** \
> This project uses AI-assisted development tools. \
> See the [AI usage policy](ai-policy.md) for details.


## Features
* Full support of the [MessagePack](https://github.com/msgpack/msgpack) specification
* Explicit or implicit data formats when reading/writing
  * *ReadInteger vs ReadI8/ReadU8/...*
* ~~Fully documented~~
* Supports all modern PureBasic setups
  * x86/x64/arm64
  * asm/c backends
  * 5.73 to 6.41


## Limitations
* No custom `malloc`/`realloc`/`free` callbacks
* More involved Map and Array interactions
  * *No dynamic typing*
  * *Building arrays/maps requires special insertion in parent MsgPack (See [examples](#arrays--maps))*
  * *Lots of internal checks for boundaries and counts before any reading can be done*
  * *Deep nesting costs more time, see [Performances](#performances)*
* Usage of larger `.q` type for field sizes
  * *Helps prevent unsigned numbers causing issues on x86*
* Particular handling of signaling `NaN` for *Float32*
  * `0x7F800001` may be returned as `0x7FC00001` on x86 and x64 (x87 FPU limitation)
  * ARM64 keeps them as-is
  * `MsgPackReadFloat` does it on all architectures
* No implementation of the *Timestamp* extension


## Usage

### Submodule
Adding as a submodule:
```shell
git submodule add https://github.com/aziascreations/PB-MessagePack.git Includes/PB-MessagePack
```

Pull latest submodule version:
```shell
git submodule update --init --recursive
```


### Inclusion
Include the main file, it pulls in everything else, [PB-Endianness](https://github.com/aziascreations/PB-Endianness) included:
```purebasic
XIncludeFile "Includes/PB-MessagePack/Includes/MessagePack.pbi"
```

The options below can be defined before the inclusion:
* `#MsgPack_MaxDepth` - Maximum nesting depth of arrays and maps, from `1` to `4096`. (Default: `128`)
* `#MsgPack_DisableNullChecks` - Skips the `#Null` pointer checks when set to `#True`. (Default: `#False`)

### Double import safeguard
`Endianness.pbi` raises a `CompilerError` if it is included twice from different paths,
to prevent two versions of it from being mixed.

If your project, or another include, already uses its own copy of PB-Endianness,
include it **before** `MessagePack.pbi`, which will then skip its own copy:
```purebasic
XIncludeFile "Includes/PB-Endianness/Includes/Endianness.pbi"
XIncludeFile "Includes/PB-MessagePack/Includes/MessagePack.pbi"
```

Including it afterward will trigger the error, unless `#Endianness_BypassIncludeCheck` is defined.


## Performances

> [!WARNING]
> Parts of the library can be much slower than C# and Python.
> 
> This is partially due to many security checks, and the rest is actively being investigated.
> We're also in the early stages of development, so there's also that...

### Security trade-offs
Arrays and maps are always validated before being used:
* `MsgPackExamine` checks the whole array/map before returning a view, so its content is read twice. \
  Examining a nested array/map checks its content again, so data nested `N` levels deep can be read up to `N+1` times.
* `MsgPackWriteArray/Map` and their variants check and count the given fields, then copy them. \
  Building nested arrays/maps copies the inner data once per level.
* `MsgPackGetFieldFullSize`, `MsgPackSkip` and `MsgPackNextEntry` walk through every contained field, they don't jump over them.

This is mostly noticeable with deeply nested data, which is why `#MsgPack_MaxDepth` defaults to `128` to prevent wasting time on hostile data.

`#MsgPack_ExaminationOptions_Unsafe` skips the check done by `MsgPackExamine`, and it can be used on non-root iterable values. \
However, using on an iterable element at the root means invalid data is only detected while iterating !


### Current status
* Binary data and skipping fields is faster than in msgpack and MessagePack-CSharp.
* Small fields, short strings and maps are slower than in MessagePack-CSharp.
* Writing maps is slower that C# and Python because of the checks mentionned above.
* Strings are about 4 times slower to write and up to 11 times slower to read than binary data of the same size.
  * *Currently being [investigated](PerfTests/Investigations.md).*
* The new strings library in PureBasic 6.40+ is 2.5 to 4 times faster than older versions.
* Using the C backend instead of the ASM one is up to 3 times faster.
* Preallocate the buffer or using a bigger `GrowthIncrement` than the default of `1` makes small writes up to 35 times faster.
* `#MsgPack_DisableNullChecks` only saves about 5%.
* Examining nested data gets quadratically slower with the depth
  * *It is up to 17 times slower when not using `#MsgPack_ExaminationOptions_Unsafe` at 128 levels.*

The detailed results, workloads and how to run them are in [PerfTests/readme.md](PerfTests/readme.md).


## Examples

### Explicit vs Implicit typing
* [BasicExplicitTyping.pb](Examples/BasicExplicitTyping/BasicExplicitTyping.pb)
* [BasicImplicitTyping.pb](Examples/BasicImplicitTyping/BasicImplicitTyping.pb)

### Data types
* [BasicStrings.pb](Examples/BasicStrings/BasicStrings.pb)
* [BasicBinary.pb](Examples/BasicBinary/BasicBinary.pb)
* [BasicExtensions.pb](Examples/BasicExtensions/BasicExtensions.pb)

### Arrays & Maps
* [BasicArrays.pb](Examples/BasicArrays/BasicArrays.pb)
* [BasicMaps.pb](Examples/BasicMaps/BasicMaps.pb)

### Dumping a buffer
* [DumpExplicitTypes.pb](Examples/DumpExplicitTypes/DumpExplicitTypes.pb) - Exact format code of each field
* [DumpImplicitTypes.pb](Examples/DumpImplicitTypes/DumpImplicitTypes.pb) - General data type of each field


## Cloning
Use this command to clone the repository and its submodules:
```
git clone --recurse-submodules https://github.com/aziascreations/PB-MessagePack.git
```

If you forgot the submodules, use this command:
```shell
git submodule update --init --recursive
```


## Special Thanks
* [AndyMK](https://www.purebasic.fr/english/memberlist.php?mode=viewprofile&u=2587) / [agorangetek](https://github.com/agorangetek)
  * PureBasic Visual Studio Code Extension ([GitHub repository](https://github.com/agorangetek/purebasic-vscode-extension))
* [Louis Somers](https://github.com/mlsomers)
  * LsMsgPack windows utility ([GitHub repository](https://github.com/mlsomers/LsMsgPack))


## License
All the code in this repo is released in the [Public Domain](LICENSE).
