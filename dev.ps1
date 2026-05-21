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

$src = "$root\chromium\src"
$outDir = "out\Debug_GN_x64"

Push-Location $src
try {
    & autoninja -C $outDir cef
    & "$src\$outDir\cefclient.exe" $Rest
} finally {
    Pop-Location
}
