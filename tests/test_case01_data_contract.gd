extends Node

class_name TestCase01DataContract

const LEVELS_PATH: String = "res://data/clues_levels.json"
const ResusData = preload("res://scripts/case_01/ResusData.gd")

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

func _ready() -> void:
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_json_parses()
	test_stage_sizes()
	test_all_levels_validate()
	test_cross_references()
	test_stage_c_has_no_modules_dup()
	test_stage_c_switch_filtering_is_off()
	test_stage_c_visual_sim_profiles_complete()

func test_json_parses() -> void:
	var root: Variant = _load_root()
	assert_true(typeof(root) == TYPE_ARRAY and (root as Array).size() > 0, "clues_levels.json parses and is non-empty")

func test_stage_sizes() -> void:
	var quest: Dictionary = _load_case01()
	var stages: Dictionary = quest.get("stages", {}) as Dictionary
	assert_equal((stages.get("A", {}) as Dictionary).get("levels", []).size(), 5, "Stage A has 5 levels")
	assert_equal((stages.get("B", {}) as Dictionary).get("levels", []).size(), 4, "Stage B has 4 levels")
	assert_equal((stages.get("C", {}) as Dictionary).get("levels", []).size(), 3, "Stage C has 3 levels")

func test_all_levels_validate() -> void:
	var quest: Dictionary = _load_case01()
	var stages: Dictionary = quest.get("stages", {}) as Dictionary
	for stage_id in ["A", "B", "C"]:
		var levels: Array = ((stages.get(stage_id, {}) as Dictionary).get("levels", []) as Array)
		for level_v in levels:
			if typeof(level_v) != TYPE_DICTIONARY:
				continue
			var level: Dictionary = (level_v as Dictionary).duplicate(true)
			assert_true(ResusData.validate_level(level), "validate_level passes for %s/%s" % [stage_id, str(level.get("id", "UNKNOWN"))])

func test_cross_references() -> void:
	var quest: Dictionary = _load_case01()
	var stages: Dictionary = quest.get("stages", {}) as Dictionary

	# A-04 correct_config references existing config_id
	var stage_a_levels: Array = ((stages.get("A", {}) as Dictionary).get("levels", []) as Array)
	for level_v in stage_a_levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		if str(level.get("id", "")) != "RESUS-A-04":
			continue
		var config_ids: Dictionary = {}
		for cfg_v in level.get("configs", []) as Array:
			if typeof(cfg_v) != TYPE_DICTIONARY:
				continue
			config_ids[str((cfg_v as Dictionary).get("config_id", ""))] = true
		for task_v in level.get("tasks", []) as Array:
			if typeof(task_v) != TYPE_DICTIONARY:
				continue
			var task: Dictionary = task_v as Dictionary
			var expected_cfg: String = str(task.get("correct_config", ""))
			assert_true(config_ids.has(expected_cfg), "A-04 task maps to existing config: %s" % str(task.get("task_id", "")))

	# B quiz rounds have at least one correct option
	for level_v in ((stages.get("B", {}) as Dictionary).get("levels", []) as Array):
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		var format: String = str(level.get("format", "")).to_upper()
		if format != "TOPOLOGY_MATCH" and format != "IP_QUIZ":
			continue
		for round_v in level.get("rounds", []) as Array:
			if typeof(round_v) != TYPE_DICTIONARY:
				continue
			var has_correct: bool = false
			for option_v in (round_v as Dictionary).get("options", []) as Array:
				if typeof(option_v) == TYPE_DICTIONARY and bool((option_v as Dictionary).get("is_correct", false)):
					has_correct = true
			assert_true(has_correct, "%s round has at least one correct option" % str(level.get("id", "")))

	# C-02 and C-03 contracts
	var stage_c_levels: Array = ((stages.get("C", {}) as Dictionary).get("levels", []) as Array)
	for level_v in stage_c_levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		var level_id: String = str(level.get("id", ""))
		var format: String = str(level.get("format", "")).to_upper()
		if format == "ATTACK_MATCH":
			for round_v in level.get("rounds", []) as Array:
				if typeof(round_v) != TYPE_DICTIONARY:
					continue
				var rd: Dictionary = round_v as Dictionary
				assert_true(rd.has("attack_options") and rd.has("defense_options"), "%s round has attack+defense options" % level_id)
		elif format == "SUBNET_CALC":
			for round_v in level.get("rounds", []) as Array:
				if typeof(round_v) != TYPE_DICTIONARY:
					continue
				var rd: Dictionary = round_v as Dictionary
				assert_true(rd.has("ip") and rd.has("mask") and rd.has("questions"), "%s round has ip/mask/questions" % level_id)

func test_stage_c_has_no_modules_dup() -> void:
	var quest: Dictionary = _load_case01()
	var levels: Array = (((quest.get("stages", {}) as Dictionary).get("C", {}) as Dictionary).get("levels", []) as Array)
	for level_v in levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		if str(level.get("format", "")).to_upper() != "MULTI_CHOICE_SLOTS":
			continue
		assert_true(not level.has("modules"), "C-01 has no duplicated modules array")

func test_stage_c_switch_filtering_is_off() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_01")
	assert_true(not level.is_empty(), "C-01 level found")
	for option_v in level.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_v as Dictionary
		if str(option.get("option_id", "")) != "SWITCH":
			continue
		var effects: Dictionary = option.get("effects", {}) as Dictionary
		assert_equal(str(effects.get("filtering", "")), "OFF", "SWITCH filtering must be OFF")
		return
	assert_true(false, "SWITCH option found in C-01")

func test_stage_c_visual_sim_profiles_complete() -> void:
	var level: Dictionary = _find_level("C", "CASE01_C_01")
	assert_true(not level.is_empty(), "C-01 level found for visual_sim")
	var visual_sim: Dictionary = level.get("visual_sim", {}) as Dictionary
	var required_profiles: Array[String] = ["EMPTY", "FAIL", "GOOD", "NOISY", "PERFECT", "SELECT_ALL"]
	var required_fields: Array[String] = ["packet_count", "speed", "scatter", "steal_rate", "attacker_alpha", "packet_tint", "attacker_tint"]
	for profile in required_profiles:
		assert_true(visual_sim.has(profile), "visual_sim has profile %s" % profile)
		var config: Dictionary = visual_sim.get(profile, {}) as Dictionary
		for field in required_fields:
			assert_true(config.has(field), "visual_sim.%s has field %s" % [profile, field])

func _load_root() -> Variant:
	var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return null
	return json.data

func _load_case01() -> Dictionary:
	var root: Variant = _load_root()
	if typeof(root) != TYPE_ARRAY:
		return {}
	for entry_v in root as Array:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) == "CASE_01_DIGITAL_RESUS":
			return entry
	return {}

func _find_level(stage_id: String, level_id: String) -> Dictionary:
	var quest: Dictionary = _load_case01()
	var stages: Dictionary = quest.get("stages", {}) as Dictionary
	var levels: Array = ((stages.get(stage_id, {}) as Dictionary).get("levels", []) as Array)
	for level_v in levels:
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_v as Dictionary
		if str(level.get("id", "")) == level_id:
			return level.duplicate(true)
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
	print("[CASE01 DATA CONTRACT TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
