extends Control

const TrialV2 = preload("res://scripts/TrialV2.gd")

@onready var btn_back = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var mode_label = $UI/SafeArea/Main/HeaderBar/HeaderContent/ModeChip/ModeLabel
@onready var level_label = $UI/SafeArea/Main/HeaderBar/HeaderContent/LevelLabel
@onready var stability_text = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityText
@onready var stability_bar = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityBar
@onready var shield_freq = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldFreq
@onready var shield_lazy = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldLazy
@onready var btn_details = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails
@onready var noir_overlay = $UI/NoirOverlay
@onready var safe_area: MarginContainer = $UI/SafeArea
@onready var main_root: VBoxContainer = $UI/SafeArea/Main
@onready var header_content: HBoxContainer = $UI/SafeArea/Main/HeaderBar/HeaderContent
@onready var content_split: HBoxContainer = $UI/SafeArea/Main/ContentSplit
@onready var left_panel: VBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel
@onready var right_panel: VBoxContainer = $UI/SafeArea/Main/ContentSplit/RightPanel
@onready var bottom_actions: HBoxContainer = $UI/SafeArea/Main/BottomBar/Actions

@onready var target_panel = $UI/SafeArea/Main/ContentSplit/LeftPanel/TargetPanel
@onready var target_title = $UI/SafeArea/Main/ContentSplit/LeftPanel/TargetPanel/TargetContent/TargetTitle
@onready var target_value = $UI/SafeArea/Main/ContentSplit/LeftPanel/TargetPanel/TargetContent/TargetValueBig
@onready var target_sub = $UI/SafeArea/Main/ContentSplit/LeftPanel/TargetPanel/TargetContent/TargetSub

@onready var input_panel = $UI/SafeArea/Main/ContentSplit/LeftPanel/InputPanel
@onready var input_bin = $UI/SafeArea/Main/ContentSplit/LeftPanel/InputPanel/InputContent/InputBin
@onready var input_dec = $UI/SafeArea/Main/ContentSplit/LeftPanel/InputPanel/InputContent/InputBasesRow/InputDec
@onready var input_oct = $UI/SafeArea/Main/ContentSplit/LeftPanel/InputPanel/InputContent/InputBasesRow/InputOct
@onready var input_hex = $UI/SafeArea/Main/ContentSplit/LeftPanel/InputPanel/InputContent/InputBasesRow/InputHex

@onready var upper_bits = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/NibblesCenter/NibblesRow/UpperNibble/UpperBits
@onready var lower_bits = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/NibblesCenter/NibblesRow/LowerNibble/LowerBits
@onready var nibbles_center = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/NibblesCenter
@onready var weights_row = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/WeightsRow

@onready var rank_label = $UI/SafeArea/Main/ContentSplit/RightPanel/RankPanel/RankContent/RankLabel
@onready var progress_label = $UI/SafeArea/Main/ContentSplit/RightPanel/RankPanel/RankContent/ProgressLabel
@onready var rank_title = $UI/SafeArea/Main/ContentSplit/RightPanel/RankPanel/RankContent/RankTitle
@onready var reg_a_value = $UI/SafeArea/Main/ContentSplit/RightPanel/ProtocolPanel/ProtocolContent/RegsRow/RegAValue
@onready var reg_b_value = $UI/SafeArea/Main/ContentSplit/RightPanel/ProtocolPanel/ProtocolContent/RegsRow/RegBValue
@onready var op_value = $UI/SafeArea/Main/ContentSplit/RightPanel/ProtocolPanel/ProtocolContent/RegsRow/OpValue
@onready var shift_status = $UI/SafeArea/Main/ContentSplit/RightPanel/ProtocolPanel/ProtocolContent/ShiftStatus
@onready var protocol_title = $UI/SafeArea/Main/ContentSplit/RightPanel/ProtocolPanel/ProtocolContent/ProtocolTitle
@onready var live_log_title = $UI/SafeArea/Main/ContentSplit/RightPanel/LiveLogPanel/LiveLogContent/LiveLogTitle
@onready var hint_title = $UI/SafeArea/Main/ContentSplit/RightPanel/HintPanel/HintContent/HintTitle
@onready var live_log_text = $UI/SafeArea/Main/ContentSplit/RightPanel/LiveLogPanel/LiveLogContent/LiveLogText
@onready var hint_text = $UI/SafeArea/Main/ContentSplit/RightPanel/HintPanel/HintContent/HintText

@onready var btn_hint = $UI/SafeArea/Main/BottomBar/Actions/BtnHint
@onready var btn_check = $UI/SafeArea/Main/BottomBar/Actions/BtnCheck
@onready var btn_reset = $UI/SafeArea/Main/BottomBar/Actions/BtnReset
@onready var upper_title = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/NibblesCenter/NibblesRow/UpperNibble/UpperTitle
@onready var lower_title = $UI/SafeArea/Main/ContentSplit/LeftPanel/SwitchesPanel/SwitchesContent/NibblesCenter/NibblesRow/LowerNibble/LowerTitle

@onready var toast_panel = $UI/ToastLayer/Toast
@onready var toast_label = $UI/ToastLayer/Toast/ToastLabel

@onready var details_sheet = $UI/DetailsSheet
@onready var btn_close_details = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
@onready var details_scroll: ScrollContainer = $UI/DetailsSheet/DetailsContent/DetailsScroll
@onready var details_text = $UI/DetailsSheet/DetailsContent/DetailsScroll/DetailsText
@onready var details_title = $UI/DetailsSheet/DetailsContent/DetailsHeader/DetailsTitle

@onready var safe_overlay = $UI/SafeModeOverlay
@onready var safe_summary = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeSummary
@onready var safe_bits_row = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeBitsRow
@onready var safe_title = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeTitle
@onready var btn_retry = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeActions/BtnRetry
@onready var btn_continue = $UI/SafeModeOverlay/CenterContainer/SafePanel/SafeContent/SafeActions/BtnContinue

const COLOR_OK = Color(0.2, 1.0, 0.6, 1)
const COLOR_WARN = Color(1.0, 0.75, 0.2, 1)
const COLOR_ERR = Color(1.0, 0.3, 0.3, 1)

const SWIPE_MIN: float = 60.0
const SWIPE_MAX_Y: float = 40.0
const DETAILS_SHEET_H: float = 380.0
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 740.0
const PHONE_PORTRAIT_MAX_WIDTH: float = 520.0

var current_target: int = 0
var current_input: int = 0
var is_level_active: bool = false
var level_started_ms: int = 0
var first_action_ms: int = -1
var check_attempt_count: int = 0
var hint_used: bool = false
var trial_seq: int = 0
var task_session: Dictionary = {}
var bit_toggle_count: int = 0
var bit_toggle_unique: Dictionary = {}
var bit_retoggle_count: int = 0
var reset_count: int = 0
var retry_count: int = 0
var continue_count: int = 0
var details_open_count: int = 0
var details_open_before_check: bool = false
var details_close_count: int = 0
var hint_open_count: int = 0
var safe_mode_open_count: int = 0

var first_check_ms: int = -1
var last_check_ms: int = -1
var time_to_hint_ms: int = -1
var time_to_details_ms: int = -1
var time_to_reset_ms: int = -1

var min_hamming_seen: int = 999
var last_hamming_seen: int = -1
var hamming_improved_before_success: bool = false

var current_streak_without_change: int = 0
var check_without_change_count: int = 0
var changed_after_hint: bool = false
var changed_after_details: bool = false

var used_reset_before_success: bool = false
var used_retry_after_fail: bool = false

var _input_changed_since_last_check: bool = false
var _last_check_failed: bool = false
var _last_shield_code: String = "NONE"
var _safe_mode_used: bool = false

var bit_buttons: Array[Button] = []
var weight_labels: Array[Label] = []
var safe_bit_labels: Array[Label] = []

var log_lines: Array[String] = []
var _hint_state_kind: String = "none"
var _hint_state_key: String = ""
var _hint_state_default: String = ""
var _hint_state_params: Dictionary = {}
var _hint_diag_code: String = ""
var _hint_zone_code: String = ""
var _hint_hd: int = 0
var _has_last_hint: bool = false
var _shift_status_token: int = 0
var _shift_state_key: String = ""
var _shift_state_default: String = ""
var _shift_state_params: Dictionary = {}
var _shift_state_color: Color = Color(1, 1, 1, 1)

var details_open: bool = false
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_tracking: bool = false
var _content_mobile_layout: VBoxContainer = null
var _details_sheet_height: float = DETAILS_SHEET_H
var _body_scroll_installed: bool = false
var _body_scroll: ScrollContainer = null
var _nibbles_grid_installed: bool = false
var _nibbles_grid: GridContainer = null
var _quest_started: bool = false
var _quest_finished: bool = false

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
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	_apply_i18n()

	await get_tree().process_frame
	_set_details_open(false, true)

	_start_quest_tracking()
	start_level(GlobalMetrics.current_level_index)
	_on_viewport_size_changed()
	_install_body_scroll()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	_finish_quest_once(false)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _apply_i18n() -> void:
	btn_details.text = _tr("decryptor.ab.ui.btn_details", "LOG")
	upper_title.text = _tr("decryptor.ab.ui.upper_nibble", "UPPER")
	lower_title.text = _tr("decryptor.ab.ui.lower_nibble", "LOWER")
	rank_title.text = _tr("decryptor.ab.ui.rank_title", "RANK")
	protocol_title.text = _tr("decryptor.ab.ui.protocol_title", "PROTOCOL DIAGNOSTICS")
	live_log_title.text = _tr("decryptor.ab.ui.live_log_title", "LIVE TERMINAL")
	hint_title.text = _tr("decryptor.ab.ui.hint_title", "LAST DIAGNOSTIC")
	btn_hint.text = _tr("decryptor.ab.ui.btn_hint", "HINT")
	btn_check.text = _tr("decryptor.ab.ui.btn_check", "CHECK")
	btn_reset.text = _tr("decryptor.ab.ui.btn_reset", "RESET")
	details_title.text = _tr("decryptor.ab.ui.details_title", "DETAILS")
	btn_close_details.text = _tr("decryptor.ab.ui.btn_close_details", "CLOSE")
	safe_title.text = _tr("decryptor.ab.ui.safe_title", "SAFE MODE: ERROR ANALYSIS")
	btn_retry.text = _tr("decryptor.ab.ui.btn_retry", "RETRY")
	btn_continue.text = _tr("decryptor.ab.ui.btn_continue", "CONTINUE")

	if GlobalMetrics != null:
		var level_idx: int = GlobalMetrics.current_level_index
		_update_level_label(level_idx)
		_update_rank_info()
		_update_target_display(level_idx, GlobalMetrics.current_mode)
		_update_protocol_diagnostics()
		_on_stability_changed(GlobalMetrics.stability, 0.0)

	_apply_hint_state()
	_apply_shift_state()
	if safe_overlay.visible:
		_update_safe_summary()

func _set_hint_key(key: String, default_text: String, params: Dictionary = {}) -> void:
	_hint_state_kind = "key"
	_hint_state_key = key
	_hint_state_default = default_text
	_hint_state_params = params.duplicate(true)
	_apply_hint_state()

func _set_hint_diagnosis(diagnosis_code: String, zone_code: String, hd: int) -> void:
	_hint_state_kind = "diagnosis"
	_hint_diag_code = diagnosis_code
	_hint_zone_code = zone_code
	_hint_hd = hd
	_apply_hint_state()

func _build_diagnosis_line() -> String:
	return _tr("decryptor.ab.hint.diagnosis_zone", "Diagnosis: {diagnosis} | Zone: {zone}", {
		"diagnosis": _translate_hint(_hint_diag_code),
		"zone": _translate_hint(_hint_zone_code)
	})

func _apply_hint_state() -> void:
	match _hint_state_kind:
		"key":
			hint_text.text = _tr(_hint_state_key, _hint_state_default, _hint_state_params)
		"diagnosis":
			var line := _build_diagnosis_line()
			hint_text.text = _tr("decryptor.ab.hint.diagnosis_with_hd", "{line}\nHD: {hd}", {
				"line": line,
				"hd": _hint_hd
			})
		_:
			hint_text.text = ""

func _set_shift_status_i18n(key: String, default_text: String, color: Color, auto_reset: bool, params: Dictionary = {}) -> void:
	_shift_state_key = key
	_shift_state_default = default_text
	_shift_state_params = params.duplicate(true)
	_shift_state_color = color
	_set_shift_status(_tr(key, default_text, params), color, auto_reset)

func _apply_shift_state() -> void:
	if _shift_state_key.is_empty():
		return
	_set_shift_status(_tr(_shift_state_key, _shift_state_default, _shift_state_params), _shift_state_color, false)

func _update_safe_summary() -> void:
	var xor_val = current_input ^ current_target
	var wrong_bits = 0
	for bit in range(8):
		if (xor_val & (1 << bit)) != 0:
			wrong_bits += 1
	safe_summary.text = _tr("decryptor.ab.safe.summary", "Target: {target}\nInput: {input}\nWrong bits: {count}", {
		"target": _format_value(current_target, GlobalMetrics.current_mode),
		"input": _format_value(current_input, GlobalMetrics.current_mode),
		"count": wrong_bits
	})

func _show_toast_key(key: String, default_text: String, color: Color, params: Dictionary = {}) -> void:
	_show_toast(_tr(key, default_text, params), color)

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

func _start_quest_tracking() -> void:
	if _quest_started:
		return
	GlobalMetrics.start_quest("Decryptor_AB")
	_quest_started = true
	_quest_finished = false

func _finish_quest_once(success: bool) -> void:
	if not _quest_started or _quest_finished:
		return
	GlobalMetrics.finish_quest("Decryptor_AB", 100 if success else 0, success)
	_quest_finished = true

func start_level(level_idx: int) -> void:
	GlobalMetrics.start_level(level_idx)
	is_level_active = true
	current_target = GlobalMetrics.current_target_value
	current_input = 0
	_has_last_hint = false
	_hint_diag_code = ""
	_hint_zone_code = ""
	_hint_hd = 0
	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	check_attempt_count = 0
	hint_used = false
	trial_seq += 1
	task_session = {
		"events": [],
		"trial_seq": trial_seq
	}
	bit_toggle_count = 0
	bit_toggle_unique.clear()
	bit_retoggle_count = 0
	reset_count = 0
	retry_count = 0
	continue_count = 0
	details_open_count = 0
	details_open_before_check = false
	details_close_count = 0
	hint_open_count = 0
	safe_mode_open_count = 0
	first_check_ms = -1
	last_check_ms = -1
	time_to_hint_ms = -1
	time_to_details_ms = -1
	time_to_reset_ms = -1
	last_hamming_seen = _calc_hamming(current_input, current_target)
	min_hamming_seen = last_hamming_seen
	hamming_improved_before_success = false
	current_streak_without_change = 0
	check_without_change_count = 0
	changed_after_hint = false
	changed_after_details = false
	used_reset_before_success = false
	used_retry_after_fail = false
	_input_changed_since_last_check = false
	_last_check_failed = false
	_last_shield_code = "NONE"
	_safe_mode_used = false

	var mode = GlobalMetrics.current_mode
	mode_label.text = mode
	_update_level_label(level_idx)
	_update_rank_info()
	_update_weights_for_mode(mode)
	_update_target_display(level_idx, mode)
	_update_protocol_diagnostics()
	_set_hint_key("decryptor.ab.hint.none", "No diagnostics yet.")
	_reset_bit_buttons()
	_update_input_display()
	_log_message(_tr("decryptor.ab.log.system_ready", "System initialized. Target locked."), COLOR_OK)
	_on_stability_changed(100.0, 0.0)
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"stage_id": "A" if level_idx < 15 else "B",
		"level_index": level_idx,
		"mode": mode,
		"target_value": current_target
	})

func _update_level_label(level_idx: int) -> void:
	var protocol = "A" if level_idx < 15 else "B"
	level_label.text = _tr("decryptor.ab.level_label", "PROTOCOL {protocol}-{index}", {
		"protocol": protocol,
		"index": level_idx + 1
	})

func _update_rank_info() -> void:
	var rank_info: Dictionary = GlobalMetrics.get_rank_info()
	var rank_key := "decryptor.ab.rank.master"
	if GlobalMetrics.current_level_index < 5:
		rank_key = "decryptor.ab.rank.intern"
	elif GlobalMetrics.current_level_index < 10:
		rank_key = "decryptor.ab.rank.signalist"
	elif GlobalMetrics.current_level_index < 15:
		rank_key = "decryptor.ab.rank.analyst"
	elif GlobalMetrics.current_level_index < 30:
		rank_key = "decryptor.ab.rank.engineer"
	rank_label.text = _tr(rank_key, "NOVICE")
	progress_label.text = _tr("decryptor.ab.progress_label", "LEVEL {current} / {total}", {
		"current": GlobalMetrics.current_level_index + 1,
		"total": GlobalMetrics.MAX_LEVELS
	})
	if rank_info.has("color"):
		rank_label.add_theme_color_override("font_color", rank_info["color"])

func _update_target_display(level_idx: int, mode: String) -> void:
	if level_idx >= 15:
		target_title.text = _tr("decryptor.ab.target.example", "EXAMPLE")
		target_value.text = _format_example(mode)
		target_sub.text = _tr("decryptor.ab.target.mode", "MODE: {mode}", {"mode": mode})
	else:
		target_title.text = _tr("decryptor.ab.target.title", "TARGET")
		target_value.text = _format_value(current_target, mode)
		if mode == "DEC":
			target_sub.text = ""
		else:
			target_sub.text = "DEC: %d" % current_target

	_pulse_panel(target_panel, Color(0.55, 1.0, 0.65, 1.0))

func _update_protocol_diagnostics() -> void:
	if GlobalMetrics.current_level_index >= 15:
		reg_a_value.text = "A: %s" % _format_value(GlobalMetrics.current_reg_a, GlobalMetrics.current_mode)
		reg_b_value.text = "B: %s" % _format_value(GlobalMetrics.current_reg_b, GlobalMetrics.current_mode)
		op_value.text = "OP: %s" % _operator_to_text(GlobalMetrics.current_operator)
		_set_shift_status_i18n("decryptor.ab.shift.swipe", "SHIFT: swipe left to apply", Color(0.7, 0.9, 0.7, 1.0), false)
	else:
		reg_a_value.text = "A: --"
		reg_b_value.text = "B: --"
		op_value.text = "OP: --"
		_set_shift_status_i18n("decryptor.ab.shift.waiting", "SHIFT: waiting", Color(0.65, 0.65, 0.65, 1.0), false)

func _operator_to_text(op: int) -> String:
	if op == GlobalMetrics.Operator.ADD:
		return "+"
	if op == GlobalMetrics.Operator.SUB:
		return "-"
	return "<<"

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
	bit_toggle_count += 1
	if bit_toggle_unique.has(bit_index):
		bit_retoggle_count += 1
	else:
		bit_toggle_unique[bit_index] = true
	if pressed:
		current_input |= (1 << bit_index)
		bit_buttons[bit_index].text = "1"
	else:
		current_input &= ~(1 << bit_index)
		bit_buttons[bit_index].text = "0"
	var hamming_to_target: int = _register_input_change()
	_clear_error_highlights()
	_animate_toggle(bit_buttons[bit_index])
	_update_input_display()
	_log_event("bit_toggled", {
		"bit_index": bit_index,
		"pressed": pressed,
		"input_value": current_input,
		"hamming_to_target": hamming_to_target
	})

func _on_check_pressed() -> void:
	if not is_level_active:
		return

	_mark_first_action()
	check_attempt_count += 1
	var check_ms: int = _elapsed_level_ms()
	if first_check_ms < 0:
		first_check_ms = check_ms
	last_check_ms = check_ms
	if _input_changed_since_last_check:
		current_streak_without_change = 0
	else:
		current_streak_without_change += 1
		check_without_change_count += 1
	_input_changed_since_last_check = false
	var submitted_input := current_input
	var hamming_to_target: int = _calc_hamming(submitted_input, current_target)
	_update_hamming_metrics(hamming_to_target)
	_log_event("check_pressed", {
		"attempt": check_attempt_count,
		"submitted_input": submitted_input,
		"hamming_to_target": hamming_to_target
	})
	var result: Dictionary = GlobalMetrics.check_solution(current_target, current_input)
	var error_code := str(result.get("error", ""))
	var is_success: bool = bool(result.get("success", false))
	if not is_success:
		_record_mistake(result, submitted_input, error_code)
	_last_check_failed = not is_success
	if error_code.begins_with("SHIELD"):
		_last_shield_code = error_code
	_log_event("check_result", {
		"success": is_success,
		"error_code": error_code,
		"penalty": float(result.get("penalty", 0.0)),
		"hamming": int(result.get("hamming", -1))
	})

	if error_code.begins_with("SHIELD"):
		if error_code == "SHIELD_ACTIVE":
			var now_sec := Time.get_ticks_msec() / 1000.0
			var cooldown_left := maxf(0.0, float(GlobalMetrics.blocked_until) - now_sec)
			_set_hint_key("decryptor.ab.hint.shield_cooldown", "Shield cooldown: {seconds}s.", {
				"seconds": "%.1f" % cooldown_left
			})
			_show_toast_key("decryptor.ab.toast.shield_cooldown", "SHIELD: COOLDOWN {seconds}s", COLOR_WARN, {
				"seconds": "%.1f" % cooldown_left
			})
			_log_message(_tr("decryptor.ab.log.shield_cooldown", "Shield cooldown {seconds}s.", {
				"seconds": "%.1f" % cooldown_left
			}), COLOR_WARN)
			_log_event("shield_triggered", {
				"shield_code": "SHIELD_ACTIVE",
				"cooldown_left_sec": cooldown_left
			})
		elif error_code == "SHIELD_FREQ":
			_set_hint_key("decryptor.ab.hint.shield_freq", "Frequency shield triggered: too many checks.")
		elif error_code == "SHIELD_LAZY":
			_set_hint_key("decryptor.ab.hint.shield_lazy", "Lazy search detected. Change input in larger steps.")
		else:
			_set_hint_key("decryptor.ab.hint.shield_active", "Shield is active. Wait for recharge.")
		_register_trial(result, submitted_input)
		return

	_register_trial(result, submitted_input)

	if is_success:
		AudioManager.play("relay")
		_show_toast_key("decryptor.ab.toast.success", "SUCCESS", COLOR_OK)
		_pulse_panel(input_panel, COLOR_OK)
		_overlay_glitch(0.15, 0.12)
		is_level_active = false
		await get_tree().create_timer(1.0).timeout
		if GlobalMetrics.current_level_index < GlobalMetrics.MAX_LEVELS - 1:
			start_level(GlobalMetrics.current_level_index + 1)
		else:
			_log_message(_tr("decryptor.ab.log.all_levels_done", "ALL LEVELS COMPLETED."), COLOR_OK)
			_finish_quest_once(true)
	else:
		AudioManager.play("error")
		_pulse_panel(input_panel, COLOR_ERR)
		_overlay_glitch(0.6, 0.2)
		if result.has("hints"):
			var h: Dictionary = result.hints
			_has_last_hint = true
			_hint_diag_code = str(h.get("diagnosis", ""))
			_hint_zone_code = str(h.get("zone", ""))
			_hint_hd = int(result.get("hamming", 0))
			_set_hint_diagnosis(_hint_diag_code, _hint_zone_code, _hint_hd)
			_log_message(_build_diagnosis_line(), COLOR_WARN)
		else:
			_set_hint_key("decryptor.ab.hint.incorrect_generic", "Incorrect input.")
		_show_toast_key("decryptor.ab.toast.incorrect", "INCORRECT", COLOR_ERR)
		_apply_error_highlight(current_input ^ current_target)

func _on_hint_pressed() -> void:
	_mark_first_action()
	hint_used = true
	hint_open_count += 1
	if time_to_hint_ms < 0:
		time_to_hint_ms = _elapsed_level_ms()
	_log_event("hint_opened", {
		"hint_open_count": hint_open_count,
		"input_value": current_input,
		"hamming_to_target": _calc_hamming(current_input, current_target),
		"hint_available": _has_last_hint,
		"diagnosis_code": _hint_diag_code,
		"zone_code": _hint_zone_code,
		"hint_hd": _hint_hd
	})
	if not _has_last_hint:
		_set_hint_key("decryptor.ab.hint.unavailable", "Diagnostics unavailable. Run a check first.")
		_show_toast_key("decryptor.ab.toast.hint_unavailable", "HINT UNAVAILABLE", COLOR_WARN)
		return
	_set_hint_diagnosis(_hint_diag_code, _hint_zone_code, _hint_hd)
	_log_message(_build_diagnosis_line(), COLOR_WARN)
	_show_toast_key("decryptor.ab.toast.hint_shown", "HINT SHOWN", COLOR_WARN)

func _on_reset_pressed() -> void:
	_mark_first_action()
	reset_count += 1
	if time_to_reset_ms < 0:
		time_to_reset_ms = _elapsed_level_ms()
	var prev_input: int = current_input
	current_input = 0
	_reset_bit_buttons()
	_update_input_display()
	var hamming_to_target: int = _register_input_change()
	_clear_error_highlights()
	_set_shift_status_i18n("decryptor.ab.shift.waiting", "SHIFT: waiting", Color(0.65, 0.65, 0.65, 1.0), false)
	_log_event("reset_pressed", {
		"reset_count": reset_count,
		"input_before": prev_input,
		"input_after": current_input,
		"hamming_to_target": hamming_to_target
	})

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
	stability_text.text = _tr("decryptor.ab.stability", "STABILITY: {value}%", {"value": int(new_val)})
	if new_val <= 0:
		_show_safe_mode()

func _on_shield_triggered(shield_name: String, duration: float) -> void:
	var shield_code: String = "SHIELD_ACTIVE"
	if shield_name == "FREQUENCY":
		_flash_shield(shield_freq)
		shield_code = "SHIELD_FREQ"
	elif shield_name == "LAZY":
		_flash_shield(shield_lazy)
		shield_code = "SHIELD_LAZY"
	_last_shield_code = shield_code
	_log_event("shield_triggered", {
		"shield_name": shield_name,
		"shield_code": shield_code,
		"duration_sec": duration
	})

	btn_check.disabled = true
	_overlay_glitch(0.6, 0.2)
	_show_toast_key("decryptor.ab.toast.shield_active", "SHIELD ACTIVE", COLOR_WARN)
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
	var was_visible: bool = safe_overlay.visible
	safe_overlay.visible = true
	btn_check.disabled = true
	btn_hint.disabled = true
	_update_safe_summary()
	if not was_visible:
		safe_mode_open_count += 1
		_safe_mode_used = true
		var hamming_to_target: int = _calc_hamming(current_input, current_target)
		_log_event("safe_mode_enabled", {
			"safe_mode_open_count": safe_mode_open_count,
			"hamming_to_target": hamming_to_target
		})
		_log_event("safe_mode_summary_opened", {
			"target_value": current_target,
			"input_value": current_input,
			"hamming_to_target": hamming_to_target
		})

	var xor_val = current_input ^ current_target
	for i in range(8):
		var bit_index = 7 - i
		var lbl = safe_bit_labels[i]
		if (xor_val & (1 << bit_index)) != 0:
			lbl.modulate = Color(1, 0.3, 0.3, 1)
		else:
			lbl.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_retry_pressed() -> void:
	var had_failed_before_retry: bool = _last_check_failed
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(100.0, 0.0)
	safe_overlay.visible = false
	btn_check.disabled = false
	btn_hint.disabled = false
	start_level(GlobalMetrics.current_level_index)
	retry_count += 1
	used_retry_after_fail = had_failed_before_retry
	_log_event("retry_pressed", {
		"retry_count": retry_count,
		"used_retry_after_fail": used_retry_after_fail
	})

func _on_continue_pressed() -> void:
	GlobalMetrics.stability = 30.0
	GlobalMetrics.stability_changed.emit(30.0, 0.0)
	safe_overlay.visible = false
	btn_check.disabled = false
	btn_hint.disabled = false
	continue_count += 1
	_log_event("continue_pressed", {
		"continue_count": continue_count,
		"stability_after_continue": GlobalMetrics.stability
	})

func _on_menu_pressed() -> void:
	_finish_quest_once(false)
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_pressed() -> void:
	_mark_first_action()
	_set_details_open(not details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	var was_open: bool = details_open
	var state_changed: bool = was_open != open
	details_open = open
	if state_changed:
		if open:
			details_open_count += 1
			if first_check_ms < 0:
				details_open_before_check = true
			if time_to_details_ms < 0:
				time_to_details_ms = _elapsed_level_ms()
			_log_event("details_opened", {
				"details_open_count": details_open_count,
				"before_first_check": first_check_ms < 0
			})
		else:
			details_close_count += 1
			_log_event("details_closed", {
				"details_close_count": details_close_count
			})
	if open:
		details_sheet.visible = true

	var target_top := -_details_sheet_height if open else 0.0
	var target_bottom := 0.0 if open else _details_sheet_height
	if immediate:
		details_sheet.offset_top = target_top
		details_sheet.offset_bottom = target_bottom
		if not open:
			details_sheet.visible = false
		return

	var tween = create_tween()
	tween.tween_property(details_sheet, "offset_top", target_top, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(details_sheet, "offset_bottom", target_bottom, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
		"VALUE_LOW":
			return _tr("decryptor.ab.hint_code.value_low", "Value is below target")
		"VALUE_HIGH":
			return _tr("decryptor.ab.hint_code.value_high", "Value is above target")
		"BIT_ERROR":
			return _tr("decryptor.ab.hint_code.bit_error", "Bit mismatch")
		"BOTH_NIBBLES":
			return _tr("decryptor.ab.hint_code.both_nibbles", "Errors in both nibbles")
		"LOWER_NIBBLE":
			return _tr("decryptor.ab.hint_code.lower_nibble", "Errors in lower nibble (bits 0-3)")
		"UPPER_NIBBLE":
			return _tr("decryptor.ab.hint_code.upper_nibble", "Errors in upper nibble (bits 4-7)")
		"NONE":
			return _tr("decryptor.ab.hint_code.none", "No mismatches")
	return code

func _set_shift_status(text: String, color: Color, auto_reset: bool) -> void:
	shift_status.text = text
	shift_status.add_theme_color_override("font_color", color)
	if not auto_reset:
		return
	_shift_status_token += 1
	var token = _shift_status_token
	_reset_shift_status_later(token)

func _reset_shift_status_later(token: int) -> void:
	await get_tree().create_timer(0.9).timeout
	if token != _shift_status_token:
		return
	if GlobalMetrics.current_level_index >= 15:
		_set_shift_status_i18n("decryptor.ab.shift.swipe", "SHIFT: swipe left to apply", Color(0.7, 0.9, 0.7, 1.0), false)
	else:
		_set_shift_status_i18n("decryptor.ab.shift.waiting", "SHIFT: waiting", Color(0.65, 0.65, 0.65, 1.0), false)

func _overlay_glitch(strength: float, duration: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("glitch_burst"):
		noir_overlay.call("glitch_burst", strength, duration)

func _log_message(msg: String, color: Color) -> void:
	var time_str = Time.get_time_string_from_system()
	var line = "[%s] %s" % [time_str, msg]
	log_lines.append(line)
	if log_lines.size() > 200:
		log_lines.remove_at(0)
	var combined_log = "\n".join(log_lines)
	details_text.text = combined_log
	var tail = log_lines.slice(maxi(0, log_lines.size() - 18), log_lines.size())
	live_log_text.text = "\n".join(tail)
	live_log_text.add_theme_color_override("default_color", color)

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
	if not _is_shift_swipe_allowed():
		_swipe_tracking = false
		return
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
	if _nibbles_grid_installed and _nibbles_grid != null and is_instance_valid(_nibbles_grid):
		if _nibbles_grid.get_global_rect().has_point(pos):
			return true
	return upper_bits.get_global_rect().has_point(pos) or lower_bits.get_global_rect().has_point(pos)

func _is_shift_swipe_allowed() -> bool:
	return GlobalMetrics.current_level_index >= 15 and GlobalMetrics.current_operator == GlobalMetrics.Operator.SHIFT_L

func _apply_shift_left() -> void:
	if not _is_shift_swipe_allowed():
		return
	_mark_first_action()
	current_input = (current_input << 1) & 0xFF
	var hamming_to_target: int = _register_input_change()
	_sync_switches_to_input()
	_update_input_display()
	_set_shift_status_i18n("decryptor.ab.shift.applied", "SHIFT: applied", COLOR_OK, true)
	_log_message(_tr("decryptor.ab.log.shift_applied", "Left shift gesture applied."), COLOR_OK)
	_log_event("shift_left_applied", {
		"input_value": current_input,
		"hamming_to_target": hamming_to_target
	})

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait
	var very_compact: bool = is_landscape and viewport_size.y <= 400.0
	var ultra_compact: bool = is_landscape and viewport_size.x <= 700.0

	_apply_safe_area_padding(compact)
	main_root.add_theme_constant_override("separation", 8 if compact else 12)
	header_content.add_theme_constant_override("separation", 6 if compact else 8)
	content_split.add_theme_constant_override("separation", 8 if compact else 12)
	bottom_actions.add_theme_constant_override("separation", 8 if compact else 10)
	_set_content_mobile_mode(phone_portrait)
	_apply_nibbles_layout(very_compact)

	btn_back.custom_minimum_size = Vector2(48.0 if very_compact else (52.0 if compact else 64.0), 40.0 if very_compact else (48.0 if compact else 52.0))
	btn_details.custom_minimum_size = Vector2(56.0 if very_compact else (64.0 if compact else 72.0), 40.0 if very_compact else (44.0 if compact else 48.0))
	btn_details.visible = true
	if very_compact:
		btn_hint.custom_minimum_size = Vector2(72.0, 40.0)
		btn_check.custom_minimum_size = Vector2(100.0, 40.0)
		btn_reset.custom_minimum_size = Vector2(72.0, 40.0)
	elif compact:
		btn_hint.custom_minimum_size = Vector2(96.0, 52.0)
		btn_check.custom_minimum_size = Vector2(132.0, 52.0)
		btn_reset.custom_minimum_size = Vector2(96.0, 52.0)
	else:
		btn_hint.custom_minimum_size = Vector2(120.0, 56.0)
		btn_check.custom_minimum_size = Vector2(180.0, 56.0)
		btn_reset.custom_minimum_size = Vector2(120.0, 56.0)
	target_value.add_theme_font_size_override("font_size", 24 if very_compact else (30 if compact else 36))

	if ultra_compact and not phone_portrait:
		right_panel.visible = false
		left_panel.size_flags_stretch_ratio = 1.0
	else:
		right_panel.visible = true
		left_panel.size_flags_stretch_ratio = 1.45

	var bit_button_size: Vector2 = Vector2(44.0, 44.0) if very_compact else Vector2(0.0, 52.0 if compact else 64.0)
	var bit_font_size: int = 14 if very_compact else (16 if compact else 18)
	for button in bit_buttons:
		if button != null:
			button.custom_minimum_size = bit_button_size
			button.add_theme_font_size_override("font_size", bit_font_size)

	var weight_font_size: int = 10 if very_compact else (12 if compact else 14)
	for label in weight_labels:
		if label != null:
			label.add_theme_font_size_override("font_size", weight_font_size)

	_details_sheet_height = clampf(viewport_size.y * (0.5 if very_compact else (0.62 if compact else 0.55)), 150.0, DETAILS_SHEET_H)
	details_scroll.custom_minimum_size.y = clampf(_details_sheet_height - 90.0, 80.0, 260.0)
	if details_open:
		_set_details_open(true, true)

	var toast_half_width: float = clampf(viewport_size.x * 0.34, 130.0, 220.0)
	toast_panel.offset_left = -toast_half_width
	toast_panel.offset_right = toast_half_width

func _install_body_scroll() -> void:
	if _body_scroll_installed and _body_scroll != null and is_instance_valid(_body_scroll):
		return
	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "BodyScroll"
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body_scroll.follow_focus = true

	var content_index: int = main_root.get_children().find(content_split)
	if content_index < 0:
		content_index = main_root.get_child_count() - 1
	main_root.add_child(_body_scroll)
	main_root.move_child(_body_scroll, content_index)

	if content_split.get_parent() != _body_scroll:
		content_split.reparent(_body_scroll)
	if _content_mobile_layout != null and is_instance_valid(_content_mobile_layout) and _content_mobile_layout.get_parent() != _body_scroll:
		_content_mobile_layout.reparent(_body_scroll)

	_body_scroll_installed = true

func _apply_nibbles_layout(compact_landscape: bool) -> void:
	if compact_landscape:
		if _nibbles_grid_installed:
			return
		_nibbles_grid = GridContainer.new()
		_nibbles_grid.name = "NibblesGrid"
		_nibbles_grid.columns = 4
		_nibbles_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_nibbles_grid.add_theme_constant_override("h_separation", 4)
		_nibbles_grid.add_theme_constant_override("v_separation", 4)

		var ordered_buttons: Array[Button] = []
		for child in upper_bits.get_children():
			if child is Button:
				ordered_buttons.append(child as Button)
		for child in lower_bits.get_children():
			if child is Button:
				ordered_buttons.append(child as Button)
		for btn in ordered_buttons:
			btn.reparent(_nibbles_grid)

		var switches_content: VBoxContainer = nibbles_center.get_parent() as VBoxContainer
		switches_content.add_child(_nibbles_grid)
		switches_content.move_child(_nibbles_grid, switches_content.get_children().find(nibbles_center))
		nibbles_center.visible = false
		_nibbles_grid_installed = true
		return

	if not _nibbles_grid_installed:
		return

	var grid_buttons: Array[Button] = []
	if _nibbles_grid != null and is_instance_valid(_nibbles_grid):
		for child in _nibbles_grid.get_children():
			if child is Button:
				grid_buttons.append(child as Button)
	for idx in range(grid_buttons.size()):
		var btn: Button = grid_buttons[idx]
		if idx < 4:
			btn.reparent(upper_bits)
		else:
			btn.reparent(lower_bits)
	nibbles_center.visible = true
	if _nibbles_grid != null and is_instance_valid(_nibbles_grid):
		_nibbles_grid.queue_free()
	_nibbles_grid = null
	_nibbles_grid_installed = false

func _set_content_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_content_mobile_layout()
	if use_mobile:
		if content_split.visible:
			if left_panel.get_parent() != mobile_layout:
				left_panel.reparent(mobile_layout)
			if right_panel.get_parent() != mobile_layout:
				right_panel.reparent(mobile_layout)
		content_split.visible = false
		mobile_layout.visible = true
	else:
		if not content_split.visible:
			if left_panel.get_parent() != content_split:
				left_panel.reparent(content_split)
			if right_panel.get_parent() != content_split:
				right_panel.reparent(content_split)
		mobile_layout.visible = false
		content_split.visible = true

func _ensure_content_mobile_layout() -> VBoxContainer:
	if _content_mobile_layout != null and is_instance_valid(_content_mobile_layout):
		return _content_mobile_layout
	_content_mobile_layout = VBoxContainer.new()
	_content_mobile_layout.name = "ContentMobileLayout"
	_content_mobile_layout.visible = false
	_content_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_mobile_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_mobile_layout.add_theme_constant_override("separation", 8)
	var parent_node: Node = _body_scroll if _body_scroll_installed and _body_scroll != null and is_instance_valid(_body_scroll) else main_root
	parent_node.add_child(_content_mobile_layout)
	var content_index: int = parent_node.get_children().find(content_split)
	if content_index < 0:
		content_index = parent_node.get_child_count() - 1
	var target_index: int = mini(content_index + 1, parent_node.get_child_count() - 1)
	parent_node.move_child(_content_mobile_layout, target_index)
	return _content_mobile_layout

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms

func _elapsed_level_ms() -> int:
	return maxi(0, Time.get_ticks_msec() - level_started_ms)

func _calc_hamming(a: int, b: int) -> int:
	var x: int = a ^ b
	var count: int = 0
	for i in range(8):
		if (x & (1 << i)) != 0:
			count += 1
	return count

func _update_hamming_metrics(hamming_to_target: int) -> void:
	last_hamming_seen = hamming_to_target
	if hamming_to_target < min_hamming_seen:
		min_hamming_seen = hamming_to_target
		hamming_improved_before_success = true

func _register_input_change() -> int:
	_input_changed_since_last_check = true
	if hint_open_count > 0:
		changed_after_hint = true
	if details_open_count > 0:
		changed_after_details = true
	var hamming_to_target: int = _calc_hamming(current_input, current_target)
	_update_hamming_metrics(hamming_to_target)
	return hamming_to_target

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _elapsed_level_ms(),
		"payload": data.duplicate(true)
	})
	if events.size() > 500:
		events = events.slice(events.size() - 500, events.size())
	task_session["events"] = events

func _derive_outcome_code(is_success: bool, error_code: String) -> String:
	if is_success:
		return "SUCCESS"
	if error_code == "INCORRECT":
		return "WRONG_VALUE"
	if error_code == "SHIELD_ACTIVE" or error_code == "SHIELD_FREQ" or error_code == "SHIELD_LAZY":
		return error_code
	if error_code == "TIMEOUT":
		return "TIMEOUT"
	if not error_code.is_empty():
		return error_code
	return "WRONG_VALUE"

func _record_mistake(result: Dictionary, submitted_input: int, error_code: String) -> void:
	var hamming_value: int = int(result.get("hamming", _calc_hamming(submitted_input, current_target)))
	GlobalMetrics.add_mistake("error=%s, HD=%d, target=%d, input=%d, level=%d" % [
		error_code,
		hamming_value,
		current_target,
		submitted_input,
		GlobalMetrics.current_level_index
	])

func _derive_mastery_block_reason(outcome_code: String) -> String:
	if outcome_code.begins_with("SHIELD"):
		return "SHIELD_TRIGGERED"
	if hint_used or hint_open_count > 0:
		return "USED_HINT"
	if check_attempt_count > 1:
		return "MULTI_CHECK"
	if reset_count > 0:
		return "RESET_USED"
	if details_open_before_check or changed_after_details:
		return "DETAILS_DEPENDENCY"
	return "NONE"

func _register_trial(result: Dictionary, submitted_input: int) -> void:
	var level_number := GlobalMetrics.current_level_index + 1
	var stage_id := "A" if GlobalMetrics.current_level_index < 15 else "B"
	var task_id := "%s_%02d" % [stage_id, level_number]
	var variant_source := "%s|%s|%d" % [GlobalMetrics.current_mode, stage_id, current_target]
	var payload: Dictionary = TrialV2.build("DECRYPTOR", stage_id, task_id, "NUMERIC_ENTRY", str(hash(variant_source)))
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - level_started_ms)
	var is_success := bool(result.get("success", false))
	var error_code := str(result.get("error", "NONE"))
	if is_success and reset_count > 0:
		used_reset_before_success = true
	var outcome_code: String = _derive_outcome_code(is_success, error_code)
	var mastery_block_reason: String = _derive_mastery_block_reason(outcome_code)
	var min_hamming_value: int = min_hamming_seen
	if min_hamming_value >= 999:
		min_hamming_value = _calc_hamming(submitted_input, current_target)
	_log_event("trial_finished", {
		"attempt": check_attempt_count,
		"is_success": is_success,
		"error_code": error_code,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason
	})
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_success
	payload["is_fit"] = is_success
	var reported_penalty: float = float(result.get("penalty", 0.0))
	payload["stability_delta"] = 0.0 if is_success else -reported_penalty
	payload["level_index"] = GlobalMetrics.current_level_index
	payload["mode"] = GlobalMetrics.current_mode
	payload["target_value"] = current_target
	payload["input_value"] = submitted_input
	payload["check_attempt_count"] = check_attempt_count
	payload["hint_used"] = hint_used
	payload["error_type"] = error_code
	payload["penalty_reported"] = reported_penalty
	payload["stage_id"] = stage_id
	payload["match_key"] = "DEC_%s_%02d_T%d" % [stage_id, GlobalMetrics.current_level_index + 1, current_target]
	payload["trial_seq"] = trial_seq
	payload["bit_toggle_count"] = bit_toggle_count
	payload["bit_toggle_unique_count"] = bit_toggle_unique.size()
	payload["bit_retoggle_count"] = bit_retoggle_count
	payload["reset_count"] = reset_count
	payload["retry_count"] = retry_count
	payload["continue_count"] = continue_count
	payload["details_open_count"] = details_open_count
	payload["details_open_before_check"] = details_open_before_check
	payload["details_close_count"] = details_close_count
	payload["hint_open_count"] = hint_open_count
	payload["safe_mode_open_count"] = safe_mode_open_count
	payload["safe_mode_used"] = _safe_mode_used
	payload["shield_event"] = _last_shield_code != "NONE"
	payload["shield_code"] = _last_shield_code
	payload["first_check_ms"] = first_check_ms
	payload["last_check_ms"] = last_check_ms
	payload["time_to_hint_ms"] = time_to_hint_ms
	payload["time_to_details_ms"] = time_to_details_ms
	payload["time_to_reset_ms"] = time_to_reset_ms
	payload["last_hamming_seen"] = last_hamming_seen
	payload["min_hamming_seen"] = min_hamming_value
	payload["hamming_improved_before_success"] = hamming_improved_before_success
	payload["current_streak_without_change"] = current_streak_without_change
	payload["check_without_change_count"] = check_without_change_count
	payload["changed_after_hint"] = changed_after_hint
	payload["changed_after_details"] = changed_after_details
	payload["used_reset_before_success"] = used_reset_before_success
	payload["used_retry_after_fail"] = used_retry_after_fail
	payload["outcome_code"] = outcome_code
	payload["mastery_block_reason"] = mastery_block_reason
	payload["hint_diag_code"] = _hint_diag_code
	payload["hint_zone_code"] = _hint_zone_code
	payload["hint_hd"] = _hint_hd
	payload["task_session"] = task_session.duplicate(true)
	if result.has("hamming"):
		payload["hamming"] = int(result.get("hamming", 0))
	GlobalMetrics.register_trial(payload)

func _sync_switches_to_input() -> void:
	for bit in range(8):
		var pressed = ((current_input >> bit) & 1) == 1
		var btn: Button = bit_buttons[bit]
		btn.set_pressed_no_signal(pressed)
		btn.text = "1" if pressed else "0"
