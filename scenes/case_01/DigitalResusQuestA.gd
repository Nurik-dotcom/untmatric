extends Control

const LEVELS_PATH := "res://data/clues_levels.json"
const ITEM_SCENE := preload("res://scenes/ui/ResusPartItem.tscn")
const ResusData := preload("res://scripts/case_01/ResusData.gd")
const ResusScoring := preload("res://scripts/case_01/ResusScoring.gd")

const COLOR_OK := Color(0.92, 0.92, 0.92, 1.0)
const COLOR_WARN := Color(0.86, 0.73, 0.56, 1.0)
const COLOR_ERR := Color(0.93, 0.34, 0.38, 1.0)

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}

var start_time_ms: int = 0
var drag_count: int = 0
var trace: Array = []
var item_nodes: Dictionary = {}

var console_target_text: String = ""
var console_visible_chars: int = 0
var console_cps: float = 14.0
var console_accum: float = 0.0
var _landscape_active: bool = false
var _portrait_content: VBoxContainer
var _landscape_content: HBoxContainer
var _landscape_left: VBoxContainer
var _landscape_right: VBoxContainer

@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var briefing_card: PanelContainer = $SafeArea/MainVBox/BriefingCard
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var briefing_label: Label = $SafeArea/MainVBox/BriefingCard/BriefingLabel

@onready var system_card: PanelContainer = $SafeArea/MainVBox/SystemCard
@onready var monitor_frame: PanelContainer = $SafeArea/MainVBox/SystemCard/SystemVBox/MonitorFrame
@onready var monitor_screen: ColorRect = $SafeArea/MainVBox/SystemCard/SystemVBox/MonitorFrame/MonitorScreen
@onready var monitor_label: Label = $SafeArea/MainVBox/SystemCard/SystemVBox/MonitorFrame/MonitorLabel
@onready var boot_console: RichTextLabel = $SafeArea/MainVBox/SystemCard/SystemVBox/BootConsole

@onready var zones_card: PanelContainer = $SafeArea/MainVBox/ZonesCard
@onready var pile_zone: Node = $SafeArea/MainVBox/PartsPileCard
@onready var zone_input: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneInput
@onready var zone_output: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneOutput
@onready var zone_memory: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneMemory
@onready var parts_pile_card: PanelContainer = $SafeArea/MainVBox/PartsPileCard
@onready var parts_grid: GridContainer = $SafeArea/MainVBox/PartsPileCard/VBox/Scroll/PartsGrid

@onready var bottom_bar: HBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/BtnConfirm
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var dimmer: ColorRect = $Dimmer
@onready var result_popup: PanelContainer = $ResultPopup
@onready var result_verdict_label: Label = $ResultPopup/VBox/VerdictLabel
@onready var result_score_label: Label = $ResultPopup/VBox/ScoreLabel
@onready var result_stability_label: Label = $ResultPopup/VBox/StabilityLabel
@onready var result_retry_button: Button = $ResultPopup/VBox/Buttons/BtnRetry
@onready var result_back_button: Button = $ResultPopup/VBox/Buttons/BtnBack

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_connect_ui_signals()
	_connect_zone_signals()
	_build_responsive_layout()
	_load_levels()
	if levels.is_empty():
		_show_error("Не удалось загрузить данные уровня «Цифровая реанимация».")
		return
	_start_level(current_level_index)
	_on_viewport_size_changed()

func _process(delta: float) -> void:
	_update_console(delta)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	result_retry_button.pressed.connect(_on_retry_pressed)
	result_back_button.pressed.connect(_on_back_pressed)

func _connect_zone_signals() -> void:
	var callback: Callable = Callable(self, "_on_item_placed")
	for zone in _all_zones():
		if zone.has_signal("item_placed") and not zone.is_connected("item_placed", callback):
			zone.connect("item_placed", callback)

func _build_responsive_layout() -> void:
	if is_instance_valid(_portrait_content) and is_instance_valid(_landscape_content):
		return

	_portrait_content = VBoxContainer.new()
	_portrait_content.name = "PortraitContent"
	_portrait_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portrait_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_portrait_content.add_theme_constant_override("separation", 10)

	_landscape_content = HBoxContainer.new()
	_landscape_content.name = "LandscapeContent"
	_landscape_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landscape_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_content.add_theme_constant_override("separation", 10)
	_landscape_content.visible = false

	_landscape_left = VBoxContainer.new()
	_landscape_left.name = "LandscapeLeft"
	_landscape_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landscape_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_left.size_flags_stretch_ratio = 1.1
	_landscape_left.add_theme_constant_override("separation", 8)

	_landscape_right = VBoxContainer.new()
	_landscape_right.name = "LandscapeRight"
	_landscape_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_landscape_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_landscape_right.size_flags_stretch_ratio = 1.0
	_landscape_right.add_theme_constant_override("separation", 8)

	_landscape_content.add_child(_landscape_left)
	_landscape_content.add_child(_landscape_right)

	main_vbox.add_child(_portrait_content)
	main_vbox.add_child(_landscape_content)

	var insert_index: int = max(0, main_vbox.get_children().find(briefing_card) + 1)
	main_vbox.move_child(_portrait_content, insert_index)
	main_vbox.move_child(_landscape_content, insert_index + 1)

	var portrait_nodes: Array[Control] = [system_card, zones_card, parts_pile_card, bottom_bar]
	for node in portrait_nodes:
		node.reparent(_portrait_content)

func _load_levels() -> void:
	levels = ResusData.load_levels(LEVELS_PATH)

func _start_level(index: int) -> void:
	current_level_index = clamp(index, 0, max(0, levels.size() - 1))
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)
	title_label.text = "ДЕЛО №1: ЦИФРОВАЯ РЕАНИМАЦИЯ"
	stage_label.text = "ЭТАП A"
	briefing_label.text = str(level_data.get("briefing", ""))
	btn_reset.text = "СБРОС"
	btn_confirm.text = "ПОДТВЕРДИТЬ"
	result_retry_button.text = "ПОВТОРИТЬ"
	result_back_button.text = "ВЫХОД"

	var bucket_labels: Dictionary = _bucket_label_map(level_data.get("buckets", []) as Array)

	_zone_setup(pile_zone, "PILE", "Куча деталей")
	_zone_setup(zone_input, "INPUT", str(bucket_labels.get("INPUT", "INPUT")))
	_zone_setup(zone_output, "OUTPUT", str(bucket_labels.get("OUTPUT", "OUTPUT")))
	_zone_setup(zone_memory, "MEMORY", str(bucket_labels.get("MEMORY", "MEMORY")))

	_reset_attempt()

func _zone_setup(zone: Node, zone_id: String, zone_label: String) -> void:
	if zone.has_method("setup"):
		zone.call("setup", zone_id, zone_label)

func _bucket_label_map(buckets: Array) -> Dictionary:
	var out: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			continue
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id == "":
			continue
		out[bucket_id] = str(bucket.get("label", bucket_id))
	return out

func _reset_attempt() -> void:
	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	trace.clear()
	item_nodes.clear()
	btn_confirm.disabled = false
	result_popup.visible = false
	dimmer.visible = false

	for zone in _all_zones():
		if zone.has_method("clear_items"):
			zone.call("clear_items")

	_spawn_items()
	_refresh_system_state(_build_snapshot())
	_update_stability_ui()

func _spawn_items() -> void:
	var items: Array = level_data.get("items", []) as Array
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item_data: Dictionary = (item_v as Dictionary).duplicate(true)
		var item_node: Node = ITEM_SCENE.instantiate()
		if not (item_node is Control):
			continue
		if item_node.has_method("setup"):
			item_node.call("setup", item_data)
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_drag_started"))

		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_node)

		var item_id: String = str(item_data.get("item_id", ""))
		if item_id != "":
			item_nodes[item_id] = item_node

func _on_drag_started(item_id: String, from_zone: String) -> void:
	drag_count += 1
	_log_event("DRAG_START", {
		"item_id": item_id,
		"from_zone": from_zone
	})

func _on_item_placed(item_id: String, to_bucket: String, from_bucket: String) -> void:
	_log_event("ITEM_PLACED", {
		"item_id": item_id,
		"from_zone": from_bucket,
		"to_zone": to_bucket
	})
	_refresh_system_state(_build_snapshot())

func _build_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for item_id_v in item_nodes.keys():
		var item_id: String = str(item_id_v)
		var item_node_v: Variant = item_nodes[item_id]
		if not (item_node_v is Node):
			snapshot[item_id] = "PILE"
			continue
		var item_node: Node = item_node_v as Node
		snapshot[item_id] = str(item_node.get_meta("zone_id", "PILE")).to_upper()
	return snapshot

func _count_placed(snapshot: Dictionary) -> int:
	var count: int = 0
	for zone_v in snapshot.values():
		if str(zone_v).to_upper() != "PILE":
			count += 1
	return count

func _evaluate_system_state(snapshot: Dictionary) -> Dictionary:
	var rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var monitor_on: bool = _rule_holds(snapshot, rules.get("monitor_on_if", {}))
	var ram_ok: bool = _rule_holds(snapshot, rules.get("ram_ok_if", {}))
	var fast_type: bool = _rule_holds(snapshot, rules.get("fast_type_if", {}))
	return {
		"monitor_on": monitor_on,
		"ram_ok": ram_ok,
		"fast_type": fast_type
	}

func _rule_holds(snapshot: Dictionary, rule_v: Variant) -> bool:
	if typeof(rule_v) != TYPE_DICTIONARY:
		return false
	var rule: Dictionary = rule_v as Dictionary
	var item_id: String = str(rule.get("item_id", ""))
	var zone_id: String = str(rule.get("zone_id", "")).to_upper()
	if item_id == "" or zone_id == "":
		return false
	return str(snapshot.get(item_id, "PILE")).to_upper() == zone_id

func _refresh_system_state(snapshot: Dictionary) -> void:
	var state: Dictionary = _evaluate_system_state(snapshot)
	var monitor_on: bool = bool(state.get("monitor_on", false))
	var ram_ok: bool = bool(state.get("ram_ok", false))
	var fast_type: bool = bool(state.get("fast_type", false))

	if monitor_on:
		monitor_screen.color = Color(0.09, 0.2, 0.12, 1.0)
		monitor_label.text = "СИГНАЛ ЕСТЬ"
		monitor_label.modulate = COLOR_OK
	else:
		monitor_screen.color = Color(0.03, 0.03, 0.03, 1.0)
		monitor_label.text = "NO SIGNAL"
		monitor_label.modulate = COLOR_ERR

	console_cps = 40.0 if fast_type else 14.0

	var feedback_rules: Dictionary = level_data.get("feedback_rules", {}) as Dictionary
	var system_rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var console_lines: Array = []
	var problem_lines: Array[String] = []
	var status_color: Color = COLOR_OK

	if not ram_ok:
		problem_lines.append(_feedback_status_line(
			feedback_rules,
			"NO_RAM",
			"Сбой загрузки: установите RAM в ПАМЯТЬ"
		))
		status_color = COLOR_ERR
		console_lines = ((feedback_rules.get("NO_RAM", {}) as Dictionary).get("console_lines", []) as Array).duplicate()
	else:
		console_lines = (system_rules.get("boot_ok_lines", []) as Array).duplicate()

	if not monitor_on:
		problem_lines.append(_feedback_status_line(
			feedback_rules,
			"NO_GPU",
			"Нет видеосигнала: установите GPU в ВЫВОД"
		))
		status_color = COLOR_ERR

	if ram_ok and not fast_type:
		problem_lines.append(_feedback_status_line(
			feedback_rules,
			"NO_CACHE",
			"Диагностика медленная: установите CACHE в ПАМЯТЬ"
		))
		if status_color != COLOR_ERR:
			status_color = COLOR_WARN

	if problem_lines.is_empty():
		problem_lines.append(_feedback_status_line(
			feedback_rules,
			"HEALTHY",
			"Система стабилизирована. Можно подтверждать."
		))
		status_color = COLOR_OK

	if console_lines.is_empty():
		console_lines.append("...")
	_set_console_target(_array_to_lines(console_lines))

	status_label.text = "\n".join(problem_lines)
	status_label.modulate = status_color

func _feedback_status_line(feedback_rules: Dictionary, rule_key: String, fallback: String) -> String:
	return str((feedback_rules.get(rule_key, {}) as Dictionary).get("status", fallback))
func _set_console_target(text: String) -> void:
	if console_target_text == text:
		return
	console_target_text = text
	console_visible_chars = 0
	console_accum = 0.0
	boot_console.text = ""

func _update_console(delta: float) -> void:
	if console_target_text.is_empty():
		return
	if console_visible_chars >= console_target_text.length():
		return
	console_accum += delta * console_cps
	var advance: int = int(floor(console_accum))
	if advance <= 0:
		return
	console_accum -= float(advance)
	console_visible_chars = min(console_target_text.length(), console_visible_chars + advance)
	boot_console.text = console_target_text.substr(0, console_visible_chars)

func _array_to_lines(lines: Array) -> String:
	var out: Array[String] = []
	for line_v in lines:
		out.append(str(line_v))
	return "\n".join(out)

func _on_confirm_pressed() -> void:
	var snapshot: Dictionary = _build_snapshot()
	var placed_count: int = _count_placed(snapshot)
	_log_event("CONFIRM_PRESSED", {"placed_count": placed_count})

	var result: Dictionary = ResusScoring.score(level_data, snapshot, placed_count)
	var system_state: Dictionary = _evaluate_system_state(snapshot)
	var elapsed_ms: int = Time.get_ticks_msec() - start_time_ms
	var match_key: String = "RESUS_A|%s|%d" % [str(level_data.get("id", "RESUS-A")), GlobalMetrics.session_history.size()]

	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "A",
		"level_id": str(level_data.get("id", "RESUS-A-00")),
		"format": "MATCHING",
		"match_key": match_key,
		"snapshot": snapshot,
		"trace": trace.duplicate(true),
		"elapsed_ms": elapsed_ms,
		"drag_count": drag_count,
		"placed_count": placed_count,
		"correct_count": int(result.get("correct_count", 0)),
		"total_items": int(result.get("total_items", 0)),
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_fit": bool(result.get("is_fit", false)),
		"is_correct": bool(result.get("is_correct", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"rule_code": str(result.get("rule_code", "SCORING_RULE")),
		"system_state": system_state
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	btn_confirm.disabled = true
	_show_result(result)

	if bool(result.get("is_correct", false)):
		AudioManager.play("relay")
	elif bool(result.get("is_fit", false)):
		AudioManager.play("click")
	else:
		AudioManager.play("error")

func _show_result(result: Dictionary) -> void:
	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	result_verdict_label.text = verdict_code
	result_score_label.text = "%d/%d  |  %d/%d" % [
		int(result.get("correct_count", 0)),
		int(result.get("total_items", 8)),
		int(result.get("points", 0)),
		int(result.get("max_points", 2))
	]
	result_stability_label.text = "Δ Стабильность: %d" % int(result.get("stability_delta", 0))

	if verdict_code == "PERFECT":
		result_verdict_label.modulate = COLOR_OK
	elif verdict_code == "PARTIAL":
		result_verdict_label.modulate = COLOR_WARN
	else:
		result_verdict_label.modulate = COLOR_ERR

	dimmer.visible = true
	result_popup.visible = true

func _on_reset_pressed() -> void:
	var snapshot: Dictionary = _build_snapshot()
	_log_event("RESET_PRESSED", {
		"placed_count": _count_placed(snapshot)
	})
	_reset_attempt()
	AudioManager.play("click")
func _on_retry_pressed() -> void:
	_reset_attempt()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

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

func _on_viewport_size_changed() -> void:
	var width: float = get_viewport_rect().size.x
	var height: float = get_viewport_rect().size.y
	var should_landscape: bool = width > height and width >= 900.0
	_apply_layout_mode(should_landscape)

func _apply_layout_mode(landscape: bool) -> void:
	if _landscape_active != landscape:
		_landscape_active = landscape
		if landscape:
			system_card.reparent(_landscape_left)
			zones_card.reparent(_landscape_left)
			parts_pile_card.reparent(_landscape_right)
			bottom_bar.reparent(_landscape_right)
		else:
			var portrait_nodes: Array[Control] = [system_card, zones_card, parts_pile_card, bottom_bar]
			for node in portrait_nodes:
				node.reparent(_portrait_content)
		_portrait_content.visible = not landscape
		_landscape_content.visible = landscape

	_apply_responsive_sizes(landscape, get_viewport_rect().size.x)

func _apply_responsive_sizes(landscape: bool, width: float) -> void:
	if landscape:
		briefing_label.custom_minimum_size = Vector2(0, 48)
		monitor_frame.custom_minimum_size = Vector2(0, 108)
		boot_console.custom_minimum_size = Vector2(0, 118)
		_set_zone_height(90)
		parts_pile_card.custom_minimum_size = Vector2(0, 0)
		status_label.custom_minimum_size = Vector2(0, 58)
		btn_reset.custom_minimum_size = Vector2(140, 58)
		btn_confirm.custom_minimum_size = Vector2(170, 58)
		parts_grid.columns = 3 if width >= 1250.0 else 2
	else:
		briefing_label.custom_minimum_size = Vector2(0, 72)
		monitor_frame.custom_minimum_size = Vector2(0, 150)
		boot_console.custom_minimum_size = Vector2(0, 180)
		_set_zone_height(120)
		parts_pile_card.custom_minimum_size = Vector2(0, 220)
		status_label.custom_minimum_size = Vector2(0, 72)
		btn_reset.custom_minimum_size = Vector2(160, 72)
		btn_confirm.custom_minimum_size = Vector2(180, 72)
		parts_grid.columns = 1 if width < 700.0 else 2

func _set_zone_height(height_px: int) -> void:
	var target_size: Vector2 = Vector2(0, height_px)
	if zone_input is Control:
		(zone_input as Control).custom_minimum_size = target_size
	if zone_output is Control:
		(zone_output as Control).custom_minimum_size = target_size
	if zone_memory is Control:
		(zone_memory as Control).custom_minimum_size = target_size

func _all_zones() -> Array:
	return [pile_zone, zone_input, zone_output, zone_memory]

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_confirm.disabled = true

