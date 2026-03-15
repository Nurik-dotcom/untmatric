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
const RENDER_ERROR := "[РЕНДЕР ОШИБКА]"
const RENDER_WARN := "РЕНДЕР: НЕСТАБИЛЬНЫЙ"
const RENDER_OK := "РЕНДЕР ГОТОВ"

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
var confirm_attempt_count: int = 0
var skip_unlocked: bool = false
var selected_fragment_id: String = ""
var trial_seq: int = 0
var task_session: Dictionary = {}

var fragment_drag_start_count: int = 0
var fragment_drop_count: int = 0
var fragment_replace_count: int = 0
var fragment_remove_count: int = 0
var unique_fragment_ids: Dictionary = {}
var slot_focus_count: int = 0
var reset_count_local: int = 0
var confirm_attempt_total_count: int = 0
var incomplete_confirm_count: int = 0
var render_preview_update_count: int = 0
var render_ok_seen: bool = false
var render_warn_seen: bool = false
var render_error_seen: bool = false
var changed_after_render_warn: bool = false
var changed_after_render_error: bool = false
var time_to_first_action_ms: int = -1
var time_to_first_drag_ms: int = -1
var time_to_first_drop_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_edit_to_confirm_ms: int = -1
var last_edit_ms: int = -1

var level_solved: bool = false
var confirm_locked: bool = false
var has_confirmed_once: bool = false
var last_render_state: String = ""
var _body_scroll_installed: bool = false

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var body: BoxContainer = $SafeArea/MainLayout/Body
@onready var fragments_card: PanelContainer = $SafeArea/MainLayout/Body/FragmentsCard
@onready var editor_card: PanelContainer = $SafeArea/MainLayout/Body/EditorCard
@onready var fragments_title_label: Label = $SafeArea/MainLayout/Body/FragmentsCard/CardVBox/FragmentsTitle
@onready var editor_title_label: Label = $SafeArea/MainLayout/Body/EditorCard/CardVBox/EditorTitle
@onready var render_header_label: Label = $SafeArea/MainLayout/Body/EditorCard/CardVBox/RenderPreviewCard/RenderVBox/RenderHeader
@onready var slots_title_label: Label = $SafeArea/MainLayout/Body/EditorCard/CardVBox/SlotsTitle
@onready var pile_zone: Node = $SafeArea/MainLayout/Body/FragmentsCard/CardVBox/PileZone
@onready var slots_grid: GridContainer = $SafeArea/MainLayout/Body/EditorCard/CardVBox/SlotsGrid
@onready var code_preview: RichTextLabel = $SafeArea/MainLayout/Body/EditorCard/CardVBox/CodePreviewCard/CodePreview
@onready var render_status: Label = $SafeArea/MainLayout/Body/EditorCard/CardVBox/RenderPreviewCard/RenderVBox/RenderStatus
@onready var render_preview: RichTextLabel = $SafeArea/MainLayout/Body/EditorCard/CardVBox/RenderPreviewCard/RenderVBox/RenderPreview
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
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error(_tr("case08.fr8a.load_error", "Не удалось загрузить уровни финального отчёта A."))
		return

	title_label.text = "\u0414\u0415\u041b\u041e #8: \u0424\u0418\u041d\u0410\u041b\u042c\u041d\u042b\u0419 \u041e\u0422\u0427\u0415\u0422"
	btn_back.text = TEXT_BACK
	btn_reset.text = TEXT_RESET
	btn_confirm.text = TEXT_CONFIRM
	btn_next.text = TEXT_NEXT
	_apply_i18n()
	_install_body_scroll()

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_on_viewport_size_changed()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if levels.is_empty():
		return
	briefing_label.text = I18n.resolve_field(level_data, "briefing")
	if pile_zone.has_method("setup"):
		pile_zone.call("setup", "PILE", _tr("case08.fr8a.pile_title", "СКЛАД ФРАГМЕНТОВ"))
	_refresh_fragment_node_labels()
	_update_code_preview()
	_update_render_preview(_collect_sequence())
	if has_confirmed_once:
		var sequence: Array[String] = _collect_sequence()
		var evaluation: Dictionary = FR8Scoring.evaluate(level_data, sequence, fragment_by_id)
		var score: Dictionary = FR8Scoring.resolve_score(level_data, evaluation)
		var verdict_code: String = str(score.get("verdict_code", "FAIL"))
		var error_code: String = str(evaluation.get("error_code", "FAIL"))
		var feedback_text: String = FR8Scoring.feedback_text(level_data, evaluation)
		if verdict_code == "PERFECT":
			_set_status("%s %s" % [feedback_text, _tr("case08.fr8a.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)
		elif verdict_code == "PARTIAL":
			_set_status(feedback_text, COLOR_WARN)
		elif error_code == "INCOMPLETE":
			_set_status(_tr("case08.fr8a.status.incomplete", STATUS_INCOMPLETE), COLOR_ERR)
		else:
			_set_status(feedback_text, COLOR_ERR)
	else:
		_set_status(_tr("case08.fr8a.status.hint", STATUS_HINT), COLOR_INFO)

func _apply_i18n() -> void:
	title_label.text = _tr("case08.fr8a.title", "ДЕЛО #8: ФИНАЛЬНЫЙ ОТЧЕТ")
	btn_back.text = _tr("case08.common.back", TEXT_BACK)
	btn_reset.text = _tr("case08.common.reset", TEXT_RESET)
	btn_confirm.text = _tr("case08.common.confirm", TEXT_CONFIRM)
	btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if (not levels.is_empty() and _is_last_level()) else _tr("case08.common.next", TEXT_NEXT)
	fragments_title_label.text = _tr("case08.fr8a.fragments_title", "СКЛАД ФРАГМЕНТОВ")
	editor_title_label.text = _tr("case08.fr8a.editor_title", "РЕДАКТОР")
	render_header_label.text = _tr("case08.fr8a.render_header", "LIVE PREVIEW")
	slots_title_label.text = _tr("case08.fr8a.slots_title", "СЛОТЫ")

func _refresh_fragment_node_labels() -> void:
	for fragment_id_var in fragment_nodes.keys():
		var fragment_id: String = str(fragment_id_var)
		var fragment_node: Node = fragment_nodes.get(fragment_id, null) as Node
		if fragment_node == null or not (fragment_node is Button):
			continue
		var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
		var label_text: String = I18n.resolve_field(fragment_data, "label", {"default": str(fragment_data.get("label", fragment_id))})
		(fragment_node as Button).text = label_text

func _localized_fragment_data(raw_fragment: Dictionary) -> Dictionary:
	var localized: Dictionary = raw_fragment.duplicate(true)
	localized["label"] = I18n.resolve_field(raw_fragment, "label", {"default": str(raw_fragment.get("label", ""))})
	localized["token"] = I18n.resolve_field(raw_fragment, "token", {"default": str(raw_fragment.get("token", localized.get("label", "")))})
	return localized

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	if not merged.has("default"):
		merged["default"] = default_text
	return I18n.tr_key(key, merged)

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
	briefing_label.text = I18n.resolve_field(level_data, "briefing")

	if pile_zone.has_method("setup"):
		pile_zone.call("setup", "PILE", _tr("case08.fr8a.pile_title", "СКЛАД ФРАГМЕНТОВ"))
	_connect_zone_signal(pile_zone)

	_build_slot_nodes()
	_begin_trial_session()
	_reset_attempt(true)

func _build_level_label() -> String:
	return "A | %s (%d/%d)" % [
		str(level_data.get("id", "FR8-A")),
		current_level_index + 1,
		levels.size()
	]

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

func _begin_trial_session() -> void:
	trial_seq += 1
	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	swap_count = 0
	trace.clear()

	fragment_drag_start_count = 0
	fragment_drop_count = 0
	fragment_replace_count = 0
	fragment_remove_count = 0
	unique_fragment_ids.clear()
	slot_focus_count = 0
	reset_count_local = 0
	confirm_attempt_total_count = 0
	incomplete_confirm_count = 0
	render_preview_update_count = 0
	render_ok_seen = false
	render_warn_seen = false
	render_error_seen = false
	changed_after_render_warn = false
	changed_after_render_error = false
	time_to_first_action_ms = -1
	time_to_first_drag_ms = -1
	time_to_first_drop_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_edit_to_confirm_ms = -1
	last_edit_ms = -1

	var level_id: String = str(level_data.get("id", "FR8-A-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage_id": "A",
		"task_id": level_id,
		"started_at_ticks": start_time_ms,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"level_id": level_id,
		"briefing": str(I18n.resolve_field(level_data, "briefing")),
		"required_slot_count": expected_sequence.size(),
		"profile": str(level_data.get("validator_profile", FR8Scoring.PROFILE_LIST_BASIC))
	})

func _elapsed_ms_now() -> int:
	if start_time_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - start_time_ms)

func _mark_first_action() -> void:
	if time_to_first_action_ms >= 0:
		return
	time_to_first_action_ms = _elapsed_ms_now()

func _mark_edit_action() -> void:
	_mark_first_action()
	last_edit_ms = _elapsed_ms_now()
	if render_warn_seen and last_render_state == "warn":
		changed_after_render_warn = true
	if render_error_seen and last_render_state == "error":
		changed_after_render_error = true

func _fragment_tag_label(fragment_id: String) -> String:
	if fragment_id.is_empty():
		return ""
	return _token_for_fragment(fragment_id)

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
		if slot_node.has_signal("slot_tapped"):
			slot_node.connect("slot_tapped", Callable(self, "_on_slot_tapped"))
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

	confirm_attempt_count = 0
	skip_unlocked = false
	selected_fragment_id = ""
	last_render_state = ""
	if not is_level_start:
		reset_count_local += 1
		_log_event("reset_pressed", {"reset_count": reset_count_local})
	_log_event("attempt_reset", {"level_start": is_level_start})

	level_solved = false
	confirm_locked = false
	has_confirmed_once = false
	_clear_fragment_highlights()
	btn_confirm.disabled = false
	btn_next.disabled = true
	btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)

	_set_status(_tr("case08.fr8a.status.hint", STATUS_HINT), COLOR_INFO)
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
			item_node.call("setup", _localized_fragment_data(fragment_data))
		item_node.set_meta("fragment_id", str(fragment_data.get("fragment_id", "")))
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_drag_started"))
		if item_node.has_signal("tapped"):
			item_node.connect("tapped", Callable(self, "_on_fragment_tapped"))
		elif item_node is Button:
			(item_node as Button).pressed.connect(_on_fragment_tapped.bind(str(fragment_data.get("fragment_id", ""))))

		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_node)

		var fragment_id: String = str(fragment_data.get("fragment_id", ""))
		if not fragment_id.is_empty():
			fragment_nodes[fragment_id] = item_node

func _on_drag_started(fragment_id: String, from_zone: String) -> void:
	_mark_first_action()
	fragment_drag_start_count += 1
	drag_count = fragment_drag_start_count
	if time_to_first_drag_ms < 0:
		time_to_first_drag_ms = _elapsed_ms_now()
	_log_event("fragment_drag_started", {
		"fragment_id": fragment_id,
		"from_zone": from_zone
	})

func _on_item_placed(fragment_id: String, to_zone: String, from_zone: String) -> void:
	_log_event("item_placed", {
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"to_zone": to_zone,
		"tag_label": _fragment_tag_label(fragment_id)
	})
	selected_fragment_id = ""
	_clear_fragment_highlights()
	_update_code_preview()
	_update_slot_feedback()
	_set_status(_tr("case08.fr8a.status.hint", STATUS_HINT), COLOR_INFO)

func _on_fragment_tapped(fragment_id: String) -> void:
	if confirm_locked:
		return
	if fragment_id.is_empty():
		return
	_mark_first_action()
	selected_fragment_id = fragment_id
	_log_event("fragment_selected", {"fragment_id": fragment_id, "zone_id": _fragment_zone(fragment_id)})
	_highlight_selected_fragment(fragment_id)
	_set_status(
		_tr("case08.fr8a.status.tap_slot", "Теперь нажмите на слот для размещения."),
		COLOR_INFO
	)

func _on_slot_tapped(slot_id: String) -> void:
	if confirm_locked:
		return
	slot_focus_count += 1
	_mark_first_action()
	_log_event("slot_focused", {"slot_id": slot_id, "has_selected_fragment": not selected_fragment_id.is_empty()})
	if selected_fragment_id.is_empty():
		return
	var result: Dictionary = handle_drop_to_slot(slot_id, {
		"kind": "TAG_FRAGMENT",
		"fragment_id": selected_fragment_id,
		"from_zone": _fragment_zone(selected_fragment_id)
	})
	if bool(result.get("success", false)):
		_on_item_placed(selected_fragment_id, slot_id, str(result.get("from_zone", "PILE")))
	selected_fragment_id = ""
	_clear_fragment_highlights()

func handle_drop_to_slot(target_zone_id: String, payload: Dictionary) -> Dictionary:
	if confirm_locked:
		return {"success": false}
	if not slot_nodes.has(target_zone_id):
		return {"success": false}
	_mark_first_action()

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
		fragment_replace_count += 1
	else:
		fragment_drop_count += 1
	if time_to_first_drop_ms < 0:
		time_to_first_drop_ms = _elapsed_ms_now()
	unique_fragment_ids[fragment_id] = true
	_mark_edit_action()
	_log_event("fragment_placed", {
		"fragment_id": fragment_id,
		"slot_id": target_zone_id,
		"tag_label": _fragment_tag_label(fragment_id),
		"from_zone": from_zone,
		"replaced_fragment_id": target_existing_id,
		"swapped": swapped,
		"current_order": _collect_sequence().duplicate()
	})

	return {
		"success": true,
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"to_zone": target_zone_id,
		"swapped": swapped
	}

func handle_drop_to_pile(payload: Dictionary) -> Dictionary:
	if confirm_locked:
		return {"success": false}
	_mark_first_action()
	var parsed: Dictionary = _parse_payload(payload)
	if parsed.is_empty():
		return {"success": false}

	var fragment_id: String = str(parsed.get("fragment_id", ""))
	var from_zone: String = str(parsed.get("from_zone", "PILE"))
	if _fragment_zone(fragment_id) == "PILE":
		return {"success": false}

	if not _move_fragment_to_zone(fragment_id, "PILE"):
		return {"success": false}
	fragment_remove_count += 1
	_mark_edit_action()
	_log_event("fragment_removed", {
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"current_order": _collect_sequence().duplicate()
	})

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

	_mark_first_action()
	has_confirmed_once = true
	confirm_attempt_count += 1
	confirm_attempt_total_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	var sequence: Array[String] = _collect_sequence()
	var snapshot_zones: Dictionary = _build_snapshot_zones()
	var required_missing_slots: int = _count_required_missing_slots(sequence)
	if required_missing_slots > 0:
		incomplete_confirm_count += 1
	var elapsed_ms: int = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, elapsed_ms - last_edit_ms)
	else:
		time_from_last_edit_to_confirm_ms = -1
	_log_event("confirm_pressed", {
		"sequence": sequence.duplicate(),
		"filled_slots": _count_filled_slots(sequence),
		"attempt": confirm_attempt_total_count,
		"required_missing_slots": required_missing_slots,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms
	})

	var evaluation: Dictionary = FR8Scoring.evaluate(level_data, sequence, fragment_by_id)
	var score: Dictionary = FR8Scoring.resolve_score(level_data, evaluation)
	var checks: Dictionary = evaluation.get("checks", {
		"container_ok": false,
		"hierarchy_ok": false,
		"order_ok": false
	}) as Dictionary
	_update_render_preview(sequence, evaluation)

	var points: int = int(score.get("points", 0))
	var max_points: int = int(score.get("max_points", 2))
	var is_fit: bool = bool(score.get("is_fit", false))
	var is_correct: bool = bool(score.get("is_correct", false))
	var stability_delta: int = int(score.get("stability_delta", 0))
	var verdict_code: String = str(score.get("verdict_code", "FAIL"))
	var error_code: String = str(evaluation.get("error_code", "FAIL"))
	var level_id: String = str(level_data.get("id", "FR8-A-00"))
	var match_key: String = "FR8_A|%s|%d" % [level_id, GlobalMetrics.session_history.size()]
	var outcome_code: String = _outcome_code_for_a(is_correct, error_code, last_render_state)
	var mastery_block_reason: String = _mastery_block_reason_for_a(is_correct, outcome_code)
	var tffa_ms: int = elapsed_ms if time_to_first_action_ms < 0 else time_to_first_action_ms

	_log_event("confirm_result", {
		"is_correct": is_correct,
		"error_type": error_code,
		"render_state": last_render_state,
		"fragment_order": sequence.duplicate(),
		"outcome_code": outcome_code
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "A",
		"level_id": level_id,
		"format": "TAG_ORDERING",
		"match_key": match_key,
		"trial_seq": trial_seq,
		"sequence": sequence,
		"snapshot_zones": snapshot_zones,
		"error_code": error_code,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"checks": {
			"container_ok": bool(checks.get("container_ok", false)),
			"hierarchy_ok": bool(checks.get("hierarchy_ok", false)),
			"order_ok": bool(checks.get("order_ok", false))
		},
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": tffa_ms,
		"drag_count": drag_count,
		"swap_count": swap_count,
		"fragment_drag_start_count": fragment_drag_start_count,
		"fragment_drop_count": fragment_drop_count,
		"fragment_replace_count": fragment_replace_count,
		"fragment_remove_count": fragment_remove_count,
		"unique_fragment_count": unique_fragment_ids.size(),
		"slot_focus_count": slot_focus_count,
		"reset_count": reset_count_local,
		"confirm_attempt_count": confirm_attempt_total_count,
		"incomplete_confirm_count": incomplete_confirm_count,
		"render_preview_update_count": render_preview_update_count,
		"render_ok_seen": render_ok_seen,
		"render_warn_seen": render_warn_seen,
		"render_error_seen": render_error_seen,
		"changed_after_render_warn": changed_after_render_warn,
		"changed_after_render_error": changed_after_render_error,
		"time_to_first_drag_ms": time_to_first_drag_ms,
		"time_to_first_drop_ms": time_to_first_drop_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"points": points,
		"max_points": max_points,
		"is_fit": is_fit,
		"is_correct": is_correct,
		"stability_delta": stability_delta,
		"verdict_code": verdict_code,
		"trace": trace.duplicate(true),
		"task_session": task_session.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	var feedback_text: String = FR8Scoring.feedback_text(level_data, evaluation)
	_clear_fragment_highlights()
	if verdict_code == "PERFECT":
		skip_unlocked = false
		level_solved = true
		confirm_locked = true
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
		_set_status("%s %s" % [feedback_text, _tr("case08.fr8a.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)
	elif verdict_code == "PARTIAL":
		level_solved = false
		confirm_locked = false
		skip_unlocked = confirm_attempt_count >= 2
		btn_next.disabled = not skip_unlocked
		if skip_unlocked:
			_set_status(
				"%s\n%s" % [
					feedback_text,
					_tr("case08.fr8a.status.skip_available", "Можно пропустить (ДАЛЕЕ) или попробовать ещё раз.")
				],
				COLOR_WARN
			)
		else:
			_set_status(feedback_text, COLOR_WARN)
	else:
		level_solved = false
		confirm_locked = false
		skip_unlocked = confirm_attempt_count >= 3
		btn_next.disabled = not skip_unlocked
		var fail_text: String = _tr("case08.fr8a.status.incomplete", STATUS_INCOMPLETE) if error_code == "INCOMPLETE" else feedback_text
		if skip_unlocked:
			_set_status(
				"%s\n%s" % [
					fail_text,
					_tr("case08.fr8a.status.skip_available", "Можно пропустить (ДАЛЕЕ) или сбросить.")
				],
				COLOR_ERR
			)
		else:
			_set_status(fail_text, COLOR_ERR)
		_flash_wrong_slots()
		if error_code == "HIERARCHY_VIOLATION":
			_highlight_foreign_fragments_in_slots()

	_play_confirm_audio(verdict_code)
	if verdict_code in ["FAIL", "EMPTY"]:
		_trigger_glitch()
		_shake_main_layout()

func _on_next_pressed() -> void:
	if not level_solved and not skip_unlocked:
		_set_status(_tr("case08.fr8a.status.solve_first", STATUS_SOLVE_FIRST), COLOR_WARN)
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
		var value: String = str(fragment_id).strip_edges()
		if not value.is_empty() and value != "(EMPTY)":
			filled += 1
	return filled

func _count_required_missing_slots(sequence: Array[String]) -> int:
	var missing: int = 0
	for i in range(slot_ids.size()):
		var expected_fragment_id: String = expected_sequence[i] if i < expected_sequence.size() else ""
		if expected_fragment_id.is_empty() or expected_fragment_id == "(EMPTY)":
			continue
		var actual_fragment_id: String = sequence[i] if i < sequence.size() else ""
		if actual_fragment_id.is_empty():
			missing += 1
	return missing

func _update_code_preview() -> void:
	var sequence: Array[String] = _collect_sequence()
	var raw_lines: Array[String] = []
	for i in range(slot_ids.size()):
		var slot_id: String = slot_ids[i]
		var fragment_id: String = sequence[i] if i < sequence.size() else ""
		var token: String = ""
		var token_color: String = "#7fffb4"
		var expected_fragment_id: String = expected_sequence[i] if i < expected_sequence.size() else ""
		var expects_empty_slot: bool = expected_fragment_id.is_empty() or expected_fragment_id == "(EMPTY)"
		if fragment_id.is_empty():
			if expects_empty_slot:
				token = "—"
				token_color = "#555555"
			else:
				token = "____"
				token_color = "#ffd07f"
		elif fragment_id == "(EMPTY)":
			token = "—"
			token_color = "#555555"
		else:
			token = _token_for_fragment(fragment_id)
			token_color = "#7fffb4"
		raw_lines.append("[color=#7f7f7f]%s[/color] [color=%s]%s[/color]" % [slot_id, token_color, _escape_bbcode(token)])

	var profile: String = str(level_data.get("validator_profile", FR8Scoring.PROFILE_LIST_BASIC)).to_upper()
	code_preview.text = "\n".join([
		"[b][color=#ffd25f]%s[/color][/b]" % _escape_bbcode(_tr("case08.fr8a.code_header", "ИСХОДНЫЙ КОД")),
		"[code]%s[/code]" % "\n".join(raw_lines),
		"",
		"[b][color=#8fffb2]%s %s[/color][/b]" % [_escape_bbcode(_tr("case08.fr8a.profile_label", "ПРОФИЛЬ:")), _escape_bbcode(profile)]
	])
	_update_render_preview(sequence)

func _update_render_preview(sequence: Array[String], evaluation_override: Dictionary = {}) -> void:
	if render_preview == null or render_status == null:
		return

	var evaluation: Dictionary = evaluation_override
	if evaluation.is_empty():
		evaluation = FR8Scoring.evaluate(level_data, sequence, fragment_by_id)

	var checks: Dictionary = evaluation.get("checks", {}) as Dictionary
	var render_state: String = "error"
	if bool(checks.get("container_ok", false)) and bool(checks.get("hierarchy_ok", false)):
		render_state = "ok" if bool(checks.get("order_ok", false)) else "warn"
	var required_missing_slots: int = _count_required_missing_slots(sequence)
	if not has_confirmed_once and required_missing_slots > 0:
		render_state = "warn"

	render_preview_update_count += 1
	var previous_render_state: String = last_render_state
	match render_state:
		"ok":
			render_ok_seen = true
		"warn":
			render_warn_seen = true
		_:
			render_error_seen = true
	if render_state != previous_render_state:
		_log_event("render_state_changed", {
			"state": render_state,
			"previous_state": previous_render_state,
			"required_missing_slots": required_missing_slots,
			"filled_slots": _count_filled_slots(sequence)
		})

	if has_confirmed_once and render_state == "error" and previous_render_state != "error" and _count_filled_slots(sequence) > 0:
		_trigger_glitch()
	last_render_state = render_state

	var profile: String = str(level_data.get("validator_profile", FR8Scoring.PROFILE_LIST_BASIC)).to_upper()
	var mock_lines: Array[String] = _build_profile_render_lines(profile, sequence)

	var header_line: String = "[b][color=#ffd25f]%s | %s[/color][/b]" % [_escape_bbcode(_tr("case08.fr8a.render_header", "МОК-РЕНДЕР")), _escape_bbcode(profile)]
	match render_state:
		"ok":
			render_status.text = _tr("case08.fr8a.render.ok", RENDER_OK)
			render_status.modulate = COLOR_OK
		"warn":
			render_status.text = _tr("case08.fr8a.render.warn", RENDER_WARN)
			render_status.modulate = COLOR_WARN
		_:
			render_status.text = _tr("case08.fr8a.render.error", RENDER_ERROR)
			render_status.modulate = COLOR_ERR
			var use_shake: bool = render_preview.get_v_scroll_bar() != null
			if use_shake:
				header_line = "[shake rate=15.0 level=5 connected=1][b][color=#ff6363]%s[/color][/b][/shake]" % _tr("case08.fr8a.render.error", RENDER_ERROR)
			else:
				header_line = "[b][color=#ff6363]%s[/color][/b]" % _tr("case08.fr8a.render.error", RENDER_ERROR)

	if required_missing_slots > 0 and not has_confirmed_once:
		mock_lines.append(
			"[color=#7d7d7d]%s[/color]" % _escape_bbcode(
				_tr("case08.fr8a.preview.empty_hint", "Заполните обязательные слоты: %d." % required_missing_slots)
			)
		)

	render_preview.text = "\n".join([
		header_line,
		"",
		"\n".join(mock_lines)
	])

func _build_profile_render_lines(profile: String, sequence: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	var inner_tokens: Array[String] = _inner_tokens_from_sequence(sequence)

	match profile:
		"LIST_BASIC":
			for token in inner_tokens:
				if token.to_lower().begins_with("<li"):
					var item_text: String = _extract_tag_text(token)
					var fallback_item: String = _tr("case08.fr8a.preview.list_item_default", "элемент")
					lines.append("[color=#d8f5d8]- %s[/color]" % _escape_bbcode(item_text if not item_text.is_empty() else fallback_item))
			if lines.is_empty():
				lines.append("[color=#808080]- ...[/color]")
		"NAV_MENU":
			var labels: Array[String] = []
			for token in inner_tokens:
				if token.to_lower().find("<a") >= 0:
					var label: String = _extract_tag_text(token)
					if not label.is_empty():
						labels.append(label)
			if labels.is_empty():
				labels = [
					_tr("case08.fr8a.preview.nav_home", "главная"),
					_tr("case08.fr8a.preview.nav_news", "новости"),
					_tr("case08.fr8a.preview.nav_about", "о нас")
				]
			var menu_line: String = ""
			for i in range(labels.size()):
				if i > 0:
					menu_line += " "
				menu_line += "[color=#f6e7a2]%s[/color]" % _escape_bbcode(labels[i].to_upper())
			lines.append("[bgcolor=#1d2430] %s [/bgcolor]" % menu_line)
		"TABLE_LOG":
			var row_count: int = 0
			for token in inner_tokens:
				if token.to_lower().find("<tr") >= 0:
					row_count += 1
			row_count = max(row_count, 2)
			lines.append("[bgcolor=#25291f][color=#d6ffb0] %s [/color][/bgcolor]" % _escape_bbcode(_tr("case08.fr8a.preview.table_header", "время | событие")))
			for i in range(row_count):
				lines.append("[color=#bac6b4] 0%d:%02d | %s_%d [/color]" % [8 + i, 10 + i, _escape_bbcode(_tr("case08.fr8a.preview.table_row_prefix", "запись")), i + 1])
		"FORM_SIMPLE":
			var field_count: int = 0
			var has_button: bool = false
			for token in inner_tokens:
				var lower: String = token.to_lower()
				if lower.find("<input") >= 0:
					field_count += 1
				if lower.find("<button") >= 0:
					has_button = true
			field_count = max(field_count, 2)
			lines.append("[bgcolor=#1f2a1f][color=#d8ffd8] %s [/color][/bgcolor]" % _escape_bbcode(_tr("case08.fr8a.preview.form_title", "ФОРМА АВТОРИЗАЦИИ")))
			for i in range(field_count):
				lines.append("[color=#c6d7c6][ %s_%d ]________________[/color]" % [_escape_bbcode(_tr("case08.fr8a.preview.form_field_prefix", "поле")), i + 1])
			var action_label: String = _tr("case08.fr8a.preview.form_btn_send", "ОТПРАВИТЬ") if has_button else _tr("case08.fr8a.preview.form_btn_action", "ДЕЙСТВИЕ")
			lines.append("[color=#ffd07a][ %s ][/color]" % _escape_bbcode(action_label))
		"ARTICLE_NOTE":
			var title_text: String = ""
			var body_text: String = ""
			for token in inner_tokens:
				var lower: String = token.to_lower()
				if title_text.is_empty() and (lower.find("<h1") >= 0 or lower.find("<h2") >= 0):
					title_text = _extract_tag_text(token)
				elif body_text.is_empty() and lower.find("<p") >= 0:
					body_text = _extract_tag_text(token)
			title_text = _tr("case08.fr8a.preview.article_title", "Примечание по делу") if title_text.is_empty() else title_text
			body_text = "..." if body_text.is_empty() else body_text
			lines.append("[b][color=#ece7cc]%s[/color][/b]" % _escape_bbcode(title_text))
			lines.append("[color=#b8b5a3]%s[/color]" % _escape_bbcode(body_text))
		"FIGURE_MEDIA":
			var has_image: bool = false
			var caption: String = ""
			for token in inner_tokens:
				var lower: String = token.to_lower()
				if lower.find("<img") >= 0:
					has_image = true
				if caption.is_empty() and lower.find("<figcaption") >= 0:
					caption = _extract_tag_text(token)
			var media_label: String = _tr("case08.fr8a.preview.figure_media", "[ медиа-кадр ]") if has_image else _tr("case08.fr8a.preview.figure_no_media", "[ нет медиа ]")
			lines.append("[bgcolor=#252a36][color=#b8c8ff]%s[/color][/bgcolor]" % _escape_bbcode(media_label))
			lines.append("[color=#d4c8a0]%s[/color]" % _escape_bbcode(caption if not caption.is_empty() else _tr("case08.fr8a.preview.figure_caption", "подпись на рассмотрении")))
		_:
			for token in inner_tokens:
				lines.append("[color=#c2c2c2]%s[/color]" % _escape_bbcode(_extract_tag_text(token)))

	if lines.is_empty():
		lines.append("[color=#7d7d7d]%s[/color]" % _escape_bbcode(_tr("case08.fr8a.preview.render_off", "[РЕНДЕР ОТКЛЮЧЕН]")))
	return lines

func _inner_tokens_from_sequence(sequence: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for fragment_id in sequence:
		if fragment_id.is_empty() or not fragment_by_id.has(fragment_id):
			continue
		var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
		var kind: String = str(fragment_data.get("kind", "")).to_upper()
		if kind == "CONTAINER_OPEN" or kind == "CONTAINER_CLOSE":
			continue
		var token_text: String = I18n.resolve_field(
			fragment_data,
			"token",
			{"default": I18n.resolve_field(fragment_data, "label", {"default": fragment_id})}
		)
		out.append(token_text)
	return out

func _token_for_fragment(fragment_id: String) -> String:
	if fragment_id.is_empty() or not fragment_by_id.has(fragment_id):
		return ""
	var fragment_data: Dictionary = fragment_by_id.get(fragment_id, {}) as Dictionary
	return I18n.resolve_field(
		fragment_data,
		"token",
		{"default": I18n.resolve_field(fragment_data, "label", {"default": fragment_id})}
	)

func _extract_tag_text(token: String) -> String:
	var text_value: String = token
	while true:
		var open_pos: int = text_value.find("<")
		if open_pos < 0:
			break
		var close_pos: int = text_value.find(">", open_pos + 1)
		if close_pos < 0:
			break
		text_value = text_value.substr(0, open_pos) + text_value.substr(close_pos + 1)
	return text_value.strip_edges()

func _flash_wrong_slots() -> void:
	for i in range(slot_ids.size()):
		var slot_id: String = slot_ids[i]
		var actual_fragment_id: String = _fragment_in_slot(slot_id)
		var expected_fragment_id: String = expected_sequence[i] if i < expected_sequence.size() else ""
		if actual_fragment_id.is_empty() or actual_fragment_id == expected_fragment_id:
			continue
		var slot_node: Node = slot_nodes.get(slot_id, null) as Node
		if slot_node != null and slot_node.has_method("flash_wrong"):
			slot_node.call("flash_wrong")

func _update_slot_feedback() -> void:
	for i in range(slot_ids.size()):
		var slot_id: String = slot_ids[i]
		var slot_node: Node = slot_nodes.get(slot_id, null) as Node
		if slot_node == null or not slot_node.has_method("set_feedback_state"):
			continue
		var actual_fragment_id: String = _fragment_in_slot(slot_id)
		if not has_confirmed_once:
			if actual_fragment_id.is_empty():
				slot_node.call("set_feedback_state", "neutral")
			else:
				slot_node.call("set_feedback_state", "filled")
			continue
		var expected_fragment_id: String = expected_sequence[i] if i < expected_sequence.size() else ""
		if actual_fragment_id.is_empty():
			slot_node.call("set_feedback_state", "neutral")
		elif actual_fragment_id == expected_fragment_id and not expected_fragment_id.is_empty():
			slot_node.call("set_feedback_state", "ok")
		else:
			slot_node.call("set_feedback_state", "bad")

func _highlight_selected_fragment(fragment_id: String) -> void:
	_clear_fragment_highlights()
	var node: Node = fragment_nodes.get(fragment_id, null) as Node
	if node is Button:
		(node as Button).add_theme_color_override("font_color", Color(0.55, 0.86, 1.0))

func _clear_fragment_highlights() -> void:
	for frag_node_var in fragment_nodes.values():
		if frag_node_var is Button:
			var button_node: Button = frag_node_var as Button
			button_node.remove_theme_color_override("font_color")

func _highlight_foreign_fragments_in_slots() -> void:
	for slot_id in slot_ids:
		var frag_id: String = _fragment_in_slot(slot_id)
		if frag_id.is_empty():
			continue
		var frag_data: Dictionary = fragment_by_id.get(frag_id, {}) as Dictionary
		var kind: String = str(frag_data.get("kind", "")).to_upper()
		if kind == "FOREIGN":
			var frag_node: Node = fragment_nodes.get(frag_id, null) as Node
			if frag_node is Button:
				(frag_node as Button).add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

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

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if main_layout == null or body == null:
		return
	var existing_scroll: ScrollContainer = main_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null and existing_scroll.get_node_or_null("Body") != null:
		_body_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var idx: int = body.get_index()
	main_layout.add_child(scroll)
	main_layout.move_child(scroll, idx)
	body.reparent(scroll)
	_body_scroll_installed = true

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape: bool = viewport_size.x > viewport_size.y
	var compact: bool = (landscape and viewport_size.y <= 420.0) or ((not landscape) and viewport_size.x <= 520.0)
	body.vertical = not landscape

	if landscape:
		if body.get_child(0) != fragments_card:
			body.move_child(fragments_card, 0)
			body.move_child(editor_card, 1)
		slots_grid.columns = 3 if compact else (3 if slot_ids.size() >= 6 else 2)
		if pile_zone.has_method("set_grid_columns"):
			pile_zone.call("set_grid_columns", 3 if viewport_size.x >= 1280.0 else 2)
	else:
		if body.get_child(0) != editor_card:
			body.move_child(editor_card, 0)
			body.move_child(fragments_card, 1)
		slots_grid.columns = 3 if compact else 2
		if pile_zone.has_method("set_grid_columns"):
			pile_zone.call("set_grid_columns", 3 if compact and viewport_size.x > 600.0 else 2)
	if pile_zone.has_method("set_item_height"):
		pile_zone.call("set_item_height", 40.0 if compact else 52.0)

func _outcome_code_for_a(is_correct: bool, error_code: String, render_state: String) -> String:
	if is_correct:
		return "SUCCESS"
	var normalized_error: String = error_code.strip_edges().to_upper()
	match normalized_error:
		"ORDER_MISMATCH":
			return "ORDER_MISMATCH"
		"UNBALANCED_TAG":
			return "UNBALANCED_TAG"
		"REQUIRED_TAG_MISSING":
			return "REQUIRED_TAG_MISSING"
		"HIERARCHY_VIOLATION":
			return "HIERARCHY_VIOLATION"
		"INCOMPLETE":
			return "INCOMPLETE"
	if render_state == "error":
		return "RENDER_ERROR"
	return "ORDER_MISMATCH"

func _mastery_block_reason_for_a(is_correct: bool, outcome_code: String) -> String:
	if reset_count_local >= 3:
		return "RESET_OVERUSE"
	if confirm_attempt_total_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if not is_correct:
		if outcome_code == "ORDER_MISMATCH":
			return "ORDER_CONFUSION"
		if outcome_code in ["UNBALANCED_TAG", "HIERARCHY_VIOLATION", "REQUIRED_TAG_MISSING", "RENDER_ERROR"]:
			return "STRUCTURE_UNSTABLE"
		if render_warn_seen and not changed_after_render_warn:
			return "RENDER_DEPENDENCY"
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

func _escape_bbcode(text_value: String) -> String:
	return text_value.replace("[", "[lb]").replace("]", "[rb]")

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
