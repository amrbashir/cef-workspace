#!/usr/bin/env bash
set -euo pipefail

# Usage: ./repack.sh <directory> <new_version>
# Example: ./repack.sh ./downloads 147.0.10

if [ $# -ne 2 ]; then
  echo "Usage: $0 <directory> <new_version>"
  echo "Example: $0 ./downloads 147.0.10"
  exit 1
fi

dir="$1"
new_ver="$2"

repack() {
  local file=$1
  local basename
  basename="$(basename "$file")"

  # Strip prefix/suffix to get e.g. 147.0.11+g04f1d22+chromium-147.0.7727.138_macosarm64_minimal
  local rest="${basename#cef_binary_}"
  local without_suffix="${rest%.tar.bz2}"

  # Old "head" version is everything before the first '+' (e.g. 147.0.11)
  local old_head="${without_suffix%%+*}"

  # Extract platform: second-to-last _-delimited segment (before type)
  local platform="${without_suffix%_*}"   # strip _type  -> ..._macosarm64
  platform="${platform##*_}"              # keep last segment -> macosarm64

  local old_name="cef_binary_${without_suffix}"
  local new_name="cef_binary_${without_suffix/${old_head}/${new_ver}}"

  local workdir
  workdir="$(mktemp -d "${dir}/.repack_XXXXXX")"

  echo "[$platform] extracting..."
  tar -xjf "$file" -C "$workdir"

  echo "[$platform] renaming inner dir to ${new_ver}"
  mv "$workdir/$old_name" "$workdir/$new_name"

  echo "[$platform] repacking..."
  tar -cjf "${dir}/${new_name}.tar.bz2" -C "$workdir" "$new_name"

  rm -rf "$workdir"
  echo "[$platform] done -> ${new_name}.tar.bz2"
}

for f in "$dir"/cef_binary_*.tar.bz2; do
  [ -e "$f" ] || continue
  repack "$f"
done

echo "All done."
