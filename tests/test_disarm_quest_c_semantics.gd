extends Node

class_name TestDisarmQuestCSemantics

const EVALUATOR_SCRIPT := preload("res://scripts/disarm_c/DisarmCSemanticEvaluator.gd")
const LEVELS_PATH := "res://data/quest_c_levels.json"

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
	test_all_levels_are_semantically_valid_unique()
	test_regressions()
	test_status_valid_unique()
	test_status_invalid_actual_mismatch()
	test_status_invalid_option_result_mismatch()
	test_status_invalid_no_solution()
	test_status_invalid_multiple_solutions()
	test_status_invalid_correct_option_mismatch()
	test_status_invalid_replace_line_syntax()

func test_levels_are_loaded() -> void:
	assert_true(not levels.is_empty(), "quest_c_levels.json is loaded")

func test_all_levels_are_semantically_valid_unique() -> void:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var report: Dictionary = evaluator.semantic_validate_level(level)
		assert_equal(
			str(report.get("status", "")),
			"valid_unique",
			"%s status is valid_unique" % str(level.get("id", "UNKNOWN"))
		)
		var solved_ids: Array = report.get("solved_option_ids", [])
		assert_equal(
			solved_ids.size(),
			1,
			"%s has exactly one semantic winner" % str(level.get("id", "UNKNOWN"))
		)
		if solved_ids.size() == 1:
			assert_equal(
				str(solved_ids[0]),
				str(level.get("bug", {}).get("correct_option_id", "")),
				"%s semantic winner matches declared correct_option_id" % str(level.get("id", "UNKNOWN"))
			)

func test_regressions() -> void:
	_assert_result("C-14", "A", 12)
	_assert_result("C-14", "C", 3)
	_assert_result("C-16", "A", 45)
	_assert_result("C-11", "A", 10)
	_assert_result("C-11", "B", 0)
	_assert_result("C-17", "A", 15)
	_assert_result("C-17", "B", 0)

func test_status_valid_unique() -> void:
	var level: Dictionary = _base_level("T-VALID-UNIQUE")
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "valid_unique", "status valid_unique")

func test_status_invalid_actual_mismatch() -> void:
	var level: Dictionary = _base_level("T-ACTUAL-MISMATCH")
	level["actual_s"] = 999
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_actual_mismatch", "status invalid_actual_mismatch")

func test_status_invalid_option_result_mismatch() -> void:
	var level: Dictionary = _base_level("T-OPTION-MISMATCH")
	var fix_options: Array = level.get("bug", {}).get("fix_options", [])
	for opt_var in fix_options:
		if typeof(opt_var) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_var as Dictionary
		if str(opt.get("option_id", "")) == "B":
			opt["result_s"] = 123
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_option_result_mismatch", "status invalid_option_result_mismatch")

func test_status_invalid_no_solution() -> void:
	var level: Dictionary = _base_level("T-NO-SOLUTION")
	level["expected_s"] = 999
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_no_solution", "status invalid_no_solution")

func test_status_invalid_multiple_solutions() -> void:
	var level: Dictionary = _base_level("T-MULTI")
	var fix_options: Array = level.get("bug", {}).get("fix_options", [])
	for opt_var in fix_options:
		if typeof(opt_var) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_var as Dictionary
		if str(opt.get("option_id", "")) == "B":
			opt["replace_line"] = "    s += 2"
			opt["result_s"] = 4
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_multiple_solutions", "status invalid_multiple_solutions")

func test_status_invalid_correct_option_mismatch() -> void:
	var level: Dictionary = _base_level("T-CORRECT-MISMATCH")
	level["bug"]["correct_option_id"] = "C"
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_correct_option_mismatch", "status invalid_correct_option_mismatch")

func test_status_invalid_replace_line_syntax() -> void:
	var level: Dictionary = _base_level("T-SYNTAX")
	var fix_options: Array = level.get("bug", {}).get("fix_options", [])
	for opt_var in fix_options:
		if typeof(opt_var) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_var as Dictionary
		if str(opt.get("option_id", "")) == "A":
			opt["replace_line"] = "проходить"
	var report: Dictionary = evaluator.semantic_validate_level(level)
	assert_equal(str(report.get("status", "")), "invalid_replace_line_syntax", "status invalid_replace_line_syntax")

func _base_level(level_id: String) -> Dictionary:
	return {
		"id": level_id,
		"bucket": "test",
		"briefing": "test",
		"expected_s": 4,
		"actual_s": 2,
		"code_lines": [
			"s = 0",
			"for i in range(2):",
			"    s += 1"
		],
		"bug": {
			"correct_line_index": 2,
			"fix_options": [
				{"option_id": "A", "replace_line": "    s += 2", "result_s": 4},
				{"option_id": "B", "replace_line": "    s += 3", "result_s": 6},
				{"option_id": "C", "replace_line": "    s += 0", "result_s": 0}
			],
			"correct_option_id": "A"
		},
		"explain_short": ["Reasoning line 1", "Reasoning line 2"]
	}

func _assert_result(level_id: String, option_id: String, expected_result: Variant) -> void:
	var level: Dictionary = _level_by_id(level_id)
	assert_true(not level.is_empty(), "%s exists" % level_id)
	if level.is_empty():
		return
	var eval_result: Dictionary = evaluator.evaluate_patch(level, option_id)
	assert_true(bool(eval_result.get("ok", false)), "%s option %s is evaluable" % [level_id, option_id])
	assert_equal(
		int(round(float(eval_result.get("result_s", 0.0)))),
		int(round(float(expected_result))),
		"%s option %s has expected semantic result" % [level_id, option_id]
	)

func _load_levels() -> Array:
	if not FileAccess.file_exists(LEVELS_PATH):
		assert_true(false, "quest_c_levels.json exists")
		return []
	var f: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if f == null:
		assert_true(false, "quest_c_levels.json opened")
		return []
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		assert_true(false, "quest_c_levels.json parse error: %s" % json.get_error_message())
		return []
	if typeof(json.data) != TYPE_ARRAY:
		assert_true(false, "quest_c_levels.json root is array")
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
	print("[DISARM C SEMANTICS TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
