[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"
$cef = Initialize-CefEnv

Invoke-Native python3 "$PSScriptRoot\automate-git.py" `
    --download-dir=$($cef.Root) `
    --branch=$Ref `
    --no-chromium-history `
    --minimal-distrib-only `
    --no-debug-build `
    --x64-build `
    --no-distrib-docs `
    --no-distrib-symbols `
    --with-pgo-profiles `
    @Rest
