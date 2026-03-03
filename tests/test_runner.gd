extends Node
# Test runner for local and CI execution.
# Every suite must implement: get_test_results() -> Dictionary.

class_name TestRunner

const SUITES: Array[Dictionary] = [
	{"name": "GlobalMetrics", "path": "res://tests/test_global_metrics.gd"},
	{"name": "MatrixSolver", "path": "res://tests/test_matrix_solver.gd"},
	{"name": "Shields", "path": "res://tests/test_shields.gd"},
	{"name": "DA7CasesBContract", "path": "res://tests/test_da7_cases_b_contract.gd"},
	{"name": "Case08DataContract", "path": "res://tests/test_case08_data_contract.gd"},
	{"name": "I18n", "path": "res://tests/test_i18n.gd"}
]

var all_results: Dictionary = {
	"total_passed": 0,
	"total_failed": 0,
	"total_errors": 0,
	"suites": []
}

func _ready():
	print("\n[TEST RUNNER] UNTformatic")
	run_tests()

func run_tests() -> void:
	for suite in SUITES:
		await run_test_suite(str(suite.get("name", "UNKNOWN")), str(suite.get("path", "")))

	print_summary()

	var has_failures := int(all_results.get("total_failed", 0)) > 0
	var has_errors := int(all_results.get("total_errors", 0)) > 0
	var exit_code = 0 if not has_failures and not has_errors else 1
	get_tree().quit(exit_code)

func run_test_suite(name: String, script_path: String) -> void:
	print("\n[SUITE] %s" % name)

	var test_class = load(script_path)
	if test_class == null:
		_record_suite_error(name, script_path, "Failed to load script")
		return

	var test_instance = test_class.new()
	if test_instance == null:
		_record_suite_error(name, script_path, "Failed to instantiate suite")
		return

	add_child(test_instance)

	# Tests run from _ready(). Wait one frame to collect result.
	await get_tree().process_frame

	if not test_instance.has_method("get_test_results"):
		_record_suite_error(name, script_path, "Suite does not implement get_test_results()")
		test_instance.queue_free()
		await get_tree().process_frame
		return

	var raw_results: Variant = test_instance.call("get_test_results")
	if typeof(raw_results) != TYPE_DICTIONARY:
		_record_suite_error(name, script_path, "get_test_results() did not return Dictionary")
		test_instance.queue_free()
		await get_tree().process_frame
		return

	var results: Dictionary = raw_results
	var passed := int(results.get("passed", 0))
	var failed := int(results.get("failed", 0))
	var skipped := int(results.get("skipped", 0))

	all_results["total_passed"] += passed
	all_results["total_failed"] += failed
	all_results["suites"].append({
		"name": name,
		"path": script_path,
		"passed": passed,
		"failed": failed,
		"skipped": skipped,
		"error": ""
	})

	test_instance.queue_free()
	await get_tree().process_frame

func _record_suite_error(name: String, script_path: String, error_message: String) -> void:
	print("  [ERROR] %s" % error_message)
	all_results["total_failed"] += 1
	all_results["total_errors"] += 1
	all_results["suites"].append({
		"name": name,
		"path": script_path,
		"passed": 0,
		"failed": 1,
		"skipped": 0,
		"error": error_message
	})

func print_summary() -> void:
	print("\n[SUMMARY]")
	var total := int(all_results.get("total_passed", 0)) + int(all_results.get("total_failed", 0))
	var pass_rate := (float(all_results["total_passed"]) / float(total) * 100.0) if total > 0 else 0.0

	print("Total passed: %d" % int(all_results.get("total_passed", 0)))
	print("Total failed: %d" % int(all_results.get("total_failed", 0)))
	print("Suite errors: %d" % int(all_results.get("total_errors", 0)))
	print("Pass rate: %.1f%%" % pass_rate)

	for suite in all_results["suites"]:
		var suite_passed := int(suite.get("passed", 0))
		var suite_failed := int(suite.get("failed", 0))
		var suite_total := suite_passed + suite_failed
		var suite_rate := (float(suite_passed) / float(suite_total) * 100.0) if suite_total > 0 else 0.0
		var suite_error := str(suite.get("error", ""))
		var status := "OK" if suite_failed == 0 and suite_error.is_empty() else "FAIL"

		if suite_error.is_empty():
			print("- [%s] %s: %d passed, %d failed (%.0f%%)" % [status, suite.get("name", "UNKNOWN"), suite_passed, suite_failed, suite_rate])
		else:
			print("- [%s] %s: %s" % [status, suite.get("name", "UNKNOWN"), suite_error])

	if int(all_results.get("total_failed", 0)) == 0 and int(all_results.get("total_errors", 0)) == 0:
		print("\nALL TESTS PASSED")
	else:
		print("\nSOME TESTS FAILED")
