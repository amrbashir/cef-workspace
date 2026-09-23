. "$PSScriptRoot\_common.ps1"
$env:GN_DEFINES = "is_official_build=true"

Invoke-Native python3 "$PSScriptRoot\automate-git.py" `
    --download-dir=$CEF_ROOT `
    --checkout=master `
    --no-chromium-history `
    --minimal-distrib-only `
    --no-debug-build `
    --x64-build `
    --no-distrib-docs `
    --no-distrib-symbols `
    --with-pgo-profiles `
    @Rest
