extends Control

const N_VALUES = [32, 64, 100, 128, 200, 256]
const POINT_COUNT = 96
const MAX_NOISE = 24.0

@onready var task_label = $RootPanel/VBox/TaskLabel
@onready var oscillo_area = $RootPanel/VBox/OscilloBox/OscilloArea
@onready var osc_line = $RootPanel/VBox/OscilloBox/OscilloArea/OscilloNode/OscLine
@onready var bits_label = $RootPanel/VBox/TunerRow/BitsLabel
@onready var bits_slider = $RootPanel/VBox/TunerRow/BitsSlider
@onready var hint_button = $RootPanel/VBox/ButtonsRow/HintButton
@onready var confirm_button = $RootPanel/VBox/ButtonsRow/ConfirmButton
@onready var hint_label = $RootPanel/VBox/HintLabel

var current_n: int = 0
var i_min: int = 0
var used_hint: bool = false
var forced_sampling: bool = false
var started_at: int = 0
var first_action_at: int = 0
var _phase: float = 0.0
var _animate: bool = true

func _ready():
	_start_new_task()
	_draw_signal()

func _process(delta: float) -> void:
	if _animate:
		_phase += delta * 2.0
		_draw_signal()

	if not forced_sampling and first_action_at == 0:
		var elapsed = Time.get_ticks_msec() - started_at
		if elapsed >= 8000:
			forced_sampling = true
			hint_label.text = "Режим принудительного замера активирован."

func _start_new_task():
	current_n = N_VALUES[randi() % N_VALUES.size()]
	i_min = int(ceil(log(float(current_n)) / log(2.0)))
	used_hint = false
	forced_sampling = false
	started_at = Time.get_ticks_msec()
	first_action_at = 0

	task_label.text = "Перехват... Мощность алфавита: %d символов. Настройте глубину кодирования." % current_n
	bits_slider.value = 1
	bits_label.text = "Биты: %d" % int(bits_slider.value)
	hint_label.text = ""

func _on_bits_slider_value_changed(value: float) -> void:
	if first_action_at == 0:
		first_action_at = Time.get_ticks_msec()
	bits_label.text = "Биты: %d" % int(value)
	_draw_signal()

func _on_hint_button_pressed() -> void:
	used_hint = true
	var hint = "Формула Хартли: N = 2^i\nМинимум i для %d: %d" % [current_n, i_min]
	hint_label.text = hint

func _on_confirm_button_pressed() -> void:
	var chosen_i = int(bits_slider.value)
	var capacity = int(pow(2.0, chosen_i))
	var correct = capacity >= current_n
	var overkill = correct and chosen_i > i_min
	var elapsed_ms = Time.get_ticks_msec() - started_at

	var payload = {
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

func _draw_signal():
	if not is_instance_valid(oscillo_area):
		return
	var size = oscillo_area.size
	if size.x <= 1 or size.y <= 1:
		return

	var chosen_i = int(bits_slider.value)
	var capacity = int(pow(2.0, chosen_i))
	var correct = capacity >= current_n
	var overkill = correct and chosen_i > i_min

	var noise_strength = 0.0
	if not correct:
		noise_strength = MAX_NOISE
	elif overkill:
		noise_strength = MAX_NOISE * 0.12
	else:
		noise_strength = 0.0

	var points := PackedVector2Array()
	points.resize(POINT_COUNT)
	var mid_y = size.y * 0.5
	var amp = size.y * 0.35
	for i in range(POINT_COUNT):
		var t = float(i) / float(POINT_COUNT - 1)
		var x = t * size.x
		var y = mid_y + sin(t * TAU * 2.0 + _phase) * amp
		if noise_strength > 0.0:
			y += randf_range(-noise_strength, noise_strength)
		points[i] = Vector2(x, y)

	osc_line.points = points
