#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
export GN_DEFINES="is_official_build=true"

python3 "$SCRIPT_DIR/automate-git.py" \
    "--download-dir=$CEF_ROOT" \
    --checkout=master \
    --no-chromium-history \
    --minimal-distrib-only \
    --no-debug-build \
    "$CEF_BUILD_FLAG" \
    --no-distrib-docs \
    --no-distrib-symbols \
    --with-pgo-profiles \
    "$@"
