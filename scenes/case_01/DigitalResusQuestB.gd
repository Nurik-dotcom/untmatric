extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const FLOW_SCENE_PATH: String = "res://scenes/case_01/Case01Flow.tscn"
const QUEST_SELECT_SCENE: String = "res://scenes/QuestSelect.tscn"
const CASE_ID: String = "CASE_01_DIGITAL_RESUS"
const STAGE_ID: String = "B"
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const QUIZ_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/QuizRenderer.tscn")
const MATCHING_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/MatchingRenderer.tscn")
const TABLE_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/TableMatchRenderer.tscn")
const ATTACK_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/AttackMatchRenderer.tscn")
const SUBNET_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/SubnetRenderer.tscn")

const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const TrialV2 = preload("res://scripts/TrialV2.gd")

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}
var attempt_index: int = 0
var trial_seq: int = 0
var task_session: Dictionary = {}
var attempt_started_ms: int = 0
var input_locked: bool = false
var _renderer: Node = null
var _last_result: Dictionary = {}
var _last_payload: Dictionary = {}
var _renderer_rounds_complete: bool = false
var _content_scroll_installed: bool = false
var _content_scroll: ScrollContainer = null
var _content_scroll_root: VBoxContainer = null

var step_select_count: int = 0
var step_reorder_count: int = 0
var toggle_count: int = 0
var inspect_open_count: int = 0
var hint_open_count: int = 0
var scan_run_count: int = 0

var reset_count_local: int = 0
var confirm_attempt_count: int = 0

var changed_after_scan: bool = false
var changed_after_hint: bool = false
var changed_after_fail: bool = false

var time_to_first_action_ms_local: int = -1
var time_to_first_scan_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_edit_to_confirm_ms: int = -1

var last_edit_ms: int = -1
var _awaiting_edit_after_scan: bool = false
var _awaiting_edit_after_hint: bool = false
var _awaiting_edit_after_fail: bool = false

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var content_area: Control = $SafeArea/MainVBox/ContentArea
@onready var bottom_bar: VBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/Buttons/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/Buttons/BtnConfirm
@onready var btn_next: Button = $SafeArea/MainVBox/BottomBar/Buttons/BtnNext

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	add_to_group("resus_b_controller")
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_install_content_scroll()

	levels = ResusData.load_stage_levels(LEVELS_PATH, STAGE_ID)
	if levels.is_empty():
		_show_error(_tr("resus.b.error.load", "Stage B data is missing."))
		return

	_load_current_level(0)
	_on_viewport_size_changed()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if _renderer != null and _renderer.has_method("apply_i18n"):
		_renderer.call("apply_i18n")

func _apply_i18n() -> void:
	title_label.text = _tr("resus.title", "Case 01: Digital Resus")
	stage_label.text = _tr("resus.b.stage.progress", "STAGE B {n}/{total}", {
		"n": current_level_index + 1,
		"total": max(1, levels.size())
	})
	btn_reset.text = _tr("resus.btn.reset", "RESET")
	btn_confirm.text = _tr("resus.btn.confirm", "CONFIRM")
	btn_next.text = _next_button_text()

func _elapsed_ms_now() -> int:
	return maxi(0, Time.get_ticks_msec() - attempt_started_ms)

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var events: Array = task_session.get("events", []) as Array
	events.append({
		"name": event_name,
		"t_ms": _elapsed_ms_now(),
		"payload": data.duplicate(true)
	})
	task_session["events"] = events

func _mark_first_action() -> void:
	if time_to_first_action_ms_local < 0:
		time_to_first_action_ms_local = _elapsed_ms_now()

func _mark_edit() -> void:
	last_edit_ms = _elapsed_ms_now()
	_mark_first_action()
	if _awaiting_edit_after_scan:
		changed_after_scan = true
		_awaiting_edit_after_scan = false
	if _awaiting_edit_after_hint:
		changed_after_hint = true
		_awaiting_edit_after_hint = false
	if _awaiting_edit_after_fail:
		changed_after_fail = true
		_awaiting_edit_after_fail = false

func _begin_trial_session() -> void:
	trial_seq += 1
	attempt_started_ms = Time.get_ticks_msec()
	task_session = {
		"events": [],
		"trial_seq": trial_seq
	}
	step_select_count = 0
	step_reorder_count = 0
	toggle_count = 0
	inspect_open_count = 0
	hint_open_count = 0
	scan_run_count = 0
	reset_count_local = 0
	confirm_attempt_count = 0
	changed_after_scan = false
	changed_after_hint = false
	changed_after_fail = false
	time_to_first_action_ms_local = -1
	time_to_first_scan_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_edit_to_confirm_ms = -1
	last_edit_ms = -1
	_awaiting_edit_after_scan = false
	_awaiting_edit_after_hint = false
	_awaiting_edit_after_fail = false
	_log_event("trial_started", {
		"level_id": str(level_data.get("id", "")),
		"briefing": str(level_data.get("briefing", "")),
		"mode": str(level_data.get("format", "DEFAULT"))
	})

func _resolve_outcome_code_b(result: Dictionary, answers: Variant) -> String:
	if bool(result.get("is_correct", false)):
		return "SUCCESS"
	var format: String = str(level_data.get("format", "")).to_upper()
	if format == "MATCHING_TABLE":
		return "ORDER_ERROR"
	if format == "MATCHING" or format == "MATCHING_CIA":
		return "LOGIC_ERROR"
	if format == "TOPOLOGY_MATCH" or format == "IP_QUIZ":
		return "SCAN_FAIL" if scan_run_count > 0 else "LOGIC_ERROR"
	if format == "ATTACK_MATCH" or format == "SUBNET_CALC":
		return "SCAN_FAIL"
	if typeof(answers) == TYPE_ARRAY and (answers as Array).is_empty():
		return "INCOMPLETE"
	return "INCOMPLETE" if not _renderer_rounds_complete else "LOGIC_ERROR"

func _resolve_mastery_block_reason_b(outcome_code: String) -> String:
	if outcome_code == "SUCCESS":
		return "NONE"
	if hint_open_count > 0:
		return "HINT_DEPENDENCY"
	if scan_run_count >= 2 or changed_after_scan:
		return "SCAN_DEPENDENCY"
	if confirm_attempt_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if step_reorder_count >= 3:
		return "ORDER_INSTABILITY"
	return "NONE"

func _load_current_level(index: int) -> void:
	current_level_index = clampi(index, 0, max(0, levels.size() - 1))
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)
	_swap_renderer()
	_begin_attempt()

func _swap_renderer() -> void:
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null
	_renderer_rounds_complete = false

	var format: String = str(level_data.get("format", "")).to_upper()
	var scene: PackedScene = null
	match format:
		"MATCHING", "MATCHING_CIA":
			scene = MATCHING_RENDERER_SCENE
		"MATCHING_TABLE":
			scene = TABLE_RENDERER_SCENE
		"TOPOLOGY_MATCH", "IP_QUIZ":
			scene = QUIZ_RENDERER_SCENE
		"ATTACK_MATCH":
			scene = ATTACK_RENDERER_SCENE
		"SUBNET_CALC":
			scene = SUBNET_RENDERER_SCENE
		_:
			_show_error(_tr("resus.b.error.format", "Unknown format: {format}", {"format": format}))
			return

	_renderer = scene.instantiate()
	var target_parent: Node = _content_scroll_root if _content_scroll_root != null else content_area
	target_parent.add_child(_renderer)
	if _renderer is Control:
		var renderer_control: Control = _renderer as Control
		renderer_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		renderer_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _renderer.has_method("setup"):
		_renderer.call("setup", level_data, self)
	if _renderer.has_signal("all_rounds_complete"):
		_renderer.connect("all_rounds_complete", Callable(self, "_on_renderer_complete"))
	else:
		_renderer_rounds_complete = true

func _install_content_scroll() -> void:
	if _content_scroll_installed:
		return
	if content_area == null:
		return
	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "ContentScroll"
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.follow_focus = true
	_content_scroll_root = VBoxContainer.new()
	_content_scroll_root.name = "ContentRoot"
	_content_scroll_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_scroll_root)
	content_area.add_child(_content_scroll)
	_content_scroll_installed = true

func _begin_attempt() -> void:
	input_locked = false
	_begin_trial_session()
	var format: String = str(level_data.get("format", "")).to_upper()
	var is_quiz: bool = _is_quiz_format(format)
	if _renderer != null and _renderer.has_signal("all_rounds_complete"):
		_renderer_rounds_complete = false
	else:
		_renderer_rounds_complete = not is_quiz
	btn_confirm.disabled = is_quiz
	btn_next.visible = false
	btn_next.disabled = true
	status_label.text = _tr("resus.status.quiz_progress", "Complete all rounds, then confirm.") if is_quiz else _tr("resus.status.ready", "Ready")
	status_label.modulate = Color(0.95, 0.95, 0.95)
	_apply_i18n()
	if _renderer != null and _renderer.has_method("reset"):
		_renderer.call("reset")
	_update_stability_ui()

func _on_confirm_pressed() -> void:
	if input_locked or _renderer == null or not _renderer.has_method("get_answers"):
		return
	var format: String = str(level_data.get("format", "")).to_upper()
	if _is_quiz_format(format) and not _renderer_rounds_complete:
		return
	confirm_attempt_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("confirm_pressed", {"attempt": confirm_attempt_count})
	var answers: Variant = _renderer.call("get_answers")
	var result: Dictionary = _score_level(answers)
	var outcome_code: String = _resolve_outcome_code_b(result, answers)
	_log_event("confirm_result", {
		"is_correct": bool(result.get("is_correct", false)),
		"score": int(result.get("points", 0)),
		"outcome_code": outcome_code
	})
	_awaiting_edit_after_fail = not bool(result.get("is_correct", false))
	_register_trial(answers, result)
	input_locked = true
	btn_confirm.disabled = true
	if _renderer.has_method("show_result"):
		_renderer.call("show_result", result)

	status_label.text = _tr("resus.status.result", "{verdict} | {points}/{max}", {
		"verdict": str(result.get("verdict_code", "FAIL")),
		"points": int(result.get("points", 0)),
		"max": int(result.get("max_points", 2))
	})
	status_label.modulate = Color(0.9, 1.0, 0.9, 1.0) if bool(result.get("is_correct", false)) else Color(1.0, 0.9, 0.9, 1.0)

	var can_advance: bool = bool(result.get("is_correct", false)) and (_has_next_level() or _is_flow_active())
	btn_next.visible = can_advance
	btn_next.disabled = not can_advance

func on_renderer_event(event_name: String, payload: Dictionary = {}) -> void:
	match event_name:
		"step_selected":
			step_select_count += 1
			_log_event("step_selected", payload)
			_mark_edit()
		"step_reordered":
			step_reorder_count += 1
			_log_event("step_reordered", payload)
			_mark_edit()
		"toggle_changed":
			toggle_count += 1
			_log_event("toggle_changed", payload)
			_mark_edit()
		"inspect_opened":
			inspect_open_count += 1
			_log_event("inspect_opened", payload)
		"hint_opened":
			hint_open_count += 1
			_awaiting_edit_after_hint = true
			_log_event("hint_opened", payload)
		"scan_started":
			scan_run_count += 1
			if time_to_first_scan_ms < 0:
				time_to_first_scan_ms = _elapsed_ms_now()
			_log_event("scan_started", payload)
		"scan_result":
			_awaiting_edit_after_scan = true
			_log_event("scan_result", payload)
		"attack_selected", "defense_selected", "network_answer_changed", "broadcast_answer_changed", "hosts_answer_changed":
			step_select_count += 1
			_log_event(event_name, payload)
			_mark_edit()
		"round_checked":
			if scan_run_count == 0:
				scan_run_count = 1
				if time_to_first_scan_ms < 0:
					time_to_first_scan_ms = _elapsed_ms_now()
			_awaiting_edit_after_scan = true
			_log_event("scan_result", payload)
		_:
			_log_event(event_name, payload)

func _score_level(answers: Variant) -> Dictionary:
	var format: String = str(level_data.get("format", "")).to_upper()
	match format:
		"MATCHING", "MATCHING_CIA":
			var snapshot: Dictionary = answers as Dictionary
			return ResusScoring.score(level_data, snapshot, _count_placed(snapshot))
		"MATCHING_TABLE":
			return ResusScoring.calculate_matching_table_result(level_data, answers as Dictionary)
		"TOPOLOGY_MATCH", "IP_QUIZ":
			return ResusScoring.calculate_quiz_result(level_data, answers as Array)
		"ATTACK_MATCH":
			return ResusScoring.calculate_attack_match_result(level_data, answers as Array)
		"SUBNET_CALC":
			return ResusScoring.calculate_subnet_result(level_data, answers as Array)
		"MULTI_CHOICE_SLOTS":
			return ResusScoring.calculate_stage_c_result(level_data, answers as Dictionary)
		_:
			return {
				"points": 0,
				"max_points": 2,
				"is_correct": false,
				"is_fit": false,
				"stability_delta": -30,
				"verdict_code": "FAIL"
			}

func _count_placed(snapshot: Dictionary) -> int:
	var count: int = 0
	for value_v in snapshot.values():
		var value: String = str(value_v).strip_edges().to_upper()
		if value != "" and value != "PILE":
			count += 1
	return count

func _register_trial(answers: Variant, result: Dictionary) -> void:
	var level_id: String = str(level_data.get("id", "CASE01_B"))
	var elapsed_ms: int = _elapsed_ms_now()
	var outcome_code: String = _resolve_outcome_code_b(result, answers)
	var mastery_block_reason: String = _resolve_mastery_block_reason_b(outcome_code)
	var payload: Dictionary = TrialV2.build(CASE_ID, STAGE_ID, level_id, "FORMAT_ROUTER", str(attempt_index))
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": level_id,
		"format": str(level_data.get("format", "")),
		"snapshot": answers,
		"trial_seq": trial_seq,
		"task_session": task_session.duplicate(true),
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": time_to_first_action_ms_local,
		"time_to_first_scan_ms": time_to_first_scan_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"step_select_count": step_select_count,
		"step_reorder_count": step_reorder_count,
		"toggle_count": toggle_count,
		"inspect_open_count": inspect_open_count,
		"hint_open_count": hint_open_count,
		"scan_run_count": scan_run_count,
		"reset_count": reset_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"changed_after_scan": changed_after_scan,
		"changed_after_hint": changed_after_hint,
		"changed_after_fail": changed_after_fail,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason
	}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)
	attempt_index += 1
	_update_stability_ui()

func _on_reset_pressed() -> void:
	reset_count_local += 1
	_log_event("reset_pressed", {"count": reset_count_local})
	_apply_retry_floor()
	_begin_attempt()

func _on_renderer_complete() -> void:
	_renderer_rounds_complete = true
	_log_event("scan_result", {"rounds_complete": true})
	if input_locked:
		return
	btn_confirm.disabled = false
	status_label.text = _tr("resus.status.quiz_done", "Quiz complete. Confirm to submit.")
	status_label.modulate = Color(0.95, 0.95, 0.95)

func _on_next_pressed() -> void:
	if _last_result.is_empty() or not bool(_last_result.get("is_correct", false)):
		return
	if _has_next_level():
		_load_current_level(current_level_index + 1)
		return
	if _is_flow_active():
		GlobalMetrics.record_case_stage_result(STAGE_ID, _build_flow_stage_summary())
		get_tree().change_scene_to_file(FLOW_SCENE_PATH)

func _on_back_pressed() -> void:
	if _is_flow_active():
		GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file(QUEST_SELECT_SCENE)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability

func _apply_retry_floor() -> void:
	if GlobalMetrics.stability < 20.0:
		var previous: float = float(GlobalMetrics.stability)
		GlobalMetrics.stability = 20.0
		GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, GlobalMetrics.stability - previous)

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.8, 0.8)
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true

func _is_quiz_format(format: String) -> bool:
	return format == "TOPOLOGY_MATCH" or format == "IP_QUIZ" or format == "ATTACK_MATCH" or format == "SUBNET_CALC"

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 6 if compact else 10)
	stability_bar.custom_minimum_size.x = 140.0 if compact else 200.0
	bottom_bar.custom_minimum_size.y = 72.0 if compact else 100.0
	btn_back.custom_minimum_size = Vector2(48.0 if compact else 64.0, 48.0 if compact else 64.0)
	btn_reset.custom_minimum_size = Vector2(0.0, 44.0 if compact else 52.0)
	btn_confirm.custom_minimum_size = Vector2(0.0, 44.0 if compact else 52.0)
	btn_next.custom_minimum_size = Vector2(0.0, 44.0 if compact else 52.0)
	status_label.custom_minimum_size.y = 28.0 if compact else 40.0

	var margin: int = 8 if compact else 14
	safe_area.add_theme_constant_override("margin_left", margin)
	safe_area.add_theme_constant_override("margin_right", margin)
	safe_area.add_theme_constant_override("margin_top", margin)
	safe_area.add_theme_constant_override("margin_bottom", margin)

func _has_next_level() -> bool:
	return current_level_index < levels.size() - 1

func _next_button_text() -> String:
	if not _has_next_level() and _is_flow_active():
		return _tr("resus.btn.next_stage", "NEXT STAGE")
	return _tr("resus.btn.next_level", "NEXT LEVEL")

func _is_flow_active() -> bool:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return bool(flow.get("is_active", false)) and str(flow.get("case_id", "")) == CASE_ID

func _case_run_id() -> String:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return str(flow.get("case_run_id", ""))

func _build_flow_stage_summary() -> Dictionary:
	var case_run_id: String = _case_run_id()
	var total_points: int = 0
	var total_stability_delta: int = 0
	for entry_v in GlobalMetrics.session_history:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != CASE_ID:
			continue
		if str(entry.get("stage", "")) != STAGE_ID:
			continue
		if str(entry.get("case_run_id", "")) != case_run_id:
			continue
		total_points += int(entry.get("points", 0))
		total_stability_delta += int(entry.get("stability_delta", 0))
	return {
		"stage": STAGE_ID,
		"case_run_id": case_run_id,
		"levels_completed": levels.size(),
		"last_level_id": str(level_data.get("id", "")),
		"points": total_points,
		"stability_delta": total_stability_delta,
		"completed_at_unix": Time.get_unix_time_from_system()
	}
