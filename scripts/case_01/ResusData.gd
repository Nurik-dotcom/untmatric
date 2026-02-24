extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = ["id", "briefing", "format", "buckets", "items", "scoring_model"]
const REQUIRED_LEGACY_KEYS: Array[String] = ["feedback_rules", "system_state_rules"]
const REQUIRED_BUCKET_IDS: Array[String] = ["INPUT", "OUTPUT", "MEMORY"]
const REQUIRED_PARTS: Array[String] = ["gpu", "ram", "cache"]
const CIA_ITEM_TYPES: Array[String] = ["INC", "CTRL"]

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
	var levels: Array = load_stage_levels(path, "B")
	if levels.is_empty():
		return {}
	return (levels[0] as Dictionary).duplicate(true)

static func load_stage_c(path: String) -> Dictionary:
	var levels: Array = load_stage_levels(path, "C")
	if levels.is_empty():
		return {}
	return (levels[0] as Dictionary).duplicate(true)

static func load_stage_levels(path: String, stage_id: String) -> Array:
	var root: Variant = _parse_root(path)
	if typeof(root) == TYPE_NIL:
		return []

	var stage_levels: Array = []
	if typeof(root) == TYPE_DICTIONARY:
		var root_dict: Dictionary = root as Dictionary
		stage_levels.append_array(_extract_stage_levels(root_dict, stage_id))
	elif typeof(root) == TYPE_ARRAY:
		var root_array: Array = root as Array
		for item_v in root_array:
			if typeof(item_v) != TYPE_DICTIONARY:
				continue
			var candidate: Dictionary = item_v as Dictionary
			var extracted: Array = _extract_stage_levels(candidate, stage_id)
			if extracted.is_empty():
				continue
			stage_levels.append_array(extracted)
			if not stage_levels.is_empty():
				break

	if stage_levels.is_empty():
		push_error("ResusData: Stage %s levels not found" % stage_id)
		return []

	var validated_levels: Array = []
	for level_v in stage_levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var stage_level: Dictionary = (level_v as Dictionary).duplicate(true)
		var is_valid: bool = false
		if stage_id == "B":
			is_valid = validate_stage_b(stage_level)
		elif stage_id == "C":
			is_valid = validate_stage_c(stage_level)
		else:
			push_error("ResusData: unsupported stage id '%s'" % stage_id)
			return []
		if is_valid:
			validated_levels.append(stage_level)
	return validated_levels

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

static func _extract_stage_levels(root_dict: Dictionary, stage_id: String) -> Array:
	var out: Array = []
	var stage_dict: Dictionary = _extract_stage(root_dict, stage_id)
	if stage_dict.is_empty():
		return out
	if stage_dict.has("levels"):
		var levels: Array = stage_dict.get("levels", []) as Array
		for level_v in levels:
			if typeof(level_v) == TYPE_DICTIONARY:
				out.append((level_v as Dictionary).duplicate(true))
	else:
		out.append(stage_dict.duplicate(true))
	return out

static func validate_level(level: Dictionary) -> bool:
	for key in REQUIRED_LEVEL_KEYS:
		if not level.has(key):
			push_error("ResusData: missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
			return false

	var level_id: String = str(level.get("id", "UNKNOWN"))
	var format: String = str(level.get("format", "")).to_upper()
	if format == "MATCHING":
		return _validate_matching_legacy(level, level_id)
	if format == "MATCHING_CIA":
		return _validate_matching_cia(level, level_id)

	push_error("ResusData: unsupported format in level %s" % level_id)
	return false

static func _validate_matching_legacy(level: Dictionary, level_id: String) -> bool:
	for key in REQUIRED_LEGACY_KEYS:
		if not level.has(key):
			push_error("ResusData: missing key '%s' in level %s" % [key, level_id])
			return false

	var buckets: Array = level.get("buckets", []) as Array
	if buckets.size() != 3:
		push_error("ResusData: level %s must have exactly 3 buckets" % level_id)
		return false

	var bucket_ids: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			return false
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id == "" or bucket_ids.has(bucket_id):
			push_error("ResusData: duplicate or empty bucket_id in level %s" % level_id)
			return false
		bucket_ids[bucket_id] = true

	for required_bucket in REQUIRED_BUCKET_IDS:
		if not bucket_ids.has(required_bucket):
			push_error("ResusData: bucket %s is required in level %s" % [required_bucket, level_id])
			return false

	var items: Array = level.get("items", []) as Array
	if items.size() != 8:
		push_error("ResusData: level %s must have exactly 8 items" % level_id)
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
			push_error("ResusData: item contract is incomplete in level %s" % level_id)
			return false
		if item_ids.has(item_id):
			push_error("ResusData: duplicate item_id %s in level %s" % [item_id, level_id])
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
	if not _validate_scoring_model(level_id, scoring_model, true):
		return false

	var system_rules: Dictionary = level.get("system_state_rules", {}) as Dictionary
	if not system_rules.has_all(["monitor_on_if", "ram_ok_if", "fast_type_if"]):
		push_error("ResusData: system_state_rules are incomplete in level %s" % level_id)
		return false

	if bool(level.get("diegetic_mode", false)):
		var socket_map: Dictionary = level.get("socket_map", {}) as Dictionary
		if socket_map.is_empty():
			push_error("ResusData: diegetic level %s missing socket_map" % level_id)
			return false
		for required_bucket in REQUIRED_BUCKET_IDS:
			if not socket_map.has(required_bucket):
				push_error("ResusData: socket_map missing bucket %s in level %s" % [required_bucket, level_id])
				return false

	return true

static func _validate_matching_cia(level: Dictionary, level_id: String) -> bool:
	var buckets: Array = level.get("buckets", []) as Array
	if buckets.size() != 3:
		push_error("ResusData: CIA level %s must have exactly 3 buckets" % level_id)
		return false

	var bucket_ids: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			return false
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id == "" or bucket_ids.has(bucket_id):
			push_error("ResusData: CIA level %s has invalid bucket_id" % level_id)
			return false
		bucket_ids[bucket_id] = true

	var items: Array = level.get("items", []) as Array
	if items.size() != 8:
		push_error("ResusData: CIA level %s must have exactly 8 items" % level_id)
		return false

	var item_ids: Dictionary = {}
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", "")).strip_edges()
		var label: String = str(item.get("label", "")).strip_edges()
		var correct_bucket_id: String = str(item.get("correct_bucket_id", "")).to_upper()
		var item_type: String = str(item.get("type", "")).to_upper()
		var explain_short: String = str(item.get("explain_short", "")).strip_edges()
		if item_id == "" or label == "" or correct_bucket_id == "":
			push_error("ResusData: CIA item contract is incomplete in level %s" % level_id)
			return false
		if item_ids.has(item_id):
			push_error("ResusData: CIA level %s has duplicate item_id %s" % [level_id, item_id])
			return false
		if not bucket_ids.has(correct_bucket_id):
			push_error("ResusData: CIA item %s references missing bucket %s" % [item_id, correct_bucket_id])
			return false
		if not CIA_ITEM_TYPES.has(item_type):
			push_error("ResusData: CIA item %s has invalid type '%s'" % [item_id, item_type])
			return false
		if explain_short.length() < 6:
			push_error("ResusData: CIA item %s must have explain_short" % item_id)
			return false
		item_ids[item_id] = true

	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	if not _validate_scoring_model(level_id, scoring_model, false):
		return false

	return true

static func _validate_scoring_model(level_id: String, scoring_model: Dictionary, require_default_code: bool) -> bool:
	var rules: Array = scoring_model.get("rules", []) as Array
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	if rules.is_empty() or default_rule.is_empty():
		push_error("ResusData: scoring_model is incomplete in level %s" % level_id)
		return false

	for rule_v in rules:
		if typeof(rule_v) != TYPE_DICTIONARY:
			return false
		var rule: Dictionary = rule_v as Dictionary
		if not rule.has_all(["min_correct", "points", "stability_delta", "verdict_code"]):
			push_error("ResusData: scoring rule is incomplete in level %s" % level_id)
			return false

	if not default_rule.has_all(["points", "stability_delta", "verdict_code"]):
		push_error("ResusData: default_rule is incomplete in level %s" % level_id)
		return false

	if require_default_code and not default_rule.has("code"):
		push_error("ResusData: default_rule is missing code in level %s" % level_id)
		return false

	if not require_default_code and not default_rule.has("code") and not default_rule.has("when"):
		push_error("ResusData: default_rule must contain 'code' or 'when' in level %s" % level_id)
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

	var tuning_model: Dictionary = stage_b.get("tuning_model", {}) as Dictionary
	if tuning_model.is_empty():
		push_error("ResusData: Stage B tuning_model is missing")
		return false
	for tuning_key in ["cpu", "ram", "gpu"]:
		if not tuning_model.has(tuning_key):
			push_error("ResusData: Stage B tuning_model missing %s" % tuning_key)
			return false

	var classifier_thresholds: Dictionary = stage_b.get("classifier_thresholds", {}) as Dictionary
	if classifier_thresholds.is_empty():
		push_error("ResusData: Stage B classifier_thresholds is missing")
		return false
	if not classifier_thresholds.has_all(["bottleneck_cpu", "bottleneck_ram", "lowpower_perf_max"]):
		push_error("ResusData: Stage B classifier_thresholds incomplete")
		return false

	var benchmark_outputs: Dictionary = stage_b.get("benchmark_outputs", {}) as Dictionary
	for class_code in ["BOTTLENECK", "OPTIMAL", "OVERBUDGET", "LOWPOWER"]:
		if not benchmark_outputs.has(class_code):
			push_error("ResusData: Stage B benchmark output is missing for %s" % class_code)
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

	var modules: Array = stage_c.get("modules", []) as Array
	if modules.size() > 0 and modules.size() != options.size():
		push_error("ResusData: Stage C modules size must match options size")
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

	var visual_sim: Dictionary = stage_c.get("visual_sim", {}) as Dictionary
	if visual_sim.is_empty():
		push_error("ResusData: Stage C visual_sim is missing")
		return false
	for verdict_code in required_feedback_keys:
		if not visual_sim.has(verdict_code):
			push_error("ResusData: Stage C visual_sim missing verdict %s" % verdict_code)
			return false

	return true
