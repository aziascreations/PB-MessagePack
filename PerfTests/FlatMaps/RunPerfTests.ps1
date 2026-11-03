$ErrorActionPreference = "Stop"

# Shows the error instead of closing the window right away.
trap {
	Write-Host $_ -ForegroundColor Red
	Pause
	exit 1
}

. (Join-Path $PSScriptRoot "..\_PerfTesting.ps1")

# Requires Python with the packages from 'PerfTests\requirements.txt', and the .NET 10 SDK.
$Rows = @(Invoke-PureBasicPerfTests $PSScriptRoot)
$Rows += Invoke-PythonPerfTest (Join-Path $PSScriptRoot "PerfPython.py")
$Rows += Invoke-DotNetPerfTest (Join-Path $PSScriptRoot "DotNet")

Show-PerfResults $Rows $PSScriptRoot
Pause
