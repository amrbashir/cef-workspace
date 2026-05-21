[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$root        = "$PSScriptRoot\checkouts\$Ref"
$chromiumDir = "$root\chromium"
$srcDir      = "$chromiumDir\src"
$cefDir      = "$srcDir\cef"
$gclientFile = "$chromiumDir\.gclient"
$entriesFile = "$chromiumDir\.gclient_entries"

$env:GN_DEFINES         = "is_official_build=true"
$env:CEF_ARCHIVE_FORMAT = "tar.bz2"
$env:GYP_MSVS_VERSION   = "2022"

# 1. Chromium/CEF checkout + version patches. --with-pgo-profiles makes a fresh
#    .gclient enable PGO profile download (required by the Release config).
python3 $PSScriptRoot/automate-git.py `
  --download-dir=$root `
  --checkout=origin/$Ref `
  --no-chromium-history `
  --with-pgo-profiles `
  --no-build `
  --no-distrib $Rest

# Steps below run with depot_tools on PATH and make the run resumable.
$env:Path = "$root\depot_tools;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

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
        $full = Join-Path $chromiumDir ($rel -replace '/', '\')
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
Push-Location $chromiumDir
try {
    & gclient sync --nohooks --no-history
    & gclient runhooks
} finally {
    Pop-Location
}

# 4. Apply CEF patches and generate the GN build files (Debug + Release).
Push-Location $cefDir
try {
    & python3 tools/gclient_hook.py
} finally {
    Pop-Location
}
