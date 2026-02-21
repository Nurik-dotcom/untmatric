extends RefCounted

const REQUIRED_LEVEL_KEYS: Array[String] = [
	"id",
	"briefing",
	"format",
	"target_text",
	"html",
	"rules",
	"options",
	"correct_option_id",
	"feedback_rules"
]

const REQUIRED_RULE_KEYS: Array[String] = ["source_id", "kind", "weight", "important", "decl"]
const REQUIRED_DECL_KEYS: Array[String] = ["prop", "value"]
const REQUIRED_OPTION_KEYS: Array[String] = ["id", "label", "value"]

static func load_levels(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("FR8CData: failed to open %s" % path)
		return []

	var json: JSON = JSON.new()
	var parse_code: int = json.parse(file.get_as_text())
	if parse_code != OK:
		push_error("FR8CData: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return []

	if typeof(json.data) != TYPE_ARRAY:
		push_error("FR8CData: root in %s must be an array" % path)
		return []

	var levels: Array = []
	for level_var in json.data:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_data: Dictionary = level_var as Dictionary
		if validate_level(level_data):
			levels.append(level_data)
		else:
			push_error("FR8CData: invalid level contract: %s" % str(level_data.get("id", "UNKNOWN")))
	return levels

static func validate_level(level: Dictionary) -> bool:
	for key in REQUIRED_LEVEL_KEYS:
		if not level.has(key):
			push_error("FR8CData: missing key '%s' in level %s" % [key, str(level.get("id", "UNKNOWN"))])
			return false

	if str(level.get("format", "")) != "CSS_CASCADE":
		push_error("FR8CData: unsupported format in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var html_var: Variant = level.get("html", [])
	if typeof(html_var) != TYPE_ARRAY or (html_var as Array).is_empty():
		push_error("FR8CData: html must be non-empty array in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var rules_var: Variant = level.get("rules", [])
	if typeof(rules_var) != TYPE_ARRAY or (rules_var as Array).is_empty():
		push_error("FR8CData: rules must be non-empty array in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var source_ids: Dictionary = {}
	for i in range((rules_var as Array).size()):
		var rule_var: Variant = (rules_var as Array)[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			push_error("FR8CData: rule entry must be dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var rule: Dictionary = rule_var as Dictionary
		for rule_key in REQUIRED_RULE_KEYS:
			if not rule.has(rule_key):
				push_error("FR8CData: rule missing key '%s' in level %s" % [rule_key, str(level.get("id", "UNKNOWN"))])
				return false
		if _selector_of(rule).is_empty():
			push_error("FR8CData: rule selector missing in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var source_id: String = str(rule.get("source_id", "")).strip_edges()
		if source_id.is_empty() or source_ids.has(source_id):
			push_error("FR8CData: duplicate/empty source_id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		source_ids[source_id] = true
		if not _is_number(rule.get("weight", 0)):
			push_error("FR8CData: rule weight must be int in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if typeof(rule.get("important", false)) != TYPE_BOOL:
			push_error("FR8CData: rule important must be bool in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if rule.has("order") and not _is_number(rule.get("order", 0)):
			push_error("FR8CData: rule order must be int in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var decl_var: Variant = rule.get("decl", {})
		if typeof(decl_var) != TYPE_DICTIONARY:
			push_error("FR8CData: rule decl must be dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var decl: Dictionary = decl_var as Dictionary
		for decl_key in REQUIRED_DECL_KEYS:
			if not decl.has(decl_key):
				push_error("FR8CData: rule decl missing '%s' in level %s" % [decl_key, str(level.get("id", "UNKNOWN"))])
				return false

	if level.has("inline_decl") and level.get("inline_decl") != null:
		var inline_var: Variant = level.get("inline_decl")
		if typeof(inline_var) != TYPE_DICTIONARY:
			push_error("FR8CData: inline_decl must be dictionary/null in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var inline_decl: Dictionary = inline_var as Dictionary
		for inline_key in ["source_id", "kind", "weight", "important", "decl"]:
			if not inline_decl.has(inline_key):
				push_error("FR8CData: inline_decl missing '%s' in level %s" % [inline_key, str(level.get("id", "UNKNOWN"))])
				return false
		if inline_decl.has("order") and not _is_number(inline_decl.get("order", 0)):
			push_error("FR8CData: inline_decl order must be int in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if not _is_number(inline_decl.get("weight", 0)):
			push_error("FR8CData: inline_decl weight must be int in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		if typeof(inline_decl.get("decl", {})) != TYPE_DICTIONARY:
			push_error("FR8CData: inline_decl decl must be dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false

	var options_var: Variant = level.get("options", [])
	if typeof(options_var) != TYPE_ARRAY or (options_var as Array).size() < 2:
		push_error("FR8CData: options must be array(>=2) in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var option_ids: Dictionary = {}
	for option_var in options_var as Array:
		if typeof(option_var) != TYPE_DICTIONARY:
			push_error("FR8CData: option entry must be dictionary in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		var option: Dictionary = option_var as Dictionary
		for option_key in REQUIRED_OPTION_KEYS:
			if not option.has(option_key):
				push_error("FR8CData: option missing key '%s' in level %s" % [option_key, str(level.get("id", "UNKNOWN"))])
				return false
		var option_id: String = str(option.get("id", "")).strip_edges()
		if option_id.is_empty() or option_ids.has(option_id):
			push_error("FR8CData: duplicate/empty option id in level %s" % str(level.get("id", "UNKNOWN")))
			return false
		option_ids[option_id] = true

	var correct_option_id: String = str(level.get("correct_option_id", "")).strip_edges()
	if correct_option_id.is_empty() or not option_ids.has(correct_option_id):
		push_error("FR8CData: correct_option_id invalid in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	var feedback_var: Variant = level.get("feedback_rules", {})
	if typeof(feedback_var) != TYPE_DICTIONARY:
		push_error("FR8CData: feedback_rules must be dictionary in level %s" % str(level.get("id", "UNKNOWN")))
		return false
	var feedback_rules: Dictionary = feedback_var as Dictionary
	if not feedback_rules.has("OK"):
		push_error("FR8CData: feedback_rules missing 'OK' in level %s" % str(level.get("id", "UNKNOWN")))
		return false

	return true

static func _selector_of(rule: Dictionary) -> String:
	var selector: String = str(rule.get("selector", "")).strip_edges()
	if not selector.is_empty():
		return selector
	selector = str(rule.get(".selector", "")).strip_edges()
	return selector

static func _is_number(value: Variant) -> bool:
	var value_type: int = typeof(value)
	return value_type == TYPE_INT or value_type == TYPE_FLOAT
