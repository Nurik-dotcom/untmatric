extends Node
# Тесты для матричного решателя
# Проверяет: генерацию матриц, проверку HD, валидность ограничений

class_name TestMatrixSolver

var metrics: Node
var test_results: Dictionary = {
	"passed": 0,
	"failed": 0
}

func _ready():
	metrics = preload("res://scripts/GlobalMetrics.gd").new()
	add_child(metrics)
	run_all_tests()

func run_all_tests():
	print("\n" + "=".repeat(60))
	print("🔲 MATRIX SOLVER TEST SUITE")
	print("=".repeat(60))
	
	test_matrix_size()
	test_row_constraints_calculation()
	test_col_constraints_calculation()
	test_hamming_distance_matrix()
	test_matrix_solution_validation()
	test_matrix_quest_uniqueness()
	test_solver_edge_cases()
	
	print_results()

# ============= MATRIX SIZE TESTS =============

func test_matrix_size():
	print("\n[TEST] Matrix Size Validation")
	
	metrics.reset_engine()
	metrics.start_matrix_quest()
	
	# Check matrix is 6x6
	assert_equal(metrics.matrix_target.size(), 6, "Matrix should have 6 rows")
	
	for i in range(6):
		var row = metrics.matrix_target[i]
		assert_equal(row.size(), 6, "Row %d should have 6 columns" % i)
		
		# Each cell should be 0 or 1
		for j in range(6):
			var cell = row[j]
			assert_true(cell == 0 or cell == 1, 
				"Cell [%d,%d] should be 0 or 1, got %s" % [i, j, cell])

# ============= ROW CONSTRAINTS TESTS =============

func test_row_constraints_calculation():
	print("\n[TEST] Row Constraints Calculation")
	
	metrics.reset_engine()
	
	# Create a known matrix
	var test_matrix = [
		[1, 0, 1, 0, 0, 0],  # 32+8 = 40
		[0, 1, 0, 1, 0, 0],  # 16+4 = 20
		[1, 1, 0, 0, 0, 0],  # 32+16 = 48
		[0, 0, 0, 0, 0, 1],  # 1
		[1, 1, 1, 1, 1, 1],  # 63
		[0, 0, 0, 0, 0, 0]   # 0
	]
	
	var constraints = metrics._build_row_constraints(test_matrix)
	
	# Verify weights: [32, 16, 8, 4, 2, 1]
	var expected_values = [40, 20, 48, 1, 63, 0]
	
	for i in range(6):
		var expected = expected_values[i]
		var actual = constraints[i].get("hex_value")
		assert_equal(actual, expected, 
			"Row %d hex_value should be %d" % [i, expected])

# ============= COLUMN CONSTRAINTS TESTS =============

func test_col_constraints_calculation():
	print("\n[TEST] Column Constraints Calculation")
	
	metrics.reset_engine()
	
	var test_matrix = [
		[1, 0, 1, 0, 0, 0],
		[0, 1, 0, 1, 0, 0],
		[1, 1, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1],
		[0, 0, 0, 0, 0, 0]
	]
	
	var constraints = metrics._build_col_constraints(test_matrix)
	
	# Count ones in each column
	var expected_ones = [3, 3, 2, 2, 1, 2]  # ones in each column
	
	for c in range(6):
		var actual_ones = constraints[c].get("ones_count")
		var actual_parity = constraints[c].get("parity")
		
		assert_equal(actual_ones, expected_ones[c],
			"Column %d should have %d ones" % [c, expected_ones[c]])
		
		# Parity: 0 if even, 1 if odd
		var expected_parity = expected_ones[c] % 2
		assert_equal(actual_parity, expected_parity,
			"Column %d parity should be %d" % [c, expected_parity])

# ============= MATRIX HAMMING DISTANCE TESTS =============

func test_hamming_distance_matrix():
	print("\n[TEST] Matrix Hamming Distance")
	
	metrics.reset_engine()
	metrics.start_matrix_quest()
	
	# Fill matrix correctly
	metrics.matrix_current = []
	for r in range(6):
		var row = []
		for c in range(6):
			row.append(metrics.matrix_target[r][c])
		metrics.matrix_current.append(row)
	
	var hd_result = metrics.validate_matrix_logic()
	assert_equal(hd_result.get("hd"), 0, "Perfect match should have HD=0")
	
	# Change one cell
	metrics.matrix_current[0][0] = 1 - metrics.matrix_current[0][0]
	
	hd_result = metrics.validate_matrix_logic()
	assert_true(hd_result.get("hd") > 0, "Changed cell should increase HD")

# ============= MATRIX SOLUTION VALIDATION TESTS =============

func test_matrix_solution_validation():
	print("\n[TEST] Matrix Solution Validation")
	
	metrics.reset_engine()
	metrics.start_matrix_quest()
	
	# Initialize current with target
	metrics.matrix_current = []
	for r in range(6):
		var row = []
		for c in range(6):
			row.append(metrics.matrix_target[r][c])
		metrics.matrix_current.append(row)
	
	# Test correct solution
	var result = metrics.check_matrix_solution()
	assert_equal(result.get("success"), true, "Correct solution should succeed")
	
	# Test incorrect solution
	metrics.reset_engine()
	metrics.start_matrix_quest()
	
	# Fill with random values
	metrics.matrix_current = []
	for r in range(6):
		var row = []
		for c in range(6):
			row.append(randi() % 2)
		metrics.matrix_current.append(row)
	
	result = metrics.check_matrix_solution()
	# Should either succeed (unlikely) or fail with hamming distance
	if not result.get("success"):
		assert_true(result.has("hamming"), "Failed solution should have hamming distance")

# ============= MATRIX UNIQUENESS TESTS =============

func test_matrix_quest_uniqueness():
	print("\n[TEST] Matrix Quest Uniqueness")
	
	# Generate multiple quests and ensure they're different
	var quests = []
	for i in range(3):
		metrics.reset_engine()
		metrics.start_matrix_quest()
		quests.append({
			"target": metrics.matrix_target.duplicate(true),
			"row_constraints": metrics.matrix_row_constraints.duplicate(true),
			"col_constraints": metrics.matrix_col_constraints.duplicate(true)
		})
	
	# At least one should be different
	var all_same = true
	for i in range(1, quests.size()):
		if quests[i]["target"] != quests[0]["target"]:
			all_same = false
			break
	
	assert_false(all_same, "Multiple quest generations should produce different results")

# ============= SOLVER EDGE CASES =============

func test_solver_edge_cases():
	print("\n[TEST] Solver Edge Cases")
	
	metrics.reset_engine()
	
	# Test empty matrix (all zeros)
	var empty_matrix = []
	for r in range(6):
		var row = []
		for c in range(6):
			row.append(0)
		empty_matrix.append(row)
	
	var row_constraints = metrics._build_row_constraints(empty_matrix)
	var col_constraints = metrics._build_col_constraints(empty_matrix)
	
	for r in range(6):
		assert_equal(row_constraints[r].get("hex_value"), 0, "Empty row should have 0 value")
	
	for c in range(6):
		assert_equal(col_constraints[c].get("ones_count"), 0, "Empty column should have 0 ones")
	
	# Test full matrix (all ones)
	var full_matrix = []
	for r in range(6):
		var row = []
		for c in range(6):
			row.append(1)
		full_matrix.append(row)
	
	row_constraints = metrics._build_row_constraints(full_matrix)
	col_constraints = metrics._build_col_constraints(full_matrix)
	
	for r in range(6):
		# Full row: 32+16+8+4+2+1 = 63
		assert_equal(row_constraints[r].get("hex_value"), 63, "Full row should have 63 value")
	
	for c in range(6):
		assert_equal(col_constraints[c].get("ones_count"), 6, "Full column should have 6 ones")
		assert_equal(col_constraints[c].get("parity"), 0, "6 ones = even parity")

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

func print_results():
	var total = test_results["passed"] + test_results["failed"]
	var pass_rate = (float(test_results["passed"]) / total * 100) if total > 0 else 0
	
	print("\n" + "=".repeat(60))
	print("📊 MATRIX TEST RESULTS")
	print("=".repeat(60))
	print("✅ Passed: %d" % test_results["passed"])
	print("❌ Failed: %d" % test_results["failed"])
	print("📈 Pass Rate: %.1f%%" % pass_rate)
	print("=".repeat(60) + "\n")
