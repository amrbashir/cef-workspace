#!/usr/bin/env python3

import argparse
import os
import sys

if __package__ is None:
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import add_arch_args, add_ref, configure_build_environment, init_env, run, selected_arch


def add_parser(subparsers):
    parser = subparsers.add_parser("create", help="Apply CEF patches and regenerate GN build files.")
    add_ref(parser)
    add_arch_args(parser)
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    configure_build_environment(selected_arch(args))
    os.environ["GN_ARGUMENTS"] = "--ide=vs2022 --sln=cef --filters=//cef/*"
    run(["python3", "tools/gclient_hook.py", *rest], cwd=cef.cef_dir)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Apply CEF patches and regenerate GN build files.")
    add_ref(parser)
    add_arch_args(parser)
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
