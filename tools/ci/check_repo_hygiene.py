#!/usr/bin/env python3
"""Fail CI on tracked temporary artifacts and duplicate external scripts."""

from __future__ import annotations

import fnmatch
import subprocess
import sys
from pathlib import Path


BANNED_TRACKED_PATTERNS = [
    ".codex_tmp/*",
    "backups/*",
    "tmp_*.log",
    "repomix-clean.txt",
    "scenes/Tutorial/temp_replace.txt",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def git_ls_files(root: Path) -> list[str]:
    output = subprocess.check_output(
        ["git", "ls-files"],
        cwd=root,
        text=True,
    )
    return [line.strip() for line in output.splitlines() if line.strip()]


def find_banned_tracked(paths: list[str]) -> list[str]:
    bad: list[str] = []
    for rel in paths:
        if any(fnmatch.fnmatch(rel, pattern) for pattern in BANNED_TRACKED_PATTERNS):
            bad.append(rel)
    return bad


def find_external_duplicates(root: Path) -> list[str]:
    # Optional check for monorepo layout:
    # parent/scripts/ui/*.gd should not duplicate project scripts/ui/*.gd.
    parent_root = root.parent
    external_ui_dir = parent_root / "scripts" / "ui"
    internal_ui_dir = root / "scripts" / "ui"
    if not external_ui_dir.exists() or not internal_ui_dir.exists():
        return []

    duplicates: list[str] = []
    for ext_script in external_ui_dir.glob("*.gd"):
        internal_candidate = internal_ui_dir / ext_script.name
        if internal_candidate.exists():
            duplicates.append(str(ext_script.relative_to(parent_root)).replace("\\", "/"))
    return duplicates


def main() -> int:
    root = repo_root()
    tracked = git_ls_files(root)

    banned = find_banned_tracked(tracked)
    duplicates = find_external_duplicates(root)

    has_errors = False
    if banned:
        has_errors = True
        print("[FAIL] Tracked temporary/service files detected:")
        for item in banned:
            print(f"  - {item}")

    if duplicates:
        has_errors = True
        print("[FAIL] Duplicate external scripts detected (parent/scripts/ui):")
        for item in duplicates:
            print(f"  - {item}")

    if has_errors:
        return 1

    print("[OK] Repository hygiene checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
