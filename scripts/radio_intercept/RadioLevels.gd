extends RefCounted

const LEVELS_PATH := "res://data/radio_levels.json"

static var _cache: Dictionary = {}

static func load_levels() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	if not FileAccess.file_exists(LEVELS_PATH):
		push_warning("RadioLevels: missing file %s" % LEVELS_PATH)
		_cache = {}
		return _cache

	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_warning("RadioLevels: failed to open %s" % LEVELS_PATH)
		_cache = {}
		return _cache

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cache = parsed
	else:
		push_warning("RadioLevels: invalid JSON shape in %s" % LEVELS_PATH)
		_cache = {}
	return _cache

static func get_stage(stage_id: String) -> Dictionary:
	var levels: Dictionary = load_levels()
	var block: Variant = levels.get(stage_id, {})
	if block is Dictionary:
		return block
	return {}

static func get_pool(stage_id: String, key: String, default_value: Array = []) -> Array:
	var block: Dictionary = get_stage(stage_id)
	var value: Variant = block.get(key, default_value)
	if value is Array:
		return value
	return default_value

static func get_value(stage_id: String, key: String, default_value: Variant = null) -> Variant:
	var block: Dictionary = get_stage(stage_id)
	return block.get(key, default_value)
