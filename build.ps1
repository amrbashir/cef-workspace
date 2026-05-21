[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)
$env:GN_DEFINES="is_official_build=true"
$env:CEF_ARCHIVE_FORMAT="tar.bz2"
$env:GYP_MSVS_VERSION="2022"

python3 $PSScriptRoot/automate-git.py `
  --download-dir=$PSScriptRoot/checkouts/$Ref `
  --checkout=origin/$Ref `
  --no-chromium-history `
  --minimal-distrib-only `
  --no-debug-build `
  --x64-build `
  --no-distrib-docs `
  --no-distrib-symbols `
  --with-pgo-profiles $Rest