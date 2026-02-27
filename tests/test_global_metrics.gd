extends Node
# Тесты для GlobalMetrics.gd
# Проверяет: стабильность, shields, расчеты Hamming distance

class_name TestGlobalMetrics

var metrics: Node
var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}
var game_over_emitted := false

func _ready():
	metrics = preload("res://scripts/GlobalMetrics.gd").new()
	add_child(metrics)
	run_all_tests()

func run_all_tests():
	print("\n" + "=".repeat(60))
	print("🧪 GLOBAL METRICS TEST SUITE")
	print("=".repeat(60))
	
	test_stability_clamping()
	test_hamming_distance()
	test_frequency_shield()
	test_lazy_search_shield()
	test_penalty_calculation()
	test_level_progression()
	test_arithmetic_generation()
	test_matrix_quest_generation()
	
	print_results()

# ============= STABILITY TESTS =============

func test_stability_clamping():
	print("\n[TEST] Stability Clamping")
	
	# Test: Max clamp (100)
	metrics.stability = 150.0
	assert_equal(metrics.stability, 100.0, "Stability should clamp at 100.0")
	
	# Test: Min clamp (0)
	metrics.stability = -50.0
	assert_equal(metrics.stability, 0.0, "Stability should clamp at 0.0")
	
	# Test: Normal value
	metrics.stability = 75.5
	assert_equal(metrics.stability, 75.5, "Stability should accept normal values")
	
	# Test: Game over signal when stability = 0
	game_over_emitted = false
	var game_over_handler := Callable(self, "_on_game_over")
	if metrics.game_over.is_connected(game_over_handler):
		metrics.game_over.disconnect(game_over_handler)
	metrics.game_over.connect(game_over_handler)
	metrics.stability = 0.0
	assert_true(game_over_emitted, "game_over signal should emit when stability reaches 0")
	metrics.game_over.disconnect(game_over_handler)

# ============= HAMMING DISTANCE TESTS =============

func test_hamming_distance():
	print("\n[TEST] Hamming Distance Calculation")
	
	# Test: Identical values
	var hd = metrics._calculate_hamming_distance(0b11110000, 0b11110000)
	assert_equal(hd, 0, "Identical values should have HD=0")
	
	# Test: Single bit difference
	hd = metrics._calculate_hamming_distance(0b11110000, 0b11110001)
	assert_equal(hd, 1, "Single bit difference should have HD=1")
	
	# Test: Multiple bits different
	hd = metrics._calculate_hamming_distance(0b11110000, 0b10100101)
	assert_equal(hd, 4, "4 bits different should have HD=4")
	
	# Test: All bits different
	hd = metrics._calculate_hamming_distance(0b11111111, 0b00000000)
	assert_equal(hd, 8, "All 8 bits different should have HD=8")
	
	# Test: Common values
	hd = metrics._calculate_hamming_distance(42, 50)  # 0b00101010 vs 0b00110010
	assert_equal(hd, 2, "42 vs 50 should have HD=2")

# ============= FREQUENCY SHIELD TESTS =============

func test_frequency_shield():
	print("\n[TEST] Frequency Shield")
	
	metrics.reset_engine()
	
	# Simulate 5 checks within 15 seconds
	for i in range(5):
		metrics._update_frequency_log(float(i))
	
	assert_equal(metrics.check_timestamps.size(), 5, "Should record 5 timestamps")
	
	# Test: Cleanup of old timestamps (>15 seconds)
	metrics._update_frequency_log(20.0)  # 20 seconds later
	# Should remove entries older than 20-15=5 seconds
	var count_before_5sec = 0
	for t in metrics.check_timestamps:
		if t >= 5.0:
			count_before_5sec += 1
	
	assert_true(count_before_5sec > 0, "Should remove old timestamps")
	
	# Test: Frequency limit check (more than 4 = shield active)
	metrics.check_timestamps.clear()
	for timestamp in [0.0, 1.0, 2.0, 3.0, 4.0]:
		metrics.check_timestamps.append(float(timestamp))
	
	var result = metrics.check_solution(42, 42)
	assert_equal(result.get("error"), "SHIELD_FREQ", "5+ checks should trigger frequency shield")

# ============= LAZY SEARCH SHIELD TESTS =============

func test_lazy_search_shield():
	print("\n[TEST] Lazy Search Shield")
	
	metrics.reset_engine()
	
	# Build history: Last 4 inputs changing < 3 unique bits
	# 0b00000001 -> 0b00000011 -> 0b00000111 -> 0b00001111
	# Bits 0,1,2,3 changing = 4 unique bits (should NOT trigger)
	metrics.last_checked_bits = [0b00000001, 0b00000011, 0b00000111]
	var current_input = 0b00001111
	var is_lazy = metrics._check_lazy_search(current_input, 3)
	assert_false(is_lazy, "Changing 4 unique bits should NOT trigger lazy shield")
	
	# Now: only bits 0 and 1 changing
	metrics.last_checked_bits = [0b00000000, 0b00000001, 0b00000011]
	is_lazy = metrics._check_lazy_search(0b00000010, 4)
	assert_true(is_lazy, "Changing < 3 unique bits with HD>2 should trigger lazy shield")

# ============= PENALTY CALCULATION TESTS =============

func test_penalty_calculation():
	print("\n[TEST] Penalty Calculation")
	
	metrics.reset_engine()
	metrics.stability = 100.0
	
	# HD=1 penalty
	var result = metrics.check_solution(0b10000000, 0b10000001)
	assert_equal(result.get("hamming"), 1, "Should calculate HD=1")
	assert_equal(result.get("penalty"), 10.0, "HD=1 should have -10.0 penalty")
	
	# Reset
	metrics.stability = 100.0
	
	# HD=2 penalty
	result = metrics.check_solution(0b11000000, 0b11000011)
	assert_equal(result.get("hamming"), 2, "Should calculate HD=2")
	assert_equal(result.get("penalty"), 15.0, "HD=2 should have -15.0 penalty")
	
	# Reset
	metrics.stability = 100.0
	
	# HD=5 penalty (chaos)
	result = metrics.check_solution(0b11110000, 0b00001111)
	assert_equal(result.get("hamming"), 8, "Should calculate HD=8")
	assert_equal(result.get("penalty"), 50.0, "HD>=5 should have -50.0 penalty (chaos)")

# ============= LEVEL PROGRESSION TESTS =============

func test_level_progression():
	print("\n[TEST] Level Progression & Ranks")
	
	# DEC mode (0-4)
	metrics.start_level(0)
	assert_equal(metrics.current_mode, "DEC", "Level 0-4 should be DEC mode")
	
	# OCT mode (5-9)
	metrics.start_level(5)
	assert_equal(metrics.current_mode, "OCT", "Level 5-9 should be OCT mode")
	
	# HEX mode (10-14)
	metrics.start_level(10)
	assert_equal(metrics.current_mode, "HEX", "Level 10-14 should be HEX mode")
	
	# Complexity B (15+)
	metrics.start_level(15)
	assert_equal(metrics.current_mode, "HEX", "Level 15+ should be HEX mode")
	
	# Test: Stability reset
	metrics.stability = 50.0
	metrics.start_level(0)
	assert_equal(metrics.stability, 100.0, "Level start should reset stability to 100.0")
	
	# Test: Rank system
	var rank = metrics.get_rank_info()
	assert_equal(rank.get("name"), "СТАЖЁР", "Level 0-4 rank should be СТАЖЁР")
	
	metrics.current_level_index = 10
	rank = metrics.get_rank_info()
	assert_equal(rank.get("name"), "КРИПТОАНАЛИТИК", "Level 10-14 rank should be КРИПТОАНАЛИТИК")

# ============= ARITHMETIC GENERATION TESTS =============

func test_arithmetic_generation():
	print("\n[TEST] Arithmetic Example Generation")
	
	metrics.reset_engine()
	metrics.start_level(15)
	
	# Initial generated values should stay within byte range.
	assert_true(metrics.current_reg_a >= 0 and metrics.current_reg_a <= 255, "reg_a should be in byte range")
	assert_true(metrics.current_target_value >= 0 and metrics.current_target_value <= 255, "target should be in byte range")
	
	# Test initial state and multiple next generations.
	for i in range(11):
		if i > 0:
			metrics._generate_arithmetic_example()
		var expected := 0
		
		match metrics.current_operator:
			metrics.Operator.ADD:
				expected = metrics.current_reg_a + metrics.current_reg_b
				assert_equal(metrics.current_target_value, expected, 
					"ADD: target should equal reg_a + reg_b")
				assert_true(expected <= 255, "ADD result should fit in byte")
				
			metrics.Operator.SUB:
				expected = metrics.current_reg_a - metrics.current_reg_b
				assert_equal(metrics.current_target_value, expected,
					"SUB: target should equal reg_a - reg_b")
				assert_true(expected >= 0, "SUB result should be non-negative")
				
			metrics.Operator.SHIFT_L:
				expected = metrics.current_reg_a << metrics.current_reg_b
				assert_equal(metrics.current_target_value, expected,
					"SHIFT_L: target should equal reg_a << reg_b")
				assert_true(expected <= 255, "SHIFT_L result should fit in byte")

# ============= MATRIX SOLVER TESTS =============

func test_matrix_quest_generation():
	print("\n[TEST] Matrix Quest Generation")
	
	metrics.reset_engine()
	metrics.start_matrix_quest()
	
	# Should have valid quest data
	assert_not_empty(metrics.matrix_target, "matrix_target should be populated")
	assert_not_empty(metrics.matrix_row_constraints, "row_constraints should be populated")
	assert_not_empty(metrics.matrix_col_constraints, "col_constraints should be populated")
	
	# Matrix should be 6x6
	assert_equal(metrics.matrix_target.size(), 6, "Matrix should have 6 rows")
	for row in metrics.matrix_target:
		assert_equal(row.size(), 6, "Each row should have 6 columns")
	
	# Test: Row constraints have hex_value
	for constraint in metrics.matrix_row_constraints:
		assert_true(constraint.has("hex_value"), "Row constraint should have hex_value")
		assert_true(constraint.get("hex_value") >= 0 and constraint.get("hex_value") <= 63,
			"hex_value should be 0-63")
	
	# Test: Col constraints have ones_count and parity
	for constraint in metrics.matrix_col_constraints:
		assert_true(constraint.has("ones_count"), "Col constraint should have ones_count")
		assert_true(constraint.has("parity"), "Col constraint should have parity")

func _on_game_over() -> void:
	game_over_emitted = true

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

func assert_not_empty(value, message: String = ""):
	if value is Array and value.size() > 0:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	elif value is Dictionary and value.size() > 0:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s (value is empty)" % message)

func assert_not_equal(actual, expected, message: String = ""):
	if actual != expected:
		test_results["passed"] += 1
		print("  ✓ %s" % message)
	else:
		test_results["failed"] += 1
		print("  ✗ FAILED: %s (got %s, should not equal %s)" % [message, actual, expected])

func print_results():
	var total = test_results["passed"] + test_results["failed"]
	var pass_rate = (float(test_results["passed"]) / total * 100) if total > 0 else 0
	
	print("\n" + "=".repeat(60))
	print("📊 TEST RESULTS")
	print("=".repeat(60))
	print("✅ Passed: %d" % test_results["passed"])
	print("❌ Failed: %d" % test_results["failed"])
	print("📈 Pass Rate: %.1f%%" % pass_rate)
	print("=".repeat(60) + "\n")

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
