#!/usr/bin/env bash

CEF_WORKSPACE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CEF_ROOT="$CEF_WORKSPACE_DIR/chromium_git"
CEF_CHROMIUM_DIR="$CEF_ROOT/chromium"
CEF_DIR="$CEF_CHROMIUM_DIR/src/cef"

export CEF_ROOT CEF_CHROMIUM_DIR CEF_DIR
export PATH="$CEF_ROOT/depot_tools:$PATH"
export CEF_ARCHIVE_FORMAT="tar.bz2"

case "$(uname -s)" in
    Darwin)
        export GN_DEFINES="is_component_build=true"
        ;;
    Linux)
        export GN_DEFINES="use_sysroot=true use_allocator=none symbol_level=1 is_cfi=false use_thin_lto=false"
        ;;
    *)
        echo "ERROR: Unsupported platform: $(uname -s)" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac
