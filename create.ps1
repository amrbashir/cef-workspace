[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"
$cef = Initialize-CefEnv

$env:GN_DEFINES   = "is_component_build=true"
$env:GN_ARGUMENTS = "--ide=vs2022 --sln=cef --filters=//cef/*"

Push-Location $cef.CefDir
try {
    Invoke-Native python3 tools\gclient_hook.py @Rest
} finally {
    Pop-Location
}
