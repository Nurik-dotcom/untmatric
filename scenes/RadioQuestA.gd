extends Control

# UI Nodes - V3 Hierarchy
@onready var wave_line = $SafeArea/MainVBox/OscPanel/OscLayer/WaveLine
@onready var mode_label = $SafeArea/MainVBox/Header/ModeLabel
@onready var timer_label = $SafeArea/MainVBox/Header/TimerLabel
@onready var forced_label = $SafeArea/MainVBox/Header/ForcedBadge
@onready var stability_label = $SafeArea/MainVBox/Header/StabilityLabel

@onready var task_main_label = $SafeArea/MainVBox/TaskCard/TaskVBox/TaskMain
@onready var task_sub_label = $SafeArea/MainVBox/TaskCard/TaskVBox/TaskHintRow/TaskSub

@onready var bit_knob = $SafeArea/MainVBox/ControlCard/ControlHBox/KnobStack/BitKnob
@onready var big_i_label = $SafeArea/MainVBox/ControlCard/ControlHBox/KnobStack/BigILabel
@onready var pow_label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/PowLabel
@onready var fit_label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/FitLabel
@onready var risk_label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/RiskRow/RiskLabel
@onready var risk_bar = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/RiskRow/RiskBar

@onready var sample_strip = $SafeArea/MainVBox/Bottom/SampleStrip
@onready var btn_hint = $SafeArea/MainVBox/Bottom/ActionsRow/BtnHint
@onready var btn_analyze = $SafeArea/MainVBox/Bottom/ActionsRow/BtnAnalyze
@onready var btn_capture = $SafeArea/MainVBox/Bottom/ActionsRow/BtnCapture
@onready var btn_next = $SafeArea/MainVBox/Bottom/ActionsRow/BtnNext
@onready var status_label = $SafeArea/MainVBox/Bottom/StatusLabel
@onready var btn_details_main = $SafeArea/MainVBox/Bottom/DetailsRow/BtnDetails

# Details Sheet
@onready var details_sheet = $DetailsSheet
@onready var dimmer = $Dimmer
@onready var details_text = $DetailsSheet/Margin/DetailsVBox/DetailsText
@onready var btn_close_details = $DetailsSheet/Margin/DetailsVBox/BtnCloseDetails

# Game State
var target_n: int = 0
var target_bits: int = 0
var current_bits: int = 1
var pool_type: String = "NORMAL"

enum Phase { TUNE, ANALYZE, DONE }
var trial_phase: Phase = Phase.TUNE

# Tracking Metrics
var analyze_count: int = 0
var knob_change_count: int = 0
var direction_change_count: int = 0
var cross_target_count: int = 0
var last_diff_sign: int = 0 # -1, 0, 1
var last_change_time: float = 0.0

# Time & Forced Sampling
var start_time: float = 0.0
var time_accum: float = 0.0
var first_action_timestamp: float = -1.0
var prev_time_to_first_action: float = 0.0

var is_timed_mode: bool = false
var forced_sampling: bool = false
var trial_duration: float = 30.0
var time_remaining: float = 0.0

# Analysis Timer
var analysis_timer: float = 0.0
const ANALYSIS_DURATION: float = 1.5

# Anchors
var anchor_countdown: int = 0
const ANCHOR_POOL = [100, 500, 1000]
const POWERS_OF_2 = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS = [10, 50, 2000]

# Trial
var hint_used: bool = false
var trial_history_ui: Array = []
var current_trial_idx: int = 0

const COLOR_GRAY = Color(0.2, 0.2, 0.2)
const COLOR_GREEN = Color(0, 1, 0)
const COLOR_YELLOW = Color(1, 1, 0)
const COLOR_RED = Color(1, 0, 0)

func _ready():
	GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0)

	_init_sampling_bar()
	anchor_countdown = randi_range(7, 10)

	details_sheet.visible = false
	dimmer.visible = false

	generate_task()

func _init_sampling_bar():
	trial_history_ui.clear()
	for slot in sample_strip.get_children():
		var bg = slot.get_node("BG")
		var mark = slot.get_node("AnchorMark")
		if bg and mark:
			bg.color = COLOR_GRAY
			mark.visible = false
			trial_history_ui.append(slot)
	current_trial_idx = 0

func mark_first_action():
	if first_action_timestamp < 0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

func _update_stability_ui(val, _change):
	stability_label.text = "%d%%" % int(val)
	var col = Color(0, 1, 0)
	if val < 30: col = Color(1, 0, 0)
	elif val < 70: col = Color(1, 1, 0)
	stability_label.add_theme_color_override("font_color", col)

func generate_task():
	trial_phase = Phase.TUNE
	hint_used = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	# Reset Metrics
	analyze_count = 0
	knob_change_count = 0
	direction_change_count = 0
	cross_target_count = 0
	last_diff_sign = 0
	last_change_time = start_time

	btn_capture.visible = true
	btn_capture.disabled = true # Disabled until Analyze
	btn_analyze.disabled = false
	btn_next.visible = false
	btn_hint.disabled = false
	bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP # Enable knob

	status_label.text = "СТАТУС: Настрой частоту, затем нажми «АНАЛИЗ»."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# Mode Logic
	forced_sampling = (prev_time_to_first_action > 10.0)
	is_timed_mode = forced_sampling

	forced_label.visible = forced_sampling
	if is_timed_mode:
		mode_label.text = "РЕЖИМ: НА ВРЕМЯ"
		timer_label.visible = true
		time_remaining = trial_duration
	else:
		mode_label.text = "РЕЖИМ: БЕЗ ВРЕМЕНИ"
		timer_label.visible = false

	# Select N
	if anchor_countdown == 0:
		target_n = ANCHOR_POOL.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi_range(7, 10)
	else:
		pool_type = "NORMAL"
		anchor_countdown -= 1
		var p = []
		p.append_array(POWERS_OF_2)
		p.append_array(TRAPS)
		target_n = p.pick_random()

	target_bits = ceil(log(target_n) / log(2.0))

	# Update Task UI
	task_main_label.text = "АЛФАВИТ: N = %d" % target_n

	# Reset Knob logic
	current_bits = 1
	bit_knob.value = 1

	# Initial UI update (doesn't count as action)
	_update_ui_state(1)

	# Reset timestamp again to be safe
	first_action_timestamp = -1.0

func _process(delta):
	time_accum += delta * 5.0

	if trial_phase != Phase.DONE and is_timed_mode:
		time_remaining -= delta
		var secs = int(ceil(time_remaining))
		timer_label.text = "00:%02d" % max(0, secs)
		if time_remaining <= 0:
			_force_fail_timeout()

	if trial_phase == Phase.ANALYZE:
		analysis_timer -= delta
		if analysis_timer <= 0:
			_complete_analysis()

	_update_oscilloscope()

func _update_oscilloscope():
	var points = PackedVector2Array()
	var layer = wave_line.get_parent()
	var layer_size = layer.size
	var width = layer_size.x
	var center_y = layer_size.y * 0.5

	wave_line.position = Vector2.ZERO

	var color = Color(0.2, 1.0, 0.2)

	# TUNE Phase: Static Noise (generic)
	if trial_phase == Phase.TUNE:
		# Use time-based seed but not dependent on bits
		for x in range(0, int(width) + 10, 5):
			# Just noise
			var noise = randf_range(-40.0, 40.0)
			points.append(Vector2(x, center_y + noise))

	# ANALYZE / DONE Phase: True Result
	else:
		var noise_amp = 0.0
		if current_bits < target_bits:
			var diff = target_bits - current_bits
			var max_amp = layer_size.y * 0.35
			noise_amp = (float(diff) / target_bits) * max_amp

		for x in range(0, int(width) + 10, 5):
			var t = (float(x) / width) * 10.0 + time_accum
			var base_y = sin(t) * (layer_size.y * 0.25)
			var noise = randf_range(-noise_amp, noise_amp)
			points.append(Vector2(x, center_y + base_y + noise))

	wave_line.default_color = color
	wave_line.points = points

# Called by Knob signal
func apply_user_bits(i: int):
	if trial_phase != Phase.TUNE: return # Should be blocked by mouse_filter, but safe check

	mark_first_action()

	# Metrics Tracking
	knob_change_count += 1
	var current_diff_sign = sign(i - current_bits)
	if current_diff_sign != 0:
		if last_diff_sign != 0 and current_diff_sign != last_diff_sign:
			direction_change_count += 1
		last_diff_sign = current_diff_sign

	# Check crossing target (basic heuristic: sign of (bits - target) flipped)
	var old_side = sign(current_bits - target_bits)
	var new_side = sign(i - target_bits)
	if old_side != 0 and new_side != 0 and old_side != new_side:
		cross_target_count += 1

	last_change_time = Time.get_ticks_msec() / 1000.0
	current_bits = i

	# Reset Analyze state
	btn_capture.disabled = true

	_update_ui_state(i)

func _update_ui_state(i: int):
	# Update Labels
	big_i_label.text = "i = %d бит" % i
	var pow_val = int(pow(2, i))
	pow_label.text = "2^i = %d" % pow_val

	var is_fit = (pow_val >= target_n)
	var is_minimal = (i == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	if is_fit:
		fit_label.text = "ПОМЕЩАЕТСЯ: ДА"
		fit_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		fit_label.text = "ПОМЕЩАЕТСЯ: НЕТ"
		fit_label.add_theme_color_override("font_color", Color(1, 0, 0))

	if is_overkill:
		var excess = i - target_bits
		var risk_pct = min(100, excess * 25.0)
		risk_bar.value = risk_pct
		risk_label.text = "РИСК: ВЫСОКИЙ" if risk_pct >= 80 else ("РИСК: СРЕДНИЙ" if risk_pct >= 40 else "РИСК: НИЗКИЙ")
		var r_col = Color(1, 0, 0) if risk_pct >= 80 else (Color(1, 1, 0) if risk_pct >= 40 else Color(0, 1, 0))
		risk_label.add_theme_color_override("font_color", r_col)
		risk_bar.modulate = r_col
	else:
		risk_label.text = "РИСК: НЕТ"
		risk_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		risk_bar.value = 0
		risk_bar.modulate = Color(0.2, 0.2, 0.2)

	# Update Details
	details_text.text = "N: %d\nЦель i: %d\n2^i: %d\nМинимально: %s\nЯкорная: %s\nРежим: %s" % [
		target_n,
		target_bits,
		pow_val,
		"ДА" if is_minimal else "НЕТ",
		"ДА" if pool_type == "ANCHOR" else "НЕТ",
		"TIMED" if is_timed_mode else "UNTIMED"
	]

func _on_analyze_pressed():
	mark_first_action()
	if trial_phase != Phase.TUNE: return

	analyze_count += 1
	trial_phase = Phase.ANALYZE
	analysis_timer = ANALYSIS_DURATION

	# Lock Inputs
	bit_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_analyze.disabled = true
	btn_capture.disabled = true
	btn_hint.disabled = true

	status_label.text = "СТАТУС: Снятие показаний..."
	status_label.add_theme_color_override("font_color", Color(1, 1, 0))

func _complete_analysis():
	# Unlock for Capture or Retuning
	trial_phase = Phase.TUNE # Logically we are back to tuning state, but now we know result
	# Actually, visual spec says: show result for 1.5s then...
	# "После анализа: ... ЗАФИКСИРОВАТЬ enabled".
	# If player moves knob, Capture disabled again.

	# We can stay in TUNE phase but just keep the visual result?
	# "В режиме TUNE: всегда статический шум".
	# If we go back to TUNE immediately, the osc will flicker back to noise.
	# Let's say we enter a sub-state "POST_ANALYZE" or just handle it in update_osc.
	# "в ANALYZE на 2 сек реальный сигнал, потом обратно в TUNE".
	# Okay, so visual goes back to noise. But Capture is enabled.

	bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_analyze.disabled = false
	btn_capture.disabled = false
	btn_hint.disabled = false

	# Set Status based on current result
	var pow_val = pow(2, current_bits)
	var is_fit = (pow_val >= target_n)
	var is_minimal = (current_bits == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	if not is_fit:
		status_label.text = "СТАТУС: Связь сорвана. Недостаточно бит."
		status_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif is_minimal:
		status_label.text = "СТАТУС: Частота стабилизирована."
		status_label.add_theme_color_override("font_color", Color(0, 1, 0))
	elif is_overkill:
		status_label.text = "СТАТУС: Сигнал чистый, но избыточная битность (риск)."
		status_label.add_theme_color_override("font_color", Color(1, 1, 0))

func _on_capture_pressed():
	mark_first_action()
	if trial_phase != Phase.TUNE: return # Or post-analyze
	_finish_trial(false)

func _force_fail_timeout():
	if trial_phase == Phase.DONE: return
	_finish_trial(true)

func _finish_trial(is_timeout: bool):
	trial_phase = Phase.DONE
	bit_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_capture.visible = false
	btn_analyze.disabled = true
	btn_next.visible = true
	btn_hint.disabled = true

	var end_time = Time.get_ticks_msec() / 1000.0
	var duration = end_time - start_time

	var pow_val = pow(2, current_bits)
	var is_fit = (pow_val >= target_n)
	var is_minimal = (current_bits == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	if is_timeout:
		is_fit = false
		is_minimal = false
		is_overkill = false
		status_label.text = "СТАТУС: ВРЕМЯ ИСТЕКЛО."
		status_label.add_theme_color_override("font_color", Color(1, 0, 0))

	# Certainty Logic
	var is_low_certainty = false
	if cross_target_count >= 2 or direction_change_count >= 3 or analyze_count >= 3 or knob_change_count >= 6:
		is_low_certainty = true

	# Payload
	if first_action_timestamp > 0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration

	var payload = {
		"quest_id": "radio_intercept",
		"stage_id": "A",
		"match_key": "RI_A_%s_%s_N%d" % [("TIMED" if is_timed_mode else "UNTIMED"), pool_type, target_n],
		"target_n": target_n,
		"user_bits": current_bits,
		"target_bits": target_bits,
		"is_fit": is_fit,
		"is_minimal": is_minimal,
		"is_overkill": is_overkill,
		"is_correct": is_fit,
		"elapsed_ms": duration * 1000.0,
		"time_to_first_action_ms": prev_time_to_first_action * 1000.0,
		"mode": "TIMED" if is_timed_mode else "UNTIMED",
		"forced_sampling": forced_sampling,
		"hint_used": hint_used,
		"analyze_count": analyze_count,
		"knob_change_count": knob_change_count,
		"direction_change_count": direction_change_count,
		"cross_target_count": cross_target_count,
		"certainty": "low" if is_low_certainty else "high",
		"analysis_required": true,
		"valid_for_diagnostics": true,
		"valid_for_mastery": (not hint_used and is_minimal and not is_low_certainty)
	}

	GlobalMetrics.register_trial(payload)

	# Sampling Bar Update
	if current_trial_idx < trial_history_ui.size():
		var slot = trial_history_ui[current_trial_idx]
		var bg = slot.get_node("BG")
		var mark = slot.get_node("AnchorMark")

		if not is_fit: bg.color = COLOR_RED
		elif is_minimal: bg.color = COLOR_GREEN
		elif is_overkill: bg.color = COLOR_YELLOW

		if pool_type == "ANCHOR":
			mark.visible = true

		current_trial_idx = (current_trial_idx + 1) % 7

func _on_next_pressed():
	bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP
	generate_task()

func _on_hint_pressed():
	mark_first_action()
	hint_used = true
	status_label.text = "ПОДСКАЗКА: Формула N = 2^i. Ищи степень двойки >= N."
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_toggle():
	mark_first_action()
	var is_open = not details_sheet.visible
	details_sheet.visible = is_open
	dimmer.visible = is_open
	btn_details_main.text = "Скрыть ▴" if is_open else "Подробнее ▾"

func _on_dimmer_gui_input(event):
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_on_details_toggle()
