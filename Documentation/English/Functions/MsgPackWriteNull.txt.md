# MsgPackWriteNull


## Syntax
```purebasic
Result.MsgPack_ErrorCode = MsgPackWriteNull(*MsgPackData.MsgPackData)
```


## Description
Writes a null field in the given MessagePack at its current offset.

The offset may be grown if required, and if ´MsgPackData\Flags´ has ´???´ unset. \
The offset may be incremented if the ´MsgPackData\Flags´ has ´???´ set.


## Parameters



## Return value
Returns `#MsgPack_Error_Success` on success.

Returns other error constants on failure:
* `#MsgPack_Error_NullPointerGiven` if `MsgPackData` parameter is `#Null`
* ???
* ???

In all cases, except for ´#MsgPack_Error_NullPointerGiven´, the value of ´MsgPackData\LastError´ will contains the returned code.


## Supports
### Compiler
* PureBasic 5.70+
* PureBasic 6.xx - ASM
* PureBasic 6.xx - GCC

### OS
* Windows
* Linux
* MacOS *(Untested)*

### CPU
* x86
* x64
* arm64
