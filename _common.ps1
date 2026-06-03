$ErrorActionPreference = 'Stop'

function Initialize-CefEnv {
    param([Parameter(Mandatory)][string]$Ref)
    $root = "$PSScriptRoot\checkouts\$Ref"
    $env:Path                      = "$root\depot_tools;$env:Path"
    $env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
    $env:GYP_MSVS_VERSION          = "2022"
    [PSCustomObject]@{
        Root        = $root
        ChromiumDir = "$root\chromium"
        CefDir      = "$root\chromium\src\cef"
    }
}

# Run a native command and exit the calling script if it fails.
# $ErrorActionPreference='Stop' does not catch native non-zero exits, so we
# check $LASTEXITCODE here to give every script consistent fail-fast behavior.
function Invoke-Native {
    $cmd, $rest = $args
    & $cmd @rest
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
