extends Node

signal language_changed(code: String)

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "i18n"
const SETTINGS_KEY := "language"
const DEFAULT_LANGUAGE := "ru"

const LANGUAGE_FILES := {
	"ru": "res://data/i18n/ru.json",
	"kk": "res://data/i18n/kk.json",
	"en": "res://data/i18n/en.json"
}

const FALLBACK_CHAINS := {
	"ru": ["ru"],
	"kk": ["kk", "ru"],
	"en": ["en", "ru"]
}

var _current_language: String = DEFAULT_LANGUAGE
var _dictionaries: Dictionary = {}

func _ready() -> void:
	_load_all_dictionaries()
	_current_language = _normalize_language(_load_saved_language())
	_save_language(_current_language)

func get_language() -> String:
	return _current_language

func set_language(code: String) -> void:
	var normalized: String = _normalize_language(code)
	if normalized == _current_language:
		return
	_current_language = normalized
	_save_language(_current_language)
	language_changed.emit(_current_language)

func tr_key(key: String, params: Dictionary = {}) -> String:
	var translation_key: String = key.strip_edges()
	if translation_key.is_empty():
		return str(params.get("default", ""))

	var resolved: String = ""
	for lang_code in _fallback_chain_for(_current_language):
		var dict: Dictionary = _dictionaries.get(lang_code, {}) as Dictionary
		if dict.has(translation_key):
			resolved = str(dict.get(translation_key, ""))
			break

	if resolved.is_empty():
		var default_text: String = str(params.get("default", ""))
		resolved = default_text if not default_text.is_empty() else translation_key

	return _format_params(resolved, params)

func get_text(key: String, params: Dictionary = {}) -> String:
	return tr_key(key, params)

func resolve_field(entry: Dictionary, field: String, params: Dictionary = {}) -> String:
	if typeof(entry) != TYPE_DICTIONARY:
		return ""

	var key_field: String = "%s_key" % field
	var key_value: String = str(entry.get(key_field, "")).strip_edges()
	var has_key: bool = not key_value.is_empty()
	var has_legacy: bool = entry.has(field)

	var merged_params: Dictionary = params.duplicate(true)
	if has_legacy and not merged_params.has("default"):
		merged_params["default"] = str(entry.get(field, ""))

	if has_key:
		return tr_key(key_value, merged_params)
	if has_legacy:
		return _format_params(str(entry.get(field, "")), merged_params)
	return str(merged_params.get("default", ""))

func _load_all_dictionaries() -> void:
	_dictionaries.clear()
	for lang_code in LANGUAGE_FILES.keys():
		var path: String = str(LANGUAGE_FILES.get(lang_code, ""))
		_dictionaries[lang_code] = _load_dictionary(path)

func _load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary

func _load_saved_language() -> String:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	if err != OK:
		return DEFAULT_LANGUAGE
	return str(config.get_value(SETTINGS_SECTION, SETTINGS_KEY, DEFAULT_LANGUAGE))

func _save_language(code: String) -> void:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		return
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, code)
	config.save(SETTINGS_PATH)

func _normalize_language(code: String) -> String:
	var normalized: String = code.strip_edges().to_lower()
	if normalized.is_empty():
		return DEFAULT_LANGUAGE
	if not LANGUAGE_FILES.has(normalized):
		return DEFAULT_LANGUAGE
	return normalized

func _fallback_chain_for(code: String) -> Array[String]:
	var normalized: String = _normalize_language(code)
	var raw_chain: Array = FALLBACK_CHAINS.get(normalized, ["ru"]) as Array
	var out: Array[String] = []
	for lang_var in raw_chain:
		var lang_code: String = str(lang_var).strip_edges().to_lower()
		if lang_code.is_empty():
			continue
		if not out.has(lang_code):
			out.append(lang_code)
	if not out.has("ru"):
		out.append("ru")
	return out

func _format_params(template: String, params: Dictionary) -> String:
	var out: String = template
	for key_var in params.keys():
		var key_name: String = str(key_var)
		if key_name == "default":
			continue
		out = out.replace("{%s}" % key_name, str(params.get(key_var, "")))
	return out
