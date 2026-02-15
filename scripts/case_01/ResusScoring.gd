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
