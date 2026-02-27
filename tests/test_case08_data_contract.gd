extends Node

class_name TestCase08DataContract

const FR8Data := preload("res://scripts/case_08/fr8_data.gd")
const FR8Scoring := preload("res://scripts/case_08/fr8_scoring.gd")
const LEVELS_PATH := "res://data/final_report_a_levels.json"
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
	test_expected_sequence_contains_only_known_ids_or_empty_markers()
	test_normalize_expected_sequence_supports_all_empty_markers()

func test_load_levels_contract_is_valid() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH)
	assert_true(not levels.is_empty(), "FR8Data.load_levels() returns valid levels")

func test_expected_sequence_contains_only_known_ids_or_empty_markers() -> void:
	var levels: Array = FR8Data.load_levels(LEVELS_PATH)
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
	print("[CASE08 CONTRACT TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
