#!/usr/bin/env python3

import argparse
import datetime
import hashlib
import json
import os
import sys
from pathlib import Path

if __package__ is None:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import DEFAULT_CEF_ARCHIVE_FORMAT, add_ref, init_env


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

ARCHIVE_SUFFIXES = {
    "tar.bz2": ".tar.bz2",
    "zip": ".zip",
}


def add_parser(subparsers):
    parser = subparsers.add_parser(
        "gen-index", help="Generate an index.json payload from binary archives."
    )
    add_ref(parser)
    parser.add_argument(
        "directory",
        nargs="?",
        help="Directory containing cef_binary_* archives. Defaults to the selected checkout's CEF binary_distrib directory.",
    )
    parser.add_argument(
        "output_file",
        nargs="?",
        help="Path where the generated index.json will be written. Defaults to the selected checkout's CEF binary_distrib/index.json.",
    )
    return parser


def sha1(path):
    digest = hashlib.sha1()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def archive_suffix():
    archive_format = os.environ.get("CEF_ARCHIVE_FORMAT", DEFAULT_CEF_ARCHIVE_FORMAT)
    normalized = archive_format.removeprefix(".")
    return ARCHIVE_SUFFIXES.get(normalized, f".{normalized}")


def index_entry_for(path):
    name = path.name
    rest = name.removeprefix("cef_binary_")
    without_suffix = rest
    for suffix in ARCHIVE_SUFFIXES.values():
        if without_suffix.endswith(suffix):
            without_suffix = without_suffix.removesuffix(suffix)
            break
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
    cef = None
    if args.directory:
        directory = Path(args.directory)
    else:
        cef = init_env(args.ref)
        directory = cef.cef_dir / "binary_distrib"
    if args.output_file:
        output_file = Path(args.output_file)
    else:
        if cef is None:
            cef = init_env(args.ref)
        output_file = cef.cef_dir / "binary_distrib" / "index.json"
    result = {platform_name: {"versions": []} for platform_name in ALL_PLATFORMS}
    for path in sorted(directory.glob(f"cef_binary_*{archive_suffix()}")):
        platform_name, version = index_entry_for(path)
        result.setdefault(platform_name, {"versions": []})["versions"] = [version]
    output_file.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Generate index.json from cef_binary_* archives."
    )
    add_ref(parser)
    parser.add_argument(
        "directory",
        nargs="?",
        help="Directory containing cef_binary_* archives. Defaults to the selected checkout's CEF binary_distrib directory.",
    )
    parser.add_argument(
        "output_file",
        nargs="?",
        help="Path where the generated index.json will be written. Defaults to the selected checkout's CEF binary_distrib/index.json.",
    )
    args = parser.parse_args(argv)
    run_command(args)


if __name__ == "__main__":
    main(sys.argv[1:])
