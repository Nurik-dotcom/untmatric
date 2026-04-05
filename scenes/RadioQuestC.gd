extends Control

enum State {
	TUNE,
	ANALYZE_LOCK,
	DECIDE,
	EXEC,
	DONE
}

enum Decision {
	NONE,
	RISK,
	ABORT
}

enum Outcome {
	NONE,
	SUCCESS_SEND,
	INTERCEPTED,
	SAFE_ABORT,
	MISSED_WINDOW
}

const RadioLevels := preload("res://scripts/radio_intercept/RadioLevels.gd")

const EPS: float = 0.05
const MIN_ESTIMATE: float = 0.0
const MAX_ESTIMATE: float = 30.0
const SAMPLE_SLOTS: int = 7
const TIGHT_LANDSCAPE_MAX_HEIGHT: float = 760.0
const ANALYZE_LOCK_DEFAULT: float = 1.5
const ANALYZE_COOLDOWN_SECONDS: float = 6.0
const ARCADE_MODE_ENABLED: bool = false
const DEFAULT_PLAN_BUDGET_NORMAL: float = 8.0
const DEFAULT_PLAN_BUDGET_ANCHOR: float = 6.0
const DEFAULT_DETECT_MIN: float = 8.0
const DEFAULT_DETECT_MAX: float = 20.0
const DEFAULT_DETECT_MARGIN_INT: float = 3.0
const DEFAULT_DETECT_MARGIN_FRAC: float = 4.0
const DEFAULT_ANCHOR_DETECT_MIN: float = 6.0
const DEFAULT_ANCHOR_DETECT_MAX: float = 12.0
const DEFAULT_BOUNDARY_OFFSET_MIN: float = 0.1
const DEFAULT_BOUNDARY_OFFSET_MAX: float = 0.3

const UNIT_MB := "MB"
const UNIT_GB := "GB"
const UNIT_MBIT_SEC := "Mbps"
const SYMBOL_SEC := "s"





const FALLBACK_POOL_MB_NORMAL: Array[float] = [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 12.0, 16.0, 20.0, 25.0]
const FALLBACK_POOL_GB_NORMAL: Array[float] = [0.5, 1.0, 1.5, 2.0]
const FALLBACK_POOL_SPEED_INT: Array[float] = [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 16.0, 20.0, 25.0]
const FALLBACK_POOL_SPEED_FRAC: Array[float] = [1.5, 2.5, 7.5, 12.5]

const COLOR_SAMPLE_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_SAMPLE_SUCCESS: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_SAMPLE_FAIL: Color = Color(0.95, 0.25, 0.25, 1.0)
const COLOR_SAMPLE_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)

@onready var safe_area: MarginContainer = $SafeArea
@onready var body_split: SplitContainer = $SafeArea/RootVBox/BodyHSplit
@onready var top_bar: PanelContainer = $SafeArea/RootVBox/TopBar
@onready var mission_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard
@onready var status_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftCol/StatusCard
@onready var risk_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard
@onready var actions_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard

@onready var title_label: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/TitleLabel
@onready var mode_chip: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/ModeChip
@onready var stability_label: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/StabilityLabel
@onready var noir_overlay: CanvasLayer = $NoirOverlay
@onready var btn_back: Button = $SafeArea/RootVBox/TopBar/TopBarHBox/BtnBack

@onready var mission_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/MissionTitle
@onready var task_line_1: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine1
@onready var task_line_2: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine2
@onready var task_line_3: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine3
@onready var micro_hint: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/MicroHint
@onready var decision_rule_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/DecisionRuleLabel

@onready var step_1_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/Step1Label
@onready var estimate_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/EstimateValue
@onready var time_knob: Control = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/KnobCenter/TimeKnob
@onready var btn_minus_1: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnMinus1
@onready var btn_minus_01: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnMinus01
@onready var btn_plus_01: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnPlus01
@onready var btn_plus_1: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnPlus1
@onready var btn_analyze: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/BtnAnalyze

@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/StatusCard/StatusMargin/StatusLabel

@onready var step_2_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/Step2Label
@onready var detection_title: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectionTitle
@onready var detection_bar: ProgressBar = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectionBar
@onready var detect_countdown: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectCountdown
@onready var transfer_title: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferTitle
@onready var transfer_bar: ProgressBar = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferBar
@onready var transfer_countdown: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferCountdown
@onready var compare_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/CompareCard
@onready var compare_title: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/CompareCard/CompareMargin/CompareVBox/CompareTitle
@onready var compare_line_1: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/CompareCard/CompareMargin/CompareVBox/CompareLine1
@onready var compare_line_2: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/CompareCard/CompareMargin/CompareVBox/CompareLine2
@onready var risk_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/RiskLabel

@onready var step_3_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/Step3Label
@onready var helper_row: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/HelperRow
@onready var btn_units: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/HelperRow/BtnUnits
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/HelperRow/BtnDetails
@onready var btn_risk: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/PrimaryActionsRow/BtnRisk
@onready var btn_abort: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/PrimaryActionsRow/BtnAbort
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/NextRow/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/SampleStrip

@onready var details_overlay: Control = $DetailsOverlay
@onready var details_dimmer: ColorRect = $DetailsOverlay/Dim
@onready var details_sheet_title: Label = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/SheetTitle
@onready var details_sheet_text: RichTextLabel = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/SheetText
@onready var btn_close_details: Button = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/BtnCloseDetails

@onready var alarm_flash: ColorRect = $AlarmFlash

var state: State = State.TUNE
var decision: Decision = Decision.NONE
var outcome: Outcome = Outcome.NONE

var file_size_value: float = 0.0
var file_size_unit: String = UNIT_MB
var speed_mbit: float = 0.0
var t_detect: float = 0.0
var t_true: float = 0.0
var t_est: float = 0.0
var t_plan: float = INF
var plan_elapsed: float = 0.0
var detection_active: bool = false
var live_mode: bool = true

var pool_type: String = "NORMAL"
var anchor_type: String = "none"
var anchor_countdown: int = 0

var detection_elapsed: float = 0.0
var transfer_elapsed: float = 0.0
var transfer_started: bool = false
var used_units: bool = false
var _plan_timeout_triggered: bool = false

var start_ms: int = 0
var first_action_ms: int = -1
var check_ms: int = -1
var decision_ms: int = -1

var analyze_count: int = 0
var knob_moves_count: int = 0
var direction_changes: int = 0
var _last_move_sign: int = 0
var analyze_lock_active: bool = false
var analyze_lock_until: float = 0.0
var analyze_cooldown_until: float = 0.0
var trial_seq: int = 0
var trial_event_log: Array = []

var details_open_count: int = 0
var details_open_before_decision: bool = false
var details_close_count: int = 0
var first_details_open_ms: int = -1
var first_units_hint_ms: int = -1
var first_risk_or_abort_ms: int = -1

var analyze_cooldown_hit_count: int = 0
var analyze_after_units: bool = false
var units_before_analyze: bool = false
var units_before_decision: bool = false

var estimate_at_first_analyze: float = -1.0
var estimate_at_last_analyze: float = -1.0
var estimate_at_decision: float = -1.0
var estimate_delta_after_analyze: float = 0.0

var first_margin_vs_detect: float = INF
var final_margin_vs_detect: float = INF
var true_margin_vs_detect: float = INF
var remaining_detect_at_decision: float = INF

var borderline_case: bool = false
var decision_quality: String = "unknown"
var mastery_block_reason: String = "NONE"

var knob_value_at_first_action: float = 0.0
var peak_estimate_error_abs: float = 0.0
var estimate_cross_count: int = 0
var _last_estimate_sign_vs_true: int = 0

var _pool_mb_normal: Array[float] = []
var _pool_gb_normal: Array[float] = []
var _pool_speed_int: Array[float] = []
var _pool_speed_frac: Array[float] = []
var _t_true_min: float = 2.0
var _t_true_max: float = 20.0
var _anchor_every_min: int = 7
var _anchor_every_max: int = 10
var _plan_budget_normal: float = DEFAULT_PLAN_BUDGET_NORMAL
var _plan_budget_anchor: float = DEFAULT_PLAN_BUDGET_ANCHOR
var _analyze_lock_seconds: float = ANALYZE_LOCK_DEFAULT
var _detect_min_sec: float = DEFAULT_DETECT_MIN
var _detect_max_sec: float = DEFAULT_DETECT_MAX
var _detect_margin_int: float = DEFAULT_DETECT_MARGIN_INT
var _detect_margin_frac: float = DEFAULT_DETECT_MARGIN_FRAC
var _anchor_detect_min: float = DEFAULT_ANCHOR_DETECT_MIN
var _anchor_detect_max: float = DEFAULT_ANCHOR_DETECT_MAX
var _boundary_offset_min: float = DEFAULT_BOUNDARY_OFFSET_MIN
var _boundary_offset_max: float = DEFAULT_BOUNDARY_OFFSET_MAX

var sample_cursor: int = 0
var sample_refs: Array = []
var _ui_ready: bool = false
var _left_scroll_installed: bool = false
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
	_collect_sample_refs()
	_reset_sample_strip()
	sample_strip.visible = false
	_apply_safe_area_padding()
	_configure_layout()
	_install_left_col_scroll()
	_set_details_visible(false)

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
		_install_left_col_scroll()
		_configure_layout()

func _process(delta: float) -> void:
	if state == State.DONE:
		return

	if state == State.TUNE:
		if live_mode and is_finite(t_plan):
			plan_elapsed += delta
			if plan_elapsed >= t_plan:
				plan_elapsed = t_plan
				_plan_timeout_triggered = true
				_log_trial_event("plan_timeout", {
					"plan_elapsed": plan_elapsed,
					"t_plan": t_plan,
					"analyze_count": analyze_count
				})
				if decision_ms < 0:
					decision_ms = Time.get_ticks_msec()
				_play_alarm_flash()
				_finalize_trial(Outcome.INTERCEPTED, "TIMEOUT")
				return
		_update_runtime_ui()
		return

	if detection_active and live_mode and is_finite(t_detect):
		detection_elapsed += delta
	if state == State.EXEC and decision == Decision.RISK and transfer_started:
		transfer_elapsed += delta

	_update_runtime_ui()

	if detection_active and live_mode and decision == Decision.NONE and detection_elapsed >= t_detect:
		_log_trial_event("decision_window_missed", {
			"detection_elapsed": detection_elapsed,
			"t_detect": t_detect,
			"decision": _decision_to_text(decision)
		})
		if decision_ms < 0:
			decision_ms = Time.get_ticks_msec()
		_play_alarm_flash()
		_finalize_trial(Outcome.INTERCEPTED, "NONE")
		return

	if state == State.ANALYZE_LOCK:
		var now_sec: float = Time.get_ticks_msec() / 1000.0
		var left: float = maxf(0.0, analyze_lock_until - now_sec)
		_set_status_i18n(
			"quest.radio.c.status.analyze_lock_progress",
			"STEP 2/3: channel scan in progress... {left}s",
			Color(0.85, 0.85, 0.85, 1.0),
			{"left": "%.1f" % left}
		)
		if now_sec < analyze_lock_until:
			return
		analyze_lock_active = false
		borderline_case = live_mode and is_finite(t_detect) and absf(_current_margin_vs_detect()) <= _borderline_eps()
		_log_trial_event("analyze_completed", {
			"t_est_after_lock": t_est,
			"remaining_detect": _current_detect_value(),
			"borderline_case": borderline_case
		})
		_set_decide_state_ui()
		_update_details_text()
		return

	if state == State.EXEC and decision == Decision.RISK:
		if transfer_elapsed >= t_true and (not live_mode or detection_elapsed <= t_detect + EPS):
			_finalize_trial(Outcome.SUCCESS_SEND, "RISK")
			return
		if detection_active and live_mode and detection_elapsed >= t_detect and transfer_elapsed < t_true - EPS:
			_play_alarm_flash()
			_finalize_trial(Outcome.INTERCEPTED, "RISK")
			return

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.get_text(key, merged)

func _apply_i18n() -> void:
	title_label.text = _tr("quest.radio.c.ui.title", "RADIO INTERCEPT | C")
	mission_title.text = _tr("quest.radio.c.ui.mission", "URGENT TRANSMISSION")
	micro_hint.text = _tr("quest.radio.c.ui.hint", "Formula: t = I / v. Estimate transfer time, then ANALYZE, then compare with the intercept window.")
	decision_rule_label.text = _tr(
		"quest.radio.c.ui.decision_rule",
		"Rule: if transfer estimate fits the intercept window, RISK is acceptable. If it does not fit, ABORT."
	)
	step_1_label.text = _tr("quest.radio.c.ui.step1", "STEP 1: t = I / v — set estimate")
	step_2_label.text = _tr("quest.radio.c.ui.step2", "STEP 2: Compare forecast with the window")
	step_3_label.text = _tr("quest.radio.c.ui.step3", "STEP 3: Choose action based on comparison")
	detection_title.text = _tr("quest.radio.c.ui.detection_title", "DETECTION")
	compare_title.text = _tr("quest.radio.c.ui.compare_title", "DECISION BASIS")
	btn_back.text = _tr("quest.radio.common.btn.back", "BACK")
	btn_units.text = _tr("quest.radio.c.ui.btn_units", "UNITS HELP")
	btn_details.text = _tr("quest.radio.common.btn.details_open", "DETAILS v")
	btn_analyze.text = _tr("quest.radio.btn.analyze", "ANALYZE")
	btn_risk.text = _tr("quest.radio.btn.risk", "RISK IT")
	btn_abort.text = _tr("quest.radio.btn.abort", "ABORT")
	btn_next.text = _tr("quest.radio.common.btn.next", "NEXT")
	details_sheet_title.text = _tr("quest.radio.c.ui.details_title", "EXPLANATION")
	btn_close_details.text = _tr("quest.radio.common.btn.details_close", "CLOSE")
	_update_mode_chip()
	_refresh_task_labels()
	_apply_status_i18n()
	_update_decision_basis_ui()
	_update_runtime_ui()
	_update_details_text()

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	_update_decision_basis_ui()

func _update_mode_chip() -> void:
	var mode_name: String = _tr("quest.radio.c.ui.mode_live", "LIVE") if live_mode else _tr("quest.radio.c.ui.mode_training", "TRAINING")
	mode_chip.text = _tr("quest.radio.c.ui.mode_template", "MODE: {mode}", {"mode": mode_name})

func _configure_text_overflow() -> void:
	for lbl in [
		task_line_1,
		task_line_2,
		task_line_3,
		micro_hint,
		decision_rule_label,
		compare_title,
		compare_line_1,
		compare_line_2,
		status_label,
		risk_label
	]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for btn in [btn_analyze, btn_units, btn_details, btn_risk, btn_abort, btn_next]:
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	btn_minus_1.pressed.connect(_on_minus_1_pressed)
	btn_minus_01.pressed.connect(_on_minus_01_pressed)
	btn_plus_01.pressed.connect(_on_plus_01_pressed)
	btn_plus_1.pressed.connect(_on_plus_1_pressed)
	btn_units.pressed.connect(_on_units_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_close_pressed)
	details_dimmer.gui_input.connect(_on_dimmer_gui_input)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_risk.pressed.connect(_on_risk_pressed)
	btn_abort.pressed.connect(_on_abort_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	var knob_callback: Callable = Callable(self, "_on_knob_value_changed")
	if not time_knob.is_connected("value_changed", knob_callback):
		time_knob.connect("value_changed", knob_callback)

func _apply_safe_area_padding() -> void:
	if safe_area == null:
		return

	var base_left: float = 16.0
	var base_top: float = 12.0
	var base_right: float = 16.0
	var base_bottom: float = 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		base_left = maxf(base_left, float(safe_rect.position.x))
		base_top = maxf(base_top, float(safe_rect.position.y))
		base_right = maxf(base_right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		base_bottom = maxf(base_bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(base_left)))
	safe_area.add_theme_constant_override("margin_top", int(round(base_top)))
	safe_area.add_theme_constant_override("margin_right", int(round(base_right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(base_bottom)))

func _install_left_col_scroll() -> void:
	if _left_scroll_installed:
		return
	if body_split == null:
		return
	var left_col := body_split.get_node_or_null("LeftCol") as VBoxContainer
	if left_col == null:
		var existing_scroll: Node = body_split.get_node_or_null("LeftColScroll")
		if existing_scroll is ScrollContainer and existing_scroll.get_node_or_null("LeftCol") != null:
			_left_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "LeftColScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var idx: int = left_col.get_index()
	var parent: Node = left_col.get_parent()
	parent.remove_child(left_col)
	parent.add_child(scroll)
	parent.move_child(scroll, idx)
	scroll.add_child(left_col)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_scroll_installed = true

func _configure_layout() -> void:
	if body_split == null or time_knob == null:
		return

	body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = size.x > size.y
	var is_portrait: bool = size.x <= size.y
	var ultra_compact: bool = size.y <= 400.0 and is_landscape
	var ultra_tight: bool = is_landscape and size.y <= 420.0
	var is_tight_landscape: bool = is_landscape and size.y <= TIGHT_LANDSCAPE_MAX_HEIGHT
	var knob_min_side: float = 320.0
	if size.y < 620.0:
		knob_min_side = 260.0
	elif size.y < 700.0:
		knob_min_side = 300.0
	body_split.vertical = is_portrait

	mission_card.visible = true
	task_line_2.visible = true
	task_line_3.visible = true
	micro_hint.visible = true
	decision_rule_label.visible = true

	if is_portrait:
		body_split.split_offset = int(size.y * 0.4)
		top_bar.custom_minimum_size.y = 48.0
		mission_card.custom_minimum_size.y = 80.0
		status_card.custom_minimum_size.y = 68.0
		compare_card.custom_minimum_size.y = 68.0
		actions_card.custom_minimum_size.y = 180.0
		time_knob.custom_minimum_size = Vector2(160, 160)
		task_line_2.visible = false
		task_line_3.visible = false
		micro_hint.visible = false
		decision_rule_label.visible = false
		title_label.add_theme_font_size_override("font_size", 18)
		mode_chip.add_theme_font_size_override("font_size", 12)
		stability_label.add_theme_font_size_override("font_size", 12)
		estimate_value_label.add_theme_font_size_override("font_size", 20)
		status_label.add_theme_font_size_override("font_size", 15)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 44.0
		btn_analyze.custom_minimum_size.y = 52.0
		btn_risk.custom_minimum_size.y = 56.0
		btn_abort.custom_minimum_size.y = 56.0
		btn_units.custom_minimum_size.y = 44.0
		btn_details.custom_minimum_size.y = 44.0
		btn_next.custom_minimum_size.y = 44.0
		btn_close_details.custom_minimum_size.y = 44.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 0.8
		actions_card.size_flags_stretch_ratio = 1.2
	elif ultra_compact:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.48), 300, 280)
		top_bar.custom_minimum_size.y = 46.0
		mission_card.custom_minimum_size.y = 100.0
		status_card.custom_minimum_size.y = 64.0
		compare_card.custom_minimum_size.y = 64.0
		actions_card.custom_minimum_size.y = 170.0
		time_knob.custom_minimum_size = Vector2(150, 150)
		task_line_2.visible = false
		task_line_3.visible = false
		micro_hint.visible = false
		decision_rule_label.visible = false
		title_label.add_theme_font_size_override("font_size", 17)
		mode_chip.add_theme_font_size_override("font_size", 12)
		stability_label.add_theme_font_size_override("font_size", 12)
		estimate_value_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_font_size_override("font_size", 15)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 40.0
		btn_analyze.custom_minimum_size.y = 48.0
		btn_risk.custom_minimum_size.y = 52.0
		btn_abort.custom_minimum_size.y = 52.0
		btn_units.custom_minimum_size.y = 40.0
		btn_details.custom_minimum_size.y = 40.0
		btn_next.custom_minimum_size.y = 42.0
		btn_close_details.custom_minimum_size.y = 40.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 0.8
		actions_card.size_flags_stretch_ratio = 1.2
	elif ultra_tight:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 340, 340)
		top_bar.custom_minimum_size.y = 48.0
		mission_card.custom_minimum_size.y = 60.0
		status_card.custom_minimum_size.y = 56.0
		compare_card.custom_minimum_size.y = 64.0
		actions_card.custom_minimum_size.y = 176.0
		time_knob.custom_minimum_size = Vector2(180, 180)
		task_line_2.visible = false
		task_line_3.visible = false
		micro_hint.visible = false
		decision_rule_label.visible = false
		title_label.add_theme_font_size_override("font_size", 18)
		mode_chip.add_theme_font_size_override("font_size", 12)
		stability_label.add_theme_font_size_override("font_size", 12)
		estimate_value_label.add_theme_font_size_override("font_size", 20)
		status_label.add_theme_font_size_override("font_size", 15)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 44.0
		btn_analyze.custom_minimum_size.y = 52.0
		btn_risk.custom_minimum_size.y = 56.0
		btn_abort.custom_minimum_size.y = 56.0
		btn_units.custom_minimum_size.y = 44.0
		btn_details.custom_minimum_size.y = 44.0
		btn_next.custom_minimum_size.y = 44.0
		btn_close_details.custom_minimum_size.y = 44.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 0.8
		actions_card.size_flags_stretch_ratio = 1.2
	elif is_tight_landscape:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.58), 420, 420)
		top_bar.custom_minimum_size.y = 52.0
		mission_card.custom_minimum_size.y = 156.0
		status_card.custom_minimum_size.y = 84.0
		compare_card.custom_minimum_size.y = 78.0
		actions_card.custom_minimum_size.y = 196.0
		time_knob.custom_minimum_size = Vector2(260, 260)
		title_label.add_theme_font_size_override("font_size", 22)
		mode_chip.add_theme_font_size_override("font_size", 13)
		stability_label.add_theme_font_size_override("font_size", 13)
		estimate_value_label.add_theme_font_size_override("font_size", 26)
		status_label.add_theme_font_size_override("font_size", 19)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 54.0
		btn_analyze.custom_minimum_size.y = 78.0
		btn_risk.custom_minimum_size.y = 76.0
		btn_abort.custom_minimum_size.y = 76.0
		btn_units.custom_minimum_size.y = 50.0
		btn_details.custom_minimum_size.y = 44.0
		btn_next.custom_minimum_size.y = 54.0
		btn_close_details.custom_minimum_size.y = 52.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 0.8
		actions_card.size_flags_stretch_ratio = 1.2
	elif is_landscape and size.x < 1500.0:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.58), 460, 460)
		top_bar.custom_minimum_size.y = 56.0
		mission_card.custom_minimum_size.y = 168.0
		status_card.custom_minimum_size.y = 90.0
		compare_card.custom_minimum_size.y = 86.0
		actions_card.custom_minimum_size.y = 206.0
		time_knob.custom_minimum_size = Vector2(knob_min_side, knob_min_side)
		title_label.add_theme_font_size_override("font_size", 24)
		mode_chip.add_theme_font_size_override("font_size", 14)
		stability_label.add_theme_font_size_override("font_size", 14)
		estimate_value_label.add_theme_font_size_override("font_size", 28)
		status_label.add_theme_font_size_override("font_size", 20)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 60.0
		btn_analyze.custom_minimum_size.y = 88.0
		btn_risk.custom_minimum_size.y = 88.0
		btn_abort.custom_minimum_size.y = 88.0
		btn_units.custom_minimum_size.y = 52.0
		btn_details.custom_minimum_size.y = 46.0
		btn_next.custom_minimum_size.y = 56.0
		btn_close_details.custom_minimum_size.y = 56.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 1.0
		actions_card.size_flags_stretch_ratio = 1.0
	elif is_landscape:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.58), 500, 500)
		top_bar.custom_minimum_size.y = 62.0
		mission_card.custom_minimum_size.y = 182.0
		status_card.custom_minimum_size.y = 96.0
		compare_card.custom_minimum_size.y = 92.0
		actions_card.custom_minimum_size.y = 214.0
		time_knob.custom_minimum_size = Vector2(knob_min_side, knob_min_side)
		title_label.add_theme_font_size_override("font_size", 28)
		mode_chip.add_theme_font_size_override("font_size", 17)
		stability_label.add_theme_font_size_override("font_size", 17)
		estimate_value_label.add_theme_font_size_override("font_size", 32)
		status_label.add_theme_font_size_override("font_size", 21)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 64.0
		btn_analyze.custom_minimum_size.y = 96.0
		btn_risk.custom_minimum_size.y = 92.0
		btn_abort.custom_minimum_size.y = 92.0
		btn_units.custom_minimum_size.y = 54.0
		btn_details.custom_minimum_size.y = 48.0
		btn_next.custom_minimum_size.y = 58.0
		btn_close_details.custom_minimum_size.y = 56.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 1.0
		actions_card.size_flags_stretch_ratio = 1.0
	else:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.56), 520, 460)
		top_bar.custom_minimum_size.y = 62.0
		mission_card.custom_minimum_size.y = 176.0
		status_card.custom_minimum_size.y = 92.0
		compare_card.custom_minimum_size.y = 88.0
		actions_card.custom_minimum_size.y = 208.0
		time_knob.custom_minimum_size = Vector2(knob_min_side, knob_min_side)
		title_label.add_theme_font_size_override("font_size", 30)
		mode_chip.add_theme_font_size_override("font_size", 18)
		stability_label.add_theme_font_size_override("font_size", 18)
		estimate_value_label.add_theme_font_size_override("font_size", 36)
		status_label.add_theme_font_size_override("font_size", 20)
		for btn in [btn_back, btn_minus_1, btn_minus_01, btn_plus_01, btn_plus_1]:
			btn.custom_minimum_size.y = 60.0
		btn_analyze.custom_minimum_size.y = 92.0
		btn_risk.custom_minimum_size.y = 88.0
		btn_abort.custom_minimum_size.y = 88.0
		btn_units.custom_minimum_size.y = 52.0
		btn_details.custom_minimum_size.y = 46.0
		btn_next.custom_minimum_size.y = 56.0
		btn_close_details.custom_minimum_size.y = 56.0
		sample_strip.visible = false
		risk_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		actions_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		risk_card.size_flags_stretch_ratio = 1.0
		actions_card.size_flags_stretch_ratio = 1.0

	btn_units.add_theme_font_size_override("font_size", 18)
	btn_details.add_theme_font_size_override("font_size", 16)

func _clamp_split_offset(target_offset: int, min_left: int, min_right: int) -> int:
	var viewport_width: int = int(get_viewport_rect().size.x)
	var min_offset: int = min_left
	var max_offset: int = max(min_left, viewport_width - min_right)
	return clampi(target_offset, min_offset, max_offset)

func _collect_sample_refs() -> void:
	sample_refs.clear()
	for child_var in sample_strip.get_children():
		var child_node: Node = child_var as Node
		var bg_node: ColorRect = child_node.get_node_or_null("BG") as ColorRect
		var mark_node: Label = child_node.get_node_or_null("AnchorMark") as Label
		if bg_node != null and mark_node != null:
			mark_node.text = "*"
			sample_refs.append({"bg": bg_node, "mark": mark_node})

func _reset_sample_strip() -> void:
	for slot_var in sample_refs:
		var slot: Dictionary = slot_var as Dictionary
		var bg: ColorRect = slot["bg"] as ColorRect
		var mark: Label = slot["mark"] as Label
		bg.color = COLOR_SAMPLE_IDLE
		mark.visible = false

func _elapsed_trial_ms() -> int:
	if start_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - start_ms)

func _state_to_text(current_state: State) -> String:
	match current_state:
		State.TUNE:
			return "TUNE"
		State.ANALYZE_LOCK:
			return "ANALYZE_LOCK"
		State.DECIDE:
			return "DECIDE"
		State.EXEC:
			return "EXEC"
		_:
			return "DONE"

func _decision_to_text(current_decision: Decision) -> String:
	match current_decision:
		Decision.RISK:
			return "RISK"
		Decision.ABORT:
			return "ABORT"
		_:
			return "NONE"

func _current_detect_value() -> float:
	if live_mode and is_finite(t_detect):
		return maxf(0.0, t_detect - detection_elapsed)
	return t_detect

func _current_margin_vs_detect() -> float:
	if live_mode and is_finite(t_detect):
		return _current_detect_value() - t_est
	return INF

func _borderline_eps() -> float:
	if not (live_mode and is_finite(t_detect)):
		return EPS
	return maxf(EPS, minf(0.5, t_detect * 0.03))

func _log_trial_event(event_type: String, meta: Dictionary = {}) -> void:
	trial_event_log.append({
		"t_ms": _elapsed_trial_ms(),
		"type": event_type,
		"state": _state_to_text(state),
		"decision": _decision_to_text(decision),
		"t_est": t_est,
		"t_true": t_true,
		"t_detect_current": _current_detect_value(),
		"meta": meta.duplicate(true)
	})

func _start_trial() -> void:
	trial_seq += 1
	state = State.TUNE
	decision = Decision.NONE
	outcome = Outcome.NONE
	transfer_started = false
	used_units = false
	_plan_timeout_triggered = false

	plan_elapsed = 0.0
	detection_elapsed = 0.0
	detection_active = false
	transfer_elapsed = 0.0

	analyze_count = 0
	knob_moves_count = 0
	direction_changes = 0
	_last_move_sign = 0
	analyze_lock_active = false
	analyze_lock_until = 0.0
	analyze_cooldown_until = 0.0
	analyze_cooldown_hit_count = 0
	analyze_after_units = false
	units_before_analyze = false
	units_before_decision = false
	estimate_at_first_analyze = -1.0
	estimate_at_last_analyze = -1.0
	estimate_at_decision = -1.0
	estimate_delta_after_analyze = 0.0
	first_margin_vs_detect = INF
	final_margin_vs_detect = INF
	true_margin_vs_detect = INF
	remaining_detect_at_decision = INF
	borderline_case = false
	decision_quality = "unknown"
	mastery_block_reason = "NONE"
	knob_value_at_first_action = 0.0
	peak_estimate_error_abs = 0.0
	estimate_cross_count = 0
	_last_estimate_sign_vs_true = 0
	details_open_count = 0
	details_open_before_decision = false
	details_close_count = 0
	first_details_open_ms = -1
	first_units_hint_ms = -1
	first_risk_or_abort_ms = -1
	trial_event_log = []

	start_ms = Time.get_ticks_msec()
	first_action_ms = -1
	check_ms = -1
	decision_ms = -1

	_generate_trial()
	t_plan = INF if not live_mode else (_plan_budget_anchor if pool_type == "ANCHOR" else _plan_budget_normal)
	_update_mode_chip()
	_refresh_task_labels()
	_reset_runtime_ui()
	_set_details_visible(false)
	_set_tune_state_ui()

	time_knob.call("set_knob_value", 0.0, false)
	_set_estimate(0.0)
	peak_estimate_error_abs = absf(t_est - t_true)
	if live_mode and is_finite(t_detect):
		first_margin_vs_detect = t_detect - t_est
		true_margin_vs_detect = t_detect - t_true
	else:
		first_margin_vs_detect = INF
		true_margin_vs_detect = INF
	btn_details.disabled = false
	_update_decision_basis_ui()
	_update_details_text()
	_log_trial_event("trial_started", {
		"trial_seq": trial_seq,
		"pool_type": pool_type,
		"anchor_type": anchor_type,
		"file_size_value": file_size_value,
		"file_size_unit": file_size_unit,
		"speed_mbit": speed_mbit,
		"t_true": t_true,
		"t_detect": t_detect,
		"live_mode": live_mode,
		"plan_budget": t_plan
	})

func _generate_trial() -> void:
	var generated: Dictionary = {}
	if anchor_countdown <= 0:
		pool_type = "ANCHOR"
		var anchor_pick: int = randi() % 3
		if anchor_pick == 0:
			generated = _generate_anchor_forgot_x8()
		elif anchor_pick == 1:
			generated = _generate_anchor_boundary()
		else:
			generated = _generate_anchor_gb()
		if generated.is_empty():
			generated = _generate_normal_trial()
			pool_type = "NORMAL"
		anchor_countdown = _random_anchor_gap()
	else:
		pool_type = "NORMAL"
		generated = _generate_normal_trial()
		anchor_countdown -= 1

	file_size_value = float(generated["size_value"])
	file_size_unit = str(generated["size_unit"])
	speed_mbit = float(generated["speed_mbit"])
	t_detect = float(generated["t_detect"])
	t_true = float(generated["t_true"])
	anchor_type = str(generated["anchor_type"])

func _generate_normal_trial() -> Dictionary:
	for _i in range(500):
		var use_gb: bool = randf() < 0.10
		var size_value: float = 0.0
		var size_unit: String = UNIT_MB
		if use_gb:
			size_value = _pick_from_float_pool(_pool_gb_normal, 1.0)
			size_unit = UNIT_GB
		else:
			size_value = _pick_from_float_pool(_pool_mb_normal, 10.0)
			size_unit = UNIT_MB

		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, size_unit, speed)
		if true_time < _t_true_min or true_time > _t_true_max:
			continue

		var is_frac_speed: bool = absf(speed - roundf(speed)) > 0.01
		var margin: float = _detect_margin_frac if is_frac_speed else _detect_margin_int
		var detect_time: float = clampf(true_time + margin, _detect_min_sec, _detect_max_sec)

		return {
			"size_value": size_value,
			"size_unit": size_unit,
			"speed_mbit": speed,
			"t_detect": detect_time,
			"t_true": true_time,
			"anchor_type": "none"
		}

	return {
		"size_value": 10.0,
		"size_unit": UNIT_MB,
		"speed_mbit": 16.0,
		"t_detect": 8.0,
		"t_true": 5.0,
		"anchor_type": "none"
	}

func _generate_anchor_forgot_x8() -> Dictionary:
	for _i in range(500):
		var size_value: float = _pick_from_float_pool(_pool_mb_normal, 10.0)
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, UNIT_MB, speed)
		if true_time < maxf(_t_true_min + 2.0, 4.0) or true_time > _t_true_max:
			continue

		var fake_time: float = size_value / speed
		var detect_low: float = maxf(fake_time, _anchor_detect_min)
		var detect_high: float = minf(true_time - 0.1, _anchor_detect_max)
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": UNIT_MB,
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x8"
		}
	return {}

func _generate_anchor_boundary() -> Dictionary:
	for _i in range(500):
		var use_gb: bool = randf() < 0.30
		var size_value: float = 0.0
		var size_unit: String = UNIT_MB
		if use_gb:
			size_value = _pick_from_float_pool(_pool_gb_normal, 1.0)
			size_unit = UNIT_GB
		else:
			size_value = _pick_from_float_pool(_pool_mb_normal, 10.0)
			size_unit = UNIT_MB

		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, size_unit, speed)
		if true_time < _t_true_min or true_time > _t_true_max:
			continue

		var detect_time: float = clampf(
			true_time + randf_range(_boundary_offset_min, _boundary_offset_max),
			_anchor_detect_min,
			_anchor_detect_max
		)
		if detect_time >= true_time + 0.05:
			return {
				"size_value": size_value,
				"size_unit": size_unit,
				"speed_mbit": speed,
				"t_detect": detect_time,
				"t_true": true_time,
				"anchor_type": "boundary"
			}
	return {}

func _generate_anchor_gb() -> Dictionary:
	for _i in range(500):
		var size_value: float = _pick_from_float_pool(_pool_gb_normal, 1.0)
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, UNIT_GB, speed)
		if true_time < maxf(_t_true_min + 4.0, 6.0) or true_time > _t_true_max:
			continue

		var fake_time: float = (size_value * 8.0) / speed
		var detect_low: float = maxf(fake_time, _anchor_detect_min)
		var detect_high: float = minf(true_time - 0.1, _anchor_detect_max)
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": UNIT_GB,
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x1024"
		}
	return {}

func _pick_speed() -> float:
	if randf() < 0.30:
		return _pick_from_float_pool(_pool_speed_frac, 2.5)
	return _pick_from_float_pool(_pool_speed_int, 8.0)

func _compute_true_time(size_value: float, size_unit: String, speed: float) -> float:
	var i_mbit: float = size_value * 8.0
	if size_unit == UNIT_GB:
		i_mbit = size_value * 1024.0 * 8.0
	return i_mbit / speed

func _refresh_task_labels() -> void:
	task_line_1.text = _tr("quest.radio.c.task", "Given: file size = {size} {unit}", {
		"size": _format_num(file_size_value),
		"unit": file_size_unit
	})
	task_line_2.text = _tr("quest.radio.c.ui.task_speed", "Channel speed: {speed} {unit}", {
		"speed": _format_num(speed_mbit),
		"unit": _tr("quest.radio.common.unit.mbps", "Mbps")
	})
	if live_mode and is_finite(t_detect):
		task_line_3.text = _tr("quest.radio.c.ui.task_detect", "Intercept window = {time} {unit}", {
			"time": _format_num(t_detect),
			"unit": _tr("quest.radio.common.unit.sec", "s")
		})
	else:
		task_line_3.text = _tr("quest.radio.c.ui.task_detect_training", "Intercept window: training mode (hidden)")

func _reset_runtime_ui() -> void:
	detection_bar.value = 0.0
	transfer_bar.value = 0.0
	detect_countdown.text = _tr("quest.radio.c.ui.waiting", "waiting") if not live_mode else "%s %s" % [_format_num(t_detect), _tr("quest.radio.common.unit.sec", "s")]
	transfer_countdown.text = "\u2014"
	risk_label.text = _tr("quest.radio.c.ui.risk_unknown", "Risk: UNKNOWN")
	alarm_flash.color = Color(1.0, 0.05, 0.05, 0.0)

func _set_tune_state_ui() -> void:
	state = State.TUNE
	_set_knob_interactive(true)
	status_label.remove_theme_color_override("font_color")
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	btn_analyze.disabled = analyze_lock_active or (now_sec < analyze_cooldown_until)
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = false
	btn_details.disabled = false
	btn_next.visible = false
	_set_status_i18n(
		"quest.radio.c.status.step1",
		"STEP 1/3: estimate transfer time t and press ANALYZE.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	if live_mode:
		risk_label.text = _tr("quest.radio.c.status.plan_left", "STATUS: planning budget left {time}s.", {
			"time": _format_num(maxf(0.0, t_plan - plan_elapsed))
		})
	else:
		risk_label.text = _tr("quest.radio.c.ui.mode_training", "TRAINING")
	_apply_phantom_preview()
	_update_decision_basis_ui()

func _set_analyze_lock_state_ui() -> void:
	state = State.ANALYZE_LOCK
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_details.disabled = true
	btn_next.visible = false
	_set_status_i18n(
		"quest.radio.c.status.step2",
		"STEP 2/3: channel scan in progress...",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	if live_mode and is_finite(t_detect):
		risk_label.text = _tr("quest.radio.c.ui.detect_left", "Detection in: {time} s", {
			"time": _format_num(maxf(0.0, t_detect - detection_elapsed))
		})
	else:
		risk_label.text = _tr("quest.radio.c.ui.mode_training", "TRAINING")
	_apply_phantom_preview()
	_update_decision_basis_ui()

func _set_decide_state_ui() -> void:
	state = State.DECIDE
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = false
	btn_abort.disabled = false
	btn_units.disabled = false
	btn_details.disabled = false
	btn_next.visible = false
	_set_status_i18n(
		"quest.radio.c.status.step3",
		"STEP 3/3: compare forecast with intercept window, then choose action.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	if live_mode and is_finite(t_detect):
		risk_label.text = _tr("quest.radio.c.ui.detect_left", "Detection in: {time} s", {
			"time": _format_num(maxf(0.0, t_detect - detection_elapsed))
		})
	else:
		risk_label.text = _tr("quest.radio.c.ui.mode_training", "TRAINING")
	_apply_phantom_preview()
	_update_decision_basis_ui()

func _set_exec_state_ui() -> void:
	state = State.EXEC
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_details.disabled = false
	btn_next.visible = false
	_update_decision_basis_ui()

func _set_done_state_ui() -> void:
	state = State.DONE
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_details.disabled = false
	btn_next.visible = true
	_update_decision_basis_ui()

func _set_knob_interactive(is_enabled: bool) -> void:
	time_knob.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled else Control.MOUSE_FILTER_IGNORE
	btn_minus_1.disabled = not is_enabled
	btn_minus_01.disabled = not is_enabled
	btn_plus_01.disabled = not is_enabled
	btn_plus_1.disabled = not is_enabled

func _on_knob_value_changed(new_value: float, delta: float) -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	_set_estimate(new_value)
	_register_knob_move(delta)

func _on_minus_01_pressed() -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	_apply_estimate_delta(-0.1)

func _on_plus_01_pressed() -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	_apply_estimate_delta(0.1)

func _on_minus_1_pressed() -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	_apply_estimate_delta(-1.0)

func _on_plus_1_pressed() -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	_apply_estimate_delta(1.0)

func _apply_estimate_delta(delta: float) -> void:
	var next_value: float = clampf(t_est + delta, MIN_ESTIMATE, MAX_ESTIMATE)
	if is_equal_approx(next_value, t_est):
		return
	time_knob.call("set_knob_value", next_value, false)
	_set_estimate(next_value)
	_register_knob_move(delta)

func _set_estimate(value_sec: float) -> void:
	t_est = clampf(value_sec, MIN_ESTIMATE, MAX_ESTIMATE)
	estimate_value_label.text = _tr("quest.radio.c.ui.estimate", "t = {value} s", {"value": _format_num(t_est)})
	_apply_phantom_preview()
	_update_decision_basis_ui()
	_update_details_text()

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _register_knob_move(delta: float) -> void:
	if is_zero_approx(delta):
		return
	if knob_moves_count == 0:
		knob_value_at_first_action = t_est
	knob_moves_count += 1
	var sign: int = 1 if delta > 0.0 else -1
	if _last_move_sign != 0 and sign != _last_move_sign:
		direction_changes += 1
	_last_move_sign = sign
	var est_error_abs: float = absf(t_est - t_true)
	peak_estimate_error_abs = maxf(peak_estimate_error_abs, est_error_abs)
	var error_sign: int = 0
	if t_est > t_true + EPS:
		error_sign = 1
	elif t_est < t_true - EPS:
		error_sign = -1
	if _last_estimate_sign_vs_true != 0 and error_sign != 0 and error_sign != _last_estimate_sign_vs_true:
		estimate_cross_count += 1
	if error_sign != 0:
		_last_estimate_sign_vs_true = error_sign
	_log_trial_event("knob_move", {
		"delta": delta,
		"knob_moves_count": knob_moves_count,
		"direction_changes": direction_changes,
		"est_error_abs": est_error_abs,
		"margin_vs_detect": _current_margin_vs_detect()
	})

func _on_analyze_pressed() -> void:
	if state != State.TUNE or analyze_lock_active:
		return
	_register_first_action()
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if now_sec < analyze_cooldown_until:
		var left: float = analyze_cooldown_until - now_sec
		analyze_cooldown_hit_count += 1
		_log_trial_event("analyze_cooldown_blocked", {
			"cooldown_left_sec": left
		})
		_set_status_i18n(
			"quest.radio.c.status.analyze_cooldown",
			"STATUS: ANALYZE available in {left}s.",
			COLOR_SAMPLE_WARN,
			{"left": "%.1f" % left}
		)
		return
	var used_units_before_analyze: bool = used_units
	if estimate_at_first_analyze < 0.0:
		estimate_at_first_analyze = t_est
	estimate_at_last_analyze = t_est
	if used_units_before_analyze:
		analyze_after_units = true
		if analyze_count == 0:
			units_before_analyze = true
	analyze_count += 1
	if check_ms < 0:
		check_ms = Time.get_ticks_msec()
	_log_trial_event("analyze_pressed", {
		"analyze_count": analyze_count,
		"t_est_at_analyze": t_est,
		"margin_vs_detect": _current_margin_vs_detect(),
		"used_units_before_analyze": used_units_before_analyze
	})
	analyze_lock_active = true
	analyze_lock_until = now_sec + _analyze_lock_seconds
	analyze_cooldown_until = now_sec + ANALYZE_COOLDOWN_SECONDS
	if live_mode:
		detection_active = true
		detection_elapsed = 0.0
	_set_analyze_lock_state_ui()
	_update_details_text()

func _on_risk_pressed() -> void:
	if state != State.DECIDE or analyze_lock_active:
		return
	_register_first_action()
	if decision == Decision.RISK:
		return

	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()
	estimate_at_decision = t_est
	remaining_detect_at_decision = _current_detect_value() if (live_mode and is_finite(t_detect)) else INF
	final_margin_vs_detect = (remaining_detect_at_decision - t_est) if (live_mode and is_finite(t_detect)) else INF
	borderline_case = live_mode and is_finite(t_detect) and absf(final_margin_vs_detect) <= _borderline_eps()
	if first_risk_or_abort_ms < 0:
		first_risk_or_abort_ms = _elapsed_trial_ms()
	if estimate_at_last_analyze >= 0.0:
		estimate_delta_after_analyze = estimate_at_decision - estimate_at_last_analyze
	_log_trial_event("risk_pressed", {
		"t_est_at_decision": t_est,
		"remaining_detect": remaining_detect_at_decision,
		"margin_vs_detect": final_margin_vs_detect,
		"borderline_case": borderline_case
	})
	decision = Decision.RISK
	transfer_started = true
	transfer_elapsed = 0.0
	_set_exec_state_ui()
	_set_status_i18n(
		"quest.radio.c.status.exec_started",
		"STATUS: transfer started.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	_update_details_text()

func _on_abort_pressed() -> void:
	if state != State.DECIDE or analyze_lock_active:
		return
	_register_first_action()
	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()
	estimate_at_decision = t_est
	remaining_detect_at_decision = _current_detect_value() if (live_mode and is_finite(t_detect)) else INF
	final_margin_vs_detect = (remaining_detect_at_decision - t_est) if (live_mode and is_finite(t_detect)) else INF
	borderline_case = live_mode and is_finite(t_detect) and absf(final_margin_vs_detect) <= _borderline_eps()
	if first_risk_or_abort_ms < 0:
		first_risk_or_abort_ms = _elapsed_trial_ms()
	if estimate_at_last_analyze >= 0.0:
		estimate_delta_after_analyze = estimate_at_decision - estimate_at_last_analyze
	_log_trial_event("abort_pressed", {
		"t_est_at_decision": t_est,
		"remaining_detect": remaining_detect_at_decision,
		"margin_vs_detect": final_margin_vs_detect,
		"borderline_case": borderline_case
	})
	decision = Decision.ABORT

	var remaining_detect: float = INF if (not live_mode) else maxf(0.0, t_detect - detection_elapsed)
	if t_true > remaining_detect + EPS:
		_finalize_trial(Outcome.SAFE_ABORT, "ABORT")
	else:
		_finalize_trial(Outcome.MISSED_WINDOW, "ABORT")

func _on_units_pressed() -> void:
	if state == State.DONE or state == State.EXEC or analyze_lock_active:
		return
	_register_first_action()
	if first_units_hint_ms < 0:
		first_units_hint_ms = _elapsed_trial_ms()
	if analyze_count == 0:
		units_before_analyze = true
	if decision == Decision.NONE:
		units_before_decision = true
	used_units = true
	_log_trial_event("units_hint_opened", {
		"before_analyze": analyze_count == 0,
		"before_decision": decision == Decision.NONE,
		"t_est": t_est
	})
	_set_status_i18n(
		"quest.radio.c.status.units_hint",
		"Hint: MB -> Mbit = x8, GB -> MB = x1024, then t = I / v.",
		Color(0.55, 0.85, 1.0, 1.0)
	)
	_update_details_text()
	_update_decision_basis_ui()

func _on_details_pressed() -> void:
	if details_overlay.visible:
		return
	details_open_count += 1
	if first_details_open_ms < 0:
		first_details_open_ms = _elapsed_trial_ms()
	if decision == Decision.NONE:
		details_open_before_decision = true
	_log_trial_event("details_opened", {
		"open_count": details_open_count,
		"before_decision": decision == Decision.NONE,
		"state": _state_to_text(state)
	})
	_set_details_visible(true)

func _on_details_close_pressed() -> void:
	if not details_overlay.visible:
		return
	details_close_count += 1
	_log_trial_event("details_closed", {
		"close_count": details_close_count
	})
	_set_details_visible(false)

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if not details_overlay.visible:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			details_dimmer.accept_event()
			_on_details_close_pressed()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			details_dimmer.accept_event()
			_on_details_close_pressed()

func _set_details_visible(is_visible: bool) -> void:
	details_overlay.visible = is_visible

func _on_next_pressed() -> void:
	_start_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _update_runtime_ui() -> void:
	if state == State.TUNE:
		if live_mode and is_finite(t_plan):
			var plan_left: float = maxf(0.0, t_plan - plan_elapsed)
			detection_bar.value = clampf(plan_elapsed / maxf(t_plan, 0.01), 0.0, 1.0) * 100.0
			detect_countdown.text = "%s %s" % [_format_num(plan_left), _tr("quest.radio.common.unit.sec", "s")]
			risk_label.text = _tr("quest.radio.c.status.plan_left", "STATUS: planning budget left {time}s.", {
				"time": _format_num(plan_left)
			})
		else:
			detection_bar.value = 0.0
			detect_countdown.text = _tr("quest.radio.c.ui.waiting", "waiting")
			risk_label.text = _tr("quest.radio.c.ui.mode_training", "TRAINING")
	else:
		var detect_left: float = maxf(0.0, t_detect - detection_elapsed)
		if detection_active and live_mode and is_finite(t_detect):
			detection_bar.value = clampf(detection_elapsed / maxf(t_detect, 0.01), 0.0, 1.0) * 100.0
			detect_countdown.text = "%s %s" % [_format_num(detect_left), _tr("quest.radio.common.unit.sec", "s")]
			if state != State.DONE:
				risk_label.text = _tr("quest.radio.c.ui.detect_left", "Detection in: {time} s", {
					"time": _format_num(detect_left)
				})
		else:
			detection_bar.value = 0.0
			detect_countdown.text = _tr("quest.radio.c.ui.waiting", "waiting")
			if state != State.DONE:
				risk_label.text = _tr("quest.radio.c.ui.mode_training", "TRAINING")

	if decision == Decision.RISK and transfer_started and t_true > 0.0:
		var transfer_ratio: float = clampf(transfer_elapsed / t_true, 0.0, 1.0)
		transfer_bar.value = transfer_ratio * 100.0
		transfer_countdown.text = "%s %s" % [_format_num(maxf(0.0, t_true - transfer_elapsed)), _tr("quest.radio.common.unit.sec", "s")]
	else:
		if state == State.TUNE or state == State.ANALYZE_LOCK or state == State.DECIDE:
			_apply_phantom_preview()
		else:
			transfer_bar.value = 0.0
			transfer_countdown.text = _tr("quest.radio.c.ui.waiting", "waiting")
	_update_decision_basis_ui()

func _apply_phantom_preview() -> void:
	var phantom_ratio: float = clampf(t_est / maxf(_t_true_max, 0.1), 0.0, 1.0)
	transfer_bar.value = phantom_ratio * 100.0
	transfer_countdown.text = _tr("quest.radio.c.ui.estimate_short", "estimate: {value} s", {"value": _format_num(t_est)})

func _update_decision_basis_ui() -> void:
	if compare_line_1 == null or compare_line_2 == null:
		return

	compare_title.text = _tr("quest.radio.c.ui.compare_title", "DECISION BASIS")

	var est_text: String = _format_num(t_est)
	var detect_value_text: String = "--"
	var detect_for_compare: float = INF
	if live_mode and is_finite(t_detect):
		detect_for_compare = t_detect
		if state != State.TUNE:
			detect_for_compare = maxf(0.0, t_detect - detection_elapsed)
		detect_value_text = _format_num(detect_for_compare)

	if state == State.TUNE or state == State.ANALYZE_LOCK or state == State.DECIDE:
		transfer_title.text = _tr("quest.radio.c.ui.transfer_estimated_title", "ESTIMATED TRANSFER")
	else:
		transfer_title.text = _tr("quest.radio.c.ui.transfer_actual_title", "TRANSFER")

	match state:
		State.TUNE:
			compare_line_1.text = _tr("quest.radio.c.ui.compare_tune", "Estimate: t_est = {est} s | Intercept window: {detect} s", {
				"est": est_text,
				"detect": detect_value_text
			})
			compare_line_2.text = _tr(
				"quest.radio.c.details.compare_now",
				"This is only a forecast. After ANALYZE, compare it against the intercept window."
			)
		State.ANALYZE_LOCK:
			compare_line_1.text = _tr("quest.radio.c.ui.compare_lock", "Forecast locked: t_est = {est} s", {"est": est_text})
			compare_line_2.text = _tr(
				"quest.radio.c.details.compare_now",
				"Channel scan in progress. Decision basis is being prepared."
			)
		State.DECIDE:
			compare_line_1.text = _tr("quest.radio.c.ui.compare_tune", "Estimate: t_est = {est} s | Intercept window: {detect} s", {
				"est": est_text,
				"detect": detect_value_text
			})
			if not (live_mode and is_finite(t_detect)):
				compare_line_2.text = _tr(
					"quest.radio.c.details.compare_now",
					"Training mode: use the estimate and choose the action with best justification."
				)
			else:
				var diff: float = t_est - detect_for_compare
				if absf(diff) <= EPS:
					compare_line_2.text = _tr("quest.radio.c.ui.compare_border", "Borderline case: high risk, compare very carefully.")
				elif diff < -EPS:
					compare_line_2.text = _tr("quest.radio.c.ui.compare_fit", "By current forecast, transfer fits the intercept window.")
				else:
					compare_line_2.text = _tr("quest.radio.c.ui.compare_exceed", "By current forecast, transfer does not fit the intercept window.")
		State.EXEC:
			if decision == Decision.RISK:
				compare_line_1.text = _tr("quest.radio.c.ui.compare_exec_risk", "Decision made: transmission started.")
			else:
				compare_line_1.text = _tr("quest.radio.c.ui.compare_exec_abort", "Decision made: transmission cancelled.")
			compare_line_2.text = _tr("quest.radio.c.ui.compare_lock", "Runtime in progress.")
		State.DONE:
			compare_line_1.text = _tr("quest.radio.c.ui.compare_done", "Result recorded.")
			compare_line_2.text = _tr("quest.radio.c.details.after_finish", "Detailed analysis is available in DETAILS.")

func _finalize_trial(result: Outcome, decision_label: String) -> void:
	if state == State.DONE:
		return

	outcome = result
	if estimate_at_decision < 0.0:
		estimate_at_decision = t_est
	if live_mode and is_finite(t_detect):
		if not is_finite(remaining_detect_at_decision):
			remaining_detect_at_decision = _current_detect_value()
		if not is_finite(final_margin_vs_detect):
			final_margin_vs_detect = remaining_detect_at_decision - estimate_at_decision
		borderline_case = borderline_case or (absf(final_margin_vs_detect) <= _borderline_eps())
	if estimate_at_last_analyze >= 0.0:
		estimate_delta_after_analyze = estimate_at_decision - estimate_at_last_analyze
	else:
		estimate_delta_after_analyze = 0.0
	_set_done_state_ui()

	var is_success: bool = (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)
	var low_certainty: bool = (knob_moves_count >= 6 or direction_changes >= 2)
	var valid_for_mastery: bool = (not used_units) and (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)
	if _plan_timeout_triggered or decision_label == "TIMEOUT":
		decision_quality = "no_decision"
	elif decision == Decision.NONE:
		decision_quality = "no_decision"
	elif decision == Decision.RISK:
		if outcome == Outcome.SUCCESS_SEND:
			decision_quality = "borderline_risk" if borderline_case else "safe_risk"
		else:
			decision_quality = "bad_risk"
	elif decision == Decision.ABORT:
		if outcome == Outcome.SAFE_ABORT:
			decision_quality = "safe_abort"
		elif outcome == Outcome.MISSED_WINDOW:
			decision_quality = "missed_opportunity"
		else:
			decision_quality = "no_decision"
	else:
		decision_quality = "unknown"

	if valid_for_mastery:
		mastery_block_reason = "NONE"
	elif _plan_timeout_triggered:
		mastery_block_reason = "TIMEOUT"
	elif decision == Decision.NONE:
		mastery_block_reason = "NONE_DECISION"
	elif used_units:
		mastery_block_reason = "USED_UNITS"
	elif low_certainty:
		mastery_block_reason = "LOW_CERTAINTY"
	elif borderline_case:
		mastery_block_reason = "BORDERLINE_GUESS"
	elif outcome == Outcome.INTERCEPTED:
		mastery_block_reason = "INTERCEPTED"
	elif outcome == Outcome.MISSED_WINDOW:
		mastery_block_reason = "MISSED_WINDOW"
	else:
		mastery_block_reason = "NONE_DECISION"

	var sample_color: Color = COLOR_SAMPLE_FAIL
	var status_color: Color = COLOR_SAMPLE_FAIL
	match outcome:
		Outcome.SUCCESS_SEND:
			_set_status_i18n(
				"quest.radio.c.result.success",
				"STATUS: SUCCESS. Packet sent before interception.",
				COLOR_SAMPLE_SUCCESS
			)
			sample_color = COLOR_SAMPLE_SUCCESS
			status_color = COLOR_SAMPLE_SUCCESS
		Outcome.INTERCEPTED:
			if _plan_timeout_triggered:
				_set_status_i18n(
					"quest.radio.c.result.plan_timeout",
					"STATUS: failed. Planning time expired before ANALYZE.",
					COLOR_SAMPLE_FAIL
				)
			elif decision == Decision.RISK:
				if t_true > t_detect + EPS:
					_set_status_i18n(
						"quest.radio.c.risk_fail_time",
						"DECISION ERROR! Calc: {calc}s. Intercept in: {limit}s. Not enough time!",
						COLOR_SAMPLE_FAIL,
						{"calc": "%.1f" % t_true, "limit": "%.1f" % t_detect}
					)
				else:
					_set_status_i18n(
						"quest.radio.c.risk_fail_math",
						"MATH ERROR! MB to Mbps conversion or division mistake.",
						COLOR_SAMPLE_FAIL
					)
			else:
				_set_status_i18n(
					"quest.radio.c.result.intercept",
					"STATUS: FAILED. You were intercepted.",
					COLOR_SAMPLE_FAIL
				)
			sample_color = COLOR_SAMPLE_FAIL
			status_color = COLOR_SAMPLE_FAIL
		Outcome.SAFE_ABORT:
			_set_status_i18n(
				"quest.radio.c.abort_success",
				"STATUS: SUCCESS. Good risk assessment, transfer was impossible.",
				COLOR_SAMPLE_SUCCESS
			)
			sample_color = COLOR_SAMPLE_SUCCESS
			status_color = COLOR_SAMPLE_SUCCESS
		Outcome.MISSED_WINDOW:
			_set_status_i18n(
				"quest.radio.c.result.missed",
				"STATUS: MISSED. You could have made it.",
				COLOR_SAMPLE_WARN
			)
			sample_color = COLOR_SAMPLE_WARN
			status_color = COLOR_SAMPLE_WARN
		_:
			_set_status_i18n("quest.radio.c.status.completed", "STATUS: completed", COLOR_SAMPLE_FAIL)
			sample_color = COLOR_SAMPLE_FAIL
			status_color = COLOR_SAMPLE_FAIL
	_status_i18n_color = status_color
	_apply_status_i18n()

	_update_sample_slot(sample_color)
	_log_trial_event("trial_finished", {
		"decision_label": decision_label,
		"decision_quality": decision_quality,
		"outcome": _outcome_to_text(outcome),
		"is_success": is_success,
		"mastery_block_reason": mastery_block_reason,
		"borderline_case": borderline_case
	})
	_send_trial_payload(is_success, decision_label)
	_update_decision_basis_ui()
	_update_details_text()

func _update_sample_slot(color: Color) -> void:
	if sample_refs.is_empty():
		return
	var slot: Dictionary = sample_refs[sample_cursor] as Dictionary
	var bg: ColorRect = slot["bg"] as ColorRect
	var mark: Label = slot["mark"] as Label
	bg.color = color
	mark.visible = (pool_type == "ANCHOR")
	sample_cursor = (sample_cursor + 1) % min(SAMPLE_SLOTS, sample_refs.size())

func _send_trial_payload(is_success: bool, decision_label: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - start_ms
	var time_to_first_action_ms: int = 0
	if first_action_ms >= 0:
		time_to_first_action_ms = first_action_ms - start_ms

	var time_to_check_ms: int = 0
	if check_ms >= 0:
		time_to_check_ms = check_ms - start_ms

	var time_to_decision_ms: int = elapsed_ms
	if decision_ms >= 0:
		time_to_decision_ms = decision_ms - start_ms
	var time_analyze_to_decision_ms: int = -1
	if check_ms >= 0 and decision_ms >= 0:
		time_analyze_to_decision_ms = maxi(0, time_to_decision_ms - time_to_check_ms)
	var time_to_units_hint_ms: int = first_units_hint_ms
	var time_to_details_open_ms: int = first_details_open_ms
	var time_to_first_risk_or_abort_ms: int = first_risk_or_abort_ms

	var error_abs: float = absf(t_est - t_true)
	var error_rel: float = 0.0
	if t_true > 0.0:
		error_rel = error_abs / t_true

	var low_certainty: bool = (knob_moves_count >= 6 or direction_changes >= 2)
	var error_type: String = _classify_error_type(time_to_decision_ms)
	var valid_for_mastery: bool = (not used_units) and (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)
	var detect_at_decision: float = remaining_detect_at_decision
	if live_mode and is_finite(t_detect) and not is_finite(detect_at_decision):
		detect_at_decision = _current_detect_value()

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "C",
		"mode": "ARCADE" if ARCADE_MODE_ENABLED else "DIAGNOSTIC",
		"match_key": _build_match_key(),
		"trial_seq": trial_seq,
		"pool_type": pool_type,
		"anchor_type": anchor_type,
		"anchor": (pool_type == "ANCHOR"),
		"file_size_value": file_size_value,
		"file_size_unit": file_size_unit,
		"speed_mbit": speed_mbit,
		"t_detect": t_detect,
		"t_true": t_true,
		"t_est": t_est,
		"estimate_sec": t_est,
		"true_sec": t_true,
		"error_sec_abs": error_abs,
		"error_sec_rel": error_rel,
		"peak_estimate_error_abs": peak_estimate_error_abs,
		"estimate_cross_count": estimate_cross_count,
		"decision": decision_label,
		"outcome": _outcome_to_text(outcome),
		"decision_quality": decision_quality,
		"mastery_block_reason": mastery_block_reason,
		"used_units": used_units,
		"units_before_analyze": units_before_analyze,
		"units_before_decision": units_before_decision,
		"analyze_after_units": analyze_after_units,
		"details_open_count": details_open_count,
		"details_open_before_decision": details_open_before_decision,
		"details_close_count": details_close_count,
		"error_type": error_type,
		"knob_moves_count": knob_moves_count,
		"knob_value_at_first_action": knob_value_at_first_action,
		"direction_changes": direction_changes,
		"analyze_count": analyze_count,
		"analyze_cooldown_hit_count": analyze_cooldown_hit_count,
		"low_certainty": low_certainty,
		"borderline_case": borderline_case,
		"plan_timeout_triggered": _plan_timeout_triggered,
		"estimate_at_first_analyze": estimate_at_first_analyze,
		"estimate_at_last_analyze": estimate_at_last_analyze,
		"estimate_at_decision": estimate_at_decision,
		"estimate_delta_after_analyze": estimate_delta_after_analyze,
		"remaining_detect_at_decision": detect_at_decision,
		"first_margin_vs_detect": first_margin_vs_detect,
		"final_margin_vs_detect": final_margin_vs_detect,
		"true_margin_vs_detect": true_margin_vs_detect,
		"valid_for_diagnostics": true,
		"valid_for_mastery": valid_for_mastery,
		"is_correct": is_success,
		"is_fit": is_success,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": time_to_first_action_ms,
		"time_to_check_ms": time_to_check_ms,
		"time_to_analyze_ms": time_to_check_ms,
		"time_to_decision_ms": time_to_decision_ms,
		"time_analyze_to_decision_ms": time_analyze_to_decision_ms,
		"time_to_units_hint_ms": time_to_units_hint_ms,
		"time_to_details_open_ms": time_to_details_open_ms,
		"time_to_first_risk_or_abort_ms": time_to_first_risk_or_abort_ms,
		"event_log": trial_event_log.duplicate(true)
	}
	var stab_delta: float = 0.0
	match outcome:
		Outcome.INTERCEPTED:
			stab_delta = -25.0
		Outcome.MISSED_WINDOW:
			stab_delta = -15.0
		Outcome.SAFE_ABORT:
			stab_delta = -5.0
		Outcome.SUCCESS_SEND:
			stab_delta = 0.0
	payload["stability_delta"] = stab_delta
	GlobalMetrics.register_trial(payload)

func _classify_error_type(time_to_decision_ms: int) -> String:
	if used_units:
		return "assisted"
	if t_true <= 0.0:
		return "arithmetic_error"

	var rel_x8: float = absf((t_est * 8.0) - t_true) / t_true
	if rel_x8 < 0.15:
		return "forgot_x8"

	if file_size_unit == UNIT_GB:
		var rel_x1024: float = absf((t_est * 1024.0) - t_true) / t_true
		if rel_x1024 < 0.15:
			return "forgot_x1024"

	var rel_error: float = absf(t_est - t_true) / t_true
	if rel_error > 0.25:
		return "arithmetic_error"
	if time_to_decision_ms > 15000:
		return "hesitation"
	return "none"

func _build_match_key() -> String:
	var unit_token: String = "MB"
	if file_size_unit == UNIT_GB:
		unit_token = "GB"
	return "RI_C_%s%s_v%s_T%s_%s" % [
		unit_token,
		_format_key_num(file_size_value),
		_format_key_num(speed_mbit),
		_format_key_num(t_detect),
		pool_type
	]

func _outcome_to_text(current_outcome: Outcome) -> String:
	match current_outcome:
		Outcome.SUCCESS_SEND:
			return "SUCCESS_SEND"
		Outcome.INTERCEPTED:
			return "INTERCEPTED"
		Outcome.SAFE_ABORT:
			return "SAFE_ABORT"
		Outcome.MISSED_WINDOW:
			return "MISSED_WINDOW"
		_:
			return "NONE"

func _update_details_text() -> void:
	var lines: Array[String] = []
	if state != State.DONE:
		lines.append(_tr("quest.radio.c.details.formula", "Formula: t = I / v"))
		lines.append(_tr("quest.radio.c.details.given", "Given: size {size} {unit}, speed {speed} {speed_unit}", {
			"size": _format_num(file_size_value),
			"unit": file_size_unit,
			"speed": _format_num(speed_mbit),
			"speed_unit": _tr("quest.radio.common.unit.mbps", "Mbps")
		}))
		lines.append(_tr("quest.radio.c.details.estimate", "Your estimate: t_est = {time} s", {"time": _format_num(t_est)}))
		if live_mode and is_finite(t_detect):
			lines.append(_tr("quest.radio.c.details.detect", "Intercept in: {time} s", {"time": _format_num(t_detect)}))
		lines.append(_tr(
			"quest.radio.c.details.route",
			"Route: 1) Estimate t  2) Press ANALYZE  3) Compare with intercept window  4) Choose RISK or ABORT"
		))
		if state == State.DECIDE:
			lines.append(_tr(
				"quest.radio.c.details.compare_now",
				"Compare now: use your current estimate and the intercept window before choosing action."
			))
		if used_units:
			lines.append(_tr("quest.radio.c.details.used_units", "Units hint used."))
		details_sheet_text.text = "\n".join(lines)
		return

	var size_mb: float = file_size_value if file_size_unit == UNIT_MB else file_size_value * 1024.0
	var i_mbit: float = size_mb * 8.0
	lines.append(_tr("quest.radio.c.details.formula", "Formula: t = I / v"))
	lines.append(_tr("quest.radio.c.details.given", "Given: size {size} {unit}, speed {speed} {speed_unit}", {
		"size": _format_num(file_size_value),
		"unit": file_size_unit,
		"speed": _format_num(speed_mbit),
		"speed_unit": _tr("quest.radio.common.unit.mbps", "Mbps")
	}))
	if file_size_unit == UNIT_GB:
		lines.append(_tr("quest.radio.c.details.conv_gb", "Conversion: {gb} GB x 1024 = {mb} MB", {
			"gb": _format_num(file_size_value),
			"mb": _format_num(size_mb)
		}))
	lines.append(_tr("quest.radio.c.details.conv_mb", "Conversion: {mb} MB x 8 = {mbit} Mbit", {
		"mb": _format_num(size_mb),
		"mbit": _format_num(i_mbit)
	}))
	lines.append(_tr("quest.radio.c.details.t_true", "t_true = {i} / {v} = {t} s", {
		"i": _format_num(i_mbit),
		"v": _format_num(speed_mbit),
		"t": _format_num(t_true)
	}))
	lines.append(_tr("quest.radio.c.details.estimate", "Your estimate: t_est = {time} s", {"time": _format_num(t_est)}))
	var decision_text: String = _tr("quest.radio.c.details.decision_none", "NO DECISION")
	if decision == Decision.RISK:
		decision_text = _tr("quest.radio.c.details.decision_risk", "RISK")
	elif decision == Decision.ABORT:
		decision_text = _tr("quest.radio.c.details.decision_abort", "ABORT")
	lines.append(_tr("quest.radio.c.details.decision", "Decision: {decision}", {"decision": decision_text}))
	lines.append(_tr("quest.radio.c.details.outcome", "Outcome: {outcome}", {"outcome": _outcome_to_text(outcome)}))
	var decision_elapsed_ms: int = (Time.get_ticks_msec() - start_ms) if decision_ms < 0 else (decision_ms - start_ms)
	lines.append(_tr("quest.radio.c.details.analysis", "Analysis: {text}", {
		"text": _describe_error_type(_classify_error_type(decision_elapsed_ms))
	}))
	details_sheet_text.text = "\n".join(lines)

func _describe_error_type(error_type: String) -> String:
	match error_type:
		"forgot_x8":
			return _tr("quest.radio.c.error.forgot_x8", "Forgot x8 when converting MB to Mbit.")
		"forgot_x1024":
			return _tr("quest.radio.c.error.forgot_x1024", "Forgot x1024 when converting GB to MB.")
		"arithmetic_error":
			return _tr("quest.radio.c.error.arithmetic", "Transfer-time calculation error.")
		"hesitation":
			return _tr("quest.radio.c.error.hesitation", "Hesitation: decision was too late.")
		"assisted":
			return _tr("quest.radio.c.error.assisted", "Units hint was used.")
		_:
			return _tr("quest.radio.c.error.none", "No critical calculation errors detected.")

func _format_num(value: float) -> String:
	return "%.1f" % value

func _format_key_num(value: float) -> String:
	var text_value: String = "%.2f" % value
	while text_value.ends_with("0"):
		text_value = text_value.substr(0, text_value.length() - 1)
	if text_value.ends_with("."):
		text_value = text_value.substr(0, text_value.length() - 1)
	return text_value

func _play_alarm_flash() -> void:
	alarm_flash.color = Color(1.0, 0.05, 0.05, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(alarm_flash, "color:a", 0.35, 0.10)
	tw.tween_property(alarm_flash, "color:a", 0.0, 0.24)

func _load_level_config() -> void:
	_pool_mb_normal = _to_float_array(
		RadioLevels.get_pool("C", "size_pool_mb", FALLBACK_POOL_MB_NORMAL),
		FALLBACK_POOL_MB_NORMAL
	)
	_pool_gb_normal = _to_float_array(
		RadioLevels.get_pool("C", "size_pool_gb", FALLBACK_POOL_GB_NORMAL),
		FALLBACK_POOL_GB_NORMAL
	)
	_pool_speed_int = _to_float_array(
		RadioLevels.get_pool("C", "speed_pool_int", FALLBACK_POOL_SPEED_INT),
		FALLBACK_POOL_SPEED_INT
	)
	_pool_speed_frac = _to_float_array(
		RadioLevels.get_pool("C", "speed_pool_frac", FALLBACK_POOL_SPEED_FRAC),
		FALLBACK_POOL_SPEED_FRAC
	)
	_t_true_min = float(RadioLevels.get_value("C", "t_true_min", 2.0))
	_t_true_max = float(RadioLevels.get_value("C", "t_true_max", 20.0))
	if _t_true_min < 0.5:
		_t_true_min = 2.0
	if _t_true_max <= _t_true_min:
		_t_true_max = _t_true_min + 10.0

	_anchor_every_min = int(RadioLevels.get_value("C", "anchor_every_min", 7))
	_anchor_every_max = int(RadioLevels.get_value("C", "anchor_every_max", 10))
	if _anchor_every_min <= 0:
		_anchor_every_min = 7
	if _anchor_every_max < _anchor_every_min:
		_anchor_every_max = _anchor_every_min

	live_mode = bool(RadioLevels.get_value("C", "live_mode", true))
	_plan_budget_normal = float(RadioLevels.get_value("C", "plan_budget_normal", DEFAULT_PLAN_BUDGET_NORMAL))
	_plan_budget_anchor = float(RadioLevels.get_value("C", "plan_budget_anchor", DEFAULT_PLAN_BUDGET_ANCHOR))
	_analyze_lock_seconds = float(RadioLevels.get_value("C", "analyze_lock_sec", ANALYZE_LOCK_DEFAULT))
	_detect_min_sec = float(RadioLevels.get_value("C", "detect_min_sec", DEFAULT_DETECT_MIN))
	_detect_max_sec = float(RadioLevels.get_value("C", "detect_max_sec", DEFAULT_DETECT_MAX))
	_detect_margin_int = float(RadioLevels.get_value("C", "detect_margin_int_sec", DEFAULT_DETECT_MARGIN_INT))
	_detect_margin_frac = float(RadioLevels.get_value("C", "detect_margin_frac_sec", DEFAULT_DETECT_MARGIN_FRAC))
	_anchor_detect_min = float(RadioLevels.get_value("C", "anchor_detect_min_sec", DEFAULT_ANCHOR_DETECT_MIN))
	_anchor_detect_max = float(RadioLevels.get_value("C", "anchor_detect_max_sec", DEFAULT_ANCHOR_DETECT_MAX))
	_boundary_offset_min = float(RadioLevels.get_value("C", "boundary_offset_min_sec", DEFAULT_BOUNDARY_OFFSET_MIN))
	_boundary_offset_max = float(RadioLevels.get_value("C", "boundary_offset_max_sec", DEFAULT_BOUNDARY_OFFSET_MAX))

	if _plan_budget_normal <= 0.0:
		_plan_budget_normal = DEFAULT_PLAN_BUDGET_NORMAL
	if _plan_budget_anchor <= 0.0:
		_plan_budget_anchor = DEFAULT_PLAN_BUDGET_ANCHOR
	if _analyze_lock_seconds <= 0.0:
		_analyze_lock_seconds = ANALYZE_LOCK_DEFAULT
	if _detect_min_sec < 1.0:
		_detect_min_sec = DEFAULT_DETECT_MIN
	if _detect_max_sec <= _detect_min_sec:
		_detect_max_sec = _detect_min_sec + 6.0
	if _detect_margin_int < 0.1:
		_detect_margin_int = DEFAULT_DETECT_MARGIN_INT
	if _detect_margin_frac < 0.1:
		_detect_margin_frac = DEFAULT_DETECT_MARGIN_FRAC
	if _anchor_detect_min < 1.0:
		_anchor_detect_min = DEFAULT_ANCHOR_DETECT_MIN
	if _anchor_detect_max <= _anchor_detect_min:
		_anchor_detect_max = _anchor_detect_min + 2.0
	if _boundary_offset_min < 0.01:
		_boundary_offset_min = DEFAULT_BOUNDARY_OFFSET_MIN
	if _boundary_offset_max < _boundary_offset_min:
		_boundary_offset_max = _boundary_offset_min

func _to_float_array(raw: Array, fallback: Array[float]) -> Array[float]:
	var result: Array[float] = []
	for value_var in raw:
		var typed: Variant = value_var
		match typeof(typed):
			TYPE_INT, TYPE_FLOAT:
				result.append(float(typed))
			TYPE_STRING:
				var text: String = String(typed).strip_edges()
				if text.is_valid_float():
					result.append(text.to_float())
	if result.is_empty():
		result.append_array(fallback)
	return result

func _random_anchor_gap() -> int:
	return randi_range(_anchor_every_min, _anchor_every_max)

func _pick_from_float_pool(pool: Array[float], fallback_value: float) -> float:
	if pool.is_empty():
		return fallback_value
	return pool[randi() % pool.size()]

func _on_stability_changed(new_value: float, _change: float) -> void:
	stability_label.text = _tr("quest.radio.c.ui.stability", "STABILITY: {v}%", {"v": int(new_value)})
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", new_value)
