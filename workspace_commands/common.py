import os
import platform
import shutil
import subprocess
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_CEF_ARCHIVE_FORMAT = "tar.bz2"


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
    os.environ["CEF_ARCHIVE_FORMAT"] = DEFAULT_CEF_ARCHIVE_FORMAT
    set_gn_defines(is_official_build="true", is_component_build="false")
    return cef


def set_gn_defines(**defines):
    gn_defines = os.environ.get("GN_DEFINES", "").split()
    values = {}
    order = []

    for define in gn_defines:
        key, separator, value = define.partition("=")
        if not separator:
            continue
        if key not in values:
            order.append(key)
        values[key] = value

    for key, value in defines.items():
        if key not in values:
            order.append(key)
        values[key] = value

    os.environ["GN_DEFINES"] = " ".join(f"{key}={values[key]}" for key in order)


def resolve_command(command):
    command = str(command)
    if os.name != "nt" or Path(command).suffix:
        return command

    for extension in os.environ.get("PATHEXT", "").split(os.pathsep):
        resolved = shutil.which(command + extension)
        if resolved:
            return resolved
    return command


def run(cmd, cwd=None):
    resolved = [resolve_command(cmd[0]), *[str(part) for part in cmd[1:]]]
    completed = subprocess.run(resolved, cwd=str(cwd) if cwd else None)
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
