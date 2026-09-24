#!/usr/bin/env bash

CEF_WORKSPACE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CEF_ROOT="$CEF_WORKSPACE_DIR/chromium_git"
CEF_CHROMIUM_DIR="$CEF_ROOT/chromium"
CEF_DIR="$CEF_CHROMIUM_DIR/src/cef"

export CEF_ROOT CEF_CHROMIUM_DIR CEF_DIR
export PATH="$CEF_ROOT/depot_tools:$PATH"
export CEF_ARCHIVE_FORMAT="tar.bz2"

case "$(uname -m)" in
    arm64|aarch64)
        CEF_BUILD_ARCH=arm64
        CEF_BUILD_FLAG=--arm64-build
        ;;
    x86_64|amd64)
        CEF_BUILD_ARCH=x64
        CEF_BUILD_FLAG=--x64-build
        ;;
    *)
        echo "ERROR: Unsupported architecture: $(uname -m)" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac

CEF_DEBUG_CONFIG="Debug_GN_$CEF_BUILD_ARCH"
CEF_RELEASE_CONFIG="Release_GN_$CEF_BUILD_ARCH"

case "$(uname -s)" in
    Darwin)
        CEF_DEBUG_DEFINES="is_component_build=true"
        CEF_RELEASE_DEFINES="is_official_build=true"
        ;;
    Linux)
        _cef_base_defines="use_sysroot=true use_allocator=none symbol_level=1 is_cfi=false use_thin_lto=false"
        CEF_DEBUG_DEFINES="$_cef_base_defines is_component_build=true"
        CEF_RELEASE_DEFINES="$_cef_base_defines is_official_build=true"
        unset _cef_base_defines
        ;;
    *)
        echo "ERROR: Unsupported platform: $(uname -s)" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac

export CEF_BUILD_ARCH CEF_BUILD_FLAG
export CEF_DEBUG_CONFIG CEF_RELEASE_CONFIG CEF_DEBUG_DEFINES CEF_RELEASE_DEFINES
