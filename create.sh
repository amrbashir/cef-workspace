#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

cd "$CEF_DIR"

echo "== Generating out/$CEF_DEBUG_CONFIG ($CEF_DEBUG_DEFINES) =="
GN_DEFINES="$CEF_DEBUG_DEFINES" GN_OUT_CONFIGS="$CEF_DEBUG_CONFIG" \
    python3 tools/gclient_hook.py "$@"

echo "== Generating out/$CEF_RELEASE_CONFIG ($CEF_RELEASE_DEFINES) =="
GN_DEFINES="$CEF_RELEASE_DEFINES" GN_OUT_CONFIGS="$CEF_RELEASE_CONFIG" \
    python3 tools/gclient_hook.py "$@"
