extends Control

# UI Nodes - Re-mapped for Mobile Layout
@onready var wave_line = $OscilloscopeLayer/WaveLine
@onready var mode_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/ModeInfoBox/ModeLabel
@onready var timer_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/ModeInfoBox/TimerLabel
@onready var forced_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/ModeInfoBox/ForcedLabel
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel

@onready var big_target_n = $OscilloscopeLayer/TaskOverlay/BigTargetN
@onready var instruction_label = $OscilloscopeLayer/TaskOverlay/Instruction

@onready var big_bits_label = $MainLayout/ControlsZone/BigBitsLabel
@onready var big_pow_label = $MainLayout/ControlsZone/FeedbackRow/BigPowLabel
@onready var big_fit_label = $MainLayout/ControlsZone/FeedbackRow/BigFitLabel
@onready var big_risk_label = $MainLayout/ControlsZone/BigRiskLabel
@onready var bit_slider = $MainLayout/ControlsZone/SliderContainer/BitSlider
@onready var btn_details = $MainLayout/ControlsZone/DetailsBtnContainer/BtnDetails

# Detailed Sheet Nodes
@onready var details_sheet = $DetailsSheet
@onready var dimmer = $Dimmer
@onready var val_n = $DetailsSheet/Margin/VBox/Grid/V_N
@onready var val_target = $DetailsSheet/Margin/VBox/Grid/V_Target
@onready var val_pow = $DetailsSheet/Margin/VBox/Grid/V_Pow
@onready var val_min = $DetailsSheet/Margin/VBox/Grid/V_Min
@onready var val_anchor = $DetailsSheet/Margin/VBox/Grid/V_Anchor

@onready var sampling_bar = $MainLayout/ActionsZone/SamplingBar
@onready var btn_hint = $MainLayout/ActionsZone/ButtonsRow/BtnHint
@onready var btn_capture = $MainLayout/ActionsZone/ButtonsRow/BtnCapture
@onready var btn_next = $MainLayout/ActionsZone/ButtonsRow/BtnNext
@onready var status_label = $MainLayout/ActionsZone/StatusLabel

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
var trial_duration: float = 30.0
var time_remaining: float = 0.0

# Anchors
var anchor_countdown: int = 0
const ANCHOR_POOL = [100, 500, 1000]
const POWERS_OF_2 = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS = [10, 50, 1000, 2000]

# Trial
var trial_active: bool = false
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

	# Center osc roughly in its layer (handled by layout, but y offset helps)
	# WaveLine is in OscilloscopeLayer which is Top-to-Center.
	# Center Y is roughly 150px relative to that control if it's ~300px high.

	_init_sampling_bar()
	anchor_countdown = randi_range(7, 10)

	details_sheet.visible = false
	dimmer.visible = false

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
	stability_label.text = "%d%%" % int(val)
	var col = Color(0, 1, 0)
	if val < 30: col = Color(1, 0, 0)
	elif val < 70: col = Color(1, 1, 0)
	stability_label.add_theme_color_override("font_color", col)

func generate_task():
	trial_active = true
	hint_used = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	btn_capture.visible = true
	btn_capture.disabled = false
	btn_next.visible = false
	btn_hint.disabled = false
	bit_slider.editable = true
	status_label.text = "СТАТУС: ОЖИДАНИЕ ВВОДА..."
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
	anchor_countdown -= 1
	pool_type = "NORMAL"

	if anchor_countdown <= 0:
		target_n = ANCHOR_POOL.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi_range(7, 10)
	else:
		var p = []
		p.append_array(POWERS_OF_2)
		p.append_array(TRAPS)
		target_n = p.pick_random()

	target_bits = ceil(log(target_n) / log(2.0))

	# Update Displays
	big_target_n.text = "АЛФАВИТ: N = %d" % target_n
	val_n.text = str(target_n)
	val_target.text = str(target_bits)
	val_anchor.text = "ДА" if pool_type == "ANCHOR" else "НЕТ"

	current_bits = 1
	bit_slider.value = 1
	_update_decoder_ui()

func _process(delta):
	time_accum += delta * 5.0

	if trial_active and is_timed_mode:
		time_remaining -= delta
		var secs = int(ceil(time_remaining))
		timer_label.text = "00:%02d" % max(0, secs)
		if time_remaining <= 0:
			_force_fail_timeout()

	_update_oscilloscope()

func _update_oscilloscope():
	var points = PackedVector2Array()
	var width = get_viewport_rect().size.x

	var noise_amp = 0.0
	var color = Color(0.2, 1.0, 0.2)

	if current_bits < target_bits:
		var diff = target_bits - current_bits
		noise_amp = (float(diff) / target_bits) * 80.0 # Adjusted amplitude for new height

	wave_line.default_color = color

	# Draw slightly lower resolution for performance if needed, but 5 step is fine
	for x in range(0, int(width) + 10, 5):
		var t = (float(x) / width) * 10.0 + time_accum
		var base_y = sin(t) * 80.0 # Amplitude 80
		var noise = randf_range(-noise_amp, noise_amp)
		points.append(Vector2(x, base_y + noise))

	wave_line.points = points

func _on_bit_slider_value_changed(value):
	if first_action_timestamp < 0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0
	current_bits = int(value)
	_update_decoder_ui()

func _update_decoder_ui():
	# Big UI
	big_bits_label.text = "i = %d бит" % current_bits
	var pow_val = pow(2, current_bits)
	big_pow_label.text = "2^i = %d" % pow_val

	var is_fit = (pow_val >= target_n)
	var is_minimal = (current_bits == target_bits)
	var is_overkill = (is_fit and not is_minimal)

	if is_fit:
		big_fit_label.text = "ПОМЕЩАЕТСЯ: ДА"
		big_fit_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		big_fit_label.text = "ПОМЕЩАЕТСЯ: НЕТ"
		big_fit_label.add_theme_color_override("font_color", Color(1, 0, 0))

	# Risk UI
	if is_overkill:
		var excess = current_bits - target_bits
		var risk_pct = min(100, excess * 25.0)
		if risk_pct < 40:
			big_risk_label.text = "РИСК: НИЗКИЙ"
			big_risk_label.add_theme_color_override("font_color", Color(0, 1, 0))
		elif risk_pct < 80:
			big_risk_label.text = "РИСК: СРЕДНИЙ"
			big_risk_label.add_theme_color_override("font_color", Color(1, 1, 0))
		else:
			big_risk_label.text = "РИСК: ВЫСОКИЙ"
			big_risk_label.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		big_risk_label.text = ""

	# Detailed Sheet UI
	val_pow.text = str(pow_val)
	val_min.text = "ДА" if is_minimal else "НЕТ"

func _on_capture_pressed():
	if not trial_active: return
	_finish_trial(false)

func _force_fail_timeout():
	if not trial_active: return
	_finish_trial(true)

func _finish_trial(is_timeout: bool):
	trial_active = false
	bit_slider.editable = false
	btn_capture.visible = false
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

	if not is_fit:
		status_label.text = "СТАТУС: Связь сорвана. Недостаточно бит."
		status_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif is_minimal:
		status_label.text = "СТАТУС: Частота стабилизирована. Канал чистый."
		status_label.add_theme_color_override("font_color", Color(0, 1, 0))
	elif is_overkill:
		status_label.text = "СТАТУС: Сигнал чистый, но есть риск демаскировки."
		status_label.add_theme_color_override("font_color", Color(1, 1, 0))

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
		"valid_for_diagnostics": true,
		"valid_for_mastery": (not hint_used and is_minimal)
	}

	GlobalMetrics.register_trial(payload)

func _on_next_pressed():
	generate_task()

func _on_hint_pressed():
	hint_used = true
	status_label.text = "ПОДСКАЗКА: Формула N = 2^i. Ищи степень двойки >= N."
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_toggle():
	var is_open = not details_sheet.visible
	details_sheet.visible = is_open
	dimmer.visible = is_open
	btn_details.text = "Скрыть ▴" if is_open else "Подробнее ▾"

func _on_dimmer_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		_on_details_toggle() # Close on click
