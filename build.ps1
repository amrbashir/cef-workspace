[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Release,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"

$outDir = if ($Release) { "out\Release_GN_x64" } else { "out\Debug_GN_x64" }

Push-Location "$CEF_CHROMIUM_DIR\src"
try {
    Invoke-Native autoninja -C $outDir cef @Rest
} finally {
    Pop-Location
}
