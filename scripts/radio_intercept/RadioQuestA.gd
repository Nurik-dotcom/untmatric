extends Control

const RadioLevels := preload("res://scripts/radio_intercept/RadioLevels.gd")
const FALLBACK_NORMAL_POOL: Array[int] = [16, 32, 64, 128, 256, 512, 1024]
const FALLBACK_TRAP_POOL: Array[int] = [10, 50, 100, 500, 1000, 2000]
const FALLBACK_ANCHOR_POOL: Array[int] = [100, 500, 1000]

const POINT_COUNT: int = 96
const MAX_NOISE: float = 24.0
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 520.0

@onready var safe_area: MarginContainer = $SafeArea
@onready var root_panel: Panel = $SafeArea/RootPanel
@onready var root_vbox: VBoxContainer = $SafeArea/RootPanel/VBox
@onready var buttons_row: HBoxContainer = $SafeArea/RootPanel/VBox/ButtonsRow
@onready var task_label: Label = $SafeArea/RootPanel/VBox/HeaderBar/TaskLabel
@onready var oscillo_area: Control = $SafeArea/RootPanel/VBox/OscilloBox/OscilloArea
@onready var osc_line: Line2D = $SafeArea/RootPanel/VBox/OscilloBox/OscilloArea/OscilloNode/OscLine
@onready var bits_label: Label = $SafeArea/RootPanel/VBox/TunerRow/BitsLabel
@onready var bits_slider: HSlider = $SafeArea/RootPanel/VBox/TunerRow/BitsSlider
@onready var analyze_button: Button = $SafeArea/RootPanel/VBox/TunerRow/AnalyzeButton
@onready var hint_button: Button = $SafeArea/RootPanel/VBox/ButtonsRow/HintButton
@onready var confirm_button: Button = $SafeArea/RootPanel/VBox/ButtonsRow/ConfirmButton
@onready var hint_label: Label = $SafeArea/RootPanel/VBox/HintLabel

var current_n: int = 0
var i_min: int = 1
var current_bits: int = 1

var used_hint: bool = false
var forced_sampling: bool = false
var started_at: int = 0
var first_action_at: int = 0

var _phase: float = 0.0
var _animate: bool = true
var _analysis_visible: bool = false
var _analysis_lock: bool = false
var _drawn_bits: int = 1

var _root_scroll_installed: bool = false
var _pool_normal: Array[int] = []
var _pool_trap: Array[int] = []
var _pool_anchor: Array[int] = []
var _anchor_every_min: int = 7
var _anchor_every_max: int = 10
var _anchor_countdown: int = 0

func _ready() -> void:
	randomize()
	_install_root_scroll()
	_load_level_config()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_anchor_countdown = _random_anchor_gap()
	_on_viewport_size_changed()
	_start_new_task()
	call_deferred("_draw_signal")

func _process(delta: float) -> void:
	if _animate:
		_phase += delta * 2.0
		_draw_signal()

	if not forced_sampling and first_action_at == 0:
		var elapsed: int = Time.get_ticks_msec() - started_at
		if elapsed >= 8000:
			forced_sampling = true
			hint_label.text = "\u0420\u0435\u0436\u0438\u043c \u043f\u0440\u0438\u043d\u0443\u0434\u0438\u0442\u0435\u043b\u044c\u043d\u043e\u0433\u043e \u0437\u0430\u043c\u0435\u0440\u0430 \u0430\u043a\u0442\u0438\u0432\u0438\u0440\u043e\u0432\u0430\u043d."

func _start_new_task() -> void:
	current_n = _pick_target_n()
	i_min = int(ceil(log(float(current_n)) / log(2.0)))
	current_bits = int(bits_slider.min_value)
	_drawn_bits = current_bits
	_analysis_visible = false
	_analysis_lock = false
	used_hint = false
	forced_sampling = false
	started_at = Time.get_ticks_msec()
	first_action_at = 0

	task_label.text = "\u041f\u0435\u0440\u0435\u0445\u0432\u0430\u0442... \u041c\u043e\u0449\u043d\u043e\u0441\u0442\u044c \u0430\u043b\u0444\u0430\u0432\u0438\u0442\u0430: %d \u0441\u0438\u043c\u0432\u043e\u043b\u043e\u0432. \u041d\u0430\u0441\u0442\u0440\u043e\u0439\u0442\u0435 \u0433\u043b\u0443\u0431\u0438\u043d\u0443 \u043a\u043e\u0434\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u044f." % current_n
	bits_slider.value = current_bits
	bits_label.text = "\u0411\u0438\u0442\u044b: %d" % current_bits
	hint_label.text = ""
	analyze_button.disabled = false
	confirm_button.disabled = false

func _on_bits_slider_value_changed(value: float) -> void:
	if first_action_at == 0:
		first_action_at = Time.get_ticks_msec()
	current_bits = int(value)
	bits_label.text = "\u0411\u0438\u0442\u044b: %d" % current_bits

func _on_hint_button_pressed() -> void:
	used_hint = true
	var hint: String = "\u0424\u043e\u0440\u043c\u0443\u043b\u0430 \u0425\u0430\u0440\u0442\u043b\u0438: N = 2^i\n\u041c\u0438\u043d\u0438\u043c\u0443\u043c i \u0434\u043b\u044f %d: %d" % [current_n, i_min]
	hint_label.text = hint

func _on_analyze_button_pressed() -> void:
	if _analysis_lock:
		return
	if first_action_at == 0:
		first_action_at = Time.get_ticks_msec()

	_analysis_lock = true
	analyze_button.disabled = true
	confirm_button.disabled = true
	_drawn_bits = current_bits
	_analysis_visible = true
	_draw_signal()

	await get_tree().create_timer(1.5).timeout
	_check_answer()

func _check_answer() -> void:
	var chosen_i: int = _drawn_bits
	var capacity: int = int(pow(2.0, chosen_i))
	var correct: bool = capacity >= current_n
	var overkill: bool = correct and chosen_i > i_min
	var elapsed_ms: int = Time.get_ticks_msec() - started_at

	var payload: Dictionary = {
		"quest": "radio_intercept",
		"stage": "A",
		"N": current_n,
		"i_min": i_min,
		"chosen_i": chosen_i,
		"capacity": capacity,
		"is_correct": correct,
		"is_overkill": overkill,
		"used_hint": used_hint,
		"forced_sampling": forced_sampling,
		"elapsed_ms": elapsed_ms
	}
	GlobalMetrics.register_trial(payload)

	_start_new_task()
	_draw_signal()

func _on_confirm_button_pressed() -> void:
	_on_analyze_button_pressed()

func _on_slider_value_changed(value: float) -> void:
	_on_bits_slider_value_changed(value)

func _on_hint_pressed() -> void:
	_on_hint_button_pressed()

func _on_confirm_pressed() -> void:
	_on_confirm_button_pressed()

func _on_analyze_pressed() -> void:
	_on_analyze_button_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")

func _on_viewport_size_changed() -> void:
	var size: Vector2 = get_viewport_rect().size
	var is_phone_landscape: bool = _is_phone_landscape(size)
	if is_phone_landscape:
		safe_area.add_theme_constant_override("margin_left", 10)
		safe_area.add_theme_constant_override("margin_right", 10)
		safe_area.add_theme_constant_override("margin_top", 8)
		safe_area.add_theme_constant_override("margin_bottom", 8)
		root_vbox.add_theme_constant_override("separation", 12)
		task_label.add_theme_font_size_override("font_size", 20)
		bits_label.add_theme_font_size_override("font_size", 24)
		buttons_row.add_theme_constant_override("separation", 16)
	else:
		safe_area.add_theme_constant_override("margin_left", 16)
		safe_area.add_theme_constant_override("margin_right", 16)
		safe_area.add_theme_constant_override("margin_top", 12)
		safe_area.add_theme_constant_override("margin_bottom", 12)
		root_vbox.add_theme_constant_override("separation", 20)
		task_label.add_theme_font_size_override("font_size", 24)
		bits_label.add_theme_font_size_override("font_size", 32)
		buttons_row.add_theme_constant_override("separation", 40)
	call_deferred("_draw_signal")

func _is_phone_landscape(size: Vector2) -> bool:
	return size.x > size.y and size.y <= PHONE_LANDSCAPE_MAX_HEIGHT

func _draw_signal() -> void:
	if not is_instance_valid(oscillo_area):
		return
	var size: Vector2 = oscillo_area.size
	if size.x <= 1.0 or size.y <= 1.0:
		return

	var chosen_i: int = _drawn_bits if _analysis_visible else maxi(i_min, 1)
	var capacity: int = int(pow(2.0, chosen_i))
	var correct: bool = capacity >= current_n
	var overkill: bool = correct and chosen_i > i_min

	var noise_strength: float = MAX_NOISE
	if _analysis_visible and overkill:
		noise_strength = MAX_NOISE * 0.12
	elif _analysis_visible and correct:
		noise_strength = 0.0

	var points := PackedVector2Array()
	points.resize(POINT_COUNT)
	var mid_y: float = size.y * 0.5
	var amp: float = size.y * 0.35
	for i in range(POINT_COUNT):
		var t: float = float(i) / float(POINT_COUNT - 1)
		var x: float = t * size.x
		var y: float = mid_y + sin(t * TAU * 2.0 + _phase) * amp
		if noise_strength > 0.0:
			y += randf_range(-noise_strength, noise_strength)
		points[i] = Vector2(x, y)

	osc_line.points = points

func _install_root_scroll() -> void:
	if _root_scroll_installed:
		return
	if safe_area == null or root_panel == null:
		return

	var root_scroll := ScrollContainer.new()
	root_scroll.name = "RootScroll"
	root_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root_scroll.follow_focus = true

	safe_area.remove_child(root_panel)
	safe_area.add_child(root_scroll)
	root_scroll.add_child(root_panel)
	root_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_panel.size_flags_vertical = Control.SIZE_FILL
	_root_scroll_installed = true

func _load_level_config() -> void:
	_pool_normal = _to_int_array(
		RadioLevels.get_pool("A", "N_pool_normal", FALLBACK_NORMAL_POOL),
		FALLBACK_NORMAL_POOL
	)
	_pool_trap = _to_int_array(
		RadioLevels.get_pool("A", "N_pool_trap", FALLBACK_TRAP_POOL),
		FALLBACK_TRAP_POOL
	)
	_pool_anchor = _to_int_array(
		RadioLevels.get_pool("A", "N_pool_anchor", FALLBACK_ANCHOR_POOL),
		FALLBACK_ANCHOR_POOL
	)
	_anchor_every_min = int(RadioLevels.get_value("A", "anchor_every_min", 7))
	_anchor_every_max = int(RadioLevels.get_value("A", "anchor_every_max", 10))
	if _anchor_every_min <= 0:
		_anchor_every_min = 7
	if _anchor_every_max < _anchor_every_min:
		_anchor_every_max = _anchor_every_min

func _pick_target_n() -> int:
	if _anchor_countdown <= 0:
		_anchor_countdown = _random_anchor_gap()
		return _pick_from_pool(_pool_anchor, 100)

	_anchor_countdown -= 1
	if randf() < 0.30:
		return _pick_from_pool(_pool_trap, 100)
	return _pick_from_pool(_pool_normal, 128)

func _pick_from_pool(pool: Array[int], fallback_value: int) -> int:
	if pool.is_empty():
		return fallback_value
	return pool[randi() % pool.size()]

func _random_anchor_gap() -> int:
	return randi_range(_anchor_every_min, _anchor_every_max)

func _to_int_array(raw: Array, fallback: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value_var in raw:
		var typed: Variant = value_var
		match typeof(typed):
			TYPE_INT:
				result.append(int(typed))
			TYPE_FLOAT:
				result.append(int(round(float(typed))))
			TYPE_STRING:
				var text: String = String(typed).strip_edges()
				if text.is_valid_int():
					result.append(text.to_int())
	if result.is_empty():
		result.append_array(fallback)
	return result
