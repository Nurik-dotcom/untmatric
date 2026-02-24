extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const ITEM_SCENE: PackedScene = preload("res://scenes/ui/ResusPartItem.tscn")
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}

var start_time_ms: int = 0
var drag_count: int = 0
var trace: Array = []
var item_nodes: Dictionary = {}
var input_locked: bool = false

var console_target_text: String = ""
var console_visible_chars: int = 0
var console_cps: float = 16.0
var console_accum: float = 0.0
var _last_state_key: String = ""
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _briefing_collapsed: bool = true
var _briefing_toggle_button: Button = null

@onready var noir_overlay: Node = $NoirOverlay
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var bottom_bar: HBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var briefing_card: PanelContainer = $SafeArea/MainVBox/BriefingCard
@onready var parts_grid: GridContainer = $SafeArea/MainVBox/PartsPileCard/VBox/Scroll/PartsGrid
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var briefing_label: Label = $SafeArea/MainVBox/BriefingCard/BriefingLabel

@onready var monitor_screen: ColorRect = $SafeArea/MainVBox/SystemCard/SystemVBox/MonitorFrame/MonitorScreen
@onready var monitor_label: Label = $SafeArea/MainVBox/SystemCard/SystemVBox/MonitorFrame/MonitorLabel
@onready var boot_console: RichTextLabel = $SafeArea/MainVBox/SystemCard/SystemVBox/BootConsole
@onready var diag_video_value: Label = $SafeArea/MainVBox/SystemCard/SystemVBox/DiagPanel/DiagVBox/VideoRow/VideoValue
@onready var diag_memory_value: Label = $SafeArea/MainVBox/SystemCard/SystemVBox/DiagPanel/DiagVBox/MemoryRow/MemoryValue
@onready var diag_buffer_value: Label = $SafeArea/MainVBox/SystemCard/SystemVBox/DiagPanel/DiagVBox/BufferRow/BufferValue

@onready var pile_zone: Node = $SafeArea/MainVBox/PartsPileCard
@onready var zone_input: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneInput
@onready var zone_output: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneOutput
@onready var zone_memory: Node = $SafeArea/MainVBox/ZonesCard/ZonesVBox/ZoneMemory

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
	add_to_group("resus_a_controller")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	result_retry_button.pressed.connect(_on_retry_pressed)
	result_back_button.pressed.connect(_on_back_pressed)

	_ensure_scroll_layout()
	_setup_collapsible_briefing()
	_connect_zone_signals()
	_load_levels()
	if levels.is_empty():
		_show_error("Failed to load Case 01 stage A data")
		return
	_start_level(current_level_index)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _process(delta: float) -> void:
	_update_console(delta)

func is_input_locked() -> bool:
	return input_locked

func _connect_zone_signals() -> void:
	if pile_zone.has_signal("item_placed"):
		pile_zone.connect("item_placed", Callable(self, "_on_pile_item_placed"))

	for zone in _socket_zones():
		if zone.has_signal("hint_requested"):
			zone.connect("hint_requested", Callable(self, "_on_socket_hint_requested"))
		if zone.has_signal("drop_accepted"):
			zone.connect("drop_accepted", Callable(self, "_on_socket_drop_accepted"))
		if zone.has_signal("drop_rejected"):
			zone.connect("drop_rejected", Callable(self, "_on_socket_drop_rejected"))

func _load_levels() -> void:
	levels = ResusData.load_levels(LEVELS_PATH)

func _start_level(index: int) -> void:
	current_level_index = clamp(index, 0, max(0, levels.size() - 1))
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)
	title_label.text = "Case 01: Digital Reanimation"
	stage_label.text = "STAGE A"
	briefing_label.text = str(level_data.get("briefing", ""))
	btn_reset.text = "RESET"
	btn_confirm.text = "CONFIRM"
	result_retry_button.text = "RETRY"
	result_back_button.text = "BACK"

	_configure_zones()
	_reset_attempt()

func _configure_zones() -> void:
	var bucket_labels: Dictionary = _bucket_label_map(level_data.get("buckets", []) as Array)
	var socket_map: Dictionary = level_data.get("socket_map", {}) as Dictionary

	if pile_zone.has_method("setup"):
		pile_zone.call("setup", "PILE", "PARTS PILE")

	if zone_input.has_method("setup"):
		zone_input.call("setup", "INPUT", str(bucket_labels.get("INPUT", "INPUT")), _string_array(socket_map.get("INPUT", [])))
	if zone_output.has_method("setup"):
		zone_output.call("setup", "OUTPUT", str(bucket_labels.get("OUTPUT", "OUTPUT")), _string_array(socket_map.get("OUTPUT", [])))
	if zone_memory.has_method("setup"):
		zone_memory.call("setup", "MEMORY", str(bucket_labels.get("MEMORY", "MEMORY")), _string_array(socket_map.get("MEMORY", [])))

func _reset_attempt() -> void:
	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	trace.clear()
	item_nodes.clear()
	input_locked = false
	btn_confirm.disabled = false
	dimmer.visible = false
	result_popup.visible = false
	_last_state_key = ""

	if pile_zone.has_method("clear_items"):
		pile_zone.call("clear_items")
	for zone in _socket_zones():
		if zone.has_method("clear_items"):
			zone.call("clear_items")

	_spawn_items()
	_refresh_system_state(_build_placements_snapshot())
	_update_stability_ui()

func _spawn_items() -> void:
	var items: Array = level_data.get("items", []) as Array
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item_data: Dictionary = (item_v as Dictionary).duplicate(true)
		var item_node_v: Variant = ITEM_SCENE.instantiate()
		if not (item_node_v is Control):
			continue
		var item_node: Control = item_node_v as Control
		if item_node.has_method("setup"):
			item_node.call("setup", item_data)
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_drag_started"))
		if item_node.has_signal("drag_cancelled"):
			item_node.connect("drag_cancelled", Callable(self, "_on_drag_cancelled"))
		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_node)
		var item_id: String = str(item_data.get("item_id", ""))
		if item_id != "":
			item_nodes[item_id] = item_node

func _on_drag_started(item_id: String, from_zone: String) -> void:
	if input_locked:
		return
	drag_count += 1
	_log_event("DRAG_START", {
		"item_id": item_id,
		"from_zone": from_zone
	})
	_highlight_hint_socket(item_id)

func _on_drag_cancelled(item_id: String, from_zone: String) -> void:
	if input_locked:
		return
	if item_id == "":
		return

	var item_node_v: Variant = item_nodes.get(item_id, null)
	if item_node_v is Control and pile_zone.has_method("add_item_control"):
		pile_zone.call("add_item_control", item_node_v as Control)
		_bounce_node(item_node_v as Control)

	_refresh_system_state(_build_placements_snapshot())
	_log_event("DROP_BOUNCE", {
		"item_id": item_id,
		"from_zone": from_zone,
		"attempted_socket": "INVALID"
	})
	_play_sfx("error")
	_show_socket_error("Неверный сокет")
	_highlight_hint_socket(item_id)

func _on_socket_hint_requested(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	_log_event("SOCKET_HINT", {
		"item_id": item_id,
		"hinted_socket": socket_id
	})

func _on_socket_drop_accepted(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	_log_event("DROP_OK", {
		"item_id": item_id,
		"socket": socket_id
	})

func _on_socket_drop_rejected(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	_log_event("DROP_BOUNCE", {
		"item_id": item_id,
		"attempted_socket": socket_id
	})
	_show_socket_error("Неверный сокет")

func on_socket_drop(payload: Dictionary, socket_id: String, accepted: bool) -> void:
	if input_locked:
		return
	var item_id: String = str(payload.get("item_id", ""))
	var source_path: String = str(payload.get("node_path", ""))
	if source_path == "":
		return
	var source_node: Node = get_node_or_null(source_path)
	if source_node == null or not (source_node is Control):
		return

	if accepted:
		var zone: Node = _zone_for_socket(socket_id)
		if zone != null and zone.has_method("add_item_control"):
			zone.call("add_item_control", source_node)
		_refresh_system_state(_build_placements_snapshot())
		_play_sfx("click")
		return

	if pile_zone.has_method("add_item_control"):
		pile_zone.call("add_item_control", source_node)
	_refresh_system_state(_build_placements_snapshot())
	_bounce_node(source_node as Control)
	_play_sfx("error")
	_show_socket_error("Неверный сокет")
	if item_id != "":
		_highlight_hint_socket(item_id)

func _on_pile_item_placed(item_id: String, _to_bucket: String, from_bucket: String) -> void:
	if input_locked:
		return
	_log_event("DROP_OK", {
		"item_id": item_id,
		"socket": "PILE",
		"from": from_bucket
	})
	_refresh_system_state(_build_placements_snapshot())

func _build_placements_snapshot() -> Dictionary:
	var placements: Dictionary = {}
	for item_id_v in item_nodes.keys():
		var item_id: String = str(item_id_v)
		var item_node_v: Variant = item_nodes.get(item_id, null)
		if not (item_node_v is Node):
			placements[item_id] = "PILE"
			continue
		var item_node: Node = item_node_v as Node
		placements[item_id] = str(item_node.get_meta("zone_id", "PILE")).to_upper()
	return placements

func _count_placed(placements: Dictionary) -> int:
	var count: int = 0
	for zone_v in placements.values():
		if str(zone_v).to_upper() != "PILE":
			count += 1
	return count

func _evaluate_system_state(placements: Dictionary) -> Dictionary:
	var rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var fx_rules: Dictionary = level_data.get("fx_rules", {}) as Dictionary
	var monitor_rule: Dictionary = fx_rules.get("gpu_on", rules.get("monitor_on_if", {})) as Dictionary
	var ram_rule: Dictionary = fx_rules.get("ram_ok", rules.get("ram_ok_if", {})) as Dictionary
	var cache_rule: Dictionary = fx_rules.get("cache_ok", rules.get("fast_type_if", {})) as Dictionary

	var gpu_ok: bool = _rule_holds(placements, monitor_rule)
	var ram_ok: bool = _rule_holds(placements, ram_rule)
	var cache_ok: bool = _rule_holds(placements, cache_rule)

	return {
		"gpu_ok": gpu_ok,
		"ram_ok": ram_ok,
		"cache_ok": cache_ok,
		"monitor_on": gpu_ok,
		"fast_type": cache_ok
	}

func _rule_holds(placements: Dictionary, rule_v: Variant) -> bool:
	if typeof(rule_v) != TYPE_DICTIONARY:
		return false
	var rule: Dictionary = rule_v as Dictionary
	var item_id: String = str(rule.get("item_id", "")).strip_edges()
	var zone_id: String = str(rule.get("bucket_id", rule.get("zone_id", ""))).to_upper()
	if item_id == "" or zone_id == "":
		return false
	return str(placements.get(item_id, "PILE")).to_upper() == zone_id

func _refresh_system_state(placements: Dictionary) -> void:
	var state: Dictionary = _evaluate_system_state(placements)
	var gpu_ok: bool = bool(state.get("gpu_ok", false))
	var ram_ok: bool = bool(state.get("ram_ok", false))
	var cache_ok: bool = bool(state.get("cache_ok", false))

	var state_key: String = "%s|%s|%s" % [str(gpu_ok), str(ram_ok), str(cache_ok)]
	if _last_state_key == state_key:
		return
	_last_state_key = state_key

	_update_monitor(gpu_ok)
	_update_diag_panel(gpu_ok, ram_ok, cache_ok)

	console_cps = 42.0 if cache_ok else 16.0
	var console_lines: Array[String] = _build_console_lines(gpu_ok, ram_ok, placements)
	var console_text: String = "\n".join(console_lines)
	_set_console_target(console_text)

	status_label.text = "VIDEO %s | MEMORY %s | BUFFER %s" % [
		"OK" if gpu_ok else "FAIL",
		"OK" if ram_ok else "FAIL",
		"FAST" if cache_ok else "SLOW"
	]
	status_label.modulate = COLOR_OK if gpu_ok and ram_ok and cache_ok else (COLOR_ERR if not ram_ok or not gpu_ok else COLOR_WARN)

	_log_event("DIAG_STATE", {
		"gpu_ok": gpu_ok,
		"ram_ok": ram_ok,
		"cache_ok": cache_ok
	})

func _update_monitor(monitor_on: bool) -> void:
	if monitor_on:
		monitor_screen.color = Color(0.08, 0.2, 0.12, 1.0)
		monitor_label.text = "SIGNAL OK"
		monitor_label.modulate = COLOR_OK
	else:
		monitor_screen.color = Color(0.03, 0.03, 0.03, 1.0)
		monitor_label.text = "NO SIGNAL"
		monitor_label.modulate = COLOR_ERR

func _update_diag_panel(gpu_ok: bool, ram_ok: bool, cache_ok: bool) -> void:
	var diag: Dictionary = level_data.get("diag_panel", {}) as Dictionary
	var gpu_diag: Dictionary = diag.get("GPU", {}) as Dictionary
	var ram_diag: Dictionary = diag.get("RAM", {}) as Dictionary
	var cache_diag: Dictionary = diag.get("CACHE", {}) as Dictionary

	diag_video_value.text = str(gpu_diag.get("ok", "VIDEO: OK")) if gpu_ok else str(gpu_diag.get("bad", "VIDEO: NO SIGNAL"))
	diag_memory_value.text = str(ram_diag.get("ok", "MEMORY: OK")) if ram_ok else str(ram_diag.get("bad", "MEMORY: READ ERROR"))
	diag_buffer_value.text = str(cache_diag.get("ok", "BUFFER: FAST")) if cache_ok else str(cache_diag.get("bad", "BUFFER: SLOW"))

	diag_video_value.modulate = COLOR_OK if gpu_ok else COLOR_ERR
	diag_memory_value.modulate = COLOR_OK if ram_ok else COLOR_ERR
	diag_buffer_value.modulate = COLOR_OK if cache_ok else COLOR_WARN

func _build_console_lines(gpu_ok: bool, ram_ok: bool, placements: Dictionary) -> Array[String]:
	var feedback_rules: Dictionary = level_data.get("feedback_rules", {}) as Dictionary
	var system_rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var fx_rules: Dictionary = level_data.get("fx_rules", {}) as Dictionary

	if not ram_ok:
		var no_ram: Dictionary = feedback_rules.get("NO_RAM", {}) as Dictionary
		return _string_array(no_ram.get("console_lines", []))

	var lines: Array[String] = _string_array(system_rules.get("boot_ok_lines", []))
	if _input_devices_connected(placements):
		for line in _string_array(fx_rules.get("hid_lines_on_input", [])):
			lines.append(line)

	if not gpu_ok:
		lines.append("[WARN] display output unavailable")

	if lines.is_empty():
		lines.append("[BOOT] ...")
	return lines

func _input_devices_connected(placements: Dictionary) -> bool:
	var socket_map: Dictionary = level_data.get("socket_map", {}) as Dictionary
	var input_ids: Array[String] = _string_array(socket_map.get("INPUT", []))
	for item_id in input_ids:
		if str(placements.get(item_id, "PILE")).to_upper() == "INPUT":
			return true
	return false

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

func _on_confirm_pressed() -> void:
	if input_locked:
		return

	var placements: Dictionary = _build_placements_snapshot()
	var placed_count: int = _count_placed(placements)
	_log_event("CONFIRM_PRESSED", {
		"placed_count": placed_count
	})

	input_locked = true
	btn_confirm.disabled = true

	var result: Dictionary = ResusScoring.score(level_data, placements, placed_count)
	var system_state: Dictionary = _evaluate_system_state(placements)
	var elapsed_ms: int = Time.get_ticks_msec() - start_time_ms
	var match_key: String = "RESUS_A|%s|%d" % [str(level_data.get("id", "RESUS-A")), GlobalMetrics.session_history.size()]

	var snapshot_a: Dictionary = {
		"placements": placements.duplicate(true),
		"system_state": system_state.duplicate(true)
	}

	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "A",
		"level_id": str(level_data.get("id", "RESUS-A-00")),
		"format": "MATCHING",
		"match_key": match_key,
		"snapshot": placements.duplicate(true),
		"diegetic_snapshot": snapshot_a,
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
		"system_state": system_state.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()
	_show_result(result)

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _show_result(result: Dictionary) -> void:
	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	result_verdict_label.text = verdict_code
	result_score_label.text = "%d/%d | %d/%d" % [
		int(result.get("correct_count", 0)),
		int(result.get("total_items", 8)),
		int(result.get("points", 0)),
		int(result.get("max_points", 2))
	]
	result_stability_label.text = "STABILITY %d" % int(result.get("stability_delta", 0))

	if verdict_code == "PERFECT":
		result_verdict_label.modulate = COLOR_OK
	elif verdict_code == "PARTIAL":
		result_verdict_label.modulate = COLOR_WARN
	else:
		result_verdict_label.modulate = COLOR_ERR

	dimmer.visible = true
	result_popup.visible = true

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {
		"placed_count": _count_placed(_build_placements_snapshot())
	})
	_reset_attempt()
	_play_sfx("click")

func _on_retry_pressed() -> void:
	_reset_attempt()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _highlight_hint_socket(item_id: String) -> void:
	var target_socket: String = _expected_socket_for_item(item_id)
	if target_socket == "":
		return
	var zone: Control = _zone_for_socket(target_socket) as Control
	if zone == null:
		return
	var tween: Tween = create_tween()
	zone.modulate = Color(1.12, 1.14, 1.12, 1.0)
	tween.tween_property(zone, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)

func _expected_socket_for_item(item_id: String) -> String:
	var socket_map: Dictionary = level_data.get("socket_map", {}) as Dictionary
	for socket_id_v in socket_map.keys():
		var socket_id: String = str(socket_id_v).to_upper()
		for accepted_id in _string_array(socket_map.get(socket_id, [])):
			if accepted_id == item_id:
				return socket_id
	return ""

func _bounce_node(node: Control) -> void:
	var tween: Tween = create_tween()
	node.scale = Vector2(1.12, 1.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.2)

func _socket_zones() -> Array:
	return [zone_input, zone_output, zone_memory]

func _zone_for_socket(socket_id: String) -> Node:
	match socket_id.to_upper():
		"INPUT":
			return zone_input
		"OUTPUT":
			return zone_output
		"MEMORY":
			return zone_memory
		_:
			return null

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

func _string_array(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(values) != TYPE_ARRAY:
		return out
	for value_v in values as Array:
		out.append(str(value_v))
	return out

func _log_event(name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - start_time_ms,
		"event": name,
		"data": data.duplicate(true)
	})

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", float(GlobalMetrics.stability))

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_confirm.disabled = true

func _show_socket_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR

func _ensure_scroll_layout() -> void:
	if _content_scroll != null and is_instance_valid(_content_scroll):
		return

	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "ContentScroll"
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_content_vbox = VBoxContainer.new()
	_content_vbox.name = "ContentVBox"
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_scroll.add_child(_content_vbox)

	var move_nodes: Array[Node] = []
	for child in main_vbox.get_children():
		if child == header or child == bottom_bar:
			continue
		move_nodes.append(child)

	for node in move_nodes:
		node.reparent(_content_vbox)

	main_vbox.add_child(_content_scroll)
	var bottom_index: int = main_vbox.get_children().find(bottom_bar)
	if bottom_index >= 0:
		main_vbox.move_child(_content_scroll, bottom_index)

func _setup_collapsible_briefing() -> void:
	if briefing_card == null or briefing_label == null:
		return

	var briefing_parent: Node = briefing_label.get_parent()
	if briefing_parent == briefing_card:
		var wrapper: VBoxContainer = VBoxContainer.new()
		wrapper.name = "BriefingVBox"
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrapper.add_theme_constant_override("separation", 6)

		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.name = "BriefingTopRow"
		top_row.add_theme_constant_override("separation", 8)

		var title: Label = Label.new()
		title.text = "BRIEFING"
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title)

		_briefing_toggle_button = Button.new()
		_briefing_toggle_button.name = "BriefingToggleButton"
		_briefing_toggle_button.text = "?"
		_briefing_toggle_button.custom_minimum_size = Vector2(40.0, 36.0)
		_briefing_toggle_button.pressed.connect(_on_briefing_toggle_pressed)
		top_row.add_child(_briefing_toggle_button)

		briefing_card.remove_child(briefing_label)
		wrapper.add_child(top_row)
		wrapper.add_child(briefing_label)
		briefing_card.add_child(wrapper)
	elif _briefing_toggle_button == null:
		var existing_btn: Button = briefing_card.find_child("BriefingToggleButton", true, false) as Button
		if existing_btn != null:
			_briefing_toggle_button = existing_btn

	_apply_briefing_state()

func _on_briefing_toggle_pressed() -> void:
	_briefing_collapsed = not _briefing_collapsed
	_apply_briefing_state()

func _apply_briefing_state() -> void:
	if briefing_label == null:
		return
	briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_label.max_lines_visible = 2 if _briefing_collapsed else 0
	if _briefing_toggle_button != null:
		_briefing_toggle_button.text = "?" if _briefing_collapsed else "x"

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	if _content_vbox != null:
		_content_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 8 if compact else 10)
	bottom_bar.add_theme_constant_override("separation", 8 if compact else 10)
	stability_bar.custom_minimum_size.x = 160.0 if compact else 220.0

	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	btn_reset.custom_minimum_size = Vector2(120.0 if compact else 160.0, 60.0 if compact else 72.0)
	btn_confirm.custom_minimum_size = Vector2(140.0 if compact else 180.0, 60.0 if compact else 72.0)
	status_label.custom_minimum_size.y = 60.0 if compact else 72.0

	if phone_portrait:
		parts_grid.columns = 1
	elif compact:
		parts_grid.columns = 2
	else:
		parts_grid.columns = 2

	var popup_width: float = clampf(viewport_size.x - (24.0 if compact else 120.0), 300.0, 460.0)
	var popup_height: float = clampf(viewport_size.y - (24.0 if compact else 120.0), 240.0, 380.0)
	result_popup.offset_left = -popup_width * 0.5
	result_popup.offset_top = -popup_height * 0.5
	result_popup.offset_right = popup_width * 0.5
	result_popup.offset_bottom = popup_height * 0.5

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))
