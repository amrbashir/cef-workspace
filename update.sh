#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"


# Create/update the Chromium and CEF checkout without building it.
python3 "$SCRIPT_DIR/automate-git.py" \
    "--download-dir=$CEF_ROOT" \
    --url=https://github.com/chromiumembedded/cef.git \
    --checkout=master \
    --no-chromium-history \
    --with-pgo-profiles \
    --no-build \
    --no-distrib \
    "$CEF_BUILD_FLAG" \
    "$@"

# Remove interrupted git dependencies whose HEAD cannot be resolved, allowing
# gclient to clone them again. Entries containing ':' are non-checkout objects.
entries_file="$CEF_CHROMIUM_DIR/.gclient_entries"
if [[ -f "$entries_file" ]]; then
    sed -En "s/^[[:space:]]*'([^']+)'[[:space:]]*:.*/\1/p" "$entries_file" |
    while IFS= read -r rel; do
        [[ "$rel" == src || "$rel" == *:* ]] && continue
        case "$rel" in
            /*|../*|*/../*|*/..)
                echo "- Skipping unsafe dependency path: $rel" >&2
                continue
                ;;
        esac
        full="$CEF_CHROMIUM_DIR/$rel"
        if [[ -e "$full/.git" ]] && ! git -C "$full" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
            echo "- Removing corrupt: $rel" >&2
            rm -rf -- "$full"
        fi
    done
fi

cd "$CEF_CHROMIUM_DIR"
gclient sync --nohooks --no-history
gclient runhooks

"$SCRIPT_DIR/create.sh"
