#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
export GN_DEFINES="is_official_build=true"

ref=master
rest=()
while (($#)); do
    case "$1" in
        --ref|-Ref)
            if (($# < 2)); then
                echo "ERROR: $1 requires a value" >&2
                exit 2
            fi
            ref=$2
            shift 2
            ;;
        --ref=*|-Ref=*)
            ref=${1#*=}
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

python3 "$SCRIPT_DIR/automate-git.py" \
    "--download-dir=$CEF_ROOT" \
    "--branch=$ref" \
    --no-chromium-history \
    --minimal-distrib-only \
    --no-debug-build \
    --x64-build \
    --no-distrib-docs \
    --no-distrib-symbols \
    --with-pgo-profiles \
    "${rest[@]}"
