# Testing Guide

This document describes the current, supported test flow for UNTformatic.

## Prerequisites

- Godot `4.3` (recommended and used in CI).
- Run commands from project root: `untmatric`.

## Primary command

```bash
godot --headless --path . --scene res://tests/TestRunner.tscn
```

This command is the source of truth for local runs and CI.

## Platform wrappers

### Windows

```bat
tests\run_tests.bat
```

### Linux/macOS

```bash
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

Both wrappers call the same runner scene and propagate the exit code.

## Runner contract

- Each suite must implement `get_test_results() -> Dictionary`.
- Missing script, missing contract, or invalid result format is treated as a failed suite.
- Final process exit code is non-zero on any failed suite/error.

## CI policy

Workflow: `.github/workflows/tests.yml`

- Uses Godot `4.3`.
- Fails on non-zero test exit code.
- Fails when log contains `SCRIPT ERROR:` or `Parse Error:`.
- Always uploads `test-output.log` artifact.

## Acceptance checklist

- `godot --headless --path . --scene res://tests/TestRunner.tscn` returns `0` only when all tests pass.
- Any broken assertion in any suite returns non-zero.
- Any parse error in a `test_*.gd` script returns non-zero.
- `tests/run_tests.bat` works in standard `cmd.exe`.
- `tests/run_tests.sh` resolves project root correctly and does not escape outside project.

## Known limitations

- Coverage is focused on logic/data layers (`GlobalMetrics`, matrix solver, shields, i18n/data contracts).
- Basic scene smoke coverage is included (`MainMenu`, `QuestSelect`, `LearnSelect`, and QuestSelect transition targets).
- Full interaction-level UI progression is still not fully tested end-to-end.
- Performance/load testing is not part of this suite.

## Troubleshooting

- `Failed to load script`: run the primary command and inspect first parse/runtime error in output.
- No Godot in PATH: set `GODOT_PATH` explicitly in wrapper environment.
- CI mismatch with local: verify local Godot version is `4.3` and run with `--path .`.
