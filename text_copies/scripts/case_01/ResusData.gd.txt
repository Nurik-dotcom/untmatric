extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = ["id", "briefing", "format", "buckets", "items", "scoring_model", "feedback_rules", "system_state_rules"]
const REQUIRED_BUCKET_IDS: Array[String] = ["INPUT", "OUTPUT", "MEMORY"]
const REQUIRED_PARTS: Array[String] = ["gpu", "ram", "cache"]

static func load_levels(path: String) -> Array:
	var root: Variant = _parse_root(path)
	if typeof(root) == TYPE_NIL:
		return []

	var levels: Array = []
	if typeof(root) == TYPE_ARRAY:
		for level_v in root:
			if typeof(level_v) != TYPE_DICTIONARY:
				continue
			var level_data: Dictionary = level_v as Dictionary
			if validate_level(level_data):
				levels.append(level_data)
	elif typeof(root) == TYPE_DICTIONARY:
		var root_dict: Dictionary = root as Dictionary
		if root_dict.has("stages"):
			var stages: Dictionary = root_dict.get("stages", {}) as Dictionary
			var stage_a: Variant = stages.get("A", null)
			if typeof(stage_a) == TYPE_DICTIONARY:
				var stage_a_data: Dictionary = stage_a as Dictionary
				if validate_level(stage_a_data):
					levels.append(stage_a_data)
	return levels

static func load_stage_b(path: String) -> Dictionary:
	return _load_stage(path, "B")

static func load_stage_c(path: String) -> Dictionary:
	return _load_stage(path, "C")

static func _load_stage(path: String, stage_id: String) -> Dictionary:
	var root: Variant = _parse_root(path)
	if typeof(root) == TYPE_NIL:
		return {}

	var stage_data: Dictionary = {}
	if typeof(root) == TYPE_DICTIONARY:
		var root_dict: Dictionary = root as Dictionary
		stage_data = _extract_stage(root_dict, stage_id)
	elif typeof(root) == TYPE_ARRAY:
		var root_array: Array = root as Array
		for item_v in root_array:
			if typeof(item_v) != TYPE_DICTIONARY:
				continue
			var candidate: Dictionary = item_v as Dictionary
			stage_data = _extract_stage(candidate, stage_id)
			if not stage_data.is_empty():
				break

	if stage_data.is_empty():
		push_error("ResusData: Stage %s section not found" % stage_id)
		return {}

	var is_valid: bool = false
	if stage_id == "B":
		is_valid = validate_stage_b(stage_data)
	elif stage_id == "C":
		is_valid = validate_stage_c(stage_data)
	else:
		push_error("ResusData: unsupported stage id '%s'" % stage_id)
		return {}

	if not is_valid:
		return {}
	return stage_data

static func _parse_root(path: String) -> Variant:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ResusData: failed to open %s" % path)
		return null

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		push_error("ResusData: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.data

static func _extract_stage(root_dict: Dictionary, stage_id: String) -> Dictionary:
	if root_dict.has("stages"):
		var stages: Dictionary = root_dict.get("stages", {}) as Dictionary
		var stage_data_v: Variant = stages.get(stage_id, null)
		if typeof(stage_data_v) == TYPE_DICTIONARY:
			return stage_data_v as Dictionary
	if root_dict.has(stage_id) and typeof(root_dict.get(stage_id, null)) == TYPE_DICTIONARY:
		return root_dict.get(stage_id, {}) as Dictionary
	return {}

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

static func validate_stage_b(stage_b: Dictionary) -> bool:
	if str(stage_b.get("format", "")) != "SINGLE_CHOICE_CONTEXT":
		push_error("ResusData: Stage B invalid format")
		return false

	var budget: int = int(stage_b.get("budget", 0))
	if budget <= 0:
		push_error("ResusData: Stage B invalid budget")
		return false

	var options: Array = stage_b.get("options", []) as Array
	if options.size() != 4:
		push_error("ResusData: Stage B must contain exactly 4 options")
		return false

	var option_ids: Dictionary = {}
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			push_error("ResusData: Stage B option must be dictionary")
			return false
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", ""))
		if option_id == "" or option_ids.has(option_id):
			push_error("ResusData: Stage B option_id is missing or duplicated")
			return false
		if not option_data.has_all(["title", "total_price", "parts", "tags"]):
			push_error("ResusData: Stage B option %s is incomplete" % option_id)
			return false
		option_ids[option_id] = true

	var correct_option_id: String = str(stage_b.get("correct_option_id", ""))
	if correct_option_id == "" or not option_ids.has(correct_option_id):
		push_error("ResusData: Stage B correct_option_id is invalid")
		return false

	var feedback_rules: Dictionary = stage_b.get("feedback_rules", {}) as Dictionary
	for option_id_v in option_ids.keys():
		var option_id: String = str(option_id_v)
		if not feedback_rules.has(option_id):
			push_error("ResusData: Stage B feedback rule is missing for %s" % option_id)
			return false

	var scoring_model: Dictionary = stage_b.get("scoring_model", {}) as Dictionary
	if scoring_model.is_empty():
		push_error("ResusData: Stage B scoring_model is missing")
		return false
	if not scoring_model.has_all(["correct_points", "wrong_points", "stability_delta_correct", "stability_delta_wrong", "default_rule"]):
		push_error("ResusData: Stage B scoring_model is incomplete")
		return false
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	if not default_rule.has_all(["when", "points", "stability_delta", "verdict_code"]):
		push_error("ResusData: Stage B default_rule is incomplete")
		return false

	return true

static func validate_stage_c(stage_c: Dictionary) -> bool:
	if str(stage_c.get("format", "")) != "MULTI_CHOICE_SLOTS":
		push_error("ResusData: Stage C invalid format")
		return false

	if int(stage_c.get("max_slots", 0)) != 3:
		push_error("ResusData: Stage C max_slots must be 3")
		return false

	var options: Array = stage_c.get("options", []) as Array
	if options.size() != 5:
		push_error("ResusData: Stage C must contain exactly 5 options")
		return false

	var required_effect_keys: Array[String] = ["collisions", "filtering", "eavesdrop", "media"]
	var option_ids: Dictionary = {}
	var correct_count: int = 0
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			push_error("ResusData: Stage C option must be dictionary")
			return false
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "" or option_ids.has(option_id):
			push_error("ResusData: Stage C option_id is missing or duplicated")
			return false
		if not option_data.has_all(["label", "is_correct", "why"]):
			push_error("ResusData: Stage C option %s is incomplete" % option_id)
			return false
		var effects: Dictionary = option_data.get("effects", {}) as Dictionary
		for effect_key in required_effect_keys:
			if not effects.has(effect_key):
				push_error("ResusData: Stage C option %s missing effect '%s'" % [option_id, effect_key])
				return false
		if bool(option_data.get("is_correct", false)):
			correct_count += 1
		option_ids[option_id] = true

	if correct_count != 3:
		push_error("ResusData: Stage C must have exactly 3 correct options")
		return false

	var scoring_model: Dictionary = stage_c.get("scoring_model", {}) as Dictionary
	if scoring_model.is_empty():
		push_error("ResusData: Stage C scoring_model is missing")
		return false
	if not scoring_model.has_all(["rule_2", "rule_1a", "rule_1b", "default_rule", "empty_rule", "select_all_rule"]):
		push_error("ResusData: Stage C scoring_model is incomplete")
		return false

	var feedback_rules: Dictionary = stage_c.get("feedback_rules", {}) as Dictionary
	var required_feedback_keys: Array[String] = ["PERFECT", "GOOD", "NOISY", "FAIL", "EMPTY", "SELECT_ALL"]
	for feedback_key in required_feedback_keys:
		if not feedback_rules.has(feedback_key):
			push_error("ResusData: Stage C feedback rule '%s' is missing" % feedback_key)
			return false

	return true
