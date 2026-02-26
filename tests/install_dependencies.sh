#!/usr/bin/env bash
# install_dependencies.sh - Setup test environment
# Usage: ./tests/install_dependencies.sh

set -e

echo "Setting up test environment..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Godot is installed
if ! command -v godot &> /dev/null; then
    echo "⚠️  Warning: Godot not found in PATH"
    echo "Please visit: https://godotengine.org/download"
    echo "And add it to your PATH"
    exit 1
fi

GODOT_VERSION=$(godot --version 2>&1 | head -n1)
echo "✓ Godot found: $GODOT_VERSION"

# Import assets/resources if needed
if [ -f "project.godot" ]; then
    echo "✓ Project configuration found"
else
    echo "✗ project.godot not found"
    echo "Make sure you're in the project root directory"
    exit 1
fi

# Check if Scripts folder exists
if [ -d "scripts" ]; then
    echo "✓ Scripts folder found"
else
    echo "✗ Scripts folder not found"
    exit 1
fi

# Check if tests folder exists
if [ -d "tests" ]; then
    echo "✓ Tests folder found"
else
    echo "✗ Tests folder not found"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Run tests: ./tests/run_tests.sh"
echo "  2. Read docs: cat tests/README.md"
echo "  3. Debug failing tests for investigation"
echo ""
