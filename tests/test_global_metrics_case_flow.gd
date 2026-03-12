extends Node

class_name TestGlobalMetricsCaseFlow

const GLOBAL_METRICS_SCRIPT := preload("res://scripts/GlobalMetrics.gd")

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

var metrics: Node

func _ready() -> void:
	metrics = GLOBAL_METRICS_SCRIPT.new()
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_start_case_flow_initializes_expected_structure()
	test_record_case_stage_result_updates_results_without_duplicates()
	test_get_case_flow_returns_deep_copy()
	test_clear_case_flow_empties_state()
	test_start_quest_and_add_mistake_track_runtime_state()

func test_start_case_flow_initializes_expected_structure() -> void:
	metrics.clear_case_flow()
	var run_id: String = metrics.start_case_flow("CASE_01", ["A", "B", "C"])
	var flow: Dictionary = metrics.get_case_flow()

	assert_true(not run_id.is_empty(), "start_case_flow returns non-empty run id")
	assert_equal(bool(flow.get("is_active", false)), true, "case flow marked as active")
	assert_equal(str(flow.get("case_id", "")), "CASE_01", "case_id is stored")
	assert_equal(str(flow.get("case_run_id", "")), run_id, "case_run_id stored in flow")
	assert_equal(flow.get("stages", []), ["A", "B", "C"], "stages list is stored")
	assert_true(flow.has("started_at_unix"), "started_at_unix field exists")

func test_record_case_stage_result_updates_results_without_duplicates() -> void:
	metrics.clear_case_flow()
	metrics.start_case_flow("CASE_02", ["A", "B"])
	metrics.record_case_stage_result("A", {"score": 10})
	metrics.record_case_stage_result("A", {"score": 20})

	var flow: Dictionary = metrics.get_case_flow()
	var stage_results: Dictionary = flow.get("stage_results", {}) as Dictionary
	var completed: Array = flow.get("completed_stages", []) as Array
	var stage_a: Dictionary = stage_results.get("A", {}) as Dictionary

	assert_true(stage_results.has("A"), "stage_results contains stage A")
	assert_equal(int(stage_a.get("score", 0)), 20, "latest stage summary overwrites previous value")
	assert_equal(_count_occurrences(completed, "A"), 1, "completed_stages does not duplicate same stage")

func test_get_case_flow_returns_deep_copy() -> void:
	metrics.clear_case_flow()
	metrics.start_case_flow("CASE_03", ["A"])
	metrics.record_case_stage_result("A", {"score": 33, "meta": {"attempt": 1}})

	var snapshot: Dictionary = metrics.get_case_flow()
	var snapshot_results: Dictionary = snapshot.get("stage_results", {}) as Dictionary
	var snapshot_stage_a: Dictionary = snapshot_results.get("A", {}) as Dictionary
	var snapshot_meta: Dictionary = snapshot_stage_a.get("meta", {}) as Dictionary
	snapshot_meta["attempt"] = 99
	snapshot_stage_a["score"] = 999
	snapshot_stage_a["meta"] = snapshot_meta
	snapshot_results["A"] = snapshot_stage_a
	snapshot["stage_results"] = snapshot_results
	var snapshot_completed: Array = snapshot.get("completed_stages", []) as Array
	snapshot_completed.append("Z")
	snapshot["completed_stages"] = snapshot_completed

	var original: Dictionary = metrics.get_case_flow()
	var original_results: Dictionary = original.get("stage_results", {}) as Dictionary
	var original_stage_a: Dictionary = original_results.get("A", {}) as Dictionary
	var original_meta: Dictionary = original_stage_a.get("meta", {}) as Dictionary
	var original_completed: Array = original.get("completed_stages", []) as Array

	assert_equal(int(original_stage_a.get("score", 0)), 33, "Mutating returned snapshot does not affect stored score")
	assert_equal(int(original_meta.get("attempt", 0)), 1, "Mutating nested snapshot data does not affect source")
	assert_false(original_completed.has("Z"), "Mutating snapshot array does not affect source")

func test_clear_case_flow_empties_state() -> void:
	metrics.start_case_flow("CASE_04", ["A", "B", "C"])
	metrics.record_case_stage_result("A", {"score": 5})
	metrics.clear_case_flow()

	assert_true(metrics.get_case_flow().is_empty(), "clear_case_flow removes active case flow state")

func test_start_quest_and_add_mistake_track_runtime_state() -> void:
	metrics.start_quest("CaseFlow_Quest")
	metrics.add_mistake("wrong_node")
	metrics.add_mistake("bad_sum")

	assert_true(float(metrics.current_quest_start_time) > 0.0, "start_quest records start time")
	assert_equal(metrics.current_quest_mistakes.size(), 2, "add_mistake stores all mistakes")
	assert_equal(str(metrics.current_quest_mistakes[0]), "wrong_node", "First mistake is tracked")
	assert_equal(str(metrics.current_quest_mistakes[1]), "bad_sum", "Second mistake is tracked")

func _count_occurrences(values: Array, needle: Variant) -> int:
	var count := 0
	for value in values:
		if value == needle:
			count += 1
	return count

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s (got=%s expected=%s)" % [message, str(actual), str(expected)])

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func assert_false(condition: bool, message: String) -> void:
	if not condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func print_results() -> void:
	print("[GLOBAL METRICS CASE FLOW TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
