# CEF Workspace

Python wrappers around CEF's `automate-git.py` and `depot_tools` for working on
Chromium/CEF. Checkouts live under `checkouts/<ref>/` (default ref: `master`).
Commands accept `--ref <name>` and forward unknown trailing arguments to the
underlying tool. Each command is implemented in `workspace_commands/` and can
also be invoked directly.

### Local development

```bash
python3 workspace.py update
python3 workspace.py build
```

### Release build

```bash
python3 workspace.py build --release
python3 workspace.py make-distrib --minimal
```

### Official distribution build

```bash
python3 workspace.py build-official
```

### Scripts

| Command                                | Purpose                                                                                     |
| -------------------------------------- | ------------------------------------------------------------------------------------------- |
| `python3 workspace.py update`          | Sync Chromium + CEF, repair corrupt deps, run `gclient sync`/`runhooks`, then create files. |
| `python3 workspace.py create`          | Apply CEF patches and regenerate GN build files (`tools/gclient_hook.py`).                  |
| `python3 workspace.py build`           | Build CEF with `autoninja`. Debug by default; use `--release` for Release.                 |
| `python3 workspace.py make-distrib`    | Package a binary distribution (`tools/make_distrib.py --ninja-build`).                     |
| `python3 workspace.py build-official`  | One-shot official Release build via `automate-git.py` (PGO, minimal distrib).              |
| `python3 workspace.py fix-style`       | Reformat CEF sources (`tools/fix_style.py`).                                                |
| `python3 workspace.py patch-updater`   | Regenerate CEF patch files from the current tree (`tools/patch_updater.py`).                |
| `python3 workspace.py gen-index <dir> <output-file>` | Generate an `index.json` payload from `cef_binary_*.tar.bz2` files.        |
| `python3 workspace.py repack <archive> <version>` | Repack one `cef_binary_*.tar.bz2` file with a new leading CEF version.          |

Direct command modules use the same arguments. For example:

```bash
python3 workspace_commands/build.py --release
python3 workspace_commands/gen_index.py ./downloads index.json
```
