extends Control

const RadioLevels := preload("res://scripts/radio_intercept/RadioLevels.gd")

const FALLBACK_ANCHOR_POOL: Array[int] = [100, 500, 1000]
const FALLBACK_NORMAL_POOL: Array[int] = [16, 32, 64, 128, 256, 512, 1024]
const FALLBACK_TRAP_POOL: Array[int] = [10, 50, 100, 500, 1000, 2000]
const SAMPLE_SLOTS: int = 7
const ANALYZE_REVEAL_SECONDS: float = 3.0
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 520.0

const COLOR_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_GOOD: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)
const COLOR_BAD: Color = Color(0.95, 0.25, 0.25, 1.0)



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
@onready var noir_overlay: CanvasLayer = $NoirOverlay
@onready var bits_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutRow/BitsValueLabel
@onready var fit_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutRow/FitValueLabel

@onready var decoder_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/DecoderTitle
@onready var bit_knob: Control = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BitKnob
@onready var knob_hint: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/KnobHint
@onready var btn_hint: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowTop/BtnHint
@onready var btn_analyze: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowTop/BtnAnalyze
@onready var btn_capture: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowBottom/BtnCapture
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowBottom/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/SampleStrip
@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BtnDetails

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
var analysis_revealing: bool = false
var analyze_reveal_until: float = 0.0
var last_analysis_fit: bool = false
var last_analysis_minimal: bool = false
var last_analysis_overkill: bool = false
var last_analyzed_bits: int = -1

var _normal_pool: Array[int] = []
var _trap_pool: Array[int] = []
var _anchor_pool: Array[int] = []
var _i_min: int = 1
var _i_max: int = 12
var _anchor_every_min: int = 7
var _anchor_every_max: int = 10
var _target_wave_line: Line2D

var osc_phase: float = 0.0
var noise_seed: int = 1
var _ui_ready: bool = false
var _current_stability: float = 100.0
var _body_scroll_installed: bool = false
var _status_i18n_key: String = ""
var _status_i18n_default: String = ""
var _status_i18n_params: Dictionary = {}
var _status_i18n_color: Color = Color(0.85, 0.85, 0.85, 1.0)

func _ready() -> void:
	randomize()
	_load_level_config()
	_apply_i18n()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_connect_signals()
	_configure_text_overflow()
	_install_body_scroll()
	_collect_sample_refs()
	_ensure_target_wave_line()
	_reset_sample_strip()
	_set_details_visible(false)
	_apply_safe_area_padding()
	_configure_layout()

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_on_stability_changed(GlobalMetrics.stability, 0.0)

	anchor_countdown = _random_anchor_gap()
	_start_trial()
	_ui_ready = true

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

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
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if trial_active and analysis_revealing:
		var remaining: float = maxf(0.0, analyze_reveal_until - now_sec)
		_set_status_i18n(
			"quest.radio.a.status.analyze_progress",
			"STATUS: analyzing channel... {left}s",
			COLOR_WARN,
			{"left": "%.1f" % remaining}
		)
		if now_sec >= analyze_reveal_until:
			analysis_revealing = false
			analysis_committed = true
			last_analyzed_bits = current_bits
			bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP
			btn_hint.disabled = false
			btn_capture.disabled = false
			btn_analyze.disabled = false
			_set_fit_label_from_analysis()
			_update_details_text()
			_set_status_i18n(
				"quest.radio.a.status.analyze_done",
				"STATUS: analysis complete. Press CAPTURE.",
				COLOR_GOOD
			)
	_update_header_meta()
	_update_waveform()
func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.get_text(key, merged)

func _configure_text_overflow() -> void:
	for lbl in [target_label, rule_label, knob_hint, status_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for btn in [btn_hint, btn_analyze, btn_capture, btn_next, btn_details]:
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_i18n() -> void:
	title_label.text = _tr("quest.radio.a.ui.title", "RADIO INTERCEPT | A")
	btn_back.text = _tr("quest.radio.common.btn.back", "BACK")
	mission_title.text = _tr("quest.radio.a.ui.mission", "MISSION")
	rule_label.text = _tr("quest.radio.a.ui.rule", "Find minimum i where 2^i >= N")
	decoder_title.text = _tr("quest.radio.a.ui.decoder", "DECODER")
	knob_hint.text = _tr("quest.radio.a.ui.knob_hint", "Rotate the knob, then press ANALYZE")
	btn_hint.text = _tr("quest.radio.a.ui.btn_hint", "HINT")
	btn_analyze.text = _tr("quest.radio.btn.analyze", "ANALYZE")
	btn_capture.text = _tr("quest.radio.btn.capture", "CAPTURE")
	btn_next.text = _tr("quest.radio.common.btn.next", "NEXT")
	btn_details.text = _tr("quest.radio.common.btn.details_open", "DETAILS v")
	details_title.text = _tr("quest.radio.a.ui.details_title", "EXPLANATION")
	btn_close_details.text = _tr("quest.radio.common.btn.details_close", "CLOSE")
	_update_dynamic_texts()
	_apply_status_i18n()
	_update_header_meta()
	_update_details_text()

func _update_dynamic_texts() -> void:
	if target_n > 0:
		target_label.text = _tr("quest.radio.a.task", "Signal detected. Alphabet size: %d chars. Set decoding depth.") % target_n
	if current_bits > 0:
		bits_value_label.text = _tr("quest.radio.a.bits", "%d BIT") % current_bits

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _set_status_i18n(key: String, default_text: String, color: Color, params: Dictionary = {}) -> void:
	_status_i18n_key = key
	_status_i18n_default = default_text
	_status_i18n_params = params.duplicate(true)
	_status_i18n_color = color
	_apply_status_i18n()

func _apply_status_i18n() -> void:
	if _status_i18n_key.is_empty():
		return
	status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)
	status_label.add_theme_color_override("font_color", _status_i18n_color)

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
	analysis_revealing = false
	analyze_reveal_until = 0.0
	last_analysis_fit = false
	last_analysis_minimal = false
	last_analysis_overkill = false
	last_analyzed_bits = -1
	noise_seed = randi()

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
		target_n = _random_from_int_pool(_anchor_pool, FALLBACK_ANCHOR_POOL.pick_random())
		pool_type = "ANCHOR"
		anchor_countdown = _random_anchor_gap()
	else:
		pool_type = "NORMAL"
		anchor_countdown -= 1
		var pool: Array[int] = []
		pool.append_array(_normal_pool)
		pool.append_array(_trap_pool)
		if pool.is_empty():
			pool.append_array(FALLBACK_NORMAL_POOL)
			pool.append_array(FALLBACK_TRAP_POOL)
		target_n = pool.pick_random()

	target_bits = int(ceil(log(float(target_n)) / log(2.0)))
	target_label.text = _tr("quest.radio.a.task", "Signal detected. Alphabet size: %d chars. Set decoding depth.") % target_n

	current_bits = _i_min
	bit_knob.set("value", _i_min)
	_apply_user_bits(_i_min, false)
	_set_fit_label_unknown()
	if _target_wave_line != null:
		_target_wave_line.visible = false
		_target_wave_line.points = PackedVector2Array()

	_set_status_i18n(
		"quest.radio.a.status.plan",
		"STATUS: set i, then press ANALYZE.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	_update_header_meta()
	_update_details_text()

func _mark_first_action() -> void:
	if first_action_timestamp < 0.0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

func _on_knob_value_changed(new_value: int) -> void:
	if not trial_active or analysis_revealing:
		return
	_apply_user_bits(new_value, true)

func _apply_user_bits(i_value: int, from_user: bool) -> void:
	if from_user:
		_mark_first_action()

	current_bits = clampi(i_value, _i_min, _i_max)

	if from_user:
		knob_change_count += 1
		var diff_sign: int = signi(target_bits - current_bits)
		if last_diff_sign != 0 and diff_sign != 0 and diff_sign != last_diff_sign:
			direction_change_count += 1
			cross_target_count += 1
		last_diff_sign = diff_sign
		noise_seed = int((noise_seed * 1103515245 + 12345 + current_bits * 17) & 0x7fffffff)
		if analysis_committed:
			analysis_committed = false
			last_analyzed_bits = -1
			btn_capture.disabled = true
			_set_status_i18n(
				"quest.radio.a.status.plan",
				"STATUS: set i, then press ANALYZE.",
				Color(0.85, 0.85, 0.85, 1.0)
			)

	bits_value_label.text = _tr("quest.radio.a.bits", "%d BIT") % current_bits
	if analysis_committed and current_bits == last_analyzed_bits:
		_set_fit_label_from_analysis()
	else:
		_set_fit_label_unknown()
	_update_details_text()

func _on_hint_pressed() -> void:
	if not trial_active:
		return
	_mark_first_action()
	hint_used = true
	_set_status_i18n(
		"quest.radio.a.status.hint",
		"STATUS: use rule 2^i >= N and choose minimal i.",
		Color(0.55, 0.85, 1.0, 1.0)
	)
	_update_details_text()

func _on_analyze_pressed() -> void:
	if not trial_active or analysis_revealing:
		return
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	_mark_first_action()
	analyze_count += 1
	analysis_committed = false
	last_analyzed_bits = -1
	analysis_revealing = true
	btn_analyze.disabled = true
	btn_capture.disabled = true
	btn_hint.disabled = true
	bit_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var capacity: int = int(pow(2.0, current_bits))
	last_analysis_fit = capacity >= target_n
	last_analysis_minimal = current_bits == target_bits
	last_analysis_overkill = last_analysis_fit and not last_analysis_minimal
	if not last_analysis_fit:
		_set_status_i18n(
			"quest.radio.a.status.analyze_underfit",
			"STATUS: not enough capacity. Increase i.",
			COLOR_WARN
		)
	elif last_analysis_overkill:
		_set_status_i18n(
			"quest.radio.a.status.analyze_overkill",
			"STATUS: fits, but with bit overhead.",
			COLOR_WARN
		)
	else:
		_set_status_i18n(
			"quest.radio.a.status.analyze_ok",
			"STATUS: minimal solution confirmed.",
			COLOR_GOOD
		)
	_set_fit_label_from_analysis()
	analyze_reveal_until = now_sec + ANALYZE_REVEAL_SECONDS
	_update_details_text()
func _on_capture_pressed() -> void:
	if not trial_active or btn_capture.disabled:
		return
	_mark_first_action()
	_finish_trial(false)

func _finish_trial(is_timeout: bool) -> void:
	if not trial_active:
		return

	var used_analyze: bool = analysis_committed or analyze_count > 0
	trial_active = false
	analysis_revealing = false
	analysis_committed = false
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
		_set_status_i18n("quest.radio.a.result.bad", "STATUS: incorrect. Packet did not fit.", COLOR_BAD)
	elif is_minimal:
		_set_status_i18n("quest.radio.a.result.good", "STATUS: excellent. Minimal coding depth.", COLOR_GOOD)
	else:
		_set_status_i18n("quest.radio.a.result.warn", "STATUS: correct, but overprovisioned.", COLOR_WARN)

	_update_sample_slot(is_fit, is_minimal)

	if first_action_timestamp > 0.0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration

	var scrubbed_guessing: bool = direction_change_count >= 2 or cross_target_count >= 2
	var valid_for_mastery: bool = is_fit and is_minimal and (not hint_used) and analyze_count <= 1 and (not scrubbed_guessing)

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
		"used_analyze": used_analyze,
		"used_hint": hint_used,
		"valid_for_mastery": valid_for_mastery,
		"valid_for_diagnostics": true,
		"forced_sampling": forced_sampling,
		"analyze_count": analyze_count,
		"knob_change_count": knob_change_count,
		"direction_change_count": direction_change_count,
		"cross_target_count": cross_target_count,
		"elapsed_ms": duration * 1000.0
	}
	var stability_delta: float = 0.0
	if not is_fit:
		stability_delta -= 10.0
	if analyze_count > 0:
		stability_delta -= 5.0 * float(analyze_count)
	payload["stability_delta"] = stability_delta
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
	btn_details.text = _tr("quest.radio.common.btn.details_close", "CLOSE ^") if visible else _tr("quest.radio.common.btn.details_open", "DETAILS v")

func _set_fit_label_unknown() -> void:
	fit_value_label.text = _tr("quest.radio.a.fit.unknown", "SIGNAL: NOT VERIFIED")
	fit_value_label.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80, 1.0))

func _set_fit_label_from_analysis() -> void:
	fit_value_label.text = _tr("quest.radio.a.fit.yes", "FIT: YES") if last_analysis_fit else _tr("quest.radio.a.fit.no", "FIT: NO")
	fit_value_label.add_theme_color_override("font_color", COLOR_GOOD if last_analysis_fit else COLOR_BAD)

func _update_details_text() -> void:
	var lines: Array[String] = []
	if trial_active:
		lines.append(_tr("quest.radio.a.details.rule", "Rule: find minimum i where 2^i >= N."))
		lines.append(_tr("quest.radio.a.details.steps_title", "Steps:"))
		lines.append(_tr("quest.radio.a.details.step1", "1) Select i with the knob."))
		lines.append(_tr("quest.radio.a.details.step2", "2) Press ANALYZE and wait for scan."))
		lines.append(_tr("quest.radio.a.details.step3", "3) Press CAPTURE to lock answer."))
		if analysis_revealing:
			lines.append(_tr("quest.radio.a.details.analyzing", "Channel analysis in progress. Please wait."))
		elif analysis_committed:
			lines.append(_tr("quest.radio.a.details.analysis_done", "Analysis complete. Changing i requires a new scan."))
	else:
		var lower_i: int = maxi(0, target_bits - 1)
		var lower_capacity: int = int(pow(2.0, lower_i))
		var minimal_capacity: int = int(pow(2.0, target_bits))
		var chosen_capacity: int = int(pow(2.0, current_bits))
		lines.append(_tr("quest.radio.a.details.given", "Given: N = {n}", {"n": target_n}))
		lines.append(_tr("quest.radio.a.details.powers_title", "Power-of-two check:"))
		lines.append(_tr("quest.radio.a.details.lower", "2^{li} = {lc} < {n} (insufficient)", {
			"li": lower_i,
			"lc": lower_capacity,
			"n": target_n
		}))
		lines.append(_tr("quest.radio.a.details.minimal", "2^{ti} = {tc} >= {n} (sufficient)", {
			"ti": target_bits,
			"tc": minimal_capacity,
			"n": target_n
		}))
		lines.append(_tr("quest.radio.a.details.answer", "Answer: i = {i} (minimal)", {"i": target_bits}))
		if current_bits > target_bits:
			lines.append(_tr("quest.radio.a.details.choice_over", "Your choice: i = {i} -> 2^{i} = {cap} (overkill)", {
				"i": current_bits,
				"cap": chosen_capacity
			}))
		elif current_bits < target_bits:
			lines.append(_tr("quest.radio.a.details.choice_under", "Your choice: i = {i} -> 2^{i} = {cap} (does not fit)", {
				"i": current_bits,
				"cap": chosen_capacity
			}))
		else:
			lines.append(_tr("quest.radio.a.details.choice_ok", "Your choice: i = {i} -> 2^{i} = {cap} (minimal)", {
				"i": current_bits,
				"cap": chosen_capacity
			}))
	details_text.text = "\n".join(lines)

func _update_header_meta() -> void:
	var mode_text: String = _tr("quest.radio.a.meta.mode_timed", "WITH TIMER") if is_timed_mode else _tr("quest.radio.a.meta.mode_no_timer", "NO TIMER")
	var timer_text: String = ""
	if is_timed_mode:
		timer_text = _tr("quest.radio.a.meta.timer", " | T: {t}s", {"t": "%.1f" % time_remaining})
	meta_label.text = _tr("quest.radio.a.meta.main", "MODE: {mode} | STAB: {stability}%{timer}", {
		"mode": mode_text,
		"stability": int(_current_stability),
		"timer": timer_text
	})

func _on_stability_changed(new_value: float, _delta: float) -> void:
	_current_stability = new_value
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", new_value)
	_update_header_meta()

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if root_vbox == null or body_split == null:
		return

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.follow_focus = true

	root_vbox.remove_child(body_split)
	root_vbox.add_child(body_scroll)
	body_scroll.add_child(body_split)
	body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_split.size_flags_vertical = Control.SIZE_FILL
	_body_scroll_installed = true

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
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 380, 360)
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
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 420, 380)
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
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.57), 460, 420)
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

func _clamp_split_offset(target_offset: int, min_left: int, min_right: int) -> int:
	var viewport_width: int = int(get_viewport_rect().size.x)
	return clampi(target_offset, min_left, max(min_left, viewport_width - min_right))

func _update_waveform() -> void:
	if wave_layer.size.x <= 1.0 or wave_layer.size.y <= 1.0:
		return

	_draw_idle_wave(wave_layer.size)
	if analysis_revealing:
		_draw_analysis_wave(wave_layer.size)
	elif _target_wave_line != null:
		_target_wave_line.visible = false

func _draw_idle_wave(draw_size: Vector2) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center_y: float = draw_size.y * 0.5
	var main_amp: float = draw_size.y * 0.12
	var noise_amp: float = draw_size.y * 0.08
	var seed_phase: float = float(noise_seed % 100000) * 0.001
	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y + sin((t * TAU * 2.2) + osc_phase * 0.8 + seed_phase) * main_amp
		y += sin((t * TAU * 9.0) + osc_phase * 1.2 + seed_phase * 1.7) * noise_amp * 0.60
		y += cos((t * TAU * 17.0) + osc_phase * 0.7 - seed_phase * 0.9) * noise_amp * 0.50
		y += sin((t * TAU * 31.0) + seed_phase * 0.37) * noise_amp * 0.35
		points.append(Vector2(x, y))
	wave_line.default_color = Color(0.20, 1.0, 0.20, 1.0)
	wave_line.points = points

func _draw_analysis_wave(draw_size: Vector2) -> void:
	if _target_wave_line == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var center_y: float = draw_size.y * 0.5
	var normalized: float = float(target_bits - _i_min) / maxf(1.0, float(_i_max - _i_min))
	var amp: float = draw_size.y * (0.10 + normalized * 0.14)
	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y + sin((t * TAU * 2.0) + 0.15) * amp
		points.append(Vector2(x, y))
	_target_wave_line.visible = true
	_target_wave_line.default_color = Color(0.95, 0.25, 0.25, 0.95)
	_target_wave_line.points = points

func _load_level_config() -> void:
	var normal_pool: Array = RadioLevels.get_pool("A", "N_pool_normal", FALLBACK_NORMAL_POOL)
	var trap_pool: Array = RadioLevels.get_pool("A", "N_pool_trap", FALLBACK_TRAP_POOL)
	var anchor_pool: Array = RadioLevels.get_pool("A", "N_pool_anchor", FALLBACK_ANCHOR_POOL)
	_normal_pool = _to_int_array(normal_pool, FALLBACK_NORMAL_POOL)
	_trap_pool = _to_int_array(trap_pool, FALLBACK_TRAP_POOL)
	_anchor_pool = _to_int_array(anchor_pool, FALLBACK_ANCHOR_POOL)

	_i_min = int(RadioLevels.get_value("A", "i_min", 1))
	_i_max = int(RadioLevels.get_value("A", "i_max", 12))
	if _i_min >= _i_max:
		_i_min = 1
		_i_max = 12

	_anchor_every_min = int(RadioLevels.get_value("A", "anchor_every_min", 7))
	_anchor_every_max = int(RadioLevels.get_value("A", "anchor_every_max", 10))
	if _anchor_every_min <= 0:
		_anchor_every_min = 7
	if _anchor_every_max < _anchor_every_min:
		_anchor_every_max = _anchor_every_min

	bit_knob.set("min_value", _i_min)
	bit_knob.set("max_value", _i_max)

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

func _random_anchor_gap() -> int:
	return randi_range(_anchor_every_min, _anchor_every_max)

func _random_from_int_pool(pool: Array[int], fallback_value: int) -> int:
	if pool.is_empty():
		return fallback_value
	return pool[randi() % pool.size()]

func _ensure_target_wave_line() -> void:
	_target_wave_line = wave_layer.get_node_or_null("TargetWaveLine") as Line2D
	if _target_wave_line == null:
		_target_wave_line = Line2D.new()
		_target_wave_line.name = "TargetWaveLine"
		_target_wave_line.width = 2.0
		_target_wave_line.default_color = Color(0.95, 0.25, 0.25, 0.95)
		wave_layer.add_child(_target_wave_line)
	_target_wave_line.visible = false
