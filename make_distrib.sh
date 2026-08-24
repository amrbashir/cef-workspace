#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

cd "$CEF_DIR/tools"
./make_distrib.sh --ninja-build "$CEF_BUILD_FLAG" --minimal "$@"
