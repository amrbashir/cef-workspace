param(
    # Name recorded in archive.json. cef-rs ignores the directory if this
    # version is newer than its own.
    [string]$ArchiveName
)

. "$PSScriptRoot\_common.ps1"

$distribRoot = "$CEF_DIR\binary_distrib"
$distrib = Get-ChildItem $distribRoot -Directory -Filter 'cef_binary_*_minimal' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $distrib) { throw "No cef_binary_*_minimal directory in $distribRoot" }

$cefRsArch = if ($CEF_BUILD_ARCH -eq 'arm64') { 'aarch64' } else { 'x86_64' }
$outDir = "$distribRoot\cef_windows_$cefRsArch"

# Flatten the way cef-rs does: Release/ becomes the directory itself,
# Resources/ is merged into its top level, headers and wrapper sources
# sit alongside them.
Remove-Item $outDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item $outDir -ItemType Directory | Out-Null
Copy-Item "$distrib\Release\*" $outDir -Recurse
Copy-Item "$distrib\Resources\*" $outDir -Recurse
foreach ($item in 'CMakeLists.txt', 'cmake', 'include', 'libcef_dll', 'CREDITS.html') {
    Copy-Item "$distrib\$item" $outDir -Recurse
}

$archive = "$distrib.tar.bz2"
if (-not $ArchiveName) { $ArchiveName = Split-Path $archive -Leaf }
[ordered]@{
    type = 'minimal'
    name = $ArchiveName
    sha1 = if (Test-Path $archive) { (Get-FileHash $archive -Algorithm SHA1).Hash.ToLower() } else { '' }
} | ConvertTo-Json | Set-Content "$outDir\archive.json"

Write-Host "`$env:CEF_PATH = '$outDir'"
