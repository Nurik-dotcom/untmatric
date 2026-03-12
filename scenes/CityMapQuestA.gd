extends Control

const PACK_PATH := "res://data/city_map/pack_6_1_A.json"
const LOG_PREFIX := "case_6_1"
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
@onready var content_split: SplitContainer = $SafeArea/MainVBox/ContentSplit
@onready var graph_panel: PanelContainer = $SafeArea/MainVBox/ContentSplit/GraphPanel
@onready var info_panel: PanelContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel
@onready var graph_container: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer
@onready var edges_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/EdgesLayer
@onready var nodes_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/NodesLayer
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var label_case: Label = $SafeArea/MainVBox/Header/LabelCase
@onready var label_mode: Label = $SafeArea/MainVBox/Header/LabelMode
@onready var label_progress: Label = $SafeArea/MainVBox/Header/LabelProgress
@onready var btn_reset: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnReset
@onready var btn_submit: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnNext
@onready var buttons_row: HBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow
@onready var info_vbox: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox
@onready var sum_input: LineEdit = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumInput
@onready var path_display: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/PathDisplay
@onready var sum_live_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumLiveLabel
@onready var input_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/InputLabel
@onready var status_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/StatusLabel
@onready var label_state: Label = $SafeArea/MainVBox/Header/LabelState
@onready var label_timer: Label = $SafeArea/MainVBox/Header/LabelTimer
@onready var footer_row: HBoxContainer = $SafeArea/MainVBox/Footer
@onready var footer_label: Label = $SafeArea/MainVBox/Footer/FooterLabel
@onready var footer_meta: Label = $SafeArea/MainVBox/Footer/FooterMeta
@onready var briefing_card: PanelContainer = $SafeArea/MainVBox/BriefingCard
@onready var briefing_title: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingTitle
@onready var briefing_text: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingText

var level_data: Dictionary = {}
var pack_data: Dictionary = {}
var pack_levels: Array = []
var node_defs: Dictionary = {}
var adjacency: Dictionary = {}
var edge_visuals: Dictionary = {}
var node_buttons: Dictionary = {}
var config_hash: String = ""
var input_regex := RegEx.new()
var pack_id: String = "CITY_MAP_A_PACK_01"
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
var run_total_resets: int = 0

var min_sum: int = 0
var accent_color: Color = DEFAULT_ACCENT
var node_radius_px: float = 25.0
var node_hit_target_px: float = 48.0

var current_node: String = ""
var path: Array[String] = []
var path_sum: int = 0
var stability: float = 100.0
var t_elapsed_seconds: int = 0
var is_game_over: bool = false
var stage_completed: bool = false
var input_locked: bool = false
var first_attempt_edge: String = ""
var level_started_ms: int = 0
var first_action_ms: int = -1
var round_phase: int = PHASE_BUILD
var phase_time_ms: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0}

var trial_seq: int = 0
var task_session: Dictionary = {}

var node_select_count: int = 0
var edge_step_count: int = 0
var undo_count_local: int = 0
var reset_count_local: int = 0
var submit_attempt_count: int = 0
var invalid_step_preview_count: int = 0

var route_change_count: int = 0
var path_peak_len: int = 0
var unique_nodes_visited: Dictionary = {}
var revisit_count: int = 0

var sum_input_edit_count: int = 0
var sum_input_clear_count: int = 0

var details_open_count: int = 0
var hint_open_count: int = 0
var changed_after_review: bool = false
var changed_after_hint: bool = false

var time_to_first_step_ms: int = -1
var time_to_first_submit_ms: int = -1
var time_to_first_input_ms: int = -1
var time_from_last_edit_to_submit_ms: int = -1
var last_edit_ms: int = -1

var n_calc: int = 0
var n_opt: int = 0
var n_parse: int = 0
var n_reset: int = 0
var undo_count: int = 0
var numpad_input_count: int = 0
var backspace_count: int = 0
var dossier_open_count: int = 0
var time_dossier_open_ms: int = 0
var wait_count: int = 0
var wait_total_sim_sec: int = 0
var think_time_before_move_ms: Array[int] = []

var _last_move_ms: int = 0
var _dossier_open_started_ms: int = -1
var _jitter_map: Dictionary = {}
var _node_positions: Dictionary = {}
var _traffic_visuals: Dictionary = {}
var _undo_stack: Array[Dictionary] = []
var _renderer = preload("res://scripts/city_map/GraphRenderer.gd").new()

var _traffic_layer: Control
var _btn_help: Button
var _btn_undo: Button
var _numpad_panel: PanelContainer
var _numpad_grid: GridContainer
var _info_scroll: ScrollContainer
var _numpad_buttons: Array[Button] = []
var _traffic_shader: Shader
var _traffic_texture: Texture2D
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
var _phase_label: Label
var _reveal_label: Label
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
	label_mode.text = _tr("city_map.a.header.mode", "MODE: A")
	if is_instance_valid(_btn_help):
		_btn_help.tooltip_text = _tr("city_map.common.tooltip.dossier", "DOSSIER")
	if is_instance_valid(_btn_undo):
		_btn_undo.text = _tr("city_map.common.btn.undo_step", "UNDO STEP")
	btn_reset.text = _tr("city_map.common.btn.reset_route", "RESET ROUTE")
	btn_submit.text = _tr("city_map.common.btn.check", "CHECK")
	input_label.text = _tr("city_map.common.input.enter_sum", "Enter route sum")
	footer_meta.text = _tr("city_map.a.footer.meta", "CITY MAP / A")
	_set_progress_ui()
	_set_briefing()
	_update_visuals()
	_update_timer_display()
	if is_instance_valid(_phase_label):
		_phase_label.text = _phase_text()
	if not _status_i18n_key.is_empty():
		_set_status_i18n(_status_i18n_key, _status_i18n_default, _status_i18n_color, _status_i18n_params)

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

	_phase_label = Label.new()
	_phase_label.name = "PhaseLabelRuntime"
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phase_label.add_theme_font_size_override("font_size", 14)
	_phase_label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 0.95))
	info_vbox.add_child(_phase_label)
	info_vbox.move_child(_phase_label, 0)

	_numpad_panel = PanelContainer.new()
	_numpad_panel.name = "NumpadPanel"
	_numpad_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(_numpad_panel)
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
	info_vbox.move_child(_numpad_panel, info_vbox.get_child_count() - 2)

	_reveal_label = Label.new()
	_reveal_label.name = "RevealLabelRuntime"
	_reveal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_reveal_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.70, 1.0))
	info_vbox.add_child(_reveal_label)
	info_vbox.move_child(_reveal_label, info_vbox.get_child_count() - 2)

	_traffic_layer = Control.new()
	_traffic_layer.name = "TrafficLayer"
	_traffic_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_traffic_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_container.add_child(_traffic_layer)
	graph_container.move_child(_traffic_layer, nodes_layer.get_index())

	briefing_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	briefing_card.visible = false
	_phase_started_ms = Time.get_ticks_msec()

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

func _set_phase(next_phase: int, force: bool = false) -> void:
	var clamped_phase := clampi(next_phase, PHASE_BUILD, PHASE_REVIEW)
	if not force and round_phase == clamped_phase:
		if is_instance_valid(_phase_label):
			_phase_label.text = _phase_text()
		return
	var now_ms := Time.get_ticks_msec()
	if _phase_started_ms > 0:
		var current_key := str(round_phase)
		phase_time_ms[current_key] = int(phase_time_ms.get(current_key, 0)) + maxi(0, now_ms - _phase_started_ms)
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

func _mark_change_after_review_feedback() -> void:
	if _last_reveal.is_empty():
		return
	changed_after_review = true
	if _last_review_had_hint:
		changed_after_hint = true

func _reset_trial_telemetry() -> void:
	task_session = {"events": [], "trial_seq": trial_seq}
	node_select_count = 0
	edge_step_count = 0
	undo_count_local = 0
	reset_count_local = 0
	submit_attempt_count = 0
	invalid_step_preview_count = 0
	route_change_count = 0
	path_peak_len = 0
	unique_nodes_visited.clear()
	revisit_count = 0
	sum_input_edit_count = 0
	sum_input_clear_count = 0
	details_open_count = 0
	hint_open_count = 0
	changed_after_review = false
	changed_after_hint = false
	time_to_first_step_ms = -1
	time_to_first_submit_ms = -1
	time_to_first_input_ms = -1
	time_from_last_edit_to_submit_ms = -1
	last_edit_ms = -1
	_last_review_had_hint = false
	var start_node := str(level_data.get("start_node", "A"))
	if not start_node.is_empty():
		unique_nodes_visited[start_node] = true
	path_peak_len = maxi(path_peak_len, path.size())

func _route_display_text() -> String:
	var tokens: Array[String] = []
	for i in range(path.size()):
		var node_id := str(path[i])
		if i == path.size() - 1:
			tokens.append("[%s]" % node_id)
		else:
			tokens.append(node_id)
	return " -> ".join(tokens)

func _best_known_path_preview() -> Array[String]:
	return _solver.build_best_path_preview(level_data.get("min_path_examples", []))

func _soft_hint_text(result_code: String) -> String:
	if attempt_in_sublevel < 2:
		return ""
	match result_code:
		"ERR_NOT_OPT":
			return _tr("city_map.a.hint.not_opt", "Hint: compare total costs of both branches from the last fork.")
		"ERR_CALC":
			return _tr("city_map.a.hint.calc", "Hint: recalculate the selected edge weights one by one.")
		"ERR_INCOMPLETE":
			return _tr("city_map.a.hint.incomplete", "Hint: the check button unlocks only after you reach the target node.")
		_:
			return _tr("city_map.a.hint.generic", "Hint: shortest path means minimum total weight, not minimum number of steps.")

func _build_review_text(verdict: Dictionary) -> String:
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var step_idx := int(verdict.get("player_error_step_idx", -1))
	var player_cost := int(verdict.get("player_cost", int(verdict.get("sum_actual", -1))))
	var best_cost := int(verdict.get("best_known_cost", min_sum))
	var route_valid := bool(verdict.get("route_valid", false))
	var finish_reached := bool(verdict.get("finish_reached", false))
	var optimal_ok := bool(verdict.get("optimal_ok", false))

	var happened := ""
	var where := ""
	var revisit := ""
	var keep := ""
	match result_code:
		"OK":
			happened = _tr("city_map.common.review.ok.happened", "What happened: your route is valid and optimal.")
			where = _tr("city_map.common.review.ok.where", "Where: all transitions are valid and the target is reached.")
			revisit = _tr("city_map.common.review.ok.revisit", "Review: keep comparing route sums, not just number of steps.")
			keep = _tr("city_map.common.review.ok.keep", "Still correct: direction, finish, arithmetic, and optimality.")
		"ERR_NOT_OPT":
			happened = _tr("city_map.common.review.not_opt.happened", "What happened: route is valid, but not the minimum.")
			where = _tr("city_map.common.review.not_opt.where", "Where: after the fork, a cheaper continuation exists.")
			revisit = _tr("city_map.common.review.not_opt.revisit", "Review: compare cumulative totals for each branch.")
			keep = _tr("city_map.common.review.not_opt.keep", "Still correct: direction rules are followed and finish is reached.")
		"ERR_CALC":
			happened = _tr("city_map.common.review.calc.happened", "What happened: route is valid, but entered sum is wrong.")
			where = _tr("city_map.common.review.calc.where", "Where: arithmetic stage after route construction.")
			revisit = _tr("city_map.common.review.calc.revisit", "Review: add edge weights in the selected order.")
			keep = _tr("city_map.common.review.calc.keep", "Still correct: route itself is valid.")
		"ERR_INCOMPLETE":
			happened = _tr("city_map.common.review.incomplete.happened", "What happened: target node is not reached yet.")
			where = _tr("city_map.common.review.incomplete.where", "Where: route ended before the finish node.")
			revisit = _tr("city_map.common.review.incomplete.revisit", "Review: continue from the current node to the finish.")
			keep = _tr("city_map.common.review.incomplete.keep", "Still correct: current transitions remain usable.")
		"ERR_PATH_INVALID":
			happened = _tr("city_map.common.review.invalid.happened", "What happened: route has a forbidden transition.")
			where = _tr("city_map.common.review.invalid.where", "Where: invalid step #{step}.", {"step": step_idx if step_idx > 0 else 1})
			revisit = _tr("city_map.common.review.invalid.revisit", "Review: follow only outgoing directed edges.")
			keep = _tr("city_map.common.review.invalid.keep", "Still correct: selected valid parts of the route can be reused.")
		_:
			happened = _tr("city_map.common.review.generic.happened", "What happened: route check failed.")
			where = _tr("city_map.common.review.generic.where", "Where: inspect transitions and total cost.")
			revisit = _tr("city_map.common.review.generic.revisit", "Review: rebuild route and compare total weight.")
			keep = _tr("city_map.common.review.generic.keep", "Still correct: continue from your current idea.")

	var status_line := _tr(
		"city_map.a.review.status",
		"Status: valid={valid}, finish={finish}, optimal={opt}",
		{
			"valid": "yes" if route_valid else "no",
			"finish": "yes" if finish_reached else "no",
			"opt": "yes" if optimal_ok else "no"
		}
	)
	var cost_line := _tr(
		"city_map.a.review.cost",
		"Cost: yours={player}, best={best}",
		{"player": player_cost, "best": best_cost}
	)
	var hint_text := _soft_hint_text(result_code)
	_last_review_had_hint = false
	if not hint_text.is_empty():
		_hint_count += 1
		hint_open_count += 1
		_last_review_had_hint = true
		_log_event("hint_opened", {"result_code": result_code, "hint": hint_text})
		return "%s\n%s\n%s\n%s\n%s\n%s\n%s" % [happened, where, revisit, keep, status_line, cost_line, hint_text]
	return "%s\n%s\n%s\n%s\n%s\n%s" % [happened, where, revisit, keep, status_line, cost_line]

func _on_help_pressed() -> void:
	_set_dossier_open(not briefing_card.visible)

func _set_dossier_open(opened: bool) -> void:
	if briefing_card.visible == opened:
		return
	briefing_card.visible = opened
	if opened:
		dossier_open_count += 1
		details_open_count += 1
		_dossier_open_started_ms = Time.get_ticks_msec()
		_log_event("details_opened", {"opened": true, "count": details_open_count})
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

func _on_undo_pressed() -> void:
	if _is_round_locked() or _undo_stack.is_empty():
		return
	_mark_change_after_review_feedback()
	var snapshot: Dictionary = _undo_stack.pop_back()
	current_node = str(snapshot.get("current_node", current_node))
	path = snapshot.get("path", path).duplicate()
	path_sum = int(snapshot.get("path_sum", path_sum))
	first_attempt_edge = str(snapshot.get("first_attempt_edge", first_attempt_edge))
	first_action_ms = int(snapshot.get("first_action_ms", first_action_ms))
	undo_count += 1
	undo_count_local += 1
	route_change_count += 1
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
		"first_attempt_edge": first_attempt_edge,
		"first_action_ms": first_action_ms
	})

func _start_pack_run() -> void:
	run_started_unix = int(Time.get_unix_time_from_system())
	run_id = "CITYMAP_%s_%d" % ["A", run_started_unix]
	level_index = 0
	attempt_in_run = 0
	levels_completed = 0
	levels_perfect = 0
	run_total_time_seconds = 0
	run_total_calc_errors = 0
	run_total_opt_errors = 0
	run_total_parse_errors = 0
	run_total_resets = 0
	_load_sublevel(level_index)

func _load_pack(pack_path: String) -> void:
	pack_data.clear()
	pack_levels.clear()
	level_total = 0

	var file := FileAccess.open(pack_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open pack data: %s" % pack_path)
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
		level_total = pack_levels.size()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid pack JSON in %s" % pack_path)
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
		level_total = pack_levels.size()
		return

	pack_data = parsed
	pack_id = str(pack_data.get("pack_id", "CITY_MAP_A_PACK_01"))
	var raw_levels: Array = pack_data.get("levels", [])
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_entry: Dictionary = level_var
		if str(level_entry.get("path", "")).is_empty():
			continue
		pack_levels.append(level_entry)

	if pack_levels.is_empty():
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
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
	n_calc = 0
	n_opt = 0
	n_parse = 0
	n_reset = 0
	t_elapsed_seconds = 0
	undo_count = 0
	numpad_input_count = 0
	backspace_count = 0
	dossier_open_count = 0
	time_dossier_open_ms = 0
	wait_count = 0
	wait_total_sim_sec = 0
	_hint_count = 0
	_last_reveal = {}
	_pack_summary_ready = false
	_pack_summary_data = {}
	round_phase = PHASE_BUILD
	phase_time_ms = {"1": 0, "2": 0, "3": 0, "4": 0}
	_phase_started_ms = Time.get_ticks_msec()
	think_time_before_move_ms.clear()
	_last_move_ms = Time.get_ticks_msec()
	_dossier_open_started_ms = -1
	briefing_card.visible = false

	_set_briefing()
	_rebuild_graph_ui()
	_reset_round_state(true)
	trial_seq += 1
	_reset_trial_telemetry()
	_log_event("trial_started", {
		"level_id": str(level_data.get("level_id", "")),
		"start_node": str(level_data.get("start_node", "A")),
		"end_node": str(level_data.get("end_node", "E")),
		"min_sum": int(min_sum)
	})
	_lock_input(false)
	_update_timer_display()
	_recalculate_stability()
	if is_game_over:
		return
	btn_next.visible = false
	btn_next.disabled = true
	_set_progress_ui()
	GlobalMetrics.start_quest(str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))))

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
			"suffix": "" if sub_id.is_empty() else " | " + sub_id
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
	_update_visuals()

func _on_next_pressed() -> void:
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
		"mode": "A",
		"run_id": run_id,
		"pack_id": pack_id,
		"levels_total": level_total,
		"levels_completed": levels_completed,
		"levels_perfect": levels_perfect,
		"total_time_seconds": run_total_time_seconds,
		"total_calc_errors": run_total_calc_errors,
		"total_opt_errors": run_total_opt_errors,
		"total_parse_errors": run_total_parse_errors,
		"total_reset_errors": run_total_resets,
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
	var calc_err := int(summary.get("total_calc_errors", run_total_calc_errors))
	var opt_err := int(summary.get("total_opt_errors", run_total_opt_errors))
	var parse_err := int(summary.get("total_parse_errors", run_total_parse_errors))
	var avg_time := 0.0 if solved <= 0 else float(int(summary.get("total_time_seconds", run_total_time_seconds))) / float(solved)
	var recommendation := _pack_recommendation_text(calc_err, opt_err, parse_err)

	briefing_title.text = _tr("city_map.common.summary.title", "PACK SUMMARY")
	briefing_text.text = _tr(
		"city_map.a.summary.body",
		"Solved: {solved}/{total}\nFirst try: {perfect}\nErrors:\n- Arithmetic: {calc}\n- Optimality: {opt}\n- Input: {parse}\nAverage time: {avg}s",
		{
			"solved": solved,
			"total": total,
			"perfect": perfect,
			"calc": calc_err,
			"opt": opt_err,
			"parse": parse_err,
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

func _pack_recommendation_text(calc_err: int, opt_err: int, parse_err: int) -> String:
	if opt_err >= calc_err and opt_err >= parse_err and opt_err > 0:
		return _tr("city_map.a.summary.reco.opt", "Train branch comparison for shortest path.")
	if calc_err >= parse_err and calc_err > 0:
		return _tr("city_map.a.summary.reco.calc", "Train edge-weight arithmetic on your route.")
	if parse_err > 0:
		return _tr("city_map.a.summary.reco.parse", "Check numeric input format before submit.")
	return _tr("city_map.a.summary.reco.good", "Maintain the same route-check discipline on harder maps.")

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
	var compact_landscape: bool = is_landscape and viewport.y <= 640.0
	if content_split.vertical:
		content_split.split_offset = int(viewport.y * 0.64)
	else:
		var graph_ratio: float = 0.80 if compact_landscape else 0.76
		content_split.split_offset = int(viewport.x * graph_ratio)
	_apply_compact_phone_layout(compact_landscape)

func _apply_compact_phone_layout(compact: bool) -> void:
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
	info_panel.custom_minimum_size = Vector2(188.0 if compact else 248.0, 0.0)
	sum_input.custom_minimum_size.y = 36.0 if compact else 44.0
	status_label.custom_minimum_size.y = 44.0 if compact else 64.0
	if is_instance_valid(_btn_help):
		_btn_help.custom_minimum_size = Vector2(36.0, 36.0) if compact else Vector2(44.0, 44.0)
	if is_instance_valid(_btn_undo):
		_btn_undo.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_reset.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_submit.custom_minimum_size.y = 34.0 if compact else 44.0
	btn_next.custom_minimum_size.y = 34.0 if compact else 44.0
	for np_btn in _numpad_buttons:
		np_btn.custom_minimum_size.y = 30.0 if compact else 44.0
	if is_instance_valid(_numpad_grid):
		_numpad_grid.columns = 6 if compact else 3
	if is_instance_valid(_info_scroll):
		_info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

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
	t_elapsed_seconds += 1
	_update_timer_display()
	if t_elapsed_seconds > int(level_data.get("time_limit_sec", 120)):
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

	for node_var in level_data.get("nodes", []):
		var node: Dictionary = node_var
		node_defs[str(node.get("id", ""))] = node

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue
		if not adjacency.has(from_id):
			adjacency[from_id] = {}
		adjacency[from_id][to_id] = int(edge.get("w", 0))

	input_regex = RegEx.new()
	var regex_pattern := "^[0-9]+$"
	if level_data.has("rules") and level_data.rules.has("input_regex"):
		regex_pattern = str(level_data.rules.input_regex)
	input_regex.compile(regex_pattern)

	min_sum = int(level_data.get("min_sum", -1))
	if min_sum < 0:
		min_sum = _calculate_min_sum()

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
	briefing_title.text = _tr("city_map.a.briefing.title", "ROUTE AUDIT")
	briefing_text.text = _tr(
		"city_map.a.briefing.text",
		"Goal: reach {end} from {start}. Rule: move only along arrows. Task: find the shortest route.",
		{
			"start": str(level_data.get("start_node", "A")),
			"end": str(level_data.get("end_node", "E"))
		}
	)
	footer_label.text = _tr(
		"city_map.a.briefing.footer",
		"Shortest route is the minimum total weight, not the minimum number of steps."
	)

func _calculate_min_sum() -> int:
	var start_node := str(level_data.get("start_node", ""))
	var end_node := str(level_data.get("end_node", ""))
	if start_node.is_empty() or end_node.is_empty():
		return 0
	return _solver.compute_min_sum_basic(node_defs.keys(), adjacency, start_node, end_node)

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

		var label := Label.new()
		label.text = str(edge.get("w", 0))
		label.add_theme_font_size_override("font_size", 15)
		label.position = _renderer.edge_label_position(baked, 14.0)
		label.add_theme_color_override("font_color", Color(0.62, 0.74, 0.90))
		edges_layer.add_child(label)

		var key := _edge_key(from_id, to_id)
		edge_visuals[key] = {
			"line": line,
			"arrow": arrow,
			"label": label,
			"edge": edge
		}

	var hit_radius := _renderer.minimum_hit_radius(node_radius_px, node_hit_target_px)
	for node_id in node_defs.keys():
		var node: Dictionary = node_defs[node_id]
		var btn := Button.new()
		btn.text = str(node.get("label", node_id))
		btn.flat = false
		var diameter := hit_radius * 2.0
		btn.size = Vector2(diameter, diameter)
		btn.position = _node_screen_pos(node) - Vector2(hit_radius, hit_radius)
		btn.pressed.connect(_on_node_pressed.bind(node_id))
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
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	for layer in [edges_layer, _traffic_layer, nodes_layer]:
		tween.parallel().tween_property(layer, "scale", target_scale, 0.3)
		tween.parallel().tween_property(layer, "position", target_pos, 0.3)

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
	_suppress_sum_input_telemetry = true
	sum_input.clear()
	_suppress_sum_input_telemetry = false
	_clear_status_i18n()
	_last_reveal = {}
	_last_review_had_hint = false
	if is_instance_valid(_reveal_label):
		_reveal_label.text = ""
	first_action_ms = -1
	first_attempt_edge = ""
	_undo_stack.clear()
	_last_move_ms = Time.get_ticks_msec()

	if full_reset:
		level_started_ms = Time.get_ticks_msec()
		phase_time_ms = {"1": 0, "2": 0, "3": 0, "4": 0}
		_phase_started_ms = Time.get_ticks_msec()
	_set_phase(PHASE_BUILD, true)

	_update_visuals()

func _update_visuals() -> void:
	var end_node := str(level_data.get("end_node", "E"))
	var at_finish := current_node == end_node
	if stage_completed:
		_set_phase(PHASE_REVIEW)
	elif at_finish and sum_input.text.strip_edges().is_empty():
		_set_phase(PHASE_RULES)
	elif at_finish:
		_set_phase(PHASE_INPUT)
	else:
		_set_phase(PHASE_BUILD)

	path_display.text = _tr("city_map.common.input.path", "PATH: {path}", {"path": _route_display_text()})
	var step_count := maxi(0, path.size() - 1)
	if round_phase == PHASE_REVIEW and not _last_reveal.is_empty():
		sum_live_label.text = _tr(
			"city_map.a.input.sum_after",
			"Route cost: {player} | Best: {best}",
			{
				"player": int(_last_reveal.get("player_cost", path_sum)),
				"best": int(_last_reveal.get("best_known_cost", min_sum))
			}
		)
	else:
		sum_live_label.text = _tr("city_map.a.input.steps", "Steps: {count}", {"count": step_count})

	for node_id in node_buttons.keys():
		var btn: Button = node_buttons[node_id]
		var is_current: bool = node_id == current_node
		var is_available: bool = adjacency.has(current_node) and adjacency[current_node].has(node_id)
		btn.disabled = is_current or _is_round_locked()
		if is_current:
			btn.modulate = Color(0.95, 0.86, 0.45)
		elif is_available:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.42, 0.46, 0.56)

	for key in edge_visuals.keys():
		_set_edge_style(key, "dim")

	if adjacency.has(current_node):
		for next_id in adjacency[current_node].keys():
			_set_edge_style(_edge_key(current_node, str(next_id)), "available")

	for i in range(path.size() - 1):
		_set_edge_style(_edge_key(path[i], path[i + 1]), "traversed")

	_sync_traffic_visuals()
	if is_instance_valid(_btn_undo):
		_btn_undo.disabled = _is_round_locked() or _undo_stack.is_empty()
	btn_submit.disabled = _is_round_locked() or not at_finish
	btn_next.visible = stage_completed
	btn_next.disabled = not stage_completed

func _set_edge_style(key: String, state: String) -> void:
	if not edge_visuals.has(key):
		return

	var visual: Dictionary = edge_visuals[key]
	var line: Line2D = visual["line"]
	var arrow: Polygon2D = visual["arrow"]
	var label: Label = visual["label"]

	var start_color := Color(0.18, 0.22, 0.30, 0.28)
	var end_color := Color(0.30, 0.38, 0.52, 0.48)

	if state == "available":
		start_color = Color(0.24, 0.40, 0.62, 0.48)
		end_color = accent_color
		end_color.a = 0.95
	elif state == "traversed":
		start_color = accent_color.lightened(0.10)
		start_color.a = 0.80
		end_color = Color(0.92, 0.97, 1.0, 1.0)

	line.gradient = _build_gradient(start_color, end_color)
	arrow.color = end_color
	label.add_theme_color_override("font_color", end_color.lightened(0.10))

func _edge_key(from_id: String, to_id: String) -> String:
	return "%s->%s" % [from_id, to_id]

func _on_node_pressed(node_id: String) -> void:
	if _is_round_locked():
		return
	if not adjacency.has(current_node) or not adjacency[current_node].has(node_id):
		var attempted := _edge_key(current_node, node_id)
		invalid_step_preview_count += 1
		_log_event("invalid_step_attempt", {
			"from": current_node,
			"to": node_id,
			"attempted_edge": attempted,
			"path_len": path.size()
		})
		_set_status_i18n(
			"city_map.a.status.wrong_direction",
			"Cannot move: road goes in another direction ({edge}).",
			Color(1.0, 0.65, 0.35),
			{"edge": attempted}
		)
		return

	var now_ms := Time.get_ticks_msec()
	if _last_move_ms > 0:
		think_time_before_move_ms.append(now_ms - _last_move_ms)
	_last_move_ms = now_ms
	_mark_change_after_review_feedback()
	_push_undo_snapshot()

	if first_attempt_edge.is_empty():
		first_attempt_edge = _edge_key(current_node, node_id)
		first_action_ms = now_ms - level_started_ms

	var from_node := current_node
	path_sum += int(adjacency[current_node][node_id])
	path.append(node_id)
	current_node = node_id
	node_select_count += 1
	edge_step_count = maxi(0, path.size() - 1)
	if time_to_first_step_ms < 0:
		time_to_first_step_ms = _elapsed_ms_now()
	path_peak_len = maxi(path_peak_len, path.size())
	if unique_nodes_visited.has(node_id):
		revisit_count += 1
	else:
		unique_nodes_visited[node_id] = true
	route_change_count += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("route_step_added", {
		"from": from_node,
		"to": node_id,
		"path_len": path.size(),
		"current_node": current_node
	})
	_last_reveal = {}
	_last_review_had_hint = false
	if is_instance_valid(_reveal_label):
		_reveal_label.text = ""
	if path.size() == 2:
		_set_dossier_open(false)
	_update_visuals()

func _on_reset_pressed() -> void:
	if _is_round_locked():
		return
	_mark_change_after_review_feedback()
	n_reset += 1
	reset_count_local += 1
	route_change_count += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("reset_pressed", {
		"path_before": path.duplicate(),
		"current_node_before": current_node
	})
	GlobalMetrics.add_mistake("Сброс маршрута: level=%s, current_node=%s, path=%s, path_sum=%d, resets=%d" % [
		str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))),
		current_node,
		" -> ".join(path),
		path_sum,
		n_reset
	])
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
		push_error("CityMapQuestA: failed to navigate to QuestSelect, err=%d" % int(err))

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
	sum_input_edit_count += 1
	if time_to_first_input_ms < 0:
		time_to_first_input_ms = _elapsed_ms_now()
	last_edit_ms = _elapsed_ms_now()
	_mark_change_after_review_feedback()
	if digits.is_empty():
		sum_input_clear_count += 1
		_log_event("sum_input_cleared")
	else:
		_log_event("sum_input_changed", {"value": digits, "len": digits.length()})
	if current_node == str(level_data.get("end_node", "E")) and not digits.is_empty():
		_set_phase(PHASE_INPUT)

func _on_submit_pressed() -> void:
	if _is_round_locked():
		return
	submit_attempt_count += 1
	if time_to_first_submit_ms < 0:
		time_to_first_submit_ms = _elapsed_ms_now()
	time_from_last_edit_to_submit_ms = -1 if last_edit_ms < 0 else maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("submit_pressed", {
		"path": path.duplicate(),
		"sum_input": sum_input.text.strip_edges(),
		"current_node": current_node
	})
	if current_node != str(level_data.get("end_node", "E")):
		_set_status_i18n(
			"city_map.common.result.err_incomplete",
			"Reach the target node before check.",
			Color(1.0, 0.62, 0.28)
		)
		_set_phase(PHASE_BUILD)
		return
	_set_dossier_open(false)
	_set_phase(PHASE_REVIEW)

	attempt_in_sublevel += 1
	attempt_in_run += 1
	var verdict := _judge_solution(sum_input.text.strip_edges())
	_last_reveal = verdict
	_log_event("submit_result", {
		"result_code": str(verdict.get("result_code", "ERR_UNKNOWN")),
		"route_valid": bool(verdict.get("route_valid", false)),
		"finish_reached": bool(verdict.get("finish_reached", false)),
		"calc_ok": bool(verdict.get("calc_ok", false)),
		"optimal_ok": bool(verdict.get("optimal_ok", false)),
		"best_known_cost": int(verdict.get("best_known_cost", min_sum)),
		"player_error_step_idx": int(verdict.get("player_error_step_idx", -1)),
		"player_cost": int(verdict.get("player_cost", int(verdict.get("sum_actual", -1))))
	})
	_log_attempt(verdict)
	if is_instance_valid(_reveal_label):
		_reveal_label.text = _build_review_text(verdict)

	if verdict.result_code == "OK":
		_set_status_i18n(
			"city_map.a.status.success",
			"Route accepted. Optimal sum confirmed.",
			Color(0.38, 1.0, 0.62)
		)
		GlobalMetrics.finish_quest(str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))), 100, true)
		stage_completed = true
		levels_completed += 1
		run_total_time_seconds += t_elapsed_seconds
		run_total_calc_errors += n_calc
		run_total_opt_errors += n_opt
		run_total_parse_errors += n_parse
		run_total_resets += n_reset
		if attempt_in_sublevel == 1:
			levels_perfect += 1
		btn_next.visible = true
		btn_next.disabled = false
		_lock_input(true)
		_set_progress_ui()
		return

	var result_code: String = str(verdict.result_code)
	GlobalMetrics.add_mistake("Ошибка маршрута: level=%s, code=%s, input=%s, actual_sum=%d, min_sum=%d, current_node=%s, path=%s" % [
		str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))),
		result_code,
		sum_input.text.strip_edges(),
		int(verdict.get("sum_actual", -1)),
		min_sum,
		current_node,
		" -> ".join(path)
	])
	var result_meta: Dictionary = _result_message_meta(result_code)
	_set_status_i18n(
		str(result_meta.get("key", "city_map.common.result.unhandled")),
		str(result_meta.get("default", "Unhandled result: {code}")),
		Color(1.0, 0.62, 0.28),
		result_meta.get("params", {})
	)
	_recalculate_stability()

func _result_message(result_code: String) -> String:
	var meta: Dictionary = _result_message_meta(result_code)
	return _tr(
		str(meta.get("key", "city_map.common.result.unhandled")),
		str(meta.get("default", "Unhandled result: {code}")),
		meta.get("params", {})
	)

func _result_message_meta(result_code: String) -> Dictionary:
	match result_code:
		"ERR_INCOMPLETE":
			return {"key": "city_map.common.result.err_incomplete", "default": "Reach node E before submit."}
		"ERR_PARSE":
			return {"key": "city_map.common.result.err_parse", "default": "Use digits only."}
		"ERR_CALC":
			return {"key": "city_map.common.result.err_calc", "default": "Entered sum does not match selected route."}
		"ERR_NOT_OPT":
			return {"key": "city_map.common.result.err_not_opt", "default": "Route is valid but not optimal."}
		"ERR_PATH_INVALID":
			return {"key": "city_map.common.result.err_path_invalid", "default": "Route is invalid for directed edges."}
		_:
			return {
				"key": "city_map.common.result.unhandled",
				"default": "Unhandled result: {code}",
				"params": {"code": result_code}
			}

func _mastery_block_reason(result_code: String) -> String:
	if submit_attempt_count >= 5:
		return "MULTI_SUBMIT_GUESSING"
	if undo_count_local >= 6:
		return "EXCESSIVE_UNDO"
	if hint_open_count > 0 and not changed_after_hint:
		return "HINT_DEPENDENCY"
	match result_code:
		"OK":
			return "NONE"
		"ERR_NOT_OPT":
			return "NOT_OPTIMAL"
		"ERR_CALC":
			return "ARITHMETIC_ERROR"
		"ERR_PATH_INVALID":
			return "PATH_INVALID"
		"ERR_INCOMPLETE":
			return "INCOMPLETE_ROUTE"
		_:
			return "NONE"

func _judge_solution(input_text: String) -> Dictionary:
	var sum_actual := _compute_path_sum()
	var sum_input_value: Variant = null
	var result_code := "OK"
	var player_error_step_idx := -1

	if sum_actual < 0:
		result_code = "ERR_PATH_INVALID"
		player_error_step_idx = _solver.first_invalid_step_index(path, adjacency)
	elif current_node != str(level_data.get("end_node", "E")):
		result_code = "ERR_INCOMPLETE"
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

	var best_preview := _best_known_path_preview()
	var reveal := _solver.build_reveal_payload(
		path,
		result_code,
		sum_actual,
		min_sum,
		str(level_data.get("end_node", "E")),
		sum_input_value,
		true,
		true,
		true,
		true,
		true,
		player_error_step_idx,
		best_preview,
		min_sum
	)
	reveal["sum_actual"] = sum_actual
	reveal["sum_input"] = sum_input_value
	return reveal

func _compute_path_sum() -> int:
	var total := 0
	for i in range(path.size() - 1):
		var from_id := path[i]
		var to_id := path[i + 1]
		if not adjacency.has(from_id) or not adjacency[from_id].has(to_id):
			return -1
		total += int(adjacency[from_id][to_id])
	return total

func _recalculate_stability() -> void:
	var trust_cfg: Dictionary = level_data.get("trust", {})
	var overtime_div := int(trust_cfg.get("overtime_div", 2))
	overtime_div = maxi(1, overtime_div)
	var overtime: int = maxi(0, t_elapsed_seconds - int(level_data.get("time_limit_sec", 120)))
	var overtime_penalty := int(floor(float(overtime) / float(overtime_div)))

	var penalties := (
		n_calc * int(trust_cfg.get("penalty_calc", 25))
		+ n_opt * int(trust_cfg.get("penalty_opt", 25))
		+ n_parse * int(trust_cfg.get("penalty_parse", 5))
		+ n_reset * int(trust_cfg.get("penalty_reset", 5))
		+ maxi(0, undo_count - 1) * 5
		+ wait_count
		+ overtime_penalty
	)

	stability = clampf(float(trust_cfg.get("initial", 100)) - float(penalties), 0.0, 100.0)
	label_state.text = _tr("city_map.common.status.stability", "STABILITY: {value}%", {"value": int(stability)})

	if stability <= 10.0 and not is_game_over:
		is_game_over = true
		stage_completed = false
		GlobalMetrics.add_mistake("Критическая потеря стабильности: level=%s, stability=%d, calc=%d, opt=%d, parse=%d, reset=%d, undo=%d, wait=%d, overtime=%d" % [
			str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))),
			int(stability),
			n_calc,
			n_opt,
			n_parse,
			n_reset,
			undo_count,
			wait_count,
			overtime_penalty
		])
		GlobalMetrics.finish_quest(str(level_data.get("level_id", _current_level_entry().get("id", "CityMapQuestA"))), 0, false)
		_set_status_i18n(
			"city_map.common.status.mission_failed",
			"MISSION FAILED: CRITICAL STABILITY.",
			Color(1.0, 0.30, 0.30)
		)
		btn_next.visible = false
		btn_next.disabled = true
		_lock_input(true)

func _update_timer_display() -> void:
	var time_limit := int(level_data.get("time_limit_sec", 120))
	var remaining: int = maxi(0, time_limit - t_elapsed_seconds)
	var mm: int = int(remaining / 60.0)
	var ss: int = remaining % 60
	label_timer.text = _tr("city_map.common.status.time", "TIME: {mm}:{ss}", {"mm": "%02d" % mm, "ss": "%02d" % ss})
	if t_elapsed_seconds > time_limit:
		label_timer.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))
	else:
		label_timer.add_theme_color_override("font_color", Color(1, 1, 1))

func _log_attempt(verdict: Dictionary) -> void:
	var sum_actual := int(verdict.get("sum_actual", -1))
	var sum_input_value: Variant = verdict.get("sum_input", null)
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var phase_snapshot: Dictionary = _phase_snapshot_ms()
	var level_entry := _current_level_entry()
	var sublevel_id := str(level_entry.get("id", "6_1_%02d" % (level_index + 1)))
	var sublevel_path := str(level_entry.get("path", ""))
	var next_available := result_code == "OK" and level_index + 1 < level_total
	var first_attempt_edge_value: Variant = null
	if not first_attempt_edge.is_empty():
		first_attempt_edge_value = first_attempt_edge

	var attempt_no := GlobalMetrics.session_history.size() + 1
	var mastery_reason := _mastery_block_reason(result_code)
	var solver_path_value: Variant = verdict.get("path", path.duplicate())
	var solver_path: Array = solver_path_value if typeof(solver_path_value) == TYPE_ARRAY else path.duplicate()
	var log_data := {
		"schema_version": "city_map.v2.2.0",
		"quest_id": "CITY_MAP",
		"stage": "A",
		"task_id": str(level_data.get("level_id", "6_1")),
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
		"match_key": "CITY_MAP|A|%s|v%s" % [str(level_data.get("level_id", "6_1")), config_hash.substr(0, 8)],
		"variant_hash": config_hash,
		"contract_version": str(level_data.get("contract_version", "city_map.v2.1.0")),
		"attempt_no": attempt_no,
		"result_code": result_code,
		"outcome_code": result_code,
		"mastery_block_reason": mastery_reason,
		"route_valid": bool(verdict.get("route_valid", false)),
		"finish_reached": bool(verdict.get("finish_reached", false)),
		"calc_ok": bool(verdict.get("calc_ok", sum_input_value != null and int(sum_input_value) == sum_actual)),
		"dynamic_ok": bool(verdict.get("dynamic_ok", true)),
		"must_visit_ok": bool(verdict.get("must_visit_ok", true)),
		"cycle_ok": bool(verdict.get("cycle_ok", true)),
		"xor_ok": bool(verdict.get("xor_ok", true)),
		"blacklist_ok": bool(verdict.get("blacklist_ok", true)),
		"optimal_ok": bool(verdict.get("optimal_ok", sum_actual == min_sum and result_code == "OK")),
		"best_known_cost": int(verdict.get("best_known_cost", min_sum)),
		"player_error_step_idx": int(verdict.get("player_error_step_idx", -1)),
		"first_attempt_edge": first_attempt_edge_value,
		"t_elapsed_seconds": t_elapsed_seconds,
		"path": solver_path.duplicate(),
		"sum_actual": sum_actual,
		"sum_input": sum_input_value,
		"min_sum": min_sum,
		"stability_final": int(stability),
		"n_calc": n_calc,
		"n_opt": n_opt,
		"n_parse": n_parse,
		"n_reset": n_reset,
		"undo_count": undo_count_local,
		"reset_count": reset_count_local,
		"submit_attempt_count": submit_attempt_count,
		"node_select_count": node_select_count,
		"edge_step_count": edge_step_count,
		"invalid_step_preview_count": invalid_step_preview_count,
		"route_change_count": route_change_count,
		"path_peak_len": path_peak_len,
		"unique_nodes_count": unique_nodes_visited.size(),
		"revisit_count": revisit_count,
		"sum_input_edit_count": sum_input_edit_count,
		"sum_input_clear_count": sum_input_clear_count,
		"details_open_count": details_open_count,
		"hint_open_count": hint_open_count,
		"changed_after_review": changed_after_review,
		"changed_after_hint": changed_after_hint,
		"time_to_first_step_ms": time_to_first_step_ms,
		"time_to_first_input_ms": time_to_first_input_ms,
		"time_to_first_submit_ms": time_to_first_submit_ms,
		"time_from_last_edit_to_submit_ms": time_from_last_edit_to_submit_ms,
		"phase_time_ms": phase_snapshot.duplicate(true),
		"wait_count": wait_count,
		"wait_total_sim_sec": wait_total_sim_sec,
		"closed_edge_attempts": 0,
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
		"elapsed_ms": t_elapsed_seconds * 1000,
		"duration": float(t_elapsed_seconds),
		"time_to_first_action_ms": first_action_ms if first_action_ms >= 0 else t_elapsed_seconds * 1000,
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
