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
var trace: Array = []

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var title_label: Label = $SafeArea/MainLayout/Header/TitleLabel
@onready var level_label: Label = $SafeArea/MainLayout/Header/LevelLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainLayout/Header/StabilityBar
@onready var briefing_label: RichTextLabel = $SafeArea/MainLayout/BriefingCard/BriefingLabel
@onready var cards_row: HBoxContainer = $SafeArea/MainLayout/TimelineCard/CardVBox/CardsRow
@onready var status_label: Label = $SafeArea/MainLayout/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainLayout/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainLayout/BottomBar/BtnConfirm
@onready var btn_next: Button = $SafeArea/MainLayout/BottomBar/BtnNext
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error("\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0443\u0440\u043e\u0432\u043d\u0438 Final Report B.")
		return

	title_label.text = TEXT_TITLE
	btn_back.text = TEXT_BACK
	btn_reset.text = TEXT_RESET
	btn_confirm.text = TEXT_CONFIRM
	btn_next.text = TEXT_NEXT

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_apply_layout_mode()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _load_levels() -> void:
	levels = FR8BData.load_levels(LEVELS_PATH)
	if SESSION_LEVEL_COUNT > 0 and levels.size() > SESSION_LEVEL_COUNT:
		var limited: Array = []
		for i in range(SESSION_LEVEL_COUNT):
			limited.append(levels[i])
		levels = limited

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
	swap_count = 0
	reset_count = 0
	start_time_ms = Time.get_ticks_msec()
	time_to_first_action_ms = -1
	trace.clear()

	level_label.text = _build_level_label()
	briefing_label.text = str(level_data.get("briefing", ""))

	_log_event("LEVEL_START", {
		"level_id": str(level_data.get("id", "FR8-B")),
		"index": current_level_index
	})
	_reset_attempt(true)
	_update_stability_ui()
	_apply_layout_mode()

func _build_level_label() -> String:
	return "B | %s (%d/%d)" % [
		str(level_data.get("id", "FR8-B")),
		current_level_index + 1,
		levels.size()
	]

func _expected_order() -> Array[String]:
	var out: Array[String] = []
	for stage_var in level_data.get("expected_order", []) as Array:
		out.append(str(stage_var).strip_edges())
	return out

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

func _reset_attempt(is_level_start: bool = false) -> void:
	current_order = initial_order.duplicate()
	if not is_level_start:
		_mark_first_action()
		reset_count += 1

	_log_event("RESET", {"level_start": is_level_start})

	trial_locked = false
	level_solved = false
	btn_confirm.disabled = false
	btn_next.disabled = true
	btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT

	_rebuild_cards()
	_set_status(STATUS_HINT, COLOR_INFO)

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
			card_node.call("setup", cards_by_stage_id[stage_id])
		if card_node.has_method("set_move_enabled"):
			card_node.call("set_move_enabled", i > 0 and not trial_locked, i < current_order.size() - 1 and not trial_locked)
		if card_node.has_signal("move_requested"):
			card_node.connect("move_requested", Callable(self, "_on_card_move_requested"))
		if card_node.has_signal("hint_requested"):
			card_node.connect("hint_requested", Callable(self, "_on_card_hint_requested"))

	_apply_layout_mode()

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

	var other_stage: String = current_order[target_index]
	current_order[target_index] = stage_id
	current_order[index] = other_stage
	swap_count += 1

	_log_event("MOVE_CARD", {
		"stage_id": stage_id,
		"from_index": index,
		"to_index": target_index,
		"dir": dir
	})

	_rebuild_cards()
	_set_status(STATUS_HINT, COLOR_INFO)
	if AudioManager != null:
		AudioManager.play("click")

func _on_card_hint_requested(stage_id: String) -> void:
	_mark_first_action()
	_log_event("HINT_REQUESTED", {"stage_id": stage_id})

	var hint_text: String = ""
	if cards_by_stage_id.has(stage_id):
		var card_data: Dictionary = cards_by_stage_id.get(stage_id, {}) as Dictionary
		hint_text = str(card_data.get("hint", "")).strip_edges()

	if hint_text.is_empty():
		_set_status(STATUS_HINT, COLOR_INFO)
	else:
		_set_status(hint_text, COLOR_INFO)

	if AudioManager != null:
		AudioManager.play("click")

func _on_confirm_pressed() -> void:
	if trial_locked:
		return

	_mark_first_action()
	_log_event("CONFIRM_PRESSED", {
		"final_order": current_order.duplicate()
	})

	var evaluation: Dictionary = FR8BScoring.evaluate(level_data, current_order)
	var score: Dictionary = FR8BScoring.resolve_score(level_data, evaluation)
	var feedback_text: String = FR8BScoring.feedback_text(level_data, evaluation)

	var elapsed_ms: int = Time.get_ticks_msec() - start_time_ms
	var tffa_ms: int = elapsed_ms if time_to_first_action_ms < 0 else time_to_first_action_ms
	var level_id: String = str(level_data.get("id", "FR8-B-00"))
	var verdict_code: String = str(score.get("verdict_code", "FAIL"))
	var error_code: String = str(evaluation.get("error_code", "ORDER_MISMATCH"))
	var match_key: String = "FR8_B|%s|%d" % [level_id, GlobalMetrics.session_history.size()]

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "B",
		"level_id": level_id,
		"format": "TIMELINE_SORT",
		"match_key": match_key,
		"initial_order": initial_order.duplicate(),
		"final_order": current_order.duplicate(),
		"violations": (evaluation.get("violations", []) as Array).duplicate(true),
		"error_code": error_code,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": tffa_ms,
		"swap_count": swap_count,
		"reset_count": reset_count,
		"points": int(score.get("points", 0)),
		"max_points": int(score.get("max_points", 2)),
		"is_fit": bool(score.get("is_fit", false)),
		"is_correct": bool(score.get("is_correct", false)),
		"stability_delta": int(score.get("stability_delta", -25)),
		"verdict_code": verdict_code,
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	if verdict_code == "PERFECT":
		level_solved = true
		trial_locked = true
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT
		_set_status("%s %s" % [feedback_text, STATUS_NEXT_HINT], COLOR_OK)
		_rebuild_cards()
		if AudioManager != null:
			AudioManager.play("relay")
	else:
		level_solved = false
		trial_locked = false
		btn_confirm.disabled = false
		btn_next.disabled = true
		_set_status(feedback_text, COLOR_ERR)
		_trigger_glitch()
		_shake_main_layout()
		if AudioManager != null:
			AudioManager.play("error")

func _on_next_pressed() -> void:
	if not level_solved:
		_set_status(STATUS_SOLVE_FIRST, COLOR_WARN)
		return

	var from_level_id: String = str(level_data.get("id", "FR8-B-00"))
	var from_index: int = current_level_index
	if _is_last_level():
		_log_event("NEXT_PRESSED", {
			"from_level_id": from_level_id,
			"from_index": from_index,
			"to_index": -1
		})
		GlobalMetrics.current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return

	var to_index: int = current_level_index + 1
	_log_event("NEXT_PRESSED", {
		"from_level_id": from_level_id,
		"from_index": from_index,
		"to_index": to_index
	})
	_start_level(to_index)

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

func _mark_first_action() -> void:
	if time_to_first_action_ms >= 0:
		return
	time_to_first_action_ms = Time.get_ticks_msec() - start_time_ms

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

func _show_error(message: String) -> void:
	_set_status(message, COLOR_ERR)
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - start_time_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability