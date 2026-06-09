#!/usr/bin/env python3

import argparse
import datetime
import hashlib
import json
import sys
from pathlib import Path


ALL_PLATFORMS = [
    "linux32",
    "linux64",
    "linuxarm",
    "linuxarm64",
    "macosarm64",
    "macosx64",
    "windows32",
    "windows64",
    "windowsarm64",
]


def add_parser(subparsers):
    parser = subparsers.add_parser(
        "gen-index", help="Generate an index.json payload from binary archives."
    )
    parser.add_argument("directory", help="Directory containing cef_binary_*.tar.bz2 files.")
    parser.add_argument("output_file", help="Path where the generated index.json will be written.")
    return parser


def sha1(path):
    digest = hashlib.sha1()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def index_entry_for(path):
    name = path.name
    rest = name.removeprefix("cef_binary_")
    without_suffix = rest.removesuffix(".tar.bz2")
    file_type = without_suffix.rsplit("_", 1)[1]
    platform_name = without_suffix.rsplit("_", 2)[1]
    cef_version = rest.split(f"_{platform_name}_", 1)[0]
    chromium_version = cef_version.rsplit("chromium-", 1)[1]
    stat = path.stat()
    last_modified = datetime.datetime.fromtimestamp(
        stat.st_mtime, tz=datetime.timezone.utc
    ).strftime("%Y-%m-%dT%H:%M:%S.000000Z")
    return platform_name, {
        "cef_version": cef_version,
        "chromium_version": chromium_version,
        "channel": "stable",
        "files": [
            {
                "last_modified": last_modified,
                "name": name,
                "sha1": sha1(path),
                "size": stat.st_size,
                "type": file_type,
            }
        ],
    }


def run_command(args, rest=None):
    result = {platform_name: {"versions": []} for platform_name in ALL_PLATFORMS}
    for path in sorted(Path(args.directory).glob("cef_binary_*.tar.bz2")):
        platform_name, version = index_entry_for(path)
        result.setdefault(platform_name, {"versions": []})["versions"] = [version]
    Path(args.output_file).write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Generate index.json from cef_binary_*.tar.bz2 files."
    )
    parser.add_argument("directory", help="Directory containing cef_binary_*.tar.bz2 files.")
    parser.add_argument("output_file", help="Path where the generated index.json will be written.")
    args = parser.parse_args(argv)
    run_command(args)


if __name__ == "__main__":
    main(sys.argv[1:])
