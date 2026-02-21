extends RefCounted

const ERROR_EMPTY_CHOICE := "EMPTY_CHOICE"
const ERROR_SPECIFICITY := "SPECIFICITY_ERROR"
const ERROR_IMPORTANT := "IMPORTANT_MISSED"
const ERROR_ORDER_TIE := "ORDER_TIE"
const ERROR_INLINE := "INLINE_OVERRIDE"
const ERROR_OK := "OK"

const VERDICT_PERFECT := "PERFECT"
const VERDICT_FAIL := "FAIL"

static func evaluate(level: Dictionary, selected_option_id: String) -> Dictionary:
	var candidates: Array = _build_candidates(level)
	var winner: Dictionary = _pick_winner(candidates)
	var correct_option_id: String = str(level.get("correct_option_id", "")).strip_edges()
	var selected_option: Dictionary = _option_by_id(level, selected_option_id)
	var selected_value: String = str(selected_option.get("value", "")).strip_edges().to_lower()
	var selected_candidate: Dictionary = _top_candidate_for_color(candidates, selected_value)

	var error_code: String = ERROR_OK
	var is_correct: bool = false
	var is_fit: bool = not selected_option.is_empty()

	if not is_fit:
		error_code = ERROR_EMPTY_CHOICE
	else:
		is_correct = selected_option_id.strip_edges() == correct_option_id
		if not is_correct:
			error_code = _infer_error_code(selected_candidate, winner)

	var points: int = 2 if is_correct else 0
	var stability_delta: int = 0 if is_correct else -25
	var verdict_code: String = VERDICT_PERFECT if is_correct else VERDICT_FAIL

	return {
		"error_code": ERROR_OK if is_correct else error_code,
		"is_correct": is_correct,
		"is_fit": is_fit,
		"points": points,
		"max_points": 2,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"correct_option_id": correct_option_id,
		"winner_source_id": str(winner.get("source_id", "")),
		"winner": {
			"important": bool(winner.get("important", false)),
			"weight": int(winner.get("weight", 0)),
			"order": int(winner.get("order", 0)),
			"color": str(winner.get("color", ""))
		},
		"attack_strength": _strength_of(selected_candidate),
		"defense_strength": _strength_of(winner)
	}

static func feedback_text(level: Dictionary, evaluation: Dictionary) -> String:
	var error_code: String = str(evaluation.get("error_code", ERROR_SPECIFICITY))
	var feedback_rules: Dictionary = level.get("feedback_rules", {}) as Dictionary
	if error_code == ERROR_EMPTY_CHOICE:
		return "\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0432\u0430\u0440\u0438\u0430\u043d\u0442 \u0446\u0432\u0435\u0442\u0430."
	if feedback_rules.has(error_code):
		return str(feedback_rules.get(error_code, ""))
	if error_code == ERROR_IMPORTANT:
		return "!important \u043f\u0435\u0440\u0435\u0431\u0438\u0432\u0430\u0435\u0442 \u043e\u0431\u044b\u0447\u043d\u044b\u0435 \u043f\u0440\u0430\u0432\u0438\u043b\u0430."
	if error_code == ERROR_INLINE:
		return "Встроенный стиль перекрывает правила из CSS."
	if error_code == ERROR_ORDER_TIE:
		return "\u041f\u0440\u0438 \u0440\u0430\u0432\u043d\u043e\u0439 \u0441\u0438\u043b\u0435 \u043f\u043e\u0431\u0435\u0436\u0434\u0430\u0435\u0442 \u043f\u0440\u0430\u0432\u0438\u043b\u043e, \u043a\u043e\u0442\u043e\u0440\u043e\u0435 \u0438\u0434\u0451\u0442 \u043f\u043e\u0437\u0436\u0435."
	if error_code == ERROR_SPECIFICITY:
		return "\u041f\u043e\u0431\u0435\u0434\u0438\u043b \u0431\u043e\u043b\u0435\u0435 \u0441\u043f\u0435\u0446\u0438\u0444\u0438\u0447\u043d\u044b\u0439 \u0441\u0435\u043b\u0435\u043a\u0442\u043e\u0440."
	if feedback_rules.has(ERROR_OK):
		return str(feedback_rules.get(ERROR_OK, ""))
	return "\u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u043a\u0430\u0441\u043a\u0430\u0434 \u0438 \u043f\u043e\u043f\u0440\u043e\u0431\u0443\u0439\u0442\u0435 \u0441\u043d\u043e\u0432\u0430."

static func inspect_source(level: Dictionary, source_id: String) -> Dictionary:
	var sid: String = source_id.strip_edges()
	if sid.to_lower() == "inline":
		var inline_var: Variant = level.get("inline_decl", null)
		if inline_var == null or typeof(inline_var) != TYPE_DICTIONARY:
			return {}
		var inline_decl: Dictionary = inline_var as Dictionary
		var decl: Dictionary = inline_decl.get("decl", {}) as Dictionary
		return {
			"source_id": str(inline_decl.get("source_id", "INLINE")),
			"selector": "встроенный стиль",
			"kind": str(inline_decl.get("kind", "inline")),
			"weight": int(inline_decl.get("weight", 1000)),
			"important": bool(inline_decl.get("important", false)),
			"order": int(inline_decl.get("order", 10000)),
			"color": str(decl.get("value", ""))
		}

	for i in range((level.get("rules", []) as Array).size()):
		var rule_var: Variant = (level.get("rules", []) as Array)[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_var as Dictionary
		if str(rule.get("source_id", "")).strip_edges() != sid:
			continue
		var decl: Dictionary = rule.get("decl", {}) as Dictionary
		return {
			"source_id": sid,
			"selector": _selector_of(rule),
			"kind": str(rule.get("kind", "")),
			"weight": int(rule.get("weight", 0)),
			"important": bool(rule.get("important", false)),
			"order": int(rule.get("order", i + 1)),
			"color": str(decl.get("value", ""))
		}
	return {}

static func preview_attack_strength(level: Dictionary, selected_option_id: String) -> int:
	var selected_option: Dictionary = _option_by_id(level, selected_option_id)
	if selected_option.is_empty():
		return 0
	var selected_value: String = str(selected_option.get("value", "")).strip_edges().to_lower()
	var selected_candidate: Dictionary = _top_candidate_for_color(_build_candidates(level), selected_value)
	return _strength_of(selected_candidate)

static func _build_candidates(level: Dictionary) -> Array:
	var out: Array = []
	var rules: Array = level.get("rules", []) as Array
	for i in range(rules.size()):
		var rule_var: Variant = rules[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_var as Dictionary
		var decl: Dictionary = rule.get("decl", {}) as Dictionary
		out.append({
			"source_id": str(rule.get("source_id", "")).strip_edges(),
			"selector": _selector_of(rule),
			"kind": str(rule.get("kind", "")),
			"weight": int(rule.get("weight", 0)),
			"important": bool(rule.get("important", false)),
			"order": int(rule.get("order", i + 1)),
			"color": str(decl.get("value", "")).strip_edges().to_lower()
		})

	var inline_var: Variant = level.get("inline_decl", null)
	if inline_var != null and typeof(inline_var) == TYPE_DICTIONARY:
		var inline_decl: Dictionary = inline_var as Dictionary
		var inline_decl_data: Dictionary = inline_decl.get("decl", {}) as Dictionary
		out.append({
			"source_id": str(inline_decl.get("source_id", "INLINE")).strip_edges(),
			"selector": "встроенный стиль",
			"kind": str(inline_decl.get("kind", "inline")),
			"weight": int(inline_decl.get("weight", 1000)),
			"important": bool(inline_decl.get("important", false)),
			"order": int(inline_decl.get("order", 10000)),
			"color": str(inline_decl_data.get("value", "")).strip_edges().to_lower()
		})

	return out

static func _pick_winner(candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return {
			"source_id": "",
			"selector": "",
			"kind": "",
			"weight": 0,
			"important": false,
			"order": 0,
			"color": ""
		}

	var winner: Dictionary = candidates[0] as Dictionary
	for i in range(1, candidates.size()):
		if typeof(candidates[i]) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidates[i] as Dictionary
		if _is_stronger(candidate, winner):
			winner = candidate
	return winner

static func _top_candidate_for_color(candidates: Array, color_value: String) -> Dictionary:
	var color: String = color_value.strip_edges().to_lower()
	if color.is_empty():
		return {}
	var picked: Dictionary = {}
	for candidate_var in candidates:
		if typeof(candidate_var) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_var as Dictionary
		if str(candidate.get("color", "")).to_lower() != color:
			continue
		if picked.is_empty() or _is_stronger(candidate, picked):
			picked = candidate
	return picked

static func _is_stronger(a: Dictionary, b: Dictionary) -> bool:
	var a_imp: bool = bool(a.get("important", false))
	var b_imp: bool = bool(b.get("important", false))
	if a_imp != b_imp:
		return a_imp and not b_imp

	var a_weight: int = int(a.get("weight", 0))
	var b_weight: int = int(b.get("weight", 0))
	if a_weight != b_weight:
		return a_weight > b_weight

	var a_order: int = int(a.get("order", 0))
	var b_order: int = int(b.get("order", 0))
	if a_order != b_order:
		return a_order > b_order
	return false

static func _infer_error_code(selected_candidate: Dictionary, winner: Dictionary) -> String:
	if str(winner.get("source_id", "")).to_upper() == "INLINE":
		if selected_candidate.is_empty() or str(selected_candidate.get("source_id", "")).to_upper() != "INLINE":
			return ERROR_INLINE

	if bool(winner.get("important", false)):
		if selected_candidate.is_empty() or not bool(selected_candidate.get("important", false)):
			return ERROR_IMPORTANT

	if not selected_candidate.is_empty():
		var same_important: bool = bool(selected_candidate.get("important", false)) == bool(winner.get("important", false))
		var same_weight: bool = int(selected_candidate.get("weight", 0)) == int(winner.get("weight", 0))
		if same_important and same_weight and int(selected_candidate.get("order", 0)) != int(winner.get("order", 0)):
			return ERROR_ORDER_TIE
		if int(selected_candidate.get("weight", 0)) != int(winner.get("weight", 0)):
			return ERROR_SPECIFICITY

	return ERROR_SPECIFICITY

static func _option_by_id(level: Dictionary, option_id: String) -> Dictionary:
	var oid: String = option_id.strip_edges()
	if oid.is_empty():
		return {}
	for option_var in level.get("options", []) as Array:
		if typeof(option_var) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_var as Dictionary
		if str(option.get("id", "")).strip_edges() == oid:
			return option
	return {}

static func _selector_of(rule: Dictionary) -> String:
	var selector: String = str(rule.get("selector", "")).strip_edges()
	if not selector.is_empty():
		return selector
	return str(rule.get(".selector", "")).strip_edges()

static func _strength_of(candidate: Dictionary) -> int:
	if candidate.is_empty():
		return 0
	var important_bonus: int = 10000 if bool(candidate.get("important", false)) else 0
	return important_bonus + int(candidate.get("weight", 0))
