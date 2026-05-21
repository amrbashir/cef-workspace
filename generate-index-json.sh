#!/usr/bin/env bash
set -euo pipefail

# Generate index.json from cef_binary* files in specified directory (default: current).
# Usage: ./generate-index-json.sh [directory]

dir="${1:-.}"

all_platforms=(linux32 linux64 linuxarm linuxarm64 macosarm64 macosx64 windows32 windows64 windowsarm64)

# Build a JSON object collecting files grouped by platform and cef_version.
# We start with an empty object and merge each file entry into it.
result='{}'

for f in "$dir"/cef_binary_*.tar.bz2; do
  [ -e "$f" ] || continue

  basename="$(basename "$f")"

  # Extract type: last _-delimited segment before .tar.bz2
  rest="${basename#cef_binary_}"            # strip prefix
  type="${rest##*_}"                        # e.g. minimal.tar.bz2
  type="${type%.tar.bz2}"                   # e.g. minimal

  # Extract platform: second-to-last _-delimited segment (before type)
  without_suffix="${rest%.tar.bz2}"              # e.g. 128.4.9+gc7aspect+chromium-128.0.6613.18_linuxarm64_minimal
  platform="${without_suffix%_*}"                # strip _type  -> ...._linuxarm64
  platform="${platform##*_}"                     # keep last segment -> linuxarm64

  # Extract CEF version: everything before _{platform}_
  cef_version="${rest%%_${platform}_*}"

  # Extract Chromium version: after +chromium- in CEF_VERSION
  chromium_version="${cef_version##*chromium-}"

  # Get file metadata
  size="$(stat -c '%s' "$f")"
  epoch="$(stat -c '%Y' "$f")"
  last_modified="$(date -u -d "@$epoch" '+%Y-%m-%dT%H:%M:%S.000000Z')"
  sha1="$(shasum -a 1 "$f" | cut -d' ' -f1)"

  result="$(echo "$result" | jq ".\"$platform\".versions = [{
    cef_version: \"$cef_version\",
    chromium_version: \"$chromium_version\",
    channel: \"stable\",
    files: [{
      last_modified: \"$last_modified\",
      name: \"$basename\",
      sha1: \"$sha1\",
      size: $size,
      type: \"$type\"
    }]
  }]")"
done

# Ensure all platforms exist in the output (empty versions for those with no files).
for p in "${all_platforms[@]}"; do
  result="$(echo "$result" | jq --arg p "$p" 'if has($p) then . else .[$p] = {versions: []} end')"
done

echo "$result"
