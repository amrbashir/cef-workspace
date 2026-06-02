[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$root = "$PSScriptRoot\checkouts\$Ref"

$cefDir = "$root\chromium\src\cef"

Push-Location $cefDir
try {
    & ./tools/make_distrib.bat --ninja-build
} finally {
    Pop-Location
}
