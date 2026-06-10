import os
import platform
import shutil
import subprocess
from pathlib import Path
from urllib.request import urlopen


SCRIPT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_CEF_ARCHIVE_FORMAT = "tar.bz2"
AUTOMATE_GIT_PATH = SCRIPT_DIR / "automate-git.py"
AUTOMATE_GIT_URL = (
    "https://raw.githubusercontent.com/chromiumembedded/cef/master/tools/automate/automate-git.py"
)
ARCHES = ("x64", "x86", "arm64", "arm")


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


def add_arch_args(parser, include_arm=True):
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--x64", action="store_const", const="x64", dest="arch")
    group.add_argument("--x86", action="store_const", const="x86", dest="arch")
    group.add_argument("--arm64", action="store_const", const="arm64", dest="arch")
    if include_arm:
        group.add_argument("--arm", action="store_const", const="arm", dest="arch")


def default_arch():
    machine = platform.machine().lower()
    if machine in {"arm64", "aarch64"}:
        return "arm64"
    if machine in {"i386", "i686", "x86"}:
        return "x86"
    return "x64"


def selected_arch(args):
    return getattr(args, "arch", None) or default_arch()


def build_dir_arch(arch):
    return arch


def cef_build_args(arch):
    if arch == "x64":
        return ["--x64-build"]
    if arch == "arm64":
        return ["--arm64-build"]
    if arch == "arm":
        return ["--arm-build"]
    return []


def with_pgo_profiles(arch):
    system = platform.system()
    if system == "Linux":
        return arch in {"x64", "x86"}
    if system == "Windows":
        return arch in {"x64", "x86"}
    return True


def configure_build_environment(arch):
    system = platform.system()

    for name in ("CEF_ENABLE_AMD64", "CEF_ENABLE_ARM64", "CEF_INSTALL_SYSROOT", "GN_OUT_CONFIGS"):
        os.environ.pop(name, None)

    defines = {"is_official_build": "true", "is_component_build": "false"}
    out_arch = build_dir_arch(arch)
    os.environ["GN_OUT_CONFIGS"] = f"Debug_GN_{out_arch},Release_GN_{out_arch}"

    if system == "Linux":
        defines.update(use_sysroot="true", symbol_level="1", is_cfi="false")
        if arch == "x86":
            os.environ["CEF_INSTALL_SYSROOT"] = "x86"
        elif arch == "arm":
            os.environ["CEF_INSTALL_SYSROOT"] = "arm"
            defines.update(use_thin_lto="false", chrome_pgo_phase="0", use_vaapi="false")
        elif arch == "arm64":
            os.environ["CEF_INSTALL_SYSROOT"] = "arm64"
            defines.update(use_thin_lto="false", chrome_pgo_phase="0")
    elif system == "Darwin":
        machine = platform.machine().lower()
        if arch == "x64" and machine in {"arm64", "aarch64"}:
            os.environ["CEF_ENABLE_AMD64"] = "1"
        elif arch == "arm64" and machine not in {"arm64", "aarch64"}:
            os.environ["CEF_ENABLE_ARM64"] = "1"
    elif system == "Windows":
        if arch == "arm64":
            os.environ["CEF_ENABLE_ARM64"] = "1"
            defines.update(use_thin_lto="false", chrome_pgo_phase="0")

    set_gn_defines(**defines)


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


def ensure_automate_git():
    if AUTOMATE_GIT_PATH.exists():
        return AUTOMATE_GIT_PATH

    temp_path = AUTOMATE_GIT_PATH.with_suffix(".py.tmp")
    print(f"Downloading {AUTOMATE_GIT_URL} to {AUTOMATE_GIT_PATH}")
    try:
        with urlopen(AUTOMATE_GIT_URL) as response, temp_path.open("wb") as output:
            shutil.copyfileobj(response, output)
        temp_path.replace(AUTOMATE_GIT_PATH)
    finally:
        if temp_path.exists():
            temp_path.unlink()

    return AUTOMATE_GIT_PATH


def add_ref(parser):
    parser.add_argument(
        "--ref",
        default="master",
        help="Checkout ref name under checkouts/ to use. Defaults to master.",
    )
