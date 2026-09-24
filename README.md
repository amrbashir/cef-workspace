# CEF Workspace

Wrapper scripts around CEF's `automate-git.py` and `depot_tools` for working on
Chromium/CEF on Windows, macOS, or Linux. The checkout lives under `chromium_git/`. The
first update or official-build run creates that root, and the other scripts
operate on the same checkout. Scripts forward unrecognized trailing arguments
to the underlying tool.

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

### Official distribution build

```powershell
.\build-official.ps1
```
