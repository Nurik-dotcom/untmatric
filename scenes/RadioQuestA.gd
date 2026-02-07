extends Control

const ANCHOR_POOL := [100, 500, 1000]
const POWERS_OF_2 := [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS := [10, 50, 2000]
const MAX_NOISE := 24.0
const SAMPLE_SLOTS := 7

const COLOR_GRAY := Color(0.2, 0.2, 0.2)
const COLOR_GREEN := Color(0.0, 1.0, 0.0)
const COLOR_YELLOW := Color(1.0, 1.0, 0.0)
const COLOR_RED := Color(1.0, 0.0, 0.0)

@onready var wave_line: Line2D = $SafeArea/MainVBox/OscPanel/OscLayer/WaveLine
@onready var mode_label: Label = $SafeArea/MainVBox/Header/ModeLabel
@onready var timer_label: Label = $SafeArea/MainVBox/Header/TimerLabel
@onready var forced_label: Label = $SafeArea/MainVBox/Header/ForcedBadge
@onready var stability_label: Label = $SafeArea/MainVBox/Header/StabilityLabel

@onready var task_main_label: Label = $SafeArea/MainVBox/TaskCard/TaskVBox/TaskMain
@onready var task_sub_label: Label = $SafeArea/MainVBox/TaskCard/TaskVBox/TaskHintRow/TaskSub

@onready var bit_knob: Control = $SafeArea/MainVBox/ControlCard/ControlHBox/KnobStack/BitKnob
@onready var big_i_label: Label = $SafeArea/MainVBox/ControlCard/ControlHBox/KnobStack/BigILabel
@onready var pow_label: Label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/PowLabel
@onready var fit_label: Label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/FitLabel
@onready var risk_label: Label = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/RiskRow/RiskLabel
@onready var risk_bar: ProgressBar = $SafeArea/MainVBox/ControlCard/ControlHBox/ReadoutStack/RiskRow/RiskBar

@onready var sample_strip: HBoxContainer = $SafeArea/MainVBox/Bottom/SampleStrip
@onready var btn_hint: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnHint
@onready var btn_capture: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnCapture
@onready var btn_next: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnNext
@onready var status_label: Label = $SafeArea/MainVBox/Bottom/StatusLabel
@onready var btn_details_main: Button = $SafeArea/MainVBox/Bottom/DetailsRow/BtnDetails

@onready var details_sheet: PanelContainer = $DetailsSheet
@onready var dimmer: ColorRect = $Dimmer
@onready var details_text: Label = $DetailsSheet/Margin/DetailsVBox/DetailsText

var target_n: int = 0
var target_bits: int = 0
var current_bits: int = 1
var pool_type: String = "NORMAL"

var start_time: float = 0.0
var first_action_timestamp: float = -1.0
var prev_time_to_first_action: float = 0.0

var trial_active: bool = false
var hint_used: bool = false
var forced_sampling: bool = false
var is_timed_mode: bool = false
var trial_duration: float = 30.0
var time_remaining: float = 0.0

var current_trial_idx: int = 0
var anchor_countdown: int = 0
var osc_phase: float = 0.0

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0.0)

	_init_sampling_bar()
	anchor_countdown = randi_range(7, 10)
	details_sheet.visible = false
	dimmer.visible = false
	generate_task()

func _process(delta: float) -> void:
	osc_phase += delta * 5.0
	_update_oscilloscope()

	if trial_active and is_timed_mode:
		time_remaining -= delta
		var secs: int = int(ceil(time_remaining))
		timer_label.text = "00:%02d" % maxi(0, secs)
		if time_remaining <= 0.0:
			_force_fail_timeout()

func _init_sampling_bar() -> void:
	for slot in sample_strip.get_children():
		var bg := slot.get_node_or_null("BG") as ColorRect
		var mark := slot.get_node_or_null("AnchorMark") as Label
		if bg:
			bg.color = COLOR_GRAY
		if mark:
			mark.visible = false
	current_trial_idx = 0

func _update_stability_ui(val: float, _change: float) -> void:
	stability_label.text = "%d%%" % int(val)
	var col := Color(0.0, 1.0, 0.0)
	if val < 30.0:
		col = Color(1.0, 0.0, 0.0)
	elif val < 70.0:
		col = Color(1.0, 1.0, 0.0)
	stability_label.add_theme_color_override("font_color", col)

func mark_first_action() -> void:
	if first_action_timestamp < 0.0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

func generate_task() -> void:
	trial_active = true
	hint_used = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	btn_capture.visible = true
	btn_capture.disabled = false
	btn_next.visible = false
	btn_hint.disabled = false

	status_label.text = "STATUS: Configure bits and capture signal."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	forced_sampling = prev_time_to_first_action > 10.0
	is_timed_mode = forced_sampling
	forced_label.visible = forced_sampling

	if is_timed_mode:
		mode_label.text = "MODE: TIMED"
		timer_label.visible = true
		time_remaining = trial_duration
	else:
		mode_label.text = "MODE: NORMAL"
		timer_label.visible = false

	if anchor_countdown == 0:
		target_n = ANCHOR_POOL.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi_range(7, 10)
	else:
		pool_type = "NORMAL"
		anchor_countdown -= 1
		var pool: Array[int] = []
		pool.append_array(POWERS_OF_2)
		pool.append_array(TRAPS)
		target_n = pool.pick_random()

	target_bits = int(ceil(log(float(target_n)) / log(2.0)))
	task_main_label.text = "ALPHABET POWER: N = %d" % target_n
	task_sub_label.text = "Use Hartley: N = 2^i"

	current_bits = 1
	bit_knob.set("value", 1)
	apply_user_bits(1, false)
	first_action_timestamp = -1.0

func apply_user_bits(i: int, from_user: bool = true) -> void:
	if from_user:
		mark_first_action()

	current_bits = clampi(i, 1, 12)
	var pow_val: int = int(pow(2.0, current_bits))
	var is_fit: bool = pow_val >= target_n
	var is_minimal: bool = current_bits == target_bits
	var is_overkill: bool = is_fit and not is_minimal

	big_i_label.text = "i = %d bit" % current_bits
	pow_label.text = "2^i = %d" % pow_val

	if is_fit:
		fit_label.text = "FIT: YES"
		fit_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		fit_label.text = "FIT: NO"
		fit_label.add_theme_color_override("font_color", COLOR_RED)

	if is_overkill:
		var excess: int = current_bits - target_bits
		var risk_pct: float = minf(100.0, float(excess) * 25.0)
		risk_bar.value = risk_pct
		if risk_pct < 40.0:
			risk_label.text = "RISK: LOW"
			risk_label.add_theme_color_override("font_color", COLOR_GREEN)
			risk_bar.modulate = COLOR_GREEN
		elif risk_pct < 80.0:
			risk_label.text = "RISK: MEDIUM"
			risk_label.add_theme_color_override("font_color", COLOR_YELLOW)
			risk_bar.modulate = COLOR_YELLOW
		else:
			risk_label.text = "RISK: HIGH"
			risk_label.add_theme_color_override("font_color", COLOR_RED)
			risk_bar.modulate = COLOR_RED
	else:
		risk_label.text = "RISK: NONE"
		risk_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		risk_bar.value = 0.0
		risk_bar.modulate = Color(0.2, 0.2, 0.2)

	details_text.text = "N: %d\nTarget i: %d\n2^i: %d\nMinimal: %s\nAnchor: %s\nMode: %s" % [
		target_n,
		target_bits,
		pow_val,
		"YES" if is_minimal else "NO",
		"YES" if pool_type == "ANCHOR" else "NO",
		"TIMED" if is_timed_mode else "UNTIMED"
	]

func _update_oscilloscope() -> void:
	var layer := wave_line.get_parent() as Control
	var size: Vector2 = layer.size
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var pow_val: int = int(pow(2.0, current_bits))
	var noise_amp: float = 0.0
	if pow_val < target_n:
		var diff: int = target_bits - current_bits
		var max_amp: float = size.y * 0.35
		noise_amp = (float(diff) / maxf(1.0, float(target_bits))) * max_amp
	elif current_bits > target_bits:
		noise_amp = size.y * 0.05

	var points := PackedVector2Array()
	var center_y: float = size.y * 0.5
	for x in range(0, int(size.x) + 10, 5):
		var t := (float(x) / maxf(1.0, size.x)) * 10.0 + osc_phase
		var base_y := sin(t) * (size.y * 0.25)
		var noise := randf_range(-noise_amp, noise_amp)
		points.append(Vector2(x, center_y + base_y + noise))
	wave_line.points = points

func _on_capture_pressed() -> void:
	mark_first_action()
	if not trial_active:
		return
	_finish_trial(false)

func _force_fail_timeout() -> void:
	if not trial_active:
		return
	_finish_trial(true)

func _finish_trial(is_timeout: bool) -> void:
	trial_active = false
	btn_capture.visible = false
	btn_next.visible = true
	btn_hint.disabled = true

	var end_time: float = Time.get_ticks_msec() / 1000.0
	var duration: float = end_time - start_time

	var capacity: int = int(pow(2.0, current_bits))
	var is_fit: bool = capacity >= target_n
	var is_minimal: bool = current_bits == target_bits
	var is_overkill: bool = is_fit and not is_minimal

	if is_timeout:
		is_fit = false
		is_minimal = false
		is_overkill = false

	if not is_fit:
		status_label.text = "STATUS: Signal lost. Not enough bits."
		status_label.add_theme_color_override("font_color", COLOR_RED)
	elif is_minimal:
		status_label.text = "STATUS: Perfect lock. Minimal depth reached."
		status_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		status_label.text = "STATUS: Channel stable, but depth is excessive."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)

	if current_trial_idx < sample_strip.get_child_count():
		var slot := sample_strip.get_child(current_trial_idx) as Control
		var bg := slot.get_node_or_null("BG") as ColorRect
		var mark := slot.get_node_or_null("AnchorMark") as Label
		if bg:
			if not is_fit:
				bg.color = COLOR_RED
			elif is_minimal:
				bg.color = COLOR_GREEN
			else:
				bg.color = COLOR_YELLOW
		if mark:
			mark.visible = pool_type == "ANCHOR"
		current_trial_idx = (current_trial_idx + 1) % SAMPLE_SLOTS

	if first_action_timestamp > 0.0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration

	var payload: Dictionary = {
		"quest": "radio_intercept",
		"stage": "A",
		"match_key": "RI_A_%s_%s_N%d" % ["TIMED" if is_timed_mode else "UNTIMED", pool_type, target_n],
		"N": target_n,
		"i_min": target_bits,
		"chosen_i": current_bits,
		"capacity": capacity,
		"is_fit": is_fit,
		"is_correct": is_fit,
		"is_minimal": is_minimal,
		"is_overkill": is_overkill,
		"used_hint": hint_used,
		"forced_sampling": forced_sampling,
		"elapsed_ms": duration * 1000.0
	}
	GlobalMetrics.register_trial(payload)

func _on_next_pressed() -> void:
	generate_task()

func _on_hint_pressed() -> void:
	mark_first_action()
	hint_used = true
	status_label.text = "HINT: N = 2^i. Choose the minimal i where 2^i >= N."
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_toggle() -> void:
	mark_first_action()
	var is_open := not details_sheet.visible
	details_sheet.visible = is_open
	dimmer.visible = is_open
	btn_details_main.text = "Close" if is_open else "Details"

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_on_details_toggle()
