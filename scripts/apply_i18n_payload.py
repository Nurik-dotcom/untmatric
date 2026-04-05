#!/usr/bin/env python3
"""Apply i18n payload from data/i18n/new_keys.json into ru/kk/en dictionaries."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict

LANGS = ("ru", "kk", "en")


def load_json(path: Path) -> Dict[str, str]:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, payload: Dict[str, str]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply i18n payload into ru/kk/en JSON files.")
    parser.add_argument(
        "--payload",
        default="data/i18n/new_keys.json",
        help="Path to payload JSON with key -> {ru, kk, en}.",
    )
    parser.add_argument(
        "--i18n-dir",
        default="data/i18n",
        help="Directory containing ru.json/kk.json/en.json.",
    )
    args = parser.parse_args()

    payload_path = Path(args.payload)
    i18n_dir = Path(args.i18n_dir)

    if not payload_path.exists():
        raise SystemExit(f"Payload file not found: {payload_path}")

    payload = load_json(payload_path)
    if not isinstance(payload, dict):
        raise SystemExit("Payload must be a JSON object")

    dictionaries: Dict[str, Dict[str, str]] = {}
    for lang in LANGS:
        path = i18n_dir / f"{lang}.json"
        if not path.exists():
            raise SystemExit(f"Dictionary not found: {path}")
        dictionaries[lang] = load_json(path)

    stats = {lang: {"added": 0, "updated": 0} for lang in LANGS}

    for key, translations in payload.items():
        if not isinstance(translations, dict):
            raise SystemExit(f"Payload value for {key} must be object with ru/kk/en")
        for lang in LANGS:
            if lang not in translations:
                raise SystemExit(f"Missing language '{lang}' for key: {key}")
            value = str(translations[lang])
            existing = dictionaries[lang].get(key)
            if existing is None:
                stats[lang]["added"] += 1
            elif str(existing) != value:
                stats[lang]["updated"] += 1
            dictionaries[lang][key] = value

    for lang in LANGS:
        save_json(i18n_dir / f"{lang}.json", dictionaries[lang])
        print(
            f"[{lang}] added={stats[lang]['added']} updated={stats[lang]['updated']} total={len(dictionaries[lang])}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
