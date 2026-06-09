#!/usr/bin/env python3

import argparse
import shutil
import sys
import tarfile
import tempfile
from pathlib import Path


def add_parser(subparsers):
    parser = subparsers.add_parser(
        "repack", help="Repack a binary archive with a new leading CEF version."
    )
    parser.add_argument("archive", help="cef_binary_*.tar.bz2 archive to repack.")
    parser.add_argument("new_version", help="New leading CEF version for the archive name and root directory.")
    return parser


def repack(path, new_version):
    name = path.name
    rest = name.removeprefix("cef_binary_")
    without_suffix = rest.removesuffix(".tar.bz2")
    old_head = without_suffix.split("+", 1)[0]
    platform_name = without_suffix.rsplit("_", 2)[1]
    old_name = f"cef_binary_{without_suffix}"
    new_name = f"cef_binary_{without_suffix.replace(old_head, new_version, 1)}"

    workdir = Path(tempfile.mkdtemp(prefix=".repack_", dir=path.parent))
    try:
        print(f"[{platform_name}] extracting...")
        with tarfile.open(path, "r:bz2") as archive:
            archive.extractall(workdir)

        print(f"[{platform_name}] renaming inner dir to {new_version}")
        (workdir / old_name).rename(workdir / new_name)

        output = path.parent / f"{new_name}.tar.bz2"
        print(f"[{platform_name}] repacking...")
        with tarfile.open(output, "w:bz2") as archive:
            archive.add(workdir / new_name, arcname=new_name)

        print(f"[{platform_name}] done -> {output.name}")
    finally:
        shutil.rmtree(workdir)


def run_command(args, rest=None):
    repack(Path(args.archive), args.new_version)


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", help="cef_binary_*.tar.bz2 archive to repack.")
    parser.add_argument("new_version", help="New leading CEF version for the archive name and root directory.")
    args = parser.parse_args(argv)
    run_command(args)


if __name__ == "__main__":
    main(sys.argv[1:])
