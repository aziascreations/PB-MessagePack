; Test-only helpers for building raw MessagePack buffers.
; Must be included after "MessagePack.pbi".


; Wraps a new buffer filled from a hex string like "C50001" into a non-growable `MsgPackData`.
; Free it with `FreeWrappedHex()`.
Procedure.i WrapHex(Hex.s)
	Protected Size.i = Len(Hex) / 2
	Protected *Buffer = AllocateMemory(Size)
	Protected i.i

	For i = 0 To Size - 1
		PokeA(*Buffer + i, Val("$" + Mid(Hex, (i * 2) + 1, 2)))
	Next

	ProcedureReturn MsgPackWrapMsgBuffer(*Buffer, Size)
EndProcedure


Procedure FreeWrappedHex(*MsgPack.MsgPackData)
	FreeMemory(*MsgPack\Buffer)
	MsgPackFree(*MsgPack, #False)
EndProcedure


; Returns a new buffer of `Size` bytes holding `(Index * 7 + 3 + Index / 256) & $FF`.
; The pattern shifts every 256 bytes so a misplaced offset can't hide behind a repeat,
;  and it contains both `$00` and `$FF` bytes.
Procedure.i AllocatePattern(Size.i)
	Protected *Buffer = AllocateMemory(Size)
	Protected i.i

	For i = 0 To Size - 1
		PokeA(*Buffer + i, ((i * 7) + 3 + (i / 256)) & $FF)
	Next

	ProcedureReturn *Buffer
EndProcedure
