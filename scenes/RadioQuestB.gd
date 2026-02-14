extends Control

# Constants and Pools
const POOL_NORMAL = [64, 80, 100, 128, 256, 512, 1024]
const POOL_ANCHOR = [75, 110, 125, 300, 750, 1000]
const CARRIER_CAPACITY_BITS = [128, 256, 512, 1024, 2048, 4096, 8192, 16384]
const STEP_NORMAL = 1
const STEP_FAST = 8

const COLOR_GREEN = Color(0.0, 1.0, 0.0)
const COLOR_RED = Color(1.0, 0.0, 0.0)
const COLOR_YELLOW = Color(1.0, 1.0, 0.0)
const COLOR_GRAY = Color(0.2, 0.2, 0.2)

const STATUS_CALC_PROMPT = "STATUS: Calculate I and press \"CHECK CALC\"."
const STATUS_CALC_OK = "STATUS: Calculation is correct. Choose storage."
const STATUS_CALC_BAD = "STATUS: Calculation is wrong. Try again or choose storage (diagnostic mode)."

# Nodes
@onready var stability_label = $SafeArea/MainVBox/Header/StabilityLabel

@onready var i_info_label = $SafeArea/MainVBox/TaskCard/TaskVBox/IInfoLabel
@onready var k_info_label = $SafeArea/MainVBox/TaskCard/TaskVBox/KInfoLabel

@onready var i_bits_value_label = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/IBitsValue
@onready var calc_step_label = $SafeArea/MainVBox/CalcCard/CalcVBox/CalcStepLabel
@onready var btn_check_calc = $SafeArea/MainVBox/CalcCard/CalcVBox/BtnCheckCalc
@onready var btn_minus_fast = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnMinusFast
@onready var btn_minus = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnMinus
@onready var btn_plus = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnPlus
@onready var btn_plus_fast = $SafeArea/MainVBox/CalcCard/CalcVBox/IBitsRow/BtnPlusFast

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
var i_bits = 7
var k_symbols = 0
var i_bits_true = 0
var i_bits_user = 0
var selected_storage_idx = -1
var storage_options: Array = []
var used_converter = false
var is_timed = false
var forced_sampling = false
var current_pool_type = "NORMAL"

var start_ms = 0
var first_action_ms = -1
var current_trial_idx = 0
var anchor_countdown = 0

func _ready():
	randomize()
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0.0)

	for idx in range(storage_btns.size()):
		var btn: Button = storage_btns[idx]
		btn.pressed.connect(_on_storage_selected.bind(idx))

	_init_sampling_bar()
	anchor_countdown = randi() % 4 + 7
	start_trial()

func _update_stability_ui(val: float, _change: float) -> void:
	stability_label.text = "STABILITY: %d%%" % int(val)
	if val < 30:
		stability_label.add_theme_color_override("font_color", COLOR_RED)
	elif val < 70:
		stability_label.add_theme_color_override("font_color", COLOR_YELLOW)
	else:
		stability_label.add_theme_color_override("font_color", COLOR_GREEN)

func _init_sampling_bar():
	for slot in sample_strip.get_children():
		var bg: ColorRect = slot.get_node("BG")
		bg.color = COLOR_GRAY

func start_trial():
	phase = "CALC"
	selected_storage_idx = -1
	used_converter = false
	i_bits_user = 0
	start_ms = Time.get_ticks_msec()
	first_action_ms = -1

	current_pool_type = "NORMAL"
	if anchor_countdown <= 0:
		k_symbols = POOL_ANCHOR.pick_random()
		current_pool_type = "ANCHOR"
		anchor_countdown = randi() % 4 + 7
	else:
		k_symbols = POOL_NORMAL.pick_random()
		anchor_countdown -= 1

	i_bits_true = k_symbols * i_bits
	_generate_storage_options()

	i_info_label.text = "Encoding depth: i = %d bits" % i_bits
	k_info_label.text = "Message length: K = %d symbols" % k_symbols

	i_bits_value_label.text = str(i_bits_user)
	i_bits_value_label.add_theme_color_override("font_color", Color.WHITE)
	calc_step_label.text = "Step: %d bit (fast: +/- %d)" % [STEP_NORMAL, STEP_FAST]

	btn_check_calc.disabled = false
	btn_minus_fast.disabled = false
	btn_minus.disabled = false
	btn_plus.disabled = false
	btn_plus_fast.disabled = false

	for idx in range(storage_btns.size()):
		var btn: Button = storage_btns[idx]
		btn.disabled = true
		btn.button_pressed = false
		btn.text = _format_storage_btn(storage_options[idx])
		btn.modulate = Color(1, 1, 1, 1)

	btn_capture.disabled = true
	btn_capture.visible = true
	btn_next.visible = false

	status_label.text = STATUS_CALC_PROMPT
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _generate_storage_options():
	storage_options.clear()

	var best_cap = _pick_best_capacity(i_bits_true)
	var under_cap = _pick_under_capacity(i_bits_true)
	var over_cap = _pick_over_capacity(best_cap)

	storage_options.append(_make_storage_option(best_cap, "BEST"))
	storage_options.append(_make_storage_option(under_cap, "UNDER"))
	storage_options.append(_make_unit_trap_option())
	storage_options.append(_make_storage_option(over_cap, "OVER"))

	storage_options.shuffle()

func _make_storage_option(cap_bits: int, tag: String) -> Dictionary:
	var display_size = cap_bits
	var display_unit = "bits"
	if cap_bits >= 8192 and cap_bits % 8192 == 0:
		display_size = cap_bits / 8192
		display_unit = "KB"
	elif cap_bits >= 8 and cap_bits % 8 == 0:
		display_size = cap_bits / 8
		display_unit = "bytes"
	return {
		"capacity_bits": int(cap_bits),
		"display_size": int(display_size),
		"display_unit": display_unit,
		"tag": tag
	}

func _make_unit_trap_option() -> Dictionary:
	if i_bits_true % 8 == 0:
		return {
			"capacity_bits": int(i_bits_true * 8),
			"display_size": int(i_bits_true),
			"display_unit": "bytes",
			"tag": "UNIT_TRAP_BITS_BYTES"
		}

	var rounded_bytes = int(ceil(float(i_bits_true) / 8.0))
	return {
		"capacity_bits": int(rounded_bytes * 8),
		"display_size": int(rounded_bytes),
		"display_unit": "KB",
		"tag": "UNIT_TRAP_BYTES_KB"
	}

func _pick_best_capacity(needed_bits: int) -> int:
	for cap in CARRIER_CAPACITY_BITS:
		if cap >= needed_bits:
			return cap
	var cap = CARRIER_CAPACITY_BITS[CARRIER_CAPACITY_BITS.size() - 1]
	while cap < needed_bits:
		cap *= 2
	return cap

func _pick_under_capacity(needed_bits: int) -> int:
	var candidate = 0
	for cap in CARRIER_CAPACITY_BITS:
		if cap < needed_bits:
			candidate = cap
	if candidate > 0:
		return candidate
	return max(1, needed_bits - 1)

func _pick_over_capacity(best_cap: int) -> int:
	for cap in CARRIER_CAPACITY_BITS:
		if cap > best_cap:
			return cap
	return best_cap * 2

func _format_storage_btn(opt: Dictionary) -> String:
	return "%d %s" % [int(opt.display_size), str(opt.display_unit)]

func _register_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _adjust_i_bits(delta: int) -> void:
	i_bits_user = max(0, i_bits_user + delta)
	i_bits_value_label.text = str(i_bits_user)

func _on_minus_pressed():
	_register_action()
	if phase != "CALC":
		return
	_adjust_i_bits(-STEP_NORMAL)

func _on_plus_pressed():
	_register_action()
	if phase != "CALC":
		return
	_adjust_i_bits(STEP_NORMAL)

func _on_minus_fast_pressed():
	_register_action()
	if phase != "CALC":
		return
	_adjust_i_bits(-STEP_FAST)

func _on_plus_fast_pressed():
	_register_action()
	if phase != "CALC":
		return
	_adjust_i_bits(STEP_FAST)

func _on_check_calc_pressed():
	_register_action()
	if phase != "CALC":
		return

	var correct = (i_bits_user == i_bits_true)

	phase = "SELECT"

	for btn in storage_btns:
		btn.disabled = false

	btn_minus_fast.disabled = true
	btn_minus.disabled = true
	btn_plus.disabled = true
	btn_plus_fast.disabled = true
	btn_check_calc.disabled = true

	if correct:
		status_label.text = STATUS_CALC_OK
		status_label.add_theme_color_override("font_color", COLOR_GREEN)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		status_label.text = STATUS_CALC_BAD
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_YELLOW)

func _on_storage_selected(idx: int) -> void:
	_register_action()
	if phase != "SELECT":
		return

	selected_storage_idx = idx

	for i in range(storage_btns.size()):
		var btn: Button = storage_btns[i]
		btn.button_pressed = (i == idx)
		if i == idx:
			btn.modulate = Color(1, 1, 0)
		else:
			btn.modulate = Color(1, 1, 1)

	btn_capture.disabled = false

func _on_converter_pressed() -> void:
	_register_action()
	used_converter = true

	var msg = "I = %d bits" % i_bits_true
	if i_bits_true % 8 == 0:
		msg += " = %d bytes" % int(i_bits_true / 8)
	if i_bits_true % 8192 == 0:
		msg += " = %d KB" % int(i_bits_true / 8192)

	status_label.text = "Converter: " + msg
	status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))

func _on_capture_pressed() -> void:
	_register_action()
	if selected_storage_idx == -1:
		return
	_finish_trial()

func _finish_trial():
	phase = "DONE"
	var choice: Dictionary = storage_options[selected_storage_idx]
	var choice_cap = int(choice.capacity_bits)

	var calc_correct = (i_bits_user == i_bits_true)
	var calc_error_type = "none"
	if not calc_correct:
		if i_bits_user < i_bits_true:
			calc_error_type = "value_low"
		elif i_bits_user > i_bits_true:
			calc_error_type = "value_high"
		else:
			calc_error_type = "mismatch"

	var is_fit = choice_cap >= i_bits_true
	var is_best_fit = false
	var is_overkill = false
	var waste_ratio = float(choice_cap) / float(i_bits_true)

	var choice_error_type = "overkill_soft"
	if choice.tag == "UNIT_TRAP_BITS_BYTES":
		choice_error_type = "unit_confusion_bits_bytes"
		is_fit = choice_cap >= i_bits_true
	elif choice.tag == "UNIT_TRAP_BYTES_KB":
		choice_error_type = "unit_confusion_bytes_kb"
		is_fit = choice_cap >= i_bits_true
	elif choice_cap < i_bits_true:
		choice_error_type = "underfit"
		is_fit = false
	elif choice.tag == "BEST":
		choice_error_type = "best_fit"
		is_best_fit = true
		is_fit = true
	elif waste_ratio >= 4.0:
		choice_error_type = "overkill_hard"
		is_overkill = true
		is_fit = true
	else:
		choice_error_type = "overkill_soft"
		is_overkill = true
		is_fit = true

	var valid_mastery = (not used_converter) and calc_correct and (choice_error_type == "best_fit")
	var is_correct = calc_correct and choice_error_type == "best_fit"

	var mode_key = "TIMED" if is_timed else "UNTIMED"
	var match_key = "RI_B_%s_K%d_i%d_%s" % [mode_key, k_symbols, i_bits, current_pool_type]

	var payload = {
		"quest_id": "radio_intercept",
		"stage_id": "B",
		"match_key": match_key,
		"pool_type": current_pool_type,
		"dependency_mode": "default_i",
		"is_correct": is_correct,
		"i_bits": i_bits,
		"K_symbols": k_symbols,
		"I_bits_true": i_bits_true,
		"I_bits_user": i_bits_user,
		"calc_correct": calc_correct,
		"calc_error_type": calc_error_type,
		"used_converter": used_converter,
		"choice_capacity_bits": choice_cap,
		"choice_display_size": choice.display_size,
		"choice_display_unit": choice.display_unit,
		"is_fit": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"choice_error_type": choice_error_type,
		"error_type": choice_error_type,
		"valid_for_mastery": valid_mastery,
		"valid_for_diagnostics": true,
		"elapsed_ms": Time.get_ticks_msec() - start_ms,
		"duration": float(Time.get_ticks_msec() - start_ms) / 1000.0,
		"time_to_first_action_ms": (first_action_ms - start_ms) if first_action_ms > 0 else 0,
		"is_timed": is_timed,
		"forced_sampling": forced_sampling
	}

	GlobalMetrics.register_trial(payload)

	btn_capture.visible = false
	btn_next.visible = true

	if is_best_fit and calc_correct:
		status_label.text = "STATUS: Perfect. Calc and storage choice are correct."
		status_label.add_theme_color_override("font_color", COLOR_GREEN)
		_update_sample_strip(COLOR_GREEN)
	elif not is_fit:
		status_label.text = "STATUS: Error. Storage is too small."
		status_label.add_theme_color_override("font_color", COLOR_RED)
		_update_sample_strip(COLOR_RED)
	elif not calc_correct:
		status_label.text = "STATUS: Calculation is incorrect."
		status_label.add_theme_color_override("font_color", COLOR_RED)
		_update_sample_strip(COLOR_RED)
	elif is_overkill:
		status_label.text = "STATUS: Storage fits, but choice is overkill."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		_update_sample_strip(COLOR_YELLOW)
	else:
		status_label.text = "STATUS: Accepted with notes."
		status_label.add_theme_color_override("font_color", COLOR_YELLOW)
		_update_sample_strip(COLOR_YELLOW)

func _update_sample_strip(color: Color) -> void:
	if current_trial_idx < sample_strip.get_child_count():
		var slot = sample_strip.get_child(current_trial_idx)
		var bg: ColorRect = slot.get_node("BG")
		bg.color = color
		current_trial_idx = (current_trial_idx + 1) % sample_strip.get_child_count()

func _on_next_pressed() -> void:
	start_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
