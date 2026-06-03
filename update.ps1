[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Ref = "master",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

. "$PSScriptRoot\_common.ps1"
$cef = Initialize-CefEnv -Ref $Ref
$entriesFile = "$($cef.ChromiumDir)\.gclient_entries"

# 0. Refuse to run destructive automate-git flags while src/cef has work that
#    isn't safely on a remote. These flags blow away local changes (see
#    README / automate-git.py: --force-clean wipes cef_dir; --force-update and
#    --force-cef-update set discard_local_changes which adds `git checkout
#    --force` and `gclient sync --reset`).
$destructiveFlags = @('--force-clean', '--force-clean-deps', '--force-update', '--force-cef-update')
$requested = @($Rest | Where-Object { $destructiveFlags -contains $_ })
if ($requested.Count -gt 0 -and (Test-Path (Join-Path $cef.CefDir '.git'))) {
    $dirty   = & git -C $cef.CefDir status --porcelain
    $unpushed = ''
    & git -C $cef.CefDir rev-parse --abbrev-ref --symbolic-full-name '@{u}' > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $unpushed = & git -C $cef.CefDir log '@{u}..HEAD' --oneline
    } else {
        # No upstream configured -- treat HEAD as unpushed so the user is warned.
        $unpushed = & git -C $cef.CefDir log -1 --oneline
    }
    if ($dirty -or $unpushed) {
        Write-Host "ERROR: $($requested -join ', ') would discard work in $($cef.CefDir)" -ForegroundColor Red
        if ($dirty)    { Write-Host "  uncommitted changes:"; $dirty    | ForEach-Object { Write-Host "    $_" } }
        if ($unpushed) { Write-Host "  unpushed commits:";    $unpushed | ForEach-Object { Write-Host "    $_" } }
        Write-Host "Commit and push, or move the work elsewhere, then re-run." -ForegroundColor Yellow
        exit 1
    }
}

$env:GN_DEFINES         = "is_official_build=true"
$env:CEF_ARCHIVE_FORMAT = "tar.bz2"

# 1. Chromium/CEF checkout + version patches. --with-pgo-profiles makes a fresh
#    .gclient enable PGO profile download (required by the Release config).
Invoke-Native python3 "$PSScriptRoot\automate-git.py" `
    --download-dir=$($cef.Root) `
    --checkout=origin/$Ref `
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
        $full = Join-Path $cef.ChromiumDir ($rel -replace '/', '\')
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
Push-Location $cef.ChromiumDir
try {
    Invoke-Native gclient sync --nohooks --no-history
    Invoke-Native gclient runhooks
} finally {
    Pop-Location
}

# 4. Apply CEF patches and generate the GN build files (Debug + Release).
& "$PSScriptRoot\create.ps1" -Ref $Ref
