# CEF Workspace

Wrapper scripts around CEF's `automate-git.py` and `depot_tools` for working on
Chromium/CEF on Windows. Checkouts live under `checkouts\<ref>\` (default ref:
`master`). All scripts accept `-Ref <name>` and forward trailing arguments to
the underlying tool.

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

| Script               | Purpose                                                                                  |
| -------------------- | ---------------------------------------------------------------------------------------- |
| `update.ps1`         | Sync Chromium + CEF, repair corrupt deps, run `gclient sync`/`runhooks`, call `create.ps1`. |
| `create.ps1`         | Apply CEF patches and regenerate GN build files (`tools\gclient_hook.py`).               |
| `build.ps1`          | Build CEF with `autoninja`. Debug by default; `-Release $true` for Release.              |
| `make_distrib.ps1`   | Package a binary distribution (`tools\make_distrib.bat --ninja-build`).                  |
| `build-official.ps1` | One-shot official Release x64 build via `automate-git.py` (PGO, minimal distrib).        |
| `fix_style.ps1`      | Reformat CEF sources (`tools\fix_style.py`).                                             |
| `patch_updater.ps1`  | Regenerate CEF patch files from the current tree (`tools\patch_updater.py`).             |
