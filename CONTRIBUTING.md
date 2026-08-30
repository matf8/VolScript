# Contributing

Thanks for your interest in VolScript.

## Before you open a PR

1. Run the test suite on Windows:

```powershell
Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser
./src/Test/Run-Tests.ps1
```

2. Keep changes focused — one feature or fix per pull request when possible.

3. Match existing style in the module you touch (naming, spacing, small helpers over duplication).

## Project layout

| Path | Role |
|------|------|
| `VolScript.ps1` | Entry point |
| `src/Loader.psm1` | Module import order |
| `src/Core/Core.psm1` | Shared C# compilation |
| `src/Actions/` | Main runtime loop |
| `src/Test/` | Pester tests |

Do not add `-Force` to nested `Import-Module` calls — it can drop session exports.

## Adding tests

Put new tests in `src/Test/VolScript.Tests.ps1` or helpers in `src/Test/VolScript.TestHelpers.ps1`.

Pester v6 isolates `Describe` scopes — shared helpers belong in the helpers file, loaded from `BeforeAll`.

## Releases

Maintainers tag `v*` and push; GitHub Actions builds the release zip.

Local dry run:

```powershell
./scripts/Build-Release.ps1 -Version 1.0.0
```

## Packaging manifests

- **WinGet:** `packaging/winget/matf8.VolScript.yaml` — submit to [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)
- **Scoop:** `packaging/scoop/volscript.json` — add to a bucket or [ScoopExtras](https://github.com/ScoopInstaller/Extras)

Update version, URL, and SHA256 in those files when cutting a release.

## Questions

Open a [GitHub issue](https://github.com/matf8/VolScript/issues) for bugs, feature ideas, or compatibility reports (game, anti-cheat, audio device).
