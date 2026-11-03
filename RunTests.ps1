$ErrorActionPreference = "Stop"


# PureBasic versions used for unit tests, with the compiler executable of each backend.
$Compilers = [ordered]@{
	"x86" = @(
		@{ Name = "5.73"; Path = "C:\Program Files (x86)\PureBasic_573"; Backends = @{ "ASM" = "pbcompiler.exe" } },
		@{ Name = "6.21"; Path = "C:\Program Files (x86)\PureBasic_621"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } },
		@{ Name = "6.40"; Path = "C:\Program Files (x86)\PureBasic_640"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } },
		# No ASM backend, its 'FAsm.exe' triggers the AV and crashes anyway.
		@{ Name = "6.41"; Path = "C:\Program Files (x86)\PureBasic_641"; Backends = @{ "C" = "pbcompilerc.exe" } }
	)
	"x64" = @(
		@{ Name = "5.73"; Path = "C:\Program Files\PureBasic_573"; Backends = @{ "ASM" = "pbcompiler.exe" } },
		@{ Name = "6.21"; Path = "C:\Program Files\PureBasic_621"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } },
		@{ Name = "6.40"; Path = "C:\Program Files\PureBasic_640"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } },
		@{ Name = "6.41"; Path = "C:\Program Files\PureBasic_641"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } }
	)
	"arm64" = @(
		@{ Name = "6.21"; Path = "C:\Program Files\PureBasic_621_arm64"; Backends = @{ "C" = "pbcompiler.exe" } },
		@{ Name = "6.41"; Path = "C:\Program Files\PureBasic_641_arm64\PureBasic"; Backends = @{ "C" = "pbcompiler.exe" } }
	)
}

# Prompts for a choice and used `&` for the hotkey.
function Select-Choice([string]$Title, [string[]]$Labels) {
	$Choices = $Labels | ForEach-Object { New-Object System.Management.Automation.Host.ChoiceDescription $_ }
	$Index = $Host.UI.PromptForChoice($Title, "", $Choices, 0)
	return $Labels[$Index].Replace("&", "")
}


$Architecture = Select-Choice "Architecture" @("x&86", "x&64", "&arm64")
$Backend = Select-Choice "Backend" @("&ASM", "&C")

# Sets '#Endianness_UseGccBuiltins' in the PB-Endianness include, only used by the C backend.
$UseGccBuiltins = "False"
if ($Backend -eq "C") {
	$UseGccBuiltins = Select-Choice "Use GCC builtins" @("&False", "&True")
}
$UseGccBuiltinsValue = @{ "False" = 0; "True" = 1 }[$UseGccBuiltins]

$SelectedCompilers = @($Compilers[$Architecture] | Where-Object { $_.Backends.Contains($Backend) })
if ($SelectedCompilers.Count -eq 0) {
	throw "No compilers configured for $Architecture with the $Backend backend."
}

$UnitTests = Get-ChildItem -Path (Join-Path $PSScriptRoot "UnitTests") -Recurse -Filter "*.pb"

# Built in the repo, outside of any temp folder, and deleted afterward.
$BuildDir = Join-Path $PSScriptRoot "Build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$FailedCount = 0

try {
	foreach ($Compiler in $SelectedCompilers) {
		$CompilerExe = Join-Path $Compiler.Path "Compilers\$($Compiler.Backends[$Backend])"
		if (-not (Test-Path $CompilerExe)) {
			throw "Compiler not found: $CompilerExe"
		}

		Write-Host "`n=== PureBasic $($Compiler.Name) - $Architecture - $Backend - GCC builtins: $UseGccBuiltins ===" -ForegroundColor Cyan

		foreach ($UnitTest in $UnitTests) {
			$Exe = Join-Path $BuildDir "$($UnitTest.BaseName).exe"

			# Built without the debugger, the 'FatalErrors' tests rely on it.
			$CompilerOutput = & $CompilerExe $UnitTest.FullName /CONSOLE /EXE $Exe /CONSTANT "Endianness_UseGccBuiltins=$UseGccBuiltinsValue" | Out-String
			if ($LASTEXITCODE -ne 0) {
				throw "Compilation failed: $($UnitTest.Name) with PureBasic $($Compiler.Name)`n$CompilerOutput"
			}

			Write-Host "> $($UnitTest.Directory.Name)\$($UnitTest.Name)"
			& $Exe
			if ($LASTEXITCODE -ne 0) {
				Write-Host "FAILED (exit code $LASTEXITCODE)" -ForegroundColor Red
				$FailedCount++
			} else {
				Write-Host "PASSED" -ForegroundColor Green
			}

			Remove-Item -Force $Exe
		}
	}
} finally {
	Remove-Item -Recurse -Force $BuildDir
}

Write-Host ""
if ($FailedCount -ne 0) {
	Write-Host "$FailedCount test(s) failed." -ForegroundColor Red
} else {
	Write-Host "All tests passed." -ForegroundColor Green
}
Pause
