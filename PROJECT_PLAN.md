# UNTformatic Stabilization Plan (Incremental)

## Goal

Keep gameplay behavior stable while improving repository integrity, CI coverage, and documentation accuracy.

## Scope

In scope:

- Repository hygiene and tracked file cleanup
- Consistent project/editor configuration
- Accurate technical documentation
- CI integrity checks
- Smoke tests for scene loading and `QuestSelect` targets

Out of scope:

- Deep architecture rewrite
- Gameplay redesign
- Public API/data contract changes

## Implemented Baseline

1. Runtime source-of-truth fixed to `untmatric/`.
2. External duplicate scripts removed from root `scripts/ui/`.
3. Temporary/service tracked files removed and ignored.
4. Missing editor plugin enablement removed from `project.godot`.
5. UI version text aligned to Godot 4.3.
6. CI gates expanded:
   - `tools/ci/check_repo_hygiene.py`
   - `tools/ci/check_res_paths.py`
   - existing headless tests
7. New smoke suite added (`tests/test_scene_smoke.gd`) and wired into `tests/test_runner.gd`.

## Next Increment (No Deep Refactor)

1. Add selective gameplay smoke checks for key interactions after scene load.
2. Add deterministic seed mode for random-heavy tests where relevant.
3. Add lightweight build validation for Android export preset.
4. Continue replacing stale legacy markdown with project-local docs only.

## Acceptance Criteria

1. `godot --headless --path . --scene res://tests/TestRunner.tscn` returns success.
2. `tools/ci/check_res_paths.py` reports no missing `res://` references.
3. `tools/ci/check_repo_hygiene.py` reports no banned tracked artifacts.
4. No editor warning about missing plugin path from `project.godot`.
