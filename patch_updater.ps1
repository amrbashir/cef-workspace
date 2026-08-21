[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

Push-Location $CEF_DIR
try {
    Invoke-Native python3 tools\patch_updater.py @Rest
} finally {
    Pop-Location
}
