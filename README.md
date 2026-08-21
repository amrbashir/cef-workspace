# CEF Workspace

Wrapper scripts around CEF's `automate-git.py` and `depot_tools` for working on
Chromium/CEF on Windows, macOS, or Linux. The checkout lives under `chromium_git/`. The
first update or official-build run creates that root, and the other scripts
operate on the same checkout. Scripts forward unrecognized trailing arguments
to the underlying tool.

### Local development

```powershell
.\update.ps1
.\build.ps1
```

### Release build

```powershell
.\build.ps1 -Release $true
.\make_distrib.ps1 --minimal
```

### Official distribution build

```powershell
.\build-official.ps1
```

### Scripts

| Script                   | Purpose                                                                                         |
| ------------------------ | ----------------------------------------------------------------------------------------------- |
| `update.ps1/.sh`         | Sync Chromium + CEF, repair corrupt deps, run `gclient sync`/`runhooks`, call `create.ps1/.sh`. |
| `create.ps1/.sh`         | Apply CEF patches and regenerate GN build files (`tools\gclient_hook.py`).                      |
| `build.ps1/.sh`          | Build CEF with `autoninja`. Debug by default; `-Release $true` for Release.                     |
| `make_distrib.ps1/.sh`   | Package a binary distribution (`tools\make_distrib.bat --ninja-build`).                         |
| `build-official.ps1/.sh` | One-shot official Release build via `automate-git.py` (PGO, minimal distrib).                   |
| `fix_style.ps1/.sh`      | Reformat CEF sources (`tools\fix_style.py`).                                                    |
| `patch_updater.ps1/.sh`  | Regenerate CEF patch files from the current tree (`tools\patch_updater.py`).                    |
