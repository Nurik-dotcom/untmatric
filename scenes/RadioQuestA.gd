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
@onready var mission_margin: MarginContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin
@onready var mission_vbox: VBoxContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox
@onready var readout_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutCard
@onready var scope_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard
@onready var right_vbox: VBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox

@onready var btn_back: Button = $SafeArea/RootVBox/Header/HeaderHBox/BtnBack
@onready var title_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/TitleLabel
@onready var meta_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/MetaLabel

@onready var mission_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/MissionTitle
@onready var target_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/TargetLabel
@onready var rule_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/RuleLabel
@onready var steps_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/MissionCard/MissionMargin/MissionVBox/StepsLabel
@onready var wave_layer: Control = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard/ScopeMargin/ScopeLayer
@onready var wave_line: Line2D = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ScopeCard/ScopeMargin/ScopeLayer/WaveLine
@onready var noir_overlay: CanvasLayer = $NoirOverlay
@onready var bits_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutCard/ReadoutMargin/ReadoutRow/BitsValueLabel
@onready var fit_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/ReadoutCard/ReadoutMargin/ReadoutRow/FitValueLabel

@onready var decoder_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/DecoderTitle
@onready var bit_knob: Control = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BitKnob
@onready var knob_hint: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/KnobHint
@onready var btn_hint: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowTop/BtnHint
@onready var btn_analyze: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowTop/BtnAnalyze
@onready var btn_capture: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowBottom/BtnCapture
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRowBottom/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/SampleStrip
@onready var status_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusCard
@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusCard/StatusMargin/StatusLabel
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
var overshoot_count: int = 0

var current_trial_idx: int = 0
var anchor_countdown: int = 0
var sample_refs: Array[Dictionary] = []
var trial_seq: int = 0
var trial_event_log: Array = []

var analysis_committed: bool = false
var analysis_revealing: bool = false
var analyze_reveal_until: float = 0.0
var last_analysis_fit: bool = false
var last_analysis_minimal: bool = false
var last_analysis_overkill: bool = false
var last_analyzed_bits: int = -1
var time_to_analyze_ms: float = -1.0
var time_to_hint_ms: float = -1.0
var time_from_analyze_to_capture_ms: float = -1.0
var first_knob_value: int = -1
var last_knob_value: int = -1
var max_distance_from_target: int = 0
var hint_before_analyze: bool = false
var changed_after_analysis_count: int = 0
var capture_without_analyze: bool = false
var last_outcome_code: String = ""

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
var _mission_card_base_min_height: float = 160.0

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
	sample_strip.visible = false
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
			"STEP 2/3: channel analysis in progress... {left}s",
			COLOR_WARN,
			{"left": "%.1f" % remaining}
		)
		if now_sec >= analyze_reveal_until:
			analysis_revealing = false
			analysis_committed = true
			last_analyzed_bits = current_bits
			_log_trial_event("analyze_completed", {
				"analyzed_bits": last_analyzed_bits,
				"analysis_fit": last_analysis_fit,
				"analysis_minimal": last_analysis_minimal,
				"analysis_overkill": last_analysis_overkill
			})
			bit_knob.mouse_filter = Control.MOUSE_FILTER_STOP
			btn_hint.disabled = false
			btn_capture.disabled = false
			btn_analyze.disabled = false
			_set_fit_label_from_analysis()
			_update_details_text()
			_set_status_i18n(
				"quest.radio.a.status.analyze_done",
				"STEP 3/3: result ready, press CAPTURE.",
				COLOR_GOOD
			)
	_update_header_meta()
	_update_waveform()
func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.get_text(key, merged)

func _configure_text_overflow() -> void:
	for lbl in [knob_hint, bits_value_label, fit_value_label, status_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for lbl in [target_label, rule_label, steps_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	status_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	for btn in [btn_hint, btn_analyze, btn_capture, btn_next, btn_details]:
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_i18n() -> void:
	title_label.text = _tr("quest.radio.a.ui.title", "RADIO INTERCEPT | A")
	btn_back.text = _tr("quest.radio.common.btn.back", "BACK")
	mission_title.text = _tr("quest.radio.a.ui.mission", "MISSION")
	rule_label.text = _tr("quest.radio.a.ui.rule", "Find minimal i where 2^i >= N")
	steps_label.text = _tr("quest.radio.a.ui.steps", "Steps: 1) set i  2) ANALYZE  3) CAPTURE")
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
	_request_mission_card_refresh()
	_apply_status_i18n()
	_update_header_meta()
	_update_details_text()

func _update_dynamic_texts() -> void:
	rule_label.text = _tr("quest.radio.a.ui.rule", "Find minimal i where 2^i >= N")
	steps_label.text = _tr("quest.radio.a.ui.steps", "Steps: 1) set i  2) ANALYZE  3) CAPTURE")

	var n_text: Variant = target_n if target_n > 0 else "?"
	target_label.text = _tr("quest.radio.a.ui.given", "Given: N = {n}", {"n": n_text})

	var bits_value: int = current_bits
	if bits_value <= 0:
		bits_value = _i_min
	bits_value_label.text = _tr("quest.radio.a.bits_current", "CURRENT i: {bits} BIT", {"bits": bits_value})
	_request_mission_card_refresh()

func _request_mission_card_refresh() -> void:
	call_deferred("_refresh_mission_card_min_height")

func _label_required_height(label: Label) -> float:
	if label == null:
		return 0.0
	var font: Font = label.get_theme_font("font")
	if font == null:
		return label.get_combined_minimum_size().y
	var font_size: int = label.get_theme_font_size("font_size")
	var line_count: int = maxi(1, label.get_line_count())
	return font.get_height(font_size) * float(line_count)

func _refresh_mission_card_min_height() -> void:
	if mission_card == null or mission_margin == null or mission_vbox == null:
		return
	var content_height: float = 0.0
	content_height += _label_required_height(mission_title)
	content_height += _label_required_height(target_label)
	content_height += _label_required_height(rule_label)
	content_height += _label_required_height(steps_label)
	content_height += float(mission_vbox.get_theme_constant("separation")) * 3.0
	content_height += float(mission_margin.get_theme_constant("margin_top"))
	content_height += float(mission_margin.get_theme_constant("margin_bottom"))
	var min_height: float = maxf(_mission_card_base_min_height, mission_margin.get_combined_minimum_size().y)
	mission_card.custom_minimum_size.y = maxf(min_height, content_height + 8.0)

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

func _elapsed_trial_ms() -> float:
	return maxf(0.0, (Time.get_ticks_msec() / 1000.0 - start_time) * 1000.0)

func _log_trial_event(event_type: String, meta: Dictionary = {}) -> void:
	var t_ms: float = _elapsed_trial_ms()
	trial_event_log.append({
		"t_ms": t_ms,
		"type": event_type,
		"bits": current_bits,
		"target_bits": target_bits,
		"meta": meta.duplicate(true)
	})

func _start_trial() -> void:
	trial_seq += 1
	trial_active = true
	hint_used = false
	capture_without_analyze = false
	hint_before_analyze = false
	start_time = Time.get_ticks_msec() / 1000.0
	first_action_timestamp = -1.0

	analyze_count = 0
	knob_change_count = 0
	direction_change_count = 0
	cross_target_count = 0
	last_diff_sign = 0
	overshoot_count = 0
	changed_after_analysis_count = 0
	trial_event_log = []

	analysis_committed = false
	analysis_revealing = false
	analyze_reveal_until = 0.0
	last_analysis_fit = false
	last_analysis_minimal = false
	last_analysis_overkill = false
	last_analyzed_bits = -1
	time_to_analyze_ms = -1.0
	time_to_hint_ms = -1.0
	time_from_analyze_to_capture_ms = -1.0
	first_knob_value = -1
	last_knob_value = -1
	max_distance_from_target = 0
	last_outcome_code = ""
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
	_update_dynamic_texts()

	current_bits = _i_min
	bit_knob.set("value", _i_min)
	_apply_user_bits(_i_min, false)
	_update_dynamic_texts()
	_set_fit_label_unknown()
	if _target_wave_line != null:
		_target_wave_line.visible = false
		_target_wave_line.points = PackedVector2Array()
	_log_trial_event("trial_started", {
		"trial_seq": trial_seq,
		"target_n": target_n,
		"target_bits": target_bits,
		"pool_type": pool_type,
		"forced_sampling": forced_sampling,
		"is_timed_mode": is_timed_mode
	})

	_set_status_i18n(
		"quest.radio.a.status.plan",
		"STEP 1/3: set i and press ANALYZE.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	_update_header_meta()
	_update_details_text()
	_request_mission_card_refresh()

func _mark_first_action() -> void:
	if first_action_timestamp < 0.0:
		first_action_timestamp = Time.get_ticks_msec() / 1000.0

func _on_knob_value_changed(new_value: int) -> void:
	if not trial_active or analysis_revealing:
		return
	_apply_user_bits(new_value, true)

func _apply_user_bits(i_value: int, from_user: bool) -> void:
	var prev_bits: int = current_bits
	var analysis_committed_before: bool = analysis_committed
	var was_first_action: bool = false
	if from_user:
		was_first_action = first_action_timestamp < 0.0
		_mark_first_action()

	current_bits = clampi(i_value, _i_min, _i_max)

	if from_user:
		if was_first_action:
			_log_trial_event("first_action", {
				"source": "knob",
				"from_bits": prev_bits,
				"to_bits": current_bits
			})
		if first_knob_value < 0:
			first_knob_value = current_bits
		last_knob_value = current_bits
		knob_change_count += 1
		var diff_sign: int = signi(target_bits - current_bits)
		var direction_changed: bool = false
		var crossed_target: bool = false
		if last_diff_sign != 0 and diff_sign != 0 and diff_sign != last_diff_sign:
			direction_change_count += 1
			cross_target_count += 1
			direction_changed = true
			crossed_target = true
		if (prev_bits - target_bits) * (current_bits - target_bits) < 0:
			overshoot_count += 1
			crossed_target = true
		last_diff_sign = diff_sign
		var distance_to_target: int = abs(current_bits - target_bits)
		max_distance_from_target = maxi(max_distance_from_target, distance_to_target)
		noise_seed = int((noise_seed * 1103515245 + 12345 + current_bits * 17) & 0x7fffffff)
		_log_trial_event("knob_change", {
			"from_bits": prev_bits,
			"to_bits": current_bits,
			"distance_to_target": distance_to_target,
			"crossed_target": crossed_target,
			"direction_changed": direction_changed,
			"analysis_committed_before": analysis_committed_before
		})
		if analysis_committed_before:
			changed_after_analysis_count += 1
			_log_trial_event("changed_after_analysis", {
				"changed_after_analysis_count": changed_after_analysis_count,
				"from_bits": prev_bits,
				"to_bits": current_bits
			})
			analysis_committed = false
			last_analyzed_bits = -1
			btn_capture.disabled = true
			_set_fit_label_unknown()
			_set_status_i18n(
				"quest.radio.a.status.changed_after_analysis",
				"i changed. Run ANALYZE again.",
				Color(0.85, 0.85, 0.85, 1.0)
			)

	_update_dynamic_texts()
	if analysis_committed and current_bits == last_analyzed_bits:
		_set_fit_label_from_analysis()
	else:
		_set_fit_label_unknown()
	_update_details_text()

func _on_hint_pressed() -> void:
	if not trial_active:
		return
	var was_first_action: bool = first_action_timestamp < 0.0
	_mark_first_action()
	if was_first_action:
		_log_trial_event("first_action", {"source": "hint"})
	hint_used = true
	if time_to_hint_ms < 0.0:
		time_to_hint_ms = _elapsed_trial_ms()
	if analyze_count == 0:
		hint_before_analyze = true
	_log_trial_event("hint_opened", {
		"hint_before_analyze": analyze_count == 0,
		"distance_to_target": abs(current_bits - target_bits),
		"knob_change_count": knob_change_count
	})
	_set_status_i18n(
		"quest.radio.a.status.hint",
		"Hint: use rule 2^i >= N and choose minimal i.",
		Color(0.55, 0.85, 1.0, 1.0)
	)
	_update_details_text()

func _on_analyze_pressed() -> void:
	if not trial_active or analysis_revealing:
		return
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var was_first_action: bool = first_action_timestamp < 0.0
	_mark_first_action()
	if was_first_action:
		_log_trial_event("first_action", {"source": "analyze"})
	analyze_count += 1
	if time_to_analyze_ms < 0.0:
		time_to_analyze_ms = maxf(0.0, (now_sec - start_time) * 1000.0)
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
	_log_trial_event("analyze_pressed", {
		"capacity": capacity,
		"analysis_fit": last_analysis_fit,
		"analysis_minimal": last_analysis_minimal,
		"analysis_overkill": last_analysis_overkill,
		"distance_to_target": abs(current_bits - target_bits),
		"analyze_count": analyze_count
	})
	_set_status_i18n(
		"quest.radio.a.status.analyze_progress",
		"STEP 2/3: channel analysis in progress... {left}s",
		COLOR_WARN,
		{"left": "%.1f" % ANALYZE_REVEAL_SECONDS}
	)
	_set_fit_label_from_analysis()
	analyze_reveal_until = now_sec + ANALYZE_REVEAL_SECONDS
	_update_details_text()
func _on_capture_pressed() -> void:
	if not trial_active or btn_capture.disabled:
		return
	var was_first_action: bool = first_action_timestamp < 0.0
	_mark_first_action()
	if was_first_action:
		_log_trial_event("first_action", {"source": "capture"})
	capture_without_analyze = analyze_count == 0
	if analysis_committed and time_to_analyze_ms >= 0.0:
		time_from_analyze_to_capture_ms = maxf(0.0, _elapsed_trial_ms() - time_to_analyze_ms)
	_log_trial_event("capture_pressed", {
		"capture_without_analyze": capture_without_analyze,
		"analysis_committed": analysis_committed,
		"distance_to_target": abs(current_bits - target_bits)
	})
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
		_set_status_i18n("quest.radio.a.result.bad", "Result: packet does not fit.", COLOR_BAD)
	elif is_minimal:
		_set_status_i18n("quest.radio.a.result.good", "Result: exact minimal i, excellent.", COLOR_GOOD)
	else:
		_set_status_i18n("quest.radio.a.result.warn", "Result: valid, but i is overprovisioned.", COLOR_WARN)

	_update_sample_slot(is_fit, is_minimal)

	if first_action_timestamp > 0.0:
		prev_time_to_first_action = first_action_timestamp - start_time
	else:
		prev_time_to_first_action = duration

	var scrubbed_guessing: bool = direction_change_count >= 2 or cross_target_count >= 2
	var valid_for_mastery: bool = is_fit and is_minimal and (not hint_used) and analyze_count <= 1 and (not scrubbed_guessing)
	var mastery_block_reason: String = "NONE"
	if is_timeout:
		mastery_block_reason = "TIMEOUT"
	elif not is_fit:
		mastery_block_reason = "NOT_FIT"
	elif not is_minimal:
		mastery_block_reason = "OVERKILL"
	elif hint_used:
		mastery_block_reason = "USED_HINT"
	elif analyze_count > 1:
		mastery_block_reason = "TOO_MANY_ANALYZE"
	elif scrubbed_guessing:
		mastery_block_reason = "SCRUBBED_GUESSING"

	if is_timeout:
		last_outcome_code = "TIMEOUT_UNDERFIT"
	elif not is_fit:
		last_outcome_code = "UNDERFIT"
	elif is_minimal:
		last_outcome_code = "MINIMAL_FIT"
	else:
		last_outcome_code = "OVERKILL_FIT"

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "A",
		"match_key": "RI_A_%s_%s_N%d" % ["TIMED" if is_timed_mode else "UNTIMED", pool_type, target_n],
		"trial_seq": trial_seq,
		"pool_type": pool_type,
		"N": target_n,
		"i_min": target_bits,
		"chosen_i": current_bits,
		"capacity": capacity,
		"final_gap_bits": current_bits - target_bits,
		"is_fit": is_fit,
		"is_correct": is_fit,
		"is_minimal": is_minimal,
		"is_overkill": is_overkill,
		"outcome_code": last_outcome_code,
		"used_analyze": used_analyze,
		"used_hint": hint_used,
		"hint_before_analyze": hint_before_analyze,
		"capture_without_analyze": capture_without_analyze,
		"valid_for_mastery": valid_for_mastery,
		"mastery_block_reason": mastery_block_reason,
		"valid_for_diagnostics": true,
		"forced_sampling": forced_sampling,
		"analyze_count": analyze_count,
		"knob_change_count": knob_change_count,
		"direction_change_count": direction_change_count,
		"cross_target_count": cross_target_count,
		"overshoot_count": overshoot_count,
		"changed_after_analysis_count": changed_after_analysis_count,
		"max_distance_from_target": max_distance_from_target,
		"first_knob_value": first_knob_value,
		"last_knob_value": last_knob_value,
		"time_to_first_action_ms": prev_time_to_first_action * 1000.0,
		"time_to_hint_ms": time_to_hint_ms,
		"time_to_analyze_ms": time_to_analyze_ms,
		"time_from_analyze_to_capture_ms": time_from_analyze_to_capture_ms,
		"scrubbed_guessing": scrubbed_guessing,
		"elapsed_ms": duration * 1000.0,
		"event_log": trial_event_log.duplicate(true)
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

func _set_fit_label_unknown() -> void:
	fit_value_label.text = _tr("quest.radio.a.fit.unknown", "CHECK: NOT RUN")
	fit_value_label.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80, 1.0))

func _set_fit_label_from_analysis() -> void:
	if not last_analysis_fit:
		fit_value_label.text = _tr("quest.radio.a.fit.underfit", "CHECK: UNDER CAPACITY")
		fit_value_label.add_theme_color_override("font_color", COLOR_BAD)
	elif last_analysis_overkill:
		fit_value_label.text = _tr("quest.radio.a.fit.overkill", "CHECK: OVERKILL")
		fit_value_label.add_theme_color_override("font_color", COLOR_WARN)
	elif last_analysis_minimal:
		fit_value_label.text = _tr("quest.radio.a.fit.minimal", "CHECK: MINIMAL")
		fit_value_label.add_theme_color_override("font_color", COLOR_GOOD)
	else:
		fit_value_label.text = _tr("quest.radio.a.fit.yes", "FIT: YES")
		fit_value_label.add_theme_color_override("font_color", COLOR_GOOD)

func _update_details_text() -> void:
	var lines: Array[String] = []
	if trial_active:
		lines.append(_tr("quest.radio.a.details.given", "Given: N = {n}", {"n": target_n}))
		lines.append(_tr("quest.radio.a.details.rule", "Rule: find minimal i where 2^i >= N."))
		lines.append(_tr("quest.radio.a.ui.steps", "Steps: 1) set i  2) ANALYZE  3) CAPTURE"))
		if hint_used or analysis_committed:
			var lower_i_live: int = maxi(0, target_bits - 1)
			var lower_capacity_live: int = int(pow(2.0, lower_i_live))
			var minimal_capacity_live: int = int(pow(2.0, target_bits))
			lines.append(_tr("quest.radio.a.details.lower", "2^{li} = {lc} < {n} (insufficient)", {
				"li": lower_i_live,
				"lc": lower_capacity_live,
				"n": target_n
			}))
			lines.append(_tr("quest.radio.a.details.minimal", "2^{ti} = {tc} >= {n} (minimal fit)", {
				"ti": target_bits,
				"tc": minimal_capacity_live,
				"n": target_n
			}))
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
	sample_strip.visible = false

	mission_card.size_flags_vertical = 0
	readout_card.size_flags_vertical = 0
	scope_card.size_flags_vertical = 3
	status_card.size_flags_vertical = 0

	btn_hint.size_flags_stretch_ratio = 0.85
	btn_analyze.size_flags_stretch_ratio = 1.45
	btn_capture.size_flags_stretch_ratio = 1.0
	btn_next.size_flags_stretch_ratio = 1.0
	btn_details.modulate = Color(0.86, 0.86, 0.90, 0.95)

	if phone_landscape:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 380, 360)
		root_vbox.add_theme_constant_override("separation", 8)
		bit_knob.custom_minimum_size = Vector2(200, 200)
		_mission_card_base_min_height = 172.0
		mission_card.custom_minimum_size.y = _mission_card_base_min_height
		readout_card.custom_minimum_size.y = 72
		scope_card.custom_minimum_size.y = 132
		status_card.custom_minimum_size.y = 108
		target_label.add_theme_font_size_override("font_size", 22)
		rule_label.add_theme_font_size_override("font_size", 17)
		steps_label.add_theme_font_size_override("font_size", 15)
		bits_value_label.add_theme_font_size_override("font_size", 26)
		fit_value_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_font_size_override("font_size", 18)
		btn_details.add_theme_font_size_override("font_size", 14)
		btn_hint.add_theme_font_size_override("font_size", 17)
		btn_analyze.add_theme_font_size_override("font_size", 21)
		meta_label.add_theme_font_size_override("font_size", 16)
		btn_back.custom_minimum_size.y = 52
		btn_hint.custom_minimum_size.y = 46
		btn_analyze.custom_minimum_size.y = 60
		btn_capture.custom_minimum_size.y = 54
		btn_next.custom_minimum_size.y = 54
		btn_details.custom_minimum_size.y = 40
		btn_close_details.custom_minimum_size.y = 52
	elif size.x < 1280.0:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 420, 380)
		root_vbox.add_theme_constant_override("separation", 10)
		bit_knob.custom_minimum_size = Vector2(220, 220)
		_mission_card_base_min_height = 188.0
		mission_card.custom_minimum_size.y = _mission_card_base_min_height
		readout_card.custom_minimum_size.y = 80
		scope_card.custom_minimum_size.y = 162
		status_card.custom_minimum_size.y = 114
		target_label.add_theme_font_size_override("font_size", 24)
		rule_label.add_theme_font_size_override("font_size", 18)
		steps_label.add_theme_font_size_override("font_size", 16)
		bits_value_label.add_theme_font_size_override("font_size", 30)
		fit_value_label.add_theme_font_size_override("font_size", 21)
		status_label.add_theme_font_size_override("font_size", 19)
		btn_details.add_theme_font_size_override("font_size", 15)
		btn_hint.add_theme_font_size_override("font_size", 18)
		btn_analyze.add_theme_font_size_override("font_size", 22)
		meta_label.add_theme_font_size_override("font_size", 17)
		btn_back.custom_minimum_size.y = 56
		btn_hint.custom_minimum_size.y = 48
		btn_analyze.custom_minimum_size.y = 62
		btn_capture.custom_minimum_size.y = 56
		btn_next.custom_minimum_size.y = 56
		btn_details.custom_minimum_size.y = 42
		btn_close_details.custom_minimum_size.y = 56
	else:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.57), 460, 420)
		root_vbox.add_theme_constant_override("separation", 10)
		bit_knob.custom_minimum_size = Vector2(252, 252)
		_mission_card_base_min_height = 204.0
		mission_card.custom_minimum_size.y = _mission_card_base_min_height
		readout_card.custom_minimum_size.y = 86
		scope_card.custom_minimum_size.y = 172
		status_card.custom_minimum_size.y = 122
		target_label.add_theme_font_size_override("font_size", 26)
		rule_label.add_theme_font_size_override("font_size", 18)
		steps_label.add_theme_font_size_override("font_size", 17)
		bits_value_label.add_theme_font_size_override("font_size", 32)
		fit_value_label.add_theme_font_size_override("font_size", 22)
		status_label.add_theme_font_size_override("font_size", 20)
		btn_details.add_theme_font_size_override("font_size", 16)
		btn_hint.add_theme_font_size_override("font_size", 18)
		btn_analyze.add_theme_font_size_override("font_size", 23)
		meta_label.add_theme_font_size_override("font_size", 18)
		btn_back.custom_minimum_size.y = 58
		btn_hint.custom_minimum_size.y = 50
		btn_analyze.custom_minimum_size.y = 64
		btn_capture.custom_minimum_size.y = 58
		btn_next.custom_minimum_size.y = 58
		btn_details.custom_minimum_size.y = 44
		btn_close_details.custom_minimum_size.y = 56
	_request_mission_card_refresh()

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
	var main_amp: float = draw_size.y * 0.07
	var noise_amp: float = draw_size.y * 0.035
	var seed_phase: float = float(noise_seed % 100000) * 0.001
	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y + sin((t * TAU * 1.8) + osc_phase * 0.7 + seed_phase) * main_amp
		y += sin((t * TAU * 6.0) + osc_phase * 0.9 + seed_phase * 1.3) * noise_amp * 0.40
		y += cos((t * TAU * 11.0) + osc_phase * 0.5 - seed_phase * 0.7) * noise_amp * 0.28
		points.append(Vector2(x, y))
	wave_line.default_color = Color(0.24, 0.72, 0.32, 0.70)
	wave_line.points = points

func _draw_analysis_wave(draw_size: Vector2) -> void:
	if _target_wave_line == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	var center_y: float = draw_size.y * 0.5
	var normalized: float = float(target_bits - _i_min) / maxf(1.0, float(_i_max - _i_min))
	var amp: float = draw_size.y * (0.08 + normalized * 0.10)
	for x in range(0, int(draw_size.x) + 1, 6):
		var t: float = float(x) / maxf(1.0, draw_size.x)
		var y: float = center_y + sin((t * TAU * 2.0) + 0.15) * amp
		points.append(Vector2(x, y))
	_target_wave_line.visible = true
	_target_wave_line.default_color = Color(0.88, 0.33, 0.33, 0.88)
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
		_target_wave_line.default_color = Color(0.88, 0.33, 0.33, 0.88)
		wave_layer.add_child(_target_wave_line)
	_target_wave_line.visible = false
