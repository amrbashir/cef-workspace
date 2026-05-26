# CEF Workspace

## Workflows

### Local development

```powershell
.\update.ps1
.\dev.ps1
```

`update.ps1` creates or updates `checkouts\<Ref>`, syncs Chromium/CEF deps, runs hooks, and generates GN files.

`dev.ps1` builds `out\Debug_GN_x64\cef` and runs `cefclient.exe`. Extra args are passed to `cefclient.exe`.

### Release build

```powershell
.\build.ps1
```

Builds an official x64 minimal CEF distribution with `tar.bz2` archives, no debug build, docs, or symbols.

## Scripts

| Script | Purpose |
| --- | --- |
| `build.ps1 [-Ref master] [args...]` | Build an official x64 minimal CEF distribution via `automate-git.py`. |
| `update.ps1 [-Ref master] [args...]` | Fetch/update Chromium + CEF, repair corrupt deps, sync hooks, and generate GN files. |
| `create.ps1 [-Ref master]` | Run CEF `gclient_hook.py` for the checkout. |
| `dev.ps1 [-Ref master] [cefclient args...]` | Build `cef` Debug x64 with `autoninja`, then run `cefclient.exe`. |
| `fix_style.ps1 [-Ref master] [args...]` | Run CEF `tools\fix_style.py`. |
| `make_distrib.ps1 [-Ref master] [args...]` | Run CEF `tools\make_distrib.py` for a partial x64 binary distribution. |
| `generate-index-json.sh [directory]` | Generate CEF binary `index.json` from `cef_binary_*.tar.bz2` files. |
| `repack.sh <directory> <new_version>` | Repack CEF binary archives with a replaced head version. |
