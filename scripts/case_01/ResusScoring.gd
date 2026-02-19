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

static func calculate_stage_b_result(stage_b_data: Dictionary, snapshot: Dictionary) -> Dictionary:
	var selected_option_id: String = str(snapshot.get("selected_option_id", "")).strip_edges()
	var scoring_model: Dictionary = stage_b_data.get("scoring_model", {}) as Dictionary
	var feedback_rules: Dictionary = stage_b_data.get("feedback_rules", {}) as Dictionary
	var correct_option_id: String = str(stage_b_data.get("correct_option_id", ""))
	var max_points: int = int(stage_b_data.get("stage_max_points", int(scoring_model.get("correct_points", 2))))

	if selected_option_id == "":
		var default_rule: Dictionary = scoring_model.get("default_rule", {}) as Dictionary
		return {
			"points": int(default_rule.get("points", 0)),
			"max_points": max_points,
			"is_correct": false,
			"is_fit": false,
			"stability_delta": int(default_rule.get("stability_delta", -50)),
			"verdict_code": str(default_rule.get("verdict_code", "EMPTY")),
			"error_code": "EMPTY",
			"diagnostic_headline": "Вариант не выбран",
			"diagnostic_details": ["Выберите один из 4 вариантов и подтвердите решение."]
		}

	var is_correct: bool = selected_option_id == correct_option_id
	var points: int = int(scoring_model.get("correct_points", 2)) if is_correct else int(scoring_model.get("wrong_points", 0))
	var stability_delta: int = int(scoring_model.get("stability_delta_correct", 0)) if is_correct else int(scoring_model.get("stability_delta_wrong", -10))
	var verdict_code: String = "SUCCESS" if is_correct else "WRONG"

	var feedback: Dictionary = feedback_rules.get(selected_option_id, {}) as Dictionary
	if feedback.is_empty() and feedback_rules.has(correct_option_id):
		feedback = feedback_rules.get(correct_option_id, {}) as Dictionary

	var error_code: String = str(feedback.get("error_code", "OK" if is_correct else "WRONG"))
	var headline: String = str(feedback.get("headline", "Конфигурация проверена"))
	var details: Array = (feedback.get("details", []) as Array).duplicate()

	return {
		"points": points,
		"max_points": max_points,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"error_code": error_code,
		"diagnostic_headline": headline,
		"diagnostic_details": details
	}

static func calculate_stage_c_result(stage_c_data: Dictionary, snapshot: Dictionary) -> Dictionary:
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
			"why": str(option_data.get("why", "Пояснение отсутствует."))
		})

	var selected_count: int = selected_ids.size()
	var unique_used_count: int = int(snapshot.get("unique_used_count", selected_count))
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
	var is_select_all_behavior: bool = (options.size() > 0 and unique_used_count >= options.size()) or selected_count == options.size()

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
		"missing_required": missing_required.duplicate(),
		"feedback_headline": feedback_headline,
		"feedback_details": feedback_details,
		"explain_selected": explain_selected
	}
