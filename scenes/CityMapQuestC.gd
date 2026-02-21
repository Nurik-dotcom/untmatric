extends Control

const PACK_PATH := "res://data/city_map/pack_6_3_C.json"
const LOG_PREFIX := "case_6_3"
const DEFAULT_ACCENT := Color(0.40, 0.72, 1.0, 1.0)
const ARROW_ANGLE_RAD := 0.52
const ARROW_LEN := 16.0

@onready var content_split: BoxContainer = $SafeArea/MainVBox/ContentSplit
@onready var graph_container: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer
@onready var edges_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/EdgesLayer
@onready var nodes_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/NodesLayer
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var label_progress: Label = $SafeArea/MainVBox/Header/LabelProgress
@onready var btn_reset: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnReset
@onready var btn_submit: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnNext
@onready var sum_input: LineEdit = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumInput
@onready var path_display: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/PathDisplay
@onready var sim_time_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SimTimeLabel
@onready var sum_live_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumLiveLabel
@onready var constraint_info_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ConstraintInfoLabel
@onready var warning_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/WarningLabel
@onready var status_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/StatusLabel
@onready var schedule_list: VBoxContainer = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SchedulePanel/ScheduleMargin/ScheduleVBox/ScheduleScroll/ScheduleList
@onready var label_state: Label = $SafeArea/MainVBox/Header/LabelState
@onready var label_timer: Label = $SafeArea/MainVBox/Header/LabelTimer
@onready var footer_label: Label = $SafeArea/MainVBox/Footer/FooterLabel
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
var first_attempt_edge: String = ""
var level_started_ms: int = 0
var first_action_ms: int = -1
var planning_time_ms: int = 0

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

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	sum_input.text_changed.connect(_on_sum_input_changed)
	graph_container.resized.connect(_on_graph_resized)

	_load_pack(PACK_PATH)
	_apply_content_layout_mode()
	_setup_timer()
	call_deferred("_start_pack_run")

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

	_set_briefing()
	_rebuild_graph_ui()
	_build_schedule_ui()
	_reset_round_state(true)
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
	var shown_index := maxi(0, level_index + 1)
	label_progress.text = "TASK: %d/%d" % [shown_index, maxi(1, level_total)]
	if level_index >= level_total - 1:
		btn_next.text = "FINISH"
	else:
		btn_next.text = "NEXT"

func _is_round_locked() -> bool:
	return is_game_over or stage_completed or input_locked

func _lock_input(locked: bool) -> void:
	input_locked = locked
	sum_input.editable = not locked and not is_game_over and not stage_completed
	btn_submit.disabled = locked or is_game_over or stage_completed
	btn_reset.disabled = locked or is_game_over or stage_completed
	_update_visuals()

func _on_next_pressed() -> void:
	if not stage_completed:
		return
	if level_index + 1 >= level_total:
		_finalize_pack_run()
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_load_sublevel(level_index + 1)

func _finalize_pack_run() -> void:
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
	content_split.vertical = get_viewport_rect().size.x < get_viewport_rect().size.y

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
	if real_time_sec > int(level_data.get("time_limit_sec", 140)):
		_recalculate_stability()

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

func _set_briefing() -> void:
	briefing_title.text = "ОКНО КОМЕНДАНТСКОГО ЧАСА"
	briefing_text.text = "Доберитесь до узла L в условиях динамических окон патруля. Рёбра ЗАКРЫТО заблокированы, рёбра ОПАСНО имеют повышенную стоимость."
	var constraint_text := "ОГРАНИЧЕНИЕ: ОБЯЗАТЕЛЬНО %s | НЕ БОЛЕЕ ОДНОГО ИЗ (E,G) | ИЗБЕГАТЬ %s" % [
		"-" if must_visit_nodes.is_empty() else ",".join(must_visit_nodes),
		"-" if blacklist_nodes.is_empty() else ",".join(blacklist_nodes)
	]
	briefing_constraint.text = constraint_text
	constraint_info_label.text = constraint_text
	footer_label.text = "РЕАЛЬНЫЙ таймер в заголовке. СИМ-время меняется только при успешном перемещении."

func _build_schedule_ui() -> void:
	for child in schedule_list.get_children():
		child.queue_free()

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		if not edge.has("schedule"):
			continue
		var parts: Array[String] = []
		for slot_var in edge.schedule:
			var slot: Dictionary = slot_var
			var state := str(slot.get("state", "open"))
			var w_text := "ЗАКРЫТО" if state == "closed" else str(slot.get("w", edge.get("w", 0)))
			parts.append("[%d-%d: %s]" % [int(slot.get("t_from", 0)), int(slot.get("t_to", 0)), w_text])

		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.text = "%s->%s: %s" % [str(edge.get("from", "")), str(edge.get("to", "")), " ".join(parts)]
		schedule_list.add_child(row)

func _calculate_min_sum_dynamic() -> int:
	var start_node := str(level_data.get("start_node", ""))
	var end_node := str(level_data.get("end_node", ""))
	if start_node.is_empty() or end_node.is_empty():
		return 0

	var frontier: Array[Dictionary] = [{
		"node": start_node,
		"sim": 0,
		"cost": 0,
		"path": [start_node]
	}]
	var best := 1_000_000_000

	while not frontier.is_empty():
		var best_index := 0
		for i in range(1, frontier.size()):
			if int(frontier[i].cost) < int(frontier[best_index].cost):
				best_index = i
		var state: Dictionary = frontier.pop_at(best_index)

		var node_id := str(state.node)
		var sim := int(state.sim)
		var cost := int(state.cost)
		var path_local: Array = state.path
		if cost >= best:
			continue

		if node_id == end_node and _must_visit_ok(path_local) and not _is_xor_violation(path_local) and not _path_has_blacklist(path_local):
			best = min(best, cost)
			continue

		for next_id in adjacency.get(node_id, {}).keys():
			var edge: Dictionary = adjacency[node_id][next_id]
			var runtime := _edge_runtime_state(edge, sim)
			if runtime.state == "closed":
				continue

			var visits := 0
			for p in path_local:
				if str(p) == str(next_id):
					visits += 1
			if visits >= 2:
				continue

			var next_path := path_local + [str(next_id)]
			if _is_xor_violation(next_path):
				continue
			if _path_has_blacklist(next_path):
				continue

			frontier.append({
				"node": str(next_id),
				"sim": sim + int(runtime.weight),
				"cost": cost + int(runtime.weight),
				"path": next_path
			})

	return 0 if best >= 1_000_000_000 else best

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
	edge_visuals.clear()
	node_buttons.clear()

	if graph_container.size.x <= 0.0 or graph_container.size.y <= 0.0:
		return

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty() or not node_defs.has(from_id) or not node_defs.has(to_id):
			continue

		var start_pos := _node_screen_pos(node_defs[from_id])
		var end_pos := _node_screen_pos(node_defs[to_id])
		var line := Line2D.new()
		line.width = 4.0
		line.points = PackedVector2Array([start_pos, end_pos])
		line.gradient = _build_gradient(Color(0.18, 0.22, 0.30, 0.28), Color(0.30, 0.38, 0.52, 0.48))
		edges_layer.add_child(line)

		var arrow := _create_arrow_polygon(start_pos, end_pos)
		edges_layer.add_child(arrow)

		var label := Label.new()
		label.text = str(edge.get("w", 0))
		label.add_theme_font_size_override("font_size", 15)
		label.position = _edge_label_pos(start_pos, end_pos)
		label.add_theme_color_override("font_color", Color(0.62, 0.74, 0.90))
		edges_layer.add_child(label)

		edge_visuals[_edge_key(from_id, to_id)] = {
			"line": line,
			"arrow": arrow,
			"label": label,
			"edge": edge
		}

	for node_id in node_defs.keys():
		var node: Dictionary = node_defs[node_id]
		var btn := Button.new()
		btn.text = str(node.get("label", node_id))
		var diameter := node_radius_px * 2.0
		btn.size = Vector2(diameter, diameter)
		btn.position = _node_screen_pos(node) - Vector2(node_radius_px, node_radius_px)
		btn.pressed.connect(_on_node_pressed.bind(node_id))
		nodes_layer.add_child(btn)
		node_buttons[node_id] = btn

func _edge_label_pos(start_pos: Vector2, end_pos: Vector2) -> Vector2:
	var dir := (end_pos - start_pos).normalized()
	var normal := Vector2(-dir.y, dir.x)
	return ((start_pos + end_pos) * 0.5) + (normal * 12.0) - Vector2(10.0, 10.0)

func _create_arrow_polygon(start_pos: Vector2, end_pos: Vector2) -> Polygon2D:
	var dir := (end_pos - start_pos).normalized()
	var tip := end_pos - dir * (node_radius_px + 4.0)
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
	var pos: Dictionary = node_data.get("pos", {})
	var x := float(pos.get("x", 0.0))
	var y := float(pos.get("y", 0.0))

	if x >= 0.0 and x <= 1.0 and y >= 0.0 and y <= 1.0:
		var padding := node_radius_px + 4.0
		var usable := graph_container.size - Vector2(padding * 2.0, padding * 2.0)
		usable.x = maxf(1.0, usable.x)
		usable.y = maxf(1.0, usable.y)
		return Vector2(padding + x * usable.x, padding + y * usable.y)

	return Vector2(x, y)

func _reset_round_state(full_reset: bool) -> void:
	current_node = str(level_data.get("start_node", "A"))
	path = [current_node]
	path_sum = 0
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
	sum_input.clear()
	status_label.text = ""

	if full_reset:
		level_started_ms = Time.get_ticks_msec()
		real_time_sec = 0

	_update_visuals()

func _update_visuals() -> void:
	path_display.text = "ПУТЬ: %s" % " -> ".join(path)
	sim_time_label.text = "СИМ: %d" % sim_time_sec
	sum_live_label.text = "СУММА: %d" % path_sum

	if xor_violation:
		warning_label.text = "ПРЕДУПРЕЖДЕНИЯ: НАРУШЕНИЕ XOR"
	elif _path_has_blacklist(path):
		warning_label.text = "ПРЕДУПРЕЖДЕНИЯ: ВХОД В ЧЁРНЫЙ СПИСОК"
	elif closed_edge_attempts > 0:
		warning_label.text = "ПРЕДУПРЕЖДЕНИЯ: ЗАКРЫТОЕ РЕБРО ЗАБЛОКИРОВАНО"
	elif cycle_detected:
		warning_label.text = "ПРЕДУПРЕЖДЕНИЯ: ОБНАРУЖЕН ЦИКЛ"
	else:
		warning_label.text = "ПРЕДУПРЕЖДЕНИЯ: -"

	for node_id in node_buttons.keys():
		var btn: Button = node_buttons[node_id]
		var is_current: bool = node_id == current_node
		var is_available: bool = adjacency.has(current_node) and adjacency[current_node].has(node_id)
		btn.disabled = is_current or not is_available or _is_round_locked()
		if is_current:
			btn.modulate = Color(0.95, 0.86, 0.45)
		elif is_available:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.42, 0.46, 0.56)

	for key in edge_visuals.keys():
		var visual: Dictionary = edge_visuals[key]
		var edge: Dictionary = visual.edge
		var runtime := _edge_runtime_state(edge, sim_time_sec)
		var is_available: bool = adjacency.has(current_node) and adjacency[current_node].has(str(edge.get("to", ""))) and str(edge.get("from", "")) == current_node
		var is_traversed: bool = _path_contains_edge(str(edge.get("from", "")), str(edge.get("to", "")))

		var state := "dim"
		if is_traversed:
			state = "traversed"
		elif runtime.state == "closed":
			state = "closed"
		elif runtime.danger:
			state = "danger"
		elif is_available:
			state = "available"

		_apply_edge_style(key, state, runtime)

func _apply_edge_style(key: String, state: String, runtime: Dictionary) -> void:
	if not edge_visuals.has(key):
		return
	var visual: Dictionary = edge_visuals[key]
	var line: Line2D = visual.line
	var arrow: Polygon2D = visual.arrow
	var label: Label = visual.label

	var start_color := Color(0.18, 0.22, 0.30, 0.28)
	var end_color := Color(0.30, 0.38, 0.52, 0.48)
	var label_text := str(runtime.weight)

	match state:
		"available":
			start_color = Color(0.24, 0.40, 0.62, 0.48)
			end_color = accent_color
			end_color.a = 0.95
		"traversed":
			start_color = accent_color.lightened(0.10)
			start_color.a = 0.80
			end_color = Color(0.92, 0.97, 1.0, 1.0)
		"closed":
			start_color = Color(0.58, 0.14, 0.14, 0.55)
			end_color = Color(1.0, 0.25, 0.25, 1.0)
			label_text = "ЗАКРЫТО"
		"danger":
			start_color = Color(0.62, 0.35, 0.12, 0.60)
			end_color = Color(1.0, 0.62, 0.18, 1.0)
			label_text = "%d ОПАСНО" % int(runtime.weight)

	line.gradient = _build_gradient(start_color, end_color)
	arrow.color = end_color
	label.text = label_text
	label.add_theme_color_override("font_color", end_color.lightened(0.10))

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

	if edge.has("schedule"):
		for slot_var in edge.schedule:
			var slot: Dictionary = slot_var
			var from_t := int(slot.get("t_from", 0))
			var to_t := int(slot.get("t_to", 0))
			if time_sec >= from_t and time_sec < to_t:
				active_state = str(slot.get("state", "open"))
				active_weight = int(slot.get("w", base_weight))
				break

	return {
		"weight": active_weight,
		"state": active_state,
		"danger": active_state != "closed" and active_weight > base_weight
	}

func _on_node_pressed(node_id: String) -> void:
	if _is_round_locked():
		return
	if not adjacency.has(current_node) or not adjacency[current_node].has(node_id):
		return

	if first_attempt_edge.is_empty():
		first_attempt_edge = _edge_key(current_node, node_id)
		first_action_ms = Time.get_ticks_msec() - level_started_ms
		planning_time_ms = first_action_ms

	if path.size() >= 2 and path[path.size() - 2] == node_id:
		backtrack_count += 1
	if path.has(node_id):
		cycle_events += 1
		cycle_detected = true

	var edge: Dictionary = adjacency[current_node][node_id]
	var runtime := _edge_runtime_state(edge, sim_time_sec)
	if runtime.state == "closed":
		closed_edge_attempts += 1
		n_closed += 1
		dynamic_weight_awareness = false
		status_label.text = "ЗАКРЫТОЕ РЕБРО: перемещение заблокировано"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		_recalculate_stability()
		_update_visuals()
		return

	if runtime.danger:
		dynamic_weight_awareness = false

	path_sum += int(runtime.weight)
	step_weights.append(int(runtime.weight))
	sim_time_sec += int(runtime.weight)
	path.append(node_id)
	current_node = node_id

	if blacklist_nodes.has(node_id):
		ambush_hits += 1
		constraint_violations += 1
		status_label.text = "ЗАСАДА: вход в узел чёрного списка"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.30))

	if _is_xor_violation(path) and not xor_violation:
		xor_violation = true
		n_logic += 1
		constraint_violations += 1
		status_label.text = "НАРУШЕНИЕ XOR: в группе допускается не более одного узла"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.18))

	_recalculate_stability()
	_update_visuals()

func _on_reset_pressed() -> void:
	if _is_round_locked():
		return
	n_reset += 1
	_reset_round_state(false)
	_recalculate_stability()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_sum_input_changed(new_text: String) -> void:
	var digits := ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits != new_text:
		sum_input.text = digits
		sum_input.caret_column = digits.length()

func _on_submit_pressed() -> void:
	if _is_round_locked():
		return

	attempt_in_sublevel += 1
	attempt_in_run += 1
	var verdict := _judge_solution(sum_input.text.strip_edges())
	_log_attempt(verdict)

	if verdict.result_code == "OK":
		status_label.text = "Маршрут принят. Динамические ограничения соблюдены."
		status_label.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
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

	status_label.text = _result_message(str(verdict.result_code))
	status_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.28))
	_recalculate_stability()

func _result_message(result_code: String) -> String:
	match result_code:
		"ERR_INCOMPLETE":
			return "Дойдите до узла L перед отправкой."
		"ERR_MISSING_TRANSIT":
			return "Ограничение не выполнено: посетите обязательные транзитные узлы."
		"ERR_LOGIC_VIOLATION":
			return "Нарушено ограничение XOR."
		"ERR_AMBUSH":
			return "Посещён узел из чёрного списка."
		"ERR_PARSE":
			return "Вводите только цифры."
		"ERR_CALC":
			return "Введённая сумма не совпадает со смоделированной стоимостью пути."
		"ERR_NOT_OPT":
			return "Маршрут корректный, но не оптимальный."
		"ERR_PATH_INVALID":
			return "Маршрут недопустим для ориентированных рёбер."
		_:
			return "Необработанный результат: %s" % result_code

func _judge_solution(input_text: String) -> Dictionary:
	var sum_actual := _compute_path_sum()
	var sum_input_value: Variant = null
	var result_code := "OK"

	if sum_actual < 0:
		result_code = "ERR_PATH_INVALID"
	elif current_node != str(level_data.get("end_node", "L")):
		result_code = "ERR_INCOMPLETE"
	elif not _must_visit_ok(path):
		n_transit += 1
		constraint_violations += 1
		result_code = "ERR_MISSING_TRANSIT"
	elif _is_xor_violation(path):
		if not xor_violation:
			xor_violation = true
			n_logic += 1
		constraint_violations += 1
		result_code = "ERR_LOGIC_VIOLATION"
	elif _path_has_blacklist(path):
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

	return {
		"result_code": result_code,
		"sum_actual": sum_actual,
		"sum_input": sum_input_value,
		"must_visit_ok": _must_visit_ok(path)
	}

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
		+ n_reset * int(trust_cfg.get("penalty_reset", 5))
		+ n_transit * int(trust_cfg.get("penalty_transit", 25))
		+ n_logic * int(trust_cfg.get("penalty_logic_violation", 30))
		+ n_closed * int(trust_cfg.get("penalty_closed_edge", 8))
		+ overtime_penalty
	)

	var effective := float(trust_cfg.get("initial", 100)) - float(penalties)
	var ambush_multiplier := float(trust_cfg.get("ambush_multiplier", 0.5))
	for _i in range(ambush_hits):
		effective *= ambush_multiplier

	stability = clampf(effective, 0.0, 100.0)
	label_state.text = "СТАБИЛЬНОСТЬ: %d%%" % int(stability)

	var fail_threshold := float(trust_cfg.get("fail_threshold", 10))
	if stability <= fail_threshold and not is_game_over:
		is_game_over = true
		stage_completed = false
		status_label.text = "МИССИЯ ПРОВАЛЕНА: КРИТИЧЕСКАЯ СТАБИЛЬНОСТЬ."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
		btn_next.visible = false
		btn_next.disabled = true
		_lock_input(true)

func _update_timer_display() -> void:
	var time_limit := int(level_data.get("time_limit_sec", 140))
	var remaining: int = maxi(0, time_limit - real_time_sec)
	var mm: int = remaining / 60
	var ss: int = remaining % 60
	label_timer.text = "ВРЕМЯ: %02d:%02d" % [mm, ss]
	if real_time_sec > time_limit:
		label_timer.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))
	else:
		label_timer.add_theme_color_override("font_color", Color(1, 1, 1))

func _log_attempt(verdict: Dictionary) -> void:
	var sum_actual := int(verdict.get("sum_actual", -1))
	var sum_input_value: Variant = verdict.get("sum_input", null)
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var must_visit_ok := bool(verdict.get("must_visit_ok", false))
	var level_entry := _current_level_entry()
	var sublevel_id := str(level_entry.get("id", "6_3_%02d" % (level_index + 1)))
	var sublevel_path := str(level_entry.get("path", ""))
	var next_available := result_code == "OK" and level_index + 1 < level_total

	var attempt_no := GlobalMetrics.session_history.size() + 1
	var log_data := {
		"schema_version": "city_map.v2.2.0",
		"quest_id": "CITY_MAP",
		"stage": "C",
		"task_id": str(level_data.get("level_id", "6.3")),
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
		"calc_ok": sum_input_value != null and int(sum_input_value) == sum_actual,
		"optimal_ok": sum_actual == min_sum and result_code == "OK" and must_visit_ok and not xor_violation and not _path_has_blacklist(path),
		"must_visit_ok": must_visit_ok,
		"first_attempt_edge": null if first_attempt_edge.is_empty() else first_attempt_edge,
		"t_elapsed_seconds": real_time_sec,
		"path": path.duplicate(),
		"sum_actual": sum_actual,
		"sum_input": sum_input_value,
		"min_sum": min_sum,
		"backtrack_count": backtrack_count,
		"cycle_events": cycle_events,
		"constraint_violations": constraint_violations,
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

	var stamp := Time.get_unix_time_from_system()
	var filename := "user://research_logs/%s_%d.json" % [LOG_PREFIX, stamp]
	if is_summary:
		filename = "user://research_logs/%s_run_%s_%d.json" % [LOG_PREFIX, run_id, stamp]
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
