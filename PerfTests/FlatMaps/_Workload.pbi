; Workload shared by every implementation in this folder, keep `PerfPython.py` and `DotNet/Program.cs` in sync.
;
; `#Perf_Maps` top-level maps are written, then read, each holding `#Perf_Entries` entries:
;  "Key00" to "Key15" (FixStr), mapped to 0 to 15 (FixInt), in that order.
; 16 entries make it a Map16, the smallest format code that fits.
; `NsPerOp` is the time per map.
;
; Write check: the encoded size.
; Read check: the sum of the keys' length and of the values.

#Perf_Maps = 100000
#Perf_Entries = 16

; 3 bytes of header, then 6 bytes per key and 1 per value.
#Perf_EncodedSize = #Perf_Maps * (3 + #Perf_Entries * 7)
