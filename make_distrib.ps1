[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Minimal,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

$cliArgs = @("--ninja-build", "--x64-build")
if ($Minimal) {
    $cliArgs += "--minimal"
} else {
    $cliArgs += "--allow-partial"
}
if ($Rest) { $cliArgs += $Rest }

Push-Location $CEF_DIR
try {
    Invoke-Native .\tools\make_distrib.bat @cliArgs
} finally {
    Pop-Location
}
