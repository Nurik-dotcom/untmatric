#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List


ROOT = Path(__file__).resolve().parents[2]
LEVELS_PATH = ROOT / "data" / "final_report_a_levels.json"


# Per-level fragment index (0-based) -> canonical ASCII id.
TARGET_IDS_BY_LEVEL: Dict[str, Dict[int, str]] = {
    "FR8-A-L01": {1: "li_a", 2: "li_b", 5: "noise_div"},
    "FR8-A-L02": {5: "noise_p"},
    "FR8-A-N01": {2: "a_mvp", 5: "noise_span"},
    "FR8-A-N02": {4: "noise_div"},
    "FR8-A-T01": {5: "noise_div"},
    "FR8-A-T02": {1: "row_1", 2: "row_2", 3: "row_3"},
    "FR8-A-F02": {1: "name_label", 2: "name_input", 3: "code_label", 4: "code_input", 7: "noise_div"},
    "FR8-A-A02": {5: "noise_nav"},
    "FR8-A-M02": {2: "caption_camera"},
}


BUCKET_BY_LEVEL: Dict[str, str] = {
    "FR8-A-L01": "newbie",
    "FR8-A-L02": "newbie",
    "FR8-A-N01": "newbie",
    "FR8-A-N02": "newbie",
    "FR8-A-T01": "intermediate",
    "FR8-A-T02": "intermediate",
    "FR8-A-F01": "intermediate",
    "FR8-A-F02": "intermediate",
    "FR8-A-A01": "advanced",
    "FR8-A-A02": "advanced",
    "FR8-A-M01": "advanced",
    "FR8-A-M02": "advanced",
}


FR8_A_F01_FEEDBACK_RULES = {
    "UNBALANCED_TAG": "Контейнер разорван: начало и конец структуры не совпадают.",
    "HIERARCHY_VIOLATION": "Чужеродный элемент внутри контейнера.",
    "REQUIRED_TAG_MISSING": "Обязательный элемент отсутствует внутри контейнера.",
    "ORDER_MISMATCH": "Синтаксис жив, но порядок улик нарушен.",
    "OK": "Улики восстановлены. Файл читаем.",
}


FR8_A_F02_BRIEFING = "Форма с двумя полями. Соберите без лишних элементов."


def build_remap(levels: List[dict]) -> Dict[str, str]:
    remap: Dict[str, str] = {}
    for level in levels:
        level_id = str(level.get("id", "")).strip()
        level_targets = TARGET_IDS_BY_LEVEL.get(level_id)
        if not level_targets:
            continue
        fragments = level.get("fragments", [])
        if not isinstance(fragments, list):
            continue
        for idx, target_id in level_targets.items():
            if idx < 0 or idx >= len(fragments):
                raise RuntimeError(f"{level_id}: fragment index {idx} is out of range")
            fragment = fragments[idx]
            if not isinstance(fragment, dict):
                raise RuntimeError(f"{level_id}: fragment at index {idx} is not an object")
            old_id = str(fragment.get("fragment_id", "")).strip()
            if not old_id:
                raise RuntimeError(f"{level_id}: fragment index {idx} has empty fragment_id")
            if old_id == target_id:
                continue
            if old_id in remap and remap[old_id] != target_id:
                raise RuntimeError(
                    f"Conflicting mapping for '{old_id}': '{remap[old_id]}' vs '{target_id}'"
                )
            remap[old_id] = target_id
    return remap


def apply_global_remap(levels: List[dict], remap: Dict[str, str]) -> int:
    changed = 0
    for level in levels:
        fragments = level.get("fragments", [])
        if isinstance(fragments, list):
            for fragment in fragments:
                if not isinstance(fragment, dict):
                    continue
                old_id = str(fragment.get("fragment_id", ""))
                if old_id in remap:
                    fragment["fragment_id"] = remap[old_id]
                    changed += 1
                for key in ("label_key", "token_key"):
                    key_value = str(fragment.get(key, ""))
                    if key_value in remap:
                        fragment[key] = remap[key_value]
                        changed += 1

        expected = level.get("expected_sequence", [])
        if isinstance(expected, list):
            for i, entry in enumerate(expected):
                entry_str = str(entry)
                if entry_str in remap:
                    expected[i] = remap[entry_str]
                    changed += 1
    return changed


def apply_content_fixes(levels: List[dict]) -> int:
    changed = 0
    for level in levels:
        level_id = str(level.get("id", "")).strip()

        target_bucket = BUCKET_BY_LEVEL.get(level_id)
        if target_bucket and str(level.get("bucket", "")).strip() != target_bucket:
            level["bucket"] = target_bucket
            changed += 1

        if level_id == "FR8-A-F01":
            if level.get("feedback_rules") != FR8_A_F01_FEEDBACK_RULES:
                level["feedback_rules"] = dict(FR8_A_F01_FEEDBACK_RULES)
                changed += 1
        elif level_id == "FR8-A-F02":
            if str(level.get("briefing", "")) != FR8_A_F02_BRIEFING:
                level["briefing"] = FR8_A_F02_BRIEFING
                changed += 1
    return changed


def validate_ascii_fragment_ids(levels: List[dict]) -> None:
    bad: List[str] = []
    for level in levels:
        level_id = str(level.get("id", "UNKNOWN"))
        for fragment in level.get("fragments", []):
            if not isinstance(fragment, dict):
                continue
            fragment_id = str(fragment.get("fragment_id", ""))
            if any(ord(ch) > 127 for ch in fragment_id):
                bad.append(f"{level_id}:{fragment_id!r}")
    if bad:
        raise RuntimeError("Non-ASCII fragment_id remained after migration:\n" + "\n".join(bad))


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate FR8-A fragment IDs and related content.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate and print migration summary without writing the JSON file.",
    )
    args = parser.parse_args()

    levels = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    if not isinstance(levels, list):
        raise RuntimeError("Expected top-level array in final_report_a_levels.json")

    remap = build_remap(levels)
    id_changes = apply_global_remap(levels, remap)
    content_changes = apply_content_fixes(levels)
    validate_ascii_fragment_ids(levels)

    print("Detected remap entries:")
    for old_id, new_id in sorted(remap.items(), key=lambda x: x[1]):
        old_repr = old_id.encode("unicode_escape").decode("ascii")
        print(f"  '{old_repr}' -> '{new_id}'")
    print(f"ID-related replacements: {id_changes}")
    print(f"Content replacements (feedback/briefing/bucket): {content_changes}")

    if args.check:
        print("Check mode: no file written.")
        return 0

    LEVELS_PATH.write_text(
        json.dumps(levels, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Updated: {LEVELS_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
