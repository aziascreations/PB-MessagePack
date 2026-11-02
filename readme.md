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


## Limitations
* No custom `malloc`/`realloc`/`free` callbacks
* More involved Map and Array interactions
  * *No dynamic typing*
  * *Building arrays/maps requires special insertion in parent MsgPack ~~(See examples)~~*
  * *Lots of internal checks for boundaries and counts before any reading can be done*
  * *[TODO: Note about deep nesting and performances]*
* Usage of larger `.q` type for field sizes
  * *Helps prevent unsigned numbers causing issues on x86*
* Particular handling of `NaN` for *Float32* and *Float64*
  * `0x7F800001` gets returned as `0x7FC00001` (x87 FPU limitation)
  * **ARM64 untested yet**
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

TODO: Add note about handling pre-inclusion of PB-Endianness


### Inclusion
...


## Examples

### Explicit vs Implicit typing
* [BasicExplicitTyping.pb](Examples/BasicExplicitTyping/BasicExplicitTyping.pb)
* [BasicImplicitTyping.pb](Examples/BasicImplicitTyping/BasicImplicitTyping.pb)


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
