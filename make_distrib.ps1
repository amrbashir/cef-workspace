[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

Push-Location $CEF_DIR\tools
try {
    Invoke-Native .\make_distrib.bat --ninja-build $CEF_BUILD_FLAG --minimal @Rest
} finally {
    Pop-Location
}
