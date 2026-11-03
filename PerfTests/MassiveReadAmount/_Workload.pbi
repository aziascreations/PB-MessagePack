; Workload shared by every implementation in this folder, keep `PerfPython.py` and `DotNet/Program.cs` in sync.
;
; `#Perf_Records` records of 8 fields, 1M fields in total, each record being:
;   42 (FixInt), -5 (FixInt), 200 (UInt8), -1000 (Int16), 70000 (UInt32),
;   -1099511627776 (Int64), 3.14 (Float64), "Hello" (FixStr)
;
; Write check: the encoded size.
; Read check: the sum of the integers, of `Int()` of the float, and of the string's length.
; Skip check: the number of fields skipped.

#Perf_Records = 125000
#Perf_Fields = #Perf_Records * 8

; 1 + 1 + 2 + 3 + 5 + 9 + 9 + 6 bytes per record.
#Perf_EncodedSize = #Perf_Records * 36
