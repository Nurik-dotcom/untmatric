extends Control

const LEVELS_PATH := "res://data/final_report_a_levels.json"
const FR8Data := preload("res://scripts/case_08/fr8_data.gd")
const FR8Scoring := preload("res://scripts/case_08/fr8_scoring.gd")
const TAG_FRAGMENT_SCENE: PackedScene = preload("res://scenes/ui/TagFragmentItem.tscn")
const TAG_SLOT_SCENE: PackedScene = preload("res://scenes/ui/TagSlotZone.tscn")

const COLOR_OK := Color(0.55, 0.95, 0.62, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)
const COLOR_INFO := Color(0.84, 0.84, 0.84, 1.0)

const TEXT_BACK := "\u041d\u0410\u0417\u0410\u0414"
const TEXT_RESET := "\u0421\u0411\u0420\u041e\u0421"
const TEXT_CONFIRM := "\u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c"
const TEXT_NEXT := "\u0414\u0410\u041b\u0415\u0415"
const TEXT_FINISH := "\u0417\u0410\u0412\u0415\u0420\u0428\u0418\u0422\u042c"

const STATUS_HINT := "\u041f\u0435\u0440\u0435\u0442\u0430\u0449\u0438\u0442\u0435 \u0444\u0440\u0430\u0433\u043c\u0435\u043d\u0442\u044b \u0432 \u0441\u043b\u043e\u0442\u044b \u0440\u0435\u0434\u0430\u043a\u0442\u043e\u0440\u0430\u2026"
const STATUS_INCOMPLETE := "\u041d\u0435 \u0432\u0441\u0435 \u0444\u0440\u0430\u0433\u043c\u0435\u043d\u0442\u044b \u0432\u0441\u0442\u0430\u0432\u043b\u0435\u043d\u044b"
const STATUS_NEXT_HINT := "\u0413\u043e\u0442\u043e\u0432\u043e. \u0416\u043c\u0438\u0442\u0435 \u0414\u0410\u041b\u0415\u0415."
const STATUS_SOLVE_FIRST := "\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u0440\u0435\u0448\u0438\u0442\u0435 \u0443\u0440\u043e\u0432\u0435\u043d\u044c"

var levels: Array = []
var level_data: Dictionary = {}
var fragments_data: Array = []

var slot_ids: Array[String] = []
var expected_sequence: Array[String] = []
var fragment_by_id: Dictionary = {}
var slot_nodes: Dictionary = {}
var fragment_nodes: Dictionary = {}

var current_level_index: int = 0
var start_time_ms: int = 0
var drag_count: int = 0
var swap_count: int = 0
var trace: Array = []

var level_solved: bool = false
var confirm_locked: bool = false

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var body: BoxContainer = $SafeArea/MainLayout/Body
@onready var fragments_card: PanelContainer = $SafeArea/MainLayout/Body/FragmentsCard
@onready var editor_card: PanelContainer = $SafeArea/MainLayout/Body/EditorCard
@onready var pile_zone: Node = $SafeArea/MainLayout/Body/FragmentsCard/CardVBox/PileZone
@onready var slots_grid: GridContainer = $SafeArea/MainLayout/Body/EditorCard/CardVBox/SlotsGrid
@onready var code_preview: RichTextLabel = $SafeArea/MainLayout/Body/EditorCard/CardVBox/CodePreviewCard/CodePreview
@onready var status_label: Label = $SafeArea/MainLayout/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainLayout/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainLayout/BottomBar/BtnConfirm
@onready var btn_next: Button = $SafeArea/MainLayout/BottomBar/BtnNext
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var title_label: Label = $SafeArea/MainLayout/Header/TitleLabel
@onready var level_label: Label = $SafeArea/MainLayout/Header/LevelLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainLayout/Header/StabilityBar
@onready var briefing_label: Label = $SafeArea/MainLayout/BriefingCard/BriefingLabel
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

func _ready() -> void:
	add_to_group("fr8_drop_controller")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error("\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0443\u0440\u043e\u0432\u043d\u0438 Final Report A.")
		return

	title_label.text = "\u0414\u0415\u041b\u041e #8: \u0424\u0418\u041d\u0410\u041b\u042c\u041d\u042b\u0419 \u041e\u0422\u0427\u0415\u0422"
	btn_back.text = TEXT_BACK
	btn_reset.text = TEXT_RESET
	btn_confirm.text = TEXT_CONFIRM
	btn_next.text = TEXT_NEXT

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_on_viewport_size_changed()

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _load_levels() -> void:
	levels = FR8Data.load_levels(LEVELS_PATH)

func _start_level(index: int) -> void:
	if levels.is_empty():
		return

	current_level_index = clamp(index, 0, levels.size() - 1)
	GlobalMetrics.current_level_index = current_level_index
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)
	fragments_data = (level_data.get("fragments", []) as Array).duplicate(true)

	slot_ids.clear()
	for slot_var in level_data.get("slots", []) as Array:
		slot_ids.append(str(slot_var))

	expected_sequence = FR8Scoring.normalize_expected_sequence(level_data)
	fragment_by_id.clear()
	for fragment_var in fragments_data:
		if typeof(fragment_var) != TYPE_DICTIONARY:
			continue
		var fragment_data: Dictionary = fragment_var as Dictionary
		fragment_by_id[str(fragment_data.get("fragment_id", ""))] = fragment_data

	level_label.text = _build_level_label()
	briefing_label.text = str(level_data.get("briefing", ""))

	if pile_zone.has_method("setup"):
		pile_zone.call("setup", "PILE", "\u0421\u041a\u041b\u0410\u0414 \u0424\u0420\u0410\u0413\u041c\u0415\u041d\u0422\u041e\u0412")
	_connect_zone_signal(pile_zone)

	_build_slot_nodes()
	_reset_attempt(true)

func _build_level_label() -> String:
	return "A | %s (%d/%d)" % [
		str(level_data.get("id", "FR8-A")),
		current_level_index + 1,
		levels.size()
	]

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

func _build_slot_nodes() -> void:
	for child in slots_grid.get_children():
		child.queue_free()
	slot_nodes.clear()

	for slot_id in slot_ids:
		var slot_node: Node = TAG_SLOT_SCENE.instantiate()
		slots_grid.add_child(slot_node)
		if slot_node.has_method("setup"):
			slot_node.call("setup", slot_id, slot_id)
		_connect_zone_signal(slot_node)
		slot_nodes[slot_id] = slot_node

func _connect_zone_signal(zone_node: Node) -> void:
	if zone_node == null:
		return
	if not zone_node.has_signal("item_placed"):
		return
	var callback: Callable = Callable(self, "_on_item_placed")
	if not zone_node.is_connected("item_placed", callback):
		zone_node.connect("item_placed", callback)

func _reset_attempt(is_level_start: bool = false) -> void:
	for slot_id in slot_ids:
		var slot_node: Node = slot_nodes.get(slot_id, null)
		if slot_node != null and slot_node.has_method("clear_items"):
			slot_node.call("clear_items")

	if pile_zone.has_method("clear_items"):
		pile_zone.call("clear_items")

	_spawn_fragments_into_pile()

	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	swap_count = 0
	trace.clear()
	_log_event("RESET", {"level_start": is_level_start})

	level_solved = false
	confirm_locked = false
	btn_confirm.disabled = false
	btn_next.disabled = true
	btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT

	_set_status(STATUS_HINT, COLOR_INFO)
	_update_code_preview()
	_update_slot_feedback()
	_update_stability_ui()

func _spawn_fragments_into_pile() -> void:
	fragment_nodes.clear()
	var shuffled_fragments: Array = fragments_data.duplicate(true)
	shuffled_fragments.shuffle()

	for fragment_var in shuffled_fragments:
		if typeof(fragment_var) != TYPE_DICTIONARY:
			continue
		var fragment_data: Dictionary = fragment_var as Dictionary
		var item_node: Node = TAG_FRAGMENT_SCENE.instantiate()
		if not (item_node is Control):
			continue

		if item_node.has_method("setup"):
			item_node.call("setup", fragment_data)
		item_node.set_meta("fragment_id", str(fragment_data.get("fragment_id", "")))
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_drag_started"))

		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_node)

		var fragment_id: String = str(fragment_data.get("fragment_id", ""))
		if not fragment_id.is_empty():
			fragment_nodes[fragment_id] = item_node

func _on_drag_started(fragment_id: String, from_zone: String) -> void:
	drag_count += 1
	_log_event("DRAG_START", {
		"fragment_id": fragment_id,
		"from_zone": from_zone
	})

func _on_item_placed(fragment_id: String, to_zone: String, from_zone: String) -> void:
	_log_event("ITEM_PLACED", {
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"to_zone": to_zone
	})
	_update_code_preview()
	_update_slot_feedback()
	_set_status(STATUS_HINT, COLOR_INFO)

func handle_drop_to_slot(target_zone_id: String, payload: Dictionary) -> Dictionary:
	if not slot_nodes.has(target_zone_id):
		return {"success": false}

	var parsed: Dictionary = _parse_payload(payload)
	if parsed.is_empty():
		return {"success": false}

	var fragment_id: String = str(parsed.get("fragment_id", ""))
	var from_zone: String = str(parsed.get("from_zone", "PILE"))

	if _fragment_zone(fragment_id) == target_zone_id:
		return {"success": false}

	var target_existing_id: String = _fragment_in_slot(target_zone_id)
	var swapped: bool = false
	if not target_existing_id.is_empty() and target_existing_id != fragment_id:
		var return_zone: String = from_zone
		if not _zone_exists(return_zone) or return_zone == target_zone_id:
			return_zone = "PILE"
		if not _move_fragment_to_zone(target_existing_id, return_zone):
			return {"success": false}
		swapped = true

	if not _move_fragment_to_zone(fragment_id, target_zone_id):
		return {"success": false}

	if swapped:
		swap_count += 1

	return {
		"success": true,
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"to_zone": target_zone_id,
		"swapped": swapped
	}

func handle_drop_to_pile(payload: Dictionary) -> Dictionary:
	var parsed: Dictionary = _parse_payload(payload)
	if parsed.is_empty():
		return {"success": false}

	var fragment_id: String = str(parsed.get("fragment_id", ""))
	var from_zone: String = str(parsed.get("from_zone", "PILE"))
	if _fragment_zone(fragment_id) == "PILE":
		return {"success": false}

	if not _move_fragment_to_zone(fragment_id, "PILE"):
		return {"success": false}

	return {
		"success": true,
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"to_zone": "PILE",
		"swapped": false
	}

func _parse_payload(payload: Dictionary) -> Dictionary:
	if str(payload.get("kind", "")) != "TAG_FRAGMENT":
		return {}
	var fragment_id: String = str(payload.get("fragment_id", "")).strip_edges()
	if fragment_id.is_empty() or not fragment_nodes.has(fragment_id):
		return {}
	return {
		"fragment_id": fragment_id,
		"from_zone": str(payload.get("from_zone", "PILE"))
	}

func _zone_exists(zone_id: String) -> bool:
	if zone_id == "PILE":
		return true
	return slot_nodes.has(zone_id)

func _zone_by_id(zone_id: String) -> Node:
	if zone_id == "PILE":
		return pile_zone
	return slot_nodes.get(zone_id, null) as Node

func _move_fragment_to_zone(fragment_id: String, zone_id: String) -> bool:
	var fragment_node: Node = fragment_nodes.get(fragment_id, null) as Node
	if fragment_node == null:
		return false
	var zone_node: Node = _zone_by_id(zone_id)
	if zone_node == null:
		return false
	if not zone_node.has_method("add_item_control"):
		return false
	zone_node.call("add_item_control", fragment_node)
	return true

func _fragment_zone(fragment_id: String) -> String:
	var fragment_node: Node = fragment_nodes.get(fragment_id, null) as Node
	if fragment_node == null:
		return "PILE"
	if fragment_node.has_method("get_zone_id"):
		return str(fragment_node.call("get_zone_id"))
	return str(fragment_node.get_meta("zone_id", "PILE"))

func _fragment_in_slot(slot_id: String) -> String:
	var slot_node: Node = slot_nodes.get(slot_id, null) as Node
	if slot_node == null:
		return ""
	if slot_node.has_method("get_current_fragment_id"):
		return str(slot_node.call("get_current_fragment_id")).strip_edges()
	return ""

func _collect_sequence() -> Array[String]:
	var sequence: Array[String] = []
	for slot_id in slot_ids:
		sequence.append(_fragment_in_slot(slot_id))
	return sequence

func _build_snapshot_zones() -> Dictionary:
	var snapshot: Dictionary = {}
	for fragment_id_var in fragment_by_id.keys():
		var fragment_id: String = str(fragment_id_var)
		snapshot[fragment_id] = _fragment_zone(fragment_id)
	return snapshot

func _on_confirm_pressed() -> void:
	if confirm_locked:
		return

	var sequence: Array[String] = _collect_sequence()
	var snapshot_zones: Dictionary = _build_snapshot_zones()
	var elapsed_ms: int = Time.get_ticks_msec() - start_time_ms
	_log_event("CONFIRM_PRESSED", {
		"sequence": sequence.duplicate(),
		"filled_slots": _count_filled_slots(sequence)
	})

	var evaluation: Dictionary = FR8Scoring.evaluate(level_data, sequence, fragment_by_id)
	var score: Dictionary = FR8Scoring.resolve_score(level_data, evaluation)
	var checks: Dictionary = evaluation.get("checks", {
		"container_ok": false,
		"hierarchy_ok": false,
		"order_ok": false
	}) as Dictionary

	var points: int = int(score.get("points", 0))
	var max_points: int = int(score.get("max_points", 2))
	var is_fit: bool = bool(score.get("is_fit", false))
	var is_correct: bool = bool(score.get("is_correct", false))
	var stability_delta: int = int(score.get("stability_delta", 0))
	var verdict_code: String = str(score.get("verdict_code", "FAIL"))
	var error_code: String = str(evaluation.get("error_code", "FAIL"))
	var level_id: String = str(level_data.get("id", "FR8-A-00"))
	var match_key: String = "FR8_A|%s|%d" % [level_id, GlobalMetrics.session_history.size()]

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "A",
		"level_id": level_id,
		"format": "TAG_ORDERING",
		"match_key": match_key,
		"sequence": sequence,
		"snapshot_zones": snapshot_zones,
		"error_code": error_code,
		"checks": {
			"container_ok": bool(checks.get("container_ok", false)),
			"hierarchy_ok": bool(checks.get("hierarchy_ok", false)),
			"order_ok": bool(checks.get("order_ok", false))
		},
		"elapsed_ms": elapsed_ms,
		"drag_count": drag_count,
		"swap_count": swap_count,
		"points": points,
		"max_points": max_points,
		"is_fit": is_fit,
		"is_correct": is_correct,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	var feedback_text: String = FR8Scoring.feedback_text(level_data, evaluation)
	if verdict_code == "PERFECT":
		level_solved = true
		confirm_locked = true
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT
		_set_status("%s %s" % [feedback_text, STATUS_NEXT_HINT], COLOR_OK)
	elif verdict_code == "PARTIAL":
		level_solved = false
		confirm_locked = false
		btn_next.disabled = true
		_set_status(feedback_text, COLOR_WARN)
	else:
		level_solved = false
		confirm_locked = false
		btn_next.disabled = true
		if error_code == "INCOMPLETE":
			_set_status(STATUS_INCOMPLETE, COLOR_ERR)
		else:
			_set_status(feedback_text, COLOR_ERR)

	_play_confirm_audio(verdict_code)
	if verdict_code in ["FAIL", "EMPTY"]:
		_trigger_glitch()
		_shake_main_layout()

func _on_next_pressed() -> void:
	if not level_solved:
		_set_status(STATUS_SOLVE_FIRST, COLOR_WARN)
		return

	var from_level_id: String = str(level_data.get("id", "FR8-A-00"))
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

func _play_confirm_audio(verdict_code: String) -> void:
	if AudioManager == null:
		return
	match verdict_code:
		"PERFECT":
			AudioManager.play("relay")
		"FAIL", "EMPTY":
			AudioManager.play("error")
		_:
			AudioManager.play("click")

func _count_filled_slots(sequence: Array[String]) -> int:
	var filled: int = 0
	for fragment_id in sequence:
		if not str(fragment_id).is_empty():
			filled += 1
	return filled

func _update_code_preview() -> void:
	var lines: Array[String] = []
	for i in range(slot_ids.size()):
		var slot_id: String = slot_ids[i]
		var fragment_id: String = _fragment_in_slot(slot_id)
		var token: String = "____"
		if not fragment_id.is_empty() and fragment_by_id.has(fragment_id):
			var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
			token = str(fragment_data.get("token", fragment_data.get("label", fragment_id)))
		lines.append("%s  %s" % [slot_id, token])
	code_preview.text = "[code]%s[/code]" % "\n".join(lines)

func _update_slot_feedback() -> void:
	for i in range(slot_ids.size()):
		var slot_id: String = slot_ids[i]
		var slot_node: Node = slot_nodes.get(slot_id, null) as Node
		if slot_node == null or not slot_node.has_method("set_feedback_state"):
			continue
		var actual_fragment_id: String = _fragment_in_slot(slot_id)
		var expected_fragment_id: String = expected_sequence[i] if i < expected_sequence.size() else ""
		if actual_fragment_id.is_empty():
			slot_node.call("set_feedback_state", "neutral")
		elif actual_fragment_id == expected_fragment_id and not expected_fragment_id.is_empty():
			slot_node.call("set_feedback_state", "ok")
		else:
			slot_node.call("set_feedback_state", "bad")

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
	var landscape: bool = viewport_size.x > viewport_size.y
	body.vertical = not landscape

	if landscape:
		if body.get_child(0) != fragments_card:
			body.move_child(fragments_card, 0)
			body.move_child(editor_card, 1)
		slots_grid.columns = 3 if slot_ids.size() >= 6 else 2
		if pile_zone.has_method("set_grid_columns"):
			pile_zone.call("set_grid_columns", 3 if viewport_size.x >= 1280.0 else 2)
	else:
		if body.get_child(0) != editor_card:
			body.move_child(editor_card, 0)
			body.move_child(fragments_card, 1)
		slots_grid.columns = 2
		if pile_zone.has_method("set_grid_columns"):
			pile_zone.call("set_grid_columns", 2)

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
