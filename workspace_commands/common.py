import os
import platform
import subprocess
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent.parent


class CefEnv:
    def __init__(self, ref):
        self.root = SCRIPT_DIR / "checkouts" / ref
        self.chromium_dir = self.root / "chromium"
        self.cef_dir = self.chromium_dir / "src" / "cef"


def parse_bool(value):
    if isinstance(value, bool):
        return value
    if value is None:
        return True
    return str(value).lower() in {"1", "true", "yes", "on", "$true"}


def normalize_legacy_args(argv):
    normalized = []
    for arg in argv:
        if arg.startswith("-Release:"):
            normalized.append("--release=" + arg.split(":", 1)[1])
        elif arg == "-Release":
            normalized.append("--release")
        else:
            normalized.append(arg)
    return normalized


def init_env(ref):
    cef = CefEnv(ref)
    os.environ["PATH"] = str(cef.root / "depot_tools") + os.pathsep + os.environ.get("PATH", "")
    os.environ["DEPOT_TOOLS_WIN_TOOLCHAIN"] = "0"
    os.environ["GYP_MSVS_VERSION"] = "2022"
    return cef


def run(cmd, cwd=None):
    completed = subprocess.run([str(part) for part in cmd], cwd=str(cwd) if cwd else None)
    if completed.returncode:
        raise SystemExit(completed.returncode)


def default_arch():
    return "arm64" if platform.system() == "Darwin" else "x64"


def add_ref(parser):
    parser.add_argument(
        "--ref",
        default="master",
        help="Checkout ref name under checkouts/ to use. Defaults to master.",
    )
