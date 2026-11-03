; Shared by the PureBasic performance tests.
;
; Each scenario is run once to warm up, then `#Perf_Runs` times, and its median is printed as:
;  `Implementation,Scenario,MedianMs,NsPerOp,Check`
; `Check` is returned by the scenario, e.g. an encoded size or a checksum, to compare implementations.

#Perf_Runs = 5

; Times are measured with `QueryPerformanceCounter_()`, `ElapsedMilliseconds()` is too coarse.
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
	CompilerError "The performance tests only support Windows !"
CompilerEndIf

Prototype.q PerfScenario()


; Errors go to stderr, stdout only holds the results.
Procedure PerfFail(Message.s)
	ConsoleError("FAILED: " + Message)
	End 1
EndProcedure

Macro PerfCheckWrite(ErrorCode)
	If ErrorCode <> #MsgPack_Error_Success
		PerfFail("A write failed !")
	EndIf
EndMacro


; `Operations` is the number of operations done by one run of `Function`, used for `NsPerOp`.
Procedure PerfRun(Implementation.s, Scenario.s, Function.PerfScenario, Operations.q)
	Protected Dim Times.d(#Perf_Runs - 1)
	Protected Check.q, Frequency.q, Start.q, Stop.q
	Protected Median.d
	Protected i.i
	
	QueryPerformanceFrequency_(@Frequency)
	
	Check = Function()
	
	For i = 0 To #Perf_Runs - 1
		QueryPerformanceCounter_(@Start)
		Check = Function()
		QueryPerformanceCounter_(@Stop)
		Times(i) = (Stop - Start) * 1000.0 / Frequency
	Next
	
	SortArray(Times(), #PB_Sort_Ascending)
	Median = Times(#Perf_Runs / 2)
	
	PrintN(Implementation + "," + Scenario + "," + StrD(Median, 1) + "," + StrD(Median * 1000000.0 / Operations, 1) + "," + Str(Check))
EndProcedure
