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
    ensure_automate_git,
    init_env,
    run,
    selected_arch,
    with_pgo_profiles,
)


def add_parser(subparsers):
    parser = subparsers.add_parser("build-official", help="One-shot official Release build.")
    add_ref(parser)
    add_arch_args(parser)
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    arch = selected_arch(args)
    configure_build_environment(arch)
    cli_args = [
        "python3",
        ensure_automate_git(),
        f"--download-dir={cef.root}",
        f"--checkout=origin/{args.ref}",
        "--no-chromium-history",
        "--minimal-distrib-only",
        "--no-debug-build",
        *cef_build_args(arch),
        "--no-distrib-docs",
        "--no-distrib-symbols",
    ]
    if with_pgo_profiles(arch):
        cli_args.append("--with-pgo-profiles")
    run(
        [
            *cli_args,
            *rest,
        ]
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description="One-shot official Release build.")
    add_ref(parser)
    add_arch_args(parser)
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
