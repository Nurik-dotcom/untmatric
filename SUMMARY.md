# UNTformatic Technical Summary

## Project Snapshot

- Project: UNTformatic
- Engine target: Godot 4.3
- Runtime root: `untmatric/`
- Main scene: `res://scenes/MainMenu.tscn`
- Target platform in presets: Android (`export_presets.cfg`)

## Runtime Architecture

- Entry flow:
  - `MainMenu` -> `QuestSelect` / `LearnSelect`
  - `QuestSelect` routes to A/B/C quest scenes
- Core autoload singletons:
  - `GlobalMetrics` (game/session state and scoring support)
  - `I18n` (language dictionaries and fallback chain)
  - `AudioManager` (audio pool playback)
  - `UIViewportFit` (viewport scaling on small landscape screens)
- Data-driven gameplay:
  - quest definitions and level packs under `data/`
  - localized strings under `data/i18n/`

## Quality Baseline

Latest local command:

```bash
godot --headless --path . --scene res://tests/TestRunner.tscn
```

Latest observed totals:

- Passed: `1289`
- Failed: `0`
- Suite errors: `0`

Test suites:

- `GlobalMetrics`
- `MatrixSolver`
- `Shields`
- `Case08DataContract`
- `I18n`
- `SceneSmoke`

## CI Baseline

Workflow: `.github/workflows/tests.yml`

Checks in order:

1. Repository hygiene (`tools/ci/check_repo_hygiene.py`)
2. `res://` path integrity (`tools/ci/check_res_paths.py`)
3. Headless tests (`res://tests/TestRunner.tscn`)

## Current Stabilization Outcome

- Removed stale plugin enablement from `project.godot` (`editor_plugins` now empty).
- Normalized UI version text to Godot 4.3 in:
  - `scenes/MainMenu.gd`
  - `data/i18n/{ru,kk,en}.json`
- Added smoke coverage for key menu/quest scene targets.
- Removed tracked temporary/service files (`.codex_tmp`, `backups`, tmp logs, scratch files).
- Removed external duplicate UI scripts outside runtime root.
