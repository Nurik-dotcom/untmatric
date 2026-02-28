# UNTformatic

UNTformatic is a Godot 4.3 educational detective game project with multiple quest families (A/B/C complexity levels), localization, and headless test automation.

## Tech Stack

- Engine: Godot 4.3
- Language: GDScript
- Main scene: `res://scenes/MainMenu.tscn`
- Core autoloads:
  - `GlobalMetrics`
  - `I18n`
  - `AudioManager`
  - `UIViewportFit`

## Repository Scope

This directory (`untmatric/`) is the runtime source of truth.

- Runtime code: `scenes/`, `scripts/`
- Data and localization: `data/`
- Tests: `tests/`
- CI checks: `.github/workflows/tests.yml`, `tools/ci/`

## Local Run

From `untmatric/`:

```bash
godot --path .
```

## Test Run

Primary command:

```bash
godot --headless --path . --scene res://tests/TestRunner.tscn
```

Wrapper scripts:

- Windows: `tests/run_tests.bat`
- Linux/macOS: `tests/run_tests.sh`

## CI Gates

CI job `.github/workflows/tests.yml` runs:

1. Repository hygiene check (`tools/ci/check_repo_hygiene.py`)
2. `res://` reference integrity check (`tools/ci/check_res_paths.py`)
3. Headless test runner (`res://tests/TestRunner.tscn`)
4. Failure log upload (`test-output.log`)

## Repository Hygiene Policy

Do not commit temporary/service artifacts to git:

- `.codex_tmp/`
- `backups/`
- `tmp_*.log`
- `repomix-clean.txt`
- `scenes/Tutorial/temp_replace.txt`

Use `.gitignore` to keep these out of tracked history.
