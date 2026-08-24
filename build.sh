#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

release=false
rest=()
while (($#)); do
    case "$1" in
        --release|-Release)
            release=true
            shift
            ;;
        --)
            shift
            rest+=("$@")
            break
            ;;
        *)
            rest+=("$1")
            shift
            ;;
    esac
done

if "$release"; then
    out_dir="out/$CEF_RELEASE_CONFIG"
else
    out_dir="out/$CEF_DEBUG_CONFIG"
fi

cd "$CEF_CHROMIUM_DIR/src"
autoninja -C "$out_dir" cef "${rest[@]}"
