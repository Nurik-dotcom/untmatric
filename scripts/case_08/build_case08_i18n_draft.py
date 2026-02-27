#!/usr/bin/env python3
"""Build and verify Case 08 i18n draft dictionaries for en/kk."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Set, Tuple

ROOT = Path(__file__).resolve().parents[2]
I18N_DIR = ROOT / "data" / "i18n"

RU_PATH = I18N_DIR / "ru.json"
EN_PATH = I18N_DIR / "en.json"
KK_PATH = I18N_DIR / "kk.json"
MAP_EN_PATH = I18N_DIR / "case08_value_map_en.json"
MAP_KK_PATH = I18N_DIR / "case08_value_map_kk.json"

LEVEL_PREFIXES: Tuple[str, ...] = (
    "case08.fr8a.FR8-A-",
    "case08.fr8b.FR8-B-",
    "case08.fr8c.FR8-C-",
)

SOURCE_CASE08_FILES: Tuple[Path, ...] = (
    ROOT / "scripts" / "case_08" / "fr8_final_report_a.gd",
    ROOT / "scripts" / "case_08" / "fr8_final_report_b.gd",
    ROOT / "scripts" / "case_08" / "fr8_final_report_c.gd",
    ROOT / "scripts" / "case_08" / "fr8_scoring.gd",
    ROOT / "scripts" / "case_08" / "fr8b_scoring.gd",
    ROOT / "scripts" / "case_08" / "fr8c_scoring.gd",
)

PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z0-9_]+\}")
TAG_RE = re.compile(r"<[^>]+>")
MOJIBAKE_RE = re.compile(r"[ЂЃѓ„†‡€‰ЉЊЌЋЏ™љњќћџ]")
TR_KEY_RE = re.compile(r'_tr\("([^"]+)"')

ALLOW_EQUAL_VALUES: Set[str] = {"MVP", "QA", "Name", "Submit", "OK"}


def _load_json(path: Path) -> Dict[str, str]:
    return json.loads(path.read_text(encoding="utf-8"))


def _save_json(path: Path, payload: Dict[str, str]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _is_level_key(key: str) -> bool:
    return any(key.startswith(prefix) for prefix in LEVEL_PREFIXES)


def _collect_level_keys(ru: Dict[str, str]) -> List[str]:
    return sorted(k for k in ru.keys() if _is_level_key(k))


def _collect_case08_tr_keys() -> Set[str]:
    out: Set[str] = set()
    for path in SOURCE_CASE08_FILES:
        text = path.read_text(encoding="utf-8")
        for key in TR_KEY_RE.findall(text):
            if key.startswith("case08."):
                out.add(key)
    return out


def _is_critical_key(key: str) -> bool:
    if key.endswith(".briefing"):
        return True
    if ".feedback." in key:
        return True
    if ".dep." in key and key.endswith(".message"):
        return True
    if ".option." in key and key.endswith(".label"):
        return True
    return False


def _is_technical_value(value: str) -> bool:
    stripped = value.strip()
    if stripped in ALLOW_EQUAL_VALUES:
        return True
    if stripped.startswith("<") and stripped.endswith(">"):
        inner = TAG_RE.sub("", stripped).strip()
        return inner == ""
    if re.fullmatch(r"[#.\w:\-]+", stripped):
        return True
    return False


def _is_ascii_phrase(value: str) -> bool:
    stripped = value.strip()
    if not stripped:
        return True
    return re.fullmatch(r"[ -~]+", stripped) is not None


def _extract_placeholders(value: str) -> List[str]:
    return sorted(PLACEHOLDER_RE.findall(value))


def _extract_tags(value: str) -> List[str]:
    return sorted(TAG_RE.findall(value))


def _verify_placeholder_and_tag_parity(
    key: str,
    source: str,
    translated: str,
    lang: str,
    issues: List[str],
) -> None:
    if _extract_placeholders(source) != _extract_placeholders(translated):
        issues.append(f"{lang}: placeholder mismatch for {key}")
    if _extract_tags(source) != _extract_tags(translated):
        issues.append(f"{lang}: tag mismatch for {key}")


def _verify_no_mojibake(
    lang: str,
    dictionary: Dict[str, str],
    issues: List[str],
) -> None:
    for key, value in dictionary.items():
        if not key.startswith("case08."):
            continue
        if isinstance(value, str) and MOJIBAKE_RE.search(value):
            issues.append(f"{lang}: mojibake signature in {key}")


def _write_from_maps() -> None:
    ru = _load_json(RU_PATH)
    en = _load_json(EN_PATH)
    kk = _load_json(KK_PATH)
    map_en = _load_json(MAP_EN_PATH)
    map_kk = _load_json(MAP_KK_PATH)

    level_keys = _collect_level_keys(ru)

    missing_en_values = sorted({ru[k] for k in level_keys if ru[k] not in map_en})
    missing_kk_values = sorted({ru[k] for k in level_keys if ru[k] not in map_kk})
    if missing_en_values or missing_kk_values:
        if missing_en_values:
            print(f"Missing EN mappings: {len(missing_en_values)}", file=sys.stderr)
        if missing_kk_values:
            print(f"Missing KK mappings: {len(missing_kk_values)}", file=sys.stderr)
        raise SystemExit(1)

    for key in level_keys:
        source = ru[key]
        en[key] = map_en[source]
        kk[key] = map_kk[source]

    _save_json(EN_PATH, en)
    _save_json(KK_PATH, kk)


def _verify() -> List[str]:
    issues: List[str] = []
    ru = _load_json(RU_PATH)
    en = _load_json(EN_PATH)
    kk = _load_json(KK_PATH)
    map_en = _load_json(MAP_EN_PATH)
    map_kk = _load_json(MAP_KK_PATH)

    level_keys = _collect_level_keys(ru)
    unique_values = {ru[k] for k in level_keys}

    for value in unique_values:
        if value not in map_en:
            issues.append("map_en: missing source value")
        if value not in map_kk:
            issues.append("map_kk: missing source value")

    for lang, dictionary in (("en", en), ("kk", kk)):
        missing_level = [k for k in level_keys if k not in dictionary]
        if missing_level:
            issues.append(f"{lang}: missing level keys ({len(missing_level)})")

        for key in level_keys:
            source = ru[key]
            translated = str(dictionary.get(key, ""))
            _verify_placeholder_and_tag_parity(key, source, translated, lang, issues)

            if _is_critical_key(key) and translated == source:
                if _is_technical_value(source):
                    continue
                if lang == "en" and _is_ascii_phrase(source):
                    continue
                issues.append(f"{lang}: critical key is not translated: {key}")

    required_case08_non_level = sorted(_collect_case08_tr_keys())
    missing_non_level_en = [k for k in required_case08_non_level if k not in en]
    if missing_non_level_en:
        issues.append(f"en: missing non-level case08 keys: {len(missing_non_level_en)}")

    _verify_no_mojibake("ru", ru, issues)
    _verify_no_mojibake("en", en, issues)
    _verify_no_mojibake("kk", kk, issues)

    return issues


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build and verify Case 08 i18n draft")
    parser.add_argument("--write", action="store_true", help="Write en/kk level keys from value maps")
    parser.add_argument("--verify", action="store_true", help="Run verification checks")
    args = parser.parse_args(list(argv) if argv is not None else None)

    run_verify = args.verify or not args.write
    if args.write:
        _write_from_maps()

    if run_verify:
        issues = _verify()
        if issues:
            print("Case08 i18n verification failed:", file=sys.stderr)
            for item in issues:
                print(f" - {item}", file=sys.stderr)
            return 1
        print("Case08 i18n verification passed.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
