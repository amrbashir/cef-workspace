#!/usr/bin/env python3

import argparse
import sys

from workspace_commands import (
    build,
    build_official,
    create,
    fix_style,
    gen_index,
    make_distrib,
    patch_updater,
    repack,
    update,
)
from workspace_commands.common import normalize_legacy_args


COMMANDS = {
    "build": build,
    "build-official": build_official,
    "create": create,
    "fix-style": fix_style,
    "gen-index": gen_index,
    "make-distrib": make_distrib,
    "patch-updater": patch_updater,
    "repack": repack,
    "update": update,
}


def build_parser():
    parser = argparse.ArgumentParser(description="Cross-platform CEF workspace commands.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for module in COMMANDS.values():
        module.add_parser(subparsers)
    return parser


def main(argv):
    argv = normalize_legacy_args(argv)
    parser = build_parser()
    args, rest = parser.parse_known_args(argv)
    COMMANDS[args.command].run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
