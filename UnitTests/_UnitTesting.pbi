; Feel free to copy this, it's just a rough draft

Global PassedUnitTests.i = 0
Global FailedUnitTests.i = 0

Procedure Pass(TestName.s="")
	PassedUnitTests = PassedUnitTests + 1
	If Len(TestName)
		Debug "Passed -> "+TestName
	Else
		Debug "Passed"
	EndIf
EndProcedure

Procedure Fail(TestName.s="", Details.s="")
	FailedUnitTests = FailedUnitTests + 1
	
	If Len(TestName)
		If Len(Details)
			Debug "Failed -> "+TestName + " (" + Details + ")"
		Else
			Debug "Failed -> "+TestName
		EndIf
	Else
		Debug "Failed"
	EndIf
EndProcedure

Procedure AssertIsTrue(Bool.b=#True, TestName.s="", Details.s="")
	If Bool
		Pass(TestName)
	Else
		Fail(TestName, Details)
	EndIf
EndProcedure

Procedure AssertEqualsA(Val1.a, Val2.a, TestName.s="")
	If Val1 = Val2
		Pass(TestName)
	Else
		Fail(TestName, Str(Val1) + " <> " + Str(Val2))
	EndIf
EndProcedure

Procedure AssertEqualsB(Val1.b, Val2.b, TestName.s="")
	If Val1 = Val2
		Pass(TestName)
	Else
		Fail(TestName, Str(Val1) + " <> " + Str(Val2))
	EndIf
EndProcedure

Procedure AssertNotEquals(Val1, Val2, TestName.s="")
	If Val1 <> Val2
		Pass(TestName)
	Else
		Fail(TestName, Str(Val1) + " = " + Str(Val2))
	EndIf
EndProcedure

Procedure AssertIsFalse(Bool.b=#False, TestName.s="")
	If Bool
		Fail(TestName)
	Else
		Pass(TestName)
	EndIf
EndProcedure

Procedure Assert(Bool.b, TestName.s="", Details.s="")
	AssertIsTrue(Bool, TestName, Details)
EndProcedure
