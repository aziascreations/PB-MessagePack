; Workload shared by every implementation in this folder, keep `PerfPython.py` and `DotNet/Program.cs` in sync.
;
; For each size, `#Perf_TotalSize / Size` fields of `Size` bytes are written, then read:
;  * Strings of 8, 1024 and 65536 "a" characters, encoded as UTF-8.
;  * Binaries of 1024 and 1048576 bytes set to `$AB`.
; The PureBasic test also writes and reads strings of 1024 characters as UTF-16, which the others don't support.
;
; Scenarios are named `str-<Size>-write`, `str-<Size>-read`, `bin-<Size>-write` and `bin-<Size>-read`.
; `NsPerOp` is the time per field.
;
; Write check: the encoded size.
; Read check: the total number of characters or bytes read.

#Perf_TotalSize = 33554432
