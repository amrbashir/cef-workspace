#!/usr/bin/env python3

import argparse
import sys

if __package__ is None:
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands.common import add_ref, init_env, run


def add_parser(subparsers):
    parser = subparsers.add_parser("patch-updater", help="Regenerate CEF patch files.")
    add_ref(parser)
    return parser


def run_command(args, rest):
    cef = init_env(args.ref)
    run(["python3", "tools/patch_updater.py", *rest], cwd=cef.cef_dir)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Regenerate CEF patch files.")
    add_ref(parser)
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
