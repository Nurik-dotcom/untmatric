extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = ["id", "briefing", "format", "buckets", "items", "scoring_model", "feedback_rules", "system_state_rules"]
const REQUIRED_BUCKET_IDS: Array[String] = ["INPUT", "OUTPUT", "MEMORY"]
const REQUIRED_PARTS: Array[String] = ["gpu", "ram", "cache"]

static func load_levels(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ResusData: failed to open %s" % path)
		return []

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		push_error("ResusData: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	if typeof(json.data) != TYPE_ARRAY:
		push_error("ResusData: root must be an array")
		return []

	var levels: Array = []
	for level_v in json.data:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		if validate_level(level):
			levels.append(level)
	return levels

static func validate_level(level: Dictionary) -> bool:
	for key in REQUIRED_LEVEL_KEYS:
		if not level.has(key):
			push_error("ResusData: missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
			return false

	if str(level.get("format", "")) != "MATCHING":
		push_error("ResusData: unsupported format in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var buckets: Array = level.get("buckets", []) as Array
	if buckets.size() != 3:
		push_error("ResusData: level %s must have exactly 3 buckets" % str(level.get("id", "UNKNOWN")))
		return false

	var bucket_ids: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			return false
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id == "" or bucket_ids.has(bucket_id):
			push_error("ResusData: duplicate or empty bucket_id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		bucket_ids[bucket_id] = true

	for required_bucket in REQUIRED_BUCKET_IDS:
		if not bucket_ids.has(required_bucket):
			push_error("ResusData: bucket %s is required in level %s" % [required_bucket, str(level.get("id", "UNKNOWN"))])
			return false

	var items: Array = level.get("items", []) as Array
	if items.size() != 8:
		push_error("ResusData: level %s must have exactly 8 items" % str(level.get("id", "UNKNOWN")))
		return false

	var item_ids: Dictionary = {}
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		var label: String = str(item.get("label", ""))
		var correct_bucket_id: String = str(item.get("correct_bucket_id", "")).to_upper()
		if item_id == "" or label == "" or correct_bucket_id == "":
			push_error("ResusData: item contract is incomplete in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if item_ids.has(item_id):
			push_error("ResusData: duplicate item_id %s in level %s" % [item_id, str(level.get("id", "UNKNOWN"))])
			return false
		if not bucket_ids.has(correct_bucket_id):
			push_error("ResusData: item %s references missing bucket %s" % [item_id, correct_bucket_id])
			return false
		item_ids[item_id] = true

	for mandatory_part in REQUIRED_PARTS:
		if not item_ids.has(mandatory_part):
			push_error("ResusData: mandatory part %s is missing" % mandatory_part)
			return false

	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	var rules: Array = scoring_model.get("rules", []) as Array
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	if rules.is_empty() or default_rule.is_empty():
		push_error("ResusData: scoring_model is incomplete in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for rule_v in rules:
		if typeof(rule_v) != TYPE_DICTIONARY:
			return false
		var rule: Dictionary = rule_v as Dictionary
		if not rule.has_all(["min_correct", "points", "stability_delta", "verdict_code"]):
			push_error("ResusData: scoring rule is incomplete in level %s" % str(level.get("id", "UNKNOWN")))
			return false

	if not default_rule.has_all(["code", "points", "stability_delta", "verdict_code"]):
		push_error("ResusData: default_rule is incomplete in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var system_rules: Dictionary = level.get("system_state_rules", {}) as Dictionary
	if not system_rules.has_all(["monitor_on_if", "ram_ok_if", "fast_type_if"]):
		push_error("ResusData: system_state_rules are incomplete in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	return true
