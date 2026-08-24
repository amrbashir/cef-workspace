[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

Push-Location $CEF_DIR
try {
    Write-Host "== Generating out\$CEF_DEBUG_CONFIG ($CEF_DEBUG_DEFINES) =="
    $env:GN_DEFINES = $CEF_DEBUG_DEFINES
    $env:GN_OUT_CONFIGS = $CEF_DEBUG_CONFIG
    Invoke-Native python3 tools\gclient_hook.py @Rest

    Write-Host "== Generating out\$CEF_RELEASE_CONFIG ($CEF_RELEASE_DEFINES) =="
    $env:GN_DEFINES = $CEF_RELEASE_DEFINES
    $env:GN_OUT_CONFIGS = $CEF_RELEASE_CONFIG
    Invoke-Native python3 tools\gclient_hook.py @Rest
} finally {
    Remove-Item Env:\GN_DEFINES, Env:\GN_OUT_CONFIGS -ErrorAction SilentlyContinue
    Pop-Location
}
