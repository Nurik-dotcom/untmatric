extends RefCounted

const PROFILE_LIST_BASIC := "LIST_BASIC"
const PROFILE_NAV_MENU := "NAV_MENU"
const PROFILE_TABLE_LOG := "TABLE_LOG"
const PROFILE_FORM_SIMPLE := "FORM_SIMPLE"
const PROFILE_ARTICLE_NOTE := "ARTICLE_NOTE"
const PROFILE_FIGURE_MEDIA := "FIGURE_MEDIA"

const STATE_INCOMPLETE := "INCOMPLETE"
const STATE_ORDER_OK := "ORDER_OK"
const STATE_SYNTAX_OK := "SYNTAX_OK"
const STATE_FAIL := "FAIL"

const ERROR_INCOMPLETE := "INCOMPLETE"
const ERROR_UNBALANCED := "UNBALANCED_TAG"
const ERROR_HIERARCHY := "HIERARCHY_VIOLATION"
const ERROR_REQUIRED := "REQUIRED_TAG_MISSING"
const ERROR_ORDER := "ORDER_MISMATCH"
const ERROR_OK := "OK"

static func normalize_expected_sequence(level: Dictionary) -> Array[String]:
	var raw_expected: Array = level.get("expected_sequence", []) as Array
	var normalized: Array[String] = []
	for expected_var in raw_expected:
		var expected_id: String = str(expected_var).strip_edges()
		normalized.append("" if expected_id == "(EMPTY)" else expected_id)
	return normalized

static func evaluate(level: Dictionary, sequence: Array, fragment_by_id: Dictionary) -> Dictionary:
	var expected_sequence: Array[String] = normalize_expected_sequence(level)
	var checks: Dictionary = {
		"container_ok": false,
		"hierarchy_ok": false,
		"required_ok": false,
		"order_ok": false
	}

	if _is_incomplete(sequence, expected_sequence):
		return {
			"state": STATE_INCOMPLETE,
			"error_code": ERROR_INCOMPLETE,
			"incomplete": true,
			"checks": checks,
			"container_ok": false,
			"hierarchy_ok": false,
			"order_ok": false
		}

	var first_index: int = -1
	var last_index: int = -1
	for i in range(sequence.size()):
		var fragment_id: String = str(sequence[i]).strip_edges()
		if fragment_id.is_empty():
			continue
		if first_index < 0:
			first_index = i
		last_index = i

	if first_index < 0 or last_index <= first_index:
		return {
			"state": STATE_FAIL,
			"error_code": ERROR_UNBALANCED,
			"incomplete": false,
			"checks": checks,
			"container_ok": false,
			"hierarchy_ok": false,
			"order_ok": false
		}

	var profile: String = str(level.get("validator_profile", PROFILE_LIST_BASIC)).to_upper()

	var open_id: String = str(sequence[first_index]).strip_edges()
	var close_id: String = str(sequence[last_index]).strip_edges()
	var open_kind: String = _fragment_kind(fragment_by_id, open_id)
	var close_kind: String = _fragment_kind(fragment_by_id, close_id)
	if open_kind != "CONTAINER_OPEN" or close_kind != "CONTAINER_CLOSE":
		return {
			"state": STATE_FAIL,
			"error_code": ERROR_UNBALANCED,
			"incomplete": false,
			"checks": checks,
			"container_ok": false,
			"hierarchy_ok": false,
			"order_ok": false
		}

	var allowed_containers: Dictionary = {}
	for container_var in level.get("allowed_containers", []) as Array:
		allowed_containers[str(container_var).strip_edges().to_lower()] = true

	var open_tag: String = _container_tag(fragment_by_id, open_id)
	var close_tag: String = _container_tag(fragment_by_id, close_id)
	if open_tag.is_empty() or close_tag.is_empty() or open_tag != close_tag or not allowed_containers.has(open_tag):
		return {
			"state": STATE_FAIL,
			"error_code": ERROR_UNBALANCED,
			"incomplete": false,
			"checks": checks,
			"container_ok": false,
			"hierarchy_ok": false,
			"order_ok": false
		}
	checks["container_ok"] = true

	var allowed_inner_kinds: Dictionary = _allowed_inner_kind_map(level, profile)
	var inner_fragment_ids: Array[String] = []
	for i in range(first_index + 1, last_index):
		var inner_id: String = str(sequence[i]).strip_edges()
		if inner_id.is_empty():
			return {
				"state": STATE_FAIL,
				"error_code": ERROR_HIERARCHY,
				"incomplete": false,
				"checks": checks,
				"container_ok": true,
				"hierarchy_ok": false,
				"order_ok": false
			}
		inner_fragment_ids.append(inner_id)
		var inner_kind: String = _fragment_kind(fragment_by_id, inner_id)
		if not allowed_inner_kinds.has(inner_kind):
			return {
				"state": STATE_FAIL,
				"error_code": ERROR_HIERARCHY,
				"incomplete": false,
				"checks": checks,
				"container_ok": true,
				"hierarchy_ok": false,
				"order_ok": false
			}
	checks["hierarchy_ok"] = true

	var required_result: Dictionary = _check_required(level, profile, inner_fragment_ids, fragment_by_id)
	if not bool(required_result.get("ok", false)):
		return {
			"state": STATE_FAIL,
			"error_code": ERROR_REQUIRED,
			"incomplete": false,
			"checks": checks,
			"container_ok": true,
			"hierarchy_ok": true,
			"order_ok": false
		}
	checks["required_ok"] = true

	var order_ok: bool = _sequence_equals_expected(sequence, expected_sequence)
	checks["order_ok"] = order_ok

	if order_ok:
		return {
			"state": STATE_ORDER_OK,
			"error_code": ERROR_OK,
			"incomplete": false,
			"checks": checks,
			"container_ok": true,
			"hierarchy_ok": true,
			"order_ok": true
		}

	return {
		"state": STATE_SYNTAX_OK,
		"error_code": ERROR_ORDER,
		"incomplete": false,
		"checks": checks,
		"container_ok": true,
		"hierarchy_ok": true,
		"order_ok": false
	}

static func resolve_score(level: Dictionary, evaluation: Dictionary) -> Dictionary:
	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	var rules: Array = scoring_model.get("rules", []) as Array
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	var state: String = str(evaluation.get("state", STATE_FAIL))
	var incomplete: bool = bool(evaluation.get("incomplete", false))

	var max_points: int = 0
	for rule_var in rules:
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		var rule_data: Dictionary = rule_var as Dictionary
		max_points = max(max_points, int(rule_data.get("points", 0)))

	var selected_rule: Dictionary = {}
	if incomplete:
		selected_rule = default_rule
	else:
		for rule_var in rules:
			if typeof(rule_var) != TYPE_DICTIONARY:
				continue
			var rule: Dictionary = rule_var as Dictionary
			var min_state: String = str(rule.get("min_state", "ANY")).to_upper()
			if _state_matches(state, min_state):
				selected_rule = rule
				break

	if selected_rule.is_empty():
		selected_rule = {
			"code": "FALLBACK",
			"points": 0,
			"stability_delta": -30,
			"verdict_code": "FAIL"
		}

	var is_fit: bool = false
	var is_correct: bool = false
	if not incomplete:
		if state == STATE_ORDER_OK:
			is_fit = true
			is_correct = true
		elif state == STATE_SYNTAX_OK:
			is_fit = true

	return {
		"rule_code": str(selected_rule.get("code", "SCORING_RULE")),
		"points": int(selected_rule.get("points", 0)),
		"max_points": max_points,
		"stability_delta": int(selected_rule.get("stability_delta", -30)),
		"verdict_code": str(selected_rule.get("verdict_code", "FAIL")),
		"is_fit": is_fit,
		"is_correct": is_correct
	}

static func feedback_text(level: Dictionary, evaluation: Dictionary) -> String:
	if bool(evaluation.get("incomplete", false)):
		return "Не все фрагменты вставлены"

	var error_code: String = str(evaluation.get("error_code", ERROR_ORDER))
	var feedback_rules: Dictionary = level.get("feedback_rules", {}) as Dictionary
	if feedback_rules.has(error_code):
		return str(feedback_rules.get(error_code, ""))
	if feedback_rules.has("OK"):
		return str(feedback_rules.get("OK", ""))
	return "Проверка завершена."

static func _is_incomplete(sequence: Array, expected_sequence: Array[String]) -> bool:
	if sequence.size() != expected_sequence.size():
		return true
	for i in range(sequence.size()):
		var actual_id: String = str(sequence[i]).strip_edges()
		var expected_id: String = expected_sequence[i]
		if actual_id.is_empty() and not expected_id.is_empty():
			return true
	return false

static func _allowed_inner_kind_map(level: Dictionary, profile: String) -> Dictionary:
	var base_kinds: Array[String] = []
	match profile:
		PROFILE_LIST_BASIC:
			base_kinds = ["LI_ITEM"]
		PROFILE_NAV_MENU:
			base_kinds = ["LINK", "LI_ITEM", "TEXT_BLOCK", "NAV_LIST_OPEN", "NAV_LIST_CLOSE"]
		PROFILE_TABLE_LOG:
			base_kinds = ["TR_ROW"]
		PROFILE_FORM_SIMPLE:
			base_kinds = ["FORM_FIELD", "BUTTON", "TEXT_BLOCK"]
		PROFILE_ARTICLE_NOTE:
			base_kinds = ["TEXT_BLOCK"]
		PROFILE_FIGURE_MEDIA:
			base_kinds = ["MEDIA", "TEXT_BLOCK"]
		_:
			base_kinds = ["LI_ITEM"]

	for kind_var in level.get("allowed_inner_kinds", []) as Array:
		var kind_name: String = str(kind_var).strip_edges().to_upper()
		if kind_name.is_empty():
			continue
		if not (kind_name in base_kinds):
			base_kinds.append(kind_name)

	var out: Dictionary = {}
	for kind_name in base_kinds:
		out[kind_name] = true
	return out

static func _check_required(level: Dictionary, profile: String, inner_fragment_ids: Array[String], fragment_by_id: Dictionary) -> Dictionary:
	var required_tags_all: Array[String] = _to_lower_str_array(level.get("required_tags_all", []))
	var required_tags_any: Array[String] = _to_lower_str_array(level.get("required_tags_any", []))
	var required_kinds_all: Array[String] = _to_upper_str_array(level.get("required_kinds_all", []))
	var required_kinds_any: Array[String] = _to_upper_str_array(level.get("required_kinds_any", []))

	if profile == PROFILE_NAV_MENU and required_tags_any.is_empty():
		required_tags_any.append("a")
	if profile == PROFILE_FORM_SIMPLE and required_tags_all.is_empty():
		required_tags_all.append_array(["input", "button"])
	if profile == PROFILE_FIGURE_MEDIA and required_tags_all.is_empty():
		required_tags_all.append_array(["img", "figcaption"])

	var inner_kind_map: Dictionary = {}
	var inner_tag_map: Dictionary = {}
	for fragment_id in inner_fragment_ids:
		var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
		var kind_name: String = str(fragment_data.get("kind", "")).to_upper()
		if not kind_name.is_empty():
			inner_kind_map[kind_name] = true

		var token: String = str(fragment_data.get("token", ""))
		for tag_name in _extract_tag_names(token):
			inner_tag_map[tag_name] = true

	for tag_name in required_tags_all:
		if not inner_tag_map.has(tag_name):
			return {"ok": false}
	if not required_tags_any.is_empty():
		var any_tag_found: bool = false
		for tag_name in required_tags_any:
			if inner_tag_map.has(tag_name):
				any_tag_found = true
				break
		if not any_tag_found:
			return {"ok": false}

	for kind_name in required_kinds_all:
		if not inner_kind_map.has(kind_name):
			return {"ok": false}
	if not required_kinds_any.is_empty():
		var any_kind_found: bool = false
		for kind_name in required_kinds_any:
			if inner_kind_map.has(kind_name):
				any_kind_found = true
				break
		if not any_kind_found:
			return {"ok": false}

	return {"ok": true}

static func _to_lower_str_array(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	var raw_array: Array = raw as Array
	for item in raw_array:
		var value: String = str(item).strip_edges().to_lower()
		if value.is_empty():
			continue
		if not (value in out):
			out.append(value)
	return out

static func _to_upper_str_array(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	var raw_array: Array = raw as Array
	for item in raw_array:
		var value: String = str(item).strip_edges().to_upper()
		if value.is_empty():
			continue
		if not (value in out):
			out.append(value)
	return out

static func _extract_tag_names(token: String) -> Array[String]:
	var out: Array[String] = []
	var lower_token: String = token.to_lower()
	var cursor: int = 0
	while true:
		var start_idx: int = lower_token.find("<", cursor)
		if start_idx < 0:
			break
		var end_idx: int = lower_token.find(">", start_idx + 1)
		if end_idx < 0:
			break

		var segment: String = lower_token.substr(start_idx + 1, end_idx - start_idx - 1).strip_edges()
		if segment.begins_with("/"):
			segment = segment.substr(1).strip_edges()
		if segment.begins_with("!"):
			cursor = end_idx + 1
			continue

		var space_idx: int = segment.find(" ")
		var slash_idx: int = segment.find("/")
		var cut_idx: int = segment.length()
		if space_idx >= 0:
			cut_idx = min(cut_idx, space_idx)
		if slash_idx >= 0:
			cut_idx = min(cut_idx, slash_idx)
		var tag_name: String = segment.substr(0, cut_idx).strip_edges()
		if not tag_name.is_empty() and not (tag_name in out):
			out.append(tag_name)

		cursor = end_idx + 1
	return out

static func _fragment_kind(fragment_by_id: Dictionary, fragment_id: String) -> String:
	if not fragment_by_id.has(fragment_id):
		return ""
	var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
	return str(fragment_data.get("kind", "")).to_upper()

static func _container_tag(fragment_by_id: Dictionary, fragment_id: String) -> String:
	if not fragment_by_id.has(fragment_id):
		return ""
	var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
	var token: String = str(fragment_data.get("token", "")).strip_edges().to_lower()
	var tags: Array[String] = _extract_tag_names(token)
	if tags.is_empty():
		return ""
	return tags[0]

static func _sequence_equals_expected(sequence: Array, expected_sequence: Array[String]) -> bool:
	if sequence.size() != expected_sequence.size():
		return false
	for i in range(sequence.size()):
		if str(sequence[i]).strip_edges() != expected_sequence[i]:
			return false
	return true

static func _state_matches(state: String, min_state: String) -> bool:
	match min_state:
		"ORDER_OK":
			return state == STATE_ORDER_OK
		"SYNTAX_OK":
			return state == STATE_SYNTAX_OK or state == STATE_ORDER_OK
		"FAIL":
			return state == STATE_FAIL
		"ANY":
			return true
		_:
			return false
