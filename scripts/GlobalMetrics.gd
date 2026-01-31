extends Node

# LogicEngine v6.2 Specification

@warning_ignore("unused_signal")
signal stability_changed(new_value, change)
@warning_ignore("unused_signal")
signal shield_triggered(shield_name, penalty)
@warning_ignore("unused_signal")
signal hint_unlocked(level, text)

# Core Resources
var stability: float = 100.0
var current_level_index: int = 0
var current_mode: String = "DEC" # DEC, OCT, HEX
var selected_complexity: String = "A"

# Anti-Spam / Shields
var check_timestamps: Array[float] = []
var last_checked_bits: Array = [] # History of bit arrays
var blocked_until: float = 0.0

# Level Configuration (Complexity A)
# 15 Levels: 1-5 DEC, 6-10 OCT, 11-15 HEX
const MAX_LEVELS = 15

func _ready():
	reset_engine()

func reset_engine():
	stability = 100.0
	current_level_index = 0
	check_timestamps.clear()
	last_checked_bits.clear()
	blocked_until = 0.0

func start_level(index: int):
	current_level_index = index
	# Determine mode based on level index (0-based)
	if index < 5:
		current_mode = "DEC"
	elif index < 10:
		current_mode = "OCT"
	else:
		current_mode = "HEX"

	# Reset shields for the new level/attempt if desired,
	# but typically stability persists or resets per level depending on design.
	# TDD says: "Stability begins with 100% on each level"
	stability = 100.0
	emit_signal("stability_changed", stability, 0)
	check_timestamps.clear()
	last_checked_bits.clear()

# Returns (success: bool, info: Dictionary)
func check_solution(target_val: int, input_val: int) -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time < blocked_until:
		return {
			"success": false,
			"error": "SHIELD_ACTIVE",
			"message": "Система перегрета. Ждите...",
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
			"message": "Блокировка: Слишком часто",
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
			"message": "Доступ разрешен",
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
			"message": "Ошибка доступа. HD: %d" % hd
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
	if last_checked_bits.size() < 3: return false

	# Check last 3 inputs. If difference between consecutive inputs is small...
	# TDD: "If 3 checks in a row player changes < 3 unique bits"
	# Let's look at the last input only for simplicity or track full history
	var last_input = last_checked_bits[-1]
	var diff = _calculate_hamming_distance(current_input, last_input)

	# This is a simplified logic. Real logic would track the last 3 checks.
	# For now, if change is small (<3 bits) and we are wrong, flag it.
	if diff < 3:
		return true
	return false

func _record_input_history(val: int):
	last_checked_bits.append(val)
	if last_checked_bits.size() > 10:
		last_checked_bits.pop_front()

func _generate_hints(target: int, input: int, _hd: int) -> Dictionary:
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
