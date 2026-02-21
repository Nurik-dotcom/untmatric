extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = [
	"id",
	"briefing",
	"format",
	"validator_profile",
	"allowed_containers",
	"slots",
	"fragments",
	"expected_sequence",
	"scoring_model",
	"feedback_rules"
]

const REQUIRED_FRAGMENT_KEYS: Array[String] = ["fragment_id", "label", "kind", "token"]
const REQUIRED_RULE_KEYS: Array[String] = ["code", "min_state", "points", "stability_delta", "verdict_code"]
const REQUIRED_DEFAULT_RULE_KEYS: Array[String] = ["code", "points", "stability_delta", "verdict_code"]
const REQUIRED_FEEDBACK_KEYS: Array[String] = ["UNBALANCED_TAG", "HIERARCHY_VIOLATION", "ORDER_MISMATCH", "OK"]
const SUPPORTED_PROFILES: Array[String] = ["LIST_BASIC", "NAV_MENU", "TABLE_LOG", "FORM_SIMPLE", "ARTICLE_NOTE", "FIGURE_MEDIA"]

static func load_levels(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("FR8Data: failed to open %s" % path)
		return []

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		push_error("FR8Data: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	if typeof(json.data) != TYPE_ARRAY:
		push_error("FR8Data: root in %s must be an array" % path)
		return []

	var levels: Array = []
	for level_var in json.data:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_data: Dictionary = level_var as Dictionary
		if validate_level(level_data):
			levels.append(level_data)
		else:
			push_error("FR8Data: invalid level contract: %s" % str(level_data.get("id", "UNKNOWN")))

	return levels

static func validate_level(level: Dictionary) -> bool:
	for key in REQUIRED_LEVEL_KEYS:
		if not level.has(key):
			push_error("FR8Data: missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
			return false

	if str(level.get("format", "")) != "TAG_ORDERING":
		push_error("FR8Data: unsupported format in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var profile: String = str(level.get("validator_profile", "")).strip_edges().to_upper()
	if not (profile in SUPPORTED_PROFILES):
		push_error("FR8Data: unsupported validator_profile '%s' in level %s" % [profile, str(level.get("id", "UNKNOWN"))])
		return false

	var slots: Array = level.get("slots", []) as Array
	if slots.size() < 5 or slots.size() > 7:
		push_error("FR8Data: level %s must have 5-7 slots" % str(level.get("id", "UNKNOWN")))
		return false

	var slot_ids: Dictionary = {}
	for slot_var in slots:
		var slot_id: String = str(slot_var).strip_edges()
		if slot_id.is_empty() or slot_ids.has(slot_id):
			push_error("FR8Data: duplicate/empty slot id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		slot_ids[slot_id] = true

	var allowed_containers: Array = level.get("allowed_containers", []) as Array
	if allowed_containers.is_empty():
		push_error("FR8Data: level %s has no allowed_containers" % str(level.get("id", "UNKNOWN")))
		return false

	var allowed_map: Dictionary = {}
	for container_var in allowed_containers:
		var container_name: String = str(container_var).strip_edges().to_lower()
		if container_name.is_empty():
			continue
		allowed_map[container_name] = true
	if allowed_map.is_empty():
		push_error("FR8Data: level %s allowed_containers are invalid" % str(level.get("id", "UNKNOWN")))
		return false

	if level.has("allowed_inner_kinds") and typeof(level.get("allowed_inner_kinds")) != TYPE_ARRAY:
		push_error("FR8Data: allowed_inner_kinds must be array in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for req_key in ["required_tags_all", "required_tags_any", "required_kinds_all", "required_kinds_any"]:
		if level.has(req_key) and typeof(level.get(req_key)) != TYPE_ARRAY:
			push_error("FR8Data: %s must be array in level %s" % [req_key, str(level.get("id", "UNKNOWN"))])
			return false

	var fragments: Array = level.get("fragments", []) as Array
	if fragments.is_empty():
		push_error("FR8Data: level %s has empty fragments list" % str(level.get("id", "UNKNOWN")))
		return false

	var fragment_ids: Dictionary = {}
	for fragment_var in fragments:
		if typeof(fragment_var) != TYPE_DICTIONARY:
			push_error("FR8Data: fragment entry must be a dictionary")
			return false
		var fragment: Dictionary = fragment_var as Dictionary
		for key in REQUIRED_FRAGMENT_KEYS:
			if not fragment.has(key):
				push_error("FR8Data: fragment is missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
				return false
		var fragment_id: String = str(fragment.get("fragment_id", "")).strip_edges()
		if fragment_id.is_empty() or fragment_ids.has(fragment_id):
			push_error("FR8Data: duplicate/empty fragment_id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		fragment_ids[fragment_id] = true

	var expected_sequence: Array = level.get("expected_sequence", []) as Array
	if expected_sequence.size() != slots.size():
		push_error("FR8Data: expected_sequence length mismatch in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for expected_var in expected_sequence:
		var expected_id: String = str(expected_var).strip_edges()
		if expected_id == "(EMPTY)":
			continue
		if expected_id.is_empty():
			push_error("FR8Data: expected_sequence cannot contain empty ids (use '(EMPTY)') in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if not fragment_ids.has(expected_id):
			push_error("FR8Data: expected fragment '%s' missing in level %s" % [expected_id, str(level.get("id", "UNKNOWN"))])
			return false

	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	var rules: Array = scoring_model.get("rules", []) as Array
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	if rules.is_empty() or default_rule.is_empty():
		push_error("FR8Data: scoring_model is incomplete in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for rule_var in rules:
		if typeof(rule_var) != TYPE_DICTIONARY:
			push_error("FR8Data: scoring rule must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var rule: Dictionary = rule_var as Dictionary
		for rule_key in REQUIRED_RULE_KEYS:
			if not rule.has(rule_key):
				push_error("FR8Data: scoring rule key '%s' is missing in level %s" % [rule_key, str(level.get("id", "UNKNOWN"))])
				return false
		var min_state: String = str(rule.get("min_state", "")).to_upper()
		if not (min_state in ["ORDER_OK", "SYNTAX_OK", "FAIL", "ANY"]):
			push_error("FR8Data: unsupported min_state '%s' in level %s" % [min_state, str(level.get("id", "UNKNOWN"))])
			return false

	for default_key in REQUIRED_DEFAULT_RULE_KEYS:
		if not default_rule.has(default_key):
			push_error("FR8Data: default_rule key '%s' is missing in level %s" % [default_key, str(level.get("id", "UNKNOWN"))])
			return false

	var feedback_rules: Dictionary = level.get("feedback_rules", {}) as Dictionary
	for feedback_key in REQUIRED_FEEDBACK_KEYS:
		if not feedback_rules.has(feedback_key):
			push_error("FR8Data: feedback rule '%s' missing in level %s" % [feedback_key, str(level.get("id", "UNKNOWN"))])
			return false

	return true