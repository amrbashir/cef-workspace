#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# Name recorded in archive.json. cef-rs ignores the directory if this version
# is newer than its own.
archive_name="$1"

distrib_root="$CEF_DIR/binary_distrib"
distrib=
for candidate in "$distrib_root"/cef_binary_*_minimal; do
    if [[ -d "$candidate" && (-z "$distrib" || "$candidate" -nt "$distrib") ]]; then
        distrib="$candidate"
    fi
done
if [[ -z "$distrib" ]]; then
    echo "ERROR: No cef_binary_*_minimal directory in $distrib_root" >&2
    exit 1
fi

[[ "$(uname -s)" == Darwin ]] && cef_rs_os=macos || cef_rs_os=linux
[[ "$CEF_BUILD_ARCH" == arm64 ]] && cef_rs_arch=aarch64 || cef_rs_arch=x86_64
out_dir="$distrib_root/cef_${cef_rs_os}_${cef_rs_arch}"

# Flatten the way cef-rs does: Release/ becomes the directory itself,
# Resources/ is merged into its top level (except on macOS, where it lives
# inside the framework), headers and wrapper sources sit alongside them.
rm -rf "$out_dir"
mkdir -p "$out_dir"
cp -R "$distrib/Release/." "$out_dir/"
[[ "$cef_rs_os" == macos ]] || cp -R "$distrib/Resources/." "$out_dir/"
for item in CMakeLists.txt cmake include libcef_dll CREDITS.html; do
    cp -R "$distrib/$item" "$out_dir/"
done

archive="$distrib.tar.bz2"
: "${archive_name:=$(basename "$archive")}"
sha1=$([[ -f "$archive" ]] && sha1sum "$archive" | cut -d' ' -f1 || true)
cat > "$out_dir/archive.json" <<JSON
{
  "type": "minimal",
  "name": "$archive_name",
  "sha1": "$sha1"
}
JSON

echo "export CEF_PATH=$out_dir"
