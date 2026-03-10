extends Node

class_name TestCase01Scoring

const LEVELS_PATH: String = "res://data/clues_levels.json"
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

func _ready() -> void:
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_matching_thresholds()
	test_matching_table_thresholds()
	test_topology_and_ip_quiz()
	test_attack_match_requires_two_of_two()
	test_subnet_requires_three_of_three_and_normalization()
	test_subnet_ip_normalization_edge_cases()
	test_multi_choice_slots_smoke()

func test_matching_thresholds() -> void:
	var level: Dictionary = _find_level("A", "RESUS-A-01")
	assert_true(not level.is_empty(), "A-01 level found")

	var perfect_snapshot: Dictionary = _build_matching_snapshot(level, 8)
	var perfect: Dictionary = ResusScoring.score(level, perfect_snapshot, 8)
	assert_equal(str(perfect.get("verdict_code", "")), "PERFECT", "MATCHING 8/8 -> PERFECT")

	var good_snapshot: Dictionary = _build_matching_snapshot(level, 6)
	var good: Dictionary = ResusScoring.score(level, good_snapshot, 8)
	assert_equal(str(good.get("verdict_code", "")), "GOOD", "MATCHING 6/8 -> GOOD")

	var good_5_snapshot: Dictionary = _build_matching_snapshot(level, 5)
	var good_5: Dictionary = ResusScoring.score(level, good_5_snapshot, 8)
	assert_equal(str(good_5.get("verdict_code", "")), "GOOD", "MATCHING 5/8 -> GOOD (boundary)")

	var fail_4_snapshot: Dictionary = _build_matching_snapshot(level, 4)
	var fail_4: Dictionary = ResusScoring.score(level, fail_4_snapshot, 8)
	assert_equal(str(fail_4.get("verdict_code", "")), "FAIL", "MATCHING 4/8 -> FAIL (boundary)")

	var empty: Dictionary = ResusScoring.score(level, {}, 0)
	assert_equal(str(empty.get("verdict_code", "")), "EMPTY", "MATCHING 0 placed -> EMPTY")

	var fail_snapshot: Dictionary = _build_matching_snapshot(level, 3)
	var fail: Dictionary = ResusScoring.score(level, fail_snapshot, 8)
	assert_equal(str(fail.get("verdict_code", "")), "FAIL", "MATCHING 3/8 -> FAIL")

func test_matching_table_thresholds() -> void:
	var level: Dictionary = _find_level("A", "RESUS-A-04")
	assert_true(not level.is_empty(), "A-04 level found")

	var perfect_snapshot := {
		"TASK_OFFICE": "PC1",
		"TASK_GAMING": "PC3",
		"TASK_VIDEO": "PC4",
		"TASK_PROGRAMMING": "PC2"
	}
	var perfect: Dictionary = ResusScoring.calculate_matching_table_result(level, perfect_snapshot)
	assert_equal(str(perfect.get("verdict_code", "")), "PERFECT", "MATCHING_TABLE 4/4 -> PERFECT")

	var good_snapshot := {
		"TASK_OFFICE": "PC1",
		"TASK_GAMING": "PC3",
		"TASK_VIDEO": "PC2",
		"TASK_PROGRAMMING": "PC2"
	}
	var good: Dictionary = ResusScoring.calculate_matching_table_result(level, good_snapshot)
	assert_equal(str(good.get("verdict_code", "")), "GOOD", "MATCHING_TABLE 3/4 -> GOOD")

	var fail_snapshot := {
		"TASK_OFFICE": "PC3",
		"TASK_GAMING": "PC1",
		"TASK_VIDEO": "PC2",
		"TASK_PROGRAMMING": "PC2"
	}
	var fail: Dictionary = ResusScoring.calculate_matching_table_result(level, fail_snapshot)
	assert_equal(str(fail.get("verdict_code", "")), "FAIL", "MATCHING_TABLE 1/4 -> FAIL")

func test_topology_and_ip_quiz() -> void:
	var topo: Dictionary = _find_level("B", "CASE01_B_01")
	var topo_result: Dictionary = ResusScoring.calculate_quiz_result(topo, ["star", "star", "ring"])
	assert_equal(str(topo_result.get("verdict_code", "")), "PERFECT", "TOPOLOGY_MATCH 3/3 -> PERFECT")

	var ip_quiz: Dictionary = _find_level("B", "CASE01_B_04")
	var ip_result: Dictionary = ResusScoring.calculate_quiz_result(ip_quiz, ["B", "192.168.1.1", "128"])
	assert_equal(str(ip_result.get("verdict_code", "")), "GOOD", "IP_QUIZ 2/3 -> GOOD")

func test_attack_match_requires_two_of_two() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_02")
	assert_true(not level.is_empty(), "C-02 level found")

	var partial_answers: Array = [
		{"attack": "ddos", "defense": "antivirus"},
		{"attack": "phishing", "defense": "awareness"},
		{"attack": "mitm", "defense": "vpn"}
	]
	var partial: Dictionary = ResusScoring.calculate_attack_match_result(level, partial_answers)
	assert_equal(int(partial.get("correct_count", -1)), 2, "ATTACK_MATCH counts only full 2/2 round as correct")
	assert_equal(str(partial.get("verdict_code", "")), "GOOD", "ATTACK_MATCH 2/3 -> GOOD")

	var perfect_answers: Array = [
		{"attack": "ddos", "defense": "ratelimit"},
		{"attack": "phishing", "defense": "awareness"},
		{"attack": "mitm", "defense": "vpn"}
	]
	var perfect: Dictionary = ResusScoring.calculate_attack_match_result(level, perfect_answers)
	assert_equal(str(perfect.get("verdict_code", "")), "PERFECT", "ATTACK_MATCH 3/3 -> PERFECT")

func test_subnet_requires_three_of_three_and_normalization() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_03")
	assert_true(not level.is_empty(), "C-03 level found")

	var partial_answers: Array = [
		{"network": "192.168.10.0", "broadcast": "192.168.10.255", "hosts": "253"},
		{"network": "10.0.5.128", "broadcast": "10.0.5.255", "hosts": "126"}
	]
	var partial: Dictionary = ResusScoring.calculate_subnet_result(level, partial_answers)
	assert_equal(int(partial.get("correct_count", -1)), 1, "SUBNET round fails when one field is wrong")
	assert_equal(str(partial.get("verdict_code", "")), "FAIL", "SUBNET 1/2 -> FAIL")

	var normalized_answers: Array = [
		{"network": "192.168.010.000", "broadcast": "192.168.010.255", "hosts": "254"},
		{"network": "10.000.005.128", "broadcast": "010.000.005.255", "hosts": "126"}
	]
	var normalized: Dictionary = ResusScoring.calculate_subnet_result(level, normalized_answers)
	assert_equal(str(normalized.get("verdict_code", "")), "PERFECT", "SUBNET IP normalization handles leading zeros")

func test_subnet_ip_normalization_edge_cases() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_03")
	assert_true(not level.is_empty(), "C-03 level found for edge cases")

	var empty_answers: Array = [
		{"network": "", "broadcast": "", "hosts": ""},
		{"network": "", "broadcast": "", "hosts": ""}
	]
	var empty_result: Dictionary = ResusScoring.calculate_subnet_result(level, empty_answers)
	assert_equal(str(empty_result.get("verdict_code", "")), "FAIL", "SUBNET empty answers -> FAIL")

	var spaced_answers: Array = [
		{"network": " 192.168.10.0 ", "broadcast": "192.168.10.255", "hosts": " 254 "},
		{"network": "10.0.5.128", "broadcast": "10.0.5.255", "hosts": "126"}
	]
	var spaced: Dictionary = ResusScoring.calculate_subnet_result(level, spaced_answers)
	assert_equal(str(spaced.get("verdict_code", "")), "PERFECT", "SUBNET trims whitespace")

func test_multi_choice_slots_smoke() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_01")
	assert_true(not level.is_empty(), "C-01 level found")
	var snapshot := {
		"slots": ["SWITCH", "FIREWALL", "FIBER"],
		"selected": ["SWITCH", "FIREWALL", "FIBER"],
		"unique_used_count": 3
	}
	var result: Dictionary = ResusScoring.calculate_stage_c_result(level, snapshot)
	assert_equal(str(result.get("verdict_code", "")), "PERFECT", "MULTI_CHOICE_SLOTS perfect path remains working")

func _build_matching_snapshot(level: Dictionary, correct_target: int) -> Dictionary:
	var snapshot: Dictionary = {}
	var items: Array = level.get("items", []) as Array
	var buckets: Array = level.get("buckets", []) as Array
	var fallback_bucket: String = "PILE"
	if not buckets.is_empty() and typeof(buckets[0]) == TYPE_DICTIONARY:
		fallback_bucket = str((buckets[0] as Dictionary).get("bucket_id", "PILE")).to_upper()
	var idx: int = 0
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		var expected: String = str(item.get("correct_bucket_id", "PILE")).to_upper()
		if idx < correct_target:
			snapshot[item_id] = expected
		else:
			snapshot[item_id] = "PILE" if fallback_bucket == expected else fallback_bucket
		idx += 1
	return snapshot

func _find_level(stage_id: String, level_id: String) -> Dictionary:
	var root: Variant = _load_root()
	if typeof(root) != TYPE_ARRAY:
		return {}
	for entry_v in root as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != "CASE_01_DIGITAL_RESUS":
			continue
		var levels: Array = (((entry.get("stages", {}) as Dictionary).get(stage_id, {}) as Dictionary).get("levels", []) as Array)
		for level_v in levels:
			if typeof(level_v) != TYPE_DICTIONARY:
				continue
			var level: Dictionary = level_v as Dictionary
			if str(level.get("id", "")) == level_id:
				return level.duplicate(true)
	return {}

func _load_root() -> Variant:
	var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return null
	return json.data

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
	print("[CASE01 SCORING TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
