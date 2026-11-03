$ErrorActionPreference = "Stop"

# Shows the error instead of closing the window right away.
trap {
	Write-Host $_ -ForegroundColor Red
	Pause
	exit 1
}

. (Join-Path $PSScriptRoot "..\_PerfTesting.ps1")

$Rows = @(Invoke-PureBasicPerfTests $PSScriptRoot)

Show-PerfResults $Rows $PSScriptRoot
Pause
