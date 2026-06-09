#!/usr/bin/env python3

import argparse
import sys

if __package__ is None:
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import add_ref, default_arch, init_env, parse_bool, run


def add_parser(subparsers):
    parser = subparsers.add_parser("build", help="Build CEF with autoninja.")
    add_ref(parser)
    parser.add_argument(
        "--release",
        nargs="?",
        const=True,
        default=False,
        type=parse_bool,
        help="Build the Release GN output directory instead of Debug.",
    )
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture. Defaults to arm64 on macOS and x64 elsewhere.",
    )
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    arch = args.arch or default_arch()
    config = "Release" if parse_bool(args.release) else "Debug"
    out_dir = f"out/{config}_GN_{arch}"
    run(["autoninja", "-C", out_dir, "cef", *rest], cwd=cef.chromium_dir / "src")


def main(argv=None):
    parser = argparse.ArgumentParser(description="Build CEF with autoninja.")
    add_ref(parser)
    parser.add_argument(
        "--release",
        nargs="?",
        const=True,
        default=False,
        type=parse_bool,
        help="Build the Release GN output directory instead of Debug.",
    )
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture. Defaults to arm64 on macOS and x64 elsewhere.",
    )
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
