extends Node

class_name TestRestoreQuestBSemantics

const EVALUATOR_SCRIPT := preload("res://scripts/restore_b/RestoreBSemanticEvaluator.gd")
const LEVELS_PATH := "res://data/quest_b_levels.json"

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

var evaluator = EVALUATOR_SCRIPT.new()
var levels: Array = []

func _ready() -> void:
	levels = _load_levels()
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_levels_are_loaded()
	test_all_levels_have_unique_semantic_solution()
	test_declared_correct_id_matches_semantic_winner()
	test_every_block_has_valid_preview_and_trace()
	test_mandatory_regressions()
	test_status_valid_multiple_solutions()
	test_status_invalid_no_solution()
	test_status_invalid_correct_id_mismatch()
	test_status_invalid_trace_mismatch()
	test_status_invalid_explain_mismatch()
	test_broken_template_is_detected_for_quarantine_path()

func test_levels_are_loaded() -> void:
	assert_true(not levels.is_empty(), "quest_b_levels.json is loaded")

func test_all_levels_have_unique_semantic_solution() -> void:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var previews: Dictionary = evaluator.build_variant_previews(level)
		var report: Dictionary = evaluator.semantic_validate_level(level, previews)
		var solved_ids: Array = report.get("solved_block_ids", [])
		assert_equal(
			solved_ids.size(),
			1,
			"%s has exactly one solved block" % str(level.get("id", "UNKNOWN"))
		)
		assert_equal(
			str(report.get("status", "")),
			"valid_unique_solution",
			"%s semantic status is valid_unique_solution" % str(level.get("id", "UNKNOWN"))
		)

func test_declared_correct_id_matches_semantic_winner() -> void:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var report: Dictionary = evaluator.semantic_validate_level(level)
		var solved_ids: Array = report.get("solved_block_ids", [])
		if solved_ids.size() != 1:
			assert_true(false, "%s has one semantic winner for declared id check" % str(level.get("id", "UNKNOWN")))
			continue
		assert_equal(
			str(level.get("correct_block_id", "")),
			str(solved_ids[0]),
			"%s declared correct_block_id matches semantic winner" % str(level.get("id", "UNKNOWN"))
		)

func test_every_block_has_valid_preview_and_trace() -> void:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		for block_var in level.get("blocks", []) as Array:
			if typeof(block_var) != TYPE_DICTIONARY:
				continue
			var block: Dictionary = block_var as Dictionary
			var preview: Dictionary = evaluator.evaluate_variant(level, block)
			var block_id: String = str(block.get("block_id", "?"))
			assert_true(
				bool(preview.get("semantic_valid", false)),
				"%s block %s is semantically evaluable" % [str(level.get("id", "UNKNOWN")), block_id]
			)
			assert_true(
				typeof(preview.get("trace", [])) == TYPE_ARRAY,
				"%s block %s has trace array" % [str(level.get("id", "UNKNOWN")), block_id]
			)
			var trace: Array = preview.get("trace", [])
			if trace.is_empty():
				continue
			var last_step: Dictionary = trace[trace.size() - 1] if typeof(trace[trace.size() - 1]) == TYPE_DICTIONARY else {}
			assert_equal(
				int(last_step.get("s_after", 0)),
				int(preview.get("computed_s", 0)),
				"%s block %s trace terminal s matches computed_s" % [str(level.get("id", "UNKNOWN")), block_id]
			)

func test_mandatory_regressions() -> void:
	_assert_winner("B-03", ">=")
	_assert_winner("B-07", "2")
	_assert_winner("B-09", "<")
	_assert_winner("B-17", "6")

func test_status_valid_multiple_solutions() -> void:
	var level: Dictionary = _base_level("T-MULTI", 1)
	level["blocks"] = [
		{"block_id": "A", "slot_type": "INT", "insert": "1"},
		{"block_id": "B", "slot_type": "INT", "insert": "1"}
	]
	level["correct_block_id"] = "A"
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "valid_multiple_solutions", "validator returns valid_multiple_solutions")

func test_status_invalid_no_solution() -> void:
	var level: Dictionary = _base_level("T-NONE", 9)
	level["blocks"] = [
		{"block_id": "A", "slot_type": "INT", "insert": "1"},
		{"block_id": "B", "slot_type": "INT", "insert": "2"}
	]
	level["correct_block_id"] = "A"
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_no_solution", "validator returns invalid_no_solution")

func test_status_invalid_correct_id_mismatch() -> void:
	var level: Dictionary = _base_level("T-ID-MISMATCH", 1)
	level["blocks"] = [
		{"block_id": "A", "slot_type": "INT", "insert": "1"},
		{"block_id": "B", "slot_type": "INT", "insert": "2"}
	]
	level["correct_block_id"] = "B"
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_correct_id_mismatch", "validator returns invalid_correct_id_mismatch")

func test_status_invalid_trace_mismatch() -> void:
	var level: Dictionary = _base_level("T-TRACE-MISMATCH", 1)
	level["blocks"] = [
		{"block_id": "A", "slot_type": "INT", "insert": "1"},
		{"block_id": "B", "slot_type": "INT", "insert": "2"}
	]
	level["correct_block_id"] = "A"
	level["trace_correct"] = [
		{"i": 0, "s_before": 0, "s_after": 7}
	]
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_trace_mismatch", "validator returns invalid_trace_mismatch")

func test_status_invalid_explain_mismatch() -> void:
	var level: Dictionary = _base_level("T-EXPLAIN-MISMATCH", 1)
	level["blocks"] = [
		{"block_id": "A", "slot_type": "INT", "insert": "1"},
		{"block_id": "B", "slot_type": "INT", "insert": "2"}
	]
	level["correct_block_id"] = "A"
	level["explain_short"] = ["debug: this line should fail semantic explain check"]
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_explain_mismatch", "validator returns invalid_explain_mismatch")

func test_broken_template_is_detected_for_quarantine_path() -> void:
	var level: Dictionary = {
		"id": "T-BROKEN-TEMPLATE",
		"target_s": 1,
		"code_template": [
			"s = 0",
			"for i in range(3):",
			"s += [SLOT]"
		],
		"slot": {"slot_type": "INT"},
		"blocks": [
			{"block_id": "A", "slot_type": "INT", "insert": "1"},
			{"block_id": "B", "slot_type": "INT", "insert": "2"}
		],
		"correct_block_id": "A",
		"trace_correct": [],
		"explain_short": ["Template is intentionally broken for validator test."]
	}
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_no_solution", "broken template ends in invalid_no_solution")

	var issues: Array = report.get("issues", [])
	var has_variant_error: bool = false
	for issue_var in issues:
		if typeof(issue_var) != TYPE_DICTIONARY:
			continue
		var issue: Dictionary = issue_var as Dictionary
		if str(issue.get("code", "")) == "variant_error":
			has_variant_error = true
			break
	assert_true(has_variant_error, "broken template reports variant_error issue for quarantine")

func _base_level(level_id: String, target_s: int) -> Dictionary:
	return {
		"id": level_id,
		"bucket": "test",
		"briefing": "test",
		"target_s": target_s,
		"code_template": [
			"s = 0",
			"for i in range(1):",
			"    s += [SLOT]"
		],
		"slot": {"slot_type": "INT"},
		"blocks": [],
		"correct_block_id": "",
		"distractor_feedback": {},
		"explain_short": ["Production text."],
		"trace_correct": [
			{"i": 0, "s_before": 0, "s_after": target_s}
		],
		"economy": {"wrong_penalty": 0, "reward": 0, "analyze_cost": 0}
	}

func _assert_winner(level_id: String, expected_block_id: String) -> void:
	var level: Dictionary = _level_by_id(level_id)
	assert_true(not level.is_empty(), "%s exists" % level_id)
	if level.is_empty():
		return
	var report: Dictionary = evaluator.semantic_validate_level(level)
	var solved_ids: Array = report.get("solved_block_ids", [])
	assert_equal(solved_ids.size(), 1, "%s has one solved id in regression check" % level_id)
	if solved_ids.size() == 1:
		assert_equal(str(solved_ids[0]), expected_block_id, "%s winner block id" % level_id)

func _load_levels() -> Array:
	if not FileAccess.file_exists(LEVELS_PATH):
		assert_true(false, "quest_b_levels.json exists")
		return []
	var f: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if f == null:
		assert_true(false, "quest_b_levels.json opened")
		return []
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		assert_true(false, "quest_b_levels.json parse error: %s" % json.get_error_message())
		return []
	if typeof(json.data) != TYPE_ARRAY:
		assert_true(false, "quest_b_levels.json root is array")
		return []
	return json.data as Array

func _level_by_id(level_id: String) -> Dictionary:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		if str(level.get("id", "")) == level_id:
			return level
	return {}

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s (got=%s expected=%s)" % [message, str(actual), str(expected)])

func print_results() -> void:
	print("[RESTORE B SEMANTICS TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
