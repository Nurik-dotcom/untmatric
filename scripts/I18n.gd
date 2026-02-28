extends Node

signal language_changed(code: String)

var current_language: String = "ru"

# Simple in‑memory dictionary. Keys are string identifiers used in scripts,
# values are dictionaries: { "ru": "Текст", "en": "Text", ... }.
var _catalog: Dictionary = {}


func _ready() -> void:
	# Placeholder: in a full project this is where JSON/CSV translation
	# files would be loaded into `_catalog`.
	pass


func set_language(code: String) -> void:
	code = code.to_lower()
	if code == current_language:
		return
	current_language = code
	language_changed.emit(current_language)


func tr_key(key: String, params: Dictionary = {}) -> String:
	"""
	Main translation helper used across the project.
	`params` usually contains:
	- "default": fallback string
	- any other named placeholders to be substituted: {value}, {count}, ...
	"""
	var default_text: String = str(params.get("default", key))

	var entry: Variant = _catalog.get(key, null)
	var text: String = default_text
	if typeof(entry) == TYPE_DICTIONARY:
		var dict_entry: Dictionary = entry as Dictionary
		var lang_value: Variant = dict_entry.get(current_language, null)
		if lang_value == null:
			lang_value = dict_entry.get("en", null)
		if lang_value != null:
			text = str(lang_value)

	# Simple named placeholder replacement: {name} -> params["name"].
	for p_key in params.keys():
		if p_key == "default":
			continue
		var value_str := str(params[p_key])
		text = text.replace("{" + str(p_key) + "}", value_str)

	return text
