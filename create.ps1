[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

$env:GN_ARGUMENTS = "--ide=vs2022 --sln=cef --filters=//cef/*"

Push-Location $CEF_DIR
try {
    Invoke-Native python3 tools\gclient_hook.py @Rest
} finally {
    Pop-Location
}
