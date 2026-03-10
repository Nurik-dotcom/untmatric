extends RefCounted

static func score(level: Dictionary, snapshot: Dictionary, placed_count: int) -> Dictionary:
	var items: Array = level.get("items", []) as Array
	var total_items: int = items.size()
	var scoring_model: Dictionary = level.get("scoring_model", {}) as Dictionary
	var rules: Array = (scoring_model.get("rules", []) as Array).duplicate()
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary

	var correct_count: int = 0
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		var expected_bucket: String = str(item.get("correct_bucket_id", "")).to_upper()
		var actual_bucket: String = str(snapshot.get(item_id, "PILE")).to_upper()
		if expected_bucket == actual_bucket:
			correct_count += 1

	var max_points: int = 0
	for rule_v in rules:
		if typeof(rule_v) != TYPE_DICTIONARY:
			continue
		var rule_data: Dictionary = rule_v as Dictionary
		max_points = max(max_points, int(rule_data.get("points", 0)))

	if placed_count <= 0:
		return {
			"correct_count": correct_count,
			"total_items": total_items,
			"points": int(default_rule.get("points", 0)),
			"max_points": max_points,
			"is_fit": false,
			"is_correct": false,
			"stability_delta": int(default_rule.get("stability_delta", -50)),
			"verdict_code": str(default_rule.get("verdict_code", "EMPTY")),
			"rule_code": str(default_rule.get("code", "EMPTY_CONFIRM"))
		}

	var selected_rule: Dictionary = {}
	var selected_min_correct: int = -9999
	for rule_v in rules:
		if typeof(rule_v) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_v as Dictionary
		var min_correct: int = int(rule.get("min_correct", 0))
		if correct_count >= min_correct and min_correct > selected_min_correct:
			selected_min_correct = min_correct
			selected_rule = rule

	if selected_rule.is_empty():
		selected_rule = {
			"points": 0,
			"stability_delta": -30,
			"verdict_code": "FAIL",
			"code": "FALLBACK"
		}

	var points: int = int(selected_rule.get("points", 0))
	var is_correct: bool = correct_count == total_items and points == max_points
	var is_fit: bool = points > 0

	return {
		"correct_count": correct_count,
		"total_items": total_items,
		"points": points,
		"max_points": max_points,
		"is_fit": is_fit,
		"is_correct": is_correct,
		"stability_delta": int(selected_rule.get("stability_delta", -30)),
		"verdict_code": str(selected_rule.get("verdict_code", "FAIL")),
		"rule_code": str(selected_rule.get("code", "SCORING_RULE"))
	}

static func calculate_matching_table_result(level_data: Dictionary, snapshot: Dictionary) -> Dictionary:
	var tasks: Array = level_data.get("tasks", []) as Array
	var total: int = tasks.size()
	var correct: int = 0
	var details: Array = []

	for task_v in tasks:
		if typeof(task_v) != TYPE_DICTIONARY:
			continue
		var task: Dictionary = task_v as Dictionary
		var task_id: String = str(task.get("task_id", "")).strip_edges()
		if task_id == "":
			continue
		var expected: String = str(task.get("correct_config", "")).strip_edges()
		var given: String = str(snapshot.get(task_id, "")).strip_edges()
		var is_ok: bool = given == expected
		if is_ok:
			correct += 1
		details.append({
			"task_id": task_id,
			"given": given,
			"expected": expected,
			"correct": is_ok,
			"explain_key": str(task.get("explain_key", ""))
		})

	return _build_quiz_verdict(correct, total, details)

static func calculate_quiz_result(level_data: Dictionary, answers: Array) -> Dictionary:
	var rounds: Array = level_data.get("rounds", []) as Array
	var total: int = rounds.size()
	var correct: int = 0
	var details: Array = []

	for i in range(mini(answers.size(), total)):
		if typeof(rounds[i]) != TYPE_DICTIONARY:
			continue
		var round_data: Dictionary = rounds[i] as Dictionary
		var answer: Variant = answers[i]
		var is_right: bool = _check_single_answer(round_data, answer)
		if is_right:
			correct += 1
		details.append({
			"round": i,
			"answer": answer,
			"correct": is_right,
			"explain_key": str(round_data.get("explain_key", ""))
		})

	return _build_quiz_verdict(correct, total, details)

static func calculate_attack_match_result(level_data: Dictionary, answers: Array) -> Dictionary:
	var rounds: Array = level_data.get("rounds", []) as Array
	var total: int = rounds.size()
	var correct: int = 0
	var details: Array = []

	for i in range(mini(answers.size(), total)):
		if typeof(rounds[i]) != TYPE_DICTIONARY:
			continue
		var round_data: Dictionary = rounds[i] as Dictionary
		var answer_data: Dictionary = answers[i] as Dictionary
		var attack_answer: String = str(answer_data.get("attack", "")).strip_edges()
		var defense_answer: String = str(answer_data.get("defense", "")).strip_edges()
		var attack_ok: bool = _check_option_in_list(round_data.get("attack_options", []) as Array, attack_answer)
		var defense_ok: bool = _check_option_in_list(round_data.get("defense_options", []) as Array, defense_answer)
		var round_ok: bool = attack_ok and defense_ok
		if round_ok:
			correct += 1
		details.append({
			"round": i,
			"attack": attack_answer,
			"defense": defense_answer,
			"attack_ok": attack_ok,
			"defense_ok": defense_ok,
			"round_ok": round_ok,
			"explain_key": str(round_data.get("explain_key", ""))
		})

	return _build_quiz_verdict(correct, total, details)

static func calculate_subnet_result(level_data: Dictionary, answers: Array) -> Dictionary:
	var rounds: Array = level_data.get("rounds", []) as Array
	var total: int = rounds.size()
	var correct: int = 0
	var details: Array = []

	for i in range(mini(answers.size(), total)):
		if typeof(rounds[i]) != TYPE_DICTIONARY:
			continue
		var round_data: Dictionary = rounds[i] as Dictionary
		var answer_data: Dictionary = answers[i] as Dictionary
		var questions: Array = round_data.get("questions", []) as Array
		var all_ok: bool = true
		var sub_details: Array = []

		for question_v in questions:
			if typeof(question_v) != TYPE_DICTIONARY:
				continue
			var question: Dictionary = question_v as Dictionary
			var q_type: String = str(question.get("type", "")).strip_edges()
			var expected: String = _normalize_subnet_value(q_type, str(question.get("correct", "")))
			var given_raw: String = str(answer_data.get(q_type, ""))
			var given: String = _normalize_subnet_value(q_type, given_raw)
			var match: bool = given == expected
			if not match:
				all_ok = false
			sub_details.append({
				"type": q_type,
				"given": given,
				"expected": expected,
				"ok": match
			})

		if all_ok:
			correct += 1
		details.append({
			"round": i,
			"round_ok": all_ok,
			"sub": sub_details,
			"explain_key": str(round_data.get("explain_key", ""))
		})

	return _build_quiz_verdict(correct, total, details)

static func calculate_stage_b_result(stage_b_data: Dictionary, snapshot: Dictionary) -> Dictionary:
	if stage_b_data.has("rounds"):
		if str(stage_b_data.get("format", "")).to_upper() == "IP_QUIZ" or str(stage_b_data.get("format", "")).to_upper() == "TOPOLOGY_MATCH":
			return calculate_quiz_result(stage_b_data, snapshot.get("answers", []) as Array)
	return _build_quiz_verdict(0, 0, [])

static func calculate_stage_c_result(stage_c_data: Dictionary, snapshot: Dictionary) -> Dictionary:
	var format: String = str(stage_c_data.get("format", "")).to_upper()
	if format == "ATTACK_MATCH":
		return calculate_attack_match_result(stage_c_data, snapshot.get("answers", []) as Array)
	if format == "SUBNET_CALC":
		return calculate_subnet_result(stage_c_data, snapshot.get("answers", []) as Array)

	var options: Array = stage_c_data.get("options", []) as Array
	var scoring_model: Dictionary = stage_c_data.get("scoring_model", {}) as Dictionary
	var feedback_rules: Dictionary = stage_c_data.get("feedback_rules", {}) as Dictionary

	var option_by_id: Dictionary = {}
	var correct_set: Dictionary = {}
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue
		option_by_id[option_id] = option_data
		if bool(option_data.get("is_correct", false)):
			correct_set[option_id] = true

	var slots_raw: Array = snapshot.get("slots", []) as Array
	var slots: Array[String] = []
	for slot_v in slots_raw:
		slots.append(str(slot_v).strip_edges())

	var selected_raw: Array = snapshot.get("selected", []) as Array
	if selected_raw.is_empty() and not slots.is_empty():
		selected_raw = slots_raw
	var selected_set: Dictionary = {}
	var selected_ids: Array[String] = []
	for selected_v in selected_raw:
		var selected_id: String = str(selected_v).strip_edges()
		if selected_id == "" or selected_set.has(selected_id):
			continue
		selected_set[selected_id] = true
		selected_ids.append(selected_id)
	selected_ids.sort()

	var correct_selected: int = 0
	var wrong_selected: int = 0
	var explain_selected: Array = []
	for selected_id in selected_ids:
		var is_option_correct: bool = correct_set.has(selected_id)
		if is_option_correct:
			correct_selected += 1
		else:
			wrong_selected += 1

		var option_data_v: Variant = option_by_id.get(selected_id, {})
		var option_data: Dictionary = option_data_v as Dictionary
		explain_selected.append({
			"option_id": selected_id,
			"label": str(option_data.get("label", selected_id)),
			"is_correct": is_option_correct,
			"why": str(option_data.get("why", "No explanation"))
		})

	var selected_count: int = selected_ids.size()
	var unique_used_count: int = int(snapshot.get("unique_used_count", selected_count))
	var strategy_flags: Array[String] = []
	if options.size() > 0 and unique_used_count >= options.size():
		strategy_flags.append("TOUCHED_ALL_OPTIONS")
	var max_points: int = int(stage_c_data.get("stage_max_points", 2))
	var verdict_code: String = "FAIL"
	var points: int = 0
	var stability_delta: int = -50

	var rule_2: Dictionary = scoring_model.get("rule_2", {}) as Dictionary
	var rule_1a: Dictionary = scoring_model.get("rule_1a", {}) as Dictionary
	var rule_1b: Dictionary = scoring_model.get("rule_1b", {}) as Dictionary
	var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
	var empty_rule: Dictionary = scoring_model.get("empty_rule", {}) as Dictionary
	var select_all_rule: Dictionary = scoring_model.get("select_all_rule", default_rule) as Dictionary
	var is_select_all_behavior: bool = options.size() > 0 and selected_ids.size() == options.size()

	if selected_count == 0:
		verdict_code = str(empty_rule.get("verdict_code", "EMPTY"))
		points = int(empty_rule.get("points", 0))
		stability_delta = int(empty_rule.get("stability_delta", -50))
	elif is_select_all_behavior:
		verdict_code = str(select_all_rule.get("verdict_code", "SELECT_ALL"))
		points = int(select_all_rule.get("points", 0))
		stability_delta = int(select_all_rule.get("stability_delta", -50))
	elif correct_selected == int(rule_2.get("need_correct", 3)) and wrong_selected <= int(rule_2.get("max_wrong", 0)):
		verdict_code = str(rule_2.get("verdict_code", "PERFECT"))
		points = int(rule_2.get("points", 2))
		stability_delta = int(rule_2.get("stability_delta", 0))
	elif correct_selected == int(rule_1a.get("need_correct", 2)) and wrong_selected <= int(rule_1a.get("max_wrong", 0)):
		verdict_code = str(rule_1a.get("verdict_code", "GOOD"))
		points = int(rule_1a.get("points", 1))
		stability_delta = int(rule_1a.get("stability_delta", 0))
	elif correct_selected == int(rule_1b.get("need_correct", 3)) and wrong_selected <= int(rule_1b.get("max_wrong", 1)):
		verdict_code = str(rule_1b.get("verdict_code", "NOISY"))
		points = int(rule_1b.get("points", 1))
		stability_delta = int(rule_1b.get("stability_delta", -10))
	else:
		verdict_code = str(default_rule.get("verdict_code", "FAIL"))
		points = int(default_rule.get("points", 0))
		stability_delta = int(default_rule.get("stability_delta", -50))

	var required_ids: Array[String] = []
	for option_id_v in correct_set.keys():
		required_ids.append(str(option_id_v))
	required_ids.sort()

	var missing_required: Array[String] = []
	for required_id in required_ids:
		if not selected_set.has(required_id):
			missing_required.append(required_id)

	var feedback: Dictionary = feedback_rules.get(verdict_code, {}) as Dictionary
	var feedback_headline: String = str(feedback.get("headline", verdict_code))
	var feedback_details: Array = (feedback.get("details", []) as Array).duplicate()

	return {
		"points": points,
		"max_points": max_points,
		"is_correct": verdict_code == "PERFECT",
		"is_fit": points > 0,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"slots": slots.duplicate(),
		"selected_ids": selected_ids.duplicate(),
		"correct_selected": correct_selected,
		"wrong_selected": wrong_selected,
		"selected_count": selected_count,
		"unique_used_count": unique_used_count,
		"strategy_flags": strategy_flags.duplicate(),
		"missing_required": missing_required.duplicate(),
		"feedback_headline": feedback_headline,
		"feedback_details": feedback_details,
		"explain_selected": explain_selected
	}

static func _check_single_answer(round_data: Dictionary, answer: Variant) -> bool:
	var answer_str: String = str(answer).strip_edges()
	for option_v in round_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("id", "")).strip_edges() == answer_str:
			return bool(option_data.get("is_correct", false))
	return false

static func _check_option_in_list(options: Array, answer: String) -> bool:
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("id", "")).strip_edges() == answer:
			return bool(option_data.get("is_correct", false))
	return false

static func _normalize_subnet_value(q_type: String, raw: String) -> String:
	var normalized: String = raw.strip_edges()
	if q_type == "network_address" or q_type == "network":
		return _normalize_ip_answer(normalized)
	if q_type == "broadcast":
		return _normalize_ip_answer(normalized)
	if q_type == "host_count" or q_type == "hosts":
		if normalized == "":
			return ""
		if normalized.is_valid_int():
			return str(int(normalized))
	return normalized

static func _normalize_ip_answer(raw: String) -> String:
	var trimmed: String = raw.strip_edges()
	var parts: PackedStringArray = trimmed.split(".")
	if parts.size() != 4:
		return trimmed
	var out: PackedStringArray = PackedStringArray()
	for part in parts:
		var p: String = part.strip_edges()
		if p == "" or not p.is_valid_int():
			return trimmed
		out.append(str(int(p)))
	return ".".join(out)

static func _build_quiz_verdict(correct: int, total: int, details: Array) -> Dictionary:
	var ratio: float = float(correct) / maxf(1.0, float(total))
	var points: int = 2 if ratio >= 0.9 else (1 if ratio >= 0.6 else 0)
	var stability_delta: int = 0 if ratio >= 0.9 else (-10 if ratio >= 0.6 else -30)
	var verdict_code: String = "PERFECT" if ratio >= 0.9 else ("GOOD" if ratio >= 0.6 else "FAIL")
	return {
		"correct_count": correct,
		"total": total,
		"ratio": ratio,
		"points": points,
		"max_points": 2,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"is_correct": ratio >= 0.9,
		"is_fit": points > 0,
		"details": details
	}
