extends Control

const LEVELS_PATH := "res://data/final_report_b_levels.json"
const SESSION_LEVEL_COUNT := 6
const FR8BData := preload("res://scripts/case_08/fr8b_data.gd")
const FR8BScoring := preload("res://scripts/case_08/fr8b_scoring.gd")
const TIMELINE_CARD_SCENE: PackedScene = preload("res://scenes/ui/TimelineCard.tscn")

const COLOR_OK := Color(0.55, 0.95, 0.62, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)
const COLOR_INFO := Color(0.84, 0.84, 0.84, 1.0)

const TEXT_TITLE := "\u0414\u0415\u041b\u041e #8: \u0424\u0418\u041d\u0410\u041b\u042c\u041d\u042b\u0419 \u041e\u0422\u0427\u0415\u0422 [B]"
const TEXT_BACK := "\u041d\u0410\u0417\u0410\u0414"
const TEXT_RESET := "\u0421\u0411\u0420\u041e\u0421"
const TEXT_CONFIRM := "\u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c"
const TEXT_NEXT := "\u0414\u0410\u041b\u0415\u0415"
const TEXT_FINISH := "\u0417\u0410\u0412\u0415\u0420\u0428\u0418\u0422\u042c"

const STATUS_HINT := "\u0412\u044b\u0441\u0442\u0440\u043e\u0439\u0442\u0435 \u044d\u0442\u0430\u043f\u044b \u043f\u043e \u0432\u0440\u0435\u043c\u0435\u043d\u0438, \u0437\u0430\u0442\u0435\u043c \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c."
const STATUS_NEXT_HINT := "\u041f\u043b\u0430\u043d \u0443\u0442\u0432\u0435\u0440\u0436\u0434\u0451\u043d. \u0416\u043c\u0438\u0442\u0435 \u0414\u0410\u041b\u0415\u0415."
const STATUS_SOLVE_FIRST := "\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u0437\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 \u0443\u0440\u043e\u0432\u0435\u043d\u044c."

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}

var cards_by_stage_id: Dictionary = {}
var current_order: Array[String] = []
var initial_order: Array[String] = []

var swap_count: int = 0
var reset_count: int = 0
var start_time_ms: int = 0
var time_to_first_action_ms: int = -1

var trial_locked: bool = false
var level_solved: bool = false
var has_confirmed_once: bool = false
var trace: Array = []
var trial_seq: int = 0
var task_session: Dictionary = {}

var card_drag_start_count: int = 0
var card_move_count: int = 0
var reorder_count: int = 0
var slot_swap_count: int = 0
var scan_run_count: int = 0
var scan_glitch_count: int = 0
var dependency_violation_seen_count: int = 0
var reset_count_local: int = 0
var confirm_attempt_count: int = 0
var changed_after_scan: bool = false
var changed_after_fail: bool = false
var time_to_first_drag_ms: int = -1
var time_to_first_scan_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_edit_to_confirm_ms: int = -1
var last_edit_ms: int = -1
var awaiting_change_after_fail: bool = false

var dependency_lines: Array = []
var stage_run_history_start: int = 0
var stage_level_ids: Dictionary = {}

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var title_label: Label = $SafeArea/MainLayout/Header/TitleLabel
@onready var level_label: Label = $SafeArea/MainLayout/Header/LevelLabel
@onready var level_progress_bar: ProgressBar = $SafeArea/MainLayout/Header/LevelProgressBar
@onready var stability_bar: ProgressBar = $SafeArea/MainLayout/Header/StabilityBar
@onready var briefing_label: RichTextLabel = $SafeArea/MainLayout/BriefingCard/BriefingLabel
@onready var axis_left_label: Label = $SafeArea/MainLayout/TimelineCard/CardVBox/AxisRow/AxisLeft
@onready var axis_right_label: Label = $SafeArea/MainLayout/TimelineCard/CardVBox/AxisRow/AxisRight
@onready var cards_row: HBoxContainer = $SafeArea/MainLayout/TimelineCard/CardVBox/CardsRow
@onready var dependency_overlay: Control = $SafeArea/MainLayout/TimelineCard/DependencyOverlay
@onready var status_label: Label = $SafeArea/MainLayout/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainLayout/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainLayout/BottomBar/BtnConfirm
@onready var btn_next: Button = $SafeArea/MainLayout/BottomBar/BtnNext
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	if dependency_overlay != null and not dependency_overlay.draw.is_connected(_on_dependency_overlay_draw):
		dependency_overlay.draw.connect(_on_dependency_overlay_draw)

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error(_tr("case08.fr8b.load_error", "Не удалось загрузить уровни финального отчёта B."))
		return
	stage_run_history_start = GlobalMetrics.session_history.size()

	_apply_i18n()

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_apply_layout_mode()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	_apply_runtime_i18n()

func _apply_i18n() -> void:
	title_label.text = _tr("case08.fr8b.title", TEXT_TITLE)
	btn_back.text = _tr("case08.common.back", TEXT_BACK)
	btn_reset.text = _tr("case08.common.reset", TEXT_RESET)
	btn_confirm.text = _tr("case08.common.confirm", TEXT_CONFIRM)
	axis_left_label.text = _tr("case08.fr8b.axis.past", "ПРОШЛОЕ")
	axis_right_label.text = _tr("case08.fr8b.axis.future", "БУДУЩЕЕ")
	if levels.is_empty():
		btn_next.text = _tr("case08.common.next", TEXT_NEXT)
	elif trial_locked and level_solved and btn_confirm.disabled and btn_reset.disabled and _is_last_level():
		btn_next.text = _tr("case08.common.exit", "ВЫХОД")
	else:
		btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)

func _apply_runtime_i18n() -> void:
	if levels.is_empty():
		return
	briefing_label.text = I18n.resolve_field(level_data, "briefing")
	_rebuild_cards()
	if has_confirmed_once:
		var evaluation: Dictionary = FR8BScoring.evaluate(level_data, current_order)
		var feedback_text: String = FR8BScoring.feedback_text(level_data, evaluation)
		if level_solved:
			_set_status("%s %s" % [feedback_text, _tr("case08.fr8b.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)
		else:
			_set_status(feedback_text, COLOR_ERR)
	else:
		_set_status(_tr("case08.fr8b.status.hint", STATUS_HINT), COLOR_INFO)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	if not merged.has("default"):
		merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _localized_card_data(card_data: Dictionary) -> Dictionary:
	var localized: Dictionary = card_data.duplicate(true)
	localized["title"] = I18n.resolve_field(card_data, "title", {"default": str(card_data.get("title", str(card_data.get("stage_id", ""))))})
	localized["hint"] = I18n.resolve_field(card_data, "hint", {"default": str(card_data.get("hint", ""))})
	return localized

func _load_levels() -> void:
	levels = FR8BData.load_levels(LEVELS_PATH)
	if SESSION_LEVEL_COUNT > 0 and levels.size() > SESSION_LEVEL_COUNT:
		var limited: Array = []
		for i in range(SESSION_LEVEL_COUNT):
			limited.append(levels[i])
		levels = limited
	stage_level_ids.clear()
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var id_value: String = str((level_var as Dictionary).get("id", "")).strip_edges()
		if id_value.is_empty():
			continue
		stage_level_ids[id_value] = true

func _start_level(index: int) -> void:
	if levels.is_empty():
		return

	current_level_index = clamp(index, 0, levels.size() - 1)
	GlobalMetrics.current_level_index = current_level_index
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)

	cards_by_stage_id.clear()
	var base_order: Array[String] = []
	for card_var in level_data.get("cards", []) as Array:
		if typeof(card_var) != TYPE_DICTIONARY:
			continue
		var card_data: Dictionary = card_var as Dictionary
		var stage_id: String = str(card_data.get("stage_id", "")).strip_edges()
		if stage_id.is_empty():
			continue
		cards_by_stage_id[stage_id] = card_data
		base_order.append(stage_id)

	current_order = base_order.duplicate()
	var anti_cheat: Dictionary = level_data.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_cards", false)) and current_order.size() > 1:
		current_order.shuffle()
		if _arrays_equal(current_order, _expected_order()):
			var first_id: String = current_order[0]
			current_order[0] = current_order[1]
			current_order[1] = first_id

	initial_order = current_order.duplicate()
	_begin_trial_session()

	level_label.text = _build_level_label()
	_update_progress_ui()
	briefing_label.text = I18n.resolve_field(level_data, "briefing")

	_reset_attempt(true)
	_update_stability_ui()
	_apply_layout_mode()

func _build_level_label() -> String:
	var progress_pct: int = int((float(current_level_index + 1) / maxf(1.0, float(levels.size()))) * 100.0)
	return "B | %s (%d/%d) — %d%%" % [
		str(level_data.get("id", "FR8-B")),
		current_level_index + 1,
		levels.size(),
		progress_pct
	]

func _update_progress_ui() -> void:
	if level_progress_bar == null:
		return
	var progress_pct: float = (float(current_level_index + 1) / maxf(1.0, float(levels.size()))) * 100.0
	level_progress_bar.value = progress_pct

func _expected_order() -> Array[String]:
	var out: Array[String] = []
	for stage_var in level_data.get("expected_order", []) as Array:
		out.append(str(stage_var).strip_edges())
	return out

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

func _begin_trial_session() -> void:
	trial_seq += 1
	start_time_ms = Time.get_ticks_msec()
	time_to_first_action_ms = -1
	trace.clear()
	swap_count = 0
	reset_count = 0
	has_confirmed_once = false

	card_drag_start_count = 0
	card_move_count = 0
	reorder_count = 0
	slot_swap_count = 0
	scan_run_count = 0
	scan_glitch_count = 0
	dependency_violation_seen_count = 0
	reset_count_local = 0
	confirm_attempt_count = 0
	changed_after_scan = false
	changed_after_fail = false
	time_to_first_drag_ms = -1
	time_to_first_scan_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_edit_to_confirm_ms = -1
	last_edit_ms = -1
	awaiting_change_after_fail = false

	var level_id: String = str(level_data.get("id", "FR8-B-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage_id": "B",
		"task_id": level_id,
		"started_at_ticks": start_time_ms,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"level_id": level_id,
		"stage_count": current_order.size(),
		"dependency_count": (level_data.get("dependencies", []) as Array).size(),
		"axis": "past_future"
	})

func _elapsed_ms_now() -> int:
	if start_time_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - start_time_ms)

func _reset_attempt(is_level_start: bool = false) -> void:
	current_order = initial_order.duplicate()
	if not is_level_start:
		_mark_first_action()
		reset_count_local += 1
		reset_count = reset_count_local
		_log_event("reset_pressed", {"reset_count": reset_count_local})
	_log_event("attempt_reset", {"level_start": is_level_start})

	_log_event("СБРОС", {"level_start": is_level_start})

	trial_locked = false
	level_solved = false
	has_confirmed_once = false
	awaiting_change_after_fail = false
	btn_confirm.disabled = false
	btn_next.disabled = true
	btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
	_clear_dependency_overlay()

	_rebuild_cards()
	_set_status(_tr("case08.fr8b.status.hint", STATUS_HINT), COLOR_INFO)

func _rebuild_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()

	for i in range(current_order.size()):
		var stage_id: String = current_order[i]
		if not cards_by_stage_id.has(stage_id):
			continue

		var card_node: Node = TIMELINE_CARD_SCENE.instantiate()
		cards_row.add_child(card_node)
		if card_node.has_method("setup"):
			var card_data: Dictionary = cards_by_stage_id.get(stage_id, {}) as Dictionary
			card_node.call("setup", _localized_card_data(card_data))
		card_node.set_meta("stage_id", stage_id)
		if card_node is CanvasItem:
			(card_node as CanvasItem).modulate = Color.WHITE
		if card_node.has_method("set_move_enabled"):
			card_node.call("set_move_enabled", i > 0 and not trial_locked, i < current_order.size() - 1 and not trial_locked)
		if card_node.has_signal("move_requested"):
			card_node.connect("move_requested", Callable(self, "_on_card_move_requested"))
		if card_node.has_signal("hint_requested"):
			card_node.connect("hint_requested", Callable(self, "_on_card_hint_requested"))

	_apply_layout_mode()
	_queue_dependency_overlay_redraw()

func _on_card_move_requested(stage_id: String, dir: int) -> void:
	if trial_locked:
		return

	var index: int = current_order.find(stage_id)
	if index < 0:
		return
	var target_index: int = index + dir
	if target_index < 0 or target_index >= current_order.size():
		return

	_mark_first_action()
	_clear_dependency_overlay()
	card_drag_start_count += 1
	card_move_count += 1
	reorder_count += 1
	slot_swap_count += 1
	swap_count = slot_swap_count
	if time_to_first_drag_ms < 0:
		time_to_first_drag_ms = _elapsed_ms_now()
	last_edit_ms = _elapsed_ms_now()
	if scan_run_count > 0:
		changed_after_scan = true
	if awaiting_change_after_fail:
		changed_after_fail = true
		awaiting_change_after_fail = false

	var other_stage: String = current_order[target_index]
	current_order[target_index] = stage_id
	current_order[index] = other_stage
	_queue_dependency_overlay_redraw()

	_log_event("card_reordered", {
		"stage_id": stage_id,
		"from_index": index,
		"to_index": target_index,
		"dir": dir,
		"current_order": current_order.duplicate()
	})

	_rebuild_cards()
	_set_status(_tr("case08.fr8b.status.hint", STATUS_HINT), COLOR_INFO)
	if AudioManager != null:
		AudioManager.play("click")

func _on_card_hint_requested(stage_id: String) -> void:
	_mark_first_action()
	_log_event("HINT_REQUESTED", {"stage_id": stage_id})

	var hint_text: String = ""
	if cards_by_stage_id.has(stage_id):
		var card_data: Dictionary = cards_by_stage_id.get(stage_id, {}) as Dictionary
		hint_text = I18n.resolve_field(card_data, "hint", {"default": str(card_data.get("hint", ""))}).strip_edges()

	if hint_text.is_empty():
		_set_status(_tr("case08.fr8b.status.hint", STATUS_HINT), COLOR_INFO)
	else:
		_set_status(hint_text, COLOR_INFO)

	if AudioManager != null:
		AudioManager.play("click")

func _on_confirm_pressed() -> void:
	if trial_locked:
		return

	_mark_first_action()
	confirm_attempt_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if time_to_first_scan_ms < 0:
		time_to_first_scan_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	else:
		time_from_last_edit_to_confirm_ms = -1
	_log_event("confirm_pressed", {
		"current_order": current_order.duplicate(),
		"attempt": confirm_attempt_count,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms
	})
	has_confirmed_once = true
	trial_locked = true
	btn_confirm.disabled = true
	_set_status(_tr("case08.fr8b.status.scanning", "ИНИЦИАЛИЗАЦИЯ ЛОГИЧЕСКОГО СКАНИРОВАНИЯ..."), COLOR_WARN)

	var evaluation: Dictionary = FR8BScoring.evaluate(level_data, current_order)
	var score: Dictionary = FR8BScoring.resolve_score(level_data, evaluation)
	var feedback_text: String = FR8BScoring.feedback_text(level_data, evaluation)
	var violations: Array = (evaluation.get("violations", []) as Array).duplicate(true)
	scan_run_count += 1
	_log_event("logic_scan_started", {
		"scan_run_count": scan_run_count,
		"current_order": current_order.duplicate()
	})
	_build_dependency_overlay_lines(evaluation)
	var scan_triggered_glitch: bool = await _run_logic_scan(evaluation)
	if scan_triggered_glitch:
		scan_glitch_count += 1
	if not violations.is_empty():
		dependency_violation_seen_count += 1
		var top_violation: Dictionary = evaluation.get("top_violation", {}) as Dictionary
		_log_event("dependency_violation_shown", {
			"violating_stage_id": str(top_violation.get("a", "")),
			"top_violation": top_violation.duplicate(true),
			"broken_dependency_count": violations.size()
		})
	await _restore_cards_color()

	var elapsed_ms: int = _elapsed_ms_now()
	var tffa_ms: int = elapsed_ms if time_to_first_action_ms < 0 else time_to_first_action_ms
	var level_id: String = str(level_data.get("id", "FR8-B-00"))
	var verdict_code: String = str(score.get("verdict_code", "FAIL"))
	var error_code: String = str(evaluation.get("error_code", "ORDER_MISMATCH"))
	var match_key: String = "FR8_B|%s|%d" % [level_id, GlobalMetrics.session_history.size()]
	var is_correct: bool = bool(score.get("is_correct", false))
	var outcome_code: String = _outcome_code_for_b(is_correct, error_code, violations, scan_triggered_glitch)
	var mastery_block_reason: String = _mastery_block_reason_for_b(is_correct, outcome_code)

	_log_event("confirm_result", {
		"is_correct": is_correct,
		"error_type": error_code,
		"violations": violations.duplicate(true),
		"current_order": current_order.duplicate(),
		"outcome_code": outcome_code
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "B",
		"level_id": level_id,
		"format": "TIMELINE_SORT",
		"match_key": match_key,
		"trial_seq": trial_seq,
		"initial_order": initial_order.duplicate(),
		"final_order": current_order.duplicate(),
		"current_order": current_order.duplicate(),
		"violations": violations.duplicate(true),
		"error_code": error_code,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": tffa_ms,
		"time_to_first_drag_ms": time_to_first_drag_ms,
		"time_to_first_scan_ms": time_to_first_scan_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"swap_count": swap_count,
		"reset_count": reset_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"card_drag_start_count": card_drag_start_count,
		"card_move_count": card_move_count,
		"reorder_count": reorder_count,
		"slot_swap_count": slot_swap_count,
		"scan_run_count": scan_run_count,
		"scan_glitch_count": scan_glitch_count,
		"dependency_violation_seen_count": dependency_violation_seen_count,
		"changed_after_scan": changed_after_scan,
		"changed_after_fail": changed_after_fail,
		"points": int(score.get("points", 0)),
		"max_points": int(score.get("max_points", 2)),
		"is_fit": bool(score.get("is_fit", false)),
		"is_correct": is_correct,
		"stability_delta": int(score.get("stability_delta", -25)),
		"verdict_code": verdict_code,
		"trace": trace.duplicate(true),
		"task_session": task_session.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	if verdict_code == "PERFECT":
		level_solved = true
		trial_locked = true
		awaiting_change_after_fail = false
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
		_set_status("%s %s" % [feedback_text, _tr("case08.fr8b.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)
		_rebuild_cards()
		if AudioManager != null:
			AudioManager.play("relay")
	else:
		level_solved = false
		trial_locked = false
		awaiting_change_after_fail = true
		btn_confirm.disabled = false
		btn_next.disabled = true
		_set_status(feedback_text, COLOR_ERR)
		if not scan_triggered_glitch:
			_trigger_glitch()
			_shake_main_layout()
		if AudioManager != null:
			AudioManager.play("error")

func _on_next_pressed() -> void:
	if not level_solved:
		_set_status(_tr("case08.fr8b.status.solve_first", STATUS_SOLVE_FIRST), COLOR_WARN)
		return

	if _is_last_level():
		if btn_next.text == _tr("case08.common.exit", "ВЫХОД"):
			GlobalMetrics.current_level_index = 0
			get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
			return
		_show_session_summary()
		return

	var from_level_id: String = str(level_data.get("id", "FR8-B-00"))
	var from_index: int = current_level_index
	var to_index: int = current_level_index + 1
	_log_event("NEXT_PRESSED", {
		"from_level_id": from_level_id,
		"from_index": from_index,
		"to_index": to_index
	})
	_start_level(to_index)

func _show_session_summary() -> void:
	trial_locked = true
	level_solved = true
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.text = _tr("case08.common.exit", "ВЫХОД")
	btn_next.disabled = false
	level_label.text = "B | ИТОГИ"
	_update_progress_ui()

	var latest_by_level: Dictionary = {}
	for idx in range(stage_run_history_start, GlobalMetrics.session_history.size()):
		var entry_var: Variant = GlobalMetrics.session_history[idx]
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_var as Dictionary
		if str(entry.get("quest_id", "")) != "CASE_08_FINAL_REPORT":
			continue
		if str(entry.get("stage", "")) != "B":
			continue
		var level_id: String = str(entry.get("level_id", "")).strip_edges()
		if level_id.is_empty() or not stage_level_ids.has(level_id):
			continue
		latest_by_level[level_id] = entry

	var total: int = levels.size()
	var correct: int = 0
	var total_ms: int = 0
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_id: String = str((level_var as Dictionary).get("id", "")).strip_edges()
		if level_id.is_empty():
			continue
		if not latest_by_level.has(level_id):
			continue
		var row: Dictionary = latest_by_level[level_id] as Dictionary
		if bool(row.get("is_correct", false)):
			correct += 1
		total_ms += int(row.get("elapsed_ms", 0))

	var pct: int = int((float(correct) / maxf(1.0, float(total))) * 100.0)
	var avg_sec: float = (float(total_ms) / 1000.0) / maxf(1.0, float(total))
	if level_progress_bar != null:
		level_progress_bar.value = 100.0

	briefing_label.text = ""
	for child in cards_row.get_children():
		child.queue_free()
	_clear_dependency_overlay()

	var summary: String = "СЕССИЯ ЗАВЕРШЕНА\n\n"
	summary += "Правильно: %d / %d (%d%%)\n" % [correct, total, pct]
	summary += "Среднее время: %.1f с\n\n" % avg_sec

	if pct >= 90:
		summary += "Отличный результат. План утверждён."
		_set_status("Сессия пройдена успешно.", COLOR_OK)
	elif pct >= 60:
		summary += "Неплохо, но есть пробелы."
		_set_status("Рекомендуется повторить.", COLOR_WARN)
	else:
		summary += "Требуется доработка."
		_set_status("Нужно повторить материал.", COLOR_ERR)

	briefing_label.text = summary

func _on_back_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_reset_pressed() -> void:
	_reset_attempt(false)
	if AudioManager != null:
		AudioManager.play("click")

func _on_viewport_size_changed() -> void:
	_apply_layout_mode()

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var count: int = max(1, current_order.size())
	var available_width: float = max(320.0, viewport_size.x - 80.0)
	var card_width: float
	if viewport_size.x > viewport_size.y:
		card_width = clamp(available_width / float(count), 145.0, 230.0)
	else:
		card_width = clamp(available_width / float(count), 108.0, 170.0)

	for child in cards_row.get_children():
		if child is Control:
			var control: Control = child as Control
			control.custom_minimum_size = Vector2(card_width, 120)
	_queue_dependency_overlay_redraw()

func _mark_first_action() -> void:
	if time_to_first_action_ms >= 0:
		return
	time_to_first_action_ms = _elapsed_ms_now()

func _arrays_equal(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true

func _set_status(text_value: String, color_value: Color) -> void:
	status_label.text = text_value
	status_label.modulate = color_value

func _run_logic_scan(evaluation: Dictionary) -> bool:
	var top_violation: Dictionary = evaluation.get("top_violation", {}) as Dictionary
	var violating_stage_id: String = str(top_violation.get("a", "")).strip_edges()
	var scan_triggered_glitch: bool = false

	for child in cards_row.get_children():
		if not (child is Control):
			continue
		var card: Control = child as Control
		var stage_id: String = str(card.get_meta("stage_id", "")).strip_edges()

		await _highlight_card_node(card, Color(1.5, 1.5, 1.5, 1.0), 0.14)
		if AudioManager != null:
			AudioManager.play("click")
		await get_tree().create_timer(0.3).timeout

		if not violating_stage_id.is_empty() and stage_id == violating_stage_id:
			await _highlight_card_node(card, Color(2.0, 0.2, 0.2, 1.0), 0.18)
			_trigger_glitch()
			_shake_main_layout()
			await get_tree().create_timer(0.5).timeout
			scan_triggered_glitch = true
			break

		await _highlight_card_node(card, Color(0.45, 1.35, 0.55, 1.0), 0.15)

	return scan_triggered_glitch

func _restore_cards_color() -> Signal:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for child in cards_row.get_children():
		if child is Control:
			tween.tween_property(child, "modulate", Color.WHITE, 0.3)
	return tween.finished

func _highlight_card_node(card: Control, target_color: Color, duration: float) -> Signal:
	var tween: Tween = create_tween()
	tween.tween_property(card, "modulate", target_color, duration)
	return tween.finished

func _build_dependency_overlay_lines(evaluation: Dictionary) -> void:
	dependency_lines.clear()

	var broken_map: Dictionary = {}
	for violation_var in evaluation.get("violations", []) as Array:
		if typeof(violation_var) != TYPE_DICTIONARY:
			continue
		var violation: Dictionary = violation_var as Dictionary
		var key: String = "%s->%s" % [
			str(violation.get("a", "")).strip_edges(),
			str(violation.get("b", "")).strip_edges()
		]
		broken_map[key] = true

	for dep_var in level_data.get("dependencies", []) as Array:
		if typeof(dep_var) != TYPE_DICTIONARY:
			continue
		var dep: Dictionary = dep_var as Dictionary
		var a: String = str(dep.get("a", "")).strip_edges()
		var b: String = str(dep.get("b", "")).strip_edges()
		if a.is_empty() or b.is_empty():
			continue
		dependency_lines.append({
			"a": a,
			"b": b,
			"broken": broken_map.has("%s->%s" % [a, b])
		})

	_queue_dependency_overlay_redraw()

func _clear_dependency_overlay() -> void:
	if dependency_lines.is_empty():
		return
	dependency_lines.clear()
	_queue_dependency_overlay_redraw()

func _queue_dependency_overlay_redraw() -> void:
	if dependency_overlay != null:
		dependency_overlay.queue_redraw()

func _card_by_stage_id(stage_id: String) -> Control:
	for child in cards_row.get_children():
		if not (child is Control):
			continue
		if str(child.get_meta("stage_id", "")).strip_edges() == stage_id:
			return child as Control
	return null

func _on_dependency_overlay_draw() -> void:
	if dependency_overlay == null or dependency_lines.is_empty():
		return

	for line_var in dependency_lines:
		if typeof(line_var) != TYPE_DICTIONARY:
			continue
		var line_data: Dictionary = line_var as Dictionary
		var card_a: Control = _card_by_stage_id(str(line_data.get("a", "")))
		var card_b: Control = _card_by_stage_id(str(line_data.get("b", "")))
		if card_a == null or card_b == null:
			continue

		var rect_a: Rect2 = card_a.get_global_rect()
		var rect_b: Rect2 = card_b.get_global_rect()
		var p1: Vector2 = dependency_overlay.to_local(rect_a.position + Vector2(rect_a.size.x * 0.5, rect_a.size.y * 0.18))
		var p2: Vector2 = dependency_overlay.to_local(rect_b.position + Vector2(rect_b.size.x * 0.5, rect_b.size.y * 0.18))
		var arc_y: float = min(p1.y, p2.y) - 18.0
		var v1: Vector2 = Vector2(p1.x, arc_y)
		var v2: Vector2 = Vector2(p2.x, arc_y)

		var broken: bool = bool(line_data.get("broken", false))
		var color_value: Color = Color(1.0, 0.34, 0.34, 0.95) if broken else Color(1.0, 0.82, 0.35, 0.86)
		var width: float = 2.2 if broken else 1.7

		_draw_dependency_segment(p1, v1, color_value, width, broken)
		_draw_dependency_segment(v1, v2, color_value, width, broken)
		_draw_dependency_segment(v2, p2, color_value, width, broken)

func _draw_dependency_segment(from_point: Vector2, to_point: Vector2, color_value: Color, width: float, broken: bool) -> void:
	if dependency_overlay == null:
		return
	if not broken:
		dependency_overlay.draw_line(from_point, to_point, color_value, width, true)
		return

	var delta: Vector2 = to_point - from_point
	var dist: float = delta.length()
	if dist <= 2.0:
		return
	var dir: Vector2 = delta / dist
	var gap: float = min(14.0, dist * 0.48)
	var segment_len: float = (dist - gap) * 0.5
	if segment_len <= 0.0:
		return
	var first_end: Vector2 = from_point + dir * segment_len
	var second_start: Vector2 = to_point - dir * segment_len
	dependency_overlay.draw_line(from_point, first_end, color_value, width, true)
	dependency_overlay.draw_line(second_start, to_point, color_value, width, true)

func _trigger_glitch() -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("glitch_strength", 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(func(value: float) -> void: shader_material.set_shader_parameter("glitch_strength", value), 1.0, 0.0, 0.25)

func _shake_main_layout() -> void:
	var origin: Vector2 = main_layout.position
	var tween: Tween = create_tween()
	for _i in 4:
		tween.tween_property(main_layout, "position", origin + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), 0.03)
	tween.tween_property(main_layout, "position", origin, 0.04)

func _outcome_code_for_b(is_correct: bool, error_code: String, violations: Array, scan_triggered_glitch: bool) -> String:
	if is_correct:
		return "SUCCESS"
	var normalized_error: String = error_code.strip_edges().to_upper()
	if normalized_error in ["LOGIC_GAP", "CAUSALITY_LOOP"]:
		return "DEPENDENCY_VIOLATION"
	if normalized_error == "ORDER_MISMATCH":
		return "ORDER_WRONG"
	if violations.is_empty():
		return "TIMELINE_WRONG"
	if not scan_triggered_glitch:
		return "SCAN_FAIL"
	return "DEPENDENCY_VIOLATION"

func _mastery_block_reason_for_b(is_correct: bool, outcome_code: String) -> String:
	if reset_count_local >= 3:
		return "RESET_OVERUSE"
	if confirm_attempt_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if not is_correct:
		if outcome_code == "DEPENDENCY_VIOLATION" and not changed_after_scan:
			return "DEPENDENCY_IGNORED"
		if scan_run_count > 0 and not changed_after_scan:
			return "SCAN_DEPENDENCY"
		if reorder_count >= 6:
			return "TIMELINE_INSTABILITY"
	return "NONE"

func _show_error(message: String) -> void:
	_set_status(message, COLOR_ERR)
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var t_ms: int = _elapsed_ms_now()
	var event_payload: Dictionary = data.duplicate(true)
	var event_row: Dictionary = {
		"name": event_name,
		"event": event_name,
		"t_ms": t_ms,
		"payload": event_payload.duplicate(true),
		"data": event_payload.duplicate(true)
	}
	trace.append(event_row)
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": t_ms,
		"payload": event_payload.duplicate(true)
	})
	task_session["events"] = events

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	var overlay_controller: Node = get_node_or_null("CanvasLayer")
	if overlay_controller != null and overlay_controller.has_method("set_danger_level"):
		overlay_controller.call("set_danger_level", GlobalMetrics.stability)
		return
	var shared_overlay: Node = get_tree().get_first_node_in_group("noir_overlay")
	if shared_overlay != null and shared_overlay.has_method("set_danger_level"):
		shared_overlay.call("set_danger_level", GlobalMetrics.stability)
