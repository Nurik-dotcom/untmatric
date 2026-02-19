extends Control

# Constants and Pools
const POOL_NORMAL = [64, 80, 100, 128, 256, 512, 1024]
const POOL_ANCHOR = [75, 110, 125, 300, 750, 1000]
const SAMPLE_SLOTS = 7

# Nodes
@onready var mode_label = $SafeArea/MainVBox/Header/ModeLabel
@onready var timer_label = $SafeArea/MainVBox/Header/TimerLabel
@onready var stability_label = $SafeArea/MainVBox/Header/StabilityLabel

@onready var i_info_label = $SafeArea/MainVBox/TaskCard/TaskVBox/IInfoLabel
@onready var k_info_label = $SafeArea/MainVBox/TaskCard/TaskVBox/KInfoLabel

@onready var i_bits_value_label = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/IBitsValue
@onready var btn_check_calc = $SafeArea/MainVBox/CalcCard/CalcVBox/BtnCheckCalc
@onready var btn_minus = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnMinus
@onready var btn_plus = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnPlus

@onready var storage_grid = $SafeArea/MainVBox/StorageCard/StorageVBox/StorageGrid
# Storage buttons will be retrieved dynamically or by fixed paths since I created them
@onready var storage_btns = [
	$SafeArea/MainVBox/StorageCard/StorageVBox/StorageGrid/StorageBtn1,
	$SafeArea/MainVBox/StorageCard/StorageVBox/StorageGrid/StorageBtn2,
	$SafeArea/MainVBox/StorageCard/StorageVBox/StorageGrid/StorageBtn3,
	$SafeArea/MainVBox/StorageCard/StorageVBox/StorageGrid/StorageBtn4
]

@onready var sample_strip = $SafeArea/MainVBox/BottomVBox/SampleStrip
@onready var btn_converter = $SafeArea/MainVBox/BottomVBox/ActionsRow/BtnConverter
@onready var btn_capture = $SafeArea/MainVBox/BottomVBox/ActionsRow/BtnCapture
@onready var btn_next = $SafeArea/MainVBox/BottomVBox/ActionsRow/BtnNext
@onready var status_label = $SafeArea/MainVBox/BottomVBox/StatusLabel

# State
var phase = "CALC" # CALC | SELECT | DONE
var i_bits = 7 # Default from spec
var k_symbols = 0
var i_bits_true = 0
var i_bits_user = 0
var calc_checked = false
var selected_storage_idx = -1
var storage_options = []
var used_converter = false
var is_timed = false
var forced_sampling = false

var start_ms = 0
var first_action_ms = -1
var current_trial_idx = 0
var anchor_countdown = 0

# Colors
const COLOR_GREEN = Color(0.0, 1.0, 0.0)
const COLOR_RED = Color(1.0, 0.0, 0.0)
const COLOR_YELLOW = Color(1.0, 1.0, 0.0)
const COLOR_GRAY = Color(0.2, 0.2, 0.2)

func _ready():
	randomize()
	if GlobalMetrics.stability_changed.connect(_update_stability_ui) != OK:
		print("Failed to connect stability signal")
	_update_stability_ui(GlobalMetrics.stability, 0.0)

	# Connect storage buttons
	for idx in range(storage_btns.size()):
		var btn = storage_btns[idx]
		btn.pressed.connect(_on_storage_selected.bind(idx))

	_init_sampling_bar()
	anchor_countdown = randi() % 4 + 7 # Random 7-10

	start_trial()

func _update_stability_ui(val, _change):
	stability_label.text = "СТАБИЛЬНОСТЬ: %d%%" % int(val)
	if val < 30:
		stability_label.add_theme_color_override("font_color", COLOR_RED)
	elif val < 70:
		stability_label.add_theme_color_override("font_color", COLOR_YELLOW)
	else:
		stability_label.add_theme_color_override("font_color", COLOR_GREEN)

func _init_sampling_bar():
	for slot in sample_strip.get_children():
		var bg = slot.get_node("BG")
		bg.color = COLOR_GRAY

func start_trial():
	phase = "CALC"
	selected_storage_idx = -1
	calc_checked = false
	used_converter = false
	i_bits_user = 0
	start_ms = Time.get_ticks_msec()
	first_action_ms = -1

	# 1. Generate K and I
	var pool_type = "NORMAL"
	if anchor_countdown <= 0:
		k_symbols = POOL_ANCHOR.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi() % 4 + 7
	else:
		k_symbols = POOL_NORMAL.pick_random()
		anchor_countdown -= 1

	i_bits_true = k_symbols * i_bits

	# 2. Generate Storage Options
	_generate_storage_options()

	# 3. Update UI
	i_info_label.text = "Глубина кодирования: i = %d бит" % i_bits
	k_info_label.text = "Длина сообщения: K = %d символов" % k_symbols

	i_bits_value_label.text = str(i_bits_user)
	i_bits_value_label.add_theme_color_override("font_color", Color.WHITE)

	btn_check_calc.disabled = false
	btn_check_calc.text = "ПРОВЕРИТЬ РАСЧЁТ"

	btn_minus.disabled = false
	btn_plus.disabled = false

	for idx in range(storage_btns.size()):
		var btn = storage_btns[idx]
		btn.disabled = true
		btn.button_pressed = false
		btn.text = _format_storage_btn(storage_options[idx])
		# Reset style (remove outline/modulate from previous trial)
		btn.modulate = Color(1, 1, 1, 1)

	btn_capture.disabled = true
	btn_capture.visible = true
	btn_next.visible = false

	status_label.text = "СТАТУС: Вычисли I (бит) и нажми 'ПРОВЕРИТЬ'."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _generate_storage_options():
	storage_options = []
	var attempts = 0

	# Helper to format and create option
	var create_opt = func(cap, tag):
		var disp_size = cap
		var unit = "бит"

		# Auto-format for display
		if cap >= 8192 and cap % 8192 == 0:
			disp_size = cap / 8192
			unit = "Кбайт"
		elif cap >= 8 and cap % 8 == 0:
			disp_size = cap / 8
			unit = "байт"

		return {
			"capacity_bits": cap,
			"display_size": disp_size,
			"display_unit": unit,
			"tag": tag
		}

	# 1. BEST FIT (Next power of 2 or nice round number > I_true)
	# Spec: "capacity_bits = nearest power/step above (not exactly I)"
	var best_cap = 1
	while best_cap <= i_bits_true:
		best_cap *= 2
	# If best_cap is huge, maybe just I_true + padding? Spec says "power/step".
	# Let's stick to power of 2 for simplicity, or round up to next 128/256/1024
	if best_cap == i_bits_true: best_cap *= 2 # Ensure > I_true

	storage_options.append(create_opt.call(best_cap, "BEST"))

	# 2. UNDERFIT (< I_true)
	var under_cap = int(floor(i_bits_true * 0.75))
	# Ensure it's not 0
	if under_cap < 1: under_cap = 1
	storage_options.append(create_opt.call(under_cap, "UNDER"))

	# 3. UNIT TRAP
	# If I divides by 8, trap is bytes. Else digits confusion.
	var trap_cap = 0
	var trap_unit = "бит"
	var trap_display = 0

	if i_bits_true % 8 == 0:
		# Trap: User sees "X bytes" but it's actually "X bits" capacity?
		# Or User calculates X bits, and we show option "X bytes" which is X*8 bits (OVERKILL)?
		# Spec: "if I % 8 == 0: make trap on bytes"
		# Usually means: Option is labeled "X bytes" (== 8*X bits), but maybe the trap is
		# an option labeled "X bits" when the answer is X bytes?
		# Let's look at "unit_confusion" error type:
		# "choice == I*8 or choice == I/8"

		# Let's make an option that HAS the number 'I_true' but in BYTES.
		# e.g. I=128. Trap is "128 bytes" (= 1024 bits). This is OVERKILL/CONFUSION.
		# OR Trap is "16 bits" when I=128 (answer in bytes). This is UNDERFIT.

		# Let's make a trap that matches the numeric value of I_true, but is in Bytes.
		# Capacity = I_true * 8. Display = I_true, Unit = "байт".
		# Error logic checks: if choice_cap == I_true * 8 -> unit_confusion.
		trap_cap = i_bits_true * 8
		# Manually create to ensure display is 'I_true' 'bytes'
		storage_options.append({
			"capacity_bits": trap_cap,
			"display_size": i_bits_true,
			"display_unit": "байт", # This is the trap: same number, diff unit
			"tag": "UNIT_TRAP"
		})
	else:
		# "same digits, different unit" - harder if not div by 8.
		# Let's just make a "KB" trap with similar small number?
		# Or maybe a Bit/Byte confusion on a rounded number.
		# Let's fallback to: Value = I_true, Unit = "Кбайт" (huge overkill)
		trap_cap = i_bits_true * 8192
		storage_options.append({
			"capacity_bits": trap_cap,
			"display_size": i_bits_true,
			"display_unit": "Кбайт",
			"tag": "UNIT_TRAP"
		})

	# 4. OVERKILL (>= I_true * 4)
	var over_cap = i_bits_true * 4
	# Round to nice number
	over_cap = ceil(over_cap / 100.0) * 100
	storage_options.append(create_opt.call(int(over_cap), "OVER"))

	storage_options.shuffle()

func _format_storage_btn(opt):
	return "%d %s" % [opt.display_size, opt.display_unit]

func _register_action():
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _on_minus_pressed():
	_register_action()
	if phase != "CALC": return
	i_bits_user = max(0, i_bits_user - 8)
	i_bits_value_label.text = str(i_bits_user)

func _on_plus_pressed():
	_register_action()
	if phase != "CALC": return
	i_bits_user += 8
	i_bits_value_label.text = str(i_bits_user)

func _on_check_calc_pressed():
	_register_action()
	if phase != "CALC": return

	calc_checked = true
	var correct = (i_bits_user == i_bits_true)

	phase = "SELECT"

	# Enable storage
	for btn in storage_btns:
		btn.disabled = false

	btn_minus.disabled = true
	btn_plus.disabled = true
	btn_check_calc.disabled = true

	if correct:
		status_label.text = "СТАТУС: Расчёт верный. Выбери подходящий носитель."
		status_label.add_theme_color_override("font_color", COLOR_GREEN)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		status_label.text = "СТАТУС: Расчёт отличается, но продолжим. Выбери носитель."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_YELLOW)

func _on_storage_selected(idx):
	_register_action()
	if phase != "SELECT": return

	selected_storage_idx = idx

	# Visual feedback
	for i in range(storage_btns.size()):
		storage_btns[i].button_pressed = (i == idx)
		if i == idx:
			storage_btns[i].modulate = Color(1, 1, 0) # Highlight
		else:
			storage_btns[i].modulate = Color(1, 1, 1)

	btn_capture.disabled = false

func _on_converter_pressed():
	_register_action()
	used_converter = true

	var msg = "I = %d бит" % i_bits_true
	if i_bits_true % 8 == 0:
		msg += " = %d байт" % (i_bits_true / 8)
	if i_bits_true % 8192 == 0:
		msg += " = %d Кбайт" % (i_bits_true / 8192)

	status_label.text = "КОНВЕРТЕР: " + msg
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

func _on_capture_pressed():
	_register_action()
	if selected_storage_idx == -1: return

	_finish_trial()

func _finish_trial():
	phase = "DONE"
	var choice = storage_options[selected_storage_idx]
	var choice_cap = choice.capacity_bits

	var calc_correct = (i_bits_user == i_bits_true)

	# Metrics
	var is_fit = choice_cap >= i_bits_true
	var is_best_fit = false # Will determine below
	var is_overkill = false
	var waste_ratio = 0.0
	if choice_cap > 0:
		waste_ratio = float(choice_cap) / float(i_bits_true)

	var error_type = "unknown"

	if choice_cap < i_bits_true:
		error_type = "underfit"
		is_fit = false
	elif not calc_correct:
		error_type = "calc_wrong"
		# Secondary classification could be handled by analytics
	elif choice_cap == i_bits_true * 8 or choice_cap * 8 == i_bits_true:
		# Strict check for unit confusion (Bit vs Byte)
		error_type = "unit_confusion_bits_bytes"
		is_fit = true # Technically fits if it's the larger one, but logic says error
		if choice_cap < i_bits_true: is_fit = false
	elif choice.tag == "BEST":
		error_type = "best_fit"
		is_best_fit = true
		is_fit = true
	elif waste_ratio > 4.0:
		error_type = "overkill_hard"
		is_overkill = true
		is_fit = true
	else:
		error_type = "overkill_soft"
		is_overkill = true
		is_fit = true

	# Valid for mastery?
	var valid_mastery = (not used_converter) and calc_correct and (error_type == "best_fit")

	# Register in GlobalMetrics
	var payload = {
		"quest_id": "radio_intercept",
		"stage_id": "B",
		"match_key": "RI_B_%s" % ("TIMED" if is_timed else "UNTIMED"),
		"pool_type": "ANCHOR" if k_symbols in POOL_ANCHOR else "NORMAL",
		"dependency_mode": "default_i",

		"i_bits": i_bits,
		"K_symbols": k_symbols,
		"I_bits_true": i_bits_true,
		"I_bits_user": i_bits_user,

		"calc_correct": calc_correct,
		"used_converter": used_converter,
		"choice_capacity_bits": choice_cap,
		"choice_display_size": choice.display_size,
		"choice_display_unit": choice.display_unit,

		"is_fit": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"error_type": error_type,

		"valid_for_mastery": valid_mastery,
		"valid_for_diagnostics": true,

		"elapsed_ms": Time.get_ticks_msec() - start_ms,
		"time_to_first_action_ms": (first_action_ms - start_ms) if first_action_ms > 0 else 0,
		"is_timed": is_timed,
		"forced_sampling": forced_sampling
	}

	GlobalMetrics.register_trial(payload)

	# Update UI Feedback
	btn_capture.visible = false
	btn_next.visible = true

	if is_best_fit and calc_correct:
		status_label.text = "РЕЗУЛЬТАТ: Отлично! Точный расчёт и оптимальный носитель."
		status_label.add_theme_color_override("font_color", COLOR_GREEN)
		_update_sample_strip(COLOR_GREEN)
	elif not is_fit:
		status_label.text = "РЕЗУЛЬТАТ: Ошибка. Носитель слишком мал."
		status_label.add_theme_color_override("font_color", COLOR_RED)
		_update_sample_strip(COLOR_RED)
	elif not calc_correct:
		status_label.text = "РЕЗУЛЬТАТ: Расчёт неверен. Проверь формулу I = K * i."
		status_label.add_theme_color_override("font_color", COLOR_RED)
		_update_sample_strip(COLOR_RED)
	elif is_overkill:
		status_label.text = "РЕЗУЛЬТАТ: Носитель подходит, но избыточен."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		_update_sample_strip(COLOR_YELLOW)
	else:
		status_label.text = "РЕЗУЛЬТАТ: Принято с замечаниями."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		_update_sample_strip(COLOR_YELLOW)

func _update_sample_strip(color):
	if current_trial_idx < sample_strip.get_child_count():
		var slot = sample_strip.get_child(current_trial_idx)
		var bg = slot.get_node("BG")
		bg.color = color
		current_trial_idx = (current_trial_idx + 1) % sample_strip.get_child_count()

func _on_next_pressed():
	start_trial()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
