#!/usr/bin/env bash
# run_tests.sh - запускает тесты UNTformatic
# Использует Godot headless режим

set -e

GODOT_PATH="${GODOT_PATH:-godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
TEST_SCENE="res://tests/TestRunner.tscn"

echo "🧪 Running UNTformatic Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $PROJECT_DIR"
echo "Godot: $GODOT_PATH"
echo "Test Scene: $TEST_SCENE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

cd "$PROJECT_DIR"

# Запустить тесты в headless режиме
$GODOT_PATH --headless --scene "$TEST_SCENE" 2>&1

EXIT_CODE=$?

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test execution completed with exit code: $EXIT_CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $EXIT_CODE
