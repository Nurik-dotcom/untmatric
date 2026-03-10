extends Node

class_name TestCase08DataContract

const FR8Data := preload("res://scripts/case_08/fr8_data.gd")
const FR8Scoring := preload("res://scripts/case_08/fr8_scoring.gd")
const FR8CData := preload("res://scripts/case_08/fr8c_data.gd")
const FR8CScoring := preload("res://scripts/case_08/fr8c_scoring.gd")
const LEVELS_PATH_A := "res://data/final_report_a_levels.json"
const LEVELS_PATH_C := "res://data/final_report_c_levels.json"
const LEGACY_EMPTY_MARKER := "(\u0420\u045f\u0420\u0408\u0420\u040e\u0420\u045e\u0420\u045b\u0420\u2122)"

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

func _ready() -> void:
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_load_levels_contract_is_valid()
	test_a_fragment_ids_are_ascii()
	test_expected_sequence_contains_only_known_ids_or_empty_markers()
	test_normalize_expected_sequence_supports_all_empty_markers()
	test_a_localized_content_fixes()
	test_a_bucket_distribution()
	test_c_data_contract_is_valid()
	test_c_rules_have_ascii_selector_kind_prop()
	test_c_scoring_contains_winning_source_id_alias()

func test_load_levels_contract_is_valid() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH_A)
	assert_true(not levels.is_empty(), "FR8Data.load_levels() returns valid levels")

func test_a_fragment_ids_are_ascii() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH_A)
	assert_true(not levels.is_empty(), "A levels are available for ASCII fragment_id check")
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var level_id: String = str(level.get("id", "UNKNOWN"))
		for fragment_var in level.get("fragments", []) as Array:
			if typeof(fragment_var) != TYPE_DICTIONARY:
				continue
			var fragment: Dictionary = fragment_var as Dictionary
			var fragment_id: String = str(fragment.get("fragment_id", ""))
			assert_true(_is_ascii(fragment_id), "fragment_id is ASCII in %s: %s" % [level_id, fragment_id])

func test_expected_sequence_contains_only_known_ids_or_empty_markers() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH_A)
	assert_true(not levels.is_empty(), "Levels are available for expected_sequence checks")

	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var fragment_ids: Dictionary = {}
		for fragment_var in level.get("fragments", []) as Array:
			if typeof(fragment_var) != TYPE_DICTIONARY:
				continue
			var fragment: Dictionary = fragment_var as Dictionary
			var fragment_id: String = str(fragment.get("fragment_id", "")).strip_edges()
			if not fragment_id.is_empty():
				fragment_ids[fragment_id] = true

		var normalized_expected: Array[String] = FR8Scoring.normalize_expected_sequence(level)
		var expected_sequence: Array = level.get("expected_sequence", []) as Array
		assert_equal(normalized_expected.size(), expected_sequence.size(), "normalized expected_sequence has same size for %s" % str(level.get("id", "UNKNOWN")))
		for expected_id in normalized_expected:
			if expected_id.is_empty():
				continue
			assert_true(fragment_ids.has(expected_id), "expected fragment id '%s' exists in level %s" % [expected_id, str(level.get("id", "UNKNOWN"))])

func test_normalize_expected_sequence_supports_all_empty_markers() -> void:
	var sample_level: Dictionary = {
		"expected_sequence": ["frag_open", "(EMPTY)", "(ПУСТОЙ)", LEGACY_EMPTY_MARKER, "frag_close"]
	}
	var normalized: Array[String] = FR8Scoring.normalize_expected_sequence(sample_level)
	assert_equal(normalized.size(), 5, "normalize_expected_sequence keeps sequence length")
	assert_equal(normalized[0], "frag_open", "normal fragment ids are preserved")
	assert_equal(normalized[1], "", "canonical EMPTY marker becomes empty id")
	assert_equal(normalized[2], "", "RU EMPTY marker becomes empty id")
	assert_equal(normalized[3], "", "legacy mojibake EMPTY marker becomes empty id")
	assert_equal(normalized[4], "frag_close", "tail fragment id is preserved")

func test_a_localized_content_fixes() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH_A)
	assert_true(not levels.is_empty(), "A levels are available for localization checks")

	var f01: Dictionary = _level_by_id(levels, "FR8-A-F01")
	var f02: Dictionary = _level_by_id(levels, "FR8-A-F02")
	assert_true(not f01.is_empty(), "FR8-A-F01 exists")
	assert_true(not f02.is_empty(), "FR8-A-F02 exists")
	if f01.is_empty() or f02.is_empty():
		return

	var feedback_rules: Dictionary = f01.get("feedback_rules", {}) as Dictionary
	assert_equal(
		str(feedback_rules.get("UNBALANCED_TAG", "")),
		"Контейнер разорван: начало и конец структуры не совпадают.",
		"FR8-A-F01 UNBALANCED_TAG is Russian"
	)
	assert_equal(
		str(f02.get("briefing", "")),
		"Форма с двумя полями. Соберите без лишних элементов.",
		"FR8-A-F02 briefing is Russian"
	)

func test_a_bucket_distribution() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH_A)
	assert_true(not levels.is_empty(), "A levels are available for bucket checks")

	var expected_bucket_by_id: Dictionary = {
		"FR8-A-L01": "newbie",
		"FR8-A-L02": "newbie",
		"FR8-A-N01": "newbie",
		"FR8-A-N02": "newbie",
		"FR8-A-T01": "intermediate",
		"FR8-A-T02": "intermediate",
		"FR8-A-F01": "intermediate",
		"FR8-A-F02": "intermediate",
		"FR8-A-A01": "advanced",
		"FR8-A-A02": "advanced",
		"FR8-A-M01": "advanced",
		"FR8-A-M02": "advanced",
	}
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var level_id: String = str(level.get("id", ""))
		if not expected_bucket_by_id.has(level_id):
			continue
		assert_equal(
			str(level.get("bucket", "")),
			str(expected_bucket_by_id.get(level_id, "")),
			"%s has expected bucket" % level_id
		)

func test_c_data_contract_is_valid() -> void:
	var levels: Array = FR8CData.load_levels(LEVELS_PATH_C)
	assert_true(not levels.is_empty(), "FR8CData.load_levels() returns valid levels")

func test_c_rules_have_ascii_selector_kind_prop() -> void:
	var levels: Array = FR8CData.load_levels(LEVELS_PATH_C)
	assert_true(not levels.is_empty(), "C levels are available for selector/kind/prop checks")
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		var level_id: String = str(level.get("id", "UNKNOWN"))
		for rule_var in level.get("rules", []) as Array:
			if typeof(rule_var) != TYPE_DICTIONARY:
				continue
			var rule: Dictionary = rule_var as Dictionary
			var selector: String = str(rule.get("selector", ""))
			var kind: String = str(rule.get("kind", ""))
			var decl: Dictionary = rule.get("decl", {}) as Dictionary
			var prop: String = str(decl.get("prop", ""))
			assert_true(_is_ascii(selector), "C selector is ASCII in %s: %s" % [level_id, selector])
			assert_true(_is_ascii(kind), "C kind is ASCII in %s: %s" % [level_id, kind])
			assert_true(_is_ascii(prop), "C decl.prop is ASCII in %s: %s" % [level_id, prop])

func test_c_scoring_contains_winning_source_id_alias() -> void:
	var levels: Array = FR8CData.load_levels(LEVELS_PATH_C)
	assert_true(not levels.is_empty(), "C levels are available for winning_source_id alias check")
	if levels.is_empty():
		return
	var level: Dictionary = levels[0] as Dictionary
	var selected_option_id: String = str(level.get("correct_option_id", ""))
	var evaluation: Dictionary = FR8CScoring.evaluate(level, selected_option_id)
	assert_true(evaluation.has("winner_source_id"), "FR8CScoring returns winner_source_id")
	assert_true(evaluation.has("winning_source_id"), "FR8CScoring returns winning_source_id alias")
	assert_equal(
		str(evaluation.get("winning_source_id", "")),
		str(evaluation.get("winner_source_id", "")),
		"winning_source_id matches winner_source_id"
	)

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

func _is_ascii(text_value: String) -> bool:
	for i in range(text_value.length()):
		if text_value.unicode_at(i) > 127:
			return false
	return true

func _level_by_id(levels: Array, level_id: String) -> Dictionary:
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var as Dictionary
		if str(level.get("id", "")) == level_id:
			return level
	return {}

func print_results() -> void:
	print("[CASE08 CONTRACT TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
