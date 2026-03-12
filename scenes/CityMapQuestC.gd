extends Control

const PACK_PATH := "res://data/city_map/pack_6_3_C.json"
const LOG_PREFIX := "case_6_3"
const DEFAULT_ACCENT := Color(0.40, 0.72, 1.0, 1.0)
const ARROW_ANGLE_RAD := 0.52
const ARROW_LEN := 16.0
const AUTO_FIT_MARGIN_PX := 24.0
const TRAFFIC_BASE_SPEED := 2.4
const PHASE_BUILD := 1
const PHASE_RULES := 2
const PHASE_INPUT := 3
const PHASE_REVIEW := 4

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var content_split: BoxContainer = $SafeArea/MainVBox/ContentSplit
@onready var graph_panel: PanelContainer = $SafeArea/MainVBox/ContentSplit/GraphPanel
@onready var info_panel: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel
@onready var graph_container: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer
@onready var edges_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/EdgesLayer
@onready var nodes_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/NodesLayer
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var label_case: Label = $SafeArea/MainVBox/Header/LabelCase
@onready var label_mode: Label = $SafeArea/MainVBox/Header/LabelMode
@onready var label_progress: Label = $SafeArea/MainVBox/Header/LabelProgress
@onready var btn_reset: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ActionCard/ActionMargin/ButtonsRow/BtnReset
@onready var btn_submit: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ActionCard/ActionMargin/ButtonsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ReviewCard/ReviewMargin/ReviewVBox/BtnNext
@onready var buttons_row: HBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ActionCard/ActionMargin/ButtonsRow
@onready var info_vbox: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox
@onready var sum_input: LineEdit = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/InputCard/InputMargin/InputVBox/SumInput
@onready var path_display: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/RouteCard/RouteMargin/RouteVBox/PathDisplay
@onready var sim_time_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/RouteCard/RouteMargin/RouteVBox/SimTimeLabel
@onready var sum_live_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/RouteCard/RouteMargin/RouteVBox/SumLiveLabel
@onready var constraint_info_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ObjectiveCard/ObjectiveMargin/ObjectiveVBox/ConstraintInfoLabel
@onready var warning_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ObjectiveCard/ObjectiveMargin/ObjectiveVBox/WarningLabel
@onready var input_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/InputCard/InputMargin/InputVBox/InputLabel
@onready var status_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ObjectiveCard/ObjectiveMargin/ObjectiveVBox/StatusLabel
@onready var schedule_list: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleScroll/ScheduleList
@onready var schedule_panel: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ScheduleCard
@onready var schedule_title: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleTitle
@onready var schedule_summary_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleSummaryLabel
@onready var schedule_scroll: ScrollContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ScheduleCard/ScheduleMargin/ScheduleVBox/ScheduleScroll
@onready var phase_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/PhaseCard
@onready var phase_vbox: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/PhaseCard/PhaseMargin/PhaseVBox
@onready var objective_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ObjectiveCard
@onready var route_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/RouteCard
@onready var action_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ActionCard
@onready var input_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/InputCard
@onready var input_vbox: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/InputCard/InputMargin/InputVBox
@onready var review_card: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ReviewCard
@onready var review_vbox: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ReviewCard/ReviewMargin/ReviewVBox
@onready var label_state: Label = $SafeArea/MainVBox/Header/LabelState
@onready var label_timer: Label = $SafeArea/MainVBox/Header/LabelTimer
@onready var footer_row: HBoxContainer = $SafeArea/MainVBox/Footer
@onready var footer_label: Label = $SafeArea/MainVBox/Footer/FooterLabel
@onready var footer_meta: Label = $SafeArea/MainVBox/Footer/FooterMeta
@onready var briefing_card: PanelContainer = $SafeArea/MainVBox/BriefingCard
@onready var briefing_title: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingTitle
@onready var briefing_text: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingText
@onready var briefing_constraint: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/ConstraintLabel

var level_data: Dictionary = {}
var pack_data: Dictionary = {}
var pack_levels: Array = []
var node_defs: Dictionary = {}
var adjacency: Dictionary = {}
var edge_visuals: Dictionary = {}
var node_buttons: Dictionary = {}
var config_hash: String = ""
var input_regex := RegEx.new()
var pack_id: String = "CITY_MAP_C_PACK_01"
var level_index: int = 0
var level_total: int = 0
var run_id: String = ""
var run_started_unix: int = 0
var attempt_in_sublevel: int = 0
var attempt_in_run: int = 0
var levels_completed: int = 0
var levels_perfect: int = 0
var run_total_time_seconds: int = 0
var run_total_calc_errors: int = 0
var run_total_opt_errors: int = 0
var run_total_parse_errors: int = 0
var run_total_reset_errors: int = 0
var run_total_transit_errors: int = 0
var run_total_logic_errors: int = 0
var run_total_closed_errors: int = 0
var run_total_ambush_hits: int = 0

var min_sum: int = 0
var accent_color: Color = DEFAULT_ACCENT
var node_radius_px: float = 25.0
var node_hit_target_px: float = 48.0
var must_visit_nodes: Array[String] = []
var blacklist_nodes: Array[String] = []
var xor_groups: Array = []

var current_node: String = ""
var path: Array[String] = []
var path_sum: int = 0
var step_weights: Array[int] = []
var stability: float = 100.0
var real_time_sec: int = 0
var sim_time_sec: int = 0
var is_game_over: bool = false
var stage_completed: bool = false
var input_locked: bool = false
var _route_committed_for_input: bool = false
var first_attempt_edge: String = ""
var level_started_ms: int = 0
var first_action_ms: int = -1
var planning_time_ms: int = 0
var round_phase: int = PHASE_BUILD
var phase_time_ms: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0}

var trial_seq: int = 0
var task_session: Dictionary = {}

var node_select_count: int = 0
var edge_step_count: int = 0
var submit_attempt_count: int = 0
var wait_action_count: int = 0
var reset_count_local: int = 0
var undo_count_local: int = 0

var closed_edge_attempt_count: int = 0
var danger_edge_count_local: int = 0
var blacklist_violation_count: int = 0
var xor_violation_count: int = 0
var dynamic_replan_count: int = 0

var timeline_step_count: int = 0
var changed_after_warning: bool = false
var changed_after_review: bool = false

var time_to_first_step_ms: int = -1
var time_to_first_submit_ms: int = -1
var time_to_first_wait_ms: int = -1
var time_from_last_edit_to_submit_ms: int = -1
var last_edit_ms: int = -1

var backtrack_count: int = 0
var cycle_events: int = 0
var cycle_detected: bool = false
var constraint_violations: int = 0
var closed_edge_attempts: int = 0
var ambush_hits: int = 0
var xor_violation: bool = false
var dynamic_weight_awareness: bool = true

var n_calc: int = 0
var n_opt: int = 0
var n_parse: int = 0
var n_reset: int = 0
var n_transit: int = 0
var n_logic: int = 0
var n_closed: int = 0
var undo_count: int = 0
var numpad_input_count: int = 0
var backspace_count: int = 0
var dossier_open_count: int = 0
var time_dossier_open_ms: int = 0
var wait_count: int = 0
var wait_total_sim_sec: int = 0
var schedule_panel_open_count: int = 0
var think_time_before_move_ms: Array[int] = []

var _last_move_ms: int = 0
var _dossier_open_started_ms: int = -1
var _jitter_map: Dictionary = {}
var _node_positions: Dictionary = {}
var _traffic_visuals: Dictionary = {}
var _undo_stack: Array[Dictionary] = []
var _node_badges: Dictionary = {}
var _renderer = preload("res://scripts/city_map/GraphRenderer.gd").new()

var _traffic_layer: Control
var _btn_help: Button
var _btn_undo: Button
var _btn_wait: Button
var _numpad_panel: PanelContainer
var _numpad_grid: GridContainer
var _info_scroll: ScrollContainer
var _numpad_buttons: Array[Button] = []
var _traffic_shader: Shader
var _traffic_texture: Texture2D
var _closed_texture: Texture2D
var _schedule_rows: Array[Dictionary] = []
var _danger_edges_seen: Dictionary = {}
var _closed_edges_seen: Dictionary = {}
var _warning_active: bool = false
var _last_warning_text: String = ""
var _is_leaving_scene := false
var _status_i18n_key: String = ""
var _status_i18n_default: String = ""
var _status_i18n_params: Dictionary = {}
var _status_i18n_color: Color = Color(1, 1, 1, 1)
var _phase_started_ms: int = 0
var _hint_count: int = 0
var _last_reveal: Dictionary = {}
var _last_review_had_hint: bool = false
var _suppress_sum_input_telemetry: bool = false
var _analytics_schema_version: String = "city_map.v3.0.0"
var _last_step_cost: int = 0
var _review_phase_active: bool = false
var _status_override_until_ms: int = 0
var _phase_label: Label
var _reveal_label: Label
var _btn_schedule_toggle: Button
var _schedule_collapsed: bool = true
var _solver = preload("res://scripts/city_map/GraphSolver.gd").new()
var _pack_summary_ready: bool = false
var _pack_summary_data: Dictionary = {}

func _ready() -> void:
	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if not btn_back.button_down.is_connected(_on_back_button_down):
		btn_back.button_down.connect(_on_back_button_down)
	if not btn_back.gui_input.is_connected(_on_back_gui_input):
		btn_back.gui_input.connect(_on_back_gui_input)
	btn_back.disabled = false
	btn_back.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_back.focus_mode = Control.FOCUS_ALL
	btn_back.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	set_process_input(true)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	sum_input.text_changed.connect(_on_sum_input_changed)
	graph_container.resized.connect(_on_graph_resized)
	_setup_noir_ui()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()
	_configure_sum_input_display()

	_load_pack(PACK_PATH)
	_apply_content_layout_mode()
	_setup_timer()
	call_deferred("_start_pack_run")

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var opts: Dictionary = params.duplicate(true)
	opts["default"] = default_text
	return I18n.tr_key(key, opts)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	label_case.text = _tr("city_map.common.header.case", "CASE 6: CITY MAP")
	label_mode.text = _tr("city_map.c.header.mode", "MODE: C")
	if is_instance_valid(_btn_help):
		_btn_help.tooltip_text = _tr("city_map.common.tooltip.dossier", "DOSSIER")
	if is_instance_valid(_btn_undo):
		_btn_undo.text = _tr("city_map.common.btn.undo_step", "UNDO STEP")
	if is_instance_valid(_btn_wait):
		_btn_wait.text = _tr("city_map.c.btn.wait", "WAIT +5")
	if is_instance_valid(_btn_schedule_toggle):
		_btn_schedule_toggle.text = _tr(
			"city_map.c.schedule.toggle_context",
			"Schedule: context only"
		) if _schedule_collapsed else _tr("city_map.c.schedule.toggle_all", "Schedule: show all")
	btn_reset.text = _tr("city_map.common.btn.reset_route", "RESET ROUTE")
	btn_submit.text = _submit_button_text()
	input_label.text = _tr("city_map.common.input.enter_sum", "ENTER FINAL SUM")
	schedule_title.text = _tr("city_map.c.schedule.title", "SCHEDULE")
	schedule_summary_label.text = _tr("city_map.c.schedule.summary.idle", "Schedule: no relevant changes right now")
	footer_meta.text = _tr("city_map.c.footer.meta", "CITY MAP / C")
	_set_progress_ui()
	_set_briefing()
	_update_visuals()
	_update_timer_display()
	if is_instance_valid(_phase_label):
		_phase_label.text = _phase_text()
	if not _status_i18n_key.is_empty():
		_set_status_i18n(_status_i18n_key, _status_i18n_default, _status_i18n_color, _status_i18n_params)
	_apply_content_layout_mode()

func _set_status_i18n(key: String, default_text: String, color: Color, params: Dictionary = {}) -> void:
	_status_i18n_key = key
	_status_i18n_default = default_text
	_status_i18n_params = params.duplicate(true)
	_status_i18n_color = color
	status_label.text = _tr(key, default_text, _status_i18n_params)
	status_label.add_theme_color_override("font_color", color)

func _clear_status_i18n() -> void:
	_status_i18n_key = ""
	_status_i18n_default = ""
	_status_i18n_params = {}
	status_label.text = ""

func _setup_noir_ui() -> void:
	_ensure_info_scroll_container()
	_configure_info_text_wrapping()

	_btn_help = Button.new()
	_btn_help.text = "?"
	_btn_help.custom_minimum_size = Vector2(44, 44)
	_btn_help.tooltip_text = "DOSSIER"
	_btn_help.pressed.connect(_on_help_pressed)
	header.add_child(_btn_help)

	_btn_undo = Button.new()
	_btn_undo.text = "UNDO STEP"
	_btn_undo.custom_minimum_size = Vector2(0, 44)
	_btn_undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_undo.pressed.connect(_on_undo_pressed)
	buttons_row.add_child(_btn_undo)
	buttons_row.move_child(_btn_undo, 0)

	_btn_wait = Button.new()
	_btn_wait.text = "WAIT +5"
	_btn_wait.custom_minimum_size = Vector2(0, 44)
	_btn_wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_wait.pressed.connect(_on_wait_pressed)
	buttons_row.add_child(_btn_wait)
	buttons_row.move_child(_btn_wait, 1)

	_phase_label = Label.new()
	_phase_label.name = "PhaseLabelRuntime"
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phase_label.add_theme_font_size_override("font_size", 14)
	_phase_label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 0.95))
	var phase_anchor := phase_vbox.get_node_or_null("PhaseLabelAnchor")
	if phase_anchor != null:
		phase_anchor.queue_free()
	phase_vbox.add_child(_phase_label)

	_numpad_panel = PanelContainer.new()
	_numpad_panel.name = "NumpadPanel"
	_numpad_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_vbox.add_child(_numpad_panel)
	_numpad_grid = GridContainer.new()
	_numpad_grid.columns = 3
	_numpad_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_numpad_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_numpad_panel.add_child(_numpad_grid)
	var labels := ["7", "8", "9", "4", "5", "6", "1", "2", "3", "C", "0", "<"]
	for key in labels:
		var btn := Button.new()
		btn.text = key
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_numpad_button_pressed.bind(key))
		_numpad_grid.add_child(btn)
		_numpad_buttons.append(btn)

	_reveal_label = Label.new()
	_reveal_label.name = "RevealLabelRuntime"
	_reveal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_reveal_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.70, 1.0))
	var review_anchor := review_vbox.get_node_or_null("ReviewAnchorLabel")
	if review_anchor != null:
		review_anchor.queue_free()
	review_vbox.add_child(_reveal_label)
	review_vbox.move_child(_reveal_label, 0)

	_traffic_layer = Control.new()
	_traffic_layer.name = "TrafficLayer"
	_traffic_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_traffic_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_container.add_child(_traffic_layer)
	graph_container.move_child(_traffic_layer, nodes_layer.get_index())

	briefing_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	briefing_card.visible = false
	_phase_started_ms = Time.get_ticks_msec()

func _configure_info_text_wrapping() -> void:
	constraint_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	constraint_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	constraint_info_label.clip_text = false
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	path_display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	schedule_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _ensure_info_scroll_container() -> void:
	var parent: Node = info_vbox.get_parent()
	if parent is ScrollContainer:
		_info_scroll = parent as ScrollContainer
		return
	if parent == null:
		return
	var insertion_index: int = info_vbox.get_index()
	parent.remove_child(info_vbox)
	_info_scroll = ScrollContainer.new()
	_info_scroll.name = "InfoScrollRuntime"
	_info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_info_scroll)
	parent.move_child(_info_scroll, insertion_index)
	_info_scroll.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _configure_sum_input_display() -> void:
	sum_input.editable = false
	sum_input.selecting_enabled = false
	sum_input.shortcut_keys_enabled = false
	sum_input.context_menu_enabled = false
	sum_input.focus_mode = Control.FOCUS_CLICK
	sum_input.set("virtual_keyboard_enabled", false)
	sum_input.set("virtual_keyboard_show_on_focus", false)

func _phase_text() -> String:
	match round_phase:
		PHASE_BUILD:
			return _tr("city_map.common.phase.build", "STEP 1/4: Build route")
		PHASE_RULES:
			return _tr("city_map.common.phase.rules", "STEP 2/4: Check rules")
		PHASE_INPUT:
			return _tr("city_map.common.phase.input", "STEP 3/4: Enter total")
		_:
			return _tr("city_map.common.phase.review", "STEP 4/4: Review")

func _submit_button_text() -> String:
	var compact := _is_compact_schedule_mode()
	if round_phase == PHASE_RULES:
		return _tr("city_map.c.btn.to_input.compact", "IN") if compact else _tr("city_map.c.btn.to_input", "TO SUM INPUT")
	if round_phase == PHASE_INPUT or round_phase == PHASE_BUILD:
		return _tr("city_map.c.btn.submit.compact", "CHK") if compact else _tr("city_map.common.btn.check", "CHECK")
	return _tr("city_map.c.btn.submit.compact", "CHK") if compact else _tr("city_map.common.btn.check", "CHECK")

func _set_phase(next_phase: int, force: bool = false) -> void:
	var clamped_phase := clampi(next_phase, PHASE_BUILD, PHASE_REVIEW)
	if not force and round_phase == clamped_phase:
		if is_instance_valid(_phase_label):
			_phase_label.text = _phase_text()
		return
	var now_ms := Time.get_ticks_msec()
	if _phase_started_ms > 0:
		var key := str(round_phase)
		phase_time_ms[key] = int(phase_time_ms.get(key, 0)) + maxi(0, now_ms - _phase_started_ms)
	round_phase = clamped_phase
	_phase_started_ms = now_ms
	if is_instance_valid(_phase_label):
		_phase_label.text = _phase_text()

func _phase_snapshot_ms() -> Dictionary:
	var snapshot: Dictionary = phase_time_ms.duplicate(true)
	var now_ms := Time.get_ticks_msec()
	if _phase_started_ms > 0:
		var key := str(round_phase)
		snapshot[key] = int(snapshot.get(key, 0)) + maxi(0, now_ms - _phase_started_ms)
	return snapshot

func _elapsed_ms_now() -> int:
	if level_started_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - level_started_ms)

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var events_value: Variant = task_session.get("events", [])
	var events: Array = events_value if typeof(events_value) == TYPE_ARRAY else []
	events.append({
		"name": event_name,
		"t_ms": _elapsed_ms_now(),
		"payload": data.duplicate(true)
	})
	task_session["events"] = events

func _mark_change_after_feedback() -> void:
	if _warning_active:
		changed_after_warning = true
	if _review_phase_active or not _last_reveal.is_empty():
		changed_after_review = true

func _reset_trial_telemetry() -> void:
	task_session = {"events": [], "trial_seq": trial_seq}
	node_select_count = 0
	edge_step_count = 0
	submit_attempt_count = 0
	wait_action_count = 0
	reset_count_local = 0
	undo_count_local = 0
	closed_edge_attempt_count = 0
	danger_edge_count_local = 0
	blacklist_violation_count = 0
	xor_violation_count = 0
	dynamic_replan_count = 0
	timeline_step_count = 0
	changed_after_warning = false
	changed_after_review = false
	time_to_first_step_ms = -1
	time_to_first_submit_ms = -1
	time_to_first_wait_ms = -1
	time_from_last_edit_to_submit_ms = -1
	last_edit_ms = -1
	_last_review_had_hint = false

func _is_meaningful_move() -> bool:
	return path.size() > 1 or wait_count > 0 or undo_count > 0

func _build_objective_text() -> String:
	var must_text := "-" if must_visit_nodes.is_empty() else ",".join(must_visit_nodes)
	var blacklist_text := "-" if blacklist_nodes.is_empty() else ",".join(blacklist_nodes)
	var xor_parts: Array[String] = []
	for group_var in xor_groups:
		var group: Dictionary = group_var
		if str(group.get("type", "")) != "AT_MOST_ONE":
			continue
		var nodes_local: Array[String] = []
		for member_var in group.get("nodes", []):
			nodes_local.append(str(member_var))
		if not nodes_local.is_empty():
			xor_parts.append(",".join(nodes_local))
	var xor_text := "-" if xor_parts.is_empty() else " | ".join(xor_parts)
	var lines: Array[String] = [
		_tr("city_map.c.objective.must", "Objective: pass required node(s): {nodes}", {"nodes": must_text}),
		_tr("city_map.c.objective.blacklist", "Avoid blacklist node(s): {nodes}", {"nodes": blacklist_text}),
		_tr("city_map.c.objective.xor", "XOR rule: choose at most one from {nodes}", {"nodes": xor_text}),
		_tr("city_map.c.objective.schedule", "Watch time windows on scheduled edges.")
	]
	return "\n".join(lines)

func _build_warning_text() -> String:
	if not _is_meaningful_move():
		return ""
	var warnings: Array[String] = []
	var missing_must: Array[String] = []
	for must_node in must_visit_nodes:
		if not path.has(must_node):
			missing_must.append(must_node)
	if not missing_must.is_empty() and _is_meaningful_move():
		warnings.append(
			_tr(
				"city_map.c.warning.missing_must",
				"You still need required node(s): {nodes}",
				{"nodes": ",".join(missing_must)}
			)
		)
	if xor_violation:
		warnings.append(_tr("city_map.c.warning.xor", "XOR group conflict: choose at most one node"))
	if _path_has_blacklist(path):
		warnings.append(_tr("city_map.c.warning.blacklist", "Blacklist entered: reroute away from forbidden zone"))
	if closed_edge_attempts > 0:
		warnings.append(_tr("city_map.c.warning.closed_edge", "Closed edge blocked: wait or pick another branch"))
	if cycle_events > 0:
		warnings.append(_tr("city_map.c.warning.cycle", "Loop detected: avoid revisiting same branch"))
	if backtrack_count > 0:
		warnings.append(_tr("city_map.c.warning.undo", "Undo is normal while exploring dynamic options"))

	if warnings.is_empty():
		return ""
	if warnings.size() > 2:
		warnings = [warnings[0], warnings[1]]
	return _tr("city_map.common.warning.list", "Warnings:\n{items}", {"items": "\n".join(warnings)})

func _build_context_schedule_summary() -> Dictionary:
	var relevant_count := 0
	var danger_count := 0
	var closed_count := 0
	var soonest_ttc := -1
	var outgoing_scheduled := 0

	for row_var in _schedule_rows:
		var row: Dictionary = row_var
		var edge: Dictionary = row.get("edge", {})
		var edge_from := str(edge.get("from", ""))
		var edge_to := str(edge.get("to", ""))
		var runtime := get_edge_runtime_state(edge, sim_time_sec)
		var ttc := int(runtime.get("time_to_change", -1))
		var is_relevant := edge_from == current_node or _path_contains_edge(edge_from, edge_to)
		if edge_from == current_node:
			outgoing_scheduled += 1
		if not is_relevant:
			continue
		relevant_count += 1
		var state_text := str(runtime.get("state", "OPEN"))
		if state_text == "DANGER":
			danger_count += 1
		elif state_text == "CLOSED":
			closed_count += 1
		if ttc >= 0 and (soonest_ttc < 0 or ttc < soonest_ttc):
			soonest_ttc = ttc

	var summary_text := ""
	if relevant_count <= 0:
		summary_text = _tr("city_map.c.schedule.summary.idle", "Schedule: no relevant changes right now")
	elif danger_count > 0:
		summary_text = _tr(
			"city_map.c.schedule.summary.danger",
			"Schedule: {count} danger edge(s), nearest change in {ttc}s",
			{"count": danger_count, "ttc": soonest_ttc if soonest_ttc >= 0 else "-"}
		)
	elif closed_count > 0:
		summary_text = _tr(
			"city_map.c.schedule.summary.closed",
			"Schedule: {count} closed edge(s) on current context",
			{"count": closed_count}
		)
	else:
		summary_text = _tr(
			"city_map.c.schedule.summary.context",
			"Schedule: {count} relevant edge(s), nearest change in {ttc}s",
			{"count": relevant_count, "ttc": soonest_ttc if soonest_ttc >= 0 else "-"}
		)

	return {
		"text": summary_text,
		"relevant_count": relevant_count,
		"danger_count": danger_count,
		"closed_count": closed_count,
		"soonest_ttc": soonest_ttc,
		"outgoing_scheduled": outgoing_scheduled
	}

func _sync_phase_visibility() -> void:
	var has_schedule_data := not _schedule_rows.is_empty()
	var schedule_summary: Dictionary = _build_context_schedule_summary()
	var relevant_count := int(schedule_summary.get("relevant_count", 0))
	var outgoing_scheduled := int(schedule_summary.get("outgoing_scheduled", 0))
	var has_context_schedule := relevant_count > 0 or outgoing_scheduled > 0
	if is_instance_valid(schedule_summary_label):
		schedule_summary_label.text = str(schedule_summary.get("text", ""))

	var show_phase := true
	var show_objective := round_phase != PHASE_REVIEW
	var show_route := true
	var show_action := round_phase != PHASE_REVIEW
	var show_schedule := false
	if round_phase == PHASE_BUILD:
		show_schedule = has_schedule_data and has_context_schedule
	elif round_phase == PHASE_RULES or round_phase == PHASE_INPUT:
		show_schedule = has_schedule_data
	var show_input := round_phase == PHASE_INPUT
	var show_review := round_phase == PHASE_REVIEW

	phase_card.visible = show_phase
	objective_card.visible = show_objective
	route_card.visible = show_route
	action_card.visible = show_action
	schedule_panel.visible = show_schedule
	input_card.visible = show_input
	review_card.visible = show_review

	if is_instance_valid(_btn_undo):
		_btn_undo.visible = round_phase == PHASE_BUILD or round_phase == PHASE_RULES
		_btn_undo.disabled = _is_round_locked() or _undo_stack.is_empty()
	if is_instance_valid(_btn_wait):
		_btn_wait.visible = round_phase == PHASE_BUILD or round_phase == PHASE_RULES
		var wait_has_effect := _wait_has_effect(5)
		_btn_wait.disabled = _is_round_locked() or not wait_has_effect
		if _btn_wait.disabled and not _is_round_locked() and not wait_has_effect:
			_btn_wait.tooltip_text = _tr("city_map.c.wait.no_effect", "Waiting now does not change available routes.")
		else:
			_btn_wait.tooltip_text = ""
	btn_reset.visible = round_phase != PHASE_REVIEW
	btn_submit.visible = round_phase != PHASE_REVIEW
	btn_submit.text = _submit_button_text()
	if round_phase == PHASE_BUILD:
		btn_submit.disabled = true
	elif round_phase == PHASE_RULES:
		btn_submit.disabled = current_node != str(level_data.get("end_node", "L"))
	else:
		btn_submit.disabled = _is_round_locked() or current_node != str(level_data.get("end_node", "L"))

	if round_phase == PHASE_INPUT:
		if is_instance_valid(_btn_undo):
			_btn_undo.visible = false
		if is_instance_valid(_btn_wait):
			_btn_wait.visible = false

	btn_next.visible = round_phase == PHASE_REVIEW
	btn_next.disabled = false
	if round_phase == PHASE_REVIEW and not stage_completed:
		btn_next.text = _tr("city_map.common.btn.retry", "RETRY")
	else:
		_set_progress_ui()
	schedule_summary_label.visible = show_schedule

func _route_display_text_with_timing() -> String:
	if path.size() <= 1:
		return "[%s]" % str(path[0]) if not path.is_empty() else "-"
	var chunks: Array[String] = []
	chunks.append(str(path[0]))
	for i in range(path.size() - 1):
		var next_node := str(path[i + 1])
		var step_weight := int(step_weights[i]) if i < step_weights.size() else -1
		var suffix := ""
		if step_weight >= 0:
			suffix = " (+%ds)" % step_weight
		if i == path.size() - 2:
			chunks.append("[%s%s]" % [next_node, suffix])
		else:
			chunks.append("%s%s" % [next_node, suffix])
	return " -> ".join(chunks)

func _best_known_path_preview() -> Array[String]:
	return _solver.build_best_path_preview(level_data.get("min_path_examples", []))

func _soft_hint_text(result_code: String) -> String:
	if attempt_in_sublevel < 2:
		return ""
	match result_code:
		"ERR_LOGIC_VIOLATION":
			return _tr("city_map.c.hint.xor", "Hint: in XOR groups choose no more than one node.")
		"ERR_AMBUSH":
			return _tr("city_map.c.hint.blacklist", "Hint: blacklist nodes are forbidden zones.")
		"ERR_MISSING_TRANSIT":
			return _tr("city_map.c.hint.must", "Hint: include required nodes before final approach.")
		"ERR_PATH_INVALID":
			return _tr("city_map.c.hint.closed", "Hint: closed edges can block transitions at current sim-time.")
		_:
			return _tr("city_map.c.hint.generic", "Hint: review time windows and pick a route tempo that keeps edges available.")

func _build_wait_preview(delta_sec: int) -> String:
	var preview_ctx := _build_wait_delta_context(delta_sec)
	return _tr(
		"city_map.c.wait.preview",
		"WAIT +{delta}s: sim {from}->{to}, opens={opens}, closes={closes}",
		preview_ctx
	)

func _build_wait_delta_context(delta_sec: int) -> Dictionary:
	var target_sim := sim_time_sec + delta_sec
	var opened: Array[String] = []
	var closed: Array[String] = []
	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		if from_id != current_node:
			continue
		var now_runtime := get_edge_runtime_state(edge, sim_time_sec)
		var next_runtime := get_edge_runtime_state(edge, target_sim)
		var key := "%s->%s" % [from_id, str(edge.get("to", ""))]
		if str(now_runtime.get("state", "OPEN")) == "CLOSED" and str(next_runtime.get("state", "OPEN")) != "CLOSED":
			opened.append(key)
		if str(now_runtime.get("state", "OPEN")) != "CLOSED" and str(next_runtime.get("state", "OPEN")) == "CLOSED":
			closed.append(key)
	var open_text := "-" if opened.is_empty() else ",".join(opened)
	var close_text := "-" if closed.is_empty() else ",".join(closed)
	return {"delta": delta_sec, "from": sim_time_sec, "to": target_sim, "opens": open_text, "closes": close_text}

func _wait_has_effect(delta_sec: int = 5) -> bool:
	if not adjacency.has(current_node):
		return false
	for next_var in adjacency[current_node].keys():
		var edge: Dictionary = adjacency[current_node][next_var]
		if not edge.has("schedule"):
			continue
		var now_runtime := get_edge_runtime_state(edge, sim_time_sec)
		var next_runtime := get_edge_runtime_state(edge, sim_time_sec + delta_sec)
		if str(now_runtime.get("state", "OPEN")) != str(next_runtime.get("state", "OPEN")):
			return true
		if int(now_runtime.get("w", now_runtime.get("weight", 0))) != int(next_runtime.get("w", next_runtime.get("weight", 0))):
			return true
	return false

func _set_transient_status_i18n(key: String, default_text: String, color: Color, params: Dictionary = {}, duration_ms: int = 1800) -> void:
	_set_status_i18n(key, default_text, color, params)
	_status_override_until_ms = Time.get_ticks_msec() + maxi(300, duration_ms)

func _refresh_status_guidance() -> void:
	var now_ms := Time.get_ticks_msec()
	if _status_override_until_ms > 0 and now_ms < _status_override_until_ms:
		return
	if _status_override_until_ms > 0 and now_ms >= _status_override_until_ms:
		_status_override_until_ms = 0
		_clear_status_i18n()

	if not _status_i18n_key.is_empty() and not _status_i18n_key.begins_with("city_map.c.status.guidance"):
		return

	match round_phase:
		PHASE_BUILD:
			_set_status_i18n("city_map.c.status.guidance.build", "Build route and track upcoming edge changes.", Color(0.78, 0.86, 0.96))
		PHASE_RULES:
			_set_status_i18n("city_map.c.status.guidance.rules", "Route reached target. Move to sum input.", Color(0.78, 0.86, 0.96))
		PHASE_INPUT:
			_set_status_i18n("city_map.c.status.guidance.input", "Enter route total and check.", Color(0.78, 0.86, 0.96))
		_:
			pass

func _build_review_text(verdict: Dictionary) -> String:
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var player_cost := int(verdict.get("player_cost", int(verdict.get("sum_actual", -1))))
	var best_cost := int(verdict.get("best_known_cost", min_sum))
	var must_ok := bool(verdict.get("must_visit_ok", false))
	var xor_ok := bool(verdict.get("xor_ok", false))
	var blacklist_ok := bool(verdict.get("blacklist_ok", false))
	var dynamic_ok := bool(verdict.get("dynamic_ok", false))
	var optimal_ok := bool(verdict.get("optimal_ok", false))

	var happened := ""
	var where := ""
	var revisit := ""
	var keep := ""
	match result_code:
		"OK":
			happened = _tr("city_map.common.review.ok.happened", "What happened: your route is valid and optimal.")
			where = _tr("city_map.c.review.ok.where", "Where: constraints and timing windows are satisfied.")
			revisit = _tr("city_map.c.review.ok.revisit", "Review: keep balancing route choice and movement tempo.")
			keep = _tr("city_map.c.review.ok.keep", "Still correct: dynamic model and constraints are both respected.")
		"ERR_LOGIC_VIOLATION":
			happened = _tr("city_map.c.review.xor.happened", "What happened: XOR rule is violated.")
			where = _tr("city_map.c.review.xor.where", "Where: nodes from one XOR group were combined.")
			revisit = _tr("city_map.c.review.xor.revisit", "Review: keep only one node from each XOR group.")
			keep = _tr("city_map.c.review.xor.keep", "Still correct: valid timed edges can be reused.")
		"ERR_AMBUSH":
			happened = _tr("city_map.c.review.blacklist.happened", "What happened: blacklist node was visited.")
			where = _tr("city_map.c.review.blacklist.where", "Where: route entered a forbidden zone.")
			revisit = _tr("city_map.c.review.blacklist.revisit", "Review: reroute around blacklist nodes.")
			keep = _tr("city_map.c.review.blacklist.keep", "Still correct: timing insights remain useful.")
		_:
			happened = _tr("city_map.common.review.generic.happened", "What happened: route check failed.")
			where = _tr("city_map.common.review.generic.where", "Where: inspect constraints and time windows.")
			revisit = _tr("city_map.common.review.generic.revisit", "Review: adjust route and pace.")
			keep = _tr("city_map.common.review.generic.keep", "Still correct: preserve valid route segments.")

	var status_line := _tr(
		"city_map.c.review.status",
		"Status: must={must}, xor={xor}, blacklist={blacklist}, dynamic={dyn}, optimal={opt}",
		{
			"must": "yes" if must_ok else "no",
			"xor": "yes" if xor_ok else "no",
			"blacklist": "yes" if blacklist_ok else "no",
			"dyn": "yes" if dynamic_ok else "no",
			"opt": "yes" if optimal_ok else "no"
		}
	)
	var cost_line := _tr(
		"city_map.c.review.cost",
		"Cost: yours={player}, best_known={best}",
		{"player": player_cost, "best": best_cost}
	)
	var route_line := _tr(
		"city_map.c.review.route",
		"Route: {path}",
		{"path": _route_display_text_with_timing()}
	)
	var step_breakdown := _build_review_step_breakdown(verdict)
	var review_lines: Array[String] = [happened, where, revisit, keep, status_line, cost_line, route_line]
	if not step_breakdown.is_empty():
		review_lines.append(step_breakdown)
	var hint_text := _soft_hint_text(result_code)
	_last_review_had_hint = false
	if not hint_text.is_empty():
		_hint_count += 1
		_last_review_had_hint = true
		_log_event("hint_opened", {"result_code": result_code, "hint": hint_text})
		review_lines.append(hint_text)
	return "\n".join(review_lines)

func _build_review_step_breakdown(verdict: Dictionary) -> String:
	var weights_variant: Variant = verdict.get("step_weights", [])
	if typeof(weights_variant) != TYPE_ARRAY:
		return ""
	var weights: Array = weights_variant
	if path.size() <= 1 or weights.is_empty():
		return ""
	var error_step_idx := int(verdict.get("player_error_step_idx", -1))
	var sim_cursor := 0
	var lines: Array[String] = []
	for i in range(path.size() - 1):
		var from_id := str(path[i])
		var to_id := str(path[i + 1])
		var step_cost := int(weights[i]) if i < weights.size() else 0
		var runtime_state := "OPEN"
		if adjacency.has(from_id) and adjacency[from_id].has(to_id):
			runtime_state = str(get_edge_runtime_state(adjacency[from_id][to_id], sim_cursor).get("state", "OPEN"))
		var tags: Array[String] = []
		if blacklist_nodes.has(to_id):
			tags.append(_tr("city_map.c.review.step.tag.blacklist", "BLACKLIST"))
		if runtime_state == "DANGER":
			tags.append(_tr("city_map.c.review.step.tag.danger", "DANGER"))
		elif runtime_state == "CLOSED":
			tags.append(_tr("city_map.c.review.step.tag.closed", "CLOSED"))
		if i == error_step_idx:
			tags.append(_tr("city_map.c.review.step.tag.error", "ERROR STEP"))
		sim_cursor += step_cost
		var tag_suffix := ""
		if not tags.is_empty():
			tag_suffix = " [%s]" % ", ".join(tags)
		lines.append(
			_tr(
				"city_map.c.review.step.line",
				"{from}->{to} (+{cost}) t={sim}{tags}",
				{"from": from_id, "to": to_id, "cost": step_cost, "sim": sim_cursor, "tags": tag_suffix}
			)
		)
	return _tr(
		"city_map.c.review.step_breakdown",
		"Step breakdown:\n{steps}",
		{"steps": "\n".join(lines)}
	)

func _on_help_pressed() -> void:
	_set_dossier_open(not briefing_card.visible)

func _set_dossier_open(opened: bool) -> void:
	if briefing_card.visible == opened:
		return
	briefing_card.visible = opened
	if opened:
		dossier_open_count += 1
		_dossier_open_started_ms = Time.get_ticks_msec()
		_log_event("details_opened", {"opened": true, "count": dossier_open_count})
	else:
		if _dossier_open_started_ms >= 0:
			time_dossier_open_ms += Time.get_ticks_msec() - _dossier_open_started_ms
		_dossier_open_started_ms = -1
		_log_event("details_opened", {"opened": false})

func _on_numpad_button_pressed(key: String) -> void:
	if _is_round_locked():
		return
	var text := sum_input.text
	match key:
		"C":
			if not text.is_empty():
				sum_input.clear()
		"<":
			backspace_count += 1
			if text.length() > 0:
				sum_input.text = text.substr(0, text.length() - 1)
		_:
			if text.length() >= sum_input.max_length:
				return
			sum_input.text = "%s%s" % [text, key]
			numpad_input_count += 1

func _on_wait_pressed() -> void:
	if _is_round_locked():
		return
	_mark_change_after_feedback()
	if not _wait_has_effect(5):
		_log_event("wait_pressed", {"delta": 5, "has_effect": false, "sim_time_sec": sim_time_sec})
		_set_transient_status_i18n(
			"city_map.c.wait.no_effect",
			"Waiting now does not change available routes.",
			Color(0.86, 0.82, 0.72),
			{},
			1500
		)
		return
	_push_undo_snapshot()
	if first_attempt_edge.is_empty():
		first_attempt_edge = "WAIT+5"
		first_action_ms = Time.get_ticks_msec() - level_started_ms
		planning_time_ms = first_action_ms
	var wait_delta_ctx := _build_wait_delta_context(5)
	wait_count += 1
	wait_action_count += 1
	dynamic_replan_count += 1
	if time_to_first_wait_ms < 0:
		time_to_first_wait_ms = _elapsed_ms_now()
	last_edit_ms = _elapsed_ms_now()
	wait_total_sim_sec += 5
	sim_time_sec += 5
	_last_step_cost = 0
	_log_event("wait_pressed", {
		"delta": 5,
		"has_effect": true,
		"context": wait_delta_ctx.duplicate(true),
		"dynamic_replan_count": dynamic_replan_count
	})
	_log_event("timeline_advanced", {"sim_time_sec": sim_time_sec, "delta": 5})
	_last_move_ms = Time.get_ticks_msec()
	_set_transient_status_i18n(
		"city_map.c.status.wait_delta",
		"WAIT +{delta}s: sim {from}->{to}, opens={opens}, closes={closes}",
		Color(1.0, 0.78, 0.34),
		wait_delta_ctx
	)
	_update_visuals()

func _on_undo_pressed() -> void:
	if _is_round_locked() or _undo_stack.is_empty():
		return
	_mark_change_after_feedback()
	var snapshot: Dictionary = _undo_stack.pop_back()
	current_node = str(snapshot.get("current_node", current_node))
	path = snapshot.get("path", path).duplicate()
	path_sum = int(snapshot.get("path_sum", path_sum))
	_last_step_cost = int(snapshot.get("last_step_cost", _last_step_cost))
	step_weights = snapshot.get("step_weights", step_weights).duplicate()
	sim_time_sec = int(snapshot.get("sim_time_sec", sim_time_sec))
	backtrack_count = int(snapshot.get("backtrack_count", backtrack_count))
	cycle_events = int(snapshot.get("cycle_events", cycle_events))
	cycle_detected = bool(snapshot.get("cycle_detected", cycle_detected))
	constraint_violations = int(snapshot.get("constraint_violations", constraint_violations))
	closed_edge_attempts = int(snapshot.get("closed_edge_attempts", closed_edge_attempts))
	ambush_hits = int(snapshot.get("ambush_hits", ambush_hits))
	xor_violation = bool(snapshot.get("xor_violation", xor_violation))
	dynamic_weight_awareness = bool(snapshot.get("dynamic_weight_awareness", dynamic_weight_awareness))
	first_attempt_edge = str(snapshot.get("first_attempt_edge", first_attempt_edge))
	first_action_ms = int(snapshot.get("first_action_ms", first_action_ms))
	_route_committed_for_input = false
	_review_phase_active = false
	undo_count += 1
	undo_count_local += 1
	edge_step_count = maxi(0, path.size() - 1)
	last_edit_ms = _elapsed_ms_now()
	_log_event("undo_pressed", {"path_len": path.size(), "current_node": current_node})
	_last_move_ms = Time.get_ticks_msec()
	_recalculate_stability()
	_update_visuals()

func _push_undo_snapshot() -> void:
	_undo_stack.append({
		"current_node": current_node,
		"path": path.duplicate(),
		"path_sum": path_sum,
		"last_step_cost": _last_step_cost,
		"step_weights": step_weights.duplicate(),
		"sim_time_sec": sim_time_sec,
		"backtrack_count": backtrack_count,
		"cycle_events": cycle_events,
		"cycle_detected": cycle_detected,
		"constraint_violations": constraint_violations,
		"closed_edge_attempts": closed_edge_attempts,
		"ambush_hits": ambush_hits,
		"xor_violation": xor_violation,
		"dynamic_weight_awareness": dynamic_weight_awareness,
		"first_attempt_edge": first_attempt_edge,
		"first_action_ms": first_action_ms
	})

func _start_pack_run() -> void:
	run_started_unix = int(Time.get_unix_time_from_system())
	run_id = "CITYMAP_%s_%d" % ["C", run_started_unix]
	level_index = 0
	attempt_in_run = 0
	levels_completed = 0
	levels_perfect = 0
	run_total_time_seconds = 0
	run_total_calc_errors = 0
	run_total_opt_errors = 0
	run_total_parse_errors = 0
	run_total_reset_errors = 0
	run_total_transit_errors = 0
	run_total_logic_errors = 0
	run_total_closed_errors = 0
	run_total_ambush_hits = 0
	_load_sublevel(level_index)

func _load_pack(pack_path: String) -> void:
	pack_data.clear()
	pack_levels.clear()
	level_total = 0

	var file := FileAccess.open(pack_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open pack data: %s" % pack_path)
		pack_levels = [{"id": "6_3_01", "path": "res://data/city_map/level_6_3.json"}]
		level_total = pack_levels.size()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid pack JSON in %s" % pack_path)
		pack_levels = [{"id": "6_3_01", "path": "res://data/city_map/level_6_3.json"}]
		level_total = pack_levels.size()
		return

	pack_data = parsed
	pack_id = str(pack_data.get("pack_id", "CITY_MAP_C_PACK_01"))
	var raw_levels: Array = pack_data.get("levels", [])
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_entry: Dictionary = level_var
		if str(level_entry.get("path", "")).is_empty():
			continue
		pack_levels.append(level_entry)

	if pack_levels.is_empty():
		pack_levels = [{"id": "6_3_01", "path": "res://data/city_map/level_6_3.json"}]
	level_total = pack_levels.size()

func _load_sublevel(index: int) -> void:
	if index < 0 or index >= pack_levels.size():
		return

	level_index = index
	var level_entry := _current_level_entry()
	var level_path := str(level_entry.get("path", ""))
	if level_path.is_empty():
		push_error("Missing level path in pack entry at index %d" % index)
		return

	_load_level_data(level_path)
	attempt_in_sublevel = 0
	is_game_over = false
	stage_completed = false
	input_locked = false
	real_time_sec = 0
	sim_time_sec = 0
	n_calc = 0
	n_opt = 0
	n_parse = 0
	n_reset = 0
	n_transit = 0
	n_logic = 0
	n_closed = 0
	backtrack_count = 0
	cycle_events = 0
	cycle_detected = false
	constraint_violations = 0
	closed_edge_attempts = 0
	ambush_hits = 0
	xor_violation = false
	dynamic_weight_awareness = true
	undo_count = 0
	numpad_input_count = 0
	backspace_count = 0
	dossier_open_count = 0
	time_dossier_open_ms = 0
	wait_count = 0
	wait_total_sim_sec = 0
	schedule_panel_open_count = 0
	_hint_count = 0
	_last_reveal = {}
	_last_step_cost = 0
	_pack_summary_ready = false
	_pack_summary_data = {}
	round_phase = PHASE_BUILD
	phase_time_ms = {"1": 0, "2": 0, "3": 0, "4": 0}
	_phase_started_ms = Time.get_ticks_msec()
	think_time_before_move_ms.clear()
	_last_move_ms = Time.get_ticks_msec()
	_dossier_open_started_ms = -1
	_danger_edges_seen.clear()
	_closed_edges_seen.clear()
	briefing_card.visible = false

	_set_briefing()
	_rebuild_graph_ui()
	_build_schedule_ui()
	_reset_round_state(true)
	trial_seq += 1
	_reset_trial_telemetry()
	_log_event("trial_started", {
		"level_id": str(level_data.get("level_id", "")),
		"time_limit_sec": int(level_data.get("time_limit_sec", 140)),
		"trust_initial": int(level_data.get("trust", {}).get("initial", 100)),
		"analytics_schema_version": _analytics_schema_version
	})
	_lock_input(false)
	_update_timer_display()
	_recalculate_stability()
	if is_game_over:
		return
	btn_next.visible = false
	btn_next.disabled = true
	_set_progress_ui()

func _current_level_entry() -> Dictionary:
	if level_index < 0 or level_index >= pack_levels.size():
		return {}
	var level_var: Variant = pack_levels[level_index]
	if typeof(level_var) != TYPE_DICTIONARY:
		return {}
	return level_var

func _set_progress_ui() -> void:
	var shown_index := maxi(1, level_index + 1)
	var total := maxi(1, level_total)
	var level_entry := _current_level_entry()
	var sub_id := str(level_entry.get("id", ""))
	label_progress.text = _tr(
		"city_map.common.header.progress",
		"TASK: {current}/{total}{suffix}",
		{
			"current": shown_index,
			"total": total,
			"suffix": ("" if sub_id.is_empty() else " | " + sub_id)
		}
	)
	if level_index >= total - 1:
		btn_next.text = _tr("city_map.common.btn.finish", "FINISH")
	else:
		btn_next.text = _tr("city_map.common.btn.next", "NEXT")

func _is_round_locked() -> bool:
	return is_game_over or stage_completed or input_locked

func _lock_input(locked: bool) -> void:
	input_locked = locked
	sum_input.editable = false
	btn_submit.disabled = locked or is_game_over or stage_completed
	btn_reset.disabled = locked or is_game_over or stage_completed
	if is_instance_valid(_btn_undo):
		_btn_undo.disabled = locked or is_game_over or stage_completed or _undo_stack.is_empty()
	if is_instance_valid(_btn_wait):
		_btn_wait.disabled = locked or is_game_over or stage_completed
	_update_visuals()

func _on_next_pressed() -> void:
	if round_phase == PHASE_REVIEW and not stage_completed:
		_route_committed_for_input = false
		_review_phase_active = false
		_last_reveal = {}
		if is_instance_valid(_reveal_label):
			_reveal_label.text = ""
		_clear_status_i18n()
		_set_phase(PHASE_BUILD)
		_update_visuals()
		return
	if not stage_completed:
		return
	if _pack_summary_ready:
		_request_back_navigation("pack_complete")
		return
	if level_index + 1 >= level_total:
		var summary := _finalize_pack_run()
		_show_pack_summary(summary)
		return
	_load_sublevel(level_index + 1)

func _finalize_pack_run() -> Dictionary:
	var summary := {
		"schema_version": "city_map.run.v1",
		"quest_id": "CITY_MAP",
		"mode": "C",
		"run_id": run_id,
		"pack_id": pack_id,
		"levels_total": level_total,
		"levels_completed": levels_completed,
		"levels_perfect": levels_perfect,
		"total_time_seconds": run_total_time_seconds,
		"total_calc_errors": run_total_calc_errors,
		"total_opt_errors": run_total_opt_errors,
		"total_parse_errors": run_total_parse_errors,
		"total_reset_errors": run_total_reset_errors,
		"total_transit_errors": run_total_transit_errors,
		"total_logic_errors": run_total_logic_errors,
		"total_closed_errors": run_total_closed_errors,
		"total_ambush_hits": run_total_ambush_hits,
		"finished_at_unix": int(Time.get_unix_time_from_system())
	}
	_save_json_log(summary, true)
	return summary

func _show_pack_summary(summary: Dictionary) -> void:
	_pack_summary_ready = true
	_pack_summary_data = summary.duplicate(true)
	var solved := int(summary.get("levels_completed", levels_completed))
	var total := int(summary.get("levels_total", level_total))
	var perfect := int(summary.get("levels_perfect", levels_perfect))
	var route_err := int(summary.get("total_closed_errors", run_total_closed_errors))
	var cond_err := int(summary.get("total_transit_errors", run_total_transit_errors)) + int(summary.get("total_logic_errors", run_total_logic_errors))
	var calc_err := int(summary.get("total_calc_errors", run_total_calc_errors))
	var opt_err := int(summary.get("total_opt_errors", run_total_opt_errors))
	var avg_time := 0.0 if solved <= 0 else float(int(summary.get("total_time_seconds", run_total_time_seconds))) / float(solved)
	var recommendation := _pack_recommendation_text(route_err, cond_err, calc_err, opt_err)

	briefing_title.text = _tr("city_map.common.summary.title", "PACK SUMMARY")
	briefing_text.text = _tr(
		"city_map.c.summary.body",
		"Solved: {solved}/{total}\nFirst try: {perfect}\nErrors:\n- Dynamic route: {route}\n- Constraints: {cond}\n- Arithmetic: {calc}\n- Optimality: {opt}\nAverage time: {avg}s",
		{
			"solved": solved,
			"total": total,
			"perfect": perfect,
			"route": route_err,
			"cond": cond_err,
			"calc": calc_err,
			"opt": opt_err,
			"avg": int(round(avg_time))
		}
	)
	footer_label.text = _tr("city_map.common.summary.recommendation", "Recommendation: {text}", {"text": recommendation})
	_set_dossier_open(true)
	_set_status_i18n("city_map.common.summary.ready", "Pack summary is ready. Press FINISH to exit.", Color(0.82, 0.92, 1.0))
	_lock_input(true)
	btn_next.visible = true
	btn_next.disabled = false
	btn_next.text = _tr("city_map.common.btn.finish", "FINISH")

func _pack_recommendation_text(route_err: int, cond_err: int, calc_err: int, opt_err: int) -> String:
	if cond_err >= route_err and cond_err >= calc_err and cond_err >= opt_err and cond_err > 0:
		return _tr("city_map.c.summary.reco.constraints", "Track must-visit, XOR, and blacklist constraints step by step.")
	if route_err >= calc_err and route_err >= opt_err and route_err > 0:
		return _tr("city_map.c.summary.reco.dynamic", "Plan tempo with schedule windows and avoid closed edges.")
	if opt_err >= calc_err and opt_err > 0:
		return _tr("city_map.c.summary.reco.opt", "Compare dynamic route alternatives, not only immediate edge cost.")
	if calc_err > 0:
		return _tr("city_map.c.summary.reco.calc", "Recalculate simulated path cost after each timed step.")
	return _tr("city_map.c.summary.reco.good", "Strong dynamic planning and constraint control.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_request_back_navigation("ui_cancel")
		get_viewport().set_input_as_handled()
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if btn_back.get_global_rect().has_point(mouse_event.global_position):
		_request_back_navigation("mouse_rect_hit")
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_apply_content_layout_mode()
		_rebuild_graph_ui()
		_update_visuals()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if has_node("ResearchTimer"):
			get_node("ResearchTimer").paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if has_node("ResearchTimer"):
			get_node("ResearchTimer").paused = false

func _apply_content_layout_mode() -> void:
	var viewport: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport.x >= viewport.y
	content_split.vertical = not is_landscape
	var compact_landscape: bool = is_landscape and viewport.y <= 760.0
	var compact_portrait: bool = not is_landscape and viewport.x <= 480.0
	if content_split.vertical:
		graph_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		graph_panel.size_flags_stretch_ratio = 3.8
		info_panel.size_flags_stretch_ratio = 1.2
	else:
		graph_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_panel.size_flags_horizontal = Control.SIZE_FILL
		graph_panel.size_flags_stretch_ratio = 4.0 if compact_landscape else 4.2
		info_panel.size_flags_stretch_ratio = 1.0
	_apply_compact_phone_layout(compact_landscape or compact_portrait)

func _apply_compact_phone_layout(compact: bool) -> void:
	var viewport: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport.x >= viewport.y
	safe_area.add_theme_constant_override("margin_left", 8 if compact else 16)
	safe_area.add_theme_constant_override("margin_right", 8 if compact else 16)
	safe_area.add_theme_constant_override("margin_top", 8 if compact else 12)
	safe_area.add_theme_constant_override("margin_bottom", 8 if compact else 12)
	main_vbox.add_theme_constant_override("separation", 6 if compact else 12)
	header.add_theme_constant_override("separation", 6 if compact else 10)
	buttons_row.add_theme_constant_override("separation", 4 if compact else 8)
	content_split.add_theme_constant_override("separation", 8 if compact else 12)
	header.custom_minimum_size.y = 42.0 if compact else 56.0
	btn_back.custom_minimum_size = Vector2(44.0, 44.0) if compact else Vector2(56.0, 56.0)
	label_case.visible = not compact
	label_mode.visible = not compact
	label_progress.add_theme_font_size_override("font_size", 14 if compact else 18)
	label_state.add_theme_font_size_override("font_size", 14 if compact else 18)
	label_timer.add_theme_font_size_override("font_size", 14 if compact else 18)
	footer_row.visible = not compact
	graph_panel.custom_minimum_size = Vector2.ZERO
	graph_container.custom_minimum_size = Vector2.ZERO
	if is_landscape:
		var info_width_max: float = viewport.x * 0.26
		var info_width_min: float = minf(190.0, info_width_max)
		var info_width_target: float = viewport.x * (0.20 if compact else 0.23)
		var info_width: float = clampf(info_width_target, info_width_min, info_width_max)
		info_panel.custom_minimum_size = Vector2(info_width, 0.0)
	else:
		info_panel.custom_minimum_size = Vector2(0.0, 0.0)
	sum_input.custom_minimum_size.y = 36.0 if compact else 44.0
	status_label.custom_minimum_size.y = 44.0 if compact else 64.0
	_btn_undo.text = _tr("city_map.c.btn.undo.compact", "UN") if compact else _tr("city_map.common.btn.undo_step", "UNDO STEP")
	_btn_wait.text = _tr("city_map.c.btn.wait.compact", "W+5") if compact else _tr("city_map.c.btn.wait", "WAIT +5")
	btn_reset.text = _tr("city_map.c.btn.reset.compact", "RST") if compact else _tr("city_map.common.btn.reset_route", "RESET ROUTE")
	btn_submit.text = _submit_button_text()
	if is_instance_valid(_btn_help):
		_btn_help.custom_minimum_size = Vector2(36.0, 36.0) if compact else Vector2(44.0, 44.0)
	if is_instance_valid(_btn_undo):
		_btn_undo.custom_minimum_size.y = 34.0 if compact else 44.0
	if is_instance_valid(_btn_wait):
		_btn_wait.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_reset.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_submit.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_next.custom_minimum_size.y = 34.0 if compact else 44.0
	for np_btn in _numpad_buttons:
		np_btn.custom_minimum_size.y = 30.0 if compact else 44.0
	if is_instance_valid(_numpad_grid):
		_numpad_grid.columns = 6 if compact else 3
	if is_instance_valid(schedule_panel):
		schedule_panel.custom_minimum_size.y = 160.0 if compact else 0.0
		schedule_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	if is_instance_valid(_info_scroll):
		_info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_apply_schedule_typography(compact)

func _setup_timer() -> void:
	var timer := Timer.new()
	timer.name = "ResearchTimer"
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)

func _on_timer_tick() -> void:
	if is_game_over or stage_completed or level_data.is_empty():
		return
	real_time_sec += 1
	_update_timer_display()
	refresh_edge_states()
	if real_time_sec > int(level_data.get("time_limit_sec", 140)):
		_recalculate_stability()

func _process(delta: float) -> void:
	for key_var in _traffic_visuals.keys():
		var key := str(key_var)
		var item: Dictionary = _traffic_visuals[key]
		var speed := float(item.get("speed", 0.0))
		var offset := float(item.get("offset", 0.0))
		offset = fposmod(offset + speed * delta, 1.0)
		var mat: ShaderMaterial = item["material"]
		mat.set_shader_parameter("scroll", offset)
		item["offset"] = offset
		_traffic_visuals[key] = item

func _load_level_data(path_to_file: String) -> void:
	var file := FileAccess.open(path_to_file, FileAccess.READ)
	if file == null:
		push_error("Failed to open level data: %s" % path_to_file)
		return

	var raw_json := file.get_as_text()
	config_hash = raw_json.sha256_text()
	var parsed: Variant = JSON.parse_string(raw_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid level JSON in %s" % path_to_file)
		return

	level_data = parsed
	node_defs.clear()
	adjacency.clear()
	must_visit_nodes.clear()
	blacklist_nodes.clear()
	xor_groups.clear()

	for node_var in level_data.get("nodes", []):
		var node: Dictionary = node_var
		node_defs[str(node.get("id", ""))] = node

	for must_var in level_data.get("constraints", {}).get("must_visit", []):
		must_visit_nodes.append(str(must_var))
	for blacklist_var in level_data.get("constraints", {}).get("blacklist_nodes", []):
		blacklist_nodes.append(str(blacklist_var))
	for xor_var in level_data.get("constraints", {}).get("xor_groups", []):
		xor_groups.append(xor_var)
	var analytics_cfg: Dictionary = level_data.get("analytics", {})
	_analytics_schema_version = str(analytics_cfg.get("schema_version", "city_map.v3.0.0"))

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue
		if not adjacency.has(from_id):
			adjacency[from_id] = {}
		adjacency[from_id][to_id] = edge

	input_regex = RegEx.new()
	var regex_pattern := "^[0-9]+$"
	if level_data.has("rules") and level_data.rules.has("input_regex"):
		regex_pattern = str(level_data.rules.input_regex)
	input_regex.compile(regex_pattern)

	min_sum = int(level_data.get("min_sum", -1))
	if min_sum < 0:
		min_sum = _calculate_min_sum_dynamic()

	if level_data.has("ui"):
		if level_data.ui.has("accent_color"):
			accent_color = Color(level_data.ui.accent_color)
		if level_data.ui.has("node_radius_px"):
			var raw_radius := float(level_data.ui.node_radius_px)
			node_radius_px = raw_radius * 0.5 if raw_radius > 32.0 else raw_radius
			node_radius_px = maxf(16.0, node_radius_px)
		if level_data.ui.has("node_hit_target_px"):
			node_hit_target_px = maxf(44.0, float(level_data.ui.node_hit_target_px))
		else:
			node_hit_target_px = 48.0
	else:
		node_hit_target_px = 48.0

	_jitter_map = _renderer.build_deterministic_jitter(node_defs, config_hash, 8.0)

func _set_briefing() -> void:
	briefing_title.text = _tr("city_map.c.briefing.title", "CURFEW WINDOW")
	briefing_text.text = _tr(
		"city_map.c.briefing.text",
		"Reach {end}. Time changes edge state: OPEN, DANGER, CLOSED. Plan both route and tempo.",
		{"end": str(level_data.get("end_node", "L"))}
	)
	update_conditions_panel()
	footer_label.text = _tr(
		"city_map.c.briefing.footer",
		"WAIT is tactical: preview state changes before using it."
	)

func _build_schedule_ui() -> void:
	if _btn_schedule_toggle == null and schedule_title.get_parent() is VBoxContainer:
		var schedule_vbox := schedule_title.get_parent() as VBoxContainer
		_btn_schedule_toggle = Button.new()
		_btn_schedule_toggle.name = "ScheduleToggleRuntime"
		_btn_schedule_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_btn_schedule_toggle.custom_minimum_size = Vector2(0, 34)
		_btn_schedule_toggle.pressed.connect(_on_schedule_toggle_pressed)
		schedule_vbox.add_child(_btn_schedule_toggle)
		schedule_vbox.move_child(_btn_schedule_toggle, schedule_title.get_index() + 1)
	_schedule_collapsed = true
	if is_instance_valid(_btn_schedule_toggle):
		_btn_schedule_toggle.text = _tr("city_map.c.schedule.toggle_context", "Schedule: context only")

	for child in schedule_list.get_children():
		child.queue_free()
	_schedule_rows.clear()

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		if not edge.has("schedule"):
			continue
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.clip_text = false
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		schedule_list.add_child(row)
		_schedule_rows.append({
			"label": row,
			"edge": edge.duplicate(true)
		})
	_apply_schedule_typography(_is_compact_schedule_mode())
	refresh_schedule_ui()

func _on_schedule_toggle_pressed() -> void:
	_schedule_collapsed = not _schedule_collapsed
	if _schedule_collapsed:
		_btn_schedule_toggle.text = _tr("city_map.c.schedule.toggle_context", "Schedule: context only")
	else:
		_btn_schedule_toggle.text = _tr("city_map.c.schedule.toggle_all", "Schedule: show all")
		schedule_panel_open_count += 1
	refresh_schedule_ui()

func _is_compact_schedule_mode() -> bool:
	var viewport: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport.x >= viewport.y
	return (is_landscape and viewport.y <= 760.0) or ((not is_landscape) and viewport.x <= 480.0)

func _apply_schedule_typography(compact: bool) -> void:
	var font_size: int = 13 if compact else 16
	for row_var in _schedule_rows:
		var row: Dictionary = row_var
		var row_label: Label = row.get("label", null) as Label
		if row_label == null:
			continue
		row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_label.clip_text = false
		row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_label.add_theme_font_size_override("font_size", font_size)

func update_conditions_panel() -> void:
	var conditions_text: String = _build_objective_text()
	constraint_info_label.text = conditions_text
	briefing_constraint.text = conditions_text
	constraint_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _schedule_sort_key(row: Dictionary) -> Array[int]:
	var edge: Dictionary = row.get("edge", {})
	var runtime := get_edge_runtime_state(edge, sim_time_sec)
	var edge_from := str(edge.get("from", ""))
	var ttc := int(runtime.get("time_to_change", -1))
	var state_text := str(runtime.get("state", "OPEN"))
	var priority := 4
	if edge_from == current_node:
		priority = 0
	elif state_text == "DANGER":
		priority = 1
	elif state_text == "CLOSED":
		priority = 2
	elif ttc >= 0:
		priority = 3
	return [priority, 999999 if ttc < 0 else ttc]

func _is_schedule_relevant(edge: Dictionary) -> bool:
	var edge_from := str(edge.get("from", ""))
	var edge_to := str(edge.get("to", ""))
	return edge_from == current_node or _path_contains_edge(edge_from, edge_to)

func _schedule_row_less(a: Dictionary, b: Dictionary) -> bool:
	var ka := _schedule_sort_key(a)
	var kb := _schedule_sort_key(b)
	if ka[0] != kb[0]:
		return ka[0] < kb[0]
	return ka[1] < kb[1]

func refresh_schedule_ui() -> void:
	var schedule_summary := _build_context_schedule_summary()
	var relevant_count := int(schedule_summary.get("relevant_count", 0))
	if is_instance_valid(schedule_summary_label):
		schedule_summary_label.text = str(schedule_summary.get("text", ""))

	var sorted_rows: Array = _schedule_rows.duplicate()
	sorted_rows.sort_custom(Callable(self, "_schedule_row_less"))

	for index in range(sorted_rows.size()):
		var row_for_order: Dictionary = sorted_rows[index]
		var row_label_for_order: Label = row_for_order.get("label", null) as Label
		if row_label_for_order != null and row_label_for_order.get_parent() == schedule_list:
			schedule_list.move_child(row_label_for_order, index)

	for row_var in sorted_rows:
		var row: Dictionary = row_var
		var row_label: Label = row.get("label", null) as Label
		var edge: Dictionary = row.get("edge", {})
		if row_label == null:
			continue
		var is_relevant_now := _is_schedule_relevant(edge)
		row_label.visible = (not _schedule_collapsed) or is_relevant_now
		if not row_label.visible:
			continue

		var runtime: Dictionary = get_edge_runtime_state(edge, sim_time_sec)
		var parts: Array[String] = []
		for slot_var in edge.get("schedule", []):
			var slot: Dictionary = slot_var
			var from_t: int = int(slot.get("t_from", 0))
			var to_t: int = int(slot.get("t_to", 0))
			var slot_state: String = str(slot.get("state", "open")).to_upper()
			var slot_w_text: String = _tr("city_map.common.state.closed", "CLOSED") if slot_state == "CLOSED" else str(int(slot.get("w", edge.get("w", 0))))
			var to_text: String = _tr("city_map.c.schedule.infinite", "INF") if to_t >= 999 else str(to_t)
			var slot_text: String = "[%d-%s: %s]" % [from_t, to_text, slot_w_text]
			var is_active: bool = sim_time_sec >= from_t and sim_time_sec < to_t
			if is_active:
				slot_text = _tr("city_map.c.schedule.active_slot", ">>{slot}<<", {"slot": slot_text})
			parts.append(slot_text)

		var edge_from: String = str(edge.get("from", ""))
		var edge_to: String = str(edge.get("to", ""))
		var ttc: int = int(runtime.get("time_to_change", -1))
		var state_text: String = str(runtime.get("state", "OPEN"))
		var state_label: String = state_text
		if state_text == "CLOSED":
			state_label = _tr("city_map.common.state.closed", "CLOSED")
		elif state_text == "DANGER":
			state_label = _tr("city_map.common.state.danger", "DANGER")
		elif state_text == "OPEN":
			state_label = _tr("city_map.common.state.open", "OPEN")
		var base_text: String = _tr(
			"city_map.c.schedule.row",
			"{from}->{to}: {slots} | {state}",
			{"from": edge_from, "to": edge_to, "slots": " ".join(parts), "state": state_label}
		)
		row_label.text = _tr("city_map.c.schedule.row_ttc", "{row} (t-{seconds}s)", {"row": base_text, "seconds": ttc}) if ttc >= 0 else base_text

		var warning_soon: bool = ttc >= 0 and ttc <= 15
		if state_text == "CLOSED":
			row_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32, 1.0))
		elif state_text == "DANGER" or warning_soon:
			row_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.30, 1.0))
		else:
			row_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.94, 1.0))

	if _schedule_collapsed:
		schedule_scroll.visible = relevant_count > 1
	else:
		schedule_scroll.visible = true

func refresh_edge_states() -> void:
	_update_visuals()

func _calculate_min_sum_dynamic() -> int:
	var start_node := str(level_data.get("start_node", ""))
	var end_node := str(level_data.get("end_node", ""))
	if start_node.is_empty() or end_node.is_empty():
		return 0
	return _solver.compute_min_sum_dynamic(adjacency, start_node, end_node, must_visit_nodes, xor_groups, blacklist_nodes, 0, 2)

func _node_in_xor_group(node_id: String) -> bool:
	for group_var in xor_groups:
		var group: Dictionary = group_var
		if str(group.get("type", "")) != "AT_MOST_ONE":
			continue
		for member_var in group.get("nodes", []):
			if str(member_var) == node_id:
				return true
	return false

func _on_graph_resized() -> void:
	if graph_container.size.x <= 0.0 or graph_container.size.y <= 0.0:
		return
	_rebuild_graph_ui()
	_update_visuals()

func _rebuild_graph_ui() -> void:
	for child in edges_layer.get_children():
		child.queue_free()
	for child in nodes_layer.get_children():
		child.queue_free()
	for child in _traffic_layer.get_children():
		child.queue_free()
	_traffic_visuals.clear()
	edge_visuals.clear()
	node_buttons.clear()
	_node_badges.clear()
	_node_positions.clear()

	if graph_container.size.x <= 0.0 or graph_container.size.y <= 0.0:
		return

	_node_positions = _renderer.compute_node_positions(
		node_defs,
		graph_container.size,
		node_radius_px,
		_jitter_map,
		AUTO_FIT_MARGIN_PX
	)

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty() or not node_defs.has(from_id) or not node_defs.has(to_id):
			continue

		var start_pos := _node_screen_pos(node_defs[from_id])
		var end_pos := _node_screen_pos(node_defs[to_id])
		var bend := float(edge.get("bend", 0.0))
		var baked := _renderer.build_edge_points(start_pos, end_pos, bend, 10.0)
		var line := Line2D.new()
		line.width = 4.0
		line.points = baked
		line.gradient = _build_gradient(Color(0.18, 0.22, 0.30, 0.28), Color(0.30, 0.38, 0.52, 0.48))
		edges_layer.add_child(line)

		var arrow := _create_arrow_polygon_from_points(baked)
		edges_layer.add_child(arrow)

		var weight_label := Label.new()
		weight_label.text = str(edge.get("w", 0))
		weight_label.add_theme_font_size_override("font_size", 15)
		weight_label.position = _renderer.edge_label_position(baked, 14.0)
		weight_label.add_theme_color_override("font_color", Color(0.62, 0.74, 0.90))
		edges_layer.add_child(weight_label)

		var timer_label := Label.new()
		timer_label.text = ""
		timer_label.add_theme_font_size_override("font_size", 11)
		timer_label.position = weight_label.position + Vector2(0.0, 16.0)
		timer_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.94))
		edges_layer.add_child(timer_label)

		edge_visuals[_edge_key(from_id, to_id)] = {
			"line": line,
			"arrow": arrow,
			"label": weight_label,
			"weight_label": weight_label,
			"timer_label": timer_label,
			"edge": edge
		}

	var hit_radius := _renderer.minimum_hit_radius(node_radius_px, node_hit_target_px)
	for node_id in node_defs.keys():
		var node: Dictionary = node_defs[node_id]
		var btn := Button.new()
		var base_label := str(node.get("label", node_id))
		var in_xor := _node_in_xor_group(node_id)
		btn.text = base_label
		btn.flat = false
		var diameter := hit_radius * 2.0
		btn.size = Vector2(diameter, diameter)
		btn.position = _node_screen_pos(node) - Vector2(hit_radius, hit_radius)
		btn.set_meta("in_xor", in_xor)
		btn.pressed.connect(_on_node_pressed.bind(node_id))

		var badge_text := ""
		var badge_color := Color(0.82, 0.88, 0.94)
		if blacklist_nodes.has(node_id):
			badge_text = "X"
			badge_color = Color(1.0, 0.44, 0.44)
		elif must_visit_nodes.has(node_id):
			badge_text = "M"
			badge_color = Color(0.98, 0.86, 0.40)
		elif in_xor:
			badge_text = "⊕"
			badge_color = Color(0.64, 0.78, 1.0)
		if not badge_text.is_empty():
			var badge := Label.new()
			badge.text = badge_text
			badge.add_theme_font_size_override("font_size", 11)
			badge.add_theme_color_override("font_color", badge_color)
			badge.position = Vector2(diameter - 14.0, -2.0)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(badge)
			_node_badges[node_id] = badge

		nodes_layer.add_child(btn)
		node_buttons[node_id] = btn

	_animate_graph_fit()

func _edge_label_pos(start_pos: Vector2, end_pos: Vector2) -> Vector2:
	var dir := (end_pos - start_pos).normalized()
	var normal := Vector2(-dir.y, dir.x)
	return ((start_pos + end_pos) * 0.5) + (normal * 12.0) - Vector2(10.0, 10.0)

func _create_arrow_polygon_from_points(points: PackedVector2Array) -> Polygon2D:
	if points.size() < 2:
		points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT])
	var tip := points[points.size() - 1]
	var prev := points[maxi(0, points.size() - 2)]
	var dir := (tip - prev).normalized()
	if dir.length() <= 0.0001:
		dir = Vector2.RIGHT
	tip -= dir * (node_radius_px + 4.0)
	var base := tip - dir * ARROW_LEN
	var side_len := ARROW_LEN * 0.65

	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		tip,
		base + dir.rotated(ARROW_ANGLE_RAD) * side_len,
		base + dir.rotated(-ARROW_ANGLE_RAD) * side_len
	])
	polygon.color = Color(0.45, 0.66, 0.96, 0.95)
	return polygon

func _build_gradient(start_color: Color, end_color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, start_color)
	gradient.set_color(1, end_color)
	return gradient

func _node_screen_pos(node_data: Dictionary) -> Vector2:
	var node_id := str(node_data.get("id", ""))
	if _node_positions.has(node_id):
		return _node_positions[node_id]

	var pos: Dictionary = node_data.get("pos", {})
	var x := float(pos.get("x", 0.0))
	var y := float(pos.get("y", 0.0))

	if x >= 0.0 and x <= 1.0 and y >= 0.0 and y <= 1.0:
		var padding := node_radius_px + 4.0
		var usable := graph_container.size - Vector2(padding * 2.0, padding * 2.0)
		usable.x = maxf(1.0, usable.x)
		usable.y = maxf(1.0, usable.y)
		var p := Vector2(padding + x * usable.x, padding + y * usable.y)
		if _jitter_map.has(node_id):
			p += _jitter_map[node_id]
		return p

	var p_abs := Vector2(x, y)
	if _jitter_map.has(node_id):
		p_abs += _jitter_map[node_id]
	return p_abs

func _animate_graph_fit() -> void:
	if _node_positions.is_empty():
		return
	var fit := _renderer.compute_fit_transform(_node_positions, graph_container.size, AUTO_FIT_MARGIN_PX)
	var target_scale := Vector2(float(fit.get("scale", 1.0)), float(fit.get("scale", 1.0)))
	var target_pos := Vector2(fit.get("offset", Vector2.ZERO))
	for layer in [edges_layer, _traffic_layer, nodes_layer]:
		layer.scale = target_scale
		layer.position = target_pos

func _get_traffic_shader() -> Shader:
	if _traffic_shader != null:
		return _traffic_shader
	_traffic_shader = Shader.new()
	_traffic_shader.code = """
shader_type canvas_item;
uniform float scroll = 0.0;
uniform vec4 tint : source_color = vec4(0.60, 0.86, 1.0, 0.95);

void fragment() {
	vec2 uv = UV;
	uv.x = fract(uv.x + scroll);
	vec4 tex = texture(TEXTURE, uv);
	COLOR = tex * tint;
}
"""
	return _traffic_shader

func _get_traffic_texture() -> Texture2D:
	if _traffic_texture != null:
		return _traffic_texture
	var img := Image.create(16, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(16):
		var alpha := 0.0
		if x % 8 <= 2:
			alpha = 1.0
		for y in range(4):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_traffic_texture = ImageTexture.create_from_image(img)
	return _traffic_texture

func _get_closed_texture() -> Texture2D:
	if _closed_texture != null:
		return _closed_texture
	var img := Image.create(12, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(12):
		var alpha := 0.0
		if x % 4 <= 1:
			alpha = 1.0
		for y in range(4):
			img.set_pixel(x, y, Color(1.0, 0.4, 0.4, alpha))
	_closed_texture = ImageTexture.create_from_image(img)
	return _closed_texture

func _sync_traffic_visuals() -> void:
	var active_edges: Dictionary = {}
	for i in range(path.size() - 1):
		var key := _edge_key(path[i], path[i + 1])
		active_edges[key] = true
		if _traffic_visuals.has(key):
			continue
		if not edge_visuals.has(key):
			continue
		var visual: Dictionary = edge_visuals[key]
		var edge: Dictionary = visual.get("edge", {})
		var line := Line2D.new()
		line.width = 2.5
		line.points = (visual["line"] as Line2D).points
		line.texture = _get_traffic_texture()
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.default_color = Color(1.0, 1.0, 1.0, 0.95)
		var mat := ShaderMaterial.new()
		mat.shader = _get_traffic_shader()
		mat.set_shader_parameter("scroll", 0.0)
		line.material = mat
		_traffic_layer.add_child(line)
		var speed := TRAFFIC_BASE_SPEED / maxf(1.0, float(edge.get("w", 1)))
		_traffic_visuals[key] = {
			"line": line,
			"material": mat,
			"speed": speed,
			"offset": 0.0
		}

	var stale: Array[String] = []
	for key_var in _traffic_visuals.keys():
		var key := str(key_var)
		if active_edges.has(key):
			var tv: Dictionary = _traffic_visuals[key]
			if edge_visuals.has(key):
				(tv["line"] as Line2D).points = (edge_visuals[key]["line"] as Line2D).points
			_traffic_visuals[key] = tv
			continue
		stale.append(key)

	for stale_key in stale:
		var entry: Dictionary = _traffic_visuals[stale_key]
		(entry["line"] as Line2D).queue_free()
		_traffic_visuals.erase(stale_key)

func _reset_round_state(full_reset: bool) -> void:
	current_node = str(level_data.get("start_node", "A"))
	path = [current_node]
	path_sum = 0
	edge_step_count = 0
	_last_step_cost = 0
	_route_committed_for_input = false
	_review_phase_active = false
	_status_override_until_ms = 0
	step_weights.clear()
	sim_time_sec = 0
	backtrack_count = 0
	cycle_events = 0
	cycle_detected = false
	constraint_violations = 0
	closed_edge_attempts = 0
	ambush_hits = 0
	xor_violation = false
	dynamic_weight_awareness = true
	first_attempt_edge = ""
	first_action_ms = -1
	planning_time_ms = 0
	_suppress_sum_input_telemetry = true
	sum_input.clear()
	_suppress_sum_input_telemetry = false
	_clear_status_i18n()
	_last_reveal = {}
	_last_review_had_hint = false
	_warning_active = false
	_last_warning_text = ""
	if is_instance_valid(_reveal_label):
		_reveal_label.text = ""
	_undo_stack.clear()
	_last_move_ms = Time.get_ticks_msec()

	if full_reset:
		level_started_ms = Time.get_ticks_msec()
		real_time_sec = 0
		phase_time_ms = {"1": 0, "2": 0, "3": 0, "4": 0}
		_phase_started_ms = Time.get_ticks_msec()
	_set_phase(PHASE_BUILD, true)

	update_conditions_panel()
	_update_visuals()

func _update_visuals() -> void:
	var end_node := str(level_data.get("end_node", "L"))
	var at_finish := current_node == end_node
	if stage_completed or _review_phase_active:
		_set_phase(PHASE_REVIEW)
	elif at_finish and _route_committed_for_input:
		_set_phase(PHASE_INPUT)
	elif at_finish:
		_set_phase(PHASE_RULES)
	else:
		_set_phase(PHASE_BUILD)

	path_display.text = _tr("city_map.common.input.path", "PATH: {path}", {"path": _route_display_text_with_timing()})
	sim_time_label.text = _tr("city_map.c.input.sim_time", "SIM: {value}", {"value": sim_time_sec})
	sum_live_label.text = _tr(
		"city_map.c.input.last_step",
		"Last step: {step}s | Sim-time: {sim}",
		{"step": _last_step_cost, "sim": sim_time_sec}
	)
	constraint_info_label.text = _build_objective_text()
	update_warnings_panel()
	_refresh_status_guidance()

	for node_id in node_buttons.keys():
		var btn: Button = node_buttons[node_id]
		var is_current: bool = node_id == current_node
		var is_available := false
		var in_xor_group := btn.has_meta("in_xor") and bool(btn.get_meta("in_xor"))
		if adjacency.has(current_node) and adjacency[current_node].has(node_id):
			var runtime_to_node := get_edge_runtime_state(adjacency[current_node][node_id], sim_time_sec)
			is_available = str(runtime_to_node.get("state", "OPEN")) != "CLOSED"
		btn.disabled = is_current or _is_round_locked()
		if is_current:
			btn.modulate = Color(0.95, 0.86, 0.45)
		elif blacklist_nodes.has(node_id):
			btn.modulate = Color(0.90, 0.40, 0.40)
		elif must_visit_nodes.has(node_id) and not path.has(node_id):
			btn.modulate = Color(0.92, 0.86, 0.32)
		elif in_xor_group and is_available:
			btn.modulate = Color(0.80, 0.88, 1.0)
		elif in_xor_group:
			btn.modulate = Color(0.50, 0.56, 0.70)
		elif is_available:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.42, 0.46, 0.56)

	for key in edge_visuals.keys():
		var visual: Dictionary = edge_visuals[key]
		var edge: Dictionary = visual.edge
		var runtime := get_edge_runtime_state(edge, sim_time_sec)
		var is_available: bool = (
			str(edge.get("from", "")) == current_node
			and adjacency.has(current_node)
			and adjacency[current_node].has(str(edge.get("to", "")))
			and str(runtime.get("state", "OPEN")) != "CLOSED"
		)
		var is_traversed: bool = _path_contains_edge(str(edge.get("from", "")), str(edge.get("to", "")))
		var time_to_change := int(runtime.get("time_to_change", -1))
		var closing_soon := str(runtime.get("state", "OPEN")) != "CLOSED" and time_to_change >= 0 and time_to_change < 15

		var state := "dim"
		if is_traversed:
			state = "traversed"
		elif str(runtime.get("state", "OPEN")) == "CLOSED":
			state = "closed"
		elif str(runtime.get("state", "OPEN")) == "DANGER" or closing_soon:
			state = "danger"
		elif is_available:
			state = "available"

		_apply_edge_style(key, state, runtime)
		if str(runtime.get("state", "OPEN")) == "DANGER":
			_danger_edges_seen[key] = true
		if str(runtime.get("state", "OPEN")) == "CLOSED":
			_closed_edges_seen[key] = true

	refresh_schedule_ui()
	_sync_phase_visibility()
	_sync_traffic_visuals()

func update_warnings_panel() -> void:
	var warning_text := _build_warning_text()
	_warning_active = not warning_text.is_empty()
	if warning_text != _last_warning_text:
		_last_warning_text = warning_text
		if _warning_active:
			_log_event("warning_shown", {"warning": warning_text})
	warning_label.text = warning_text
	warning_label.visible = _warning_active

func _apply_edge_style(key: String, state: String, runtime: Dictionary) -> void:
	if not edge_visuals.has(key):
		return
	var visual: Dictionary = edge_visuals[key]
	var line: Line2D = visual.line
	var arrow: Polygon2D = visual.arrow
	var weight_label: Label = visual.get("weight_label", visual.get("label", null)) as Label
	var timer_label: Label = visual.get("timer_label", null) as Label

	var start_color := Color(0.18, 0.22, 0.30, 0.28)
	var end_color := Color(0.30, 0.38, 0.52, 0.48)
	var label_text := str(runtime.get("weight", 0))
	var timer_text := ""
	line.width = 3.6

	match state:
		"available":
			start_color = Color(0.24, 0.40, 0.62, 0.48)
			end_color = accent_color
			end_color.a = 0.95
			line.texture = null
			line.width = 4.0
		"traversed":
			start_color = accent_color.lightened(0.10)
			start_color.a = 0.80
			end_color = Color(0.92, 0.97, 1.0, 1.0)
			line.texture = null
			line.width = 5.0
		"closed":
			start_color = Color(0.58, 0.14, 0.14, 0.55)
			end_color = Color(1.0, 0.25, 0.25, 1.0)
			timer_text = _tr("city_map.common.state.closed", "CLOSED")
			line.texture = _get_closed_texture()
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			line.width = 4.8
		"danger":
			start_color = Color(0.62, 0.35, 0.12, 0.60)
			end_color = Color(1.0, 0.62, 0.18, 1.0)
			line.texture = null
			line.width = 5.2
		_:
			line.texture = null

	var time_to_change := int(runtime.get("time_to_change", runtime.get("next_change_sec", -1)))
	if time_to_change >= 0 and state != "closed":
		timer_text = _tr("city_map.c.edge.timer", "t-{seconds}", {"seconds": time_to_change})
	if state == "danger" and time_to_change >= 0 and time_to_change < 15:
		var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 120.0)
		end_color = end_color.lerp(Color(1.0, 0.24, 0.24, 1.0), pulse * 0.6)

	line.gradient = _build_gradient(start_color, end_color)
	arrow.color = end_color
	if is_instance_valid(weight_label):
		weight_label.text = label_text
		weight_label.add_theme_color_override("font_color", end_color.lightened(0.10))
	if is_instance_valid(timer_label):
		timer_label.text = timer_text
		timer_label.visible = not timer_text.is_empty()
		timer_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.66) if state == "danger" else end_color.lightened(0.04))

func _path_contains_edge(from_id: String, to_id: String) -> bool:
	for i in range(path.size() - 1):
		if path[i] == from_id and path[i + 1] == to_id:
			return true
	return false

func _edge_key(from_id: String, to_id: String) -> String:
	return "%s->%s" % [from_id, to_id]

func _edge_runtime_state(edge: Dictionary, time_sec: int) -> Dictionary:
	var base_weight := int(edge.get("w", 0))
	var active_weight := base_weight
	var active_state := "open"
	var next_change_sec := -1

	if edge.has("schedule"):
		for slot_var in edge.schedule:
			var slot: Dictionary = slot_var
			var from_t := int(slot.get("t_from", 0))
			var to_t := int(slot.get("t_to", 0))
			if time_sec >= from_t and time_sec < to_t:
				active_state = str(slot.get("state", "open"))
				active_weight = int(slot.get("w", base_weight))
				next_change_sec = max(0, to_t - time_sec)
				break
			if time_sec < from_t:
				var delta := from_t - time_sec
				if next_change_sec < 0 or delta < next_change_sec:
					next_change_sec = delta

	return {
		"weight": active_weight,
		"state": active_state,
		"danger": active_state != "closed" and active_weight > base_weight,
		"next_change_sec": next_change_sec
	}

func get_edge_runtime_state(edge: Dictionary, time_sec: int) -> Dictionary:
	var raw_runtime: Dictionary = _edge_runtime_state(edge, time_sec)
	var state_raw: String = str(raw_runtime.get("state", "open")).to_lower()
	var time_to_change: int = int(raw_runtime.get("next_change_sec", -1))
	var state: String = "OPEN"
	if state_raw == "closed":
		state = "CLOSED"
	elif bool(raw_runtime.get("danger", false)) or (time_to_change >= 0 and time_to_change <= 15):
		state = "DANGER"

	return {
		"state": state,
		"w": int(raw_runtime.get("weight", edge.get("w", 0))),
		"time_to_change": time_to_change,
		"danger": state == "DANGER",
		"next_change_sec": time_to_change,
		"weight": int(raw_runtime.get("weight", edge.get("w", 0)))
	}

func _on_node_pressed(node_id: String) -> void:
	if _is_round_locked():
		return
	if not adjacency.has(current_node) or not adjacency[current_node].has(node_id):
		_log_event("invalid_step_attempt", {"from": current_node, "to": node_id, "path_len": path.size()})
		_set_status_i18n(
			"city_map.c.status.invalid_move",
			"Cannot move: this transition is not available from current node.",
			Color(1.0, 0.65, 0.35)
		)
		return

	var now_ms := Time.get_ticks_msec()
	if _last_move_ms > 0:
		think_time_before_move_ms.append(now_ms - _last_move_ms)
	_last_move_ms = now_ms
	_mark_change_after_feedback()
	_push_undo_snapshot()
	last_edit_ms = _elapsed_ms_now()

	if first_attempt_edge.is_empty():
		first_attempt_edge = _edge_key(current_node, node_id)
		first_action_ms = now_ms - level_started_ms
		planning_time_ms = first_action_ms
	if time_to_first_step_ms < 0:
		time_to_first_step_ms = _elapsed_ms_now()

	var from_node := current_node
	var is_backtrack: bool = path.size() >= 2 and path[path.size() - 2] == node_id
	if is_backtrack:
		backtrack_count += 1
	var is_cycle_revisit: bool = path.has(node_id) and (not is_backtrack or path.size() > 2)
	if is_cycle_revisit:
		cycle_events += 1
		cycle_detected = true

	var edge: Dictionary = adjacency[current_node][node_id]
	var runtime := get_edge_runtime_state(edge, sim_time_sec)
	if str(runtime.get("state", "OPEN")) == "CLOSED":
		closed_edge_attempts += 1
		closed_edge_attempt_count += 1
		n_closed += 1
		dynamic_weight_awareness = false
		_log_event("closed_edge_attempted", {
			"from": from_node,
			"to": node_id,
			"sim_time_sec": sim_time_sec,
			"closed_edge_attempt_count": closed_edge_attempt_count
		})
		_set_status_i18n(
			"city_map.c.status.closed_edge",
			"Closed edge: movement blocked. Try WAIT or pick another open branch.",
			Color(1.0, 0.35, 0.35)
		)
		_recalculate_stability()
		_update_visuals()
		return

	if bool(runtime.get("danger", false)):
		dynamic_weight_awareness = false
		danger_edge_count_local += 1
		_log_event("danger_edge_used", {
			"from": from_node,
			"to": node_id,
			"sim_time_sec": sim_time_sec,
			"danger_edge_count": danger_edge_count_local
		})

	var edge_weight: int = int(runtime.get("w", 0))
	_last_step_cost = edge_weight
	path_sum += edge_weight
	step_weights.append(edge_weight)
	sim_time_sec += edge_weight
	path.append(node_id)
	current_node = node_id
	node_select_count += 1
	edge_step_count = maxi(0, path.size() - 1)
	_log_event("route_step_added", {
		"from": from_node,
		"to": node_id,
		"path_len": path.size(),
		"current_node": current_node,
		"sim_time_sec": sim_time_sec
	})
	_route_committed_for_input = false
	_review_phase_active = false
	_last_reveal = {}
	_last_review_had_hint = false
	if is_instance_valid(_reveal_label):
		_reveal_label.text = ""
	if path.size() == 2:
		_set_dossier_open(false)

	if blacklist_nodes.has(node_id):
		ambush_hits += 1
		blacklist_violation_count += 1
		constraint_violations += 1
		_log_event("blacklist_violation", {
			"node": node_id,
			"count": blacklist_violation_count
		})
		_set_status_i18n(
			"city_map.c.status.ambush",
			"AMBUSH: entered a blacklist node",
			Color(1.0, 0.42, 0.30)
		)

	if _is_xor_violation(path):
		xor_violation_count += 1
		_log_event("xor_violation", {"count": xor_violation_count, "path": path.duplicate()})
		if not xor_violation:
			xor_violation = true
			n_logic += 1
			constraint_violations += 1
			_set_status_i18n(
				"city_map.c.status.xor_violation",
				"XOR VIOLATION: at most one node allowed in the group",
				Color(1.0, 0.62, 0.18)
			)

	_recalculate_stability()
	_update_visuals()

func _on_reset_pressed() -> void:
	if _is_round_locked():
		return
	_mark_change_after_feedback()
	n_reset += 1
	reset_count_local += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("reset_pressed", {"path_before": path.duplicate(), "current_node_before": current_node})
	_reset_round_state(false)
	_recalculate_stability()

func _on_back_pressed() -> void:
	_request_back_navigation("pressed")

func _on_back_button_down() -> void:
	_request_back_navigation("button_down")

func _on_back_gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_request_back_navigation("gui_input")

func _request_back_navigation(_source: String) -> void:
	if _is_leaving_scene:
		return
	_is_leaving_scene = true
	call_deferred("_commit_back_navigation")

func _commit_back_navigation() -> void:
	var err: Error = get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
	if err != OK:
		_is_leaving_scene = false
		push_error("CityMapQuestC: failed to navigate to QuestSelect, err=%d" % int(err))

func _on_sum_input_changed(new_text: String) -> void:
	var digits := ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits != new_text:
		sum_input.text = digits
		sum_input.caret_column = digits.length()
		return
	if _suppress_sum_input_telemetry:
		return
	last_edit_ms = _elapsed_ms_now()
	_mark_change_after_feedback()
	_log_event("sum_input_changed", {"value": digits, "len": digits.length()})

func _on_submit_pressed() -> void:
	if _is_round_locked():
		return
	if round_phase == PHASE_BUILD:
		return
	var end_node := str(level_data.get("end_node", "L"))
	if current_node != end_node:
		_set_status_i18n(
			"city_map.c.result.err_incomplete",
			"Reach node L before check.",
			Color(1.0, 0.62, 0.28)
		)
		_set_phase(PHASE_BUILD)
		return

	if round_phase == PHASE_RULES:
		_route_committed_for_input = true
		_review_phase_active = false
		_suppress_sum_input_telemetry = true
		sum_input.clear()
		_suppress_sum_input_telemetry = false
		_log_event("route_committed_for_input", {"path": path.duplicate(), "sim_time_sec": sim_time_sec})
		_set_status_i18n(
			"city_map.c.status.to_input",
			"Route committed. Enter total sum.",
			Color(0.82, 0.90, 1.0)
		)
		_set_phase(PHASE_INPUT)
		_update_visuals()
		return

	if round_phase != PHASE_INPUT:
		return

	submit_attempt_count += 1
	if time_to_first_submit_ms < 0:
		time_to_first_submit_ms = _elapsed_ms_now()
	time_from_last_edit_to_submit_ms = -1 if last_edit_ms < 0 else maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("submit_pressed", {
		"path": path.duplicate(),
		"sum_input": sum_input.text.strip_edges(),
		"current_node": current_node,
		"sim_time_sec": sim_time_sec
	})
	_set_dossier_open(false)
	_review_phase_active = true
	_set_phase(PHASE_REVIEW)

	attempt_in_sublevel += 1
	attempt_in_run += 1
	var verdict := _judge_solution(sum_input.text.strip_edges())
	var timeline_value: Variant = verdict.get("timeline", [])
	var timeline: Array = timeline_value if typeof(timeline_value) == TYPE_ARRAY else []
	timeline_step_count = timeline.size()
	_log_event("dynamic_eval_result", {
		"closed_attempts": int(verdict.get("closed_attempts", 0)),
		"danger_steps": int(verdict.get("danger_steps", 0)),
		"timeline_step_count": timeline_step_count,
		"sim_end": int(verdict.get("dynamic_sim_end", sim_time_sec))
	})
	_last_reveal = verdict
	_log_event("submit_result", {
		"result_code": str(verdict.get("result_code", "ERR_UNKNOWN")),
		"route_valid": bool(verdict.get("route_valid", false)),
		"finish_reached": bool(verdict.get("finish_reached", false)),
		"calc_ok": bool(verdict.get("calc_ok", false)),
		"dynamic_ok": bool(verdict.get("dynamic_ok", false)),
		"blacklist_ok": bool(verdict.get("blacklist_ok", false)),
		"xor_ok": bool(verdict.get("xor_ok", false)),
		"optimal_ok": bool(verdict.get("optimal_ok", false)),
		"closed_attempts": int(verdict.get("closed_attempts", 0)),
		"danger_steps": int(verdict.get("danger_steps", 0))
	})
	_log_attempt(verdict)
	if is_instance_valid(_reveal_label):
		_reveal_label.text = _build_review_text(verdict)

	if verdict.result_code == "OK":
		_set_status_i18n(
			"city_map.c.status.success",
			"Route accepted. Dynamic constraints are respected.",
			Color(0.38, 1.0, 0.62)
		)
		stage_completed = true
		levels_completed += 1
		run_total_time_seconds += real_time_sec
		run_total_calc_errors += n_calc
		run_total_opt_errors += n_opt
		run_total_parse_errors += n_parse
		run_total_reset_errors += n_reset
		run_total_transit_errors += n_transit
		run_total_logic_errors += n_logic
		run_total_closed_errors += n_closed
		run_total_ambush_hits += ambush_hits
		if attempt_in_sublevel == 1:
			levels_perfect += 1
		btn_next.visible = true
		btn_next.disabled = false
		_lock_input(true)
		_set_progress_ui()
		return

	var result_code: String = str(verdict.result_code)
	var result_meta: Dictionary = _result_message_meta(result_code)
	_set_status_i18n(
		str(result_meta.get("key", "city_map.common.result.unhandled")),
		str(result_meta.get("default", "Unhandled result code: {code}")),
		Color(1.0, 0.62, 0.28),
		result_meta.get("params", {})
	)
	_recalculate_stability()
	_update_visuals()

func _result_message(result_code: String) -> String:
	var meta: Dictionary = _result_message_meta(result_code)
	return _tr(
		str(meta.get("key", "city_map.common.result.unhandled")),
		str(meta.get("default", "Unhandled result code: {code}")),
		meta.get("params", {})
	)

func _result_message_meta(result_code: String) -> Dictionary:
	match result_code:
		"ERR_INCOMPLETE":
			return {"key": "city_map.c.result.err_incomplete", "default": "Reach node L before submit."}
		"ERR_MISSING_TRANSIT":
			return {"key": "city_map.c.result.err_missing_transit", "default": "Constraint not met: visit required transit nodes."}
		"ERR_LOGIC_VIOLATION":
			return {"key": "city_map.c.result.err_logic_violation", "default": "XOR constraint violated."}
		"ERR_AMBUSH":
			return {"key": "city_map.c.result.err_ambush", "default": "A blacklist node has been visited."}
		"ERR_PARSE":
			return {"key": "city_map.common.result.err_parse", "default": "Use digits only."}
		"ERR_CALC":
			return {"key": "city_map.c.result.err_calc", "default": "Entered sum does not match simulated path cost."}
		"ERR_NOT_OPT":
			return {"key": "city_map.common.result.err_not_opt", "default": "Route is valid but not optimal."}
		"ERR_PATH_INVALID":
			return {"key": "city_map.common.result.err_path_invalid", "default": "Route is invalid for directed edges."}
		_:
			return {
				"key": "city_map.common.result.unhandled",
				"default": "Unhandled result code: {code}",
				"params": {"code": result_code}
			}

func _mastery_block_reason(result_code: String, verdict: Dictionary) -> String:
	if wait_action_count >= 8:
		return "EXCESSIVE_WAIT"
	if dynamic_replan_count >= 6 and changed_after_warning:
		return "DYNAMIC_REPLAN_INSTABILITY"
	if result_code != "OK":
		if int(verdict.get("closed_attempts", 0)) > 0 or closed_edge_attempt_count > 0:
			return "CLOSED_EDGE_IGNORED"
		if int(verdict.get("danger_steps", 0)) > 0 or danger_edge_count_local > 0:
			return "DANGER_ROUTE"
		match result_code:
			"ERR_AMBUSH":
				return "BLACKLIST_VIOLATION"
			"ERR_LOGIC_VIOLATION":
				return "XOR_VIOLATION"
			"ERR_NOT_OPT":
				return "NOT_OPTIMAL"
			"ERR_CALC":
				return "ARITHMETIC_ERROR"
			_:
				return "NONE"
	return "NONE"

func _judge_solution(input_text: String) -> Dictionary:
	var sum_actual := _compute_path_sum()
	var dynamic_eval := _solver.simulate_dynamic_path_timeline(path, adjacency, 0)
	var timeline_value: Variant = dynamic_eval.get("timeline", [])
	var timeline: Array = timeline_value if typeof(timeline_value) == TYPE_ARRAY else []
	var dynamic_closed_attempts := int(dynamic_eval.get("closed_attempts", 0))
	var dynamic_danger_steps := int(dynamic_eval.get("danger_steps", 0))
	var sum_input_value: Variant = null
	var result_code := "OK"
	var player_error_step_idx := -1
	var must_ok := _must_visit_ok(path)
	var xor_ok := not _is_xor_violation(path)
	var blacklist_ok := not _path_has_blacklist(path)
	var dynamic_ok := closed_edge_attempts == 0 and dynamic_closed_attempts == 0 and sum_actual >= 0

	if sum_actual < 0:
		result_code = "ERR_PATH_INVALID"
		player_error_step_idx = _solver.first_invalid_step_index(path, adjacency)
	elif current_node != str(level_data.get("end_node", "L")):
		result_code = "ERR_INCOMPLETE"
	elif not must_ok:
		n_transit += 1
		constraint_violations += 1
		result_code = "ERR_MISSING_TRANSIT"
	elif not xor_ok:
		if not xor_violation:
			xor_violation = true
			n_logic += 1
		constraint_violations += 1
		result_code = "ERR_LOGIC_VIOLATION"
	elif not blacklist_ok:
		result_code = "ERR_AMBUSH"
	elif input_regex.search(input_text) == null:
		n_parse += 1
		result_code = "ERR_PARSE"
	else:
		sum_input_value = int(input_text)
		if int(sum_input_value) != sum_actual:
			n_calc += 1
			result_code = "ERR_CALC"
		elif sum_actual != min_sum:
			n_opt += 1
			result_code = "ERR_NOT_OPT"

	var reveal := _solver.build_reveal_payload(
		path,
		result_code,
		sum_actual,
		min_sum,
		str(level_data.get("end_node", "L")),
		sum_input_value,
		must_ok,
		true,
		xor_ok,
		blacklist_ok,
		dynamic_ok,
		player_error_step_idx,
		_best_known_path_preview(),
		min_sum
	)
	reveal["sum_actual"] = sum_actual
	reveal["sum_input"] = sum_input_value
	reveal["sim_time_sec"] = sim_time_sec
	reveal["step_weights"] = step_weights.duplicate()
	reveal["closed_attempts"] = dynamic_closed_attempts
	reveal["danger_steps"] = dynamic_danger_steps
	reveal["timeline"] = timeline.duplicate(true)
	reveal["dynamic_sim_end"] = int(dynamic_eval.get("sim_end", sim_time_sec))
	return reveal

func _compute_path_sum() -> int:
	var total := 0
	for i in range(path.size() - 1):
		var from_id := path[i]
		var to_id := path[i + 1]
		if not adjacency.has(from_id) or not adjacency[from_id].has(to_id):
			return -1
		total += int(step_weights[i]) if i < step_weights.size() else 0
	return total

func _must_visit_ok(path_local: Array) -> bool:
	for node_id in must_visit_nodes:
		if not path_local.has(node_id):
			return false
	return true

func _path_has_blacklist(path_local: Array) -> bool:
	for node_id in blacklist_nodes:
		if path_local.has(node_id):
			return true
	return false

func _is_xor_violation(path_local: Array) -> bool:
	for group_var in xor_groups:
		var group: Dictionary = group_var
		if str(group.get("type", "")) != "AT_MOST_ONE":
			continue
		var count := 0
		for node_id_var in group.get("nodes", []):
			if path_local.has(str(node_id_var)):
				count += 1
		if count > 1:
			return true
	return false

func _recalculate_stability() -> void:
	var trust_cfg: Dictionary = level_data.get("trust", {})
	var overtime_div := int(trust_cfg.get("overtime_div", 2))
	overtime_div = maxi(1, overtime_div)
	var overtime: int = maxi(0, real_time_sec - int(level_data.get("time_limit_sec", 140)))
	var overtime_penalty := int(floor(float(overtime) / float(overtime_div)))

	var penalties := (
		n_calc * int(trust_cfg.get("penalty_calc", 25))
		+ n_opt * int(trust_cfg.get("penalty_opt", 25))
		+ n_parse * int(trust_cfg.get("penalty_parse", 5))
		+ n_reset * maxi(1, int(trust_cfg.get("penalty_reset", 5)) / 2)
		+ n_transit * int(trust_cfg.get("penalty_transit", 25))
		+ n_logic * int(trust_cfg.get("penalty_logic_violation", 30))
		+ n_closed * int(trust_cfg.get("penalty_closed_edge", 8))
		+ maxi(0, undo_count - 1) * 5
		+ overtime_penalty
	)

	var effective := float(trust_cfg.get("initial", 100)) - float(penalties)
	var ambush_multiplier := float(trust_cfg.get("ambush_multiplier", 0.5))
	for _i in range(ambush_hits):
		effective *= ambush_multiplier

	stability = clampf(effective, 0.0, 100.0)
	label_state.text = _tr("city_map.common.status.stability", "STABILITY: {value}%", {"value": int(stability)})

	var fail_threshold := float(trust_cfg.get("fail_threshold", 10))
	if stability <= fail_threshold and not is_game_over:
		is_game_over = true
		stage_completed = false
		_set_status_i18n(
			"city_map.common.status.mission_failed",
			"MISSION FAILED: CRITICAL STABILITY.",
			Color(1.0, 0.30, 0.30)
		)
		btn_next.visible = false
		btn_next.disabled = true
		_lock_input(true)

func _update_timer_display() -> void:
	var time_limit := int(level_data.get("time_limit_sec", 140))
	var remaining: int = maxi(0, time_limit - real_time_sec)
	var mm: int = int(remaining / 60.0)
	var ss: int = remaining % 60
	label_timer.text = _tr("city_map.common.status.time", "TIME: {mm}:{ss}", {"mm": "%02d" % mm, "ss": "%02d" % ss})
	if real_time_sec > time_limit:
		label_timer.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))
	else:
		label_timer.add_theme_color_override("font_color", Color(1, 1, 1))

func _log_attempt(verdict: Dictionary) -> void:
	var sum_actual := int(verdict.get("sum_actual", -1))
	var sum_input_value: Variant = verdict.get("sum_input", null)
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var must_visit_ok := bool(verdict.get("must_visit_ok", false))
	var phase_snapshot: Dictionary = _phase_snapshot_ms()
	var level_entry := _current_level_entry()
	var sublevel_id := str(level_entry.get("id", "6_3_%02d" % (level_index + 1)))
	var sublevel_path := str(level_entry.get("path", ""))
	var next_available := result_code == "OK" and level_index + 1 < level_total
	var first_attempt_edge_value: Variant = null
	if not first_attempt_edge.is_empty():
		first_attempt_edge_value = first_attempt_edge

	var attempt_no := GlobalMetrics.session_history.size() + 1
	var mastery_reason := _mastery_block_reason(result_code, verdict)
	var solver_path_value: Variant = verdict.get("path", path.duplicate())
	var solver_path: Array = solver_path_value if typeof(solver_path_value) == TYPE_ARRAY else path.duplicate()
	var timeline_value: Variant = verdict.get("timeline", [])
	var timeline: Array = timeline_value if typeof(timeline_value) == TYPE_ARRAY else []
	var log_data := {
		"schema_version": "city_map.v2.2.0",
		"quest_id": "CITY_MAP",
		"stage": "C",
		"task_id": str(level_data.get("level_id", "6.3")),
		"level_id": str(level_data.get("level_id", "")),
		"trial_seq": trial_seq,
		"run_id": run_id,
		"pack_id": pack_id,
		"sublevel_index": level_index + 1,
		"sublevel_total": level_total,
		"sublevel_id": sublevel_id,
		"sublevel_path": sublevel_path,
		"attempt_in_sublevel": attempt_in_sublevel,
		"attempt_in_run": attempt_in_run,
		"next_available": next_available,
		"match_key": "CITY_MAP|C|%s|v%s" % [str(level_data.get("level_id", "6.3")), config_hash.substr(0, 8)],
		"variant_hash": config_hash,
		"contract_version": str(level_data.get("contract_version", "city_map.v2.1.0")),
		"attempt_no": attempt_no,
		"result_code": result_code,
		"outcome_code": result_code,
		"mastery_block_reason": mastery_reason,
		"route_valid": bool(verdict.get("route_valid", false)),
		"finish_reached": bool(verdict.get("finish_reached", false)),
		"calc_ok": bool(verdict.get("calc_ok", sum_input_value != null and int(sum_input_value) == sum_actual)),
		"optimal_ok": bool(verdict.get("optimal_ok", sum_actual == min_sum and result_code == "OK" and must_visit_ok and bool(verdict.get("xor_ok", true)) and bool(verdict.get("blacklist_ok", true)))),
		"must_visit_ok": must_visit_ok,
		"xor_ok": bool(verdict.get("xor_ok", true)),
		"blacklist_ok": bool(verdict.get("blacklist_ok", true)),
		"dynamic_ok": bool(verdict.get("dynamic_ok", true)),
		"best_known_cost": int(verdict.get("best_known_cost", min_sum)),
		"player_error_step_idx": int(verdict.get("player_error_step_idx", -1)),
		"first_attempt_edge": first_attempt_edge_value,
		"t_elapsed_seconds": real_time_sec,
		"path": solver_path.duplicate(),
		"sum_actual": sum_actual,
		"sum_input": sum_input_value,
		"min_sum": min_sum,
		"backtrack_count": backtrack_count,
		"cycle_events": cycle_events,
		"constraint_violations": constraint_violations,
		"node_select_count": node_select_count,
		"edge_step_count": edge_step_count,
		"submit_attempt_count": submit_attempt_count,
		"wait_action_count": wait_action_count,
		"reset_count": reset_count_local,
		"undo_count": undo_count_local,
		"closed_edge_attempt_count": closed_edge_attempt_count,
		"danger_edge_count": danger_edge_count_local,
		"blacklist_violation_count": blacklist_violation_count,
		"xor_violation_count": xor_violation_count,
		"dynamic_replan_count": dynamic_replan_count,
		"timeline_step_count": timeline_step_count,
		"changed_after_warning": changed_after_warning,
		"changed_after_review": changed_after_review,
		"time_to_first_step_ms": time_to_first_step_ms,
		"time_to_first_submit_ms": time_to_first_submit_ms,
		"time_to_first_wait_ms": time_to_first_wait_ms,
		"time_from_last_edit_to_submit_ms": time_from_last_edit_to_submit_ms,
		"phase_time_ms": phase_snapshot.duplicate(true),
		"timeline": timeline.duplicate(true),
		"closed_attempts": int(verdict.get("closed_attempts", 0)),
		"danger_steps": int(verdict.get("danger_steps", 0)),
		"analytics_schema_version": _analytics_schema_version,
		"planning_time_ms": planning_time_ms,
		"dynamic_weight_awareness": dynamic_weight_awareness,
		"closed_edge_attempts": closed_edge_attempts,
		"ambush_hits": ambush_hits,
		"xor_violation": xor_violation,
		"sim_time_sec": sim_time_sec,
		"stability_final": int(stability),
		"n_calc": n_calc,
		"n_opt": n_opt,
		"n_parse": n_parse,
		"n_reset": n_reset,
		"n_transit": n_transit,
		"n_logic": n_logic,
		"n_closed": n_closed,
		"wait_count": wait_count,
		"wait_total_sim_sec": wait_total_sim_sec,
		"schedule_panel_open_count": schedule_panel_open_count,
		"danger_edges_seen_count": _danger_edges_seen.size(),
		"closed_edges_seen_count": _closed_edges_seen.size(),
		"dossier_open_count": dossier_open_count,
		"time_dossier_open_ms": time_dossier_open_ms,
		"help_open_count": dossier_open_count,
		"numpad_input_count": numpad_input_count,
		"backspace_count": backspace_count,
		"hint_count": _hint_count,
		"phase_build_ms": int(phase_snapshot.get("1", 0)),
		"phase_rules_ms": int(phase_snapshot.get("2", 0)),
		"phase_input_ms": int(phase_snapshot.get("3", 0)),
		"phase_review_ms": int(phase_snapshot.get("4", 0)),
		"think_time_before_move_ms": think_time_before_move_ms.duplicate(),
		"task_session": task_session.duplicate(true),
		"is_correct": result_code == "OK",
		"is_fit": result_code == "OK",
		"stability_delta": 0,
		"elapsed_ms": real_time_sec * 1000,
		"duration": float(real_time_sec),
		"time_to_first_action_ms": first_action_ms if first_action_ms >= 0 else real_time_sec * 1000,
		"error_type": "NONE" if result_code == "OK" else result_code
	}

	GlobalMetrics.register_trial(log_data)
	_save_json_log(log_data)

func _save_json_log(data: Dictionary, is_summary: bool = false) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var stamp_msec: int = Time.get_ticks_msec()
	var attempt_tag := ""
	if data.has("attempt_in_run"):
		attempt_tag = "_a%s" % str(data.get("attempt_in_run"))

	var filename := "user://research_logs/%s_%s_%d%s.json" % [LOG_PREFIX, run_id, stamp_msec, attempt_tag]
	if is_summary:
		filename = "user://research_logs/%s_run_%s_%d.json" % [LOG_PREFIX, run_id, stamp_msec]
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
