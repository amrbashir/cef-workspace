[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Release,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

$outDir = if ($Release) { "out\$CEF_RELEASE_CONFIG" } else { "out\$CEF_DEBUG_CONFIG" }

Push-Location "$CEF_CHROMIUM_DIR\src"
try {
    Invoke-Native autoninja -C $outDir cef @Rest
} finally {
    Pop-Location
}
