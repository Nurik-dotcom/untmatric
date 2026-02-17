extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = [
	"id",
	"briefing",
	"format",
	"cards",
	"dependencies",
	"expected_order",
	"feedback_rules",
	"scoring_model",
	"anti_cheat"
]

const REQUIRED_CARD_KEYS: Array[String] = ["stage_id", "title", "hint"]
const REQUIRED_DEP_KEYS: Array[String] = ["a", "b", "code"]
const REQUIRED_FEEDBACK_KEYS: Array[String] = ["LOGIC_GAP", "CAUSALITY_LOOP", "ORDER_MISMATCH", "OK"]
const REQUIRED_SCORE_KEYS: Array[String] = ["points", "stability_delta", "verdict_code"]
const ALLOWED_DEP_CODES: Array[String] = ["LOGIC_GAP", "CAUSALITY_LOOP"]

static func load_levels(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("FR8BData: failed to open %s" % path)
		return []

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		push_error("FR8BData: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	if typeof(json.data) != TYPE_ARRAY:
		push_error("FR8BData: root in %s must be an array" % path)
		return []

	var levels: Array = []
	for level_var in json.data:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_data: Dictionary = level_var as Dictionary
		if validate_level(level_data):
			levels.append(level_data)
		else:
			push_error("FR8BData: invalid level contract: %s" % str(level_data.get("id", "UNKNOWN")))

	return levels

static func validate_level(level: Dictionary) -> bool:
	for key in REQUIRED_LEVEL_KEYS:
		if not level.has(key):
			push_error("FR8BData: missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
			return false

	if str(level.get("format", "")) != "TIMELINE_SORT":
		push_error("FR8BData: unsupported format in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var cards_var: Variant = level.get("cards", [])
	if typeof(cards_var) != TYPE_ARRAY:
		push_error("FR8BData: cards must be an array in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var cards: Array = cards_var as Array
	if cards.size() < 4 or cards.size() > 7:
		push_error("FR8BData: level %s must have 4-7 cards" % str(level.get("id", "UNKNOWN")))
		return false

	var stage_ids: Dictionary = {}
	for card_var in cards:
		if typeof(card_var) != TYPE_DICTIONARY:
			push_error("FR8BData: card entry must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var card: Dictionary = card_var as Dictionary
		for card_key in REQUIRED_CARD_KEYS:
			if not card.has(card_key):
				push_error("FR8BData: card missing key '%s' in level %s" % [card_key, str(level.get("id", "UNKNOWN"))])
				return false
		var stage_id: String = str(card.get("stage_id", "")).strip_edges()
		if stage_id.is_empty() or stage_ids.has(stage_id):
			push_error("FR8BData: duplicate/empty stage_id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		stage_ids[stage_id] = true

	var expected_var: Variant = level.get("expected_order", [])
	if typeof(expected_var) != TYPE_ARRAY:
		push_error("FR8BData: expected_order must be an array in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var expected_order: Array = expected_var as Array
	if expected_order.size() != cards.size():
		push_error("FR8BData: expected_order length mismatch in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var expected_seen: Dictionary = {}
	for stage_var in expected_order:
		var stage_id: String = str(stage_var).strip_edges()
		if stage_id.is_empty() or expected_seen.has(stage_id):
			push_error("FR8BData: duplicate/empty expected_order value in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if not stage_ids.has(stage_id):
			push_error("FR8BData: unknown stage_id '%s' in expected_order (%s)" % [stage_id, str(level.get("id", "UNKNOWN"))])
			return false
		expected_seen[stage_id] = true

	var deps_var: Variant = level.get("dependencies", [])
	if typeof(deps_var) != TYPE_ARRAY:
		push_error("FR8BData: dependencies must be an array in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var deps: Array = deps_var as Array
	if deps.is_empty():
		push_error("FR8BData: dependencies cannot be empty in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for dep_var in deps:
		if typeof(dep_var) != TYPE_DICTIONARY:
			push_error("FR8BData: dependency must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var dep: Dictionary = dep_var as Dictionary
		for dep_key in REQUIRED_DEP_KEYS:
			if not dep.has(dep_key):
				push_error("FR8BData: dependency missing key '%s' in level %s" % [dep_key, str(level.get("id", "UNKNOWN"))])
				return false
		var a: String = str(dep.get("a", "")).strip_edges()
		var b: String = str(dep.get("b", "")).strip_edges()
		if a.is_empty() or b.is_empty() or a == b:
			push_error("FR8BData: invalid dependency endpoints in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if not stage_ids.has(a) or not stage_ids.has(b):
			push_error("FR8BData: dependency uses unknown stage_id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var dep_code: String = str(dep.get("code", "")).to_upper()
		if not (dep_code in ALLOWED_DEP_CODES):
			push_error("FR8BData: unsupported dependency code '%s' in level %s" % [dep_code, str(level.get("id", "UNKNOWN"))])
			return false

	var feedback_var: Variant = level.get("feedback_rules", {})
	if typeof(feedback_var) != TYPE_DICTIONARY:
		push_error("FR8BData: feedback_rules must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var feedback_rules: Dictionary = feedback_var as Dictionary
	for feedback_key in REQUIRED_FEEDBACK_KEYS:
		if not feedback_rules.has(feedback_key):
			push_error("FR8BData: feedback rule '%s' missing in level %s" % [feedback_key, str(level.get("id", "UNKNOWN"))])
			return false

	var scoring_var: Variant = level.get("scoring_model", {})
	if typeof(scoring_var) != TYPE_DICTIONARY:
		push_error("FR8BData: scoring_model must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var scoring_model: Dictionary = scoring_var as Dictionary
	if not scoring_model.has("perfect") or not scoring_model.has("fail"):
		push_error("FR8BData: scoring_model must contain perfect/fail in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	for score_key in ["perfect", "fail"]:
		var score_rule_var: Variant = scoring_model.get(score_key, {})
		if typeof(score_rule_var) != TYPE_DICTIONARY:
			push_error("FR8BData: scoring_model.%s must be dictionary in level %s" % [score_key, str(level.get("id", "UNKNOWN"))])
			return false
		var score_rule: Dictionary = score_rule_var as Dictionary
		for rule_key in REQUIRED_SCORE_KEYS:
			if not score_rule.has(rule_key):
				push_error("FR8BData: scoring_model.%s missing key '%s' in level %s" % [score_key, rule_key, str(level.get("id", "UNKNOWN"))])
				return false

	var anti_cheat_var: Variant = level.get("anti_cheat", {})
	if typeof(anti_cheat_var) != TYPE_DICTIONARY:
		push_error("FR8BData: anti_cheat must be a dictionary in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var anti_cheat: Dictionary = anti_cheat_var as Dictionary
	if anti_cheat.has("shuffle_cards") and typeof(anti_cheat.get("shuffle_cards", false)) != TYPE_BOOL:
		push_error("FR8BData: anti_cheat.shuffle_cards must be bool in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	return true