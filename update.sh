#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

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

# Refuse automate-git options that could erase CEF work not safely stored on a
# remote. A branch without an upstream is treated as having an unpushed HEAD.
requested=()
for arg in "${rest[@]}"; do
    case "$arg" in
        --force-clean|--force-clean-deps|--force-update|--force-cef-update)
            requested+=("$arg")
            ;;
    esac
done

if ((${#requested[@]})) && [[ -e "$CEF_DIR/.git" ]]; then
    dirty=$(git -C "$CEF_DIR" status --porcelain)
    if git -C "$CEF_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        unpushed=$(git -C "$CEF_DIR" log '@{u}..HEAD' --oneline)
    else
        unpushed=$(git -C "$CEF_DIR" log -1 --oneline)
    fi

    if [[ -n "$dirty" || -n "$unpushed" ]]; then
        joined=$(printf '%s, ' "${requested[@]}")
        joined=${joined%, }
        echo "ERROR: $joined would discard work in $CEF_DIR" >&2
        if [[ -n "$dirty" ]]; then
            echo "  uncommitted changes:" >&2
            while IFS= read -r line; do echo "    $line" >&2; done <<<"$dirty"
        fi
        if [[ -n "$unpushed" ]]; then
            echo "  unpushed commits:" >&2
            while IFS= read -r line; do echo "    $line" >&2; done <<<"$unpushed"
        fi
        echo "Commit and push, or move the work elsewhere, then re-run." >&2
        exit 1
    fi
fi

# Create/update the Chromium and CEF checkout without building it.
python3 "$SCRIPT_DIR/automate-git.py" \
    "--download-dir=$CEF_ROOT" \
    --url=https://github.com/chromiumembedded/cef.git \
    "--branch=$ref" \
    --no-chromium-history \
    --with-pgo-profiles \
    --no-build \
    --no-distrib \
    "$CEF_BUILD_FLAG" \
    "${rest[@]}"

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
