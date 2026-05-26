[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)


$root = "$PSScriptRoot\checkouts\$Ref"

$GN_DEFINES="is_component_build=true"
$GN_ARGUMENTS="--ide=vs2022 --sln=cef --filters=//cef/*"

$cefDir = "$root\chromium\src\cef"

Push-Location $cefDir
try {
    python3 tools\gclient_hook.py
} finally {
    Pop-Location
}
