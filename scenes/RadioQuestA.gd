extends Control

# UI Nodes
@onready var wave_line = $OscilloscopeLayer/WaveLine
@onready var task_info = $MainLayout/TaskInfo
@onready var bit_slider = $MainLayout/ControlsPanel/BitSlider
@onready var bit_label = $MainLayout/ControlsPanel/BitLabel
@onready var feedback_label = $MainLayout/ControlsPanel/FeedbackLabel
@onready var btn_capture = $MainLayout/ControlsPanel/ActionArea/BtnCapture
@onready var btn_next = $MainLayout/ControlsPanel/ActionArea/BtnNext
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel

# Game State
var target_n: int = 0
var target_bits: int = 0
var current_bits: int = 1
var start_time: float = 0.0
var trial_active: bool = false
var time_accum: float = 0.0 # For wave animation

const POWERS_OF_2 = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS = [10, 50, 100, 500, 1000]

func _ready():
	GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0)
	# Center the oscilloscope
	wave_line.position.y = get_viewport_rect().size.y * 0.4
	generate_task()

func _update_stability_ui(val, _change):
	stability_label.text = "STABILITY: %d%%" % int(val)
	if val < 30:
		stability_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif val < 70:
		stability_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		stability_label.add_theme_color_override("font_color", Color(0, 1, 0))

func generate_task():
	trial_active = true
	btn_capture.visible = true
	btn_next.visible = false
	feedback_label.text = ""
	bit_slider.editable = true

	# Select N
	var pool = []
	pool.append_array(POWERS_OF_2)
	pool.append_array(TRAPS)
	target_n = pool.pick_random()

	# Calculate Target Bits (Hartley: i = ceil(log2(N)))
	# Since we don't have log2 directly for ints, use log() / log(2)
	target_bits = ceil(log(target_n) / log(2.0))

	task_info.text = "SIGNAL DETECTED. ALPHABET POWER: N=%d" % target_n

	# Reset Slider (randomize slightly or reset to 1)
	current_bits = 1
	bit_slider.value = 1
	_update_slider_label()

	start_time = Time.get_ticks_msec() / 1000.0

func _process(delta):
	time_accum += delta * 5.0 # Speed of wave
	_update_oscilloscope()

func _update_oscilloscope():
	var points = PackedVector2Array()
	var width = get_viewport_rect().size.x
	var center_y = 0 # Relative to Line2D position

	# Logic for noise/color
	var noise_amp = 0.0
	var color = Color(0.2, 1.0, 0.2) # Green

	if current_bits < target_bits:
		# Noise proportional to distance
		var diff = target_bits - current_bits
		# Maximum noise when 1 bit vs 12 bits -> 11 difference
		noise_amp = diff * 15.0
	elif current_bits > target_bits:
		# Red warning
		var flicker = abs(sin(time_accum * 10.0))
		color = Color(1.0, 0.2 * flicker, 0.2 * flicker)
		noise_amp = 0.0 # Clean but red
	else:
		# Match
		noise_amp = 0.0
		# Maybe slight glow pulse?

	wave_line.default_color = color

	for x in range(0, int(width) + 10, 5):
		var t = (float(x) / width) * 10.0 + time_accum
		var base_y = sin(t) * 100.0 # Sine amplitude 100

		# Add noise
		var noise = randf_range(-noise_amp, noise_amp)

		points.append(Vector2(x, center_y + base_y + noise))

	wave_line.points = points

func _on_bit_slider_value_changed(value):
	current_bits = int(value)
	_update_slider_label()

func _update_slider_label():
	bit_label.text = "DECODING DEPTH: %d BITS" % current_bits

func _on_capture_pressed():
	if not trial_active: return

	trial_active = false
	bit_slider.editable = false
	btn_capture.visible = false
	btn_next.visible = true

	var end_time = Time.get_ticks_msec() / 1000.0
	var duration = end_time - start_time
	var is_correct = (current_bits == target_bits)

	var trial_data = {
		"match_key": "Radio_N%d" % target_n,
		"is_correct": is_correct,
		"duration": duration,
		"node_id": "A",
		"target_n": target_n,
		"user_bits": current_bits,
		"target_bits": target_bits
	}

	GlobalMetrics.register_trial(trial_data)

	if is_correct:
		feedback_label.text = "SIGNAL STABILIZED. EXCELLENT."
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		feedback_label.text = "SIGNAL LOST. REQUIRED: %d BITS" % target_bits
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))

func _on_next_pressed():
	generate_task()

func _on_back_pressed():
	# Go back to QuestSelect
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
