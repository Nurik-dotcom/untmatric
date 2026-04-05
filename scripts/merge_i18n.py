#!/usr/bin/env python3
"""Merge key payload into data/i18n/{ru,kk,en}.json.

Payload format:
{
  "some.key": {"ru": "...", "kk": "...", "en": "..."},
  ...
}
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

LANGS: tuple[str, ...] = ("ru", "kk", "en")


def _load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def _validate_payload(payload: dict[str, Any]) -> None:
    for key, value in payload.items():
        if not isinstance(key, str) or not key.strip():
            raise ValueError("Payload contains an empty or non-string key")
        if not isinstance(value, dict):
            raise ValueError(f"Payload value for '{key}' must be an object")
        for lang in LANGS:
            if lang not in value:
                raise ValueError(f"Payload key '{key}' is missing '{lang}' translation")


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge i18n payload into ru/kk/en dictionaries.")
    parser.add_argument(
        "--payload",
        default="data/i18n/new_keys.json",
        help="Path to payload JSON (default: data/i18n/new_keys.json)",
    )
    parser.add_argument(
        "--i18n-dir",
        default="data/i18n",
        help="Path to directory containing ru.json/kk.json/en.json",
    )
    args = parser.parse_args()

    payload_path = Path(args.payload)
    i18n_dir = Path(args.i18n_dir)
    if not payload_path.exists():
        raise FileNotFoundError(f"Payload not found: {payload_path}")
    if not i18n_dir.exists():
        raise FileNotFoundError(f"i18n directory not found: {i18n_dir}")

    payload = _load_json(payload_path)
    _validate_payload(payload)

    stats: dict[str, dict[str, int]] = {lang: {"added": 0, "updated": 0, "total": 0} for lang in LANGS}

    for lang in LANGS:
        dict_path = i18n_dir / f"{lang}.json"
        if not dict_path.exists():
            raise FileNotFoundError(f"Dictionary not found: {dict_path}")

        dictionary = _load_json(dict_path)
        for key, translations in payload.items():
            new_val = str(translations[lang])
            old_val = dictionary.get(key)
            if old_val is None:
                stats[lang]["added"] += 1
            elif str(old_val) != new_val:
                stats[lang]["updated"] += 1
            dictionary[key] = new_val

        sorted_dictionary = {k: dictionary[k] for k in sorted(dictionary.keys())}
        dict_path.write_text(
            json.dumps(sorted_dictionary, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        stats[lang]["total"] = len(sorted_dictionary)

    for lang in LANGS:
        print(
            f"{lang}.json: added {stats[lang]['added']}, "
            f"updated {stats[lang]['updated']}, total {stats[lang]['total']}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
