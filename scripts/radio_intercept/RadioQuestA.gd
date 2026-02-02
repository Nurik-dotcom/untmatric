extends Control

# UI References
@onready var task_label = $RootPanel/VBox/HeaderBar/TaskLabel
@onready var osc_area = $RootPanel/VBox/OscilloBox/OscilloArea
@onready var osc_line = $RootPanel/VBox/OscilloBox/OscilloArea/OscilloNode/OscLine
@onready var bits_label = $RootPanel/VBox/TunerRow/BitsLabel
@onready var bits_slider = $RootPanel/VBox/TunerRow/BitsSlider
@onready var hint_label = $RootPanel/VBox/HintLabel

# Game Logic
var target_n: int = 32
var start_time: int = 0
var used_hint: bool = false
var forced_sampling: bool = false
var first_action_time: int = -1

# Possible N values for quests
var n_options = [32, 64, 100, 128, 200, 256]

# Oscilloscope State
var time_phase: float = 0.0

func _ready():
	start_time = Time.get_ticks_msec()
	_pick_new_target()
	_update_oscilloscope()

	# Start a timer for forced sampling check (8 seconds)
	get_tree().create_timer(8.0).timeout.connect(_check_forced_sampling)

func _process(delta):
	time_phase += delta * 5.0
	_update_oscilloscope()

func _pick_new_target():
	target_n = n_options.pick_random()
	task_label.text = "Перехват... Мощность алфавита: %d. Настройте глубину кодирования." % target_n

func _get_i_min(n: int) -> int:
	# i_min = ceil(log2(N))
	if n <= 1: return 1
	var val = ceil(log(float(n)) / log(2.0))
	return int(val)

func _update_oscilloscope():
	if not is_instance_valid(osc_area) or not is_instance_valid(osc_line):
		return

	var width = osc_area.size.x
	var height = osc_area.size.y
	var mid_y = height / 2.0
	var points = PackedVector2Array()

	var i_chosen = int(bits_slider.value)
	var i_min = _get_i_min(target_n)
	var capacity = pow(2, i_chosen)

	var is_correct = (capacity >= target_n)
	var is_overkill = is_correct and (i_chosen > i_min)

	# Drawing Logic
	# Points count
	var steps = 100
	for step in range(steps):
		var x = (float(step) / float(steps)) * width

		# Base Sine Wave
		var y_offset = sin((step * 0.2) + time_phase) * (height * 0.3)

		# Noise Calculation
		var noise = 0.0
		if not is_correct:
			# Strong noise
			noise = randf_range(-1.0, 1.0) * (height * 0.4)
		elif is_overkill:
			# Minimal "sterile" noise (optional)
			noise = randf_range(-0.1, 0.1) * (height * 0.05)
		else:
			# Correct and optimal (i_min) -> Clean signal
			noise = 0.0

		points.append(Vector2(x, mid_y + y_offset + noise))

	osc_line.points = points

func _on_slider_value_changed(value):
	bits_label.text = "Биты: %d" % int(value)
	if first_action_time == -1:
		first_action_time = Time.get_ticks_msec()
	# Line is updated in _process, so no explicit redraw needed here usually,
	# but we can force one if _process is disabled. It's enabled, so fine.

func _on_hint_pressed():
	used_hint = true
	var i_min = _get_i_min(target_n)
	hint_label.text = "Подсказка: N <= 2^i. Для N=%d минимальное i = %d." % [target_n, i_min]

func _on_confirm_pressed():
	var end_time = Time.get_ticks_msec()
	var elapsed_ms = end_time - start_time

	var i_chosen = int(bits_slider.value)
	var i_min = _get_i_min(target_n)
	var capacity = int(pow(2, i_chosen))

	var is_correct = (capacity >= target_n)
	var is_overkill = is_correct and (i_chosen > i_min)

	var payload = {
		"quest": "radio_intercept",
		"stage": "A",
		"N": target_n,
		"i_min": i_min,
		"chosen_i": i_chosen,
		"capacity": capacity,
		"is_correct": is_correct,
		"is_overkill": is_overkill,
		"used_hint": used_hint,
		"forced_sampling": forced_sampling,
		"elapsed_ms": elapsed_ms
	}

	# Log to GlobalMetrics
	if GlobalMetrics.has_method("register_trial"):
		GlobalMetrics.register_trial(payload)
	else:
		print("GlobalMetrics.register_trial not found. Payload: ", payload)

	# Feedback
	if is_correct and not is_overkill:
		hint_label.add_theme_color_override("font_color", Color.GREEN)
		hint_label.text = "Сигнал стабилен! Переход..."
		await get_tree().create_timer(1.0).timeout
		_pick_new_target()
		_reset_round()
	elif is_overkill:
		hint_label.add_theme_color_override("font_color", Color.YELLOW)
		hint_label.text = "Избыточность! Сигнал чист, но ресурсы потрачены."
		await get_tree().create_timer(1.0).timeout
		_pick_new_target()
		_reset_round()
	else:
		hint_label.add_theme_color_override("font_color", Color.RED)
		hint_label.text = "Помехи! Недостаточная глубина."

func _check_forced_sampling():
	if first_action_time == -1 and not used_hint:
		forced_sampling = true
		hint_label.text = "Режим принудительного замера активирован."

func _reset_round():
	start_time = Time.get_ticks_msec()
	first_action_time = -1
	used_hint = false
	forced_sampling = false
	hint_label.text = ""
	hint_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
