extends RefCounted

const MATCHING_REQUIRED_KEYS: Array[String] = ["buckets", "items", "scoring_model"]
const QUIZ_SINGLE_FORMATS: Array[String] = ["TOPOLOGY_MATCH", "IP_QUIZ"]

static func load_levels(path: String) -> Array:
	return load_stage_levels(path, "A")

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
		for item_v in root as Array:
			if typeof(item_v) != TYPE_DICTIONARY:
				continue
			var candidate: Dictionary = item_v as Dictionary
			stage_levels.append_array(_extract_stage_levels(candidate, stage_id))

	if stage_levels.is_empty():
		push_error("ResusData: Stage %s levels not found" % stage_id)
		return []

	var validated: Array = []
	for level_v in stage_levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = (level_v as Dictionary).duplicate(true)
		if validate_level(level):
			validated.append(level)
	return validated

static func validate_level(level: Dictionary) -> bool:
	var level_id: String = str(level.get("id", "UNKNOWN"))
	for key in ["id", "format"]:
		if not level.has(key):
			push_error("ResusData: missing '%s' in level" % key)
			return false

	var format: String = str(level.get("format", "")).to_upper()
	match format:
		"MATCHING":
			return _validate_matching(level, level_id)
		"MATCHING_CIA":
			return _validate_matching_cia(level, level_id)
		"MATCHING_TABLE":
			return _validate_matching_table(level, level_id)
		"MULTI_CHOICE_SLOTS":
			return _validate_multi_choice_slots(level, level_id)
		"ATTACK_MATCH":
			return _validate_attack_match(level, level_id)
		"SUBNET_CALC":
			return _validate_subnet_calc(level, level_id)
		"TOPOLOGY_MATCH", "IP_QUIZ":
			return _validate_quiz_single_answer(level, level_id)
		_:
			push_error("ResusData: unsupported format '%s' in %s" % [format, level_id])
			return false

static func _validate_matching(level: Dictionary, level_id: String) -> bool:
	if not level.has_all(MATCHING_REQUIRED_KEYS):
		push_error("ResusData: missing required keys in %s" % level_id)
		return false

	var buckets: Array = level.get("buckets", []) as Array
	if buckets.size() < 2 or buckets.size() > 6:
		push_error("ResusData: %s needs 2-6 buckets, got %d" % [level_id, buckets.size()])
		return false

	var bucket_ids: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			push_error("ResusData: bucket entry must be Dictionary in %s" % level_id)
			return false
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper().strip_edges()
		if bucket_id == "" or bucket_ids.has(bucket_id):
			push_error("ResusData: invalid/duplicate bucket_id '%s' in %s" % [bucket_id, level_id])
			return false
		bucket_ids[bucket_id] = true

	var items: Array = level.get("items", []) as Array
	if items.size() < 4 or items.size() > 16:
		push_error("ResusData: %s needs 4-16 items, got %d" % [level_id, items.size()])
		return false

	var item_ids: Dictionary = {}
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			push_error("ResusData: item entry must be Dictionary in %s" % level_id)
			return false
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", "")).strip_edges()
		var label: String = str(item.get("label", "")).strip_edges()
		var label_key: String = str(item.get("label_key", "")).strip_edges()
		var correct_bucket: String = str(item.get("correct_bucket_id", "")).to_upper().strip_edges()
		if item_id == "" or item_ids.has(item_id):
			push_error("ResusData: invalid/duplicate item_id '%s' in %s" % [item_id, level_id])
			return false
		if label == "" and label_key == "":
			push_error("ResusData: item '%s' needs label or label_key in %s" % [item_id, level_id])
			return false
		if not bucket_ids.has(correct_bucket):
			push_error("ResusData: item '%s' refs unknown bucket '%s' in %s" % [item_id, correct_bucket, level_id])
			return false
		item_ids[item_id] = true

	return _validate_scoring_model(level.get("scoring_model", {}) as Dictionary, level_id)

static func _validate_matching_cia(level: Dictionary, level_id: String) -> bool:
	if not _validate_matching(level, level_id):
		return false
	for item_v in level.get("items", []) as Array:
		if typeof(item_v) != TYPE_DICTIONARY:
			return false
		var item: Dictionary = item_v as Dictionary
		var explain_short: String = str(item.get("explain_short", "")).strip_edges()
		var explain_key: String = str(item.get("explain_short_key", "")).strip_edges()
		if explain_short == "" and explain_key == "":
			push_error("ResusData: MATCHING_CIA item '%s' needs explain text or key in %s" % [str(item.get("item_id", "")), level_id])
			return false
	return true

static func _validate_matching_table(level: Dictionary, level_id: String) -> bool:
	if not level.has_all(["configs", "tasks", "scoring_model"]):
		push_error("ResusData: MATCHING_TABLE missing keys in %s" % level_id)
		return false
	var configs: Array = level.get("configs", []) as Array
	var tasks: Array = level.get("tasks", []) as Array
	if configs.size() < 2 or tasks.size() < 2:
		push_error("ResusData: MATCHING_TABLE needs >=2 configs and >=2 tasks in %s" % level_id)
		return false

	var config_ids: Dictionary = {}
	for config_v in configs:
		if typeof(config_v) != TYPE_DICTIONARY:
			return false
		var config: Dictionary = config_v as Dictionary
		var config_id: String = str(config.get("config_id", "")).strip_edges()
		if config_id == "" or config_ids.has(config_id):
			push_error("ResusData: invalid/duplicate config_id '%s' in %s" % [config_id, level_id])
			return false
		config_ids[config_id] = true

	var task_ids: Dictionary = {}
	for task_v in tasks:
		if typeof(task_v) != TYPE_DICTIONARY:
			return false
		var task: Dictionary = task_v as Dictionary
		var task_id: String = str(task.get("task_id", "")).strip_edges()
		var correct_config: String = str(task.get("correct_config", "")).strip_edges()
		if task_id == "" or task_ids.has(task_id):
			push_error("ResusData: invalid/duplicate task_id '%s' in %s" % [task_id, level_id])
			return false
		if not config_ids.has(correct_config):
			push_error("ResusData: task refs unknown config '%s' in %s" % [correct_config, level_id])
			return false
		task_ids[task_id] = true

	return _validate_scoring_model(level.get("scoring_model", {}) as Dictionary, level_id)

static func _validate_multi_choice_slots(level: Dictionary, level_id: String) -> bool:
	if not level.has_all(["options", "max_slots", "scoring_model"]):
		push_error("ResusData: MULTI_CHOICE_SLOTS missing keys in %s" % level_id)
		return false

	var max_slots: int = int(level.get("max_slots", 0))
	if max_slots < 1:
		push_error("ResusData: MULTI_CHOICE_SLOTS max_slots must be > 0 in %s" % level_id)
		return false

	var options: Array = level.get("options", []) as Array
	if options.size() < max_slots:
		push_error("ResusData: MULTI_CHOICE_SLOTS needs >= max_slots options in %s" % level_id)
		return false

	var option_ids: Dictionary = {}
	var correct_count: int = 0
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			return false
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "" or option_ids.has(option_id):
			push_error("ResusData: invalid/duplicate option_id '%s' in %s" % [option_id, level_id])
			return false
		if str(option_data.get("label", "")).strip_edges() == "" and str(option_data.get("label_key", "")).strip_edges() == "":
			push_error("ResusData: option '%s' needs label or label_key in %s" % [option_id, level_id])
			return false
		if bool(option_data.get("is_correct", false)):
			correct_count += 1
		option_ids[option_id] = true

	if correct_count < 1:
		push_error("ResusData: MULTI_CHOICE_SLOTS needs >=1 correct option in %s" % level_id)
		return false

	var feedback_rules: Dictionary = level.get("feedback_rules", {}) as Dictionary
	if feedback_rules.is_empty():
		push_error("ResusData: MULTI_CHOICE_SLOTS feedback_rules missing in %s" % level_id)
		return false

	return true

static func _validate_quiz_single_answer(level: Dictionary, level_id: String) -> bool:
	if not level.has("rounds"):
		push_error("ResusData: quiz format needs 'rounds' in %s" % level_id)
		return false
	var rounds: Array = level.get("rounds", []) as Array
	if rounds.size() < 1:
		return false

	for round_v in rounds:
		if typeof(round_v) != TYPE_DICTIONARY:
			return false
		var round_data: Dictionary = round_v as Dictionary
		if not round_data.has("options"):
			push_error("ResusData: round missing 'options' in %s" % level_id)
			return false
		var options: Array = round_data.get("options", []) as Array
		if options.size() < 2:
			push_error("ResusData: round needs >=2 options in %s" % level_id)
			return false
		var has_correct: bool = false
		for option_v in options:
			if typeof(option_v) != TYPE_DICTIONARY:
				return false
			if bool((option_v as Dictionary).get("is_correct", false)):
				has_correct = true
		if not has_correct:
			push_error("ResusData: round has no correct option in %s" % level_id)
			return false

	return true

static func _validate_attack_match(level: Dictionary, level_id: String) -> bool:
	if not level.has("rounds"):
		push_error("ResusData: ATTACK_MATCH needs rounds in %s" % level_id)
		return false
	var rounds: Array = level.get("rounds", []) as Array
	if rounds.is_empty():
		return false
	for round_v in rounds:
		if typeof(round_v) != TYPE_DICTIONARY:
			return false
		var round_data: Dictionary = round_v as Dictionary
		if not round_data.has("attack_options") or not round_data.has("defense_options"):
			push_error("ResusData: ATTACK_MATCH round missing attack/defense options in %s" % level_id)
			return false
		if not _has_correct_option(round_data.get("attack_options", []) as Array):
			push_error("ResusData: ATTACK_MATCH round missing correct attack option in %s" % level_id)
			return false
		if not _has_correct_option(round_data.get("defense_options", []) as Array):
			push_error("ResusData: ATTACK_MATCH round missing correct defense option in %s" % level_id)
			return false
	return true

static func _validate_subnet_calc(level: Dictionary, level_id: String) -> bool:
	if not level.has("rounds"):
		push_error("ResusData: SUBNET_CALC needs rounds in %s" % level_id)
		return false
	var rounds: Array = level.get("rounds", []) as Array
	if rounds.is_empty():
		return false
	for round_v in rounds:
		if typeof(round_v) != TYPE_DICTIONARY:
			return false
		var round_data: Dictionary = round_v as Dictionary
		if not round_data.has("ip") or not round_data.has("mask") or not round_data.has("questions"):
			push_error("ResusData: SUBNET_CALC round missing ip/mask/questions in %s" % level_id)
			return false
		var questions: Array = round_data.get("questions", []) as Array
		if questions.is_empty():
			push_error("ResusData: SUBNET_CALC round needs questions in %s" % level_id)
			return false
		for question_v in questions:
			if typeof(question_v) != TYPE_DICTIONARY:
				return false
			var question: Dictionary = question_v as Dictionary
			if str(question.get("type", "")).strip_edges() == "" or str(question.get("correct", "")).strip_edges() == "":
				push_error("ResusData: SUBNET_CALC question missing type/correct in %s" % level_id)
				return false
	return true

static func _validate_scoring_model(scoring_model: Dictionary, level_id: String) -> bool:
	if scoring_model.is_empty():
		push_error("ResusData: scoring_model is missing in %s" % level_id)
		return false
	if scoring_model.has("rules"):
		var rules: Array = scoring_model.get("rules", []) as Array
		if rules.is_empty():
			push_error("ResusData: scoring_model.rules is empty in %s" % level_id)
			return false
		if not scoring_model.has("default_rule"):
			push_error("ResusData: scoring_model.default_rule missing in %s" % level_id)
			return false
	return true

static func _has_correct_option(options: Array) -> bool:
	for option_v in options:
		if typeof(option_v) == TYPE_DICTIONARY and bool((option_v as Dictionary).get("is_correct", false)):
			return true
	return false

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
		for level_v in stage_dict.get("levels", []) as Array:
			if typeof(level_v) == TYPE_DICTIONARY:
				out.append((level_v as Dictionary).duplicate(true))
	else:
		out.append(stage_dict.duplicate(true))
	return out
