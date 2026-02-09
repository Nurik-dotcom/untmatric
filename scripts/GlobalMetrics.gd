extends Node

# LogicEngine v6.4 Specification

signal stability_changed(new_value, change)
signal shield_triggered(shield_name, penalty)
signal hint_unlocked(level, text)

# Core Resources
var stability: float = 100.0
var current_level_index: int = 0
var current_mode: String = "DEC" # DEC, OCT, HEX

# Anti-Spam / Shields
var check_timestamps: Array[float] = []
var last_checked_bits: Array = [] # History of bit arrays
var blocked_until: float = 0.0

# Session metrics (reset every case)
var trials_log: Array = []
var t_active_base: float = 0.0
var t_penalty: float = 0.0

# Level Configuration (Complexity A + B + C)
# 0-14: Complexity A (Decryptor)
# 15-29: Complexity B (Arithmetic)
# 30-44: Complexity C (Matrix) (Placeholder range)
const MAX_LEVELS = 45

# Protocol B: Arithmetic State
enum Operator { NONE, ADD, SUB, SHIFT }
var current_operator: Operator = Operator.NONE
var arithmetic_target: int = 0
var operand_a: int = 0
var operand_b: int = 0
var is_overflow: bool = false

# Protocol C: Matrix State
const MATRIX_SIZE = 5
const MATRIX_WEIGHTS = [1, 2, 4, 8, 16] # Hex weights 1,2,4,8,10? No, standard 8-4-2-1 logic usually.
# But wait, TDD says "Weights: (8, 4, 2, 1) | (8, 4, 2, 1)" for HEX.
# Matrix is 5x5. Weights usually powers of 2 for rows? 1,2,4,8,16.
var matrix_target: Array = []
var matrix_current: Array = []
var matrix_row_constraints: Array = []
var matrix_col_constraints: Array = []
var matrix_quest: Dictionary = {}
var matrix_changed_cells: Dictionary = {}
# Solver vars
var _solver_row_constraints: Array
var _solver_col_targets: Array
var _solver_col_parity: Array
var _solver_visibility: Array
var _solver_col_sums: Array
var _solver_solutions: int


func _ready():
	reset_engine()

func reset_engine():
	stability = 100.0
	current_level_index = 0
	check_timestamps.clear()
	last_checked_bits.clear()
	blocked_until = 0.0
	trials_log.clear()

func start_level(index: int):
	current_level_index = index
	# Complexity A: 0-14
	if index < 15:
		if index < 5:
			current_mode = "DEC"
		elif index < 10:
			current_mode = "OCT"
		else:
			current_mode = "HEX"
		current_operator = Operator.NONE
	# Complexity B: 15-29 (Arithmetic)
	elif index < 30:
		current_mode = "HEX" # Arithmetic usually in Hex
		_generate_arithmetic_example(index)
	# Complexity C: 30+ (Matrix)
	else:
		start_matrix_quest() # Generate matrix

	# Stability reset per level as per TDD
	stability = 100.0
	emit_signal("stability_changed", stability, 0)
	check_timestamps.clear()
	last_checked_bits.clear()

func register_trial(payload: Dictionary):
	trials_log.append(payload)
	print("[GlobalMetrics] Trial Registered: ", payload)
	if payload.get("is_correct", false) == false:
		stability = max(0, stability - 10)
		emit_signal("stability_changed", stability, -10)
	elif payload.get("is_overkill", false) == true:
		stability = max(0, stability - 5)
		emit_signal("stability_changed", stability, -5)

# --- Protocol A & B Check ---
func check_solution(target_val: int, input_val: int) -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0

	if current_time < blocked_until:
		return {
			"success": false,
			"error": "SHIELD_ACTIVE",
			"message": "Система перегрета. Ждите...",
			"penalty": 0
		}

	# 1. Frequency Shield (Strict >= 4)
	_update_frequency_log(current_time)
	if check_timestamps.size() >= 4:
		blocked_until = current_time + 5.0
		emit_signal("shield_triggered", "FREQUENCY", 5.0)
		return {
			"success": false,
			"error": "SHIELD_FREQ",
			"message": "Блокировка: Слишком часто",
			"penalty": 0
		}

	# 2. Logic Check
	var hd = _calculate_hamming_distance(target_val, input_val)

	# Lazy Search Shield
	if _check_lazy_search(input_val, hd):
		blocked_until = current_time + 3.0
		emit_signal("shield_triggered", "LAZY", 3.0)

	_record_input_history(input_val)

	if hd == 0:
		# Success
		# Protocol B Overflow Check (if applicable)
		var overflow_warning = false
		if current_operator == Operator.ADD and target_val > 255:
			overflow_warning = true

		return {
			"success": true,
			"message": "Доступ разрешен",
			"stability": stability,
			"is_overflow": overflow_warning
		}
	else:
		# Penalty
		var penalty = 0.0
		if hd == 1: penalty = 10.0
		elif hd == 2: penalty = 15.0
		elif hd == 3: penalty = 25.0
		elif hd == 4: penalty = 35.0
		elif hd >= 5: penalty = 50.0
		else: penalty = 50.0

		stability = max(0.0, stability - penalty)
		emit_signal("stability_changed", stability, -penalty)

		# Protocol B Borrow Warning
		# Check if this was a SUB operation and if errors align with borrow propagation
		var borrow_warning = false
		if current_operator == Operator.SUB:
			# Simple heuristic: if MSBs are wrong but LSBs correct, or vice versa in a specific pattern
			# Real borrow error usually means missing a bit flip in higher nibble
			if hd > 0:
				borrow_warning = true # Simplified: warn on error during SUB

		var hints = _generate_hints(target_val, input_val, hd)

		return {
			"success": false,
			"error": "INCORRECT",
			"hamming": hd,
			"penalty": penalty,
			"hints": hints,
			"message": "Ошибка доступа. HD: %d" % hd,
			"borrow_warning": borrow_warning
		}

# --- Protocol B: Arithmetic Logic ---
func _generate_arithmetic_example(level_idx: int):
	# Simplified generation
	var op_roll = randi() % 3
	if op_roll == 0:
		current_operator = Operator.ADD
		operand_a = randi_range(1, 127)
		operand_b = randi_range(1, 127)
		arithmetic_target = operand_a + operand_b
		# Logic to ensure overflow if desired for testing, or standard 8-bit wrap
		# If > 255, it's an overflow scenario
	elif op_roll == 1:
		current_operator = Operator.SUB
		operand_a = randi_range(20, 255)
		operand_b = randi_range(1, operand_a) # Ensure positive result for now
		arithmetic_target = operand_a - operand_b
	else:
		current_operator = Operator.SHIFT
		operand_a = randi_range(1, 64)
		operand_b = 1 # Shift amount
		arithmetic_target = operand_a << 1

	# For Decryptor script compatibility, we might need to expose this target
	# as the main 'target' or handle it separately.
	# Decryptor.gd calls check_solution(current_target...), so Decryptor needs to know the target.

# --- Protocol C: Matrix Logic ---
func start_matrix_quest():
	stability = 100.0
	emit_signal("stability_changed", stability, 0)
	check_timestamps.clear()
	last_checked_bits.clear()
	blocked_until = 0.0
	_generate_matrix_quest()
	_init_matrix_current()
	_clear_matrix_changes()

func _generate_matrix_quest():
	# ... (Matrix generation logic) ...
	# Placeholder for generation
	var attempts = 0
	while attempts < 200:
		attempts += 1
		var target = _random_matrix()
		var row_constraints = _build_row_constraints(target)
		var col_constraints = _build_col_constraints(target)

		var visibility = _pick_row_visibility(row_constraints, col_constraints)
		if visibility.size() == MATRIX_SIZE:
			for r in range(MATRIX_SIZE):
				row_constraints[r].is_hex_visible = visibility[r]

			# 30% Chance to hide one column constraint
			if randf() < 0.3:
				var hide_col = randi() % MATRIX_SIZE
				col_constraints[hide_col].ones_count = -1 # Hidden

			matrix_target = target
			matrix_row_constraints = row_constraints
			matrix_col_constraints = col_constraints
			matrix_quest = {
				"target_matrix": matrix_target,
				"row_constraints": matrix_row_constraints,
				"col_constraints": col_constraints
			}
			return

	# Fallback
	matrix_target = _random_matrix()
	matrix_row_constraints = _build_row_constraints(matrix_target)
	matrix_col_constraints = _build_col_constraints(matrix_target)
	matrix_quest = { "target_matrix": matrix_target }

func _random_matrix() -> Array:
	var matrix = []
	for r in range(MATRIX_SIZE):
		var row = []
		for c in range(MATRIX_SIZE):
			row.append(randi() % 2)
		matrix.append(row)
	return matrix

func _build_row_constraints(target: Array) -> Array:
	var constraints = []
	for r in range(MATRIX_SIZE):
		constraints.append({ "hex_value": _row_value_from_bits(target[r]), "is_hex_visible": true })
	return constraints

func _build_col_constraints(target: Array) -> Array:
	var constraints = []
	for c in range(MATRIX_SIZE):
		var ones = 0
		for r in range(MATRIX_SIZE):
			ones += target[r][c]
		constraints.append({ "ones_count": ones, "parity": ones % 2 })
	return constraints

func _row_value_from_bits(bits: Array) -> int:
	var sum = 0
	for c in range(MATRIX_SIZE):
		if bits[c] == 1: sum += MATRIX_WEIGHTS[c]
	return sum

func _row_bits_from_value(value: int) -> Array:
	var bits = []
	for c in range(MATRIX_SIZE):
		bits.append(1 if (value & MATRIX_WEIGHTS[c]) != 0 else 0)
	return bits

func _pick_row_visibility(row_constraints: Array, col_constraints: Array) -> Array:
	# Dummy implementation for now to satisfy safe logic
	var vis = []
	for r in range(MATRIX_SIZE): vis.append(true)
	return vis

func _init_matrix_current():
	matrix_current = []
	for r in range(MATRIX_SIZE):
		var row = []
		for c in range(MATRIX_SIZE): row.append(-1)
		matrix_current.append(row)

func _clear_matrix_changes():
	matrix_changed_cells.clear()

# --- Common Utils ---

func _calculate_hamming_distance(a: int, b: int) -> int:
	var x = a ^ b
	var dist = 0
	while x > 0:
		dist += 1
		x &= x - 1
	return dist

func _update_frequency_log(time_sec: float):
	check_timestamps.append(time_sec)
	var cutoff = time_sec - 15.0
	while check_timestamps.size() > 0 and check_timestamps[0] < cutoff:
		check_timestamps.pop_front()

func _check_lazy_search(current_input: int, current_hd: int) -> bool:
	if current_hd <= 2: return false
	if last_checked_bits.size() < 3: return false
	var last_input = last_checked_bits[-1]
	var diff = _calculate_hamming_distance(current_input, last_input)
	if diff < 3: return true
	return false

func _record_input_history(val: int):
	last_checked_bits.append(val)
	if last_checked_bits.size() > 10:
		last_checked_bits.pop_front()

func _generate_hints(target: int, input: int, hd: int) -> Dictionary:
	var diagnosis = "BIT_ERROR"
	if target > input: diagnosis = "VALUE_LOW"
	elif target < input: diagnosis = "VALUE_HIGH"

	var x = target ^ input
	var low_err = (x & 0x0F) != 0
	var high_err = (x & 0xF0) != 0
	var zone = "NONE"
	if low_err and high_err: zone = "BOTH_NIBBLES"
	elif low_err: zone = "LOWER_NIBBLE"
	elif high_err: zone = "UPPER_NIBBLE"

	return {
		"diagnosis": diagnosis,
		"zone": zone
	}
