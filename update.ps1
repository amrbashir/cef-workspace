. "$PSScriptRoot\_common.ps1"
$entriesFile = "$CEF_CHROMIUM_DIR\.gclient_entries"

# 1. Chromium/CEF checkout + version patches. --with-pgo-profiles makes a fresh
#    .gclient enable PGO profile download (required by the Release config).
Invoke-Native python3 "$PSScriptRoot\automate-git.py" `
    --download-dir=$CEF_ROOT `
    --url=https://github.com/chromiumembedded/cef.git `
    --checkout=master `
    --no-chromium-history `
    --with-pgo-profiles `
    --no-build `
    --no-distrib `
    @Rest

# 2. Repair deps left corrupt by an interrupted sync: a .git directory with no
#    resolvable HEAD. gclient can't recover these (and `gclient sync --force`
#    aborts on them), so delete them and let the sync below re-clone cleanly.
if (Test-Path $entriesFile) {
    # .gclient_entries lists every dep path relative to the gclient root,
    # e.g.  'src/v8': 'https://...'  -- extract those keys. Skip 'src' itself
    # and GCS/CIPD object entries (keys with ':' or other chars invalid in a
    # Windows path), which aren't git checkouts and would break Join-Path.
    $paths = Select-String -Path $entriesFile -Pattern "^\s*'([^']+)'\s*:" |
             ForEach-Object { $_.Matches[0].Groups[1].Value } |
             Where-Object { $_ -ne 'src' -and $_ -notmatch '[<>:"|?*]' }
    foreach ($rel in $paths) {
        $full = Join-Path $CEF_CHROMIUM_DIR ($rel -replace '/', '\')
        if (Test-Path (Join-Path $full ".git")) {
            & git -C $full rev-parse --verify --quiet HEAD > $null 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "- Removing corrupt: $rel" -ForegroundColor Yellow
                Remove-Item -Recurse -Force -LiteralPath $full
            }
        }
    }
}

# 3. Complete the DEPS sync. Resumable: only fetches what's missing, and is
#    a no-op when the tree is already complete.
Push-Location $CEF_CHROMIUM_DIR
try {
    Invoke-Native gclient sync --nohooks --no-history
    Invoke-Native gclient runhooks
} finally {
    Pop-Location
}

# 4. Apply CEF patches and generate the GN build files (Debug + Release).
& "$PSScriptRoot\create.ps1"
