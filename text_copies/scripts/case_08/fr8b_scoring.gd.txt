extends RefCounted

const STATE_ORDER_OK := "ORDER_OK"
const STATE_FAIL := "FAIL"

const ERROR_LOGIC_GAP := "LOGIC_GAP"
const ERROR_CAUSALITY_LOOP := "CAUSALITY_LOOP"
const ERROR_ORDER_MISMATCH := "ORDER_MISMATCH"
const ERROR_OK := "OK"

static func evaluate(level: Dictionary, current_order: Array[String]) -> Dictionary:
	var normalized_order: Array[String] = []
	for stage_id in current_order:
		normalized_order.append(str(stage_id).strip_edges())

	var expected_order: Array[String] = _normalized_array(level.get("expected_order", []))
	var positions: Dictionary = {}
	for i in range(normalized_order.size()):
		var stage_id: String = normalized_order[i]
		if stage_id.is_empty():
			continue
		positions[stage_id] = i

	var violations: Array = []
	for dep_var in level.get("dependencies", []) as Array:
		if typeof(dep_var) != TYPE_DICTIONARY:
			continue
		var dep: Dictionary = dep_var as Dictionary
		var a: String = str(dep.get("a", "")).strip_edges()
		var b: String = str(dep.get("b", "")).strip_edges()
		if a.is_empty() or b.is_empty():
			continue

		var broken: bool = false
		if not positions.has(a) or not positions.has(b):
			broken = true
		elif int(positions[a]) >= int(positions[b]):
			broken = true

		if broken:
			violations.append({
				"a": a,
				"b": b,
				"code": str(dep.get("code", ERROR_LOGIC_GAP)).to_upper(),
				"message": str(dep.get("message", ""))
			})

	if not violations.is_empty():
		var top_error: String = _pick_top_error(violations)
		var top_violation: Dictionary = _pick_top_violation(violations, top_error)
		return {
			"state": STATE_FAIL,
			"error_code": top_error,
			"violations": violations,
			"top_violation": top_violation,
			"order_ok": false
		}

	var order_ok: bool = _arrays_equal(normalized_order, expected_order)
	if order_ok:
		return {
			"state": STATE_ORDER_OK,
			"error_code": ERROR_OK,
			"violations": [],
			"top_violation": {},
			"order_ok": true
		}

	return {
		"state": STATE_FAIL,
		"error_code": ERROR_ORDER_MISMATCH,
		"violations": [],
		"top_violation": {},
		"order_ok": false
	}

static func resolve_score(level: Dictionary, evaluation: Dictionary) -> Dictionary:
	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	var perfect_rule: Dictionary = scoring_model.get("perfect", {
		"points": 2,
		"stability_delta": 0,
		"verdict_code": "PERFECT"
	}) as Dictionary
	var fail_rule: Dictionary = scoring_model.get("fail", {
		"points": 0,
		"stability_delta": -25,
		"verdict_code": "FAIL"
	}) as Dictionary

	var is_order_ok: bool = str(evaluation.get("state", STATE_FAIL)) == STATE_ORDER_OK
	var selected: Dictionary = perfect_rule if is_order_ok else fail_rule
	var max_points: int = max(int(perfect_rule.get("points", 2)), int(fail_rule.get("points", 0)))

	return {
		"points": int(selected.get("points", 0)),
		"max_points": max_points,
		"stability_delta": int(selected.get("stability_delta", -25)),
		"verdict_code": str(selected.get("verdict_code", "FAIL")),
		"is_fit": is_order_ok,
		"is_correct": is_order_ok
	}

static func feedback_text(level: Dictionary, evaluation: Dictionary) -> String:
	var feedback_rules: Dictionary = level.get("feedback_rules", {}) as Dictionary
	var error_code: String = str(evaluation.get("error_code", ERROR_ORDER_MISMATCH))
	var top_violation: Dictionary = evaluation.get("top_violation", {}) as Dictionary

	if not top_violation.is_empty() and (error_code == ERROR_CAUSALITY_LOOP or error_code == ERROR_LOGIC_GAP):
		var msg: String = str(top_violation.get("message", "")).strip_edges()
		if not msg.is_empty():
			return msg

	if feedback_rules.has(error_code):
		return str(feedback_rules.get(error_code, ""))
	if feedback_rules.has(ERROR_OK):
		return str(feedback_rules.get(ERROR_OK, ""))
	return "Проверка завершена."

static func _pick_top_error(violations: Array) -> String:
	for violation_var in violations:
		if typeof(violation_var) != TYPE_DICTIONARY:
			continue
		var violation: Dictionary = violation_var as Dictionary
		if str(violation.get("code", "")).to_upper() == ERROR_CAUSALITY_LOOP:
			return ERROR_CAUSALITY_LOOP

	for violation_var in violations:
		if typeof(violation_var) != TYPE_DICTIONARY:
			continue
		var violation: Dictionary = violation_var as Dictionary
		if str(violation.get("code", "")).to_upper() == ERROR_LOGIC_GAP:
			return ERROR_LOGIC_GAP

	return ERROR_ORDER_MISMATCH

static func _pick_top_violation(violations: Array, error_code: String) -> Dictionary:
	for violation_var in violations:
		if typeof(violation_var) != TYPE_DICTIONARY:
			continue
		var violation: Dictionary = violation_var as Dictionary
		if str(violation.get("code", "")).to_upper() == error_code:
			return violation
	if violations.is_empty():
		return {}
	if typeof(violations[0]) != TYPE_DICTIONARY:
		return {}
	return violations[0] as Dictionary

static func _normalized_array(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw as Array:
		out.append(str(item).strip_edges())
	return out

static func _arrays_equal(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true
