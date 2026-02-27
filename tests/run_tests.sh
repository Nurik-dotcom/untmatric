#!/usr/bin/env bash
# run_tests.sh - runs UNTformatic tests in headless mode.

set -u

GODOT_PATH="${GODOT_PATH:-godot}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_SCENE="res://tests/TestRunner.tscn"

echo "[INFO] Running UNTformatic tests"
echo "[INFO] Project: $PROJECT_DIR"
echo "[INFO] Godot: $GODOT_PATH"
echo "[INFO] Test scene: $TEST_SCENE"
echo

set +e
"$GODOT_PATH" --headless --path "$PROJECT_DIR" --scene "$TEST_SCENE" 2>&1
EXIT_CODE=$?
set -e

echo "[INFO] Test execution completed with exit code: $EXIT_CODE"

exit $EXIT_CODE
