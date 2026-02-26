extends Node
# Test Runner - запускает все тесты и собирает результаты
# Используется для отладки и CI

class_name TestRunner

var all_results: Dictionary = {
	"total_passed": 0,
	"total_failed": 0,
	"suites": []
}

func _ready():
	print("\n\n")
	print("╔" + "═".repeat(58) + "╗")
	print("║" + " ".repeat(10) + "🧪 UNTFORMATIC TEST SUITE 🧪" + " ".repeat(20) + "║")
	print("╚" + "═".repeat(58) + "╝")
	
	run_tests()

func run_tests():
	# Run each test suite
	await run_test_suite("GlobalMetrics", "res://tests/test_global_metrics.gd")
	await run_test_suite("MatrixSolver", "res://tests/test_matrix_solver.gd")
	await run_test_suite("Shields", "res://tests/test_shields.gd")
	
	# Print summary
	print_summary()
	
	# Exit with appropriate code
	var exit_code = 0 if all_results["total_failed"] == 0 else 1
	get_tree().quit(exit_code)

func run_test_suite(name: String, script_path: String) -> void:
	print("\n▶ Loading test suite: %s" % name)
	
	var test_class = load(script_path)
	if test_class == null:
		print("  ✗ Failed to load script: %s" % script_path)
		return
	
	var test_instance = test_class.new()
	add_child(test_instance)
	
	# Wait for tests to complete (they run in _ready)
	await get_tree().process_frame
	
	# Extract results
	if test_instance.has_meta("test_results"):
		var results = test_instance.get_meta("test_results")
		all_results["total_passed"] += results.get("passed", 0)
		all_results["total_failed"] += results.get("failed", 0)
		all_results["suites"].append({
			"name": name,
			"results": results
		})
	
	test_instance.queue_free()

func print_summary():
	print("\n\n")
	print("╔" + "═".repeat(58) + "╗")
	print("║" + " ".repeat(16) + "📊 FINAL RESULTS 📊" + " ".repeat(23) + "║")
	print("╠" + "═".repeat(58) + "╣")
	
	var total = all_results["total_passed"] + all_results["total_failed"]
	var pass_rate = (float(all_results["total_passed"]) / total * 100) if total > 0 else 0
	
	print("║ ✅ Total Passed: %-40d ║" % all_results["total_passed"])
	print("║ ❌ Total Failed: %-40d ║" % all_results["total_failed"])
	print("║ 📈 Pass Rate: %-42.1f%% ║" % pass_rate)
	
	print("╠" + "═".repeat(58) + "╣")
	
	for suite in all_results["suites"]:
		var suite_passed = suite["results"].get("passed", 0)
		var suite_failed = suite["results"].get("failed", 0)
		var suite_total = suite_passed + suite_failed
		var suite_rate = (float(suite_passed) / suite_total * 100) if suite_total > 0 else 0
		
		var status = "✓" if suite_failed == 0 else "✗"
		print("║ %s %s: %d passed, %d failed (%.0f%%)" % [status, suite["name"].ljust(20), suite_passed, suite_failed, suite_rate])
	
	print("╚" + "═".repeat(58) + "╝\n")
	
	if all_results["total_failed"] == 0:
		print("🎉 ALL TESTS PASSED! 🎉\n")
	else:
		print("⚠️  SOME TESTS FAILED\n")
