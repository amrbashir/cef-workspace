[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [switch]$Minimal,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"
$cef = Initialize-CefEnv -Ref $Ref

$cliArgs = @("--ninja-build", "--x64-build")
if ($Minimal) {
    $cliArgs += "--minimal"
} else {
    $cliArgs += "--allow-partial"
}
if ($Rest) { $cliArgs += $Rest }

Push-Location $cef.CefDir
try {
    Invoke-Native .\tools\make_distrib.bat @cliArgs
} finally {
    Pop-Location
}
