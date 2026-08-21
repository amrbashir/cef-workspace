$ErrorActionPreference = 'Stop'

$CEF_WORKSPACE_DIR = $PSScriptRoot
$CEF_ROOT         = "$CEF_WORKSPACE_DIR\chromium_git"
$CEF_CHROMIUM_DIR = "$CEF_ROOT\chromium"
$CEF_DIR          = "$CEF_CHROMIUM_DIR\src\cef"

$env:Path                      = "$CEF_ROOT\depot_tools;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
$env:GYP_MSVS_VERSION          = "2022"
$env:GN_DEFINES                = "is_component_build=true"
$env:CEF_ARCHIVE_FORMAT        = "tar.bz2"

# Run a native command and exit the calling script if it fails.
# $ErrorActionPreference='Stop' does not catch native non-zero exits, so we
# check $LASTEXITCODE here to give every script consistent fail-fast behavior.
function Invoke-Native {
    $cmd = $args[0]
    [object[]]$nativeArgs = if ($args.Count -gt 1) {
        $args[1..($args.Count - 1)]
    } else {
        @()
    }

    & $cmd @nativeArgs
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
