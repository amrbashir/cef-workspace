#!/usr/bin/env python3

import argparse
import sys

if __package__ is None:
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import (
    add_arch_args,
    add_ref,
    cef_build_args,
    configure_build_environment,
    init_env,
    run,
    selected_arch,
)


def add_parser(subparsers):
    parser = subparsers.add_parser("make-distrib", help="Package a binary distribution.")
    add_ref(parser)
    parser.add_argument(
        "--minimal",
        action="store_true",
        help="Create a minimal distribution instead of an allow-partial full distribution.",
    )
    add_arch_args(parser)
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    arch = selected_arch(args)
    configure_build_environment(arch)
    cli_args = [
        "--output-dir",
        cef.cef_dir / "binary_distrib",
        "--ninja-build",
        *cef_build_args(arch),
    ]
    cli_args.append("--minimal" if args.minimal else "--allow-partial")
    if any(arg == "--output-dir" or arg.startswith("--output-dir=") for arg in rest):
        cli_args = cli_args[2:]
    run(["python3", "tools/make_distrib.py", *cli_args, *rest], cwd=cef.cef_dir)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Package a binary distribution.")
    add_ref(parser)
    parser.add_argument(
        "--minimal",
        action="store_true",
        help="Create a minimal distribution instead of an allow-partial full distribution.",
    )
    add_arch_args(parser)
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
