# PureBasic - MsgPack
PureBasic Include for serializing and deserializing MessagePack data.

Based on the [msgpack/msgpack](https://github.com/msgpack/msgpack) specification.


## Features
* ~~Full support of the [MessagePack](https://github.com/msgpack/msgpack) specification~~
  * **Still missing Map and Array**
* Explicit or implicit data formats when reading/writing
  * *ReadInteger vs ReadI8/ReadU8/...*
* ~~Fully documented~~


## Limitations
* No custom `malloc`/`realloc`/`free` callbacks
* More involved Map and Array parsing
  * *No dynamic typing*
* Usage of larger `.q` type for field sizes
  * *Helps prevent unsigned numbers causing issues on x86*
* Particular handling of `NaN` for *Float32* and *Float64*
  * `0x7F800001` gets returned as `0x7FC00001` (x87 FPU limitation)
  * **ARM64 untested yet**
* No implementation of the *Timestamp* extension


## Usage

### Submodule
Adding submodule:
```shell
git submodule add https://github.com/aziascreations/PB-MessagePack.git Includes/PB-MessagePack
```

Pull latest submodule version:
```shell
git submodule update --init --recursive
```


### Inclusion
...


## Examples

### Writing explicitely

```purebasic
...
```


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


## License
All the code in this repo is released in the [Public Domain](LICENSE).
