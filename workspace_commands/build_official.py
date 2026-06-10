#!/usr/bin/env python3

import argparse
import sys

if __package__ is None:
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import add_ref, default_arch, ensure_automate_git, init_env, run, set_gn_defines


def add_parser(subparsers):
    parser = subparsers.add_parser("build-official", help="One-shot official Release build.")
    add_ref(parser)
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture. Defaults to arm64 on macOS and x64 elsewhere.",
    )
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    arch = args.arch or default_arch()
    set_gn_defines(is_official_build="true", is_component_build="false")
    run(
        [
            "python3",
            ensure_automate_git(),
            f"--download-dir={cef.root}",
            f"--checkout=origin/{args.ref}",
            "--no-chromium-history",
            "--minimal-distrib-only",
            "--no-debug-build",
            f"--{arch}-build",
            "--no-distrib-docs",
            "--no-distrib-symbols",
            "--with-pgo-profiles",
            *rest,
        ]
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description="One-shot official Release build.")
    add_ref(parser)
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture. Defaults to arm64 on macOS and x64 elsewhere.",
    )
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
