# CEF Workspace

Wrapper scripts around CEF's `automate-git.py` and `depot_tools` for working on
Chromium/CEF on Windows, macOS, or Linux. The checkout lives under `chromium_git/`. The
first update or official-build run creates that root, and the other scripts
operate on the same checkout. Scripts forward unrecognized trailing arguments
to the underlying tool.

### Build configurations

`update.ps1`/`create.ps1` generate two independent output directories:

| Out dir             | `is_component_build` | Use                                    |
| ------------------- | -------------------- | -------------------------------------- |
| `Debug_GN_<arch>`   | `true`               | Iterating on CEF sources, `cefclient`. |
| `Release_GN_<arch>` | `false`              | `make_distrib` output for cef-rs.      |

The component build splits Chromium into ~100 shared libraries, so relinking
after a source change takes seconds instead of minutes. It cannot be packaged:
the framework resolves its component libraries through an rpath into the ninja
output root, so it stops loading once copied elsewhere.

`is_component_build` is a compile-time flag, not a link-time one, so the two
configurations share no object files. That is why they get separate directories
rather than one directory that gets reconfigured — each stays incrementally
warm, and switching between them costs only the files changed since that
directory was last built, plus a link.

### Iterating on CEF (cefclient)

```powershell
.\update.ps1
.\build.ps1
.\chromium_git\chromium\src\out\Debug_GN_x64\cefclient.exe
```

### Packaging for cef-rs / tauri

```powershell
.\build.ps1 -Release
.\make_distrib.ps1
```

Always produces a minimal distribution — `Release_GN_<arch>` only.

### Official distribution build

```powershell
.\build-official.ps1
```

### Scripts

| Script                   | Purpose                                                                                                                           |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `update.ps1/.sh`         | Sync Chromium + CEF, repair corrupt deps, run `gclient sync`/`runhooks`, call `create.ps1/.sh`.                                   |
| `create.ps1/.sh`         | Apply CEF patches and regenerate GN build files (`tools\gclient_hook.py`) for both configurations.                                |
| `build.ps1/.sh`          | Build CEF with `autoninja`. Component Debug by default; `-Release` for the packageable config.                                    |
| `make_distrib.ps1/.sh`   | Package a minimal binary distribution (`tools\make_distrib.bat --ninja-build --minimal`).                                         |
| `build-official.ps1/.sh` | One-shot official Release build via `automate-git.py` (PGO, minimal distrib).                                                     |
| `fix_style.ps1/.sh`      | Reformat CEF sources (`tools\fix_style.py`).                                                                                      |
| `patch_updater.ps1/.sh`  | Regenerate CEF patch files from the current tree (`tools\patch_updater.py`).                                                      |
