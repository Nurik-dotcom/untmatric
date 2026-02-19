extends Control

const LEVELS_PATH := "res://data/clues_levels.json"
const NET_ITEM_SCENE := preload("res://scenes/ui/NetItem.tscn")
const ResusData := preload("res://scripts/case_01/ResusData.gd")
const ResusScoring := preload("res://scripts/case_01/ResusScoring.gd")

const COLOR_OK := Color(0.42, 0.95, 0.55, 1.0)
const COLOR_WARN := Color(1.0, 0.78, 0.25, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)

var stage_c_data: Dictionary = {}
var option_by_id: Dictionary = {}
var correct_set: Dictionary = {}
var option_order: Array[String] = []

var item_nodes_by_option: Dictionary = {}
var slot_item_by_index: Dictionary = {}
var slots: Array[String] = ["", "", ""]

var trace: Array = []
var stage_started_ms: int = 0
var attempt_index: int = 0
var drag_count: int = 0
var slot_change_count: int = 0
var unique_used_set: Dictionary = {}
var time_to_first_action_ms: int = -1
var input_locked: bool = false

@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var prompt_label: Label = $SafeArea/MainVBox/PromptCard/PromptLabel

@onready var slot_1: Node = $SafeArea/MainVBox/DiagramCard/DiagramVBox/DiagramRow/Slot1
@onready var slot_2: Node = $SafeArea/MainVBox/DiagramCard/DiagramVBox/DiagramRow/Slot2
@onready var slot_3: Node = $SafeArea/MainVBox/DiagramCard/DiagramVBox/DiagramRow/Slot3

@onready var collisions_value: Label = $SafeArea/MainVBox/RiskCard/RiskVBox/CollisionsRow/CollisionsValue
@onready var eavesdrop_value: Label = $SafeArea/MainVBox/RiskCard/RiskVBox/EavesdropRow/EavesdropValue
@onready var filtering_value: Label = $SafeArea/MainVBox/RiskCard/RiskVBox/FilteringRow/FilteringValue
@onready var media_value: Label = $SafeArea/MainVBox/RiskCard/RiskVBox/MediaRow/MediaValue

@onready var palette_flow: GridContainer = $SafeArea/MainVBox/PaletteCard/PaletteVBox/Scroll/PaletteFlow

@onready var explanation_card: PanelContainer = $SafeArea/MainVBox/ExplanationCard
@onready var expl_headline: Label = $SafeArea/MainVBox/ExplanationCard/ExplVBox/ExplHeadline
@onready var expl_details: RichTextLabel = $SafeArea/MainVBox/ExplanationCard/ExplVBox/ExplDetails
@onready var expl_why: RichTextLabel = $SafeArea/MainVBox/ExplanationCard/ExplVBox/ExplWhy

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_analyze: Button = $SafeArea/MainVBox/BottomBar/BtnAnalyze

var _slot_nodes: Array[Node] = []

func _ready() -> void:
	add_to_group("resus_c_controller")

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

	_slot_nodes = [slot_1, slot_2, slot_3]

	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)

	stage_c_data = ResusData.load_stage_c(LEVELS_PATH)
	if stage_c_data.is_empty():
		_show_error("Данные этапа C некорректны. Возврат в меню.")
		return

	_setup_ui()
	_begin_attempt()
	_on_viewport_size_changed()

func _setup_ui() -> void:
	title_label.text = "ДЕЛО №1: ЦИФРОВАЯ РЕАНИМАЦИЯ"
	stage_label.text = "ЭТАП C"
	btn_reset.text = "СБРОС"
	btn_analyze.text = "АНАЛИЗ"
	prompt_label.text = str(stage_c_data.get("prompt", ""))

	_build_option_catalog()
	_build_palette()
	_setup_slots()
	_update_risk_dashboard()
	_update_stability_ui()

func _build_option_catalog() -> void:
	option_by_id.clear()
	correct_set.clear()
	option_order.clear()

	var options: Array = stage_c_data.get("options", []) as Array
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue
		option_by_id[option_id] = option_data
		option_order.append(option_id)
		if bool(option_data.get("is_correct", false)):
			correct_set[option_id] = true

func _build_palette() -> void:
	for child in palette_flow.get_children():
		child.queue_free()
	item_nodes_by_option.clear()

	for option_id in option_order:
		var option_data: Dictionary = option_by_id.get(option_id, {}) as Dictionary
		var node_v: Variant = NET_ITEM_SCENE.instantiate()
		if not (node_v is Control):
			continue
		var item_node: Control = node_v as Control
		palette_flow.add_child(item_node)
		if item_node.has_method("setup"):
			item_node.call("setup", option_data)
		if item_node.has_method("set_source"):
			item_node.call("set_source", "PALETTE", -1)
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_item_drag_started"))
		item_nodes_by_option[option_id] = item_node

	_sort_palette_items()

func _setup_slots() -> void:
	for i in range(_slot_nodes.size()):
		var slot_node: Node = _slot_nodes[i]
		if slot_node == null:
			continue
		if slot_node.has_method("set_slot_title"):
			slot_node.call("set_slot_title", i + 1)
		if slot_node.has_method("set_current_option"):
			slot_node.call("set_current_option", "", "")
		if slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")
		if slot_node.has_method("set_locked"):
			slot_node.call("set_locked", false)

func _begin_attempt() -> void:
	trace.clear()
	drag_count = 0
	slot_change_count = 0
	unique_used_set.clear()
	time_to_first_action_ms = -1
	stage_started_ms = Time.get_ticks_msec()
	input_locked = false

	explanation_card.visible = false
	btn_analyze.disabled = false

	slots = ["", "", ""]
	slot_item_by_index.clear()

	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if not (item_v is Control):
			continue
		var item_node: Control = item_v as Control
		if item_node.get_parent() != palette_flow:
			item_node.reparent(palette_flow)
		if item_node.has_method("set_source"):
			item_node.call("set_source", "PALETTE", -1)
		if item_node.has_method("set_feedback_state"):
			item_node.call("set_feedback_state", "neutral")
		if item_node.has_method("set_locked"):
			item_node.call("set_locked", false)

	_sort_palette_items()

	for i in range(_slot_nodes.size()):
		var slot_node: Node = _slot_nodes[i]
		if slot_node == null:
			continue
		if slot_node.has_method("set_current_option"):
			slot_node.call("set_current_option", "", "")
		if slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")
		if slot_node.has_method("set_locked"):
			slot_node.call("set_locked", false)

	_update_status_line("Соберите защищённый периметр")
	_update_risk_dashboard()
	_update_stability_ui()

func is_input_locked() -> bool:
	return input_locked

func handle_drop_to_slot(slot_index: int, data: Dictionary) -> Dictionary:
	if input_locked:
		return {"success": false}
	if not _is_slot_index_valid(slot_index):
		return {"success": false}
	if str(data.get("kind", "")) != "NET_ITEM":
		return {"success": false}

	var option_id: String = str(data.get("option_id", "")).strip_edges()
	if option_id == "" or not option_by_id.has(option_id):
		return {"success": false}

	var source_path: String = str(data.get("node_path", ""))
	var source_node: Node = get_node_or_null(source_path)
	if source_node == null:
		var fallback_node: Variant = item_nodes_by_option.get(option_id, null)
		if fallback_node is Node:
			source_node = fallback_node as Node
	if source_node == null or not (source_node is Control):
		return {"success": false}

	var from_slot: int = int(data.get("from_slot", -1))
	var target_idx: int = slot_index - 1
	var prev_option_id: String = slots[target_idx]

	if from_slot == slot_index and prev_option_id == option_id:
		return {
			"success": true,
			"option_id": option_id,
			"prev_option_id": prev_option_id,
			"label": str((option_by_id.get(option_id, {}) as Dictionary).get("label", option_id))
		}

	if from_slot >= 1 and from_slot <= 3 and from_slot != slot_index:
		_clear_slot_state(from_slot)

	var prev_node_v: Variant = slot_item_by_index.get(slot_index, null)
	if prev_node_v is Control and prev_node_v != source_node:
		_move_item_to_palette(prev_node_v as Control)

	_attach_item_to_slot(source_node as Control, slot_index)
	slots[target_idx] = option_id
	slot_item_by_index[slot_index] = source_node

	_mark_first_action()
	slot_change_count += 1
	unique_used_set[option_id] = true
	_log_event("SLOT_CHANGED", {
		"slot_index": slot_index,
		"option_id": option_id,
		"prev_option_id": prev_option_id
	})
	_update_status_line("")
	_update_risk_dashboard()
	_play_sfx("click")

	return {
		"success": true,
		"option_id": option_id,
		"prev_option_id": prev_option_id,
		"label": str((option_by_id.get(option_id, {}) as Dictionary).get("label", option_id))
	}

func handle_clear_slot(slot_index: int) -> Dictionary:
	if input_locked:
		return {"success": false}
	if not _is_slot_index_valid(slot_index):
		return {"success": false}

	var idx: int = slot_index - 1
	var prev_option_id: String = slots[idx]
	if prev_option_id == "":
		return {"success": false}

	var prev_node_v: Variant = slot_item_by_index.get(slot_index, null)
	if prev_node_v is Control:
		_move_item_to_palette(prev_node_v as Control)

	_clear_slot_state(slot_index)
	_mark_first_action()
	slot_change_count += 1
	_log_event("SLOT_CLEARED", {
		"slot_index": slot_index,
		"prev_option_id": prev_option_id
	})
	_update_status_line("")
	_update_risk_dashboard()
	_play_sfx("click")

	return {
		"success": true,
		"prev_option_id": prev_option_id
	}

func _attach_item_to_slot(item_node: Control, slot_index: int) -> void:
	var slot_node: Node = _get_slot_node(slot_index)
	if slot_node == null:
		return
	if slot_node.has_method("attach_item_control"):
		slot_node.call("attach_item_control", item_node)
	if item_node.has_method("set_source"):
		item_node.call("set_source", "SLOT", slot_index)
	if item_node.has_method("set_locked"):
		item_node.call("set_locked", input_locked)

func _move_item_to_palette(item_node: Control) -> void:
	if item_node.get_parent() != palette_flow:
		item_node.reparent(palette_flow)
	if item_node.has_method("set_source"):
		item_node.call("set_source", "PALETTE", -1)
	if item_node.has_method("set_locked"):
		item_node.call("set_locked", input_locked)
	if not input_locked and item_node.has_method("set_feedback_state"):
		item_node.call("set_feedback_state", "neutral")
	_sort_palette_items()

func _clear_slot_state(slot_index: int) -> void:
	if not _is_slot_index_valid(slot_index):
		return
	var idx: int = slot_index - 1
	slots[idx] = ""
	slot_item_by_index.erase(slot_index)

	var slot_node: Node = _get_slot_node(slot_index)
	if slot_node == null:
		return
	if slot_node.has_method("set_current_option"):
		slot_node.call("set_current_option", "", "")
	if not input_locked and slot_node.has_method("set_feedback_state"):
		slot_node.call("set_feedback_state", "neutral")

func _on_item_drag_started(option_id: String, source: String, from_slot: int) -> void:
	if input_locked:
		return
	_mark_first_action()
	drag_count += 1
	_log_event("DRAG_START", {
		"option_id": option_id,
		"source": source,
		"from_slot": from_slot
	})

func _on_analyze_pressed() -> void:
	if input_locked:
		return

	var filled_slots: int = _filled_slots_count()
	var unique_used_count: int = unique_used_set.size()
	_log_event("ANALYZE_PRESSED", {
		"filled_slots": filled_slots,
		"unique_used_count": unique_used_count
	})

	var selected_ids: Array[String] = _collect_selected_ids()
	var snapshot: Dictionary = {
		"slots": slots.duplicate(),
		"selected": selected_ids.duplicate(),
		"unique_used_count": unique_used_count
	}
	var result: Dictionary = ResusScoring.calculate_stage_c_result(stage_c_data, snapshot)
	var risk: Dictionary = _calculate_risk(slots)

	_register_trial(result, risk)
	_show_explanation(result, risk)
	_apply_result_highlight(result)
	_update_stability_ui()

	input_locked = true
	btn_analyze.disabled = true
	_set_input_locked(true)

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {
		"prev_filled_slots": _filled_slots_count()
	})
	_begin_attempt()
	_play_sfx("click")

func _set_input_locked(locked: bool) -> void:
	for slot_node in _slot_nodes:
		if slot_node != null and slot_node.has_method("set_locked"):
			slot_node.call("set_locked", locked)
	for item_v in item_nodes_by_option.values():
		if item_v is Node and item_v.has_method("set_locked"):
			(item_v as Node).call("set_locked", locked)

func _show_explanation(result: Dictionary, risk: Dictionary) -> void:
	explanation_card.visible = true

	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	expl_headline.text = str(result.get("feedback_headline", verdict_code))
	if verdict_code == "PERFECT":
		expl_headline.modulate = COLOR_OK
	elif verdict_code == "GOOD" or verdict_code == "NOISY":
		expl_headline.modulate = COLOR_WARN
	else:
		expl_headline.modulate = COLOR_ERR

	var detail_lines: Array[String] = []
	for detail_v in (result.get("feedback_details", []) as Array):
		detail_lines.append("- %s" % str(detail_v))
	detail_lines.append("")
	detail_lines.append("РИСК: КОЛЛИЗИИ=%s | ПЕРЕХВАТ=%s | ФИЛЬТРАЦИЯ=%s | СРЕДА=%s" % [
		_translate_risk_value(str(risk.get("collisions", "MID"))),
		_translate_risk_value(str(risk.get("eavesdrop", "MID"))),
		_translate_risk_value(str(risk.get("filtering", "OFF"))),
		_translate_risk_value(str(risk.get("media", "UNKNOWN")))
	])
	expl_details.text = "\n".join(detail_lines)

	var why_lines: Array[String] = []
	var explain_selected: Array = result.get("explain_selected", []) as Array
	if not explain_selected.is_empty():
		why_lines.append("Выбранные элементы:")
		for explain_v in explain_selected:
			if typeof(explain_v) != TYPE_DICTIONARY:
				continue
			var explain_item: Dictionary = explain_v as Dictionary
			var marker: String = "[ВЕРНО]" if bool(explain_item.get("is_correct", false)) else "[ЛИШНЕЕ]"
			why_lines.append("%s %s: %s" % [
				marker,
				str(explain_item.get("label", explain_item.get("option_id", "?"))),
				str(explain_item.get("why", ""))
			])

	var missing_required: Array = result.get("missing_required", []) as Array
	if not missing_required.is_empty():
		if why_lines.is_empty():
			why_lines.append("Выбранные элементы:")
		why_lines.append("")
		why_lines.append("Не хватает: %s" % ", ".join(_to_string_array(missing_required)))

	expl_why.text = "\n".join(why_lines)

	status_label.text = "Результат: %s | Установлено: %d/3" % [verdict_code, _filled_slots_count()]
	status_label.modulate = expl_headline.modulate

func _apply_result_highlight(result: Dictionary) -> void:
	for i in range(1, 4):
		var slot_node: Node = _get_slot_node(i)
		if slot_node != null and slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")

	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if item_v is Node and (item_v as Node).has_method("set_feedback_state"):
			(item_v as Node).call("set_feedback_state", "neutral")

	for i in range(3):
		var option_id: String = slots[i]
		if option_id == "":
			continue
		var state: String = "correct" if correct_set.has(option_id) else "wrong"
		var slot_node: Node = _get_slot_node(i + 1)
		if slot_node != null and slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", state)
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if item_v is Node and (item_v as Node).has_method("set_feedback_state"):
			(item_v as Node).call("set_feedback_state", state)

	for missing_id_v in (result.get("missing_required", []) as Array):
		var missing_id: String = str(missing_id_v)
		if _is_option_in_slots(missing_id):
			continue
		var missing_node_v: Variant = item_nodes_by_option.get(missing_id, null)
		if missing_node_v is Node and (missing_node_v as Node).has_method("set_feedback_state"):
			(missing_node_v as Node).call("set_feedback_state", "missing")

func _register_trial(result: Dictionary, risk: Dictionary) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var selected_ids: Array[String] = _collect_selected_ids()
	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "C",
		"format": "MULTI_CHOICE_SLOTS",
		"level_id": str(stage_c_data.get("id", "CASE01_C_01")),
		"match_key": "CASE01_C_%d" % attempt_index,
		"prompt": str(stage_c_data.get("prompt", "")),
		"slots": slots.duplicate(),
		"selected": selected_ids.duplicate(),
		"selected_count": int(result.get("selected_count", selected_ids.size())),
		"correct_selected": int(result.get("correct_selected", 0)),
		"wrong_selected": int(result.get("wrong_selected", 0)),
		"risk": risk.duplicate(),
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"missing_required": _to_string_array(result.get("missing_required", []) as Array),
		"drag_count": drag_count,
		"slot_change_count": slot_change_count,
		"unique_used_count": unique_used_set.size(),
		"time_to_first_action_ms": max(-1, time_to_first_action_ms),
		"elapsed_ms": elapsed_ms,
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	attempt_index += 1

func _update_status_line(prefix: String) -> void:
	if input_locked:
		return
	var filled: int = _filled_slots_count()
	var used_unique: int = unique_used_set.size()
	if prefix.strip_edges() == "":
		status_label.text = "Установлено: %d/3 | Использовано уникальных: %d" % [filled, used_unique]
	else:
		status_label.text = "%s | Установлено: %d/3 | Использовано уникальных: %d" % [prefix, filled, used_unique]
	status_label.modulate = COLOR_WARN

func _update_risk_dashboard() -> void:
	var risk: Dictionary = _calculate_risk(slots)
	var collisions_raw: String = str(risk.get("collisions", "MID"))
	var eavesdrop_raw: String = str(risk.get("eavesdrop", "MID"))
	var filtering_raw: String = str(risk.get("filtering", "OFF"))
	var media_raw: String = str(risk.get("media", "UNKNOWN"))

	collisions_value.text = _translate_risk_value(collisions_raw)
	eavesdrop_value.text = _translate_risk_value(eavesdrop_raw)
	filtering_value.text = _translate_risk_value(filtering_raw)
	media_value.text = _translate_risk_value(media_raw)

	collisions_value.modulate = _risk_color("collisions", collisions_raw)
	eavesdrop_value.modulate = _risk_color("eavesdrop", eavesdrop_raw)
	filtering_value.modulate = _risk_color("filtering", filtering_raw)
	media_value.modulate = _risk_color("media", media_raw)

func _translate_risk_value(value: String) -> String:
	match value:
		"LOW":
			return "НИЗКИЙ"
		"MID":
			return "СРЕДНИЙ"
		"HIGH":
			return "ВЫСОКИЙ"
		"ON":
			return "ВКЛ"
		"OFF":
			return "ВЫКЛ"
		"NEUTRAL":
			return "НЕЙТРАЛЬНО"
		"UNKNOWN":
			return "НЕИЗВЕСТНО"
		"FIBER":
			return "ОПТИКА"
		"COAX":
			return "КОАКСИАЛ"
		_:
			return value

func _calculate_risk(slot_values: Array[String]) -> Dictionary:
	var selected_set: Dictionary = {}
	for option_id in slot_values:
		if option_id == "":
			continue
		selected_set[option_id] = true

	var collisions: String = "MID"
	if selected_set.has("HUB"):
		collisions = "HIGH"
	elif selected_set.has("SWITCH"):
		collisions = "LOW"

	var filtering: String = "ON" if selected_set.has("FIREWALL") else "OFF"

	var eavesdrop: String = "MID"
	if selected_set.has("FIBER"):
		eavesdrop = "LOW"
	elif selected_set.has("COAX"):
		eavesdrop = "HIGH"

	var media: String = "UNKNOWN"
	if selected_set.has("FIBER"):
		media = "FIBER"
	elif selected_set.has("COAX"):
		media = "COAX"

	return {
		"collisions": collisions,
		"eavesdrop": eavesdrop,
		"filtering": filtering,
		"media": media
	}

func _risk_color(kind: String, value: String) -> Color:
	match kind:
		"collisions", "eavesdrop":
			if value == "LOW":
				return COLOR_OK
			if value == "MID":
				return COLOR_WARN
			return COLOR_ERR
		"filtering":
			return COLOR_OK if value == "ON" else COLOR_ERR
		"media":
			if value == "FIBER":
				return COLOR_OK
			if value == "UNKNOWN":
				return COLOR_WARN
			return COLOR_ERR
		_:
			return COLOR_WARN

func _collect_selected_ids() -> Array[String]:
	var selected_set: Dictionary = {}
	for option_id in slots:
		if option_id == "":
			continue
		selected_set[option_id] = true
	var selected_ids: Array[String] = []
	for option_id_v in selected_set.keys():
		selected_ids.append(str(option_id_v))
	selected_ids.sort()
	return selected_ids

func _filled_slots_count() -> int:
	var count: int = 0
	for option_id in slots:
		if option_id != "":
			count += 1
	return count

func _is_option_in_slots(option_id: String) -> bool:
	for current in slots:
		if current == option_id:
			return true
	return false

func _sort_palette_items() -> void:
	var move_index: int = 0
	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if not (item_v is Node):
			continue
		var item_node: Node = item_v as Node
		if item_node.get_parent() != palette_flow:
			continue
		palette_flow.move_child(item_node, move_index)
		move_index += 1

func _is_slot_index_valid(slot_index: int) -> bool:
	return slot_index >= 1 and slot_index <= 3

func _get_slot_node(slot_index: int) -> Node:
	if not _is_slot_index_valid(slot_index):
		return null
	return _slot_nodes[slot_index - 1]

func _mark_first_action() -> void:
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - stage_started_ms

func _to_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value_v in values:
		out.append(str(value_v))
	return out

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - stage_started_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability

func _on_viewport_size_changed() -> void:
	var size: Vector2 = get_viewport_rect().size
	var compact: bool = size.x < 900.0 or size.x < size.y
	palette_flow.columns = 1 if compact else 2

	for slot_node in _slot_nodes:
		if slot_node is Control:
			(slot_node as Control).custom_minimum_size = Vector2(0, 96 if compact else 110)

	btn_reset.custom_minimum_size = Vector2(150, 72 if compact else 64)
	btn_analyze.custom_minimum_size = Vector2(190, 72 if compact else 64)

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_analyze.disabled = true
	btn_reset.disabled = true
	await get_tree().create_timer(1.2).timeout
	_on_back_pressed()
