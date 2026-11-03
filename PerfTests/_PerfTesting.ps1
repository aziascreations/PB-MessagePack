# Shared by the 'RunPerfTests.ps1' scripts, dot-source it.

# PureBasic versions, with the compiler executable of each architecture and backend.
# 6.21 is kept to compare with the string handling changes of 6.40.
# No x86 ASM backend, its 'FAsm.exe' triggers the AV and crashes anyway.
$Compilers = @{
	"6.41" = @{
		"x86" = @{ Path = "C:\Program Files (x86)\PureBasic_641"; Backends = @{ "C" = "pbcompilerc.exe" } }
		"x64" = @{ Path = "C:\Program Files\PureBasic_641"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } }
		"arm64" = @{ Path = "C:\Program Files\PureBasic_641_arm64\PureBasic"; Backends = @{ "C" = "pbcompiler.exe" } }
	}
	"6.21" = @{
		"x86" = @{ Path = "C:\Program Files (x86)\PureBasic_621"; Backends = @{ "C" = "pbcompilerc.exe" } }
		"x64" = @{ Path = "C:\Program Files\PureBasic_621"; Backends = @{ "ASM" = "pbcompiler.exe"; "C" = "pbcompilerc.exe" } }
	}
}

$PerfHeader = @("Implementation", "Scenario", "MedianMs", "NsPerOp", "Check")

# Where `Show-PerfResults` saves the results.
$PerfResultsDir = Join-Path $PSScriptRoot "Results"

# Prints each result line as it arrives, and passes it along.
filter Show-PerfLine {
	Write-Host "  $_"
	$_
}

# Prompts for a choice and used `&` for the hotkey.
function Select-Choice([string]$Title, [string[]]$Labels) {
	$Choices = $Labels | ForEach-Object { New-Object System.Management.Automation.Host.ChoiceDescription $_ }
	$Index = $Host.UI.PromptForChoice($Title, "", $Choices, 0)
	return $Labels[$Index].Replace("&", "")
}

# Prompts for a PureBasic version, architecture and backend, then builds and runs every '.pb' file in '$Directory'.
# They're built without the debugger, and with the C optimizer, like a release would be.
# Returns the parsed result lines.
function Invoke-PureBasicPerfTests([string]$Directory) {
	$Version = Select-Choice "Version" @("6.&41", "6.&21")
	$Architecture = Select-Choice "Architecture" @("x&86", "x&64", "&arm64")
	$Backend = Select-Choice "Backend" @("&ASM", "&C")

	# Used to name the results file.
	$script:PerfTarget = "${Version}_$Architecture-$Backend"

	$Compiler = $Compilers[$Version][$Architecture]
	if (-not $Compiler -or -not $Compiler.Backends.Contains($Backend)) {
		throw "No compiler configured for PureBasic $Version on $Architecture with the $Backend backend."
	}
	$CompilerExe = Join-Path $Compiler.Path "Compilers\$($Compiler.Backends[$Backend])"
	if (-not (Test-Path $CompilerExe)) {
		throw "Compiler not found: $CompilerExe"
	}

	$CompilerFlags = @("/CONSOLE")
	if ($Backend -eq "C") {
		$CompilerFlags += "/OPTIMIZER"
	}

	$Rows = @()

	# Built in the repo, outside of any temp folder, and deleted afterward.
	$BuildDir = Join-Path $Directory "Build"
	New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

	try {
		foreach ($PerfTest in Get-ChildItem -Path $Directory -Filter "*.pb") {
			$Exe = Join-Path $BuildDir "$($PerfTest.BaseName).exe"

			$CompilerOutput = & $CompilerExe $PerfTest.FullName /EXE $Exe @CompilerFlags | Out-String
			if ($LASTEXITCODE -ne 0) {
				throw "Compilation failed: $($PerfTest.Name)`n$CompilerOutput"
			}

			Write-Host "> $($PerfTest.Name) - PureBasic $Version - $Architecture - $Backend"
			$Rows += & $Exe | Show-PerfLine | ConvertFrom-Csv -Header $PerfHeader
			if ($LASTEXITCODE -ne 0) {
				throw "Failed: $($PerfTest.Name) (exit code $LASTEXITCODE)"
			}
		}
	} finally {
		Remove-Item -Recurse -Force $BuildDir
	}

	return $Rows
}

# Runs a Python perf test, requires the packages from 'PerfTests\requirements.txt'.
# Returns the parsed result lines.
function Invoke-PythonPerfTest([string]$Script) {
	Write-Host "> $(Split-Path $Script -Leaf)"
	$Rows = @(& python $Script | Show-PerfLine | ConvertFrom-Csv -Header $PerfHeader)
	if ($LASTEXITCODE -ne 0) {
		throw "Failed: $Script, install its packages with 'pip install -r PerfTests\requirements.txt'"
	}
	return $Rows
}

# Builds and runs a .NET perf test project, requires the .NET 10 SDK.
# Returns the parsed result lines.
function Invoke-DotNetPerfTest([string]$Project) {
	Write-Host "> $(Split-Path $Project -Leaf)"
	& dotnet build $Project -c Release --nologo -v quiet | Out-Host
	if ($LASTEXITCODE -ne 0) {
		throw "Compilation failed: $Project"
	}
	$Rows = @(& dotnet run --project $Project -c Release --no-build | Show-PerfLine | ConvertFrom-Csv -Header $PerfHeader)
	if ($LASTEXITCODE -ne 0) {
		throw "Failed: $Project (exit code $LASTEXITCODE)"
	}
	return $Rows
}

# Prints the results, reports scenarios whose checks differ between implementations,
#  and saves them as 'Results\<Directory's name>_<Version>_<Architecture>-<Backend>.csv', replacing the previous ones.
function Show-PerfResults([object[]]$Rows, [string]$Directory) {
	$Rows | Format-Table -AutoSize | Out-Host

	# Every implementation must have encoded the same bytes and read the same values.
	foreach ($Group in $Rows | Group-Object Scenario) {
		$Checks = @($Group.Group | ForEach-Object { $_.Check } | Select-Object -Unique)
		if ($Checks.Count -ne 1) {
			Write-Host "Mismatching checks for '$($Group.Name)': $($Checks -join ', ')" -ForegroundColor Red
		}
	}

	New-Item -ItemType Directory -Force -Path $PerfResultsDir | Out-Null
	$ResultsFile = Join-Path $PerfResultsDir "$(Split-Path $Directory -Leaf)_$PerfTarget.csv"
	$Rows | Export-Csv -Path $ResultsFile -NoTypeInformation
	Write-Host "Results saved to $ResultsFile"
}
