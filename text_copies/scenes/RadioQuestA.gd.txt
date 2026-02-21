extends Control

const ANCHOR_POOL: Array[int] = [100, 500, 1000]
const POWERS_OF_2: Array[int] = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]
const TRAPS: Array[int] = [10, 50, 2000]
const SAMPLE_SLOTS: int = 7
const ANALYZE_REVEAL_SECONDS: float = 1.8
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 520.0

const COLOR_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_GOOD: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)
const COLOR_BAD: Color = Color(0.95, 0.25, 0.25, 1.0)

const TXT_TITLE: String = "\u0420\u0410\u0414\u0418\u041e\u041f\u0415\u0420\u0415\u0425\u0412\u0410\u0422 | A"
const TXT_BACK: String = "\u041d\u0410\u0417\u0410\u0414"
const TXT_MISSION: String = "\u0417\u0410\u0414\u0410\u041d\u0418\u0415"
const TXT_RULE: String = "\u041d\u0430\u0439\u0434\u0438\u0442\u0435 \u043c\u0438\u043d\u0438\u043c\u0430\u043b\u044c\u043d\u043e\u0435 i, \u0433\u0434\u0435 2^i >= N"
const TXT_DECODER: String = "\u0414\u0415\u041a\u041e\u0414\u0415\u0420"
const TXT_KNOB_HINT: String = "\u041f\u043e\u0432\u0435\u0440\u043d\u0438\u0442\u0435 \u0440\u0443\u0447\u043a\u0443, \u0437\u0430\u0442\u0435\u043c \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u00ab\u0410\u041d\u0410\u041b\u0418\u0417\u00bb"
const TXT_BTN_HINT: String = "\u041f\u041e\u0414\u0421\u041a\u0410\u0417\u041a\u0410"
const TXT_BTN_ANALYZE: String = "\u0410\u041d\u0410\u041b\u0418\u0417"
const TXT_BTN_CAPTURE: String = "\u0417\u0410\u0425\u0412\u0410\u0422"
const TXT_BTN_NEXT: String = "\u0414\u0410\u041b\u0415\u0415"
const TXT_BTN_DETAILS_CLOSED: String = "\u041f\u041e\u0414\u0420\u041e\u0411\u041d\u0415\u0415 \u25be"
const TXT_BTN_DETAILS_OPEN: String = "\u0421\u041a\u0420\u042b\u0422\u042c \u25b4"
const TXT_DETAILS_TITLE: String = "\u041f\u041e\u042f\u0421\u041d\u0415\u041d\u0418\u0415"
const TXT_DETAILS_CLOSE: String = "\u0417\u0410\u041a\u0420\u042b\u0422\u042c"

const TXT_STATUS_PLAN: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041d\u0430\u0441\u0442\u0440\u043e\u0439\u0442\u0435 i, \u0437\u0430\u0442\u0435\u043c \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u00ab\u0410\u041d\u0410\u041b\u0418\u0417\u00bb."
const TXT_STATUS_HINT: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0439\u0442\u0435 \u043f\u0440\u0430\u0432\u0438\u043b\u043e 2^i >= N \u0438 \u043c\u0438\u043d\u0438\u043c\u0443\u043c i."
const TXT_ANALYZE_UNDERFIT: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041d\u0435 \u043f\u043e\u043c\u0435\u0449\u0430\u0435\u0442\u0441\u044f. \u0423\u0432\u0435\u043b\u0438\u0447\u044c\u0442\u0435 i."
const TXT_ANALYZE_OVERKILL: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u043e\u043c\u0435\u0449\u0430\u0435\u0442\u0441\u044f, \u043d\u043e \u0435\u0441\u0442\u044c \u043f\u0435\u0440\u0435\u0440\u0430\u0441\u0445\u043e\u0434 \u0431\u0438\u0442."
const TXT_ANALYZE_OK: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0420\u0435\u0448\u0435\u043d\u0438\u0435 \u043c\u0438\u043d\u0438\u043c\u0430\u043b\u044c\u043d\u043e\u0435."
const TXT_ANALYZE_DONE: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0410\u043d\u0430\u043b\u0438\u0437 \u0437\u0430\u0432\u0435\u0440\u0448\u0451\u043d. \u041d\u0430\u0436\u043c\u0438\u0442\u0435 \u00ab\u0417\u0410\u0425\u0412\u0410\u0422\u00bb."
const TXT_RESULT_BAD: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041d\u0435\u0432\u0435\u0440\u043d\u043e. \u041f\u0430\u043a\u0435\u0442 \u043d\u0435 \u043f\u043e\u043c\u0435\u0441\u0442\u0438\u043b\u0441\u044f."
const TXT_RESULT_GOOD: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041e\u0442\u043b\u0438\u0447\u043d\u043e. \u041c\u0438\u043d\u0438\u043c\u0430\u043b\u044c\u043d\u043e\u0435 \u043a\u043e\u0434\u0438\u0440\u043e\u0432\u0430\u043d\u0438\u0435."
const TXT_RESULT_WARN: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u0435\u0440\u043d\u043e, \u043d\u043e \u0441 \u043f\u0435\u0440\u0435\u0440\u0430\u0441\u0445\u043e\u0434\u043e\u043c."

@onready var safe_area: MarginContainer = $SafeArea
@onready var root_vbox: VBoxContainer = $SafeArea/RootVBox
@onready var body_split: HSplitContainer = $SafeArea/RootVBox/BodyHSplit
@onready var mission_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard
@onready var scope_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard
@onready var right_vbox: VBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox

@onready var btn_back: Button = $SafeArea/RootVBox/Header/HeaderHBox/BtnBack
@onready var title_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/TitleLabel
@onready var meta_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/MetaLabel

@onready var mission_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/MissionTitle
@onready var target_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/TargetLabel
@onready var rule_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/RuleLabel
@onready var wave_layer: Control = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard/ScopeMargin/ScopeLayer
@onready var wave_line: Line2D = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard/ScopeMargin/ScopeLayer/WaveLine
@onready var bits_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutRow/BitsValueLabel
@onready var fit_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutRow/FitValueLabel

@onready var decoder_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/DecoderTitle
@onready var bit_knob: Control = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BitKnob
@onready var knob_hint: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/KnobHint
@onready var btn_hint: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnHint
@onready var btn_analyze: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnAnalyze
@onready var btn_capture: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnCapture
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/SampleStrip
@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BtnDetails
@onready var footer_label: Label = $SafeArea/RootVBox/Footer/FooterMargin/FooterLabel

@onready var dimmer: ColorRect = $Dimmer
@onready var details_sheet: PanelContainer = $DetailsSheet
@onready var details_title: Label = $DetailsSheet/DetailsMargin/DetailsVBox/DetailsTitle
@onready var details_text: RichTextLabel = $DetailsSheet/DetailsMargin/DetailsVBox/DetailsText
@onready var btn_close_details: Button = $DetailsSheet/DetailsMargin/DetailsVBox/BtnCloseDetails

var target_n: int = 0
var target_bits: int = 0
var current_bits: int = 1
var pool_type: String = "NORMAL"

var trial_active: bool = false
var hint_used: bool = false
var forced_sampling: bool = false
var is_timed_mode: bool = false
var trial_duration: float = 30.0
var time_remaining: float = 0.0

var start_time: float = 0.0
var first_action_timestamp: float = -1.0
var prev_time_to_first_action: float = 0.0

var analyze_count: int = 0
var knob_change_count: int = 0
var direction_change_count: int = 0
var cross_target_count: int = 0
var last_diff_sign: int = 0

var current_trial_idx: int = 0
var anchor_countdown: int = 0
var sample_refs: Array[Dictionary] = []

var analysis_committed: bool = false
var analyze_reveal_until: float = 0.0
var last_analysis_fit: bool = false
var last_analysis_minimal: bool = false
var last_analysis_overkill: bool = false

var osc_phase: float = 0.0
var _ui_ready: bool = false
var _current_stability: float = 100.0

func _ready() -> void:
	randomize()
	_apply_static_texts()
	_connect_signals()
	_collect_sample_refs()
	_reset_sample_strip()
	_set_details_visible(false)
	_apply_safe_area_padding()
	_configure_layout()

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_on_stability_changed(GlobalMetrics.stability, 0.0)

	anchor_countdown = randi_range(7, 10)
	_start_trial()
	_ui_ready = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _ui_ready:
		_apply_safe_area_padding()
		_configure_layout()

func _process(delta: float) -> void:
	osc_phase += delta * 2.6

	if trial_active and is_timed_mode:
		time_remaining = maxf(0.0, time_remaining - delta)
		if time_remaining <= 0.0:
			_finish_trial(true)

	if trial_active and analysis_committed and btn_capture.disabled:
		var now_sec: float = Time.get_ticks_msec() / 1000.0
		if now_sec >= analyze_reveal_until:
			btn_capture.disabled = false
			status_label.text = TXT_ANALYZE_DONE
			status_label.add_theme_color_override("font_color", COLOR_GOOD)

	_update_header_meta()
	_update_waveform()

func _apply_static_texts() -> void:
	title_label.text = TXT_TITLE
	btn_back.text = TXT_BACK
	mission_title.text = TXT_MISSION
	rule_label.text = TXT_RULE
	decoder_title.text = TXT_DECODER
	knob_hint.text = TXT_KNOB_HINT
	btn_hint.text = TXT_BTN_HINT
	btn_analyze.text = TXT_BTN_ANALYZE
	btn_capture.text = TXT_BTN_CAPTURE
	btn_next.text = TXT_BTN_NEXT
	btn_details.text = TXT_BTN_DETAILS_CLOSED
	details_title.text = TXT_DETAILS_TITLE
	btn_close_details.text = TXT_DETAILS_CLOSE

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_capture.pressed.connect(_on_capture_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_close_pressed)
	dimmer.gui_input.connect(_on_dimmer_gui_input)

	var knob_callback: Callable = Callable(self, "_on_knob_value_changed")
	if not bit_knob.is_connected("value_changed", knob_callback):
		bit_knob.connect("value_changed", knob_callback)

func _collect_sample_refs() -> void:
	sample_refs.clear()
	for child_var in sample_strip.get_children():
		var child_node: Node = child_var as Node
		var bg_node: ColorRect = child_node.get_node_or_null("BG") as ColorRect
		var mark_node: Label = child_node.get_node_or_null("AnchorMark") as Label
		if bg_node != null and mark_node != null:
			sample_refs.append({"bg": bg_node, "mark": mark_node})

func _reset_sample_strip() -> void:
	for slot_var in sample_refs:
		var slot: Dictionary = slot_var as Dictionary
		var bg: ColorRect = slot["bg"] as ColorRect
		var mark: Label = slot["mark"] as Label
		bg.color = COLOR_IDLE
		mark.visible = false
	current_trial_idx = 0

func _start_trial() -> void:
	trial_active = true
	hint_used = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	analyze_count = 0
	knob_change_count = 0
	direction_change_count = 0
	cross_target_count = 0
	last_diff_sign = 0

	analysis_committed = false
	analyze_reveal_until = 0.0
	last_analysis_fit = false
	last_analysis_minimal = false
	last_analysis_overkill = false

	btn_capture.visible = true
	btn_capture.disabled = true
	btn_analyze.disabled = false
	btn_next.visible = false
	btn_hint.disabled = false
	bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP

	forced_sampling = prev_time_to_first_action > 10.0
	is_timed_mode = forced_sampling
	time_remaining = trial_duration if is_timed_mode else 0.0

	if anchor_countdown <= 0:
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
	target_label.text = "N = %d" % target_n

	current_bits = 1
	bit_knob.set("value", 1)
	_apply_user_bits(1, false)

	status_label.text = TXT_STATUS_PLAN
	status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	footer_label.text = ""
	_update_header_meta()
	_update_details_text()

func _mark_first_action() -> void:
	if first_action_timestamp < 0.0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

func _on_knob_value_changed(new_value: int) -> void:
	if not trial_active or analysis_committed:
		return
	_apply_user_bits(new_value, true)

func _apply_user_bits(i_value: int, from_user: bool) -> void:
	if from_user:
		_mark_first_action()

	current_bits = clampi(i_value, 1, 12)
	var pow_val: int = int(pow(2.0, current_bits))
	var is_fit: bool = pow_val >= target_n

	if from_user:
		knob_change_count += 1
		var diff_sign: int = signi(target_bits - current_bits)
		if last_diff_sign != 0 and diff_sign != 0 and diff_sign != last_diff_sign:
			direction_change_count += 1
			cross_target_count += 1
		last_diff_sign = diff_sign

	bits_value_label.text = "i = %d \u0431\u0438\u0442" % current_bits
	fit_value_label.text = "\u041f\u041e\u041c\u0415\u0429\u0410\u0415\u0422\u0421\u042f: %s" % ("\u0414\u0410" if is_fit else "\u041d\u0415\u0422")
	fit_value_label.add_theme_color_override("font_color", COLOR_GOOD if is_fit else COLOR_BAD)
	_update_details_text()

func _on_hint_pressed() -> void:
	if not trial_active:
		return
	_mark_first_action()
	hint_used = true
	status_label.text = TXT_STATUS_HINT
	status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1.0))
	_update_details_text()

func _on_analyze_pressed() -> void:
	if not trial_active or analysis_committed:
		return

	_mark_first_action()
	analyze_count += 1
	analysis_committed = true
	btn_analyze.disabled = true
	btn_capture.disabled = true
	bit_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var capacity: int = int(pow(2.0, current_bits))
	last_analysis_fit = capacity >= target_n
	last_analysis_minimal = current_bits == target_bits
	last_analysis_overkill = last_analysis_fit and not last_analysis_minimal

	if not last_analysis_fit:
		status_label.text = TXT_ANALYZE_UNDERFIT
		status_label.add_theme_color_override("font_color", COLOR_WARN)
	elif last_analysis_overkill:
		status_label.text = TXT_ANALYZE_OVERKILL
		status_label.add_theme_color_override("font_color", COLOR_WARN)
	else:
		status_label.text = TXT_ANALYZE_OK
		status_label.add_theme_color_override("font_color", COLOR_GOOD)

	analyze_reveal_until = Time.get_ticks_msec() / 1000.0 + ANALYZE_REVEAL_SECONDS
	_update_details_text()

func _on_capture_pressed() -> void:
	if not trial_active or btn_capture.disabled:
		return
	_mark_first_action()
	_finish_trial(false)

func _finish_trial(is_timeout: bool) -> void:
	if not trial_active:
		return

	trial_active = false
	btn_capture.visible = false
	btn_analyze.disabled = true
	btn_next.visible = true
	btn_hint.disabled = true
	bit_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		status_label.text = TXT_RESULT_BAD
		status_label.add_theme_color_override("font_color", COLOR_BAD)
	elif is_minimal:
		status_label.text = TXT_RESULT_GOOD
		status_label.add_theme_color_override("font_color", COLOR_GOOD)
	else:
		status_label.text = TXT_RESULT_WARN
		status_label.add_theme_color_override("font_color", COLOR_WARN)

	_update_sample_slot(is_fit, is_minimal)

	if first_action_timestamp > 0.0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "A",
		"match_key": "RI_A_%s_%s_N%d" % ["TIMED" if is_timed_mode else "UNTIMED", pool_type, target_n],
		"pool_type": pool_type,
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
		"analyze_count": analyze_count,
		"knob_change_count": knob_change_count,
		"direction_change_count": direction_change_count,
		"cross_target_count": cross_target_count,
		"elapsed_ms": duration * 1000.0
	}
	GlobalMetrics.register_trial(payload)
	_update_details_text()

func _update_sample_slot(is_fit: bool, is_minimal: bool) -> void:
	if sample_refs.is_empty():
		return
	var slot: Dictionary = sample_refs[current_trial_idx] as Dictionary
	var bg: ColorRect = slot["bg"] as ColorRect
	var mark: Label = slot["mark"] as Label
	if not is_fit:
		bg.color = COLOR_BAD
	elif is_minimal:
		bg.color = COLOR_GOOD
	else:
		bg.color = COLOR_WARN
	mark.visible = pool_type == "ANCHOR"
	current_trial_idx = (current_trial_idx + 1) % min(SAMPLE_SLOTS, sample_refs.size())

func _on_next_pressed() -> void:
	_start_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_pressed() -> void:
	_set_details_visible(true)

func _on_details_close_pressed() -> void:
	_set_details_visible(false)

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_set_details_visible(false)

func _set_details_visible(visible: bool) -> void:
	details_sheet.visible = visible
	dimmer.visible = visible
	btn_details.text = TXT_BTN_DETAILS_OPEN if visible else TXT_BTN_DETAILS_CLOSED

func _update_details_text() -> void:
	var capacity: int = int(pow(2.0, current_bits))
	var lines: Array[String] = []
	lines.append("N: %d" % target_n)
	lines.append("i_min: %d" % target_bits)
	lines.append("i_selected: %d" % current_bits)
	lines.append("2^i: %d" % capacity)
	lines.append("mode: %s" % ("TIMED" if is_timed_mode else "UNTIMED"))
	lines.append("pool: %s" % pool_type)
	if hint_used:
		lines.append("hint: used")
	if analysis_committed:
		lines.append("analysis: done")
	details_text.text = "\n".join(lines)

func _update_header_meta() -> void:
	var mode_text: String = "\u0421 \u0422\u0410\u0419\u041c\u0415\u0420\u041e\u041c" if is_timed_mode else "\u0411\u0415\u0417 \u0422\u0410\u0419\u041c\u0415\u0420\u0410"
	var timer_text: String = ""
	if is_timed_mode:
		timer_text = " | T: %.1f\u0441" % time_remaining
	meta_label.text = "\u0420\u0415\u0416\u0418\u041c: %s | \u0421\u0422\u0410\u0411: %d%%%s" % [mode_text, int(_current_stability), timer_text]

func _on_stability_changed(new_value: float, _delta: float) -> void:
	_current_stability = new_value
	_update_header_meta()

func _apply_safe_area_padding() -> void:
	var left: float = 16.0
	var top: float = 12.0
	var right: float = 16.0
	var bottom: float = 12.0

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

func _configure_layout() -> void:
	var size: Vector2 = get_viewport_rect().size
	var phone_landscape: bool = size.x > size.y and size.y <= PHONE_LANDSCAPE_MAX_HEIGHT

	if phone_landscape:
		body_split.split_offset = int(size.x * 0.54)
		root_vbox.add_theme_constant_override("separation", 8)
		bit_knob.custom_minimum_size = Vector2(180, 180)
		mission_card.custom_minimum_size.y = 110
		scope_card.custom_minimum_size.y = 170
		bits_value_label.add_theme_font_size_override("font_size", 28)
		fit_value_label.add_theme_font_size_override("font_size", 20)
		status_label.add_theme_font_size_override("font_size", 16)
		meta_label.add_theme_font_size_override("font_size", 16)
		for btn in [btn_back, btn_hint, btn_analyze, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 56
	elif size.x < 1280.0:
		body_split.split_offset = int(size.x * 0.55)
		root_vbox.add_theme_constant_override("separation", 10)
		bit_knob.custom_minimum_size = Vector2(200, 200)
		mission_card.custom_minimum_size.y = 122
		scope_card.custom_minimum_size.y = 220
		bits_value_label.add_theme_font_size_override("font_size", 32)
		fit_value_label.add_theme_font_size_override("font_size", 22)
		status_label.add_theme_font_size_override("font_size", 18)
		meta_label.add_theme_font_size_override("font_size", 17)
		for btn in [btn_back, btn_hint, btn_analyze, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 58
	else:
		body_split.split_offset = int(size.x * 0.56)
		root_vbox.add_theme_constant_override("separation", 10)
		bit_knob.custom_minimum_size = Vector2(220, 220)
		mission_card.custom_minimum_size.y = 130
		scope_card.custom_minimum_size.y = 260
		bits_value_label.add_theme_font_size_override("font_size", 34)
		fit_value_label.add_theme_font_size_override("font_size", 24)
		status_label.add_theme_font_size_override("font_size", 18)
		meta_label.add_theme_font_size_override("font_size", 18)
		for btn in [btn_back, btn_hint, btn_analyze, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 58

func _update_waveform() -> void:
	if wave_layer.size.x <= 1.0 or wave_layer.size.y <= 1.0:
		return

	if analysis_committed:
		_draw_analysis_wave(wave_layer.size)
	else:
		_draw_idle_wave(wave_layer.size)

func _draw_idle_wave(draw_size: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center_y: float = draw_size.y * 0.5
	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y
		y += sin(t * TAU * 2.2 + 0.7) * draw_size.y * 0.12
		y += sin(t * TAU * 9.0 + 1.1) * draw_size.y * 0.05
		y += cos(t * TAU * 18.0 + 0.4) * draw_size.y * 0.03
		points.append(Vector2(x, y))
	wave_line.points = points

func _draw_analysis_wave(draw_size: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center_y: float = draw_size.y * 0.5
	var main_amp: float = draw_size.y * 0.22
	var noise_amp: float = 0.0

	if not last_analysis_fit:
		noise_amp = draw_size.y * 0.24
	elif last_analysis_overkill:
		noise_amp = draw_size.y * 0.08
		main_amp = draw_size.y * 0.16
	else:
		noise_amp = draw_size.y * 0.02
		main_amp = draw_size.y * 0.20

	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y + sin((t * TAU * 2.0) + osc_phase) * main_amp
		if noise_amp > 0.0:
			y += sin((t * TAU * 13.0) + osc_phase * 1.7) * noise_amp * 0.5
			y += cos((t * TAU * 29.0) + osc_phase * 0.9) * noise_amp * 0.4
		points.append(Vector2(x, y))
	wave_line.points = points
