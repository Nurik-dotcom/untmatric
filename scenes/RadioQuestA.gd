extends Control

# UI Nodes
@onready var wave_line = $OscilloscopeLayer/WaveLine
@onready var title_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/TitleLabel
@onready var mode_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/ModeLabel
@onready var forced_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/ForcedLabel
@onready var timer_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/TimerLabel
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel

@onready var target_info_label = $MainLayout/WorkArea/LeftPanel/Margin/VBox/TargetInfo

@onready var current_bits_label = $MainLayout/WorkArea/RightPanel/Margin/VBox/CurrentBitsLabel
@onready var bit_slider = $MainLayout/WorkArea/RightPanel/Margin/VBox/BitSlider
@onready var val_n = $MainLayout/WorkArea/RightPanel/Margin/VBox/GridContainer/V_N
@onready var val_target = $MainLayout/WorkArea/RightPanel/Margin/VBox/GridContainer/V_Target
@onready var val_pow = $MainLayout/WorkArea/RightPanel/Margin/VBox/GridContainer/V_Pow
@onready var val_fit = $MainLayout/WorkArea/RightPanel/Margin/VBox/GridContainer/V_Fit
@onready var val_min = $MainLayout/WorkArea/RightPanel/Margin/VBox/GridContainer/V_Min

@onready var risk_label = $MainLayout/WorkArea/RightPanel/Margin/VBox/RiskLabel
@onready var risk_bar = $MainLayout/WorkArea/RightPanel/Margin/VBox/RiskBar

@onready var lamp_warmup = $MainLayout/WorkArea/RightPanel/Margin/VBox/LampsBox/LampWarmup
@onready var lamp_ready = $MainLayout/WorkArea/RightPanel/Margin/VBox/LampsBox/LampReady
@onready var lamp_lost = $MainLayout/WorkArea/RightPanel/Margin/VBox/LampsBox/LampLost
@onready var lamp_overkill = $MainLayout/WorkArea/RightPanel/Margin/VBox/LampsBox/LampOverkill

@onready var sampling_bar = $MainLayout/BottomPanel/Margin/VBox/SamplingBar
@onready var btn_hint = $MainLayout/BottomPanel/Margin/VBox/ControlsBox/BtnHint
@onready var btn_capture = $MainLayout/BottomPanel/Margin/VBox/ControlsBox/BtnCapture
@onready var btn_next = $MainLayout/BottomPanel/Margin/VBox/ControlsBox/BtnNext
@onready var status_label = $MainLayout/BottomPanel/Margin/VBox/StatusLabel

# Game State
var target_n: int = 0
var target_bits: int = 0
var current_bits: int = 1
var pool_type: String = "NORMAL"

# Time & Forced Sampling
var start_time: float = 0.0
var time_accum: float = 0.0
var first_action_timestamp: float = -1.0
var prev_time_to_first_action: float = 0.0

var is_timed_mode: bool = false
var forced_sampling: bool = false
var trial_duration: float = 30.0 # for timed mode
var time_remaining: float = 0.0

# Anchors
var anchor_countdown: int = 0
const ANCHOR_POOL = [100, 500, 1000]
const POWERS_OF_2 = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS = [10, 50, 1000, 2000] # 100, 500 are anchors

# Trial
var trial_active: bool = false
var hint_used: bool = false
var trial_history_ui: Array = [] # Stores trial slot Controls
var current_trial_idx: int = 0

const COLOR_GRAY = Color(0.2, 0.2, 0.2)
const COLOR_GREEN = Color(0, 1, 0)
const COLOR_YELLOW = Color(1, 1, 0)
const COLOR_RED = Color(1, 0, 0)
const COLOR_DARK = Color(0.1, 0.0, 0.1)

func _ready():
	GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0)

	# Center osc
	wave_line.position.y = get_viewport_rect().size.y * 0.4

	# Init UI
	_init_sampling_bar()
	anchor_countdown = randi_range(7, 10)

	generate_task()

func _init_sampling_bar():
	trial_history_ui.clear()
	for slot in sampling_bar.get_children():
		var bg = slot.get_node("BG")
		var mark = slot.get_node("AnchorMark")
		if bg and mark:
			bg.color = COLOR_GRAY
			mark.visible = false
			trial_history_ui.append(slot)
	current_trial_idx = 0

func _update_stability_ui(val, _change):
	stability_label.text = "СТАБИЛЬНОСТЬ: %d%%" % int(val)
	var col = Color(0, 1, 0)
	if val < 30: col = Color(1, 0, 0)
	elif val < 70: col = Color(1, 1, 0)
	stability_label.add_theme_color_override("font_color", col)

func generate_task():
	trial_active = true
	hint_used = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	# Reset UI
	btn_capture.visible = true
	btn_capture.disabled = false
	btn_next.visible = false
	btn_hint.disabled = false
	bit_slider.editable = true
	status_label.text = "СТАТУС: ОЖИДАНИЕ ВВОДА..."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 1. Determine Mode (Timed/Forced)
	forced_sampling = (prev_time_to_first_action > 10.0)
	is_timed_mode = forced_sampling # Simple logic for now

	forced_label.visible = forced_sampling
	if is_timed_mode:
		mode_label.text = "РЕЖИМ: НА ВРЕМЯ"
		timer_label.visible = true
		time_remaining = trial_duration
	else:
		mode_label.text = "РЕЖИМ: БЕЗ ВРЕМЕНИ"
		timer_label.visible = false

	# 2. Select N (Anchor logic)
	anchor_countdown -= 1
	pool_type = "NORMAL"

	if anchor_countdown <= 0:
		target_n = ANCHOR_POOL.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi_range(7, 10)
	else:
		# Mix powers and traps
		var p = []
		p.append_array(POWERS_OF_2)
		p.append_array(TRAPS)
		target_n = p.pick_random()

	# Calculate Target
	target_bits = ceil(log(target_n) / log(2.0))

	# Update Briefing
	target_info_label.text = "Обнаружен алфавит:\nN = %d символов" % target_n
	val_n.text = str(target_n)
	val_target.text = str(target_bits)

	# Reset Slider
	current_bits = 1
	bit_slider.value = 1
	_update_decoder_ui()

func _process(delta):
	time_accum += delta * 5.0

	if trial_active and is_timed_mode:
		time_remaining -= delta
		var secs = int(ceil(time_remaining))
		timer_label.text = "ОСТАЛОСЬ: 00:%02d" % max(0, secs)
		if time_remaining <= 0:
			_force_fail_timeout()

	_update_oscilloscope()

func _update_oscilloscope():
	var points = PackedVector2Array()
	var width = get_viewport_rect().size.x

	# Logic:
	# Less bits -> Noise
	# Correct bits -> Clean
	# More bits -> Clean (but Risk meter grows)

	var noise_amp = 0.0
	var color = Color(0.2, 1.0, 0.2)

	if current_bits < target_bits:
		var diff = target_bits - current_bits
		# Noise normalized to height (approx 300px half-height)
		# Limit 0.35h = 100px
		noise_amp = (float(diff) / target_bits) * 100.0
		color = Color(0.2, 1.0, 0.2) # Still green, just noisy
	else:
		# Clean wave
		noise_amp = 0.0
		color = Color(0.2, 1.0, 0.2)

	wave_line.default_color = color

	for x in range(0, int(width) + 10, 5):
		var t = (float(x) / width) * 10.0 + time_accum
		var base_y = sin(t) * 100.0
		var noise = randf_range(-noise_amp, noise_amp)
		points.append(Vector2(x, base_y + noise))

	wave_line.points = points

func _on_bit_slider_value_changed(value):
	if first_action_timestamp < 0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

	current_bits = int(value)
	_update_decoder_ui()

func _update_decoder_ui():
	current_bits_label.text = "Глубина i = %d бит" % current_bits

	var pow_val = pow(2, current_bits)
	val_pow.text = str(pow_val)

	var is_fit = (pow_val >= target_n)
	var is_minimal = (current_bits == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	val_fit.text = "ДА" if is_fit else "НЕТ"
	val_fit.add_theme_color_override("font_color", Color(0, 1, 0) if is_fit else Color(1, 0, 0))

	val_min.text = "ДА" if is_minimal else "НЕТ"

	# Lamps
	_reset_lamps()
	if not is_fit:
		_set_lamp(lamp_lost, Color(1, 0, 0))
	elif is_minimal:
		_set_lamp(lamp_ready, Color(0, 1, 0))
	elif is_overkill:
		_set_lamp(lamp_overkill, Color(1, 1, 0))

	# Risk Calculation
	if is_overkill:
		var excess = current_bits - target_bits
		# e.g. +1 bit = 25%, +4 bits = 100%
		var risk_pct = min(100, excess * 25.0)
		risk_bar.value = risk_pct
		if risk_pct < 40:
			risk_label.text = "РИСК: НИЗКИЙ"
			risk_bar.modulate = Color(0, 1, 0)
		elif risk_pct < 80:
			risk_label.text = "РИСК: СРЕДНИЙ"
			risk_bar.modulate = Color(1, 1, 0)
		else:
			risk_label.text = "РИСК: ВЫСОКИЙ"
			risk_bar.modulate = Color(1, 0, 0)
	else:
		risk_bar.value = 0
		risk_label.text = "РИСК: ОТСУТСТВУЕТ"
		risk_bar.modulate = Color(0.2, 0.2, 0.2)

func _reset_lamps():
	lamp_warmup.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	lamp_ready.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	lamp_lost.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	lamp_overkill.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

func _set_lamp(lbl, col):
	lbl.add_theme_color_override("font_color", col)

func _on_capture_pressed():
	if not trial_active: return
	_finish_trial(false)

func _force_fail_timeout():
	if not trial_active: return
	# Timeout is considered incorrect/fail
	_finish_trial(true)

func _finish_trial(is_timeout: bool):
	trial_active = false
	bit_slider.editable = false
	btn_capture.disabled = true
	btn_hint.disabled = true
	btn_next.visible = true

	var end_time = Time.get_ticks_msec() / 1000.0
	var duration = end_time - start_time

	# Calculate logic
	var pow_val = pow(2, current_bits)
	var is_fit = (pow_val >= target_n)
	var is_minimal = (current_bits == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	if is_timeout:
		is_fit = false
		is_minimal = false
		is_overkill = false

	# Status Text
	if not is_fit:
		status_label.text = "СТАТУС: Связь сорвана. Недостаточно бит для кодирования алфавита."
		status_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif is_minimal:
		status_label.text = "СТАТУС: Частота стабилизирована. Канал чистый."
		status_label.add_theme_color_override("font_color", Color(0, 1, 0))
	elif is_overkill:
		status_label.text = "СТАТУС: Сигнал чистый, но избыточная битность (риск демаскировки)."
		status_label.add_theme_color_override("font_color", Color(1, 1, 0))

	# Update Sampling Bar UI
	if current_trial_idx < trial_history_ui.size():
		var slot = trial_history_ui[current_trial_idx]
		var bg = slot.get_node("BG")
		var mark = slot.get_node("AnchorMark")

		if not is_fit:
			bg.color = COLOR_RED
		elif is_minimal:
			bg.color = COLOR_GREEN
		elif is_overkill:
			bg.color = COLOR_YELLOW

		# Show Anchor Mark if applicable
		if pool_type == "ANCHOR":
			mark.visible = true

		current_trial_idx = (current_trial_idx + 1) % 7

	# Calculate Metrics vars
	if first_action_timestamp > 0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration # No action taken

	# Payload
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
		"is_correct": is_fit, # For backward compat logic
		"elapsed_ms": duration * 1000.0,
		"time_to_first_action_ms": prev_time_to_first_action * 1000.0,
		"mode": "TIMED" if is_timed_mode else "UNTIMED",
		"forced_sampling": forced_sampling,
		"hint_used": hint_used,
		"valid_for_diagnostics": true, # Simplified for now
		"valid_for_mastery": (not hint_used and is_minimal) # Strict mastery
	}

	GlobalMetrics.register_trial(payload)

func _on_next_pressed():
	generate_task()

func _on_hint_pressed():
	hint_used = true
	var hint_text = "ПОДСКАЗКА: N = 2^i. Если N не степень двойки, выбирай минимальное i, чтобы 2^i >= N.\n(Внимание: статус мастерства снижен)"
	status_label.text = hint_text
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
