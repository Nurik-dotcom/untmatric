extends Node

# LogicEngine v6.2 Specification

signal stability_changed(new_value, change)
signal shield_triggered(shield_name, penalty)
signal hint_unlocked(level, text)
signal game_over

# Core Resources
var _stability: float = 100.0
var stability: float:
	get:
		return _stability
	set(value):
		_stability = clamp(value, 0.0, 100.0)
		if _stability <= 0.0:
			game_over.emit()
var current_level_index: int = 0
var current_mode: String = "DEC" # DEC, OCT, HEX
var current_target_value: int = 0

# Analysis History
var session_history: Array = []

func register_trial(data: Dictionary):
	session_history.append(data)
	# ﾐ渙ｵﾐｴﾐｰﾐｳﾐｾﾐｳﾐｸﾑ・ｵﾑ・ｺﾐｸﾐｹ ﾐｻﾐｾﾐｳ ﾐｲ ﾐｺﾐｾﾐｽﾑ・ｾﾐｻﾑ・ﾐｴﾐｻﾑ・ﾐｾﾑひｻﾐｰﾐｴﾐｺﾐｸ
	var match_key = data.get("match_key", "UNKNOWN")
	var is_correct = data.get("is_correct", false)
	# Use elapsed_ms if available (Radio Quest), else duration (Legacy)
	var duration = data.get("duration", data.get("elapsed_ms", 0.0) / 1000.0)
	print("MATCH: ", match_key, " | Correct: ", is_correct, " | Time: ", duration)

	# Logic for Stage A (Radio): Penalty only if FIT is false. Overkill is acceptable.
	var is_fit = data.get("is_fit", null)
	var penalty_condition = false

	if is_fit != null:
		# New schema: punish only if not fit
		penalty_condition = (is_fit == false)
	else:
		# Fallback for old schema
		penalty_condition = (is_correct == false)

	if penalty_condition:
		stability = max(0.0, stability - 10.0)
		emit_signal("stability_changed", stability, -10.0)

# Matrix (Complexity C)
const MATRIX_SIZE := 5
const MATRIX_WEIGHTS := [16, 8, 4, 2, 1]
var matrix_quest: Dictionary = {}
var matrix_target: Array = []
var matrix_row_constraints: Array = []
var matrix_col_constraints: Array = []
var matrix_current: Array = []
var matrix_changed_cells: Dictionary = {}
var _solver_row_constraints: Array = []
var _solver_col_targets: Array = []
var _solver_col_parity: Array = []
var _solver_visibility: Array = []
var _solver_col_sums: Array = []
var _solver_solutions: int = 0

enum Operator { ADD, SUB, SHIFT_L }
var current_reg_a: int = 0
var current_reg_b: int = 0
var current_operator: Operator = Operator.ADD

# Anti-Spam / Shields
var check_timestamps: Array[float] = []
var last_checked_bits: Array = [] # History of bit arrays
var blocked_until: float = 0.0

# Level Configuration (Complexity A)
# 15 Levels: 1-5 DEC, 6-10 OCT, 11-15 HEX
const MAX_LEVELS = 30

func _ready():
	randomize()
	reset_engine()

func reset_engine():
	stability = 100.0
	current_level_index = 0
	current_target_value = 0
	current_reg_a = 0
	current_reg_b = 0
	current_operator = Operator.ADD
	check_timestamps.clear()
	last_checked_bits.clear()
	blocked_until = 0.0
	matrix_quest.clear()
	matrix_target.clear()
	matrix_row_constraints.clear()
	matrix_col_constraints.clear()
	matrix_current.clear()
	matrix_changed_cells.clear()

func start_level(index: int):
	current_level_index = index
	# Determine mode based on level index (0-based)
	if index < 5:
		current_mode = "DEC"
	elif index < 10:
		current_mode = "OCT"
	elif index < 15:
		current_mode = "HEX"
	else:
		# Complexity B uses a single system (HEX) for arithmetic focus
		current_mode = "HEX"

	# Reset shields for the new level/attempt if desired,
	# but typically stability persists or resets per level depending on design.
	# TDD says: "Stability begins with 100% on each level"
	stability = 100.0
	emit_signal("stability_changed", stability, 0)
	check_timestamps.clear()
	last_checked_bits.clear()

	if index >= 15:
		_generate_arithmetic_example()
	else:
		current_target_value = randi_range(1, 255)

# Returns (success: bool, info: Dictionary)
func check_solution(target_val: int, input_val: int) -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time < blocked_until:
		return {
			"success": false,
			"error": "SHIELD_ACTIVE",
			"message": "ﾐ｡ﾐｸﾑ・ひｵﾐｼﾐｰ ﾐｿﾐｵﾑﾐｵﾐｳﾑﾐｵﾑひｰ. ﾐ孟ｴﾐｸﾑひｵ...",
			"penalty": 0
		}

	# 1. Frequency Shield
	_update_frequency_log(current_time)
	if check_timestamps.size() > 4:
		blocked_until = current_time + 5.0 # Block for 5 seconds
		emit_signal("shield_triggered", "FREQUENCY", 5.0)
		return {
			"success": false,
			"error": "SHIELD_FREQ",
			"message": "ﾐ岱ｻﾐｾﾐｺﾐｸﾑﾐｾﾐｲﾐｺﾐｰ: ﾐ｡ﾐｻﾐｸﾑ威ｺﾐｾﾐｼ ﾑ・ｰﾑ・ひｾ",
			"penalty": 0
		}

	# 2. Logic Check
	var hd = _calculate_hamming_distance(target_val, input_val)

	# Lazy Search Shield Check (if HD > 2 and user is making small changes)
	# (Simplified implementation: check if input changed little from last time)
	if _check_lazy_search(input_val, hd):
		# Apply delay penalty
		blocked_until = current_time + 3.0
		emit_signal("shield_triggered", "LAZY", 3.0)
		# We still process the error but maybe with extra penalty?
		# TDD says "penalty delay". We just blocked.

	_record_input_history(input_val)

	if hd == 0:
		return {
			"success": true,
			"message": "ﾐ頒ｾﾑ・びσｿ ﾑﾐｰﾐｷﾑﾐｵﾑ威ｵﾐｽ",
			"stability": stability
		}
	else:
		# Calculate Penalty
		var penalty = 0.0
		if hd == 1: penalty = 10.0
		elif hd == 2: penalty = 15.0
		elif hd == 3: penalty = 25.0
		elif hd == 4: penalty = 35.0
		elif hd >= 5: penalty = 50.0 # Chaos
		else: penalty = 50.0 # Fallback

		stability = max(0.0, stability - penalty)
		emit_signal("stability_changed", stability, -penalty)

		# Generate Hints
		var hints = _generate_hints(target_val, input_val, hd)

		return {
			"success": false,
			"error": "INCORRECT",
			"hamming": hd,
			"penalty": penalty,
			"hints": hints,
			"message": "ﾐ樮威ｸﾐｱﾐｺﾐｰ ﾐｴﾐｾﾑ・びσｿﾐｰ. HD: %d" % hd
		}

func _calculate_hamming_distance(a: int, b: int) -> int:
	var x = a ^ b
	var dist = 0
	while x > 0:
		dist += 1
		x &= x - 1
	return dist

func _update_frequency_log(time_sec: float):
	check_timestamps.append(time_sec)
	# Remove checks older than 15 seconds
	var cutoff = time_sec - 15.0
	while check_timestamps.size() > 0 and check_timestamps[0] < cutoff:
		check_timestamps.pop_front()

func _check_lazy_search(current_input: int, current_hd: int) -> bool:
	if current_hd <= 2: return false

	var inputs = last_checked_bits.duplicate()
	inputs.append(current_input)
	# Need at least 4 inputs to analyze 3 transitions
	if inputs.size() < 4:
		return false

	var unique_changed: Dictionary = {}
	var start = inputs.size() - 4
	for i in range(start, inputs.size() - 1):
		var diff = inputs[i] ^ inputs[i + 1]
		for bit in range(8):
			if (diff & (1 << bit)) != 0:
				unique_changed[bit] = true

	return unique_changed.size() < 3

func _generate_arithmetic_example():
	# Pick an operator for Complexity B
	var op_pick = randi() % 3
	current_operator = Operator.ADD if op_pick == 0 else Operator.SUB if op_pick == 1 else Operator.SHIFT_L

	if current_operator == Operator.ADD:
		current_reg_a = randi_range(0, 255)
		current_reg_b = randi_range(0, 255 - current_reg_a)
		current_target_value = current_reg_a + current_reg_b
	elif current_operator == Operator.SUB:
		current_reg_a = randi_range(0, 255)
		current_reg_b = randi_range(0, current_reg_a)
		current_target_value = current_reg_a - current_reg_b
	else:
		# SHIFT_L by 1..3, ensure result <= 255
		current_reg_b = randi_range(1, 3)
		var max_a = 255 >> current_reg_b
		current_reg_a = randi_range(0, max_a)
		current_target_value = current_reg_a << current_reg_b

func _record_input_history(val: int):
	last_checked_bits.append(val)
	if last_checked_bits.size() > 10:
		last_checked_bits.pop_front()

func _generate_hints(target: int, input: int, hd: int) -> Dictionary:
	# Level 1: Diagnosis
	var diagnosis = "BIT_ERROR"
	if target > input: diagnosis = "VALUE_LOW"
	elif target < input: diagnosis = "VALUE_HIGH"

	# Level 2: Nibble (Zone)
	# Check lower 4 bits (0-3) vs upper 4 bits (4-7)
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

func get_rank_info() -> Dictionary:
	var idx = current_level_index
	if idx < 5:
		return {"name": "TRAINEE", "color": Color("888888")}
	if idx < 10:
		return {"name": "SIGNAL TECH", "color": Color("33ff33")}
	if idx < 15:
		return {"name": "CRYPTO ANALYST", "color": Color("33aaff")}
	if idx < 30:
		return {"name": "SYSTEMS ENGINEER", "color": Color("ffcc00")}
	return {"name": "MONOLITH MASTER", "color": Color("ff33ff")}

# --- Matrix (Complexity C) ---
func start_matrix_quest():
	# Reset shields and stability for a new matrix quest
	stability = 100.0
	emit_signal("stability_changed", stability, 0)
	check_timestamps.clear()
	last_checked_bits.clear()
	blocked_until = 0.0
	_generate_matrix_quest()
	_init_matrix_current()
	_clear_matrix_changes()

func record_matrix_change(row: int, col: int):
	var key = "%d,%d" % [row, col]
	matrix_changed_cells[key] = true

func validate_matrix_logic() -> Dictionary:
	var hd_result = _calculate_matrix_hd()
	return {
		"hd": hd_result.hd,
		"row_ok": hd_result.row_ok,
		"col_ok": hd_result.col_ok
	}

func check_matrix_solution() -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0

	if current_time < blocked_until:
		return {
			"success": false,
			"error": "SHIELD_ACTIVE",
			"message": "System overheated. Wait.",
			"penalty": 0
		}

	# 1. Frequency Shield
	_update_frequency_log(current_time)
	if check_timestamps.size() > 4:
		blocked_until = current_time + 5.0
		emit_signal("shield_triggered", "FREQUENCY", 5.0)
		_clear_matrix_changes()
		return {
			"success": false,
			"error": "SHIELD_FREQ",
			"message": "Lockout: too frequent checks.",
			"penalty": 0
		}

	# 2. Matrix HD
	var hd_result = _calculate_matrix_hd()
	var hd = hd_result.hd

	# Lazy Search Shield (matrix)
	if _check_lazy_search_matrix(hd):
		blocked_until = current_time + 5.0
		emit_signal("shield_triggered", "LAZY", 5.0)
		_clear_matrix_changes()
		return {
			"success": false,
			"error": "SHIELD_LAZY",
			"message": "Lockout: insufficient exploration.",
			"penalty": 0
		}

	_clear_matrix_changes()

	if hd == 0:
		return {
			"success": true,
			"message": "Access granted.",
			"stability": stability
		}

	var penalty = 0.0
	if hd == 1:
		penalty = 15.0
	elif hd == 2:
		penalty = 25.0
	else:
		penalty = 40.0

	stability = max(0.0, stability - penalty)
	emit_signal("stability_changed", stability, -penalty)

	return {
		"success": false,
		"error": "INCORRECT",
		"hamming": hd,
		"penalty": penalty,
		"message": "Incorrect. HD: %d" % hd
	}

func _check_lazy_search_matrix(hd: int) -> bool:
	if hd <= 2:
		return false
	return matrix_changed_cells.size() < 3

func _calculate_matrix_hd() -> Dictionary:
	var row_ok: Array = []
	var col_ok: Array = []
	var hd = 0

	# Row checks (visible only)
	for r in range(MATRIX_SIZE):
		var row_constraint = matrix_row_constraints[r]
		var visible = row_constraint.is_hex_visible
		var row_has_unset = false
		var row_value = 0
		for c in range(MATRIX_SIZE):
			var cell = matrix_current[r][c]
			if cell == -1:
				row_has_unset = true
			elif cell == 1:
				row_value += MATRIX_WEIGHTS[c]
		var is_ok = false
		if visible and not row_has_unset and row_value == row_constraint.hex_value:
			is_ok = true
		row_ok.append(is_ok)
		if visible:
			if row_has_unset or row_value != row_constraint.hex_value:
				hd += 1

	# Column checks (always visible)
	for c in range(MATRIX_SIZE):
		var col_constraint = matrix_col_constraints[c]
		var col_has_unset = false
		var ones = 0
		for r in range(MATRIX_SIZE):
			var cell = matrix_current[r][c]
			if cell == -1:
				col_has_unset = true
			elif cell == 1:
				ones += 1
		var parity = ones % 2
		var is_ok = (not col_has_unset
			and ones == col_constraint.ones_count
			and parity == col_constraint.parity)
		col_ok.append(is_ok)
		if col_has_unset or ones != col_constraint.ones_count:
			hd += 1

	return {
		"hd": hd,
		"row_ok": row_ok,
		"col_ok": col_ok
	}

func _init_matrix_current():
	matrix_current.clear()
	for r in range(MATRIX_SIZE):
		var row: Array = []
		for _c in range(MATRIX_SIZE):
			row.append(-1)
		matrix_current.append(row)

func _clear_matrix_changes():
	matrix_changed_cells.clear()

func _generate_matrix_quest():
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

			matrix_target = target
			matrix_row_constraints = row_constraints
			matrix_col_constraints = col_constraints
			matrix_quest = {
				"target_matrix": matrix_target,
				"row_constraints": matrix_row_constraints,
				"col_constraints": matrix_col_constraints
			}
			return

	# Fallback: all rows visible
	matrix_target = _random_matrix()
	matrix_row_constraints = _build_row_constraints(matrix_target)
	matrix_col_constraints = _build_col_constraints(matrix_target)
	matrix_quest = {
		"target_matrix": matrix_target,
		"row_constraints": matrix_row_constraints,
		"col_constraints": matrix_col_constraints
	}

func _random_matrix() -> Array:
	var matrix: Array = []
	for _r in range(MATRIX_SIZE):
		var row: Array = []
		for _c in range(MATRIX_SIZE):
			row.append(randi() % 2)
		matrix.append(row)
	return matrix

func _build_row_constraints(target: Array) -> Array:
	var constraints: Array = []
	for r in range(MATRIX_SIZE):
		var row_value = _row_value_from_bits(target[r])
		constraints.append({
			"hex_value": row_value,
			"is_hex_visible": true
		})
	return constraints

func _build_col_constraints(target: Array) -> Array:
	var constraints: Array = []
	for c in range(MATRIX_SIZE):
		var ones = 0
		for r in range(MATRIX_SIZE):
			ones += target[r][c]
		var parity = ones % 2
		constraints.append({
			"ones_count": ones,
			"parity": parity
		})
	return constraints

func _row_value_from_bits(bits: Array) -> int:
	var sum = 0
	for c in range(MATRIX_SIZE):
		if bits[c] == 1:
			sum += MATRIX_WEIGHTS[c]
	return sum

func _row_bits_from_value(value: int) -> Array:
	var bits: Array = []
	for c in range(MATRIX_SIZE):
		bits.append(1 if (value & MATRIX_WEIGHTS[c]) != 0 else 0)
	return bits

func _pick_row_visibility(row_constraints: Array, col_constraints: Array) -> Array:
	var rows = [0, 1, 2, 3, 4]
	for hide_count in [2, 1]:
		var combos = _combinations(rows, hide_count)
		combos.shuffle()
		for combo in combos:
			var visibility: Array = []
			for r in rows:
				visibility.append(not combo.has(r))
			if _count_matrix_solutions(row_constraints, col_constraints, visibility) == 1:
				return visibility
	return []

func _count_matrix_solutions(row_constraints: Array, col_constraints: Array, visibility: Array) -> int:
	_solver_row_constraints = row_constraints
	_solver_col_targets = []
	_solver_col_parity = []
	for c in range(MATRIX_SIZE):
		_solver_col_targets.append(col_constraints[c].ones_count)
		_solver_col_parity.append(col_constraints[c].parity)
	_solver_visibility = visibility
	_solver_col_sums = [0, 0, 0, 0, 0]
	_solver_solutions = 0

	_solver_backtrack(0)
	return _solver_solutions

func _solver_row_fits(bits: Array, row_idx: int) -> bool:
	var remaining = MATRIX_SIZE - (row_idx + 1)
	for c in range(MATRIX_SIZE):
		var new_sum = _solver_col_sums[c] + bits[c]
		if new_sum > _solver_col_targets[c]:
			return false
		if new_sum + remaining < _solver_col_targets[c]:
			return false
	return true

func _solver_backtrack(row_idx: int) -> void:
	if _solver_solutions > 1:
		return
	if row_idx >= MATRIX_SIZE:
		for c in range(MATRIX_SIZE):
			if _solver_col_sums[c] != _solver_col_targets[c]:
				return
			if (_solver_col_sums[c] % 2) != _solver_col_parity[c]:
				return
		_solver_solutions += 1
		return

	if _solver_visibility[row_idx]:
		var bits = _row_bits_from_value(_solver_row_constraints[row_idx].hex_value)
		if _solver_row_fits(bits, row_idx):
			for c in range(MATRIX_SIZE):
				_solver_col_sums[c] += bits[c]
			_solver_backtrack(row_idx + 1)
			for c in range(MATRIX_SIZE):
				_solver_col_sums[c] -= bits[c]
	else:
		for mask in range(32):
			var bits: Array = []
			for c in range(MATRIX_SIZE):
				var bit = 1 if (mask & MATRIX_WEIGHTS[c]) != 0 else 0
				bits.append(bit)
			if not _solver_row_fits(bits, row_idx):
				continue
			for c in range(MATRIX_SIZE):
				_solver_col_sums[c] += bits[c]
			_solver_backtrack(row_idx + 1)
			for c in range(MATRIX_SIZE):
				_solver_col_sums[c] -= bits[c]

func _combinations(items: Array, count: int) -> Array:
	var results: Array = []
	if count == 1:
		for item in items:
			results.append([item])
		return results
	if count == 2:
		for i in range(items.size()):
			for j in range(i + 1, items.size()):
				results.append([items[i], items[j]])
		return results
	return results
