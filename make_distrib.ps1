[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [switch]$Minimal,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$root = "$PSScriptRoot\checkouts\$Ref"

$cefDir = "$root\chromium\src\cef"
$env:Path = "$root\depot_tools;$env:Path"

$args = @("--ninja-build", "--x64-build")
if ($Minimal) {
    $args += "--minimal"
} else {
    $args += "--allow-partial"
}
if ($Rest) { $args += $Rest }

Push-Location $cefDir
try {
    & ./tools/make_distrib.bat @args
} finally {
    Pop-Location
}
