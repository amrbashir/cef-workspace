#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

minimal=false
rest=()
while (($#)); do
    case "$1" in
        --minimal|-Minimal)
            minimal=true
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

cli_args=(--ninja-build --x64-build)
if "$minimal"; then
    cli_args+=(--minimal)
else
    cli_args+=(--allow-partial)
fi
cli_args+=("${rest[@]}")

cd "$CEF_DIR"
tools/make_distrib.sh "${cli_args[@]}"
