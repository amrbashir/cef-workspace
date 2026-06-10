#!/usr/bin/env python3

import argparse
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

if __package__ is None:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from workspace_commands import create
from workspace_commands.common import add_ref, ensure_automate_git, init_env, run, set_gn_defines


DESTRUCTIVE_FLAGS = {
    "--force-clean",
    "--force-clean-deps",
    "--force-update",
    "--force-cef-update",
}


def add_parser(subparsers):
    parser = subparsers.add_parser("update", help="Sync Chromium/CEF and generate build files.")
    add_ref(parser)
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture passed to automate-git.py. Defaults to arm64 on macOS.",
    )
    return parser


def git_output(*cmd, cwd):
    completed = subprocess.run(
        ["git", *cmd],
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return completed.returncode, completed.stdout.strip()


def guard_destructive_flags(cef, rest):
    requested = [arg for arg in rest if arg in DESTRUCTIVE_FLAGS]
    if not requested or not (cef.cef_dir / ".git").exists():
        return

    _, dirty = git_output("status", "--porcelain", cwd=cef.cef_dir)
    upstream_rc, _ = git_output(
        "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}", cwd=cef.cef_dir
    )
    if upstream_rc == 0:
        _, unpushed = git_output("log", "@{u}..HEAD", "--oneline", cwd=cef.cef_dir)
    else:
        _, unpushed = git_output("log", "-1", "--oneline", cwd=cef.cef_dir)

    if not dirty and not unpushed:
        return

    print(f"ERROR: {', '.join(requested)} would discard work in {cef.cef_dir}", file=sys.stderr)
    if dirty:
        print("  uncommitted changes:", file=sys.stderr)
        for line in dirty.splitlines():
            print(f"    {line}", file=sys.stderr)
    if unpushed:
        print("  unpushed commits:", file=sys.stderr)
        for line in unpushed.splitlines():
            print(f"    {line}", file=sys.stderr)
    print("Commit and push, or move the work elsewhere, then re-run.", file=sys.stderr)
    raise SystemExit(1)


def repair_corrupt_entries(cef):
    entries_file = cef.chromium_dir / ".gclient_entries"
    if not entries_file.exists():
        return

    pattern = re.compile(r"^\s*'([^']+)'\s*:")
    invalid_path_chars = re.compile(r'[<>:"|?*]')
    for line in entries_file.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        rel = match.group(1)
        if rel == "src" or invalid_path_chars.search(rel):
            continue
        full = cef.chromium_dir / Path(rel)
        if not (full / ".git").exists():
            continue
        completed = subprocess.run(
            ["git", "-C", str(full), "rev-parse", "--verify", "--quiet", "HEAD"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if completed.returncode:
            print(f"- Removing corrupt: {rel}", file=sys.stderr)
            shutil.rmtree(full)


def run_command(args, rest):
    arch = args.arch or ("arm64" if platform.system() == "Darwin" else None)
    if arch:
        rest = [f"--{arch}-build", *rest]

    cef = init_env(args.ref)
    guard_destructive_flags(cef, rest)

    set_gn_defines(is_official_build="true", is_component_build="false")

    run(
        [
            "python3",
            ensure_automate_git(),
            f"--download-dir={cef.root}",
            f"--checkout=origin/{args.ref}",
            "--no-chromium-history",
            "--with-pgo-profiles",
            "--no-build",
            "--no-distrib",
            *rest,
        ]
    )

    repair_corrupt_entries(cef)
    run(["gclient", "sync", "--nohooks", "--no-history"], cwd=cef.chromium_dir)
    run(["gclient", "runhooks"], cwd=cef.chromium_dir)
    create.run_command(argparse.Namespace(ref=args.ref), [])


def main(argv=None):
    parser = argparse.ArgumentParser(description="Sync Chromium/CEF and generate build files.")
    add_ref(parser)
    parser.add_argument(
        "--arch",
        choices=["x64", "arm64"],
        help="Target architecture passed to automate-git.py. Defaults to arm64 on macOS.",
    )
    args, rest = parser.parse_known_args(argv)
    run_command(args, rest)


if __name__ == "__main__":
    main(sys.argv[1:])
