extends Node
# Тесты для Shield системы защиты от читерства
# Проверяет: Frequency Shield, Lazy Search Shield, блокировки

class_name TestShields

var metrics: Node
var test_results: Dictionary = {
	"passed": 0,
	"failed": 0
}
var shield_fired := false
var shield_name := ""
var shield_penalty_time := 0.0

func _ready():
	metrics = preload("res://scripts/GlobalMetrics.gd").new()
	add_child(metrics)
	run_all_tests()

func run_all_tests():
	print("\n" + "=".repeat(60))
	print("🛡️  SHIELDS TEST SUITE")
	print("=".repeat(60))
	
	test_frequency_shield_basic()
	test_frequency_shield_cleanup()
	test_frequency_shield_blocking()
	test_lazy_search_shield_conditions()
	test_lazy_search_matrix_shield()
	test_shield_signals()
	test_shield_recovery()
	test_concurrent_shields()
	
	print_results()

# ============= FREQUENCY SHIELD TESTS =============

func test_frequency_shield_basic():
	print("\n[TEST] Frequency Shield - Basic Logic")
	
	metrics.reset_engine()
	metrics.check_timestamps.clear()
	
	# Add 4 checks - should NOT trigger
	for i in range(4):
		metrics._update_frequency_log(float(i))
	
	assert_equal(metrics.check_timestamps.size(), 4, "Should store 4 timestamps")
	
	# Add 5th check - should NOT trigger on check itself but will on next
	metrics._update_frequency_log(4.0)
	assert_equal(metrics.check_timestamps.size(), 5, "Should store 5 timestamps")

func test_frequency_shield_cleanup():
	print("\n[TEST] Frequency Shield - Timestamp Cleanup")
	
	metrics.reset_engine()
	metrics.check_timestamps.clear()
	
	# Add checks at t=0, 5, 10, 15, 20
	metrics._update_frequency_log(0.0)
	metrics._update_frequency_log(5.0)
	metrics._update_frequency_log(10.0)
	metrics._update_frequency_log(15.0)
	
	# Now at t=20, call cleanup (removes entries older than 20-15=5)
	metrics._update_frequency_log(20.0)
	
	# Should have removed entries < 5 (only t=0)
	var count_lt_5 = 0
	for t in metrics.check_timestamps:
		if t < 5.0:
			count_lt_5 += 1
	
	assert_equal(count_lt_5, 0, "Should remove timestamps older than 15 seconds")
	assert_true(metrics.check_timestamps.size() >= 4, "Should keep recent timestamps")

func test_frequency_shield_blocking():
	print("\n[TEST] Frequency Shield - Blocking Mechanism")
	
	metrics.reset_engine()
	metrics.stability = 100.0
	
	# Simulate 5 rapid checks
	for i in range(5):
		var result = metrics.check_solution(42, 42)
		if i < 4:
			assert_true(result.get("success"), "First 4 checks should process")
		else:
			assert_equal(result.get("error"), "SHIELD_FREQ", 
				"5th check should trigger frequency shield")
	
	# Check blocked_until is set
	assert_true(metrics.blocked_until > 0.0, "blocked_until should be set")
	
	# Try to check again immediately - should be blocked
	var result = metrics.check_solution(42, 42)
	assert_equal(result.get("error"), "SHIELD_ACTIVE",
		"Should return SHIELD_ACTIVE when blocked_until active")

# ============= LAZY SEARCH SHIELD TESTS =============

func test_lazy_search_shield_conditions():
	print("\n[TEST] Lazy Search Shield - HD Conditions")
	
	metrics.reset_engine()
	
	# Condition 1: HD <= 2 should NOT trigger
	var is_lazy = metrics._check_lazy_search(0b00000000, 0)
	assert_false(is_lazy, "HD=0 should not trigger lazy shield")
	
	is_lazy = metrics._check_lazy_search(0b00000001, 1)
	assert_false(is_lazy, "HD=1 should not trigger lazy shield")
	
	is_lazy = metrics._check_lazy_search(0b00000011, 2)
	assert_false(is_lazy, "HD=2 should not trigger lazy shield")
	
	# Condition 2: HD > 2 but need 4 history entries
	metrics.last_checked_bits = [0b00000000]  # Only 1 entry
	is_lazy = metrics._check_lazy_search(0b11111111, 8)
	assert_false(is_lazy, "Need at least 4 entries in history")

func test_lazy_search_shield_bit_tracking():
	print("\n[TEST] Lazy Search Shield - Bit Change Tracking")
	
	metrics.reset_engine()
	
	# Scenario: changing only 2 unique bits across 4 inputs
	# 0b00000000 -> 0b00000001 -> 0b00000011 -> 0b00000111
	# Bits changing: 0, 1, 2 = 3 unique bits (NO trigger)
	metrics.last_checked_bits = [
		0b00000000,
		0b00000001,
		0b00000011
	]
	var is_lazy = metrics._check_lazy_search(0b00000111, 3)
	assert_false(is_lazy, "3 unique bits should NOT trigger lazy shield")
	
	# Scenario: changing only 2 unique bits
	# 0b00000000 -> 0b00000001 -> 0b00000011 -> 0b00000010
	# Bits changing: 0, 1 = 2 unique bits (TRIGGER)
	metrics.last_checked_bits = [
		0b00000000,
		0b00000001,
		0b00000011
	]
	is_lazy = metrics._check_lazy_search(0b00000010, 3)
	assert_true(is_lazy, "2 unique bits with HD>2 should trigger lazy shield")

func test_lazy_search_matrix_shield():
	print("\n[TEST] Lazy Search Shield - Matrix Version")
	
	metrics.reset_engine()
	
	# Matrix shield: changed_cells < 3 and HD > 2
	
	# Scenario 1: Only 1 cell changed, HD > 2
	metrics.matrix_changed_cells = {"0,0": true}
	var is_lazy = metrics._check_lazy_search_matrix(3)
	assert_true(is_lazy, "< 3 changed cells with HD>2 should trigger")
	
	# Scenario 2: 3+ cells changed, HD > 2
	metrics.matrix_changed_cells = {
		"0,0": true,
		"0,1": true,
		"0,2": true
	}
	is_lazy = metrics._check_lazy_search_matrix(3)
	assert_false(is_lazy, "3+ changed cells should NOT trigger")
	
	# Scenario 3: HD <= 2, many cells changed
	metrics.matrix_changed_cells = {"0,0": true}
	is_lazy = metrics._check_lazy_search_matrix(2)
	assert_false(is_lazy, "HD<=2 should NOT trigger regardless of changes")

# ============= SHIELD SIGNALS TESTS =============

func test_shield_signals():
	print("\n[TEST] Shield Signal Emissions")
	
	metrics.reset_engine()
	metrics.stability = 100.0

	shield_fired = false
	shield_name = ""
	shield_penalty_time = 0.0

	var signal_handler := Callable(self, "_on_shield_triggered")
	if metrics.shield_triggered.is_connected(signal_handler):
		metrics.shield_triggered.disconnect(signal_handler)
	metrics.shield_triggered.connect(signal_handler)
	
	# Trigger frequency shield
	for i in range(5):
		metrics.check_solution(42, 42)
	
	assert_true(shield_fired, "shield_triggered signal should emit")
	assert_equal(shield_name, "FREQUENCY", "Signal should indicate FREQUENCY shield")
	assert_true(shield_penalty_time > 0.0, "Signal should include penalty time")
	metrics.shield_triggered.disconnect(signal_handler)

# ============= SHIELD RECOVERY TESTS =============

func test_shield_recovery():
	print("\n[TEST] Shield Recovery / Unblocking")
	
	metrics.reset_engine()
	
	# Manually set blocked_until to past time
	metrics.blocked_until = 0.0  # Should be in the past
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Check solution - should NOT be blocked
	var result = metrics.check_solution(42, 42)
	assert_not_equal(result.get("error"), "SHIELD_ACTIVE",
		"Should unblock when blocked_until is in the past")
	
	# Set blocked_until to future
	metrics.blocked_until = current_time + 10.0
	
	# Try again - should be blocked
	result = metrics.check_solution(42, 42)
	assert_equal(result.get("error"), "SHIELD_ACTIVE",
		"Should block when blocked_until is in the future")

func _on_shield_triggered(name: String, time: float) -> void:
	shield_fired = true
	shield_name = name
	shield_penalty_time = time

# ============= CONCURRENT SHIELDS TESTS =============

func test_concurrent_shields():
	print("\n[TEST] Concurrent Shield Triggering")
	
	metrics.reset_engine()
	metrics.stability = 100.0
	
	# This is a complex scenario: can both shields trigger?
	# In current logic, frequency shield is checked first therefore
	# if frequency triggers, lazy search doesn't get checked
	
	# Trigger frequency shield (5+ checks)
	for i in range(5):
		metrics.check_solution(42, 42)
	
	# At this point, we should be blocked by frequency shield
	var result = metrics.check_solution(42, 42)
	assert_equal(result.get("error"), "SHIELD_ACTIVE",
		"Should still be blocked from frequency shield")

# ============= PENALTY PERSISTENCE TEST =============

func test_shield_no_penalty_on_block():
	print("\n[TEST] Shield Block - No Penalty")
	
	metrics.reset_engine()
	metrics.stability = 100.0
	
	# Trigger frequency shield
	for i in range(5):
		metrics.check_solution(42, 42)
	
	var stability_before = metrics.stability
	
	# Try to check while blocked - should NOT lose stability
	var result = metrics.check_solution(99, 42)
	
	assert_equal(metrics.stability, stability_before,
		"Shield block should NOT apply penalty")
	assert_equal(result.get("penalty"), 0,
		"Shield response should have 0 penalty")

# ============= HELPER ASSERTIONS =============

func assert_equal(actual, expected, message: String = ""):
	if actual == expected:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s (got %s, expected %s)" % [message, actual, expected])

func assert_true(condition: bool, message: String = ""):
	if condition:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s" % message)

func assert_false(condition: bool, message: String = ""):
	if not condition:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s" % message)

func assert_not_equal(actual, expected, message: String = ""):
	if actual != expected:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s (should not equal %s)" % [message, expected])

func print_results():
	var total = test_results["passed"] + test_results["failed"]
	var pass_rate = (float(test_results["passed"]) / total * 100) if total > 0 else 0
	
	print("\n" + "=".repeat(60))
	print("📊 SHIELDS TEST RESULTS")
	print("=".repeat(60))
	print("✅ Passed: %d" % test_results["passed"])
	print("❌ Failed: %d" % test_results["failed"])
	print("📈 Pass Rate: %.1f%%" % pass_rate)
	print("=".repeat(60) + "\n")

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
