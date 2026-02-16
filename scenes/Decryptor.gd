extends Control

@onready var btn_back = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var mode_label = $UI/SafeArea/Main/HeaderBar/HeaderContent/ModeChip/ModeLabel
@onready var level_label = $UI/SafeArea/Main/HeaderBar/HeaderContent/LevelLabel
@onready var stability_text = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityText
@onready var stability_bar = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityBar
@onready var shield_freq = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldFreq
@onready var shield_lazy = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldLazy
@onready var btn_details = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails

@onready var target_panel = $UI/SafeArea/Main/InstrumentArea/TargetPanel
@onready var target_title = $UI/SafeArea/Main/InstrumentArea/TargetPanel/TargetContent/TargetTitle
@onready var target_value = $UI/SafeArea/Main/InstrumentArea/TargetPanel/TargetContent/TargetValueBig
@onready var target_sub = $UI/SafeArea/Main/InstrumentArea/TargetPanel/TargetContent/TargetSub

@onready var input_panel = $UI/SafeArea/Main/InstrumentArea/InputPanel
@onready var input_bin = $UI/SafeArea/Main/InstrumentArea/InputPanel/InputContent/InputBin
@onready var input_dec = $UI/SafeArea/Main/InstrumentArea/InputPanel/InputContent/InputBasesRow/InputDec
@onready var input_oct = $UI/SafeArea/Main/InstrumentArea/InputPanel/InputContent/InputBasesRow/InputOct
@onready var input_hex = $UI/SafeArea/Main/InstrumentArea/InputPanel/InputContent/InputBasesRow/InputHex

@onready var upper_bits = $UI/SafeArea/Main/InstrumentArea/SwitchesPanel/SwitchesContent/NibblesRow/UpperNibble/UpperBits
@onready var lower_bits = $UI/SafeArea/Main/InstrumentArea/SwitchesPanel/SwitchesContent/NibblesRow/LowerNibble/LowerBits
@onready var weights_row = $UI/SafeArea/Main/InstrumentArea/SwitchesPanel/SwitchesContent/WeightsRow

@onready var btn_hint = $UI/SafeArea/Main/BottomBar/Actions/BtnHint
@onready var btn_check = $UI/SafeArea/Main/BottomBar/Actions/BtnCheck
@onready var btn_reset = $UI/SafeArea/Main/BottomBar/Actions/BtnReset

@onready var toast_panel = $UI/ToastLayer/Toast
@onready var toast_label = $UI/ToastLayer/Toast/ToastLabel

@onready var details_sheet = $UI/DetailsSheet
@onready var btn_close_details = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
@onready var details_text = $UI/DetailsSheet/DetailsContent/DetailsScroll/DetailsText

@onready var safe_overlay = $UI/SafeModeOverlay
@onready var safe_summary = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeSummary
@onready var safe_bits_row = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeBitsRow
@onready var btn_retry = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeActions/BtnRetry
@onready var btn_continue = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeActions/BtnContinue

const COLOR_OK = Color(0.2, 1.0, 0.6, 1)
const COLOR_WARN = Color(1.0, 0.75, 0.2, 1)
const COLOR_ERR = Color(1.0, 0.3, 0.3, 1)

const SWIPE_MIN: float = 60.0
const SWIPE_MAX_Y: float = 40.0

var current_target: int = 0
var current_input: int = 0
var is_level_active: bool = false
var level_started_ms: int = 0
var first_action_ms: int = -1
var check_attempt_count: int = 0
var hint_used: bool = false

var bit_buttons: Array[Button] = []
var weight_labels: Array[Label] = []
var safe_bit_labels: Array[Label] = []

var log_lines: Array[String] = []
var last_hint_text: String = ""

var details_open: bool = false
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_tracking: bool = false

func _ready():
	_build_bit_buttons()
	_build_weight_labels()
	_build_safe_bits()
	_wire_signals()
	_reset_shield_state()
	_hide_overlays()

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not GlobalMetrics.shield_triggered.is_connected(_on_shield_triggered):
		GlobalMetrics.shield_triggered.connect(_on_shield_triggered)

	await get_tree().process_frame
	_set_details_open(false, true)

	start_level(GlobalMetrics.current_level_index)

func _wire_signals() -> void:
	btn_back.pressed.connect(_on_menu_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_check.pressed.connect(_on_check_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func _build_bit_buttons() -> void:
	bit_buttons.clear()
	bit_buttons.resize(8)
	for child in upper_bits.get_children():
		child.queue_free()
	for child in lower_bits.get_children():
		child.queue_free()

	for i in range(8):
		var bit_index = 7 - i
		var btn = Button.new()
		btn.toggle_mode = true
		btn.text = "0"
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggled.connect(_on_bit_toggled.bind(bit_index))
		if i < 4:
			upper_bits.add_child(btn)
		else:
			lower_bits.add_child(btn)
		bit_buttons[bit_index] = btn

func _build_weight_labels() -> void:
	weight_labels.clear()
	for child in weights_row.get_children():
		child.queue_free()

	for _i in range(8):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(0, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		weights_row.add_child(lbl)
		weight_labels.append(lbl)

func _build_safe_bits() -> void:
	safe_bit_labels.clear()
	for child in safe_bits_row.get_children():
		child.queue_free()

	for i in range(8):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(28, 28)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text = "%d" % (7 - i)
		safe_bits_row.add_child(lbl)
		safe_bit_labels.append(lbl)

func start_level(level_idx: int) -> void:
	GlobalMetrics.start_level(level_idx)
	is_level_active = true
	current_target = GlobalMetrics.current_target_value
	current_input = 0
	last_hint_text = ""
	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	check_attempt_count = 0
	hint_used = false

	var mode = GlobalMetrics.current_mode
	mode_label.text = mode
	_update_level_label(level_idx)
	_update_weights_for_mode(mode)
	_update_target_display(level_idx, mode)
	_reset_bit_buttons()
	_update_input_display()
	_log_message("System initialized. Target locked.", COLOR_OK)
	_on_stability_changed(100.0, 0.0)

func _update_level_label(level_idx: int) -> void:
	var protocol = "A" if level_idx < 15 else "B"
	level_label.text = "PROTOCOL %s-%d" % [protocol, level_idx + 1]
func _update_target_display(level_idx: int, mode: String) -> void:
	if level_idx >= 15:
		target_title.text = "EXAMPLE"
		target_value.text = _format_example(mode)
		target_sub.text = "MODE: %s" % mode
	else:
		target_title.text = "TARGET"
		target_value.text = _format_value(current_target, mode)
		if mode == "DEC":
			target_sub.text = ""
		else:
			target_sub.text = "DEC: %d" % current_target

	_pulse_panel(target_panel, Color(0.8, 0.9, 1.0, 1.0))
func _update_weights_for_mode(mode: String) -> void:
	var weights: Array[int] = []
	if mode == "DEC":
		weights = [128, 64, 32, 16, 8, 4, 2, 1]
	elif mode == "OCT":
		weights = [2, 1, 4, 2, 1, 4, 2, 1]
	else:
		weights = [8, 4, 2, 1, 8, 4, 2, 1]

	for i in range(8):
		weight_labels[i].text = str(weights[i])

func _reset_bit_buttons() -> void:
	for i in range(8):
		var btn: Button = bit_buttons[i]
		btn.set_pressed_no_signal(false)
		btn.text = "0"
		btn.modulate = Color(1, 1, 1, 1)

func _update_input_display() -> void:
	var bin = String.num_int64(current_input, 2).pad_zeros(8)
	input_bin.text = "BIN: %s %s" % [bin.substr(0, 4), bin.substr(4, 4)]
	input_dec.text = "DEC: %d" % current_input
	input_oct.text = "OCT: %o" % current_input
	input_hex.text = "HEX: %X" % current_input

func _on_bit_toggled(pressed: bool, bit_index: int) -> void:
	_mark_first_action()
	AudioManager.play("click")
	if pressed:
		current_input |= (1 << bit_index)
		bit_buttons[bit_index].text = "1"
	else:
		current_input &= ~(1 << bit_index)
		bit_buttons[bit_index].text = "0"
	_clear_error_highlights()
	_animate_toggle(bit_buttons[bit_index])
	_update_input_display()

func _on_check_pressed() -> void:
	if not is_level_active:
		return

	_mark_first_action()
	check_attempt_count += 1
	var submitted_input := current_input
	var result: Dictionary = GlobalMetrics.check_solution(current_target, current_input)
	_register_trial(result, submitted_input)

	if result.success:
		AudioManager.play("relay")
		_show_toast("SUCCESS", COLOR_OK)
		_pulse_panel(input_panel, COLOR_OK)
		is_level_active = false
		await get_tree().create_timer(1.0).timeout
		if GlobalMetrics.current_level_index < GlobalMetrics.MAX_LEVELS - 1:
			start_level(GlobalMetrics.current_level_index + 1)
		else:
			_log_message("ALL LEVELS COMPLETE.", COLOR_OK)
	else:
		AudioManager.play("error")
		_pulse_panel(input_panel, COLOR_ERR)
		if result.has("hints"):
			var h = result.hints
			last_hint_text = "Diagnosis: %s | Zone: %s" % [_translate_hint(h.diagnosis), _translate_hint(h.zone)]
			_log_message(last_hint_text, COLOR_WARN)
		_show_toast("INCORRECT", COLOR_ERR)
		_apply_error_highlight(current_input ^ current_target)
func _on_hint_pressed() -> void:
	hint_used = true
	if last_hint_text == "":
		_show_toast("NO HINT AVAILABLE", COLOR_WARN)
		return
	_log_message(last_hint_text, COLOR_WARN)
	_show_toast("HINT SHOWN", COLOR_WARN)
func _on_reset_pressed() -> void:
	current_input = 0
	_reset_bit_buttons()
	_update_input_display()
	_clear_error_highlights()

func _apply_error_highlight(xor_val: int) -> void:
	for bit in range(8):
		var btn: Button = bit_buttons[bit]
		if (xor_val & (1 << bit)) != 0:
			btn.modulate = Color(1, 0.6, 0.6, 1)
		else:
			btn.modulate = Color(1, 1, 1, 1)

func _clear_error_highlights() -> void:
	for bit in range(8):
		bit_buttons[bit].modulate = Color(1, 1, 1, 1)

func _on_stability_changed(new_val: float, _change: float) -> void:
	stability_bar.value = new_val
	stability_text.text = "STABILITY: %d%%" % int(new_val)
	if new_val <= 0:
		_show_safe_mode()

func _on_shield_triggered(name: String, duration: float) -> void:
	if name == "FREQUENCY":
		_flash_shield(shield_freq)
	elif name == "LAZY":
		_flash_shield(shield_lazy)

	btn_check.disabled = true
	_show_toast("SHIELD ACTIVE", COLOR_WARN)
	await get_tree().create_timer(duration).timeout
	btn_check.disabled = false
func _flash_shield(label: Label) -> void:
	label.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0.25), 0.6)

func _reset_shield_state() -> void:
	shield_freq.modulate = Color(1, 1, 1, 0.25)
	shield_lazy.modulate = Color(1, 1, 1, 0.25)

func _show_safe_mode() -> void:
	safe_overlay.visible = true
	btn_check.disabled = true
	btn_hint.disabled = true

	var xor_val = current_input ^ current_target
	var wrong_bits = 0
	for bit in range(8):
		if (xor_val & (1 << bit)) != 0:
			wrong_bits += 1

	safe_summary.text = "Target: %s\nInput: %s\nWrong bits: %d" % [
		_format_value(current_target, GlobalMetrics.current_mode),
		_format_value(current_input, GlobalMetrics.current_mode),
		wrong_bits
	]

	for i in range(8):
		var bit_index = 7 - i
		var lbl = safe_bit_labels[i]
		if (xor_val & (1 << bit_index)) != 0:
			lbl.modulate = Color(1, 0.3, 0.3, 1)
		else:
			lbl.modulate = Color(0.7, 0.7, 0.7, 1)
func _on_retry_pressed() -> void:
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(100.0, 0.0)
	safe_overlay.visible = false
	btn_check.disabled = false
	btn_hint.disabled = false
	start_level(GlobalMetrics.current_level_index)

func _on_continue_pressed() -> void:
	GlobalMetrics.stability = 30.0
	GlobalMetrics.stability_changed.emit(30.0, 0.0)
	safe_overlay.visible = false
	btn_check.disabled = false
	btn_hint.disabled = false

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_pressed() -> void:
	_set_details_open(not details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	details_open = open
	if open:
		details_sheet.visible = true

	var target_offset = -details_sheet.size.y if open else 0.0
	if immediate:
		details_sheet.offset_top = target_offset
		if not open:
			details_sheet.visible = false
		return

	var tween = create_tween()
	tween.tween_property(details_sheet, "offset_top", target_offset, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not open:
		tween.tween_callback(func(): details_sheet.visible = false)
func _hide_overlays() -> void:
	toast_panel.visible = false
	safe_overlay.visible = false
	details_sheet.visible = false

func _show_toast(msg: String, color: Color) -> void:
	toast_label.text = msg
	toast_label.add_theme_color_override("font_color", color)
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(toast_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	tween.tween_interval(0.9)
	tween.tween_property(toast_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.tween_callback(func(): toast_panel.visible = false)

func _animate_toggle(btn: Button) -> void:
	btn.scale = Vector2(0.96, 0.96)
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1, 1), 0.1)

func _pulse_panel(panel: Control, color: Color) -> void:
	panel.modulate = color
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.25)

func _translate_hint(code: String) -> String:
	match code:
		"VALUE_LOW": return "Value is lower than target"
		"VALUE_HIGH": return "Value is higher than target"
		"BIT_ERROR": return "Bit mismatch"
		"BOTH_NIBBLES": return "Errors in both nibbles"
		"LOWER_NIBBLE": return "Errors in lower nibble (bits 0-3)"
		"UPPER_NIBBLE": return "Errors in upper nibble (bits 4-7)"
		"NONE": return "No mismatch"
	return code
func _log_message(msg: String, color: Color) -> void:
	var time_str = Time.get_time_string_from_system()
	var line = "[%s] %s" % [time_str, msg]
	log_lines.append(line)
	if log_lines.size() > 200:
		log_lines.remove_at(0)
	details_text.text = "\n".join(log_lines)

func _format_value(val: int, mode: String) -> String:
	if mode == "DEC":
		return "%d" % val
	elif mode == "OCT":
		return "%o" % val
	elif mode == "HEX":
		return "%X" % val
	return "%d" % val

func _format_example(mode: String) -> String:
	var a = GlobalMetrics.current_reg_a
	var b = GlobalMetrics.current_reg_b
	var op = GlobalMetrics.current_operator
	var a_txt = _format_value(a, mode)
	var b_txt = _format_value(b, mode)
	if op == GlobalMetrics.Operator.ADD:
		return "%s + %s" % [a_txt, b_txt]
	elif op == GlobalMetrics.Operator.SUB:
		return "%s - %s" % [a_txt, b_txt]
	else:
		return "%s << %s" % [a_txt, b_txt]

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_switches(event.position):
				_swipe_start_pos = event.position
				_swipe_tracking = true
		else:
			if _swipe_tracking:
				var delta = event.position - _swipe_start_pos
				if abs(delta.x) >= SWIPE_MIN and abs(delta.y) <= SWIPE_MAX_Y:
					_apply_shift_left()
				_swipe_tracking = false
	elif event is InputEventMouseButton:
		if event.pressed:
			if _is_in_switches(event.position):
				_swipe_start_pos = event.position
				_swipe_tracking = true
		else:
			if _swipe_tracking:
				var delta_mouse = event.position - _swipe_start_pos
				if abs(delta_mouse.x) >= SWIPE_MIN and abs(delta_mouse.y) <= SWIPE_MAX_Y:
					_apply_shift_left()
				_swipe_tracking = false

func _is_in_switches(pos: Vector2) -> bool:
	return upper_bits.get_global_rect().has_point(pos) or lower_bits.get_global_rect().has_point(pos)

func _apply_shift_left() -> void:
	_mark_first_action()
	current_input = (current_input << 1) & 0xFF
	_sync_switches_to_input()
	_update_input_display()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms

func _register_trial(result: Dictionary, submitted_input: int) -> void:
	var level_number := GlobalMetrics.current_level_index + 1
	var stage_id := "A" if GlobalMetrics.current_level_index < 15 else "B"
	var task_id := "%s_%02d" % [stage_id, level_number]
	var variant_source := "%s|%s|%d" % [GlobalMetrics.current_mode, stage_id, current_target]
	var payload := TrialV2.build("DECRYPTOR", stage_id, task_id, "NUMERIC_ENTRY", str(hash(variant_source)))
	var elapsed_ms := max(0, Time.get_ticks_msec() - level_started_ms)
	var is_success := bool(result.get("success", false))
	var error_code := str(result.get("error", "NONE"))
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_success
	payload["is_fit"] = is_success
	payload["stability_delta"] = 0
	payload["level_index"] = GlobalMetrics.current_level_index
	payload["mode"] = GlobalMetrics.current_mode
	payload["target_value"] = current_target
	payload["input_value"] = submitted_input
	payload["check_attempt_count"] = check_attempt_count
	payload["hint_used"] = hint_used
	payload["error_type"] = error_code
	payload["penalty_reported"] = float(result.get("penalty", 0.0))
	if result.has("hamming"):
		payload["hamming"] = int(result.get("hamming", 0))
	GlobalMetrics.register_trial(payload)

func _sync_switches_to_input() -> void:
	for bit in range(8):
		var pressed = ((current_input >> bit) & 1) == 1
		var btn: Button = bit_buttons[bit]
		btn.set_pressed_no_signal(pressed)
		btn.text = "1" if pressed else "0"
