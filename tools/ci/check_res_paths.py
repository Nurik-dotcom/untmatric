#!/usr/bin/env python3
"""Fail CI if a referenced res:// path does not exist."""

from __future__ import annotations

import re
import sys
from pathlib import Path


RES_PATTERN = re.compile(r"res://[^\s\"'\)\],]+")
CHECK_EXTS = {
    ".gd",
    ".gdshader",
    ".godot",
    ".tscn",
    ".tres",
    ".cfg",
}
SKIP_DIRS = {".git", ".github", ".godot", "android", "backups"}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def iter_source_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel_parts = path.relative_to(root).parts
        if any(part in SKIP_DIRS for part in rel_parts):
            continue
        if path.suffix.lower() not in CHECK_EXTS:
            continue
        files.append(path)
    return files


def normalize_res_path(raw: str) -> str:
    value = raw.strip()
    if "::" in value:
        value = value.split("::", 1)[0]
    while value.endswith((".", ",", ";", ":")):
        value = value[:-1]
    return value


def check_paths(root: Path) -> list[str]:
    missing: list[str] = []
    for path in iter_source_files(root):
        rel_file = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        for line_no, line in enumerate(text.splitlines(), start=1):
            for match in RES_PATTERN.findall(line):
                ref = normalize_res_path(match)
                rel_ref = ref.replace("res://", "", 1)
                local_path = root / rel_ref
                if not local_path.exists():
                    missing.append(f"{rel_file}:{line_no} -> {ref}")
    return missing


def main() -> int:
    root = repo_root()
    missing = check_paths(root)
    if missing:
        print("[FAIL] Missing res:// references:")
        for item in missing:
            print(f"  - {item}")
        return 1
    print("[OK] All res:// references are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
