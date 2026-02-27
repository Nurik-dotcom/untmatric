# UNTformatic Test Suite

This folder contains unit-style tests for core gameplay logic.

## Test files

- `test_global_metrics.gd`
- `test_matrix_solver.gd`
- `test_shields.gd`
- `test_runner.gd`
- `TestRunner.tscn`

## Suite contract

Every test suite must expose:

```gdscript
func get_test_results() -> Dictionary
```

Expected result shape:

```gdscript
{
	"passed": int,
	"failed": int,
	"skipped": int # optional
}
```

If the contract is missing, the runner marks the suite as failed.

## How to run tests

From project root (`untmatric`):

### Windows (`cmd.exe`)

```bat
tests\run_tests.bat
```

### Linux/macOS

```bash
chmod +x tests/run_tests.sh
./tests/run_tests.sh
```

### Direct Godot command

```bash
godot --headless --path . --scene res://tests/TestRunner.tscn
```

## Pass/fail rules

- Exit code `0`: all suites passed, no suite errors, no script parse errors.
- Exit code `1`: any failed assertion, suite load/contract error, or parse/runtime error in test scripts.

## CI behavior

GitHub Actions uses Godot `4.3` and runs:

```bash
godot --headless --path "$GITHUB_WORKSPACE" --scene res://tests/TestRunner.tscn
```

The workflow fails when:

- Godot returns non-zero exit code.
- Log contains `SCRIPT ERROR:` or `Parse Error:`.

## Known limitations

- Current tests focus on core logic only.
- UI scene behavior and full end-to-end quest flows are not covered.
- Timing-sensitive checks can still be environment-dependent in very slow CI hosts.

## Troubleshooting

- `Failed to load script`: check script path and parse errors in console output.
- `Godot executable not found`: set `GODOT_PATH` or add `godot` to `PATH`.
- Runner exits `0` unexpectedly: ensure suite returns `get_test_results()` and increments failed counters.
