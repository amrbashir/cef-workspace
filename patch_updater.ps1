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
    python3 tools\patch_updater.py $Rest
} finally {
    Pop-Location
}
