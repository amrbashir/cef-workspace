[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"
$cef = Initialize-CefEnv -Ref $Ref

Push-Location $cef.CefDir
try {
    Invoke-Native python3 tools\patch_updater.py @Rest
} finally {
    Pop-Location
}
