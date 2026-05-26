[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$root = "$PSScriptRoot\checkouts\$Ref"
$env:Path = "$root\depot_tools;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
$env:GYP_MSVS_VERSION = "2022"

$cefDir = "$root\chromium\src\cef"

Push-Location $cefDir
try {
   & python3 tools\make_distrib.py `
    --output-dir "$root\chromium\src\cef\binary_distrib" `
    --ninja-build `
    --x64-build `
    --allow-partial `
    --no-docs `
    --no-symbols $Rest
} finally {
    Pop-Location
}
